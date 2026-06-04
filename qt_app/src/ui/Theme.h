#pragma once

#include <QColor>
#include <QString>

class QApplication;
class QWidget;
class QLabel;

// FreeTalk "Apricot" design tokens (see vLearn2Spec/design_handoff_freetalk/
// tokens.json) expressed for Qt, plus global font + stylesheet installation.
namespace Theme {

struct Palette {
    QColor bg          {"#FAF6EF"};
    QColor surface     {"#FFFFFF"};
    QColor surfaceAlt  {"#F2EADA"};
    QColor surfaceDeep {"#E8DCC4"};
    QColor ink         {"#2A1D12"};
    QColor inkSoft     {"#6C5641"};
    QColor inkFaint    {"#A8917B"};
    QColor border      {0x46, 0x30, 0x16, 0x22};  // #463016 @ low alpha
    QColor accent      {"#D4633A"};
    QColor accent2     {"#7D8C52"};
    QColor accentSoft  {"#FBE1D1"};
    QColor accentInk   {"#6E2911"};
    QColor good        {"#5E8A4A"};
    QColor warn        {"#C89035"};
    QColor bad         {"#B94A3A"};
};

const Palette& palette();

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
