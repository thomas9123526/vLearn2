#include "chat/ChatPage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QScrollBar>
#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include <QFrame>
#include <QInputDialog>
#include <QMessageBox>
#include <QTimer>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>

static QHBoxLayout* rowWrapper(QWidget* w, bool alignRight)
{
    auto* row = new QHBoxLayout;
    row->setContentsMargins(0, 2, 0, 2);
    if (alignRight) { row->addStretch(1); row->addWidget(w); }
    else            { row->addWidget(w);  row->addStretch(1); }
    return row;
}

ChatPage::ChatPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    // ---- Header --------------------------------------------------------
    auto* header = new QFrame;
    header->setObjectName("Header");
    auto* hl = new QHBoxLayout(header);
    hl->setContentsMargins(20, 14, 20, 14);
    hl->setSpacing(12);

    m_avatarHolder = new QWidget;
    auto* ah = new QHBoxLayout(m_avatarHolder);
    ah->setContentsMargins(0, 0, 0, 0);
    ah->addWidget(Theme::makeAvatar("?", 42, Theme::palette().accent));

    auto* titles = new QVBoxLayout;
    titles->setSpacing(0);
    m_titleLabel = new QLabel(tr("Tutor"));
    m_titleLabel->setStyleSheet("font-size:16px;font-weight:700;");
    m_subLabel = new QLabel(tr("AI Tutor · Online"));
    m_subLabel->setObjectName("Sub");
    titles->addWidget(m_titleLabel);
    titles->addWidget(m_subLabel);

    hl->addWidget(m_avatarHolder);
    hl->addLayout(titles);
    hl->addStretch(1);

    // ---- Transcript ----------------------------------------------------
    m_scroll = new QScrollArea;
    m_scroll->setObjectName("Transcript");
    m_scroll->setWidgetResizable(true);
    m_scroll->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);

    auto* canvas = new QWidget;
    canvas->setObjectName("Transcript");
    m_msgLayout = new QVBoxLayout(canvas);
    m_msgLayout->setContentsMargins(80, 16, 80, 16);
    m_msgLayout->setSpacing(2);
    m_msgLayout->addStretch(1);
    m_scroll->setWidget(canvas);

    // ---- Input bar -----------------------------------------------------
    auto* inputBar = new QFrame;
    inputBar->setObjectName("InputBar");
    auto* il = new QHBoxLayout(inputBar);
    il->setContentsMargins(12, 10, 12, 10);
    il->setSpacing(10);

    m_input = new QLineEdit;
    m_input->setPlaceholderText(tr("Type a message…"));
    m_send = new QPushButton("➤");
    m_send->setObjectName("SendBtn");
    m_send->setCursor(Qt::PointingHandCursor);
    il->addWidget(m_input, 1);
    il->addWidget(m_send);

    auto* inputWrap = new QHBoxLayout;
    inputWrap->setContentsMargins(80, 0, 80, 12);
    inputWrap->addWidget(inputBar);

    // ---- Assemble ------------------------------------------------------
    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(0, 0, 0, 0);
    root->setSpacing(0);
    root->addWidget(header);
    root->addWidget(m_scroll, 1);
    root->addLayout(inputWrap);

    connect(m_send,  &QPushButton::clicked,     this, &ChatPage::onSend);
    connect(m_input, &QLineEdit::returnPressed, this, &ChatPage::onSend);

    setSending(true);
}

void ChatPage::setHeader(const QString& name, const QColor& accent, const QString& sub)
{
    m_personaName = name;
    // Replace the avatar with one tinted for this persona.
    QLayoutItem* old;
    auto* ah = qobject_cast<QHBoxLayout*>(m_avatarHolder->layout());
    while ((old = ah->takeAt(0)) != nullptr) { delete old->widget(); delete old; }
    ah->addWidget(Theme::makeAvatar(name, 42, accent));
    m_titleLabel->setText(name);
    m_subLabel->setText(sub);
}

void ChatPage::clearTranscript()
{
    QLayoutItem* item;
    while ((item = m_msgLayout->takeAt(0)) != nullptr) {
        if (item->widget()) item->widget()->deleteLater();
        if (item->layout()) {
            QLayoutItem* c;
            while ((c = item->layout()->takeAt(0)) != nullptr) {
                if (c->widget()) c->widget()->deleteLater();
                delete c;
            }
            delete item->layout();
        }
        delete item;
    }
    m_msgLayout->addStretch(1);
}

void ChatPage::addDatePill(const QString& text)
{
    auto* pill = new QLabel(text);
    pill->setObjectName("DatePill");
    pill->setAlignment(Qt::AlignCenter);
    auto* row = new QHBoxLayout;
    row->addStretch(1);
    row->addWidget(pill);
    row->addStretch(1);
    m_msgLayout->insertLayout(m_msgLayout->count() - 1, row);
}

void ChatPage::appendBubble(const QString& role, const QString& content)
{
    const bool mine = (role == QLatin1String("user"));
    auto* bubble = new QLabel(content);
    bubble->setObjectName(mine ? "BubbleMe" : "BubbleTutor");
    bubble->setWordWrap(true);
    bubble->setTextInteractionFlags(Qt::TextSelectableByMouse);
    bubble->setMaximumWidth(440);
    bubble->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Preferred);

    m_msgLayout->insertLayout(m_msgLayout->count() - 1, rowWrapper(bubble, mine));
    scrollToBottom();
}

void ChatPage::scrollToBottom()
{
    // Defer until the layout has applied the new row's geometry.
    QTimer::singleShot(0, this, [this]() {
        m_scroll->verticalScrollBar()->setValue(
            m_scroll->verticalScrollBar()->maximum());
    });
}

void ChatPage::setSending(bool sending)
{
    m_send->setEnabled(!sending);
    m_input->setEnabled(!sending);
}

void ChatPage::startNewChat()
{
    emit statusMessage(tr("Loading tutors…"));
    m_api->listTeachers([this](bool ok, const QJsonValue& data, const QString& err) {
        if (!ok || !data.isArray() || data.toArray().isEmpty()) {
            QMessageBox::critical(this, tr("Cannot start chat"),
                tr("Could not load tutors: %1")
                    .arg(ok ? tr("no personas returned") : err));
            return;
        }
        QVector<Persona> personas;
        QStringList names;
        for (const QJsonValue& v : data.toArray()) {
            const Persona p = Persona::fromJson(v.toObject());
            personas.push_back(p);
            names << (p.name.isEmpty() ? p.id : p.name);
        }

        bool chose = false;
        const QString picked = QInputDialog::getItem(
            this, tr("Choose a tutor"), tr("Tutor:"), names, 0, false, &chose);
        if (!chose) return;
        const Persona& persona = personas.at(qMax(0, names.indexOf(picked)));

        emit statusMessage(tr("Starting session with %1…").arg(persona.name));
        m_api->startSession(persona.id, "chat",
            [this, persona](bool ok2, const QJsonValue& sdata, const QString& serr) {
                if (!ok2 || !sdata.isObject()) {
                    QMessageBox::critical(this, tr("Cannot start chat"),
                        tr("Failed to start session: %1").arg(serr));
                    return;
                }
                const Session s = Session::fromJson(sdata.toObject());
                m_sessionId = s.id;
                clearTranscript();
                setHeader(persona.name, Theme::personaAccent(persona.name),
                          tr("AI Tutor · Online"));
                addDatePill(tr("New conversation"));
                setSending(false);
                emit statusMessage(tr("Connected. Say hello!"));
                m_input->setFocus();
            });
    });
}

void ChatPage::openSession(const QString& id)
{
    emit statusMessage(tr("Loading conversation…"));
    m_api->getSession(id, [this, id](bool ok, const QJsonValue& data, const QString& err) {
        if (!ok || !data.isObject()) {
            QMessageBox::critical(this, tr("Cannot open"),
                tr("Failed to load conversation: %1").arg(err));
            return;
        }
        const QJsonObject o = data.toObject();
        const Session s = Session::fromJson(o);
        m_sessionId = s.id;

        clearTranscript();
        setHeader(tr("Tutor"), Theme::personaAccent(s.personaId),
                  s.status == "active" ? tr("AI Tutor · Online")
                                       : tr("Past conversation"));
        addDatePill(s.status == "active" ? tr("Conversation") : tr("Past conversation"));

        for (const QJsonValue& mv : o.value("messages").toArray()) {
            const Message m = Message::fromJson(mv.toObject());
            appendBubble(m.role, m.content);
        }
        // Read-only when the session is finished.
        setSending(s.status != "active");
        emit statusMessage(s.status == "active" ? tr("Continue the conversation")
                                                : tr("This conversation has ended"));
    });
}

void ChatPage::onSend()
{
    const QString text = m_input->text().trimmed();
    if (text.isEmpty() || m_sessionId.isEmpty()) return;

    appendBubble("user", text);
    m_input->clear();
    setSending(true);
    emit statusMessage(tr("Tutor is typing…"));

    m_api->sendMessage(m_sessionId, text,
        [this](bool ok, const QJsonValue& data, const QString& err) {
            setSending(false);
            if (!ok || !data.isObject()) {
                emit statusMessage(tr("Send failed: %1").arg(err));
                return;
            }
            const QJsonObject o = data.toObject();
            appendBubble("assistant",
                Message::fromJson(o.value("assistantMessage").toObject()).content);
            emit statusMessage(tr("Turn %1").arg(o.value("turnCount").toInt()));
            m_input->setFocus();
        });
}
