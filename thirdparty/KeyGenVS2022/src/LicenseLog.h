#pragma once

#include <QByteArray>
#include <QDateTime>
#include <QString>

// Append-only audit log of every license cert this tool issues.
//
// Today: writes a CSV next to the .lic/.png output so a single
// directory has all the artefacts an operator might need for
// review or recovery.
//
// Planned (see docs/0525/17_license_plan.md): also INSERT into the
// `vLearnLicense.generate_log` Postgres table. The hook lives in
// LicenseLog::appendToPg() -- it is wired through Qt SQL (QPSQL
// driver). Disabled until the connection string is configured via
// the LICENSE_DB_URL environment variable; falling back to CSV-only
// keeps the GUI usable on the operator's offline workstation.
class LicenseLog {
public:
    struct Entry {
        QString    serialHex;
        QString    machineId;
        QString    userName;
        QString    mode;       // "period" | "permanent"
        int        days = 0;
        QDateTime  notBefore;
        QDateTime  notAfter;
        QByteArray certDer;
        QString    operatorTag;
    };

    explicit LicenseLog(const QString& outputDir);

    // Appends `entry` to the local CSV (creating it with a header
    // row on first call). Also attempts a Postgres insert when
    // LICENSE_DB_URL is set in the environment. Returns true if the
    // local CSV append succeeded; a PG failure is reported via
    // `err` but does not fail the call -- the CSV is the source of
    // truth on the operator's workstation.
    bool append(const Entry& entry, QString* err);

    QString csvPath() const { return csvPath_; }

private:
    bool appendToCsv(const Entry& entry, QString* err);
    bool appendToPg(const Entry& entry, QString* err);

    QString csvPath_;
};
