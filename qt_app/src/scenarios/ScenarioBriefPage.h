#pragma once

#include <QWidget>

class ApiClient;
class QLabel;
class QVBoxLayout;
class QHBoxLayout;
class QPushButton;

// Scenario detail / "brief" shown between the Scenarios list and the chat
// (design_handoff §5): crumb, hero card, You-play / Tutor-plays roles,
// objectives, key phrases, and a sticky Start dock. No animation.
class ScenarioBriefPage : public QWidget {
    Q_OBJECT
public:
    explicit ScenarioBriefPage(ApiClient* api, QWidget* parent = nullptr);
    void load(const QString& scenarioId);

signals:
    void startRequested(const QString& scenarioId, const QString& title);
    void backRequested();

private:
    QLabel* pill(const QString& text);

    ApiClient*   m_api;
    QString      m_id;
    QString      m_title;

    QLabel*      m_crumb;
    QLabel*      m_heroTitle;
    QLabel*      m_heroDesc;
    QHBoxLayout* m_pillRow;     // CEFR / time / XP
    QLabel*      m_youRole;
    QLabel*      m_tutorRole;
    QVBoxLayout* m_objList;
    QVBoxLayout* m_phraseList;
    QLabel*      m_objHeader;
    QLabel*      m_phraseHeader;
    QPushButton* m_start;
};
