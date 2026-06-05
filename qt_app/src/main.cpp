#include <QApplication>
#include <QMessageBox>
#include <QPointer>
#include <QIcon>
#include <functional>

#include "config/AppConfig.h"
#include "ui/Theme.h"
#include "i18n/I18n.h"
#include "api/ApiClient.h"
#include "auth/LoginDialog.h"
#include "shell/MainShell.h"

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
    QApplication::setOrganizationName("vlearn");
    QApplication::setApplicationName("FreeTalk");
    QApplication::setWindowIcon(QIcon(":/icons/app.png"));
    QApplication::setDesktopFileName("vlearn");   // links the window to vlearn.desktop

    // FreeTalk look: load fonts + apply the active theme; install i18n.
    Theme::install(app);
    I18n::install(app);

    // 1. Read the endpoint from app_config.json BEFORE any networking.
    const AppConfig cfg = AppConfig::load(configPathArg(app));
    if (!cfg.isValid()) {
        QMessageBox::critical(
            nullptr, QObject::tr("Configuration error"),
            QObject::tr("The app could not determine the backend endpoint.\n\n%1")
                .arg(cfg.error));
        return 1;
    }

    // 2. Build the network client against the configured base URL.
    ApiClient api(cfg.baseUrl);

    LoginDialog login(&api);
    if (login.exec() != QDialog::Accepted)
        return 0;   // user cancelled sign-in

    // 3. Build the shell. On a theme change we apply the new palette and
    //    recreate the shell so every widget (incl. inline-styled ones) re-skins.
    QPointer<MainShell> shell;
    std::function<void()> build = [&]() {
        shell = new MainShell(&api);
        QObject::connect(shell, &MainShell::appearanceChangeRequested, &app, [&]() {
            // The setting was already applied (Theme/I18n); rebuild so inline
            // styles, fonts and tr() strings all refresh.
            MainShell* old = shell;
            build();
            shell->show();
            if (old) { old->hide(); old->deleteLater(); }
        });
        shell->show();
    };
    build();
    return app.exec();
}
