#pragma once

#include <QWidget>
#include "model/Models.h"

class ApiClient;
class QLabel;
class QProgressBar;
class QHBoxLayout;
class QFrame;

// Dashboard home: greeting, streak/XP hero card, Sessions/Minutes/Topics
// stats, and a Recommended-scenarios strip. Mirrors the Flutter home screen.
class HomePage : public QWidget {
    Q_OBJECT
public:
    explicit HomePage(ApiClient* api, QWidget* parent = nullptr);

    void refresh();   // re-fetch profile, progress, scenarios

signals:
    void profileLoaded(const UserProfile& profile);     // shell updates footer
    void scenarioActivated(const QString& scenarioId, const QString& title);

private:
    void applyProfile(const UserProfile& p);
    void applyProgress(const ProgressSummary& p);
    void applyScenarios(const QVector<Scenario>& list);
    void applyNews(const QString& title, const QString& summary);

    ApiClient*    m_api;
    QLabel*       m_greeting;
    QFrame*       m_newsCard;
    QLabel*       m_newsTitle;
    QLabel*       m_newsSummary;
    QLabel*       m_streakLabel;
    QLabel*       m_xpLabel;
    QLabel*       m_levelHint;
    QProgressBar* m_xpBar;
    QLabel*       m_statSessions;
    QLabel*       m_statMinutes;
    QLabel*       m_statTopics;
    QHBoxLayout*  m_scenarioRow;
};
