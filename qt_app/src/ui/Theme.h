#pragma once

#include <QColor>
#include <QString>

class QApplication;
class QWidget;
class QLabel;

// FreeTalk "Apricot" design tokens (see vLearn2Spec/design_handoff_freetalk/
// tokens.json) expressed for Qt, plus global font + stylesheet installation.
namespace Theme {

// Obsidian (dark navy + periwinkle) — the theme the running VFLS app uses.
// Values from flutter_app/lib/core/theme/app_tokens.dart.
struct Palette {
    QColor bg          {"#121120"};   // background
    QColor surface     {"#1E1C2E"};   // cards / panels
    QColor surfaceAlt  {"#26243A"};   // inputs / elevated (surfaceVariant)
    QColor surfaceDeep {"#2C2A4A"};   // primaryDark / chip hover
    QColor ink         {"#EFEEEF"};   // onSurface (primary text)
    QColor inkSoft     {"#A8A6B8"};   // onSurfaceMuted (secondary text)
    QColor inkFaint    {"#6E6C82"};   // faint
    QColor border      {"#38364E"};   // outline
    QColor accent      {"#4F4C7E"};   // primary (buttons, selected nav)
    QColor accent2     {"#9D99C7"};   // periwinkle (gradient end, highlights)
    QColor accentSoft  {"#2C2A4A"};   // soft fill for chips
    QColor accentInk   {"#C9C6E0"};   // light periwinkle text
    QColor good        {"#5DBE9C"};   // success
    QColor warn        {"#FFBB4C"};   // warning
    QColor bad         {"#FF7177"};   // error
};

const Palette& palette();

// Active theme switching. Themes: apricot | sage | iris | obsidian.
void    setTheme(const QString& name);   // re-applies QSS + QPalette live
QString currentTheme();
bool    isDark();

// Font group: Editorial | Modern | Friendly | Classic. Persisted (QSettings).
void    setFontGroup(const QString& group);
QString currentFontGroup();

// Chat bubble style: Classic | Modern | Tail | Soft | Notebook. Persisted.
void    setBubbleStyle(const QString& style);
QString currentBubbleStyle();
// Stylesheet for one bubble in the active style (uses the active palette).
QString bubbleStyleSheet(bool mine);

// Font family names resolved after loading the bundled TTFs (falls back to
// Georgia / sans-serif / monospace if a face fails to load).
QString fontDisplay();   // Lora     — headings, hero
QString fontUi();        // Inter    — body, buttons, labels
QString fontMono();      // JetBrains Mono — numbers, timestamps

// Accent color for a persona, matched by slug/name (maya/leo/sofia/theo).
QColor personaAccent(const QString& slugOrName);

// Loads fonts and applies the global stylesheet to the application.
void install(QApplication& app);

// Helpers -----------------------------------------------------------------

// rgba(...) string for use inside stylesheets (preserves alpha).
QString rgba(const QColor& c);

// Builds a round monogram avatar label (persona initial on accent fill).
QLabel* makeAvatar(const QString& name, int size, const QColor& accent);

}  // namespace Theme
