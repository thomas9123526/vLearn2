// DataManage — Windows 10 GUI tool that packs directories of files
// into signed, optionally encrypted, optionally compressed bundles
// (.ddp) consumed by the Flutter app.
//
// The .exe is built with the WIN32 subsystem (no console window pops
// up on launch). Two modes:
//   1. GUI  (no args)            → runGui() opens the main window.
//   2. CLI  (any positional arg) → parseCli() + run() against the
//                                  parent console attached via
//                                  AttachConsole(ATTACH_PARENT_PROCESS).
//
// Stage 1: GUI + CLI both reach a "what they'd do" stub. Real packing
// arrives in Stage 3+ — see README.md for the roadmap.

#include <Windows.h>
#include <shellapi.h>  // CommandLineToArgvW — excluded by WIN32_LEAN_AND_MEAN

#include <cstdio>
#include <exception>
#include <string>
#include <vector>

#include "app.h"
#include "cli.h"

namespace {

// Convert a wide command-line argument to UTF-8. The existing CLI parser
// (cli.cpp) is happy taking char*; we route both subsystems through it.
std::string wideToUtf8(const wchar_t* w) {
    if (!w) return {};
    const int len = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0,
                                        nullptr, nullptr);
    if (len <= 1) return {};
    std::string out(static_cast<size_t>(len - 1), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, out.data(), len, nullptr,
                        nullptr);
    return out;
}

// CLI mode runs in a WIN32-subsystem .exe, so by default there's no
// stdout/stderr. AttachConsole hooks us up to the parent shell's
// console if there is one (PowerShell, cmd.exe, Developer prompt);
// otherwise CLI output is silently dropped. AllocConsole would pop up
// a new console window, which we don't want — better to fail quiet
// than pop a window the user didn't ask for.
void attachToParentConsole() {
    if (!AttachConsole(ATTACH_PARENT_PROCESS)) return;
    FILE* dummy = nullptr;
    freopen_s(&dummy, "CONOUT$", "w", stdout);
    freopen_s(&dummy, "CONOUT$", "w", stderr);
    freopen_s(&dummy, "CONIN$",  "r", stdin);
    // Make CLI output unbuffered so the shell sees it even though we
    // never call exit() through the CRT's normal teardown path (the
    // WIN32 subsystem doesn't flush stdio on return the way CONSOLE
    // subsystem does).
    std::setvbuf(stdout, nullptr, _IONBF, 0);
    std::setvbuf(stderr, nullptr, _IONBF, 0);
    // Newline so the first line of output doesn't crash into the
    // shell's prompt that's still on the previous line.
    std::printf("\n");
}

}  // namespace

int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE, LPWSTR, int) {
    int wargc = 0;
    LPWSTR* wargv = CommandLineToArgvW(GetCommandLineW(), &wargc);

    // No extra args → GUI mode. Launches the main window and runs
    // until WM_QUIT; the message-loop result becomes the exit code.
    if (wargc < 2) {
        if (wargv) LocalFree(wargv);
        return datamanage::runGui(hInstance);
    }

    // CLI mode. Convert wide argv → UTF-8 char* argv so the existing
    // CLI parser doesn't need a wide-character variant. An optional
    // leading `--no-gui` is accepted but redundant — any positional
    // argument already implies CLI mode.
    std::vector<std::string> args;
    args.reserve(static_cast<size_t>(wargc));
    for (int i = 0; i < wargc; ++i) args.push_back(wideToUtf8(wargv[i]));
    if (wargv) LocalFree(wargv);

    std::vector<char*> argv_utf8;
    argv_utf8.reserve(args.size());
    for (size_t i = 0; i < args.size(); ++i) {
        if (i > 0 && args[i] == "--no-gui") continue;
        argv_utf8.push_back(args[i].data());
    }

    attachToParentConsole();

    try {
        const auto cmd = datamanage::parseCli(
            static_cast<int>(argv_utf8.size()), argv_utf8.data());
        return datamanage::run(cmd);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "error: %s\n", e.what());
        std::fprintf(stderr, "run `DataManage --help` for usage\n");
        return 1;
    }
}
