#include "auth/LoginDialog.h"
#include "api/ApiClient.h"

#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include <QFormLayout>
#include <QVBoxLayout>
#include <QJsonValue>

LoginDialog::LoginDialog(ApiClient* api, QWidget* parent)
    : QDialog(parent)
    , m_api(api)
{
    setWindowTitle(tr("vLearn2 — Sign in"));
    setModal(true);

    m_username = new QLineEdit(this);
    m_username->setPlaceholderText(tr("e.g. kky1206"));

    m_password = new QLineEdit(this);
    m_password->setEchoMode(QLineEdit::Password);

    auto* form = new QFormLayout;
    form->addRow(tr("Username"), m_username);
    form->addRow(tr("Password"), m_password);

    m_error = new QLabel(this);
    m_error->setStyleSheet("color:#c0392b;");
    m_error->setWordWrap(true);
    m_error->hide();

    m_signIn = new QPushButton(tr("Sign in"), this);
    m_signIn->setDefault(true);

    auto* root = new QVBoxLayout(this);
    root->addLayout(form);
    root->addWidget(m_error);
    root->addWidget(m_signIn);
    resize(360, sizeHint().height());

    connect(m_signIn,   &QPushButton::clicked, this, &LoginDialog::attemptSignIn);
    connect(m_password, &QLineEdit::returnPressed, this, &LoginDialog::attemptSignIn);
}

void LoginDialog::setBusy(bool busy)
{
    m_signIn->setEnabled(!busy);
    m_username->setEnabled(!busy);
    m_password->setEnabled(!busy);
    m_signIn->setText(busy ? tr("Signing in…") : tr("Sign in"));
}

void LoginDialog::attemptSignIn()
{
    const QString user = m_username->text().trimmed();
    const QString pass = m_password->text();
    if (user.isEmpty() || pass.isEmpty()) {
        m_error->setText(tr("Enter both username and password."));
        m_error->show();
        return;
    }

    m_error->hide();
    setBusy(true);

    m_api->signIn(user, pass,
        [this](bool ok, const QJsonValue&, const QString& err) {
            setBusy(false);
            if (ok) {
                accept();
            } else {
                m_error->setText(err.isEmpty() ? tr("Sign-in failed.") : err);
                m_error->show();
            }
        });
}
