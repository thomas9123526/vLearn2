#include "scenarios/ScenarioBriefPage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"
#include "model/Models.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QLabel>
#include <QFrame>
#include <QPushButton>
#include <QVariant>
#include <QJsonObject>

static QFrame* roleCard(const QString& kicker, QLabel*& body)
{
    auto* card = new QFrame; card->setObjectName("Card");
    auto* v = new QVBoxLayout(card);
    v->setContentsMargins(16, 14, 16, 14);
    v->setSpacing(4);
    auto* k = new QLabel(kicker); k->setObjectName("Kicker");
    body = new QLabel("—"); body->setWordWrap(true);
    v->addWidget(k);
    v->addWidget(body);
    return card;
}

ScenarioBriefPage::ScenarioBriefPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    m_crumb = new QLabel(tr("BRIEF")); m_crumb->setObjectName("Kicker");

    // Hero card
    auto* hero = new QFrame; hero->setObjectName("Card");
    auto* hv = new QVBoxLayout(hero);
    hv->setContentsMargins(20, 18, 20, 18);
    hv->setSpacing(10);
    auto* sceneKicker = new QLabel(tr("SCENE")); sceneKicker->setObjectName("Kicker");
    m_heroTitle = new QLabel(tr("Scenario")); m_heroTitle->setObjectName("H1");
    m_heroTitle->setWordWrap(true);
    m_heroDesc = new QLabel; m_heroDesc->setObjectName("Sub"); m_heroDesc->setWordWrap(true);
    auto* pillWrap = new QHBoxLayout; m_pillRow = pillWrap; m_pillRow->setSpacing(8);
    m_pillRow->addStretch(1);
    hv->addWidget(sceneKicker);
    hv->addWidget(m_heroTitle);
    hv->addWidget(m_heroDesc);
    hv->addLayout(m_pillRow);

    // Roles
    auto* rolesRow = new QHBoxLayout; rolesRow->setSpacing(12);
    rolesRow->addWidget(roleCard(tr("YOU PLAY"), m_youRole));
    rolesRow->addWidget(roleCard(tr("TUTOR PLAYS"), m_tutorRole));

    // Objectives
    m_objHeader = new QLabel(tr("Objectives"));
    m_objHeader->setStyleSheet(QStringLiteral("font-family:'%1';font-size:20px;color:%2;")
                                   .arg(Theme::fontDisplay(), Theme::palette().ink.name()));
    auto* objCard = new QFrame; objCard->setObjectName("Card");
    m_objList = new QVBoxLayout(objCard);
    m_objList->setContentsMargins(16, 14, 16, 14);
    m_objList->setSpacing(8);

    // Key phrases
    m_phraseHeader = new QLabel(tr("Phrases worth stealing"));
    m_phraseHeader->setStyleSheet(QStringLiteral("font-family:'%1';font-size:20px;color:%2;")
                                      .arg(Theme::fontDisplay(), Theme::palette().ink.name()));
    auto* phraseCard = new QFrame; phraseCard->setObjectName("Card");
    m_phraseList = new QVBoxLayout(phraseCard);
    m_phraseList->setContentsMargins(16, 14, 16, 14);
    m_phraseList->setSpacing(8);

    // Scroll body
    auto* page = new QWidget;
    auto* col = new QVBoxLayout(page);
    col->setContentsMargins(40, 24, 40, 24);
    col->setSpacing(16);
    col->addWidget(m_crumb);
    col->addWidget(hero);
    col->addLayout(rolesRow);
    col->addWidget(m_objHeader);
    col->addWidget(objCard);
    col->addWidget(m_phraseHeader);
    col->addWidget(phraseCard);
    col->addStretch(1);

    auto* scroll = new QScrollArea;
    scroll->setWidgetResizable(true);
    scroll->setFrameShape(QFrame::NoFrame);
    scroll->setWidget(page);

    // Sticky bottom dock
    auto* dock = new QFrame; dock->setObjectName("Header");   // top border separator
    auto* dl = new QHBoxLayout(dock);
    dl->setContentsMargins(40, 12, 40, 12);
    dl->setSpacing(12);
    auto* back = new QPushButton(tr("Back to topics"));
    back->setProperty("variant", QStringLiteral("ghost"));
    back->setCursor(Qt::PointingHandCursor);
    m_start = new QPushButton(tr("Start speaking"));
    m_start->setProperty("variant", QStringLiteral("primary"));
    m_start->setCursor(Qt::PointingHandCursor);
    dl->addWidget(back, 1);
    dl->addWidget(m_start, 2);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(0, 0, 0, 0);
    root->setSpacing(0);
    root->addWidget(scroll, 1);
    root->addWidget(dock);

    connect(back, &QPushButton::clicked, this, &ScenarioBriefPage::backRequested);
    connect(m_start, &QPushButton::clicked, this, [this]() {
        if (!m_id.isEmpty()) emit startRequested(m_id, m_title);
    });
}

QLabel* ScenarioBriefPage::pill(const QString& text)
{
    auto* l = new QLabel(text);
    l->setStyleSheet(QStringLiteral(
        "background:%1;color:%2;border-radius:999px;padding:4px 12px;"
        "font-family:'%3';font-size:11px;")
        .arg(Theme::palette().surfaceAlt.name(),
             Theme::palette().accentInk.name(), Theme::fontMono()));
    l->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Fixed);
    return l;
}

void ScenarioBriefPage::load(const QString& scenarioId)
{
    m_id = scenarioId;
    m_api->getScenario(scenarioId, [this](bool ok, const QJsonValue& d, const QString&) {
        if (!ok || !d.isObject()) return;
        const Scenario s = Scenario::fromJson(d.toObject());
        m_title = s.title;

        m_crumb->setText(QStringLiteral("BRIEF · %1").arg(s.category.toUpper()));
        m_heroTitle->setText(s.title);
        m_heroDesc->setText(s.sceneDescription.isEmpty() ? s.description : s.sceneDescription);

        // Pills
        while (m_pillRow->count() > 1) { QLayoutItem* it = m_pillRow->takeAt(0);
            if (it->widget()) it->widget()->deleteLater(); delete it; }
        if (s.cefrLevel >= 1) m_pillRow->insertWidget(m_pillRow->count() - 1, pill(cefrLabel(s.cefrLevel)));
        m_pillRow->insertWidget(m_pillRow->count() - 1, pill(tr("⏱ %1 min").arg(s.estimatedMinutes)));
        m_pillRow->insertWidget(m_pillRow->count() - 1, pill(tr("⭐ %1 XP").arg(s.xpReward)));

        m_youRole->setText(s.userRole.isEmpty() ? tr("You") : s.userRole);
        m_tutorRole->setText(s.tutorRole.isEmpty() ? tr("Your AI tutor") : s.tutorRole);

        // Objectives (numbered)
        while (m_objList->count() > 0) { QLayoutItem* it = m_objList->takeAt(0);
            if (it->widget()) it->widget()->deleteLater(); delete it; }
        if (s.objectives.isEmpty()) {
            auto* none = new QLabel(tr("Have a natural conversation and keep it going."));
            none->setObjectName("Sub"); none->setWordWrap(true);
            m_objList->addWidget(none);
        }
        int n = 1;
        for (const QString& o : s.objectives) {
            auto* row = new QLabel(QStringLiteral("%1.  %2").arg(n++).arg(o));
            row->setWordWrap(true);
            m_objList->addWidget(row);
        }
        m_objHeader->setVisible(true);

        // Key phrases (pull quotes)
        while (m_phraseList->count() > 0) { QLayoutItem* it = m_phraseList->takeAt(0);
            if (it->widget()) it->widget()->deleteLater(); delete it; }
        for (const QString& ph : s.keyPhrases) {
            auto* q = new QLabel(QStringLiteral("“%1”").arg(ph));
            q->setWordWrap(true);
            q->setStyleSheet(QStringLiteral("font-family:'%1';font-size:15px;color:%2;")
                                 .arg(Theme::fontDisplay(), Theme::palette().accent2.name()));
            m_phraseList->addWidget(q);
        }
        const bool hasPhrases = !s.keyPhrases.isEmpty();
        m_phraseHeader->setVisible(hasPhrases);
        m_phraseList->parentWidget()->setVisible(hasPhrases);

        m_start->setText(s.estimatedMinutes > 0
                             ? tr("Start speaking (%1m)").arg(s.estimatedMinutes)
                             : tr("Start speaking"));
    });
}
