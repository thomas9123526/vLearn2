#include "config/AppConfig.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>

QStringList AppConfig::searchPaths(const QString& explicitPath)
{
    QStringList paths;
    if (!explicitPath.isEmpty())
        paths << explicitPath;
    paths << QDir(QCoreApplication::applicationDirPath()).filePath("app_config.json");
    paths << QDir::current().filePath("app_config.json");
    paths.removeDuplicates();
    return paths;
}

AppConfig AppConfig::load(const QString& explicitPath)
{
    AppConfig cfg;

    QString path;
    for (const QString& candidate : searchPaths(explicitPath)) {
        if (QFileInfo::exists(candidate)) { path = candidate; break; }
    }

    if (path.isEmpty()) {
        cfg.error = QStringLiteral(
            "app_config.json not found. Looked in:\n  - %1")
            .arg(searchPaths(explicitPath).join("\n  - "));
        return cfg;
    }

    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        cfg.error = QStringLiteral("Cannot open %1: %2").arg(path, f.errorString());
        return cfg;
    }

    QJsonParseError perr;
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &perr);
    if (perr.error != QJsonParseError::NoError || !doc.isObject()) {
        cfg.error = QStringLiteral("%1 is not valid JSON: %2")
                        .arg(path, perr.errorString());
        return cfg;
    }

    const QJsonObject o = doc.object();
    // Accept "baseUrl" (preferred) or "baseurl" (matches the Flutter config).
    cfg.baseUrl = o.value("baseUrl").toString(o.value("baseurl").toString());
    cfg.sourcePath = path;
    cfg.loaded = true;

    if (cfg.baseUrl.isEmpty())
        cfg.error = QStringLiteral("%1 has no \"baseUrl\" field.").arg(path);

    return cfg;
}
