#include <QApplication>
#include <QMessageBox>

#include "config/AppConfig.h"
#include "api/ApiClient.h"
#include "auth/LoginDialog.h"
#include "chat/ChatWindow.h"

// Optional override: ./vlearn_chat --config /path/to/app_config.json
static QString configPathArg(const QApplication& app)
{
    const QStringList args = app.arguments();
    const int i = args.indexOf("--config");
    if (i >= 0 && i + 1 < args.size())
        return args.at(i + 1);
    return QString();
}

int main(int argc, char** argv)
{
    QApplication app(argc, argv);
    QApplication::setApplicationName("vLearn2 Chat");

    // 1. Read the endpoint from app_config.json BEFORE any networking.
    const AppConfig cfg = AppConfig::load(configPathArg(app));
    if (!cfg.isValid()) {
        QMessageBox::critical(
            nullptr, QObject::tr("Configuration error"),
            QObject::tr("The app could not determine the backend endpoint.\n\n%1")
                .arg(cfg.error));
        return 1;
    }

    // 2. Now build the network client against the configured base URL.
    ApiClient api(cfg.baseUrl);

    LoginDialog login(&api);
    if (login.exec() != QDialog::Accepted)
        return 0;   // user cancelled sign-in

    ChatWindow win(&api);
    win.setWindowTitle(QObject::tr("vLearn2 — Chat  (%1)").arg(cfg.baseUrl));
    win.show();
    return app.exec();
}
