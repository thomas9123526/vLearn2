#pragma once

#include <QWidget>
#include "model/Models.h"

class ApiClient;
class QLabel;

// Settings: shows the signed-in profile + a sign-out action.
class SettingsPage : public QWidget {
    Q_OBJECT
public:
    explicit SettingsPage(ApiClient* api, QWidget* parent = nullptr);
    void setProfile(const UserProfile& p);

signals:
    void signOutRequested();

private:
    ApiClient* m_api;
    QLabel*    m_name;
    QLabel*    m_level;
};
