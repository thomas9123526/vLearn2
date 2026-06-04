#pragma once

#include <QString>
#include <QStringList>

// Runtime configuration loaded from app_config.json BEFORE any network call.
//
// JSON shape:
//   { "baseUrl": "http://192.168.135.30:5101/api" }
//
// Search order (first file that exists wins):
//   1. an explicit path (e.g. from --config)
//   2. <executable dir>/app_config.json
//   3. ./app_config.json  (current working directory)
struct AppConfig {
    QString baseUrl;
    QString sourcePath;        // where it was actually loaded from
    bool    loaded = false;    // a file was found and parsed
    QString error;             // human-readable reason when !loaded or baseUrl empty

    bool isValid() const { return loaded && !baseUrl.isEmpty(); }

    // Returns the candidate paths that were searched (for diagnostics).
    static QStringList searchPaths(const QString& explicitPath);

    static AppConfig load(const QString& explicitPath = QString());
};
