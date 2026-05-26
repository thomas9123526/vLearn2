#include "LicenseLog.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QTextStream>
#include <QUrl>
#include <QUuid>

namespace {

// Quotes a CSV field per RFC 4180: wrap in quotes, double-up any
// internal quotes. Applied to every text field so a stray comma or
// quote in a username does not break the CSV.
QString csvQuote(const QString& s) {
    QString out = s;
    out.replace(QLatin1Char('"'), QLatin1String("\"\""));
    return QStringLiteral("\"%1\"").arg(out);
}

}  // namespace

LicenseLog::LicenseLog(const QString& outputDir)
    : csvPath_(QDir(outputDir).filePath(QStringLiteral("generate_log.csv"))) {}

bool LicenseLog::append(const Entry& entry, QString* err) {
    QString csvErr;
    const bool csvOk = appendToCsv(entry, &csvErr);
    if (!csvOk) {
        if (err) *err = csvErr;
        return false;
    }

    // Postgres is best-effort -- if it fails we keep the CSV success.
    // The operator can re-import the CSV later.
    QString pgErr;
    if (!appendToPg(entry, &pgErr) && !pgErr.isEmpty() && err) {
        *err = QStringLiteral("CSV written, PG insert failed: %1").arg(pgErr);
    }
    return true;
}

bool LicenseLog::appendToCsv(const Entry& entry, QString* err) {
    QFileInfo info(csvPath_);
    QDir().mkpath(info.absolutePath());
    const bool needHeader = !info.exists();

    QFile f(csvPath_);
    if (!f.open(QIODevice::Append | QIODevice::Text)) {
        if (err) *err = QStringLiteral("Cannot open %1: %2")
                            .arg(csvPath_, f.errorString());
        return false;
    }
    QTextStream out(&f);
    out.setCodec("UTF-8");

    if (needHeader) {
        out << "generated_at,serial_hex,machine_id,user_name,mode,days,"
               "not_before,not_after,cert_der_base64,operator\n";
    }
    out << csvQuote(QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)) << ','
        << csvQuote(entry.serialHex) << ','
        << csvQuote(entry.machineId) << ','
        << csvQuote(entry.userName) << ','
        << csvQuote(entry.mode) << ','
        << entry.days << ','
        << csvQuote(entry.notBefore.toUTC().toString(Qt::ISODateWithMs)) << ','
        << csvQuote(entry.notAfter.toUTC().toString(Qt::ISODateWithMs)) << ','
        << csvQuote(QString::fromLatin1(entry.certDer.toBase64())) << ','
        << csvQuote(entry.operatorTag) << '\n';
    return true;
}

bool LicenseLog::appendToPg(const Entry& entry, QString* err) {
    // Environment-gated -- silent no-op on offline workstations.
    const QByteArray rawUrl = qgetenv("LICENSE_DB_URL");
    if (rawUrl.isEmpty()) {
        return true;
    }

    const QUrl url = QUrl::fromUserInfo(QString::fromUtf8(rawUrl));
    if (!url.isValid()) {
        if (err) *err = QStringLiteral("LICENSE_DB_URL is not a valid URL");
        return false;
    }

    // Each call uses its own anonymous connection so the function
    // is reentrant and we don't leak driver state between issuances.
    const QString connectionName =
        QStringLiteral("kgen-%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(
            QStringLiteral("QPSQL"), connectionName);
        db.setHostName(url.host());
        db.setPort(url.port(5432));
        db.setUserName(url.userName());
        db.setPassword(url.password());
        // path() includes the leading '/', strip it for the DB name.
        QString dbName = url.path();
        if (dbName.startsWith(QLatin1Char('/'))) dbName.remove(0, 1);
        db.setDatabaseName(dbName);

        if (!db.open()) {
            if (err) *err = db.lastError().text();
            QSqlDatabase::removeDatabase(connectionName);
            return false;
        }

        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "INSERT INTO generate_log "
            "(serial, machine_id, user_name, mode, days, "
            " not_before, not_after, operator, cert_der) "
            "VALUES (:serial, :machine_id, :user_name, :mode, :days, "
            " :not_before, :not_after, :operator, :cert_der)"));
        q.bindValue(":serial",     entry.serialHex);
        q.bindValue(":machine_id", entry.machineId);
        q.bindValue(":user_name",  entry.userName);
        q.bindValue(":mode",       entry.mode);
        q.bindValue(":days",       entry.days);
        q.bindValue(":not_before", entry.notBefore.toUTC());
        q.bindValue(":not_after",  entry.notAfter.toUTC());
        q.bindValue(":operator",   entry.operatorTag);
        q.bindValue(":cert_der",   entry.certDer);
        if (!q.exec()) {
            if (err) *err = q.lastError().text();
            db.close();
            QSqlDatabase::removeDatabase(connectionName);
            return false;
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connectionName);
    return true;
}
