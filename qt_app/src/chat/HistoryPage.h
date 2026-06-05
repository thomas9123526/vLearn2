#pragma once

#include <QWidget>

class ApiClient;
class QListWidget;
class QLabel;

// Lists the user's past/active conversations (GET /conversations/sessions).
// Double-click (or Open) emits openRequested(sessionId).
class HistoryPage : public QWidget {
    Q_OBJECT
public:
    explicit HistoryPage(ApiClient* api, QWidget* parent = nullptr);

    void refresh();

signals:
    void openRequested(const QString& sessionId);

private:
    ApiClient*   m_api;
    QLabel*      m_empty;
    QListWidget* m_list;
};
