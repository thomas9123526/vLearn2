#include "asr/TtsService.h"

#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>

static QString firstFile(const QDir& dir, const QStringList& filters)
{
    const QStringList hits = dir.entryList(filters, QDir::Files, QDir::Name);
    return hits.isEmpty() ? QString() : dir.filePath(hits.first());
}

TtsService::TtsService(QObject* parent)
    : QObject(parent)
{
    resolvePaths();
}

void TtsService::resolvePaths()
{
    QString base = qEnvironmentVariable("VLEARN_ASR_DIR");
    if (base.isEmpty())
        base = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation))
                   .filePath("vlearn/asr");
    QDir root(base);

    // Engine binary + libs.
    for (const QString& d : root.entryList({"sherpa-onnx-*-linux-x64-shared"}, QDir::Dirs)) {
        const QString bin = root.filePath(d + "/bin/sherpa-onnx-offline-tts");
        if (QFileInfo::exists(bin)) { m_bin = bin; m_lib = root.filePath(d + "/lib"); break; }
    }

    // VITS voice model: <base>/tts/vits-*
    QDir tts(root.filePath("tts"));
    for (const QString& d : tts.entryList({"vits-*"}, QDir::Dirs)) {
        QDir md(tts.filePath(d));
        const QString onnx = firstFile(md, {"*.onnx"});       // not *.onnx.json
        const QString tok  = firstFile(md, {"tokens.txt"});
        if (onnx.isEmpty() || tok.isEmpty()) continue;
        m_model = onnx; m_tokens = tok;
        if (QFileInfo::exists(md.filePath("espeak-ng-data")))
            m_dataDir = md.filePath("espeak-ng-data");
        else if (QFileInfo::exists(md.filePath("lexicon.txt")))
            m_lexicon = md.filePath("lexicon.txt");
        break;
    }

    m_wav = QDir::temp().filePath("vlearn_tts.wav");
    const bool hasAplay = !QStandardPaths::findExecutable("aplay").isEmpty();
    m_available = hasAplay && !m_bin.isEmpty() && !m_model.isEmpty() && !m_tokens.isEmpty()
                  && (!m_dataDir.isEmpty() || !m_lexicon.isEmpty());
}

void TtsService::speak(const QString& text)
{
    if (!m_available || text.trimmed().isEmpty()) return;
    stop();

    m_synth = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    const QString cur = env.value("LD_LIBRARY_PATH");
    env.insert("LD_LIBRARY_PATH", cur.isEmpty() ? m_lib : (m_lib + ":" + cur));
    m_synth->setProcessEnvironment(env);

    connect(m_synth, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int code, QProcess::ExitStatus) {
        if (m_synth) { m_synth->deleteLater(); m_synth = nullptr; }
        if (code == 0 && QFileInfo::exists(m_wav)) play();
    });

    QStringList args{
        "--vits-model=" + m_model,
        "--vits-tokens=" + m_tokens,
        "--output-filename=" + m_wav,
    };
    if (!m_dataDir.isEmpty())  args << "--vits-data-dir=" + m_dataDir;
    else                       args << "--vits-lexicon=" + m_lexicon;
    args << text;
    m_synth->start(m_bin, args);
}

void TtsService::play()
{
    m_play = new QProcess(this);
    connect(m_play, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int, QProcess::ExitStatus) {
        if (m_play) { m_play->deleteLater(); m_play = nullptr; }
    });
    m_play->start("aplay", {"-q", m_wav});
}

void TtsService::stop()
{
    if (m_play)  { m_play->kill();  m_play->deleteLater();  m_play = nullptr; }
    if (m_synth) { m_synth->kill(); m_synth->deleteLater(); m_synth = nullptr; }
}
