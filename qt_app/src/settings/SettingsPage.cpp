#include "settings/SettingsPage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QFrame>
#include <QPushButton>
#include <QVariant>

SettingsPage::SettingsPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* kicker = new QLabel(tr("ACCOUNT"));  kicker->setObjectName("Kicker");
    auto* title  = new QLabel(tr("Settings")); title->setObjectName("H1");

    // Profile card
    auto* card = new QFrame; card->setObjectName("Card");
    auto* h = new QHBoxLayout(card);
    h->setContentsMargins(16, 16, 16, 16);
    h->setSpacing(14);
    h->addWidget(Theme::makeAvatar(m_api->displayName().isEmpty() ? "U"
                                   : m_api->displayName(), 48, Theme::palette().accent2));
    auto* col = new QVBoxLayout; col->setSpacing(2);
    m_name = new QLabel(m_api->displayName());
    m_name->setStyleSheet("font-size:16px;font-weight:700;");
    m_level = new QLabel(tr("Signed in"));
    m_level->setObjectName("Sub");
    col->addWidget(m_name);
    col->addWidget(m_level);
    h->addLayout(col);
    h->addStretch(1);

    auto* themeRow = new QLabel(tr("Theme:  Obsidian (dark)"));
    themeRow->setObjectName("Sub");

    auto* signOut = new QPushButton(tr("Sign out"));
    signOut->setProperty("variant", QStringLiteral("ghost"));
    signOut->setCursor(Qt::PointingHandCursor);
    connect(signOut, &QPushButton::clicked, this, &SettingsPage::signOutRequested);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(40, 28, 40, 28);
    root->setSpacing(14);
    root->addWidget(kicker);
    root->addWidget(title);
    root->addSpacing(6);
    root->addWidget(card);
    root->addWidget(themeRow);
    root->addStretch(1);
    root->addWidget(signOut, 0, Qt::AlignLeft);
}

void SettingsPage::setProfile(const UserProfile& p)
{
    m_name->setText(p.displayName);
    m_level->setText(tr("%1 · %2 XP · %3🔥").arg(p.cefr()).arg(p.xpTotal).arg(p.streakDays));
}
