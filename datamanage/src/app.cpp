#include "app.h"

#include <CommCtrl.h>
#include <Windows.h>

#pragma comment(lib, "comctl32.lib")

namespace datamanage {

namespace {

const wchar_t kClassName[]  = L"DataManageMainWindow";
const wchar_t kWindowTitle[] = L"DataManage 0.1.0";

// Convenience: resize the status bar to span the bottom of the main
// window. Status bars manage their own height; we just forward WM_SIZE
// so the control adjusts to the new client width.
void layoutStatusBar(HWND hwnd) {
    HWND hStatus = GetDlgItem(hwnd, IDC_STATUS_BAR);
    if (hStatus) SendMessageW(hStatus, WM_SIZE, 0, 0);
}

HMENU buildMainMenu() {
    HMENU hMenu = CreateMenu();

    HMENU hFile = CreatePopupMenu();
    AppendMenuW(hFile, MF_STRING | MF_GRAYED, IDM_FILE_OPEN_CONFIG,
                L"&Open Config…\tCtrl+O");
    AppendMenuW(hFile, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(hFile, MF_STRING, IDM_FILE_EXIT, L"E&xit");
    AppendMenuW(hMenu, MF_POPUP, reinterpret_cast<UINT_PTR>(hFile), L"&File");

    HMENU hPack = CreatePopupMenu();
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
        L"Stage 1 of 9 — project scaffold.\n\n"
        L"Windows 10 packing tool for the Flutter app.\n"
        L"Packing, signing, and encryption arrive in later stages.",
        L"About DataManage",
        MB_OK | MB_ICONINFORMATION);
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
        case WM_CREATE: {
            // Status bar across the bottom — shows the build stage so the
            // window is honest about what it can do today.
            HWND hStatus = CreateWindowExW(
                0, STATUSCLASSNAMEW, nullptr,
                WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP,
                0, 0, 0, 0,
                hwnd,
                // CreateWindowEx overloads HMENU as the child-window ID
                // for child windows. UINT_PTR widening avoids C4312 on
                // x64 where HMENU is 64-bit.
                reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_STATUS_BAR)),
                reinterpret_cast<HINSTANCE>(GetWindowLongPtrW(hwnd, GWLP_HINSTANCE)),
                nullptr);
            if (hStatus) {
                SendMessageW(hStatus, SB_SETTEXTW, 0,
                             reinterpret_cast<LPARAM>(
                                 L"Stage 1 — scaffold only (packing not "
                                 L"implemented yet)"));
            }
            return 0;
        }

        case WM_SIZE:
            layoutStatusBar(hwnd);
            return 0;

        case WM_COMMAND: {
            const UINT id = LOWORD(wp);
            switch (id) {
                case IDM_FILE_EXIT:
                    PostMessageW(hwnd, WM_CLOSE, 0, 0);
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
            // Centre a short placeholder string in the empty client area
            // (above the status bar). Replaced in Stage 3 by the real
            // panels (bundle list / config editor / log pane).
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            RECT rc;
            GetClientRect(hwnd, &rc);
            HWND hStatus = GetDlgItem(hwnd, IDC_STATUS_BAR);
            if (hStatus) {
                RECT rs;
                GetWindowRect(hStatus, &rs);
                rc.bottom -= (rs.bottom - rs.top);
            }

            SetBkMode(hdc, TRANSPARENT);
            SetTextColor(hdc, RGB(120, 120, 120));

            const wchar_t* msg_text =
                L"DataManage\n\n"
                L"Stage 1 scaffold.\n"
                L"Use Help → About for build info.";
            DrawTextW(hdc, msg_text, -1, &rc,
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
    // Common Controls v6 needs an explicit init call before any common
    // control gets created. The manifest brings in the themed DLL; this
    // tells it which class families we care about (status bar lives in
    // ICC_BAR_CLASSES).
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
