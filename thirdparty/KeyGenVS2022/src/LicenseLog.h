#pragma once

#include <ctime>
#include <string>
#include <vector>

// Append-only audit log of every license cert this tool issues.
// Writes a CSV next to the .lic/.png output so a single directory
// has all the artefacts an operator might need for review or
// recovery.
//
// The original Qt version also did a best-effort Postgres INSERT
// when LICENSE_DB_URL was set. The Win32 port drops that path --
// QSqlDatabase/QPSQL was the only DB client we shipped, and CSV is
// the source of truth on the operator's workstation. Re-importing
// the CSV into Postgres is a one-line `\copy`.
class LicenseLog {
public:
    struct Entry {
        std::string                serialHex;
        std::string                machineId;
        std::string                userName;
        std::string                mode;       // "period" | "permanent"
        int                        days = 0;
        std::time_t                notBefore = 0;
        std::time_t                notAfter  = 0;
        std::vector<unsigned char> certDer;
        std::string                operatorTag;
    };

    explicit LicenseLog(const std::wstring& outputDir);

    // Appends `entry` to the local CSV (creating it with a header
    // row on first call). Returns true on success; on failure
    // writes a UTF-8 reason into `err`.
    bool append(const Entry& entry, std::string* err);

    std::wstring csvPath() const { return csvPath_; }

private:
    std::wstring csvPath_;
};
