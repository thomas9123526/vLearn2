#include <QApplication>

#include "MainWindow.h"

int main(int argc, char* argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KeyGenerator"));
    app.setOrganizationName(QStringLiteral("vLearn2"));
    // OrganizationDomain doubles as the QSettings vendor key on
    // Windows -- keep it stable so saved field values survive
    // version upgrades.
    app.setOrganizationDomain(QStringLiteral("vlearn2.local"));

    MainWindow w;
    w.show();
    return app.exec();
}
