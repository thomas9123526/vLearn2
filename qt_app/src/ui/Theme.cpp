#include "ui/Theme.h"

#include <QApplication>
#include <QFontDatabase>
#include <QLabel>

namespace Theme {

static QString g_display = "Georgia";
static QString g_ui      = "sans-serif";
static QString g_mono    = "monospace";

const Palette& palette()
{
    static const Palette p;
    return p;
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
    g_display = loadFamily(":/fonts/Lora.ttf",          "Georgia");
    g_ui      = loadFamily(":/fonts/Inter.ttf",         "sans-serif");
    g_mono    = loadFamily(":/fonts/JetBrainsMono.ttf", "monospace");

    QFont base(g_ui, 10);
    app.setFont(base);

    const Palette& p = palette();

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
            background: %surface%; color: %inkSoft%; border: 1px solid %border%;
            border-radius: 999px; padding: 6px 12px; font-size: 12px; font-weight: 600;
        }
        QPushButton[variant="chip"]:hover { background: %accentSoft%; color: %accentInk%; }
        QPushButton#SendBtn {
            background: %accent%; color: white; border: none; border-radius: 22px;
            min-width: 44px; min-height: 44px; font-size: 18px; font-weight: 700;
        }
        QPushButton#SendBtn:hover    { background: %accentInk%; }
        QPushButton#SendBtn:disabled { background: %inkFaint%; }
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
            background: %surface%; border: 1px solid %border%; border-radius: 16px;
        }
        #ScenarioCard:hover { border: 1px solid %accent2%; }
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
