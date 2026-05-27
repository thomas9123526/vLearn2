// Win32 entry point for KeyGenVS2022. Pure modal-dialog app -- the
// whole UI lives in MainWindow.rc as a single DIALOGEX template,
// and MainWindow runs it via DialogBoxParam below.

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <commctrl.h>

#include "MainWindow.h"

#pragma comment(lib, "comctl32.lib")

int APIENTRY wWinMain(_In_     HINSTANCE hInstance,
                      _In_opt_ HINSTANCE /*hPrevInstance*/,
                      _In_     LPWSTR    /*lpCmdLine*/,
                      _In_     int       /*nShowCmd*/) {
    // Enables the modern (v6) common controls (themed buttons,
    // edits, etc.). Without this you get the Win95-era look even
    // on Windows 11 because the comctl32 v5 templates are linked
    // by default.
    INITCOMMONCONTROLSEX icc{};
    icc.dwSize = sizeof(icc);
    icc.dwICC  = ICC_STANDARD_CLASSES | ICC_WIN95_CLASSES;
    ::InitCommonControlsEx(&icc);

    MainWindow window(hInstance);
    return window.runModal();
}
