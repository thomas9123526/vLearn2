#pragma once

#include <QString>

class QApplication;

// Lightweight runtime UI translation. A QTranslator subclass consults a
// per-language map keyed by the English source string, so existing tr() calls
// translate automatically. Strings not in the map fall back to English.
// Languages: en (default) | ko | zh.
namespace I18n {
void    install(QApplication& app);     // install the translator once at startup
void    setLanguage(const QString& code);
QString currentLanguage();              // "en" | "ko" | "zh"
}
