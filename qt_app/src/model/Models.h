#pragma once

#include <QString>
#include <QDateTime>
#include <QJsonObject>

// Plain data structs mirroring the backend DTOs (see
// backend/src/conversations/dto/conversation.dto.ts). Kept deliberately
// minimal — only the fields the chat UI actually reads.

struct Persona {
    QString id;
    QString name;

    static Persona fromJson(const QJsonObject& o) {
        Persona p;
        p.id   = o.value("id").toString();
        // Backend persona uses "name"; fall back to displayName/slug.
        p.name = o.value("name").toString(
                     o.value("displayName").toString(
                         o.value("slug").toString()));
        return p;
    }
};

struct Message {
    QString  id;
    QString  role;     // "user" | "assistant"
    QString  content;
    int      sequence = 0;

    bool isUser() const { return role == QLatin1String("user"); }

    static Message fromJson(const QJsonObject& o) {
        Message m;
        m.id       = o.value("id").toString();
        m.role     = o.value("role").toString();
        m.content  = o.value("content").toString();
        m.sequence = o.value("sequence").toInt();
        return m;
    }
};

struct Session {
    QString id;
    QString personaId;
    QString mode;      // "chat" | "face"
    QString status;    // "active" | "completed" | "abandoned"
    int     turnCount = 0;

    static Session fromJson(const QJsonObject& o) {
        Session s;
        s.id        = o.value("id").toString();
        s.personaId = o.value("personaId").toString();
        s.mode      = o.value("mode").toString();
        s.status    = o.value("status").toString();
        s.turnCount = o.value("turnCount").toInt();
        return s;
    }
};
