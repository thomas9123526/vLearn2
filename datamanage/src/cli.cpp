#include "cli.h"

#include <cstdio>
#include <stdexcept>
#include <string>
#include <string_view>

namespace datamanage {

namespace {

void printUsage() {
    std::puts(
        "DataManage 0.1.0 — pack files for the Flutter app\n"
        "\n"
        "Usage:\n"
        "  DataManage pack [--config <config.json>]   build .ddp bundles\n"
        "  DataManage verify <pack.ddp>               verify signature + hashes\n"
        "  DataManage info <pack.ddp>                 print manifest\n"
        "  DataManage --help                          show this help\n"
        "\n"
        "Stage 1 build: CLI skeleton only. Packing / signing / encryption\n"
        "land in subsequent stages. See README.md for the project plan.\n"
    );
}

bool isFlag(std::string_view a, std::string_view name) {
    return a == name;
}

}  // namespace

CliCommand parseCli(int argc, char** argv) {
    CliCommand cmd;
    if (argc < 2) return cmd;  // defaults to Help

    const std::string sub = argv[1];

    if (isFlag(sub, "--help") || isFlag(sub, "-h") || isFlag(sub, "help")) {
        return cmd;
    }

    if (sub == "pack") {
        cmd.command = Command::Pack;
        cmd.configPath = "config.json";  // default
        for (int i = 2; i < argc; ++i) {
            const std::string a = argv[i];
            if (a == "--config" && i + 1 < argc) {
                cmd.configPath = argv[++i];
            } else {
                throw std::runtime_error("unknown argument to `pack`: " + a);
            }
        }
        return cmd;
    }

    if (sub == "verify") {
        cmd.command = Command::Verify;
        if (argc < 3) throw std::runtime_error("`verify` needs a pack path");
        cmd.packPath = argv[2];
        return cmd;
    }

    if (sub == "info") {
        cmd.command = Command::Info;
        if (argc < 3) throw std::runtime_error("`info` needs a pack path");
        cmd.packPath = argv[2];
        return cmd;
    }

    throw std::runtime_error("unknown command: " + sub);
}

int run(const CliCommand& cmd) {
    switch (cmd.command) {
        case Command::Help:
            printUsage();
            return 0;
        case Command::Pack:
            std::printf("[pack]   config=%s\n", cmd.configPath.c_str());
            std::puts("[pack]   not implemented yet — arriving in Stage 3");
            return 0;
        case Command::Verify:
            std::printf("[verify] pack=%s\n", cmd.packPath.c_str());
            std::puts("[verify] not implemented yet — arriving in Stage 6");
            return 0;
        case Command::Info:
            std::printf("[info]   pack=%s\n", cmd.packPath.c_str());
            std::puts("[info]   not implemented yet — arriving in Stage 3");
            return 0;
    }
    return 0;
}

}  // namespace datamanage
