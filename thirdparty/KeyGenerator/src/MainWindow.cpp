#include "MainWindow.h"
#include "ui_MainWindow.h"

#include <QDateTime>
#include <QDir>
#include <QFileDialog>
#include <QFileInfo>
#include <QMessageBox>
#include <QSettings>
#include <QStandardPaths>

#include "CertIssuer.h"
#include "LeafCa.h"
#include "LicenseLog.h"
#include "QrWriter.h"

namespace {

// QSettings keys. Stored under HKCU on Windows so each operator
// has their own remembered paths.
constexpr auto kKeyLeafCert  = "paths/leafCert";
constexpr auto kKeyLeafKey   = "paths/leafKey";
constexpr auto kKeyOutputDir = "paths/outputDir";
constexpr auto kKeyUserName  = "form/userName";
constexpr auto kKeyDays      = "form/days";

// Validates that `machineId` matches the 20-digit decimal format
// that AndroidDevID / WindowsDevID now emit (16 content digits +
// 4 checksum digits). A typo here would quietly issue a license
// that can never be claimed, so we keep the check strict.
bool isPlausibleMachineId(const QString& s) {
    if (s.size() != 20) return false;
    for (QChar c : s) {
        if (c < QLatin1Char('0') || c > QLatin1Char('9')) return false;
    }
    return true;
}

}  // namespace

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent), ui_(new Ui::MainWindow) {
    ui_->setupUi(this);

    connect(ui_->leafCertBrowse,  &QPushButton::clicked, this, &MainWindow::onBrowseLeafCert);
    connect(ui_->leafKeyBrowse,   &QPushButton::clicked, this, &MainWindow::onBrowseLeafKey);
    connect(ui_->outputDirBrowse, &QPushButton::clicked, this, &MainWindow::onBrowseOutputDir);
    connect(ui_->generateButton,  &QPushButton::clicked, this, &MainWindow::onGenerate);

    restoreFields();
}

MainWindow::~MainWindow() {
    persistFields();
}

void MainWindow::restoreFields() {
    QSettings s;
    ui_->leafCertEdit->setText(s.value(kKeyLeafCert).toString());
    ui_->leafKeyEdit->setText(s.value(kKeyLeafKey).toString());

    // Default output dir = <documents>/vLearn2/licenses on first run.
    const QString defaultOut =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
        QStringLiteral("/vLearn2/licenses");
    ui_->outputDirEdit->setText(s.value(kKeyOutputDir, defaultOut).toString());

    ui_->userNameEdit->setText(s.value(kKeyUserName).toString());
    ui_->daysSpinBox->setValue(s.value(kKeyDays, 100).toInt());
}

void MainWindow::persistFields() const {
    QSettings s;
    s.setValue(kKeyLeafCert,  ui_->leafCertEdit->text());
    s.setValue(kKeyLeafKey,   ui_->leafKeyEdit->text());
    s.setValue(kKeyOutputDir, ui_->outputDirEdit->text());
    s.setValue(kKeyUserName,  ui_->userNameEdit->text());
    s.setValue(kKeyDays,      ui_->daysSpinBox->value());
}

void MainWindow::appendStatus(const QString& line) {
    const QString stamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    ui_->statusTextEdit->appendPlainText(QStringLiteral("[%1] %2").arg(stamp, line));
}

void MainWindow::onBrowseLeafCert() {
    const QString path = QFileDialog::getOpenFileName(
        this, tr("Leaf CA certificate"),
        QFileInfo(ui_->leafCertEdit->text()).absolutePath(),
        tr("PEM certificates (*.cer *.crt *.pem);;All files (*.*)"));
    if (!path.isEmpty()) {
        ui_->leafCertEdit->setText(QDir::toNativeSeparators(path));
    }
}

void MainWindow::onBrowseLeafKey() {
    const QString path = QFileDialog::getOpenFileName(
        this, tr("Leaf CA private key"),
        QFileInfo(ui_->leafKeyEdit->text()).absolutePath(),
        tr("PEM keys (*.key *.pem);;All files (*.*)"));
    if (!path.isEmpty()) {
        ui_->leafKeyEdit->setText(QDir::toNativeSeparators(path));
    }
}

void MainWindow::onBrowseOutputDir() {
    const QString path = QFileDialog::getExistingDirectory(
        this, tr("Output directory"), ui_->outputDirEdit->text());
    if (!path.isEmpty()) {
        ui_->outputDirEdit->setText(QDir::toNativeSeparators(path));
    }
}

void MainWindow::onGenerate() {
    persistFields();

    const QString leafCertPath = ui_->leafCertEdit->text().trimmed();
    const QString leafKeyPath  = ui_->leafKeyEdit->text().trimmed();
    const QString machineId    = ui_->machineIdEdit->text().trimmed();
    const QString userName     = ui_->userNameEdit->text().trimmed();
    const int days             = ui_->daysSpinBox->value();
    const QString outputDir    = ui_->outputDirEdit->text().trimmed();

    if (leafCertPath.isEmpty() || leafKeyPath.isEmpty()) {
        QMessageBox::warning(this, tr("Missing input"),
                             tr("Pick a Leaf CA cert and key first."));
        return;
    }
    if (!isPlausibleMachineId(machineId)) {
        QMessageBox::warning(this, tr("Bad machine ID"),
                             tr("Machine ID must be 20 decimal digits "
                                "(16 content + 4 checksum, from "
                                "AndroidDevID / WindowsDevID)."));
        return;
    }
    if (userName.isEmpty()) {
        QMessageBox::warning(this, tr("Missing user"),
                             tr("Enter the user name to bind the license to."));
        return;
    }

    QDir().mkpath(outputDir);

    // ---- Load Leaf CA ---------------------------------------------------
    LeafCa ca;
    QString err;
    if (!ca.load(leafCertPath, leafKeyPath, &err)) {
        appendStatus(tr("ERROR loading Leaf CA: %1").arg(err));
        QMessageBox::critical(this, tr("Leaf CA"), err);
        return;
    }
    appendStatus(tr("Leaf CA loaded (subject=%1)").arg(ca.subjectCn()));

    // ---- Issue leaf cert ------------------------------------------------
    CertIssuer issuer;
    CertIssuer::Result result;
    if (!issuer.issue(ca, machineId, userName, days, &result, &err)) {
        appendStatus(tr("ERROR issuing leaf: %1").arg(err));
        QMessageBox::critical(this, tr("Issue"), err);
        return;
    }
    const QString mode = days >= 36500 ? QStringLiteral("permanent")
                                       : QStringLiteral("period");
    appendStatus(tr("Issued serial=%1 days=%2 mode=%3 size=%4 bytes")
                     .arg(result.serialHex)
                     .arg(days)
                     .arg(mode)
                     .arg(result.certDer.size()));
    if (result.certDer.size() > 1500) {
        appendStatus(tr("WARN cert size %1 bytes exceeds the 1500-byte QR budget")
                         .arg(result.certDer.size()));
    }

    // ---- Write .lic + .png ---------------------------------------------
    const QString licPath = QStringLiteral("%1/%2.lic").arg(outputDir, result.serialHex);
    const QString pngPath = QStringLiteral("%1/%2.png").arg(outputDir, result.serialHex);

    QFile lic(licPath);
    if (!lic.open(QIODevice::WriteOnly)) {
        appendStatus(tr("ERROR writing %1: %2").arg(licPath, lic.errorString()));
        return;
    }
    lic.write(result.certDer);
    lic.close();
    appendStatus(tr("Wrote %1").arg(licPath));

    // QR payload = base64 of the DER cert (so it survives transport
    // through paste buffers / text channels).
    if (!QrWriter::writePng(result.certDer.toBase64(), pngPath, &err)) {
        appendStatus(tr("ERROR writing QR PNG: %1").arg(err));
    } else {
        appendStatus(tr("Wrote %1").arg(pngPath));
    }

    // ---- Log -----------------------------------------------------------
    LicenseLog::Entry entry;
    entry.serialHex   = result.serialHex;
    entry.machineId   = machineId;
    entry.userName    = userName;
    entry.mode        = mode;
    entry.days        = days;
    entry.notBefore   = result.notBefore;
    entry.notAfter    = result.notAfter;
    entry.certDer     = result.certDer;
    entry.operatorTag = qEnvironmentVariable("USERNAME",
                                             qEnvironmentVariable("USER", "unknown"));

    LicenseLog log(outputDir);
    if (!log.append(entry, &err)) {
        appendStatus(tr("WARN local log append failed: %1").arg(err));
    } else {
        appendStatus(tr("Logged to %1").arg(log.csvPath()));
    }
}
