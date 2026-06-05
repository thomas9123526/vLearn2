#include "chat/HistoryPage.h"
#include "api/ApiClient.h"
#include "model/Models.h"

#include <QVBoxLayout>
#include <QListWidget>
#include <QLabel>
#include <QJsonObject>
#include <QJsonArray>

HistoryPage::HistoryPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* title = new QLabel(tr("Conversations"));
    title->setObjectName("H1");

    auto* kicker = new QLabel(tr("YOUR HISTORY"));
    kicker->setObjectName("Kicker");

    m_list = new QListWidget;
    m_list->setVisible(false);

    m_empty = new QLabel(tr("No conversations yet. Start a new chat from the sidebar."));
    m_empty->setObjectName("Sub");
    m_empty->setAlignment(Qt::AlignCenter);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(48, 32, 48, 32);
    root->setSpacing(8);
    root->addWidget(kicker);
    root->addWidget(title);
    root->addSpacing(8);
    root->addWidget(m_list, 1);
    root->addWidget(m_empty, 1);

    connect(m_list, &QListWidget::itemActivated, this, [this](QListWidgetItem* it) {
        emit openRequested(it->data(Qt::UserRole).toString());
    });
}

void HistoryPage::refresh()
{
    m_api->listSessions([this](bool ok, const QJsonValue& data, const QString&) {
        m_list->clear();
        const QJsonArray arr = (ok && data.isArray()) ? data.toArray() : QJsonArray();
        for (const QJsonValue& v : arr) {
            const QJsonObject o = v.toObject();
            const Session s = Session::fromJson(o);
            const QString scenario = o.value("scenarioTitle").toString();
            const QString label = QStringLiteral("%1   ·   %2 turns   ·   %3")
                .arg(scenario.isEmpty() ? tr("Free chat") : scenario)
                .arg(s.turnCount)
                .arg(s.status);
            auto* item = new QListWidgetItem(label, m_list);
            item->setData(Qt::UserRole, s.id);
        }
        const bool any = m_list->count() > 0;
        m_list->setVisible(any);
        m_empty->setVisible(!any);
    });
}
