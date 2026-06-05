#pragma once

#include <QWidget>
#include "model/Models.h"

class ApiClient;
class QLabel;
class QVBoxLayout;

// Settings, matching the Flutter settings screen: profile tile + Appearance /
// Font / Conversation / Voice / Account sections of list tiles.
class SettingsPage : public QWidget {
    Q_OBJECT
public:
    explicit SettingsPage(ApiClient* api, QWidget* parent = nullptr);
    void setProfile(const UserProfile& p);

signals:
    void signOutRequested();

private:
    QWidget* sectionHeader(const QString& text);
    QWidget* tile(const QString& icon, const QString& title, const QString& value,
                  bool chevron, bool danger = false);
    void changePassword();

    ApiClient* m_api;
    QWidget*   m_avatarHolder;
    QLabel*    m_name;
    QLabel*    m_email;
    QLabel*    m_themeValue;
    QLabel*    m_langValue;
};
