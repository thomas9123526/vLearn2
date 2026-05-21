// CLI for DataManage. Stage 1: parses subcommands but does no real work
// yet — `pack`, `verify`, and `info` print what they'd do and exit. Real
// behaviour lands as Stages 3+ fill in.

#pragma once

#include <string>

namespace datamanage {

enum class Command {
    Help,    // --help / -h / no args
    Pack,    // build .ddp bundles from config.json
    Verify,  // verify signature + per-file hashes of a .ddp
    Info,    // dump manifest of a .ddp to stdout
};

struct CliCommand {
    Command command = Command::Help;
    std::string configPath;  // valid for Pack
    std::string packPath;    // valid for Verify / Info
};

// Parses argv. Throws std::runtime_error with a message suitable for
// stderr on malformed input.
CliCommand parseCli(int argc, char** argv);

// Dispatches to the command implementation. Returns the process exit
// code (0 on success).
int run(const CliCommand& cmd);

}  // namespace datamanage
