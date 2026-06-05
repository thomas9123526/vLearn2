#pragma once

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonValue>
#include <functional>

class QNetworkAccessManager;

// Thin REST wrapper around the vLearn2 Nest.js backend.
//
// All calls are asynchronous: you pass a Callback that fires on the Qt event
// loop when the reply arrives. `ok` is true for HTTP 2xx; otherwise `error`
// holds a human-readable message (the backend's `message` field when present,
// else the transport error).
//
// The JWT access token from signIn() is stored in-memory and attached as a
// Bearer header to every authenticated request.
class ApiClient : public QObject {
    Q_OBJECT
public:
    using Callback = std::function<void(bool ok,
                                        const QJsonValue& data,
                                        const QString& error)>;

    explicit ApiClient(QString baseUrl, QObject* parent = nullptr);

    // Auth
    void signIn(const QString& cidUsername, const QString& password, Callback cb);

    // Layout flags (tab visibility etc.)
    void getAppConfig(Callback cb);   // GET /app-config -> { flags: {...} }

    // Profile / dashboard data
    void getProfile(Callback cb);     // GET /users/profile
    void updateProfile(const QJsonObject& patch, Callback cb);  // PATCH /users/profile
    void getProgress(Callback cb);    // GET /progress
    void listScenarios(Callback cb);  // GET /scenarios
    void getScenario(const QString& idOrSlug, Callback cb);  // GET /scenarios/:id

    // Personas (needed to start a session)
    void listTeachers(Callback cb);

    // Conversation (chat mode)
    void startSession(const QString& personaId, const QString& mode /* "chat"|"face" */,
                      const QString& scenarioId, Callback cb);
    void listSessions(Callback cb);
    void getSession(const QString& id, Callback cb);
    void sendMessage(const QString& sessionId, const QString& content, Callback cb);
    void endSession(const QString& sessionId, Callback cb);

    bool    isAuthed()    const { return !m_accessToken.isEmpty(); }
    QString displayName() const { return m_displayName; }

private:
    void request(const QByteArray& method,
                 const QString& path,
                 const QJsonObject* body,   // nullptr → no body
                 Callback cb,
                 bool auth);

    QNetworkAccessManager* m_nam;
    QString m_baseUrl;       // e.g. http://localhost:5101/api
    QString m_accessToken;
    QString m_refreshToken;
    QString m_displayName;
};
