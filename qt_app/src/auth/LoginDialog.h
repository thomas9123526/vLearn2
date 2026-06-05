#pragma once

#include <QDialog>

class ApiClient;
class QLineEdit;
class QPushButton;
class QLabel;
class QCheckBox;

// Simple sign-in dialog: cidUsername + password → POST /auth/signin.
// On success the dialog accept()s and ApiClient holds the JWT.
class LoginDialog : public QDialog {
    Q_OBJECT
public:
    explicit LoginDialog(ApiClient* api, QWidget* parent = nullptr);

private slots:
    void attemptSignIn();

private:
    void setBusy(bool busy);

    ApiClient*   m_api;
    QLineEdit*   m_username;
    QLineEdit*   m_password;
    QPushButton* m_signIn;
    QLabel*      m_error;
    QCheckBox*   m_remember;
};
