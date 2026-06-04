#include "shell/MainShell.h"
#include "api/ApiClient.h"
#include "chat/ChatPage.h"
#include "chat/HistoryPage.h"
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

enum { PageChat = 0, PageHistory = 1, PageProfile = 2 };

MainShell::MainShell(ApiClient* api, QWidget* parent)
    : QMainWindow(parent)
    , m_api(api)
{
    setWindowTitle(tr("FreeTalk"));
    resize(1120, 720);

    // ---- Content stack -------------------------------------------------
    m_stack = new QStackedWidget;

    m_chat = new ChatPage(m_api);
    m_history = new HistoryPage(m_api);

    // Simple profile page.
    auto* profile = new QWidget;
    {
        auto* pl = new QVBoxLayout(profile);
        pl->setContentsMargins(48, 32, 48, 32);
        auto* k = new QLabel(tr("ACCOUNT"));        k->setObjectName("Kicker");
        auto* h = new QLabel(tr("Hey %1").arg(m_api->displayName())); h->setObjectName("H1");
        auto* s = new QLabel(tr("Signed in to FreeTalk."));           s->setObjectName("Sub");
        pl->addWidget(k); pl->addWidget(h); pl->addWidget(s); pl->addStretch(1);
    }

    m_stack->addWidget(m_chat);      // PageChat
    m_stack->addWidget(m_history);   // PageHistory
    m_stack->addWidget(profile);     // PageProfile

    // ---- Sidebar -------------------------------------------------------
    auto* sidebar = new QFrame;
    sidebar->setObjectName("Sidebar");
    sidebar->setFixedWidth(220);
    auto* sb = new QVBoxLayout(sidebar);
    sb->setContentsMargins(16, 20, 16, 16);
    sb->setSpacing(6);

    // Logo: "Free" ink + "Talk" accent italic
    auto* logoRow = new QHBoxLayout;
    logoRow->setSpacing(0);
    auto* free = new QLabel("Free"); free->setObjectName("Logo");
    auto* talk = new QLabel("Talk"); talk->setObjectName("LogoAccent");
    logoRow->addWidget(free); logoRow->addWidget(talk); logoRow->addStretch(1);
    sb->addLayout(logoRow);
    sb->addSpacing(18);

    m_navGroup = new QButtonGroup(this);
    m_navGroup->setExclusive(true);
    addNav(tr("  Chat"),     PageChat);
    addNav(tr("  History"),  PageHistory);
    addNav(tr("  Profile"),  PageProfile);

    sb->addWidget(m_navGroup->buttons().at(0));
    sb->addWidget(m_navGroup->buttons().at(1));
    sb->addWidget(m_navGroup->buttons().at(2));

    sb->addStretch(1);

    // Quick-talk CTA
    auto* quick = new QPushButton(tr("Quick talk  →"));
    quick->setProperty("variant", QStringLiteral("primary"));
    quick->setCursor(Qt::PointingHandCursor);
    sb->addWidget(quick);
    sb->addSpacing(10);

    // Profile footer
    auto* footer = new QHBoxLayout;
    footer->setSpacing(10);
    footer->addWidget(Theme::makeAvatar(m_api->displayName().isEmpty() ? "U"
                                        : m_api->displayName(), 36, Theme::palette().accent2));
    auto* name = new QLabel(m_api->displayName().isEmpty() ? tr("You")
                                                           : m_api->displayName());
    name->setStyleSheet("font-weight:600;");
    footer->addWidget(name);
    footer->addStretch(1);
    sb->addLayout(footer);

    // ---- Root layout ---------------------------------------------------
    auto* root = new QWidget;
    root->setObjectName("Root");
    auto* rl = new QHBoxLayout(root);
    rl->setContentsMargins(0, 0, 0, 0);
    rl->setSpacing(0);
    rl->addWidget(sidebar);
    rl->addWidget(m_stack, 1);
    setCentralWidget(root);

    statusBar()->showMessage(tr("Welcome, %1").arg(m_api->displayName()));

    // ---- Wiring --------------------------------------------------------
    connect(m_chat, &ChatPage::statusMessage, this, [this](const QString& t) {
        statusBar()->showMessage(t);
    });
    connect(quick, &QPushButton::clicked, this, [this]() {
        showPage(PageChat);
        m_chat->startNewChat();
    });
    connect(m_history, &HistoryPage::openRequested, this, [this](const QString& id) {
        showPage(PageChat);
        m_chat->openSession(id);
    });

    // Start on Chat and immediately begin a new conversation.
    static_cast<QPushButton*>(m_navGroup->button(PageChat))->setChecked(true);
    showPage(PageChat);
    m_chat->startNewChat();
}

QPushButton* MainShell::addNav(const QString& text, int pageIndex)
{
    auto* b = new QPushButton(text);
    b->setObjectName("NavItem");
    b->setCheckable(true);
    b->setCursor(Qt::PointingHandCursor);
    m_navGroup->addButton(b, pageIndex);
    connect(b, &QPushButton::clicked, this, [this, pageIndex]() { showPage(pageIndex); });
    return b;
}

void MainShell::showPage(int index)
{
    m_stack->setCurrentIndex(index);
    if (auto* b = m_navGroup->button(index)) b->setChecked(true);
    if (index == PageHistory) m_history->refresh();
}
