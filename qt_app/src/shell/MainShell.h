#pragma once

#include <QMainWindow>

class ApiClient;
class ChatPage;
class HistoryPage;
class QStackedWidget;
class QPushButton;
class QButtonGroup;

// The desktop "Windows-like" shell: a 220px FreeTalk sidebar (logo, nav,
// Quick-talk CTA, profile footer) + a stacked content area (Chat / History /
// Profile). Holds the ApiClient and routes navigation between pages.
class MainShell : public QMainWindow {
    Q_OBJECT
public:
    explicit MainShell(ApiClient* api, QWidget* parent = nullptr);

private:
    QPushButton* addNav(const QString& text, int pageIndex);
    void showPage(int index);

    ApiClient*      m_api;
    QStackedWidget* m_stack;
    QButtonGroup*   m_navGroup;

    ChatPage*    m_chat;
    HistoryPage* m_history;
};
