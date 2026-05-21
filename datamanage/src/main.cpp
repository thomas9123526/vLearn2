// DataManage — Windows 10 / VS 2022 C++ CLI that packs directories of
// files into signed, optionally encrypted, optionally compressed bundles
// (.ddp) that the Flutter app verifies and unpacks at runtime.
//
// Stage 1 of 9 lands the project scaffold: CMake build, CLI argument
// parsing, "what it would do" output. Real packing / signing / encryption
// arrives in Stages 3 through 7. See README.md for the full roadmap.

#include <cstdio>
#include <exception>

#include "cli.h"

#ifdef _WIN32
#include <Windows.h>
#endif

int main(int argc, char** argv) {
#ifdef _WIN32
    // The console renders UTF-8 strings (paths, manifest entries) only
    // when its output code page is set explicitly. The /utf-8 compile
    // flag handles the source side; this handles the runtime side.
    SetConsoleOutputCP(CP_UTF8);
#endif

    try {
        const auto cmd = datamanage::parseCli(argc, argv);
        return datamanage::run(cmd);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "error: %s\n", e.what());
        std::fprintf(stderr, "run `DataManage --help` for usage\n");
        return 1;
    }
}
