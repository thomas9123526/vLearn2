#include "progress/ProgressPage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QFrame>
#include <QJsonObject>

static QFrame* statBlock(QLabel*& numOut, const QString& label)
{
    auto* card = new QFrame; card->setObjectName("StatCard");
    auto* v = new QVBoxLayout(card);
    v->setContentsMargins(16, 16, 16, 16);
    numOut = new QLabel("0"); numOut->setObjectName("StatNum");
    numOut->setAlignment(Qt::AlignHCenter);
    auto* l = new QLabel(label); l->setObjectName("StatLbl");
    l->setAlignment(Qt::AlignHCenter);
    v->addWidget(numOut); v->addWidget(l);
    return card;
}

ProgressPage::ProgressPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* kicker = new QLabel(tr("YOUR JOURNEY")); kicker->setObjectName("Kicker");
    auto* title  = new QLabel(tr("Progress"));     title->setObjectName("H1");

    // CEFR hero
    auto* hero = new QFrame; hero->setObjectName("HeroCard");
    auto* hv = new QVBoxLayout(hero);
    hv->setContentsMargins(24, 20, 24, 20);
    hv->setSpacing(4);
    auto* lvlKicker = new QLabel(tr("CURRENT LEVEL"));
    lvlKicker->setStyleSheet("color:rgba(255,255,255,0.85);font-size:11px;");
    m_cefrBig = new QLabel("A1");
    m_cefrBig->setStyleSheet(QStringLiteral("color:white;font-family:'%1';font-size:48px;")
                                 .arg(Theme::fontDisplay()));
    m_cefrSub = new QLabel(tr("Keep practicing to level up."));
    m_cefrSub->setObjectName("HeroSmall");
    hv->addWidget(lvlKicker);
    hv->addWidget(m_cefrBig);
    hv->addWidget(m_cefrSub);

    // Activity stats
    auto* row = new QHBoxLayout;
    row->setSpacing(12);
    row->addWidget(statBlock(m_sessions, tr("Sessions")));
    row->addWidget(statBlock(m_minutes, tr("Minutes spoken")));
    row->addWidget(statBlock(m_topics, tr("Scenarios done")));

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(40, 28, 40, 28);
    root->setSpacing(14);
    root->addWidget(kicker);
    root->addWidget(title);
    root->addSpacing(6);
    root->addWidget(hero);
    root->addLayout(row);
    root->addStretch(1);
}

void ProgressPage::refresh()
{
    m_api->getProfile([this](bool ok, const QJsonValue& d, const QString&) {
        if (ok && d.isObject()) {
            const UserProfile p = UserProfile::fromJson(d.toObject());
            m_cefrBig->setText(p.cefr());
        }
    });
    m_api->getProgress([this](bool ok, const QJsonValue& d, const QString&) {
        if (!ok || !d.isObject()) return;
        const ProgressSummary p = ProgressSummary::fromJson(d.toObject());
        m_sessions->setText(QString::number(p.sessionsTotal));
        m_minutes->setText(QString::number(p.minutesTotal));
        m_topics->setText(QString::number(p.scenariosDone));
    });
}
