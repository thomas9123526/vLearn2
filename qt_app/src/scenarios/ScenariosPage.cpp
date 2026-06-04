#include "scenarios/ScenariosPage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"
#include "ui/ClickableFrame.h"
#include "model/Models.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QLabel>
#include <QFrame>
#include <QJsonArray>
#include <QJsonObject>

ScenariosPage::ScenariosPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* kicker = new QLabel(tr("PRACTICE")); kicker->setObjectName("Kicker");
    auto* title  = new QLabel(tr("Scenarios"));  title->setObjectName("H1");

    m_empty = new QLabel(tr("No scenarios available."));
    m_empty->setObjectName("Sub");
    m_empty->setAlignment(Qt::AlignCenter);
    m_empty->hide();

    auto* canvas = new QWidget;
    m_list = new QVBoxLayout(canvas);
    m_list->setContentsMargins(0, 0, 0, 0);
    m_list->setSpacing(10);
    m_list->addStretch(1);

    auto* scroll = new QScrollArea;
    scroll->setWidgetResizable(true);
    scroll->setFrameShape(QFrame::NoFrame);
    scroll->setWidget(canvas);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(40, 28, 40, 28);
    root->setSpacing(8);
    root->addWidget(kicker);
    root->addWidget(title);
    root->addSpacing(6);
    root->addWidget(m_empty);
    root->addWidget(scroll, 1);
}

void ScenariosPage::refresh()
{
    m_api->listScenarios([this](bool ok, const QJsonValue& d, const QString&) {
        while (m_list->count() > 1) {
            QLayoutItem* it = m_list->takeAt(0);
            if (it->widget()) it->widget()->deleteLater();
            delete it;
        }
        const QJsonArray arr = (ok && d.isArray()) ? d.toArray() : QJsonArray();
        m_empty->setVisible(arr.isEmpty());
        for (const QJsonValue& v : arr) {
            const Scenario s = Scenario::fromJson(v.toObject());
            auto* card = new ClickableFrame;
            card->setObjectName("ScenarioCard");
            card->setCursor(Qt::PointingHandCursor);
            auto* h = new QHBoxLayout(card);
            h->setContentsMargins(16, 14, 16, 14);
            h->setSpacing(12);

            auto* texts = new QVBoxLayout;
            texts->setSpacing(4);
            auto* chip = new QLabel(s.category.isEmpty() ? tr("chat") : s.category);
            chip->setObjectName("CatChip");
            chip->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Fixed);
            auto* t = new QLabel(s.title.isEmpty() ? tr("Conversation") : s.title);
            t->setObjectName("ScenarioTitle");
            auto* desc = new QLabel(s.description);
            desc->setObjectName("Sub");
            desc->setWordWrap(true);
            texts->addWidget(chip);
            texts->addWidget(t);
            texts->addWidget(desc);

            auto* meta = new QLabel(QStringLiteral("⏱ %1 min\n⭐ %2 XP")
                                        .arg(s.estimatedMinutes).arg(s.xpReward));
            meta->setObjectName("ScenarioMeta");
            meta->setAlignment(Qt::AlignRight | Qt::AlignVCenter);

            h->addLayout(texts, 1);
            h->addWidget(meta);

            const QString id = s.id, title = s.title;
            connect(card, &ClickableFrame::clicked, this, [this, id, title]() {
                emit scenarioActivated(id, title);
            });
            m_list->insertWidget(m_list->count() - 1, card);
        }
    });
}
