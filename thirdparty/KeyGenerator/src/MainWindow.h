#pragma once

#include <QMainWindow>
#include <QScopedPointer>

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

// Top-level window for the license-key generator. Owns the form
// fields, the issuing flow, and posts log entries to LicenseLog.
class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget* parent = nullptr);
    ~MainWindow() override;

private slots:
    void onBrowseLeafCert();
    void onBrowseLeafKey();
    void onBrowseOutputDir();
    void onGenerate();

private:
    void restoreFields();
    void persistFields() const;
    void appendStatus(const QString& line);

    QScopedPointer<Ui::MainWindow> ui_;
};
