#include "auth/LoginDialog.h"
#include "api/ApiClient.h"

#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include <QCheckBox>
#include <QFormLayout>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QVariant>
#include <QSettings>
#include <QByteArray>
#include <QJsonValue>

// Stored under [auth] in QSettings. Base64 is light obfuscation only — same
// "remember me" convenience the Flutter app offers, not real secret storage.
static QString unobfuscate(const QString& b64)
{
    return QString::fromUtf8(QByteArray::fromBase64(b64.toUtf8()));
}
static QString obfuscate(const QString& s)
{
    return QString::fromUtf8(s.toUtf8().toBase64());
}

LoginDialog::LoginDialog(ApiClient* api, QWidget* parent)
    : QDialog(parent)
    , m_api(api)
{
    setWindowTitle(tr("FreeTalk — Sign in"));
    setModal(true);

    auto* free = new QLabel("Free", this); free->setObjectName("Logo");
    auto* talk = new QLabel("Talk", this); talk->setObjectName("LogoAccent");
    auto* logo = new QHBoxLayout;
    logo->setSpacing(0);
    logo->addStretch(1);
    logo->addWidget(free);
    logo->addWidget(talk);
    logo->addStretch(1);

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

    m_remember = new QCheckBox(tr("Remember me"), this);

    m_signIn = new QPushButton(tr("Sign in"), this);
    m_signIn->setDefault(true);
    m_signIn->setProperty("variant", QStringLiteral("primary"));
    m_signIn->setCursor(Qt::PointingHandCursor);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(28, 24, 28, 24);
    root->setSpacing(14);
    root->addLayout(logo);
    root->addSpacing(6);
    root->addLayout(form);
    root->addWidget(m_remember);
    root->addWidget(m_error);
    root->addWidget(m_signIn);
    resize(380, sizeHint().height());

    // Prefill from a previous successful sign-in.
    QSettings s;
    if (s.value("auth/remember", true).toBool()) {
        m_username->setText(s.value("auth/username").toString());
        m_password->setText(unobfuscate(s.value("auth/password").toString()));
        m_remember->setChecked(true);
    }

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
        [this, user, pass](bool ok, const QJsonValue&, const QString& err) {
            setBusy(false);
            if (ok) {
                QSettings s;
                s.setValue("auth/remember", m_remember->isChecked());
                if (m_remember->isChecked()) {
                    s.setValue("auth/username", user);
                    s.setValue("auth/password", obfuscate(pass));
                } else {
                    s.remove("auth/username");
                    s.remove("auth/password");
                }
                accept();
            } else {
                m_error->setText(err.isEmpty() ? tr("Sign-in failed.") : err);
                m_error->show();
            }
        });
}
