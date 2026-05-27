#include "MainWindow.h"

#include <commdlg.h>
#include <shlobj.h>
#include <strsafe.h>

#include <chrono>
#include <ctime>
#include <filesystem>
#include <string>
#include <vector>

#include "CertIssuer.h"
#include "LeafCa.h"
#include "LicenseLog.h"
#include "QrWriter.h"
#include "WinStrings.h"
#include "resource.h"

#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "advapi32.lib")

namespace {

// Registry: HKCU\Software\vLearn2\KeyGenVS2022. Mirrors what the
// Qt version stored under HKCU via QSettings; each operator on the
// box gets their own remembered field values.
constexpr wchar_t kRegPath[]   = L"Software\\vLearn2\\KeyGenVS2022";
constexpr wchar_t kRegLeafCert[]   = L"paths.leafCert";
constexpr wchar_t kRegLeafKey[]    = L"paths.leafKey";
constexpr wchar_t kRegOutputDir[]  = L"paths.outputDir";
constexpr wchar_t kRegUserName[]   = L"form.userName";
constexpr wchar_t kRegDays[]       = L"form.days";

// Validates that `machineId` matches the 20-digit decimal format
// that AndroidDevID / WindowsDevID now emit (16 content digits +
// 4 checksum digits). A typo here would quietly issue a license
// that can never be claimed, so we keep the check strict.
bool isPlausibleMachineId(const std::string& s) {
    if (s.size() != 20) return false;
    for (char c : s) {
        if (c < '0' || c > '9') return false;
    }
    return true;
}

std::wstring regReadStr(const wchar_t* name, const std::wstring& def) {
    HKEY key{};
    if (::RegOpenKeyExW(HKEY_CURRENT_USER, kRegPath, 0, KEY_READ, &key) != ERROR_SUCCESS) {
        return def;
    }
    DWORD type = 0, size = 0;
    if (::RegQueryValueExW(key, name, nullptr, &type, nullptr, &size) != ERROR_SUCCESS
            || type != REG_SZ || size == 0) {
        ::RegCloseKey(key);
        return def;
    }
    std::wstring out(size / sizeof(wchar_t), L'\0');
    ::RegQueryValueExW(key, name, nullptr, nullptr,
                       reinterpret_cast<LPBYTE>(out.data()), &size);
    ::RegCloseKey(key);
    // RegQueryValueEx may include the trailing NUL in the size.
    if (!out.empty() && out.back() == L'\0') out.pop_back();
    return out;
}

DWORD regReadDword(const wchar_t* name, DWORD def) {
    HKEY key{};
    if (::RegOpenKeyExW(HKEY_CURRENT_USER, kRegPath, 0, KEY_READ, &key) != ERROR_SUCCESS) {
        return def;
    }
    DWORD type = 0, value = 0, size = sizeof(value);
    const bool ok = ::RegQueryValueExW(key, name, nullptr, &type,
                                       reinterpret_cast<LPBYTE>(&value),
                                       &size) == ERROR_SUCCESS && type == REG_DWORD;
    ::RegCloseKey(key);
    return ok ? value : def;
}

void regWriteStr(const wchar_t* name, const std::wstring& v) {
    HKEY key{};
    if (::RegCreateKeyExW(HKEY_CURRENT_USER, kRegPath, 0, nullptr, 0,
                          KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
        return;
    }
    const DWORD bytes = static_cast<DWORD>((v.size() + 1) * sizeof(wchar_t));
    ::RegSetValueExW(key, name, 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(v.c_str()), bytes);
    ::RegCloseKey(key);
}

void regWriteDword(const wchar_t* name, DWORD v) {
    HKEY key{};
    if (::RegCreateKeyExW(HKEY_CURRENT_USER, kRegPath, 0, nullptr, 0,
                          KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
        return;
    }
    ::RegSetValueExW(key, name, 0, REG_DWORD,
                     reinterpret_cast<const BYTE*>(&v), sizeof(v));
    ::RegCloseKey(key);
}

std::wstring documentsDir() {
    PWSTR path = nullptr;
    if (FAILED(::SHGetKnownFolderPath(FOLDERID_Documents, 0, nullptr, &path))) {
        return L"";
    }
    std::wstring out = path;
    ::CoTaskMemFree(path);
    return out;
}

// GetOpenFileName wrapper. Returns empty on cancel.
std::wstring browseFile(HWND owner, const wchar_t* title,
                        const wchar_t* filter, const std::wstring& initial) {
    wchar_t buf[MAX_PATH] = {0};
    StringCchCopyW(buf, MAX_PATH, initial.c_str());

    OPENFILENAMEW ofn{};
    ofn.lStructSize  = sizeof(ofn);
    ofn.hwndOwner    = owner;
    ofn.lpstrFilter  = filter;
    ofn.lpstrFile    = buf;
    ofn.nMaxFile     = MAX_PATH;
    ofn.lpstrTitle   = title;
    ofn.Flags        = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_EXPLORER;
    if (!::GetOpenFileNameW(&ofn)) return L"";
    return buf;
}

// SHBrowseForFolder wrapper. Returns empty on cancel. We pass the
// current path as a hint so the dialog opens at a useful spot.
std::wstring browseFolder(HWND owner, const wchar_t* title,
                          const std::wstring& initial) {
    BROWSEINFOW bi{};
    bi.hwndOwner = owner;
    bi.lpszTitle = title;
    bi.ulFlags   = BIF_RETURNONLYFSDIRS | BIF_USENEWUI;

    std::wstring initialCopy = initial;
    bi.lParam = reinterpret_cast<LPARAM>(initialCopy.c_str());
    bi.lpfn   = [](HWND h, UINT msg, LPARAM, LPARAM data) -> int {
        if (msg == BFFM_INITIALIZED && data) {
            ::SendMessageW(h, BFFM_SETSELECTIONW, TRUE, data);
        }
        return 0;
    };

    PIDLIST_ABSOLUTE id = ::SHBrowseForFolderW(&bi);
    if (!id) return L"";
    wchar_t buf[MAX_PATH] = {0};
    if (!::SHGetPathFromIDListW(id, buf)) {
        ::CoTaskMemFree(id);
        return L"";
    }
    ::CoTaskMemFree(id);
    return buf;
}

// ISO 8601 with milliseconds, UTC. Used both for the status line
// timestamps and for the CSV columns.
std::string nowIsoUtcMs() {
    using namespace std::chrono;
    const auto now = system_clock::now();
    const auto t   = system_clock::to_time_t(now);
    const auto ms  = static_cast<int>(duration_cast<milliseconds>(
                          now.time_since_epoch()).count() % 1000);
    std::tm tm{};
    gmtime_s(&tm, &t);
    char buf[40];
    StringCchPrintfA(buf, sizeof(buf),
        "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
        tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
        tm.tm_hour, tm.tm_min, tm.tm_sec, ms);
    return buf;
}

}  // namespace

// ─── MainWindow ─────────────────────────────────────────────

MainWindow::MainWindow(HINSTANCE hInstance) : hInstance_(hInstance) {}

int MainWindow::runModal() {
    return static_cast<int>(::DialogBoxParamW(
        hInstance_, MAKEINTRESOURCEW(IDD_MAIN), nullptr,
        &MainWindow::staticProc,
        reinterpret_cast<LPARAM>(this)));
}

INT_PTR CALLBACK MainWindow::staticProc(HWND hwnd, UINT msg,
                                        WPARAM wp, LPARAM lp) {
    MainWindow* self = nullptr;
    if (msg == WM_INITDIALOG) {
        self = reinterpret_cast<MainWindow*>(lp);
        ::SetWindowLongPtrW(hwnd, DWLP_USER, reinterpret_cast<LONG_PTR>(self));
        self->hwnd_ = hwnd;
    } else {
        self = reinterpret_cast<MainWindow*>(
            ::GetWindowLongPtrW(hwnd, DWLP_USER));
    }
    if (!self) return FALSE;
    return self->proc(hwnd, msg, wp, lp);
}

INT_PTR MainWindow::proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM /*lp*/) {
    switch (msg) {
        case WM_INITDIALOG:
            onInit(hwnd);
            return TRUE;
        case WM_COMMAND:
            switch (LOWORD(wp)) {
                case IDC_LEAF_CERT_BROWSE:   onBrowseLeafCert();  return TRUE;
                case IDC_LEAF_KEY_BROWSE:    onBrowseLeafKey();   return TRUE;
                case IDC_OUTPUT_DIR_BROWSE:  onBrowseOutputDir(); return TRUE;
                case IDC_GENERATE_BUTTON:    onGenerate();        return TRUE;
                case IDCANCEL:
                    persistFields();
                    ::EndDialog(hwnd, 0);
                    return TRUE;
            }
            break;
        case WM_CLOSE:
            persistFields();
            ::EndDialog(hwnd, 0);
            return TRUE;
    }
    return FALSE;
}

void MainWindow::onInit(HWND /*hwnd*/) {
    restoreFields();
}

void MainWindow::restoreFields() {
    setEditText(IDC_LEAF_CERT_EDIT, regReadStr(kRegLeafCert, L""));
    setEditText(IDC_LEAF_KEY_EDIT,  regReadStr(kRegLeafKey,  L""));

    // Default output dir = <documents>/vLearn2/licenses on first run.
    std::wstring defaultOut = documentsDir();
    if (!defaultOut.empty()) {
        defaultOut += L"\\vLearn2\\licenses";
    }
    setEditText(IDC_OUTPUT_DIR_EDIT, regReadStr(kRegOutputDir, defaultOut));

    setEditText(IDC_USER_NAME_EDIT, regReadStr(kRegUserName, L""));

    const DWORD days = regReadDword(kRegDays, 100);
    wchar_t buf[16];
    StringCchPrintfW(buf, 16, L"%u", days);
    setEditText(IDC_DAYS_EDIT, buf);
}

void MainWindow::persistFields() const {
    regWriteStr(kRegLeafCert,  getEditText(IDC_LEAF_CERT_EDIT));
    regWriteStr(kRegLeafKey,   getEditText(IDC_LEAF_KEY_EDIT));
    regWriteStr(kRegOutputDir, getEditText(IDC_OUTPUT_DIR_EDIT));
    regWriteStr(kRegUserName,  getEditText(IDC_USER_NAME_EDIT));

    const std::wstring daysStr = getEditText(IDC_DAYS_EDIT);
    DWORD days = 100;
    try { days = static_cast<DWORD>(std::stoul(daysStr)); }
    catch (...) {}
    regWriteDword(kRegDays, days);
}

void MainWindow::appendStatus(const std::string& utf8) {
    const std::string line = "[" + nowIsoUtcMs() + "] " + utf8 + "\r\n";
    const std::wstring wline = winstr::widen(line);

    HWND edit = ::GetDlgItem(hwnd_, IDC_STATUS_EDIT);
    if (!edit) return;
    // Move caret to end, then replace selection with new text -- the
    // idiomatic Win32 "append" since EDIT has no native append API.
    const int len = ::GetWindowTextLengthW(edit);
    ::SendMessageW(edit, EM_SETSEL, len, len);
    ::SendMessageW(edit, EM_REPLACESEL, FALSE,
                   reinterpret_cast<LPARAM>(wline.c_str()));
}

std::wstring MainWindow::getEditText(int controlId) const {
    HWND ctl = ::GetDlgItem(hwnd_, controlId);
    if (!ctl) return L"";
    const int n = ::GetWindowTextLengthW(ctl);
    if (n <= 0) return L"";
    // n+1 to fit the null terminator GetWindowTextW writes; resize
    // back down because the API may return a length shorter than the
    // initial estimate when DBCS or null-bearing text is involved.
    std::wstring out(static_cast<size_t>(n) + 1, L'\0');
    const int actual = ::GetWindowTextW(ctl, out.data(), n + 1);
    out.resize(static_cast<size_t>(actual > 0 ? actual : 0));
    return out;
}

void MainWindow::setEditText(int controlId, const std::wstring& s) {
    HWND ctl = ::GetDlgItem(hwnd_, controlId);
    if (ctl) ::SetWindowTextW(ctl, s.c_str());
}

void MainWindow::onBrowseLeafCert() {
    const std::wstring current = getEditText(IDC_LEAF_CERT_EDIT);
    const wchar_t* filter =
        L"PEM certificates (*.cer;*.crt;*.pem)\0*.cer;*.crt;*.pem\0"
        L"All files (*.*)\0*.*\0";
    const std::wstring picked = browseFile(hwnd_, L"Leaf CA certificate",
                                           filter, current);
    if (!picked.empty()) setEditText(IDC_LEAF_CERT_EDIT, picked);
}

void MainWindow::onBrowseLeafKey() {
    const std::wstring current = getEditText(IDC_LEAF_KEY_EDIT);
    const wchar_t* filter =
        L"PEM keys (*.key;*.pem)\0*.key;*.pem\0"
        L"All files (*.*)\0*.*\0";
    const std::wstring picked = browseFile(hwnd_, L"Leaf CA private key",
                                           filter, current);
    if (!picked.empty()) setEditText(IDC_LEAF_KEY_EDIT, picked);
}

void MainWindow::onBrowseOutputDir() {
    const std::wstring current = getEditText(IDC_OUTPUT_DIR_EDIT);
    const std::wstring picked = browseFolder(hwnd_, L"Output directory", current);
    if (!picked.empty()) setEditText(IDC_OUTPUT_DIR_EDIT, picked);
}

void MainWindow::onGenerate() {
    persistFields();

    const std::wstring wLeafCert = getEditText(IDC_LEAF_CERT_EDIT);
    const std::wstring wLeafKey  = getEditText(IDC_LEAF_KEY_EDIT);
    const std::wstring wOutDir   = getEditText(IDC_OUTPUT_DIR_EDIT);
    const std::string  machineId = winstr::trim(winstr::narrow(getEditText(IDC_MACHINE_ID_EDIT)));
    const std::string  userName  = winstr::trim(winstr::narrow(getEditText(IDC_USER_NAME_EDIT)));
    const std::wstring wDays     = getEditText(IDC_DAYS_EDIT);

    int days = 0;
    try { days = std::stoi(wDays); } catch (...) { days = 0; }

    if (wLeafCert.empty() || wLeafKey.empty()) {
        ::MessageBoxW(hwnd_, L"Pick a Leaf CA cert and key first.",
                      L"Missing input", MB_ICONWARNING | MB_OK);
        return;
    }
    if (!isPlausibleMachineId(machineId)) {
        ::MessageBoxW(hwnd_,
            L"Machine ID must be 20 decimal digits "
            L"(16 content + 4 checksum, from AndroidDevID / WindowsDevID).",
            L"Bad machine ID", MB_ICONWARNING | MB_OK);
        return;
    }
    if (userName.empty()) {
        ::MessageBoxW(hwnd_, L"Enter the user name to bind the license to.",
                      L"Missing user", MB_ICONWARNING | MB_OK);
        return;
    }
    if (days <= 0) {
        ::MessageBoxW(hwnd_, L"License days must be > 0.",
                      L"Bad days", MB_ICONWARNING | MB_OK);
        return;
    }

    // Make sure output dir exists.
    std::error_code ec;
    std::filesystem::create_directories(wOutDir, ec);

    // ---- Load Leaf CA ----------------------------------------------
    LeafCa ca;
    std::string err;
    if (!ca.load(wLeafCert, wLeafKey, &err)) {
        appendStatus("ERROR loading Leaf CA: " + err);
        ::MessageBoxW(hwnd_, winstr::widen(err).c_str(),
                      L"Leaf CA", MB_ICONERROR | MB_OK);
        return;
    }
    appendStatus("Leaf CA loaded (subject=" + ca.subjectCn() + ")");

    // ---- Issue leaf cert -------------------------------------------
    CertIssuer issuer;
    CertIssuer::Result result;
    if (!issuer.issue(ca, machineId, userName, days, &result, &err)) {
        appendStatus("ERROR issuing leaf: " + err);
        ::MessageBoxW(hwnd_, winstr::widen(err).c_str(),
                      L"Issue", MB_ICONERROR | MB_OK);
        return;
    }
    const std::string mode = days >= 36500 ? "permanent" : "period";
    {
        char buf[160];
        StringCchPrintfA(buf, sizeof(buf),
            "Issued serial=%s days=%d mode=%s size=%zu bytes",
            result.serialHex.c_str(), days, mode.c_str(),
            result.certDer.size());
        appendStatus(buf);
    }
    if (result.certDer.size() > 1500) {
        char buf[120];
        StringCchPrintfA(buf, sizeof(buf),
            "WARN cert size %zu bytes exceeds the 1500-byte QR budget",
            result.certDer.size());
        appendStatus(buf);
    }

    // ---- Write .lic + .png -----------------------------------------
    const std::wstring wSerial = winstr::widen(result.serialHex);
    const std::wstring licPath = std::wstring(wOutDir) + L"\\" + wSerial + L".lic";
    const std::wstring pngPath = std::wstring(wOutDir) + L"\\" + wSerial + L".png";

    {
        FILE* f = nullptr;
        if (_wfopen_s(&f, licPath.c_str(), L"wb") != 0 || !f) {
            appendStatus("ERROR writing .lic: " + winstr::narrow(licPath));
            return;
        }
        fwrite(result.certDer.data(), 1, result.certDer.size(), f);
        fclose(f);
        appendStatus("Wrote " + winstr::narrow(licPath));
    }

    if (!QrWriter::writePng(result.certDer, pngPath, &err)) {
        appendStatus("ERROR writing QR PNG: " + err);
    } else {
        appendStatus("Wrote " + winstr::narrow(pngPath));
    }

    // ---- Log -------------------------------------------------------
    LicenseLog::Entry entry;
    entry.serialHex   = result.serialHex;
    entry.machineId   = machineId;
    entry.userName    = userName;
    entry.mode        = mode;
    entry.days        = days;
    entry.notBefore   = result.notBefore;
    entry.notAfter    = result.notAfter;
    entry.certDer     = result.certDer;

    // Operator tag: USERNAME env var, falling back to "unknown".
    wchar_t userBuf[256] = {0};
    DWORD userBufSize = 256;
    if (::GetEnvironmentVariableW(L"USERNAME", userBuf, userBufSize) > 0) {
        entry.operatorTag = winstr::narrow(userBuf);
    } else {
        entry.operatorTag = "unknown";
    }

    LicenseLog log(wOutDir);
    if (!log.append(entry, &err)) {
        appendStatus("WARN local log append failed: " + err);
    } else {
        appendStatus("Logged to " + winstr::narrow(log.csvPath()));
    }
}
