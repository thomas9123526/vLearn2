#pragma once

#include <QMainWindow>
#include "model/Models.h"

class ApiClient;
class HomePage;
class ScenariosPage;
class ProgressPage;
class HistoryPage;
class SettingsPage;
class ChatPage;
class QStackedWidget;
class QPushButton;
class QButtonGroup;
class QLabel;
class QWidget;

// Desktop shell matching the running VFLS app: a 220px sidebar (FreeTalk logo,
// Home / Scenarios / Conversation history / Progress / Settings, profile footer)
// + a stacked content area. Holds the ApiClient and routes navigation.
class MainShell : public QMainWindow {
    Q_OBJECT
public:
    explicit MainShell(ApiClient* api, QWidget* parent = nullptr);

private:
    void addNav(const QString& text, int pageIndex);
    void showPage(int index);
    void updateProfile(const UserProfile& p);

    ApiClient*      m_api;
    QStackedWidget* m_stack;
    QButtonGroup*   m_navGroup;

    HomePage*      m_home;
    ScenariosPage* m_scenarios;
    ProgressPage*  m_progress;
    HistoryPage*   m_history;
    SettingsPage*  m_settings;
    ChatPage*      m_chat;

    QWidget* m_footerAvatar;
    QLabel*  m_footerName;
    QLabel*  m_footerSub;
};
