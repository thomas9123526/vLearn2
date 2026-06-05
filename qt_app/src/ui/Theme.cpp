#include "ui/Theme.h"

#include <QApplication>
#include <QFontDatabase>
#include <QLabel>
#include <QPalette>
#include <QStyleFactory>
#include <QSettings>

namespace Theme {

static QString g_display = "Georgia";
static QString g_ui      = "sans-serif";
static QString g_mono    = "monospace";

// Loaded font families (resolved after addApplicationFont).
static QString fLora, fInter, fJetBrains, fQuicksand, fNunito, fPlayfair, fSource;
static QString g_fontGroup   = "Editorial";
static QString g_bubbleStyle = "Classic";

static void applyStyle(QApplication& app);   // fwd

static Palette s_apricot, s_sage, s_iris, s_obsidian, s_current;
static QString s_name = "obsidian";
static QApplication* s_app = nullptr;
static bool s_built = false;

const Palette& palette() { return s_current; }
QString currentTheme()   { return s_name; }
bool    isDark()         { return s_name == QLatin1String("obsidian"); }

static QColor mix(const QColor& a, const QColor& b, double t)
{
    return QColor(int(a.red()   + (b.red()   - a.red())   * t),
                  int(a.green() + (b.green() - a.green()) * t),
                  int(a.blue()  + (b.blue()  - a.blue())  * t));
}

// Build a full Palette from the 12 core tokens (app_tokens.dart); derive the
// surfaceDeep / inkFaint / accentSoft helpers.
static Palette buildPalette(const char* primary, const char* primaryDark,
                            const char* accent, const char* bg, const char* surface,
                            const char* surfaceVariant, const char* onSurface,
                            const char* onSurfaceMuted, const char* outline,
                            const char* success, const char* warning, const char* error)
{
    Palette p;
    p.bg = QColor(bg); p.surface = QColor(surface); p.surfaceAlt = QColor(surfaceVariant);
    p.ink = QColor(onSurface); p.inkSoft = QColor(onSurfaceMuted); p.border = QColor(outline);
    p.accent = QColor(primary); p.accent2 = QColor(accent); p.accentInk = QColor(primaryDark);
    p.good = QColor(success); p.warn = QColor(warning); p.bad = QColor(error);
    p.surfaceDeep = mix(p.surfaceAlt, p.ink, 0.12);
    p.inkFaint    = mix(p.inkSoft, p.bg, 0.35);
    p.accentSoft  = mix(p.accent, p.surface, 0.80);
    return p;
}

static void buildPalettes()
{
    if (s_built) return; s_built = true;
    s_apricot  = buildPalette("#FF6B47","#E54D2A","#FFB997","#FFF8F4","#FFFFFF","#FFEFE5","#1B1B1F","#6B6B72","#E8E0D9","#5DBE9C","#FFB44C","#E5484D");
    s_sage     = buildPalette("#5DBE9C","#3FA37D","#A8E6CF","#F4FAF7","#FFFFFF","#E3F1EB","#1B1F1D","#626B66","#D9E8E1","#5DBE9C","#FFB44C","#E5484D");
    s_iris     = buildPalette("#7C6BE6","#5B4ECF","#C9B6FF","#F6F5FF","#FFFFFF","#EFEAFF","#1B1A24","#6B6878","#E2DEEF","#5DBE9C","#FFB44C","#E5484D");
    s_obsidian = buildPalette("#4F4C7E","#2C2A4A","#9D99C7","#121120","#1E1C2E","#26243A","#EFEEF5","#A8A6B8","#38364E","#5DBE9C","#FFB44C","#FF7177");
    s_current  = s_obsidian;
}

static const Palette& paletteByName(const QString& n)
{
    if (n == QLatin1String("apricot")) return s_apricot;
    if (n == QLatin1String("sage"))    return s_sage;
    if (n == QLatin1String("iris"))    return s_iris;
    return s_obsidian;
}

void setTheme(const QString& name)
{
    buildPalettes();
    s_name = name;
    s_current = paletteByName(name);
    if (s_app) applyStyle(*s_app);
}

QString currentFontGroup()   { return g_fontGroup; }
QString currentBubbleStyle() { return g_bubbleStyle; }

void setFontGroup(const QString& group)
{
    g_fontGroup = group;
    if (group == QLatin1String("Modern"))        { g_display = fInter;     g_ui = fInter;  g_mono = fJetBrains; }
    else if (group == QLatin1String("Friendly")) { g_display = fQuicksand; g_ui = fNunito; g_mono = fJetBrains; }
    else if (group == QLatin1String("Classic"))  { g_display = fPlayfair;  g_ui = fSource; g_mono = fJetBrains; }
    else /* Editorial */                         { g_display = fLora;      g_ui = fInter;  g_mono = fJetBrains; }
    QSettings().setValue("appearance/fontGroup", group);
    if (s_app) { s_app->setFont(QFont(g_ui, 10)); applyStyle(*s_app); }
}

void setBubbleStyle(const QString& style)
{
    g_bubbleStyle = style;
    QSettings().setValue("appearance/bubbleStyle", style);
}

// Per-style bubble stylesheet using the active palette. `mine` = the user's
// (right) bubble vs the tutor's (left).
QString bubbleStyleSheet(bool mine)
{
    const Palette& p = palette();
    const QString tutBg = p.surface.name(), meBg = p.accent.name();
    const QString border = rgba(p.border), ink = p.ink.name();
    auto base = [&](const QString& radius, const QString& extra) {
        return mine
            ? QStringLiteral("background:%1;border-radius:%2;padding:10px 14px;"
                             "font-size:15px;color:white;%3").arg(meBg, radius, extra)
            : QStringLiteral("background:%1;border:1px solid %2;border-radius:%3;"
                             "padding:10px 14px;font-size:15px;color:%4;%5")
                  .arg(tutBg, border, radius, ink, extra);
    };
    const QString s = g_bubbleStyle;
    if (s == QLatin1String("Modern"))   return base("10px", QString());
    if (s == QLatin1String("Soft"))     return base("22px", QString());
    if (s == QLatin1String("Notebook")) {
        // Squared, accent left rule.
        return mine
            ? QStringLiteral("background:%1;border-radius:6px;padding:10px 14px;font-size:15px;color:white;").arg(meBg)
            : QStringLiteral("background:%1;border:1px solid %2;border-left:3px solid %3;"
                             "border-radius:6px;padding:10px 14px;font-size:15px;color:%4;")
                  .arg(tutBg, border, p.accent2.name(), ink);
    }
    if (s == QLatin1String("Tail")) {
        // One squared bottom corner = a tail.
        const QString r = mine ? "18px 18px 4px 18px" : "18px 18px 18px 4px";
        return base(r, QString());
    }
    return base("18px", QString());   // Classic
}

QString fontDisplay() { return g_display; }
QString fontUi()      { return g_ui; }
QString fontMono()    { return g_mono; }

QString rgba(const QColor& c)
{
    return QStringLiteral("rgba(%1,%2,%3,%4)")
        .arg(c.red()).arg(c.green()).arg(c.blue())
        .arg(QString::number(c.alphaF(), 'f', 3));
}

QColor personaAccent(const QString& slugOrName)
{
    const QString s = slugOrName.toLower();
    if (s.contains("maya"))  return QColor("#D97757");
    if (s.contains("leo"))   return QColor("#4A6FA5");
    if (s.contains("sofia")) return QColor("#7E5AAF");
    if (s.contains("theo"))  return QColor("#5A8C6E");
    return palette().accent;
}

static QString loadFamily(const QString& resource, const QString& fallback)
{
    const int id = QFontDatabase::addApplicationFont(resource);
    if (id < 0) return fallback;
    const QStringList fams = QFontDatabase::applicationFontFamilies(id);
    return fams.isEmpty() ? fallback : fams.first();
}

QLabel* makeAvatar(const QString& name, int size, const QColor& accent)
{
    auto* a = new QLabel(name.left(1).toUpper());
    a->setFixedSize(size, size);
    a->setAlignment(Qt::AlignCenter);
    a->setStyleSheet(QStringLiteral(
        "QLabel{background:%1;color:white;border-radius:%2px;"
        "font-family:'%3';font-size:%4px;font-style:italic;}")
        .arg(accent.name())
        .arg(size / 2)
        .arg(fontDisplay())
        .arg(int(size * 0.46)));
    return a;
}

void install(QApplication& app)
{
    fLora      = loadFamily(":/fonts/Lora.ttf",            "Georgia");
    fInter     = loadFamily(":/fonts/Inter.ttf",           "sans-serif");
    fJetBrains = loadFamily(":/fonts/JetBrainsMono.ttf",   "monospace");
    fQuicksand = loadFamily(":/fonts/Quicksand.ttf",       "sans-serif");
    fNunito    = loadFamily(":/fonts/Nunito.ttf",          "sans-serif");
    fPlayfair  = loadFamily(":/fonts/PlayfairDisplay.ttf", "Georgia");
    fSource    = loadFamily(":/fonts/SourceSerif4.ttf",    "Georgia");

    s_app = &app;

    QSettings s;
    g_bubbleStyle = s.value("appearance/bubbleStyle", "Classic").toString();
    setFontGroup(s.value("appearance/fontGroup", "Editorial").toString());
    setTheme(s_name);   // builds palettes + applies QSS/QPalette
}

// Re-applies the active palette to the whole application (QPalette + global
// stylesheet). Runs on startup and on every theme change.
static void applyStyle(QApplication& app)
{
    const Palette& p = palette();

    // Fusion + the active palette so EVERY widget (incl. unstyled scroll
    // viewports, popups, dropdowns, message boxes) renders themed.
    app.setStyle(QStyleFactory::create("Fusion"));
    QPalette pal;
    pal.setColor(QPalette::Window,          p.bg);
    pal.setColor(QPalette::WindowText,      p.ink);
    pal.setColor(QPalette::Base,            p.surface);
    pal.setColor(QPalette::AlternateBase,   p.surfaceAlt);
    pal.setColor(QPalette::Text,            p.ink);
    pal.setColor(QPalette::PlaceholderText, p.inkSoft);
    pal.setColor(QPalette::Button,          p.surface);
    pal.setColor(QPalette::ButtonText,      p.ink);
    pal.setColor(QPalette::BrightText,      Qt::white);
    pal.setColor(QPalette::Highlight,       p.accent);
    pal.setColor(QPalette::HighlightedText, Qt::white);
    pal.setColor(QPalette::ToolTipBase,     p.surface);
    pal.setColor(QPalette::ToolTipText,     p.ink);
    pal.setColor(QPalette::Link,            p.accent2);
    pal.setColor(QPalette::Disabled, QPalette::Text,       p.inkFaint);
    pal.setColor(QPalette::Disabled, QPalette::WindowText, p.inkFaint);
    pal.setColor(QPalette::Disabled, QPalette::ButtonText, p.inkFaint);
    app.setPalette(pal);

    // Global stylesheet built from the Apricot tokens. Widgets opt into
    // specific looks via objectName (#Name) or dynamic property [variant="x"].
    const QString qss = QStringLiteral(R"(
        QWidget { color: %ink%; font-family: '%ui%'; font-size: 14px; }
        QMainWindow, QDialog, #Root { background: %bg%; }

        /* ---- Sidebar ---- */
        #Sidebar { background: %surfaceAlt%; border: none; }
        #Logo { font-family: '%display%'; font-size: 26px; color: %ink%; }
        #LogoAccent { font-family: '%display%'; font-size: 26px; font-style: italic; color: %accent%; }
        QPushButton#NavItem {
            text-align: left; padding: 10px 14px; border: none; border-radius: 12px;
            color: %inkSoft%; font-size: 14px; font-weight: 600; background: transparent;
        }
        QPushButton#NavItem:hover   { background: %surfaceDeep%; }
        QPushButton#NavItem:checked { background: %surface%; color: %ink%; }

        /* ---- Buttons ---- */
        QPushButton[variant="primary"] {
            background: %accent%; color: white; border: none; border-radius: 12px;
            padding: 10px 18px; font-weight: 700;
        }
        QPushButton[variant="primary"]:hover    { background: %accentInk%; }
        QPushButton[variant="primary"]:disabled { background: %inkFaint%; }
        QPushButton[variant="ghost"] {
            background: transparent; color: %inkSoft%; border: 1px solid %border%;
            border-radius: 12px; padding: 8px 14px; font-weight: 600;
        }
        QPushButton[variant="ghost"]:hover { background: %surfaceAlt%; }

        /* ---- Cards / panels ---- */
        #Card, #Header, #InputBar {
            background: %surface%; border: 1px solid %border%; border-radius: 18px;
        }
        #Header { border-radius: 0; border-left: none; border-right: none; border-top: none; }

        /* ---- Inputs ---- */
        QLineEdit {
            background: %surface%; border: 1px solid %border%; border-radius: 999px;
            padding: 10px 16px; font-size: 14px; selection-background-color: %accent%;
        }
        QLineEdit:focus { border: 1px solid %accent%; }

        /* ---- Chat bubbles ---- */
        QLabel#BubbleTutor {
            background: %surface%; border: 1px solid %border%; border-radius: 18px;
            padding: 10px 14px; font-size: 15px; color: %ink%;
        }
        QLabel#BubbleMe {
            background: %accent%; border-radius: 18px; padding: 10px 14px;
            font-size: 15px; color: white;
        }

        /* ---- Misc ---- */
        QLabel#Kicker { color: %inkFaint%; font-family: '%mono%'; font-size: 11px; letter-spacing: 1px; }
        QLabel#H1 { font-family: '%display%'; font-size: 30px; color: %ink%; }
        QLabel#Sub { color: %inkSoft%; font-size: 13px; }
        QLabel#DatePill {
            background: %surfaceAlt%; color: %inkSoft%; border-radius: 999px;
            padding: 4px 12px; font-family: '%mono%'; font-size: 11px;
        }
        QPushButton[variant="chip"] {
            background: %surfaceAlt%; color: %ink%; border: none;
            border-radius: 999px; padding: 7px 14px; font-size: 13px; font-weight: 600;
        }
        QPushButton[variant="chip"]:hover   { background: %surfaceDeep%; }
        QPushButton[variant="chip"]:checked { background: %accent%; color: white; }
        QPushButton#SendBtn {
            background: %accent%; color: white; border: none; border-radius: 22px;
            min-width: 44px; min-height: 44px; font-size: 18px; font-weight: 700;
        }
        QPushButton#SendBtn:hover    { background: %accentInk%; }
        QPushButton#SendBtn:disabled { background: %inkFaint%; }
        QPushButton#MicBtn {
            background: %surfaceAlt%; color: %ink%; border: none; border-radius: 22px;
            min-width: 44px; min-height: 44px; font-size: 16px;
        }
        QPushButton#MicBtn:hover    { background: %surfaceDeep%; }
        QPushButton#MicBtn:disabled { color: %inkFaint%; }
        QPushButton#MicBtn[rec="true"] { background: %bad%; color: white; }
        QScrollArea, #Transcript { background: %bg%; border: none; }
        QStatusBar { color: %inkSoft%; }
        QListWidget { background: %surface%; border: 1px solid %border%; border-radius: 14px; }
        QListWidget::item { padding: 12px; border-bottom: 1px solid %border%; }
        QListWidget::item:selected { background: %accentSoft%; color: %ink%; }

        /* ---- Home: hero / streak-xp card ---- */
        #HeroCard {
            border: none; border-radius: 16px;
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                        stop:0 %accent%, stop:1 %accent2%);
        }
        #HeroBig   { color: white; font-size: 22px; font-weight: 700; }
        #HeroSmall { color: rgba(255,255,255,0.85); font-size: 12px; }
        #HeroXp    { color: white; font-family: '%mono%'; font-size: 16px; font-weight: 700; }
        QProgressBar {
            background: rgba(255,255,255,0.20); border: none; border-radius: 5px;
            min-height: 8px; max-height: 8px; text-align: center;
        }
        QProgressBar::chunk { background: white; border-radius: 5px; }

        /* ---- Home: stat cards ---- */
        #StatCard {
            background: %surface%; border: 1px solid %border%; border-radius: 16px;
        }
        #StatNum  { font-size: 26px; font-weight: 700; color: %ink%; }
        #StatLbl  { color: %inkSoft%; font-size: 12px; }
        #StatIcon { color: %accent2%; font-size: 18px; }

        /* ---- Scenario cards ---- */
        #ScenarioCard {
            background: %surface%; border: 1px solid rgba(157,153,199,0.35);
            border-radius: 16px;
        }
        #ScenarioCard:hover { border: 1px solid %accent2%; background: %surfaceAlt%; }
        #ScenarioTitle { font-size: 15px; font-weight: 600; color: %ink%; }
        #ScenarioMeta  { color: %inkSoft%; font-family: '%mono%'; font-size: 11px; }
        QLabel#CatChip {
            background: %surfaceDeep%; color: %accentInk%; border-radius: 999px;
            padding: 3px 10px; font-size: 10px; font-weight: 700;
        }

        /* ---- Scrollbars ---- */
        QScrollBar:vertical { background: transparent; width: 10px; margin: 2px; }
        QScrollBar::handle:vertical { background: %border%; border-radius: 5px; min-height: 30px; }
        QScrollBar::handle:vertical:hover { background: %inkFaint%; }
        QScrollBar::add-line, QScrollBar::sub-line { height: 0; }
        QScrollBar:horizontal { background: transparent; height: 10px; margin: 2px; }
        QScrollBar::handle:horizontal { background: %border%; border-radius: 5px; min-width: 30px; }
    )");

    QString out = qss;
    out.replace("%bg%",          p.bg.name());
    out.replace("%surface%",     p.surface.name());
    out.replace("%surfaceAlt%",  p.surfaceAlt.name());
    out.replace("%surfaceDeep%", p.surfaceDeep.name());
    out.replace("%ink%",         p.ink.name());
    out.replace("%inkSoft%",     p.inkSoft.name());
    out.replace("%inkFaint%",    p.inkFaint.name());
    out.replace("%border%",      rgba(p.border));
    out.replace("%accent%",      p.accent.name());
    out.replace("%accent2%",     p.accent2.name());
    out.replace("%accentSoft%",  p.accentSoft.name());
    out.replace("%accentInk%",   p.accentInk.name());
    out.replace("%display%",     g_display);
    out.replace("%ui%",          g_ui);
    out.replace("%mono%",        g_mono);

    app.setStyleSheet(out);
}

}  // namespace Theme
