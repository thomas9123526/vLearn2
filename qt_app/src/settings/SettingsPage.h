#pragma once

#include <QWidget>
#include <QStringList>
#include <functional>
#include "model/Models.h"

class ApiClient;
class QLabel;
class QVBoxLayout;
class ClickableFrame;

// Settings, matching the Flutter settings screen: profile tile + Appearance /
// Font / Conversation / Voice / Account sections of list tiles.
class SettingsPage : public QWidget {
    Q_OBJECT
public:
    explicit SettingsPage(ApiClient* api, QWidget* parent = nullptr);
    void setProfile(const UserProfile& p);

signals:
    void signOutRequested();
    void appearanceChanged();   // theme/font/language/bubble changed → rebuild shell

private:
    QWidget*        sectionHeader(const QString& text);
    // Returns the row; if valueOut is non-null it receives the value QLabel so
    // the caller can update it after a picker. Actionable rows get a chevron.
    ClickableFrame* tile(const QString& icon, const QString& title, const QString& value,
                         QLabel** valueOut = nullptr, bool danger = false);
    // Pickers
    void pickFromList(QLabel* valueLabel, const QString& title,
                      const QStringList& options, std::function<void(int)> onChosen);
    void pickTheme();
    void pickLanguage();
    void pickTutor();
    void changePassword();
    void patchProfile(const QJsonObject& patch);

    ApiClient* m_api;
    QWidget*   m_avatarHolder;
    QLabel*    m_name;
    QLabel*    m_email;
    QLabel*    m_themeValue;
    QLabel*    m_langValue;
    QLabel*    m_fontValue;
    QLabel*    m_modeValue;
    QLabel*    m_bubbleValue;
    QLabel*    m_tutorValue;
};
