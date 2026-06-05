#include "asr/AsrService.h"

#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

static QString firstMatch(const QDir& dir, const QStringList& nameFilters)
{
    const QStringList hits = dir.entryList(nameFilters, QDir::Files, QDir::Name);
    return hits.isEmpty() ? QString() : dir.filePath(hits.first());
}

AsrService::AsrService(QObject* parent)
    : QObject(parent)
{
    resolvePaths();
}

void AsrService::resolvePaths()
{
    QString base = qEnvironmentVariable("VLEARN_ASR_DIR");
    if (base.isEmpty())
        base = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation))
                   .filePath("vlearn/asr");   // ~/.local/share/vlearn/asr

    QDir root(base);

    // Engine: <base>/sherpa-onnx-*-linux-x64-shared/{bin,lib}
    for (const QString& d : root.entryList({"sherpa-onnx-*-linux-x64-shared"}, QDir::Dirs)) {
        const QString bin = root.filePath(d + "/bin/sherpa-onnx-offline");
        if (QFileInfo::exists(bin)) {
            m_bin = bin;
            m_lib = root.filePath(d + "/lib");
            break;
        }
    }

    // Model: <base>/models/sherpa-onnx-whisper-*
    QDir models(root.filePath("models"));
    for (const QString& d : models.entryList({"sherpa-onnx-whisper-*"}, QDir::Dirs)) {
        QDir md(models.filePath(d));
        QString enc = firstMatch(md, {"*-encoder.int8.onnx"});
        if (enc.isEmpty()) enc = firstMatch(md, {"*-encoder.onnx"});
        QString dec = firstMatch(md, {"*-decoder.int8.onnx"});
        if (dec.isEmpty()) dec = firstMatch(md, {"*-decoder.onnx"});
        const QString tok = firstMatch(md, {"*-tokens.txt"});
        if (!enc.isEmpty() && !dec.isEmpty() && !tok.isEmpty()) {
            m_encoder = enc; m_decoder = dec; m_tokens = tok;
            break;
        }
    }

    m_wav = QDir::temp().filePath("vlearn_asr.wav");

    const bool hasArecord =
        !QStandardPaths::findExecutable("arecord").isEmpty();
    m_available = hasArecord && !m_bin.isEmpty() &&
                  !m_encoder.isEmpty() && !m_decoder.isEmpty() && !m_tokens.isEmpty();
}

void AsrService::startRecording()
{
    if (!m_available || m_recording || m_busy) return;
    QFile::remove(m_wav);
    m_rec = new QProcess(this);
    // 16 kHz, mono, signed 16-bit — what the model expects.
    m_rec->start("arecord", {"-q", "-f", "S16_LE", "-r", "16000",
                             "-c", "1", "-t", "wav", m_wav});
    if (!m_rec->waitForStarted(2000)) {
        m_rec->deleteLater(); m_rec = nullptr;
        emit failed(tr("Could not start the microphone (arecord)."));
        return;
    }
    m_recording = true;
    emit stateChanged();
}

void AsrService::stopAndTranscribe()
{
    if (!m_recording || !m_rec) return;
    m_recording = false;
    m_rec->terminate();              // flush WAV header + data
    m_rec->waitForFinished(1500);
    if (m_rec->state() != QProcess::NotRunning) m_rec->kill();
    m_rec->deleteLater(); m_rec = nullptr;
    emit stateChanged();
    runTranscribe();
}

void AsrService::runTranscribe()
{
    if (!QFileInfo::exists(m_wav) || QFileInfo(m_wav).size() < 1024) {
        emit failed(tr("No audio captured."));
        return;
    }
    m_busy = true;
    emit stateChanged();

    m_asr = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    const QString cur = env.value("LD_LIBRARY_PATH");
    env.insert("LD_LIBRARY_PATH", cur.isEmpty() ? m_lib : (m_lib + ":" + cur));
    m_asr->setProcessEnvironment(env);

    connect(m_asr, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int, QProcess::ExitStatus) {
        const QByteArray out = m_asr->readAllStandardOutput();
        m_asr->deleteLater(); m_asr = nullptr;
        m_busy = false;
        emit stateChanged();

        // The recognizer prints a JSON object with a "text" field. Find the
        // last line that parses as an object carrying "text".
        QString text;
        const QList<QByteArray> lines = out.split('\n');
        for (const QByteArray& ln : lines) {
            const QByteArray t = ln.trimmed();
            if (!t.startsWith('{')) continue;
            const QJsonDocument doc = QJsonDocument::fromJson(t);
            if (doc.isObject() && doc.object().contains("text"))
                text = doc.object().value("text").toString();
        }
        text = text.trimmed();
        if (text.isEmpty()) emit failed(tr("Didn't catch that — try again."));
        else                emit transcribed(text);
    });

    m_asr->start(m_bin, {
        "--whisper-encoder=" + m_encoder,
        "--whisper-decoder=" + m_decoder,
        "--tokens=" + m_tokens,
        "--num-threads=2",
        m_wav,
    });
    if (!m_asr->waitForStarted(3000)) {
        m_asr->deleteLater(); m_asr = nullptr;
        m_busy = false;
        emit stateChanged();
        emit failed(tr("Could not start the ASR engine."));
    }
}

void AsrService::cancel()
{
    if (m_rec) { m_rec->kill(); m_rec->deleteLater(); m_rec = nullptr; }
    if (m_asr) { m_asr->kill(); m_asr->deleteLater(); m_asr = nullptr; }
    m_recording = false;
    m_busy = false;
    emit stateChanged();
}
