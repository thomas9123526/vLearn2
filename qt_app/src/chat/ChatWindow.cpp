#include "chat/ChatWindow.h"
#include "api/ApiClient.h"

#include <QListWidget>
#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include <QWidget>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QInputDialog>
#include <QMessageBox>
#include <QStatusBar>
#include <QJsonValue>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>

ChatWindow::ChatWindow(ApiClient* api, QWidget* parent)
    : QMainWindow(parent)
    , m_api(api)
{
    setWindowTitle(tr("vLearn2 — Chat"));

    m_transcript = new QListWidget(this);
    m_transcript->setWordWrap(true);
    m_transcript->setSelectionMode(QAbstractItemView::NoSelection);
    m_transcript->setFocusPolicy(Qt::NoFocus);
    m_transcript->setStyleSheet("QListWidget{border:none;background:#f5f5f7;}"
                                "QListWidget::item{padding:8px;margin:4px;}");

    m_input = new QLineEdit(this);
    m_input->setPlaceholderText(tr("Type a message…"));
    m_input->setClearButtonEnabled(true);

    m_send = new QPushButton(tr("Send"), this);
    m_send->setDefault(true);

    auto* inputRow = new QHBoxLayout;
    inputRow->addWidget(m_input, /*stretch=*/1);
    inputRow->addWidget(m_send);

    auto* root = new QVBoxLayout;
    root->setContentsMargins(8, 8, 8, 8);
    root->addWidget(m_transcript, /*stretch=*/1);
    root->addLayout(inputRow);

    auto* central = new QWidget(this);
    central->setLayout(root);
    setCentralWidget(central);

    m_status = new QLabel(this);
    statusBar()->addWidget(m_status);

    resize(560, 720);

    connect(m_send,  &QPushButton::clicked,     this, &ChatWindow::onSend);
    connect(m_input, &QLineEdit::returnPressed, this, &ChatWindow::onSend);

    // Block input until a session exists.
    setSending(true);
    m_status->setText(tr("Hello %1 — starting a chat…").arg(m_api->displayName()));
    startNewChat();
}

void ChatWindow::startNewChat()
{
    m_api->listTeachers([this](bool ok, const QJsonValue& data, const QString& err) {
        if (!ok || !data.isArray() || data.toArray().isEmpty()) {
            QMessageBox::critical(this, tr("Cannot start chat"),
                tr("Could not load tutors: %1")
                    .arg(ok ? tr("no personas returned") : err));
            return;
        }

        const QJsonArray arr = data.toArray();
        QVector<Persona> personas;
        QStringList names;
        for (const QJsonValue& v : arr) {
            const Persona p = Persona::fromJson(v.toObject());
            personas.push_back(p);
            names << (p.name.isEmpty() ? p.id : p.name);
        }

        bool chose = false;
        const QString picked = QInputDialog::getItem(
            this, tr("Choose a tutor"), tr("Tutor:"), names, 0, false, &chose);
        if (!chose) {           // user cancelled → close the window
            close();
            return;
        }
        const Persona& persona = personas.at(qMax(0, names.indexOf(picked)));

        m_status->setText(tr("Starting session with %1…").arg(persona.name));
        m_api->startSession(persona.id, "message",
            [this](bool ok2, const QJsonValue& sdata, const QString& serr) {
                if (!ok2 || !sdata.isObject()) {
                    QMessageBox::critical(this, tr("Cannot start chat"),
                        tr("Failed to start session: %1").arg(serr));
                    return;
                }
                const Session s = Session::fromJson(sdata.toObject());
                m_sessionId = s.id;
                m_transcript->clear();
                setSending(false);
                m_status->setText(tr("Connected. Say hello!"));
                m_input->setFocus();
            });
    });
}

void ChatWindow::onSend()
{
    const QString text = m_input->text().trimmed();
    if (text.isEmpty() || m_sessionId.isEmpty())
        return;

    appendMessage("user", text);
    m_input->clear();
    setSending(true);
    m_status->setText(tr("Tutor is typing…"));

    m_api->sendMessage(m_sessionId, text,
        [this](bool ok, const QJsonValue& data, const QString& err) {
            setSending(false);
            if (!ok || !data.isObject()) {
                m_status->setText(tr("Send failed: %1").arg(err));
                return;
            }
            const QJsonObject o = data.toObject();
            appendMessage(Message::fromJson(o.value("assistantMessage").toObject()));
            const int turns = o.value("turnCount").toInt();
            m_status->setText(tr("Turn %1").arg(turns));
            m_input->setFocus();
        });
}

void ChatWindow::appendMessage(const Message& m)
{
    appendMessage(m.role, m.content);
}

void ChatWindow::appendMessage(const QString& role, const QString& content)
{
    const bool mine = (role == QLatin1String("user"));
    auto* item = new QListWidgetItem(content, m_transcript);
    item->setTextAlignment(mine ? (Qt::AlignRight | Qt::AlignVCenter)
                                 : (Qt::AlignLeft  | Qt::AlignVCenter));
    item->setBackground(mine ? QColor("#d6e4ff") : QColor("#ffffff"));
    m_transcript->scrollToBottom();
}

void ChatWindow::setSending(bool sending)
{
    m_send->setEnabled(!sending);
    m_input->setEnabled(!sending);
}
