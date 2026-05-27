#include "devid.h"

#include <fstream>
#include <string>

namespace vlearn2 {
namespace devid {

namespace {

/// In-place trim of leading/trailing whitespace and CR/LF.
void trim(std::string& s) {
    const auto first = s.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        s.clear();
        return;
    }
    const auto last = s.find_last_not_of(" \t\r\n");
    s = s.substr(first, last - first + 1);
}

} // namespace

std::string read_cpu_serial() {
    std::ifstream f("/proc/cpuinfo");
    if (!f.is_open()) {
        return {};
    }
    // Format we're after:   `Serial          : 1234567890abcdef`
    // Some kernels (older ARM) emit lowercase `serial`; match both.
    std::string line;
    while (std::getline(f, line)) {
        if (line.size() < 7) continue;
        const bool starts_with_serial =
            (line.compare(0, 6, "Serial") == 0) ||
            (line.compare(0, 6, "serial") == 0);
        if (!starts_with_serial) continue;

        const auto colon = line.find(':');
        if (colon == std::string::npos) continue;
        std::string value = line.substr(colon + 1);
        trim(value);
        return value;
    }
    return {};
}

} // namespace devid
} // namespace vlearn2
