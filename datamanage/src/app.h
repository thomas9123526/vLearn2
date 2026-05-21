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

// Status-bar child window ID — referenced from WM_SIZE so the bar
// repositions itself when the main window is resized.
constexpr UINT IDC_STATUS_BAR = 1000;

// Entry point for the GUI subsystem path. Returns the process exit code
// to forward up through wWinMain.
int runGui(HINSTANCE hInstance);

}  // namespace datamanage
