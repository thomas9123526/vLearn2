#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <string>

// Top-level dialog for the license-key generator. Wraps the modal
// dialog defined in MainWindow.rc; the dialog proc lives in
// MainWindow.cpp and forwards to this object via DWLP_USER.
class MainWindow {
public:
    explicit MainWindow(HINSTANCE hInstance);

    // Shows the modal dialog and pumps its message loop. Returns
    // the exit code (currently always 0). Blocks until the user
    // closes the window.
    int runModal();

private:
    static INT_PTR CALLBACK staticProc(HWND hwnd, UINT msg,
                                       WPARAM wp, LPARAM lp);
    INT_PTR proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp);

    void onInit(HWND hwnd);
    void onBrowseLeafCert();
    void onBrowseLeafKey();
    void onBrowseOutputDir();
    void onGenerate();

    void restoreFields();
    void persistFields() const;

    // Appends a single ISO-timestamped line to the status edit
    // control. The newline is added by this function.
    void appendStatus(const std::string& utf8);

    std::wstring getEditText(int controlId) const;
    void         setEditText(int controlId, const std::wstring& s);

    HINSTANCE hInstance_;
    HWND      hwnd_ = nullptr;
};
