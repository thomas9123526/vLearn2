#pragma once

#include <string>

namespace vlearn2 {
namespace devid {

/// Reads the `Serial` line from `/proc/cpuinfo` and returns its
/// trimmed value. Returns an empty string when:
///   * `/proc/cpuinfo` cannot be opened (SELinux denial in a
///     locked-down profile);
///   * no `Serial` line is present (vanilla AOSP on most modern
///     devices strips it for privacy reasons).
///
/// Never throws.
std::string read_cpu_serial();

} // namespace devid
} // namespace vlearn2
