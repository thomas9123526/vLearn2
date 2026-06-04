#include "home/HomePage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"
#include "ui/ClickableFrame.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QScrollArea>
#include <QLabel>
#include <QFrame>
#include <QProgressBar>
#include <QTime>
#include <QJsonObject>
#include <QJsonArray>

static QString greetingForHour()
{
    const int h = QTime::currentTime().hour();
    if (h < 12) return QObject::tr("Good morning");
    if (h < 18) return QObject::tr("Good afternoon");
    return QObject::tr("Good evening");
}

static QFrame* makeStatCard(const QString& iconText, QLabel*& numOut, const QString& label)
{
    auto* card = new QFrame;
    card->setObjectName("StatCard");
    auto* v = new QVBoxLayout(card);
    v->setContentsMargins(16, 16, 16, 16);
    v->setSpacing(4);
    auto* icon = new QLabel(iconText); icon->setObjectName("StatIcon");
    icon->setAlignment(Qt::AlignHCenter);
    numOut = new QLabel("0");          numOut->setObjectName("StatNum");
    numOut->setAlignment(Qt::AlignHCenter);
    auto* lbl = new QLabel(label);     lbl->setObjectName("StatLbl");
    lbl->setAlignment(Qt::AlignHCenter);
    v->addWidget(icon);
    v->addWidget(numOut);
    v->addWidget(lbl);
    return card;
}

HomePage::HomePage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    // Greeting -----------------------------------------------------------
    m_greeting = new QLabel(tr("Good morning"));
    m_greeting->setObjectName("H1");
    auto* sub = new QLabel(tr("Let's practice some English today."));
    sub->setObjectName("Sub");

    // Hero streak/XP card ------------------------------------------------
    auto* hero = new QFrame;
    hero->setObjectName("HeroCard");
    auto* hv = new QVBoxLayout(hero);
    hv->setContentsMargins(20, 16, 20, 16);
    hv->setSpacing(10);

    auto* heroTop = new QHBoxLayout;
    m_streakLabel = new QLabel("🔥  0 day streak"); m_streakLabel->setObjectName("HeroBig");
    m_xpLabel = new QLabel("0 XP");                  m_xpLabel->setObjectName("HeroXp");
    heroTop->addWidget(m_streakLabel);
    heroTop->addStretch(1);
    heroTop->addWidget(m_xpLabel);

    m_xpBar = new QProgressBar;
    m_xpBar->setRange(0, 500);
    m_xpBar->setValue(0);
    m_xpBar->setTextVisible(false);

    m_levelHint = new QLabel(tr("500 XP to level 2")); m_levelHint->setObjectName("HeroSmall");

    hv->addLayout(heroTop);
    hv->addWidget(m_xpBar);
    hv->addWidget(m_levelHint);

    // Stat cards ---------------------------------------------------------
    auto* statsRow = new QHBoxLayout;
    statsRow->setSpacing(12);
    statsRow->addWidget(makeStatCard("💬", m_statSessions, tr("Sessions")));
    statsRow->addWidget(makeStatCard("⏱", m_statMinutes, tr("Minutes")));
    statsRow->addWidget(makeStatCard("🗺", m_statTopics, tr("Topics")));

    // Recommended scenarios ---------------------------------------------
    auto* recHead = new QLabel(tr("Recommended scenarios"));
    recHead->setStyleSheet(QStringLiteral("font-family:'%1';font-size:20px;color:%2;")
                               .arg(Theme::fontDisplay(), Theme::palette().ink.name()));

    auto* recScroll = new QScrollArea;
    recScroll->setWidgetResizable(true);
    recScroll->setFixedHeight(170);
    recScroll->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    recScroll->setFrameShape(QFrame::NoFrame);
    auto* recCanvas = new QWidget;
    m_scenarioRow = new QHBoxLayout(recCanvas);
    m_scenarioRow->setContentsMargins(0, 0, 0, 0);
    m_scenarioRow->setSpacing(12);
    m_scenarioRow->addStretch(1);
    recScroll->setWidget(recCanvas);

    // Assemble (scrollable page) ----------------------------------------
    auto* page = new QWidget;
    auto* col = new QVBoxLayout(page);
    col->setContentsMargins(40, 28, 40, 28);
    col->setSpacing(16);
    col->addWidget(m_greeting);
    col->addWidget(sub);
    col->addWidget(hero);
    col->addLayout(statsRow);
    col->addSpacing(4);
    col->addWidget(recHead);
    col->addWidget(recScroll);
    col->addStretch(1);

    auto* outer = new QScrollArea;
    outer->setWidgetResizable(true);
    outer->setFrameShape(QFrame::NoFrame);
    outer->setWidget(page);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(0, 0, 0, 0);
    root->addWidget(outer);
}

void HomePage::applyProfile(const UserProfile& p)
{
    const QString name = p.displayName.isEmpty() ? tr("there") : p.displayName;
    m_greeting->setText(QStringLiteral("%1, %2").arg(greetingForHour(), name));
    m_streakLabel->setText(tr("🔥  %1 day streak").arg(p.streakDays));
    m_xpLabel->setText(tr("%1 XP").arg(p.xpTotal));

    const int inLevel = p.xpTotal % 500;
    m_xpBar->setValue(inLevel);
    m_levelHint->setText(tr("%1 XP to level %2").arg(500 - inLevel).arg(p.currentLevel + 1));
}

void HomePage::applyProgress(const ProgressSummary& p)
{
    m_statSessions->setText(QString::number(p.sessionsTotal));
    m_statMinutes->setText(QString::number(p.minutesTotal));
    m_statTopics->setText(QString::number(p.scenariosDone));
}

void HomePage::applyScenarios(const QVector<Scenario>& list)
{
    // Clear existing cards (keep the trailing stretch at the end).
    while (m_scenarioRow->count() > 1) {
        QLayoutItem* it = m_scenarioRow->takeAt(0);
        if (it->widget()) it->widget()->deleteLater();
        delete it;
    }
    int shown = 0;
    for (const Scenario& s : list) {
        if (shown++ >= 8) break;
        auto* card = new ClickableFrame;
        card->setObjectName("ScenarioCard");
        card->setCursor(Qt::PointingHandCursor);
        card->setFixedWidth(220);
        auto* v = new QVBoxLayout(card);
        v->setContentsMargins(14, 14, 14, 14);
        v->setSpacing(8);

        auto* chip = new QLabel(s.category.isEmpty() ? tr("chat") : s.category);
        chip->setObjectName("CatChip");
        chip->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Fixed);

        auto* title = new QLabel(s.title.isEmpty() ? tr("Conversation") : s.title);
        title->setObjectName("ScenarioTitle");
        title->setWordWrap(true);

        auto* meta = new QLabel(QStringLiteral("⏱ %1 min   ·   ⭐ %2 XP")
                                    .arg(s.estimatedMinutes).arg(s.xpReward));
        meta->setObjectName("ScenarioMeta");

        v->addWidget(chip);
        v->addWidget(title);
        v->addStretch(1);
        v->addWidget(meta);

        const QString id = s.id, t = s.title;
        connect(card, &ClickableFrame::clicked, this, [this, id, t]() {
            emit scenarioActivated(id, t);
        });
        m_scenarioRow->insertWidget(m_scenarioRow->count() - 1, card);
    }
}

void HomePage::refresh()
{
    m_api->getProfile([this](bool ok, const QJsonValue& d, const QString&) {
        if (ok && d.isObject()) {
            const UserProfile p = UserProfile::fromJson(d.toObject());
            applyProfile(p);
            emit profileLoaded(p);
        }
    });
    m_api->getProgress([this](bool ok, const QJsonValue& d, const QString&) {
        if (ok && d.isObject()) applyProgress(ProgressSummary::fromJson(d.toObject()));
    });
    m_api->listScenarios([this](bool ok, const QJsonValue& d, const QString&) {
        if (!ok || !d.isArray()) return;
        QVector<Scenario> list;
        for (const QJsonValue& v : d.toArray()) list.push_back(Scenario::fromJson(v.toObject()));
        applyScenarios(list);
    });
}
