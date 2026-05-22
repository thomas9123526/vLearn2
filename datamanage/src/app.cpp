#include "app.h"

#include <CommCtrl.h>
#include <Windows.h>
#include <commdlg.h>  // GetOpenFileName — excluded by WIN32_LEAN_AND_MEAN

#include <cstdint>
#include <cwchar>
#include <exception>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "config.h"
#include "packer.h"
#include "session.h"
#include "sha256.h"

#pragma comment(lib, "comctl32.lib")

namespace datamanage {

namespace {

const wchar_t kClassName[]   = L"DataManageMainWindow";
const wchar_t kWindowTitle[] = L"DataManage 0.1.0";

// One global "currently loaded config" path. Kept simple — the
// admin opens a config from File menu, then hits Pack → Run. Stage 3
// uses only the path; loadConfig() runs again on each pack so edits
// to the file in another editor are picked up.
struct AppState {
    std::wstring config_path;
    // True while a background pack is running. Guards against a second
    // Run Pack, and lets the window-close path warn the user.
    bool packing = false;
};
AppState g_state;

std::wstring utf8ToWide(const std::string& s) {
    if (s.empty()) return {};
    const int len = MultiByteToWideChar(CP_UTF8, 0, s.data(),
                                        static_cast<int>(s.size()),
                                        nullptr, 0);
    std::wstring out(static_cast<size_t>(len), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(),
                        static_cast<int>(s.size()),
                        out.data(), len);
    return out;
}

std::string wideToUtf8(const std::wstring& w) {
    if (w.empty()) return {};
    const int len = WideCharToMultiByte(CP_UTF8, 0, w.data(),
                                        static_cast<int>(w.size()),
                                        nullptr, 0, nullptr, nullptr);
    std::string out(static_cast<size_t>(len), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.data(),
                        static_cast<int>(w.size()),
                        out.data(), len, nullptr, nullptr);
    return out;
}

void setStatus(HWND hwnd, const std::wstring& text) {
    if (HWND hStatus = GetDlgItem(hwnd, IDC_STATUS_BAR)) {
        SendMessageW(hStatus, SB_SETTEXTW, 0,
                     reinterpret_cast<LPARAM>(text.c_str()));
    }
}

// ─── byte-size formatting for the pack-complete dialog ────────────────────

// "4631678" → "4,631,678" — thousands separators so big byte counts
// stay readable in the MessageBox.
std::wstring groupDigits(uint64_t n) {
    std::wstring s = std::to_wstring(n);
    for (int pos = static_cast<int>(s.size()) - 3; pos > 0; pos -= 3) {
        s.insert(static_cast<size_t>(pos), L",");
    }
    return s;
}

// "4,631,678 bytes (4.42 MB)" — raw byte count + the MB figure, so the
// admin sees both an exact number and a human-scale one. MB is binary
// (1 MB = 1024×1024), matching what Windows Explorer shows.
std::wstring formatSize(uint64_t bytes) {
    const double mb = static_cast<double>(bytes) / (1024.0 * 1024.0);
    wchar_t mbuf[32];
    std::swprintf(mbuf, 32, L"%.2f", mb);
    return groupDigits(bytes) + L" bytes (" + mbuf + L" MB)";
}

// One line describing the size delta between source and packed:
//   "reduced: 2,359,701 bytes (2.25 MB)  —  50.9% smaller"
// or, for incompressible/encrypted bundles that end up bigger:
//   "grew: +12,345 bytes (0.01 MB)  (+0.3%)"
std::wstring reductionLine(uint64_t in, uint64_t out) {
    wchar_t pbuf[32];
    if (out <= in) {
        const uint64_t saved = in - out;
        const double pct = in > 0
            ? 100.0 * static_cast<double>(saved) / static_cast<double>(in)
            : 0.0;
        std::swprintf(pbuf, 32, L"%.1f", pct);
        return L"reduced: " + formatSize(saved) +
               L"  —  " + pbuf + L"% smaller";
    }
    const uint64_t grew = out - in;
    const double pct = in > 0
        ? 100.0 * static_cast<double>(grew) / static_cast<double>(in)
        : 0.0;
    std::swprintf(pbuf, 32, L"%.1f", pct);
    return L"grew: +" + formatSize(grew) + L"  (+" + pbuf + L"%)";
}

// ─── background packing: worker thread + progress + resume ────────────────

// SHA-256 of the config file's raw bytes. The resume checkpoint is
// keyed to this — a changed config invalidates a stale session.
std::string hashConfigFile(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) {
        throw std::runtime_error("cannot open config to hash: " + path);
    }
    std::ostringstream ss;
    ss << f.rdbuf();
    const std::string content = ss.str();
    return Sha256::hashHex(content.data(), content.size());
}

// Overall progress percent. Each bundle owns an equal slice of the
// bar; `frac` (0..1) is how far through the current bundle we are.
int percentForBundle(size_t index, size_t total, double frac) {
    if (total == 0) return 100;
    const double overall =
        (static_cast<double>(index) + frac) / static_cast<double>(total);
    int pct = static_cast<int>(overall * 100.0 + 0.5);
    if (pct < 0)   pct = 0;
    if (pct > 100) pct = 100;
    return pct;
}

// Post a progress update to the UI thread. Ownership of the heap
// string transfers to the WM_APP_PACK_PROGRESS handler, which deletes
// it. Safe to call from the worker thread (PostMessage is thread-safe).
void postProgress(HWND hwnd, int percent, const std::wstring& text) {
    PostMessageW(hwnd, WM_APP_PACK_PROGRESS,
                 static_cast<WPARAM>(percent),
                 reinterpret_cast<LPARAM>(new std::wstring(text)));
}

// Build the pack-complete dialog body from the per-bundle results.
std::wstring buildResultText(const std::vector<PackResult>& results,
                             int resumedCount) {
    uint64_t grandIn = 0, grandOut = 0;
    std::wstring msg =
        L"Packed " + std::to_wstring(results.size()) + L" bundle(s)";
    if (resumedCount > 0) {
        msg += L"  (" + std::to_wstring(resumedCount) +
               L" resumed from a previous session)";
    }
    msg += L":\n\n";
    for (const auto& r : results) {
        grandIn  += r.total_bytes_in;
        grandOut += r.total_bytes_out;
        msg += utf8ToWide(r.output_path);
        msg += L"\n  " + std::to_wstring(r.file_count) + L" files\n";
        msg += L"  source : " + formatSize(r.total_bytes_in)  + L"\n";
        msg += L"  packed : " + formatSize(r.total_bytes_out) + L"\n";
        msg += L"  " + reductionLine(r.total_bytes_in,
                                     r.total_bytes_out) + L"\n\n";
    }
    if (results.size() > 1) {
        msg += L"───────────────────────────\n";
        msg += L"Total source : " + formatSize(grandIn)  + L"\n";
        msg += L"Total packed : " + formatSize(grandOut) + L"\n";
        msg += L"Total " + reductionLine(grandIn, grandOut) + L"\n";
    }
    return msg;
}

// The background pack loop. Runs on a std::thread; never touches Win32
// controls directly — only PostMessage's progress / done / error back
// to `hwnd`. Drives the bundle loop itself (rather than packAll) so it
// can checkpoint the resume session after every bundle.
void packWorker(HWND hwnd, Config cfg, std::string config_hash) {
    try {
        PackSession session =
            PackSession::open(cfg.output_dir, config_hash);
        const int resumed = session.resumedCount();

        std::vector<PackResult> results;
        results.reserve(cfg.bundles.size());
        const size_t total = cfg.bundles.size();

        for (size_t i = 0; i < total; ++i) {
            const BundleConfig& bundle = cfg.bundles[i];
            const std::wstring nameW = utf8ToWide(bundle.name);
            const std::wstring counter =
                L" (" + std::to_wstring(i + 1) + L"/" +
                std::to_wstring(total) + L")";

            // Already finished in a prior run — skip, reuse the record.
            if (session.isDone(bundle.name)) {
                const SessionBundle sb = session.get(bundle.name);
                PackResult r;
                r.output_path     = sb.output_path;
                r.file_count      = sb.file_count;
                r.total_bytes_in  = sb.bytes_in;
                r.total_bytes_out = sb.bytes_out;
                results.push_back(r);
                postProgress(hwnd, percentForBundle(i + 1, total, 0.0),
                             L"Resumed" + counter + L" — " + nameW +
                             L" (already packed)");
                continue;
            }

            // Per-file progress callback — fired by packBundle as it
            // walks the bundle's files.
            auto progress = [&](const std::string& rel,
                                uint64_t done, uint64_t totalFiles) {
                const double frac = totalFiles > 0
                    ? static_cast<double>(done) /
                          static_cast<double>(totalFiles)
                    : 0.0;
                std::wstring text = L"Packing" + counter + L" — " + nameW;
                if (!rel.empty()) {
                    text += L"  —  " + utf8ToWide(rel) + L"  (" +
                            std::to_wstring(done) + L"/" +
                            std::to_wstring(totalFiles) + L")";
                }
                postProgress(hwnd, percentForBundle(i, total, frac), text);
            };

            PackResult r = packBundle(bundle, cfg.output_dir, progress,
                                      bundle.pack_mode, cfg.signing);
            results.push_back(r);

            // Checkpoint immediately: a crash after this point resumes
            // from the *next* bundle.
            SessionBundle sb;
            sb.name        = bundle.name;
            sb.output_path = r.output_path;
            sb.file_count  = r.file_count;
            sb.bytes_in    = r.total_bytes_in;
            sb.bytes_out   = r.total_bytes_out;
            session.checkpoint(sb);
        }

        session.finish();  // clean run — drop the checkpoint file

        auto* done = new std::wstring(buildResultText(results, resumed));
        PostMessageW(hwnd, WM_APP_PACK_DONE, 0,
                     reinterpret_cast<LPARAM>(done));
    } catch (const std::exception& e) {
        auto* err = new std::wstring(utf8ToWide(e.what()));
        PostMessageW(hwnd, WM_APP_PACK_ERROR, 0,
                     reinterpret_cast<LPARAM>(err));
    }
}

void layoutStatusBar(HWND hwnd) {
    HWND hStatus = GetDlgItem(hwnd, IDC_STATUS_BAR);
    if (hStatus) SendMessageW(hStatus, WM_SIZE, 0, 0);
}

// Position the progress bar as a horizontal strip just above the
// status bar, with a small margin. Called from WM_SIZE.
void layoutProgressBar(HWND hwnd) {
    HWND bar = GetDlgItem(hwnd, IDC_PROGRESS_BAR);
    if (!bar) return;
    RECT rc;
    GetClientRect(hwnd, &rc);

    int statusH = 0;
    if (HWND status = GetDlgItem(hwnd, IDC_STATUS_BAR)) {
        RECT rs;
        GetWindowRect(status, &rs);
        statusH = rs.bottom - rs.top;
    }
    const int barH   = 22;
    const int margin = 12;
    MoveWindow(bar,
               margin,
               rc.bottom - statusH - barH - margin,
               rc.right - 2 * margin,
               barH,
               TRUE);
}

// Enter / leave the "packing" UI state: grey the Run Pack menu item so
// a second run can't start, and show / hide the progress bar.
void beginPackingUI(HWND hwnd) {
    g_state.packing = true;
    EnableMenuItem(GetMenu(hwnd), IDM_PACK_RUN, MF_BYCOMMAND | MF_GRAYED);
    if (HWND bar = GetDlgItem(hwnd, IDC_PROGRESS_BAR)) {
        SendMessageW(bar, PBM_SETPOS, 0, 0);
        ShowWindow(bar, SW_SHOW);
    }
}

void endPackingUI(HWND hwnd) {
    g_state.packing = false;
    EnableMenuItem(GetMenu(hwnd), IDM_PACK_RUN, MF_BYCOMMAND | MF_ENABLED);
    if (HWND bar = GetDlgItem(hwnd, IDC_PROGRESS_BAR)) {
        ShowWindow(bar, SW_HIDE);
    }
}

HMENU buildMainMenu() {
    HMENU hMenu = CreateMenu();

    HMENU hFile = CreatePopupMenu();
    AppendMenuW(hFile, MF_STRING, IDM_FILE_OPEN_CONFIG,
                L"&Open Config…\tCtrl+O");
    AppendMenuW(hFile, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(hFile, MF_STRING, IDM_FILE_EXIT, L"E&xit");
    AppendMenuW(hMenu, MF_POPUP, reinterpret_cast<UINT_PTR>(hFile), L"&File");

    HMENU hPack = CreatePopupMenu();
    // Pack is greyed until a config is loaded — enables in onOpenConfig.
    AppendMenuW(hPack, MF_STRING | MF_GRAYED, IDM_PACK_RUN, L"&Run Pack…");
    AppendMenuW(hMenu, MF_POPUP, reinterpret_cast<UINT_PTR>(hPack), L"&Pack");

    HMENU hHelp = CreatePopupMenu();
    AppendMenuW(hHelp, MF_STRING, IDM_HELP_ABOUT, L"&About DataManage");
    AppendMenuW(hMenu, MF_POPUP, reinterpret_cast<UINT_PTR>(hHelp), L"&Help");

    return hMenu;
}

void onAbout(HWND hwnd) {
    MessageBoxW(
        hwnd,
        L"DataManage 0.1.0\n\n"
        L"Loads config.json, walks each bundle's source directory,\n"
        L"compresses / signs / encrypts per pack_mode, and writes a\n"
        L".dat bundle under output_dir. Packing runs in the background\n"
        L"with live progress, and resumes a previous run if it was\n"
        L"interrupted.",
        L"About DataManage",
        MB_OK | MB_ICONINFORMATION);
}

void onOpenConfig(HWND hwnd) {
    wchar_t buf[MAX_PATH] = L"";
    OPENFILENAMEW ofn{};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner   = hwnd;
    ofn.lpstrFilter = L"Config (config.json)\0*.json\0All files\0*.*\0";
    ofn.lpstrFile   = buf;
    ofn.nMaxFile    = MAX_PATH;
    ofn.lpstrTitle  = L"Select config.json";
    ofn.Flags       = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

    if (!GetOpenFileNameW(&ofn)) return;  // user cancelled

    g_state.config_path = buf;
    // Validate immediately so the admin knows the config is loadable
    // before pressing Run.
    try {
        const auto cfg = loadConfig(wideToUtf8(g_state.config_path));
        // Enable Pack → Run Pack now that we have a valid config.
        HMENU hMenu = GetMenu(hwnd);
        EnableMenuItem(hMenu, IDM_PACK_RUN, MF_BYCOMMAND | MF_ENABLED);
        std::wstring status = L"Loaded ";
        status += utf8ToWide(std::to_string(cfg.bundles.size()));
        status += L" bundle(s) from ";
        status += g_state.config_path;
        setStatus(hwnd, status);
    } catch (const std::exception& e) {
        g_state.config_path.clear();
        const std::wstring msg =
            L"Failed to load config:\n\n" + utf8ToWide(e.what());
        MessageBoxW(hwnd, msg.c_str(), L"DataManage — config error",
                    MB_OK | MB_ICONERROR);
        setStatus(hwnd, L"Stage 3 — config failed to load");
    }
}

void onRunPack(HWND hwnd) {
    if (g_state.config_path.empty()) {
        MessageBoxW(hwnd, L"Open a config.json first via File → Open Config.",
                    L"DataManage", MB_OK | MB_ICONINFORMATION);
        return;
    }
    if (g_state.packing) {
        MessageBoxW(hwnd, L"A pack run is already in progress.",
                    L"DataManage", MB_OK | MB_ICONINFORMATION);
        return;
    }

    // Load + hash the config on the UI thread so a bad config surfaces
    // immediately — before we show the progress bar or spawn a worker.
    Config cfg;
    std::string config_hash;
    try {
        const std::string cfgPath = wideToUtf8(g_state.config_path);
        cfg         = loadConfig(cfgPath);
        config_hash = hashConfigFile(cfgPath);
    } catch (const std::exception& e) {
        MessageBoxW(hwnd,
                    (L"Failed to load config:\n\n" +
                     utf8ToWide(e.what())).c_str(),
                    L"DataManage — config error",
                    MB_OK | MB_ICONERROR);
        return;
    }

    beginPackingUI(hwnd);
    setStatus(hwnd, L"Packing…");

    // Detach: the worker outlives this call and reports back via
    // PostMessage. If the window closes mid-pack the process exits and
    // the worker dies — the resume checkpoint is the safety net for
    // exactly that case.
    std::thread(packWorker, hwnd, std::move(cfg),
                std::move(config_hash)).detach();
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
        case WM_CREATE: {
            const HINSTANCE hInst = reinterpret_cast<HINSTANCE>(
                GetWindowLongPtrW(hwnd, GWLP_HINSTANCE));

            HWND hStatus = CreateWindowExW(
                0, STATUSCLASSNAMEW, nullptr,
                WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP,
                0, 0, 0, 0,
                hwnd,
                reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_STATUS_BAR)),
                hInst, nullptr);
            if (hStatus) {
                SendMessageW(hStatus, SB_SETTEXTW, 0,
                             reinterpret_cast<LPARAM>(
                                 L"Open a config.json via "
                                 L"File → Open Config to begin"));
            }

            // Progress bar — created hidden (no WS_VISIBLE);
            // beginPackingUI shows it, endPackingUI hides it again.
            HWND hBar = CreateWindowExW(
                0, PROGRESS_CLASSW, nullptr,
                WS_CHILD,
                0, 0, 0, 0,
                hwnd,
                reinterpret_cast<HMENU>(
                    static_cast<UINT_PTR>(IDC_PROGRESS_BAR)),
                hInst, nullptr);
            if (hBar) {
                SendMessageW(hBar, PBM_SETRANGE32, 0,
                             static_cast<LPARAM>(100));
            }
            return 0;
        }

        case WM_SIZE:
            layoutStatusBar(hwnd);
            layoutProgressBar(hwnd);
            return 0;

        case WM_APP_PACK_PROGRESS: {
            if (HWND bar = GetDlgItem(hwnd, IDC_PROGRESS_BAR)) {
                SendMessageW(bar, PBM_SETPOS, wp, 0);
            }
            auto* text = reinterpret_cast<std::wstring*>(lp);
            if (text) {
                setStatus(hwnd, *text);
                delete text;
            }
            return 0;
        }

        case WM_APP_PACK_DONE: {
            endPackingUI(hwnd);
            auto* body = reinterpret_cast<std::wstring*>(lp);
            if (body) {
                MessageBoxW(hwnd, body->c_str(),
                            L"DataManage — pack complete",
                            MB_OK | MB_ICONINFORMATION);
                delete body;
            }
            setStatus(hwnd, L"Pack complete.");
            return 0;
        }

        case WM_APP_PACK_ERROR: {
            endPackingUI(hwnd);
            auto* err = reinterpret_cast<std::wstring*>(lp);
            if (err) {
                MessageBoxW(hwnd,
                            (L"Pack failed:\n\n" + *err).c_str(),
                            L"DataManage — pack error",
                            MB_OK | MB_ICONERROR);
                delete err;
            }
            setStatus(hwnd, L"Pack failed.");
            return 0;
        }

        case WM_COMMAND: {
            const UINT id = LOWORD(wp);
            switch (id) {
                case IDM_FILE_OPEN_CONFIG:
                    onOpenConfig(hwnd);
                    return 0;
                case IDM_FILE_EXIT:
                    PostMessageW(hwnd, WM_CLOSE, 0, 0);
                    return 0;
                case IDM_PACK_RUN:
                    onRunPack(hwnd);
                    return 0;
                case IDM_HELP_ABOUT:
                    onAbout(hwnd);
                    return 0;
                default:
                    break;
            }
            break;
        }

        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            RECT rc;
            GetClientRect(hwnd, &rc);
            if (HWND hStatus = GetDlgItem(hwnd, IDC_STATUS_BAR)) {
                RECT rs;
                GetWindowRect(hStatus, &rs);
                rc.bottom -= (rs.bottom - rs.top);
            }

            SetBkMode(hdc, TRANSPARENT);
            SetTextColor(hdc, RGB(120, 120, 120));

            const wchar_t* body =
                L"DataManage\n\n"
                L"File → Open Config…   (point at config.json)\n"
                L"Pack → Run Pack…       (produces .dat files)\n";
            DrawTextW(hdc, body, -1, &rc,
                      DT_CENTER | DT_VCENTER | DT_NOCLIP);

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_CLOSE:
            if (g_state.packing) {
                const int r = MessageBoxW(
                    hwnd,
                    L"A pack run is still in progress.\n\n"
                    L"Exit anyway? Finished bundles are already saved — "
                    L"the next run will resume from where this one "
                    L"stopped.",
                    L"DataManage — packing in progress",
                    MB_YESNO | MB_ICONWARNING);
                if (r != IDYES) return 0;
            }
            DestroyWindow(hwnd);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
            break;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

}  // namespace

int runGui(HINSTANCE hInstance) {
    INITCOMMONCONTROLSEX icc{};
    icc.dwSize = sizeof(icc);
    icc.dwICC = ICC_STANDARD_CLASSES | ICC_BAR_CLASSES |
                ICC_PROGRESS_CLASS | ICC_WIN95_CLASSES;
    InitCommonControlsEx(&icc);

    WNDCLASSEXW wc{};
    wc.cbSize        = sizeof(wc);
    wc.style         = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc   = WindowProc;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
    wc.lpszClassName = kClassName;
    wc.hIcon         = LoadIcon(nullptr, IDI_APPLICATION);
    wc.hIconSm       = LoadIcon(nullptr, IDI_APPLICATION);
    if (!RegisterClassExW(&wc)) return 1;

    HMENU hMenu = buildMainMenu();

    HWND hwnd = CreateWindowExW(
        0,
        kClassName,
        kWindowTitle,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT,
        900, 600,
        nullptr,
        hMenu,
        hInstance,
        nullptr);
    if (!hwnd) return 1;

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return static_cast<int>(msg.wParam);
}

}  // namespace datamanage
