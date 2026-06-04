#pragma once

#include <QMainWindow>
#include "model/Models.h"

class ApiClient;
class QListWidget;
class QLineEdit;
class QPushButton;
class QLabel;

// The chat-mode screen: a scrolling transcript + an input row.
// On open it loads the persona list, lets the user pick one, starts a
// `message`-mode session, then drives the send/reply loop.
class ChatWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit ChatWindow(ApiClient* api, QWidget* parent = nullptr);

private slots:
    void onSend();

private:
    void startNewChat();                 // pick persona → start session
    void appendMessage(const Message& m);
    void appendMessage(const QString& role, const QString& content);
    void setSending(bool sending);

    ApiClient*   m_api;
    QString      m_sessionId;

    QListWidget* m_transcript;
    QLineEdit*   m_input;
    QPushButton* m_send;
    QLabel*      m_status;   // "Tutor is typing…" / errors
};
