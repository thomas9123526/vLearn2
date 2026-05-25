// GUI mode for DataManage. Stage 1: just the main window shell —
// titlebar + menu bar + status bar + a placeholder client area. Real
// panels (bundle list, config editor, log pane, progress) arrive in
// Stage 3+ as the packer fills in.

#pragma once

#include <Windows.h>

namespace datamanage {

// Menu command IDs. Kept in one place so app.cpp's WindowProc can switch
// on them without sprinkling magic numbers around.
constexpr UINT IDM_FILE_OPEN_CONFIG = 100;
constexpr UINT IDM_FILE_EXIT        = 101;
constexpr UINT IDM_PACK_RUN         = 200;
constexpr UINT IDM_HELP_ABOUT       = 300;

// Child-window control IDs — referenced from WM_SIZE so the controls
// reposition themselves when the main window is resized.
constexpr UINT IDC_STATUS_BAR   = 1000;
constexpr UINT IDC_PROGRESS_BAR = 1001;

// Worker-thread → UI-thread messages. Packing runs on a background
// std::thread so the UI never freezes; the worker can't touch Win32
// controls directly, so it PostMessage's these instead.
//   WM_APP_PACK_PROGRESS: wParam = percent 0..100,
//                         lParam = heap-allocated std::wstring* status text
//                                  (the UI thread takes ownership + deletes)
//   WM_APP_PACK_DONE:     lParam = heap-allocated std::wstring* result dialog
//   WM_APP_PACK_ERROR:    lParam = heap-allocated std::wstring* error text
constexpr UINT WM_APP_PACK_PROGRESS = WM_APP + 1;
constexpr UINT WM_APP_PACK_DONE     = WM_APP + 2;
constexpr UINT WM_APP_PACK_ERROR    = WM_APP + 3;

// Entry point for the GUI subsystem path. Returns the process exit code
// to forward up through wWinMain.
int runGui(HINSTANCE hInstance);

}  // namespace datamanage
