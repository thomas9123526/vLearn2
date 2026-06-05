#include "settings/SettingsPage.h"
#include "api/ApiClient.h"
#include "asr/AsrService.h"
#include "asr/TtsService.h"
#include "ui/Theme.h"
#include "ui/ClickableFrame.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QLabel>
#include <QFrame>
#include <QPushButton>
#include <QDialog>
#include <QLineEdit>
#include <QFormLayout>
#include <QMessageBox>
#include <QVariant>
#include <QJsonObject>
#include <QJsonValue>

QWidget* SettingsPage::sectionHeader(const QString& text)
{
    auto* l = new QLabel(text.toUpper());
    l->setObjectName("Kicker");
    l->setContentsMargins(4, 12, 0, 2);
    return l;
}

// A list tile: leading icon glyph, title (+ optional value subtitle), chevron.
QWidget* SettingsPage::tile(const QString& icon, const QString& title,
                            const QString& value, bool chevron, bool danger)
{
    auto* row = new ClickableFrame;
    row->setObjectName("Card");
    auto* h = new QHBoxLayout(row);
    h->setContentsMargins(16, 12, 16, 12);
    h->setSpacing(14);

    auto* ic = new QLabel(icon);
    ic->setFixedWidth(24);
    ic->setStyleSheet(QStringLiteral("font-size:16px;color:%1;")
                          .arg((danger ? Theme::palette().bad : Theme::palette().accent2).name()));

    auto* col = new QVBoxLayout; col->setSpacing(1);
    auto* t = new QLabel(title);
    t->setStyleSheet(QStringLiteral("font-size:14px;font-weight:600;color:%1;")
                         .arg((danger ? Theme::palette().bad : Theme::palette().ink).name()));
    col->addWidget(t);
    if (!value.isEmpty()) {
        auto* v = new QLabel(value);
        v->setObjectName("Sub");
        col->addWidget(v);
    }

    h->addWidget(ic);
    h->addLayout(col, 1);
    if (chevron) {
        auto* chev = new QLabel("›");
        chev->setStyleSheet(QStringLiteral("color:%1;font-size:20px;").arg(Theme::palette().inkSoft.name()));
        h->addWidget(chev);
    }
    return row;
}

SettingsPage::SettingsPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* kicker = new QLabel(tr("ACCOUNT"));  kicker->setObjectName("Kicker");
    auto* title  = new QLabel(tr("Settings")); title->setObjectName("H1");

    // ---- Profile tile --------------------------------------------------
    auto* profile = new QFrame; profile->setObjectName("Card");
    auto* ph = new QHBoxLayout(profile);
    ph->setContentsMargins(16, 14, 16, 14);
    ph->setSpacing(14);
    m_avatarHolder = new QWidget;
    auto* av = new QHBoxLayout(m_avatarHolder);
    av->setContentsMargins(0, 0, 0, 0);
    av->addWidget(Theme::makeAvatar(m_api->displayName().isEmpty() ? "U"
                                    : m_api->displayName(), 48, Theme::palette().accent2));
    auto* pcol = new QVBoxLayout; pcol->setSpacing(2);
    m_name = new QLabel(m_api->displayName());
    m_name->setStyleSheet("font-size:16px;font-weight:700;");
    m_email = new QLabel(tr("Signed in"));
    m_email->setObjectName("Sub");
    pcol->addWidget(m_name);
    pcol->addWidget(m_email);
    ph->addWidget(m_avatarHolder);
    ph->addLayout(pcol);
    ph->addStretch(1);

    // ---- Voice availability (our addition) -----------------------------
    AsrService asrProbe; TtsService ttsProbe;
    const QString voiceStatus =
        (asrProbe.isAvailable() && ttsProbe.isAvailable()) ? tr("Speech models installed (ASR + TTS)")
        : asrProbe.isAvailable()                            ? tr("ASR model installed")
        : ttsProbe.isAvailable()                            ? tr("TTS model installed")
        :                                                     tr("Not installed");

    // ---- Tiles ---------------------------------------------------------
    m_themeValue = nullptr; m_langValue = nullptr;
    auto* themeTile = tile("🎨", tr("Theme"), tr("Obsidian (dark)"), false);
    auto* langTile  = tile("🌐", tr("Language"), tr("English"), false);
    auto* fontTile  = tile("🔤", tr("Font"), tr("Editorial"), false);
    auto* modeTile  = tile("💬", tr("Default mode"), tr("Chat"), false);
    auto* bubbleTile= tile("🗨", tr("Bubble style"), tr("Classic"), false);
    auto* voiceTile = tile("🔊", tr("Speech / voice"), voiceStatus, false);
    auto* pwTile    = qobject_cast<ClickableFrame*>(tile("🔒", tr("Change password"), QString(), true));
    auto* outTile   = qobject_cast<ClickableFrame*>(tile("⏻", tr("Sign out"), QString(), true, /*danger=*/true));

    connect(pwTile,  &ClickableFrame::clicked, this, &SettingsPage::changePassword);
    connect(outTile, &ClickableFrame::clicked, this, &SettingsPage::signOutRequested);

    // ---- Assemble (scrollable) ----------------------------------------
    auto* page = new QWidget;
    auto* col = new QVBoxLayout(page);
    col->setContentsMargins(40, 28, 40, 28);
    col->setSpacing(8);
    col->addWidget(kicker);
    col->addWidget(title);
    col->addSpacing(6);
    col->addWidget(profile);
    col->addWidget(sectionHeader(tr("Appearance")));
    col->addWidget(themeTile);
    col->addWidget(langTile);
    col->addWidget(sectionHeader(tr("Font")));
    col->addWidget(fontTile);
    col->addWidget(sectionHeader(tr("Conversation")));
    col->addWidget(modeTile);
    col->addWidget(bubbleTile);
    col->addWidget(sectionHeader(tr("Voice")));
    col->addWidget(voiceTile);
    col->addWidget(sectionHeader(tr("Account")));
    col->addWidget(pwTile);
    col->addWidget(outTile);
    col->addStretch(1);

    auto* scroll = new QScrollArea;
    scroll->setWidgetResizable(true);
    scroll->setFrameShape(QFrame::NoFrame);
    scroll->setWidget(page);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(0, 0, 0, 0);
    root->addWidget(scroll);
}

void SettingsPage::setProfile(const UserProfile& p)
{
    m_name->setText(p.displayName.isEmpty() ? tr("You") : p.displayName);
    m_email->setText(p.email.isEmpty()
                         ? tr("%1 · %2 XP · %3🔥").arg(p.cefr()).arg(p.xpTotal).arg(p.streakDays)
                         : p.email);
    auto* av = qobject_cast<QHBoxLayout*>(m_avatarHolder->layout());
    QLayoutItem* old;
    while ((old = av->takeAt(0)) != nullptr) { delete old->widget(); delete old; }
    av->addWidget(Theme::makeAvatar(p.displayName.isEmpty() ? "U" : p.displayName,
                                    48, Theme::palette().accent2));
}

void SettingsPage::changePassword()
{
    QDialog dlg(this);
    dlg.setWindowTitle(tr("Change password"));
    auto* cur = new QLineEdit; cur->setEchoMode(QLineEdit::Password);
    auto* nw  = new QLineEdit; nw->setEchoMode(QLineEdit::Password);
    auto* form = new QFormLayout;
    form->addRow(tr("Current password"), cur);
    form->addRow(tr("New password"), nw);
    auto* ok = new QPushButton(tr("Update"));
    ok->setProperty("variant", QStringLiteral("primary"));
    auto* root = new QVBoxLayout(&dlg);
    root->setContentsMargins(24, 20, 24, 20);
    root->addLayout(form);
    root->addWidget(ok);
    connect(ok, &QPushButton::clicked, &dlg, &QDialog::accept);
    if (dlg.exec() != QDialog::Accepted) return;
    if (cur->text().isEmpty() || nw->text().isEmpty()) return;

    QJsonObject patch{{"currentPassword", cur->text()}, {"newPassword", nw->text()}};
    m_api->updateProfile(patch, [this](bool ok2, const QJsonValue&, const QString& err) {
        if (ok2) QMessageBox::information(this, tr("Password"), tr("Password updated."));
        else     QMessageBox::warning(this, tr("Password"), err.isEmpty() ? tr("Failed.") : err);
    });
}
