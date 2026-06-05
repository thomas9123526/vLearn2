#include "shell/MainShell.h"
#include "api/ApiClient.h"
#include "home/HomePage.h"
#include "scenarios/ScenariosPage.h"
#include "scenarios/ScenarioBriefPage.h"
#include "progress/ProgressPage.h"
#include "chat/HistoryPage.h"
#include "chat/ChatPage.h"
#include "settings/SettingsPage.h"
#include "ui/Theme.h"

#include <QWidget>
#include <QFrame>
#include <QStackedWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QButtonGroup>
#include <QVariant>
#include <QLabel>
#include <QStatusBar>
#include <QJsonObject>

enum { PageHome = 0, PageScenarios, PageHistory, PageProgress, PageSettings, PageChat, PageBrief };

MainShell::MainShell(ApiClient* api, QWidget* parent)
    : QMainWindow(parent)
    , m_api(api)
{
    setWindowTitle(tr("Virtual Foreign Language"));
    resize(1120, 720);

    // ---- Pages ---------------------------------------------------------
    m_home      = new HomePage(m_api);
    m_scenarios = new ScenariosPage(m_api);
    m_brief     = new ScenarioBriefPage(m_api);
    m_history   = new HistoryPage(m_api);
    m_progress  = new ProgressPage(m_api);
    m_settings  = new SettingsPage(m_api);
    m_chat      = new ChatPage(m_api);

    m_stack = new QStackedWidget;
    m_stack->addWidget(m_home);       // 0
    m_stack->addWidget(m_scenarios);  // 1
    m_stack->addWidget(m_history);    // 2
    m_stack->addWidget(m_progress);   // 3
    m_stack->addWidget(m_settings);   // 4
    m_stack->addWidget(m_chat);       // 5 (not in nav)
    m_stack->addWidget(m_brief);      // 6 (not in nav)

    // ---- Sidebar -------------------------------------------------------
    auto* sidebar = new QFrame;
    sidebar->setObjectName("Sidebar");
    sidebar->setFixedWidth(220);
    auto* sb = new QVBoxLayout(sidebar);
    sb->setContentsMargins(16, 20, 16, 16);
    sb->setSpacing(6);

    // Logo: "F" monogram + FreeTalk
    auto* logoRow = new QHBoxLayout;
    logoRow->setSpacing(10);
    auto* mono = Theme::makeAvatar("F", 34, Theme::palette().accent);
    auto* word = new QLabel("FreeTalk"); word->setObjectName("Logo");
    logoRow->addWidget(mono);
    logoRow->addWidget(word);
    logoRow->addStretch(1);
    sb->addLayout(logoRow);
    sb->addSpacing(18);

    m_navGroup = new QButtonGroup(this);
    m_navGroup->setExclusive(true);
    addNav(tr("  Home"),                 PageHome);
    addNav(tr("  Scenarios"),            PageScenarios);
    addNav(tr("  Conversation history"), PageHistory);
    addNav(tr("  Progress"),             PageProgress);
    addNav(tr("  Settings"),             PageSettings);
    for (QAbstractButton* b : m_navGroup->buttons())
        sb->addWidget(b);

    sb->addStretch(1);

    // Profile footer
    auto* line = new QFrame; line->setFrameShape(QFrame::HLine);
    line->setStyleSheet(QStringLiteral("color:%1;").arg(Theme::palette().border.name()));
    sb->addWidget(line);

    auto* footer = new QHBoxLayout;
    footer->setSpacing(10);
    m_footerAvatar = new QWidget;
    auto* fav = new QHBoxLayout(m_footerAvatar);
    fav->setContentsMargins(0, 0, 0, 0);
    fav->addWidget(Theme::makeAvatar("U", 32, Theme::palette().accent2));
    auto* fcol = new QVBoxLayout; fcol->setSpacing(0);
    m_footerName = new QLabel(tr("You"));
    m_footerName->setStyleSheet("font-weight:600;font-size:12px;");
    m_footerSub = new QLabel("A1 · 0🔥");
    m_footerSub->setStyleSheet(QStringLiteral("color:%1;font-family:'%2';font-size:10px;")
                                   .arg(Theme::palette().inkSoft.name(), Theme::fontMono()));
    fcol->addWidget(m_footerName);
    fcol->addWidget(m_footerSub);
    footer->addWidget(m_footerAvatar);
    footer->addLayout(fcol);
    footer->addStretch(1);
    sb->addLayout(footer);

    // ---- Root ----------------------------------------------------------
    auto* root = new QWidget; root->setObjectName("Root");
    auto* rl = new QHBoxLayout(root);
    rl->setContentsMargins(0, 0, 0, 0);
    rl->setSpacing(0);
    rl->addWidget(sidebar);
    rl->addWidget(m_stack, 1);
    setCentralWidget(root);

    // ---- Wiring --------------------------------------------------------
    connect(m_home, &HomePage::profileLoaded, this, [this](const UserProfile& p) {
        updateProfile(p);
        m_settings->setProfile(p);
    });
    connect(m_chat, &ChatPage::statusMessage, this, [this](const QString& t) {
        statusBar()->showMessage(t);
    });
    // Scenario tapped → show the brief (detail) screen first.
    auto openBrief = [this](const QString& id, const QString&) {
        m_brief->load(id);
        showPage(PageBrief);
    };
    connect(m_home,      &HomePage::scenarioActivated,      this, openBrief);
    connect(m_scenarios, &ScenariosPage::scenarioActivated, this, openBrief);
    // Brief → start the conversation (→ chat shows the tutor's opening line).
    connect(m_brief, &ScenarioBriefPage::startRequested, this, [this](const QString& id, const QString& title) {
        showPage(PageChat);
        m_chat->startScenario(id, title);
    });
    connect(m_brief, &ScenarioBriefPage::backRequested, this, [this]() {
        showPage(PageScenarios);
    });
    connect(m_history,   &HistoryPage::openRequested, this, [this](const QString& id) {
        showPage(PageChat);
        m_chat->openSession(id);
    });
    connect(m_settings, &SettingsPage::signOutRequested, this, &QWidget::close);
    connect(m_settings, &SettingsPage::themeChanged, this, &MainShell::themeChangeRequested);

    // Start on Home.
    static_cast<QPushButton*>(m_navGroup->button(PageHome))->setChecked(true);
    showPage(PageHome);
    m_home->refresh();

    // Apply remote tab-visibility flags (tabs.*). Default: all visible; hide
    // only those the admin explicitly turned off via Layout flags.
    m_api->getAppConfig([this](bool ok, const QJsonValue& d, const QString&) {
        if (ok && d.isObject())
            applyTabFlags(d.toObject().value("flags").toObject());
    });
}

void MainShell::applyTabFlags(const QJsonObject& flags)
{
    struct Tab { int idx; const char* key; };
    static const Tab tabs[] = {
        {PageHome,      "tabs.home"},
        {PageScenarios, "tabs.scenarios"},
        {PageHistory,   "tabs.history"},
        {PageProgress,  "tabs.progress"},
        {PageSettings,  "tabs.settings"},
    };
    for (const Tab& t : tabs) {
        const QJsonValue v = flags.value(QLatin1String(t.key));
        const bool visible = v.isBool() ? v.toBool() : true;   // fallback: visible
        if (auto* b = m_navGroup->button(t.idx))
            b->setVisible(visible);
        // If we're currently on a now-hidden tab, fall back to the first visible.
        if (!visible && m_stack->currentIndex() == t.idx)
            showPage(firstVisibleTab());
    }
}

int MainShell::firstVisibleTab() const
{
    for (int i = PageHome; i <= PageSettings; ++i)
        if (auto* b = m_navGroup->button(i))
            if (b->isVisible()) return i;
    return PageHome;
}

void MainShell::addNav(const QString& text, int pageIndex)
{
    auto* b = new QPushButton(text);
    b->setObjectName("NavItem");
    b->setCheckable(true);
    b->setCursor(Qt::PointingHandCursor);
    m_navGroup->addButton(b, pageIndex);
    connect(b, &QPushButton::clicked, this, [this, pageIndex]() { showPage(pageIndex); });
}

void MainShell::showPage(int index)
{
    m_stack->setCurrentIndex(index);
    if (auto* b = m_navGroup->button(index)) b->setChecked(true);

    if (index == PageHome)      m_home->refresh();
    if (index == PageScenarios) m_scenarios->refresh();
    if (index == PageHistory)   m_history->refresh();
    if (index == PageProgress)  m_progress->refresh();
}

void MainShell::updateProfile(const UserProfile& p)
{
    m_footerName->setText(p.displayName.isEmpty() ? tr("You") : p.displayName);
    m_footerSub->setText(QStringLiteral("%1 · %2🔥").arg(p.cefr()).arg(p.streakDays));

    // Refresh the footer avatar with the user's initial.
    auto* fav = qobject_cast<QHBoxLayout*>(m_footerAvatar->layout());
    QLayoutItem* old;
    while ((old = fav->takeAt(0)) != nullptr) { delete old->widget(); delete old; }
    fav->addWidget(Theme::makeAvatar(
        p.displayName.isEmpty() ? "U" : p.displayName, 32, Theme::palette().accent2));
}
