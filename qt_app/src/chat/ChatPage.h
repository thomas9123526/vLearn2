#pragma once

#include <QWidget>
#include "model/Models.h"

class ApiClient;
class QVBoxLayout;
class QScrollArea;
class QLineEdit;
class QPushButton;
class QLabel;

// FreeTalk-styled chat screen (header + transcript of bubbles + quick replies
// + rounded input bar). Lives inside MainShell's stacked content area.
class ChatPage : public QWidget {
    Q_OBJECT
public:
    explicit ChatPage(ApiClient* api, QWidget* parent = nullptr);

    void startNewChat();                 // pick persona → POST /sessions
    void startScenario(const QString& scenarioId, const QString& title); // first tutor + scenario
    void openSession(const QString& id); // GET /sessions/:id → render history

signals:
    void statusMessage(const QString& text);

private slots:
    void onSend();

private:
    void  setHeader(const QString& name, const QColor& accent, const QString& sub);
    // GET /sessions/:id → render header + all messages (incl. the tutor's
    // seeded opening line). Used by every entry path.
    void  renderSession(const QString& id, const QString& preferredName,
                        const QColor& preferredAccent);
    void  clearTranscript();
    void  addDatePill(const QString& text);
    void  appendBubble(const QString& role, const QString& content);
    void  setSending(bool sending);
    void  scrollToBottom();

    ApiClient* m_api;
    QString    m_sessionId;
    QString    m_personaName;

    // header
    QWidget*   m_avatarHolder;
    QLabel*    m_titleLabel;
    QLabel*    m_subLabel;

    // transcript
    QScrollArea* m_scroll;
    QVBoxLayout* m_msgLayout;   // holds bubble rows + a trailing stretch

    // input
    QLineEdit*   m_input;
    QPushButton* m_send;
};
