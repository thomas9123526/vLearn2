#include "app.h"

#include <CommCtrl.h>
#include <Windows.h>
#include <commdlg.h>  // GetOpenFileName — excluded by WIN32_LEAN_AND_MEAN

#include <exception>
#include <string>

#include "config.h"
#include "packer.h"

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

void layoutStatusBar(HWND hwnd) {
    HWND hStatus = GetDlgItem(hwnd, IDC_STATUS_BAR);
    if (hStatus) SendMessageW(hStatus, WM_SIZE, 0, 0);
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
        L"DataManage 0.1.0\n"
        L"Stage 3 of 9 — packer MVP.\n\n"
        L"Loads config.json, walks each bundle's source directory,\n"
        L"hashes every file, and writes a .ddp under output_dir.\n\n"
        L"Compression, signing, and encryption arrive in later stages.",
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
    setStatus(hwnd, L"Packing…");
    // Force a paint so the status bar updates before the (blocking)
    // pack work begins. Stage 3 runs the packer on the UI thread —
    // a background thread + progress dialog comes later.
    UpdateWindow(hwnd);

    try {
        const Config cfg = loadConfig(wideToUtf8(g_state.config_path));
        const auto results = packAll(cfg);  // no progress callback yet

        std::wstring msg = L"Packed " +
            utf8ToWide(std::to_string(results.size())) +
            L" bundle(s):\n\n";
        for (const auto& r : results) {
            msg += utf8ToWide(r.output_path);
            msg += L"\n  ";
            msg += utf8ToWide(std::to_string(r.file_count));
            msg += L" files, ";
            msg += utf8ToWide(std::to_string(r.total_bytes_in));
            msg += L" → ";
            msg += utf8ToWide(std::to_string(r.total_bytes_out));
            msg += L" bytes\n\n";
        }
        MessageBoxW(hwnd, msg.c_str(),
                    L"DataManage — pack complete",
                    MB_OK | MB_ICONINFORMATION);
        setStatus(hwnd, L"Pack complete.");
    } catch (const std::exception& e) {
        const std::wstring msg =
            L"Pack failed:\n\n" + utf8ToWide(e.what());
        MessageBoxW(hwnd, msg.c_str(), L"DataManage — pack error",
                    MB_OK | MB_ICONERROR);
        setStatus(hwnd, L"Pack failed.");
    }
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
        case WM_CREATE: {
            HWND hStatus = CreateWindowExW(
                0, STATUSCLASSNAMEW, nullptr,
                WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP,
                0, 0, 0, 0,
                hwnd,
                reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_STATUS_BAR)),
                reinterpret_cast<HINSTANCE>(GetWindowLongPtrW(hwnd, GWLP_HINSTANCE)),
                nullptr);
            if (hStatus) {
                SendMessageW(hStatus, SB_SETTEXTW, 0,
                             reinterpret_cast<LPARAM>(
                                 L"Stage 3 — open a config.json via "
                                 L"File → Open Config to begin"));
            }
            return 0;
        }

        case WM_SIZE:
            layoutStatusBar(hwnd);
            return 0;

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
                L"Pack → Run Pack…       (produces .ddp files)\n";
            DrawTextW(hdc, body, -1, &rc,
                      DT_CENTER | DT_VCENTER | DT_NOCLIP);

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_CLOSE:
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
    icc.dwICC = ICC_STANDARD_CLASSES | ICC_BAR_CLASSES | ICC_WIN95_CLASSES;
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
