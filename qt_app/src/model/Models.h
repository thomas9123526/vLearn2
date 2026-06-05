#pragma once

#include <QString>
#include <QStringList>
#include <QDateTime>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

// I18nTextDto {en,ko,zh} or a plain string → pick a readable string (prefer en).
inline QString localized(const QJsonValue& v)
{
    if (v.isString()) return v.toString();
    if (v.isObject()) {
        const QJsonObject o = v.toObject();
        for (const char* k : {"en", "ko", "zh"}) {
            const QString s = o.value(k).toString();
            if (!s.isEmpty()) return s;
        }
    }
    return QString();
}

// CEFR label from a 1-based level (1→A1 … 6→C2).
inline QString cefrLabel(int level)
{
    static const char* k[] = {"A1", "A2", "B1", "B2", "C1", "C2"};
    return k[qBound(0, level - 1, 5)];
}

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

// GET /users/profile (UserProfileDto)
struct UserProfile {
    QString displayName;
    QString email;
    QString avatarEmoji;
    QString activePersonaId;
    QString uiLanguage;
    QString activeTheme;
    int     currentLevel = 1;
    int     xpTotal      = 0;
    int     streakDays   = 0;

    QString cefr() const { return cefrLabel(currentLevel); }

    static UserProfile fromJson(const QJsonObject& o) {
        UserProfile u;
        u.displayName     = o.value("displayName").toString();
        u.email           = o.value("email").toString();
        u.avatarEmoji     = o.value("avatarEmoji").toString();
        u.activePersonaId = o.value("activePersonaId").toString();
        u.uiLanguage      = o.value("uiLanguage").toString();
        u.activeTheme     = o.value("activeTheme").toString();
        u.currentLevel    = o.value("currentLevel").toInt(1);
        u.xpTotal         = o.value("xpTotal").toInt();
        u.streakDays      = o.value("streakDays").toInt();
        return u;
    }
};

// GET /scenarios (titles/descriptions are I18nTextDto)
struct Scenario {
    QString id;
    QString category;
    QString title;
    QString description;
    int     estimatedMinutes = 0;
    int     xpReward = 0;
    int     cefrLevel = 0;
    // Detail-only (GET /scenarios/:id): i18n role text + objectives/phrases.
    QString     sceneDescription;
    QString     userRole;
    QString     tutorRole;
    QStringList objectives;
    QStringList keyPhrases;

    static Scenario fromJson(const QJsonObject& o) {
        Scenario s;
        s.id          = o.value("id").toString();
        s.category    = o.value("category").toString();
        s.title       = localized(o.value("title"));
        s.description = localized(o.value("description"));
        // Accept camelCase or snake_case.
        s.estimatedMinutes = o.value("estimatedMinutes").toInt(
                                 o.value("estimated_minutes").toInt());
        s.xpReward         = o.value("xpReward").toInt(
                                 o.value("xp_reward").toInt());
        s.cefrLevel        = o.value("cefrLevel").toInt(
                                 o.value("cefr_level").toInt());

        // Detail fields (present on GET /scenarios/:id).
        s.sceneDescription = localized(o.value("scene_description"));
        s.userRole         = localized(o.value("user_role"));
        s.tutorRole        = localized(o.value("tutor_role"));
        for (const QJsonValue& v : o.value("objectives").toArray()) {
            const QString t = localized(v);          // {en,ko,zh}
            if (!t.isEmpty()) s.objectives << t;
        }
        for (const QJsonValue& v : o.value("key_phrases").toArray()) {
            const QString p = v.toObject().value("phrase").toString();
            if (!p.isEmpty()) s.keyPhrases << p;
        }
        return s;
    }
};

// GET /progress (summary)
struct ProgressSummary {
    int sessionsTotal = 0;
    int minutesTotal  = 0;
    int scenariosDone = 0;

    static ProgressSummary fromJson(const QJsonObject& o) {
        ProgressSummary p;
        p.sessionsTotal = o.value("sessions_total").toInt();
        p.minutesTotal  = o.value("minutes_spoken_total").toInt();
        p.scenariosDone = o.value("scenarios_completed").toInt();
        return p;
    }
};
