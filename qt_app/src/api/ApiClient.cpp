#include "api/ApiClient.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>

ApiClient::ApiClient(QString baseUrl, QObject* parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_baseUrl(std::move(baseUrl))
{
    // Drop any trailing slash so path concatenation is predictable.
    while (m_baseUrl.endsWith('/'))
        m_baseUrl.chop(1);
}

void ApiClient::request(const QByteArray& method,
                        const QString& path,
                        const QJsonObject* body,
                        Callback cb,
                        bool auth)
{
    QNetworkRequest req{QUrl(m_baseUrl + path)};
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (auth && !m_accessToken.isEmpty())
        req.setRawHeader("Authorization", "Bearer " + m_accessToken.toUtf8());

    const QByteArray payload =
        body ? QJsonDocument(*body).toJson(QJsonDocument::Compact) : QByteArray();

    QNetworkReply* reply =
        (method == "GET") ? m_nam->get(req)
                          : m_nam->sendCustomRequest(req, method, payload);

    QObject::connect(reply, &QNetworkReply::finished, this, [reply, cb]() {
        reply->deleteLater();

        const int status =
            reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray raw = reply->readAll();

        QJsonParseError perr;
        const QJsonDocument doc = QJsonDocument::fromJson(raw, &perr);

        const bool httpOk = status >= 200 && status < 300;
        if (httpOk && reply->error() == QNetworkReply::NoError) {
            QJsonValue data;
            if (doc.isObject())      data = doc.object();
            else if (doc.isArray())  data = doc.array();
            if (cb) cb(true, data, QString());
            return;
        }

        // Error path — prefer the backend's `message`, which may be a string
        // or an array of validation messages.
        QString msg;
        if (doc.isObject()) {
            const QJsonValue m = doc.object().value("message");
            if (m.isString())      msg = m.toString();
            else if (m.isArray() && !m.toArray().isEmpty())
                msg = m.toArray().first().toString();
        }
        if (msg.isEmpty())
            msg = status > 0 ? QStringLiteral("HTTP %1").arg(status)
                             : reply->errorString();
        if (cb) cb(false, QJsonValue(), msg);
    });
}

void ApiClient::signIn(const QString& cidUsername,
                       const QString& password,
                       Callback cb)
{
    QJsonObject body{
        {"cidUsername", cidUsername},
        {"password",    password},
    };
    request("POST", "/auth/signin", &body,
            [this, cb](bool ok, const QJsonValue& data, const QString& err) {
                if (ok && data.isObject()) {
                    const QJsonObject o = data.toObject();
                    m_accessToken  = o.value("accessToken").toString();
                    m_refreshToken = o.value("refreshToken").toString();
                    m_displayName  = o.value("displayName").toString();
                }
                if (cb) cb(ok, data, err);
            },
            /*auth=*/false);
}

void ApiClient::listTeachers(Callback cb)
{
    request("GET", "/teachers", nullptr, std::move(cb), /*auth=*/true);
}

void ApiClient::startSession(const QString& personaId,
                             const QString& mode,
                             Callback cb)
{
    QJsonObject body{
        {"personaId", personaId},
        {"mode",      mode},        // "message" for chat mode
    };
    request("POST", "/conversations/sessions", &body, std::move(cb), true);
}

void ApiClient::getSession(const QString& id, Callback cb)
{
    request("GET", "/conversations/sessions/" + id, nullptr, std::move(cb), true);
}

void ApiClient::sendMessage(const QString& sessionId,
                            const QString& content,
                            Callback cb)
{
    QJsonObject body{{"content", content}};
    request("POST", "/conversations/sessions/" + sessionId + "/messages",
            &body, std::move(cb), true);
}

void ApiClient::endSession(const QString& sessionId, Callback cb)
{
    QJsonObject body{{"status", "completed"}};
    request("POST", "/conversations/sessions/" + sessionId + "/end",
            &body, std::move(cb), true);
}
