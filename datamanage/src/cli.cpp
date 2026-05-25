#include "cli.h"

#include <cstdio>
#include <stdexcept>
#include <string>
#include <string_view>

#include "config.h"
#include "packer.h"

namespace datamanage {

namespace {

void printUsage() {
    std::puts(
        "DataManage 0.1.0 — pack files for the Flutter app\n"
        "\n"
        "Usage:\n"
        "  DataManage pack [--config <config.json>]   build .dat bundles\n"
        "  DataManage verify <pack.dat>               verify signature + hashes\n"
        "  DataManage info <pack.dat>                 print manifest\n"
        "  DataManage --help                          show this help\n"
        "\n"
        "Stage 3 build: `pack` works against config.json. `info` and `verify`\n"
        "land in later stages. See README.md for the project plan.\n"
    );
}

bool isFlag(std::string_view a, std::string_view name) {
    return a == name;
}

int runPack(const CliCommand& cmd) {
    const Config cfg = loadConfig(cmd.configPath);
    std::printf("[pack] config=%s\n", cmd.configPath.c_str());
    std::printf("[pack] bundles=%zu output_dir=%s\n",
                cfg.bundles.size(), cfg.output_dir.c_str());

    const auto results = packAll(cfg, [](const std::string& rel,
                                          uint64_t done,
                                          uint64_t total) {
        if (rel.empty()) {
            std::printf("[pack]   (%llu / %llu) done\n",
                        static_cast<unsigned long long>(done),
                        static_cast<unsigned long long>(total));
        } else {
            std::printf("[pack]   (%llu / %llu) %s\n",
                        static_cast<unsigned long long>(done + 1),
                        static_cast<unsigned long long>(total),
                        rel.c_str());
        }
    });

    for (const auto& r : results) {
        std::printf("[pack] wrote %s — %llu files, %llu bytes in → "
                    "%llu bytes out\n",
                    r.output_path.c_str(),
                    static_cast<unsigned long long>(r.file_count),
                    static_cast<unsigned long long>(r.total_bytes_in),
                    static_cast<unsigned long long>(r.total_bytes_out));
    }
    return 0;
}

}  // namespace

CliCommand parseCli(int argc, char** argv) {
    CliCommand cmd;
    if (argc < 2) return cmd;

    const std::string sub = argv[1];

    if (isFlag(sub, "--help") || isFlag(sub, "-h") || isFlag(sub, "help")) {
        return cmd;
    }

    if (sub == "pack") {
        cmd.command = Command::Pack;
        cmd.configPath = "config.json";
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
            return runPack(cmd);
        case Command::Verify:
            std::printf("[verify] pack=%s\n", cmd.packPath.c_str());
            std::puts("[verify] not implemented yet — arriving in Stage 6");
            return 0;
        case Command::Info:
            std::printf("[info]   pack=%s\n", cmd.packPath.c_str());
            std::puts("[info]   not implemented yet — arriving in Stage 4");
            return 0;
    }
    return 0;
}

}  // namespace datamanage
