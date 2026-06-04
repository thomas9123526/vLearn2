#pragma once

#include <QWidget>

class ApiClient;
class QVBoxLayout;
class QLabel;

// Browse scenarios (GET /scenarios) as a vertical list of cards.
// Clicking a card emits scenarioActivated(id, title).
class ScenariosPage : public QWidget {
    Q_OBJECT
public:
    explicit ScenariosPage(ApiClient* api, QWidget* parent = nullptr);
    void refresh();

signals:
    void scenarioActivated(const QString& scenarioId, const QString& title);

private:
    ApiClient*   m_api;
    QVBoxLayout* m_list;
    QLabel*      m_empty;
};
