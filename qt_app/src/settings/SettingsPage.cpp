#include "settings/SettingsPage.h"
#include "api/ApiClient.h"
#include "asr/AsrService.h"
#include "asr/TtsService.h"
#include "ui/Theme.h"
#include "ui/ClickableFrame.h"
#include "model/Models.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QLabel>
#include <QFrame>
#include <QPushButton>
#include <QDialog>
#include <QLineEdit>
#include <QFormLayout>
#include <QInputDialog>
#include <QMessageBox>
#include <QVariant>
#include <QVector>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

QWidget* SettingsPage::sectionHeader(const QString& text)
{
    auto* l = new QLabel(text.toUpper());
    l->setObjectName("Kicker");
    l->setContentsMargins(4, 12, 0, 2);
    return l;
}

ClickableFrame* SettingsPage::tile(const QString& icon, const QString& title,
                                   const QString& value, QLabel** valueOut, bool danger)
{
    auto* row = new ClickableFrame;
    row->setObjectName("ScenarioCard");          // gives the periwinkle hover border
    row->setCursor(Qt::PointingHandCursor);
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
    auto* v = new QLabel(value);
    v->setObjectName("Sub");
    v->setVisible(!value.isEmpty());
    col->addWidget(v);
    if (valueOut) *valueOut = v;

    auto* chev = new QLabel("›");
    chev->setStyleSheet(QStringLiteral("color:%1;font-size:20px;").arg(Theme::palette().inkSoft.name()));

    h->addWidget(ic);
    h->addLayout(col, 1);
    h->addWidget(chev);
    return row;
}

SettingsPage::SettingsPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* kicker = new QLabel(tr("ACCOUNT"));  kicker->setObjectName("Kicker");
    auto* title  = new QLabel(tr("Settings")); title->setObjectName("H1");

    // ---- Profile -------------------------------------------------------
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

    // ---- Voice availability --------------------------------------------
    AsrService asrProbe; TtsService ttsProbe;
    const QString voiceStatus =
        (asrProbe.isAvailable() && ttsProbe.isAvailable()) ? tr("Speech models installed (ASR + TTS)")
        : asrProbe.isAvailable()                            ? tr("ASR model installed")
        : ttsProbe.isAvailable()                            ? tr("TTS model installed")
        :                                                     tr("Not installed");

    // ---- Tiles (interactive) -------------------------------------------
    auto* themeTile  = tile("🎨", tr("Theme"),         tr("Obsidian (dark)"), &m_themeValue);
    auto* langTile   = tile("🌐", tr("Language"),      tr("English"),         &m_langValue);
    auto* fontTile   = tile("🔤", tr("Font"),          tr("Editorial"),       &m_fontValue);
    auto* tutorTile  = tile("🧑‍🏫", tr("Active tutor"), tr("Default"),         &m_tutorValue);
    auto* modeTile   = tile("💬", tr("Default mode"),  tr("Chat"),            &m_modeValue);
    auto* bubbleTile = tile("🗨", tr("Bubble style"),  tr("Classic"),         &m_bubbleValue);
    auto* voiceTile  = tile("🔊", tr("Speech / voice"), voiceStatus, nullptr);
    auto* pwTile     = tile("🔒", tr("Change password"), QString(), nullptr);
    auto* outTile    = tile("⏻", tr("Sign out"),        QString(), nullptr, /*danger=*/true);

    // Wiring — each item now responds.
    connect(themeTile, &ClickableFrame::clicked, this, &SettingsPage::pickTheme);
    connect(langTile,  &ClickableFrame::clicked, this, &SettingsPage::pickLanguage);
    connect(tutorTile, &ClickableFrame::clicked, this, &SettingsPage::pickTutor);
    connect(fontTile, &ClickableFrame::clicked, this, [this]() {
        pickFromList(m_fontValue, tr("Font"),
                     {"Editorial", "Modern", "Friendly", "Classic"}, nullptr);
    });
    connect(modeTile, &ClickableFrame::clicked, this, [this]() {
        pickFromList(m_modeValue, tr("Default mode"), {"Chat", "Face"}, nullptr);
    });
    connect(bubbleTile, &ClickableFrame::clicked, this, [this]() {
        pickFromList(m_bubbleValue, tr("Bubble style"),
                     {"Classic", "Modern", "Tail", "Soft", "Notebook"}, nullptr);
    });
    connect(voiceTile, &ClickableFrame::clicked, this, [this]() {
        QMessageBox::information(this, tr("Speech / voice"),
            tr("Offline ASR + TTS via sherpa-onnx.\nModels live in ~/.local/share/vlearn/asr."));
    });
    connect(pwTile,  &ClickableFrame::clicked, this, &SettingsPage::changePassword);
    connect(outTile, &ClickableFrame::clicked, this, &SettingsPage::signOutRequested);

    // ---- Assemble ------------------------------------------------------
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
    col->addWidget(tutorTile);
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

void SettingsPage::patchProfile(const QJsonObject& patch)
{
    m_api->updateProfile(patch, [this](bool ok, const QJsonValue&, const QString& err) {
        if (!ok) QMessageBox::warning(this, tr("Settings"),
                     tr("Couldn't save: %1").arg(err.isEmpty() ? tr("unknown error") : err));
    });
}

void SettingsPage::pickFromList(QLabel* valueLabel, const QString& title,
                                const QStringList& options, std::function<void(int)> onChosen)
{
    bool ok = false;
    const int cur = qMax(0, options.indexOf(valueLabel ? valueLabel->text() : QString()));
    const QString picked = QInputDialog::getItem(this, title, title + ':', options, cur, false, &ok);
    if (!ok) return;
    if (valueLabel) valueLabel->setText(picked);
    if (onChosen) onChosen(options.indexOf(picked));
}

void SettingsPage::pickTheme()
{
    static const QStringList names{"Apricot", "Sage", "Iris", "Obsidian"};
    static const QStringList slugs{"apricot", "sage", "iris", "obsidian"};
    pickFromList(m_themeValue, tr("Theme"), names, [this](int i) {
        patchProfile({{"activeTheme", slugs.at(qBound(0, i, 3))}});
        QMessageBox::information(this, tr("Theme"),
            tr("Saved. Restart the app to apply the new theme."));
    });
}

void SettingsPage::pickLanguage()
{
    static const QStringList names{"English", "한국어", "中文"};
    static const QStringList codes{"en", "ko", "zh"};
    pickFromList(m_langValue, tr("Language"), names, [this](int i) {
        patchProfile({{"uiLanguage", codes.at(qBound(0, i, 2))}});
    });
}

void SettingsPage::pickTutor()
{
    m_api->listTeachers([this](bool ok, const QJsonValue& d, const QString& err) {
        if (!ok || !d.isArray() || d.toArray().isEmpty()) {
            QMessageBox::warning(this, tr("Active tutor"),
                tr("Couldn't load tutors: %1").arg(ok ? tr("none") : err));
            return;
        }
        QVector<Persona> ps; QStringList names;
        for (const QJsonValue& v : d.toArray()) {
            const Persona p = Persona::fromJson(v.toObject());
            ps.push_back(p); names << (p.name.isEmpty() ? p.id : p.name);
        }
        bool chose = false;
        const QString picked = QInputDialog::getItem(
            this, tr("Active tutor"), tr("Tutor:"), names, 0, false, &chose);
        if (!chose) return;
        const Persona& p = ps.at(qMax(0, names.indexOf(picked)));
        m_tutorValue->setText(p.name);
        patchProfile({{"activePersonaId", p.id}});
    });
}

void SettingsPage::setProfile(const UserProfile& p)
{
    m_name->setText(p.displayName.isEmpty() ? tr("You") : p.displayName);
    m_email->setText(p.email.isEmpty()
                         ? tr("%1 · %2 XP · %3🔥").arg(p.cefr()).arg(p.xpTotal).arg(p.streakDays)
                         : p.email);
    if (!p.activeTheme.isEmpty()) {
        QString t = p.activeTheme; t[0] = t[0].toUpper();
        m_themeValue->setText(p.activeTheme == "obsidian" ? tr("Obsidian (dark)") : t);
    }
    if (!p.uiLanguage.isEmpty())
        m_langValue->setText(p.uiLanguage == "ko" ? "한국어"
                             : p.uiLanguage == "zh" ? "中文" : "English");

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
