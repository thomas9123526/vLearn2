#pragma once

#include <QObject>
#include <QString>

class QProcess;

// Offline TTS: synthesizes text with the bundled sherpa-onnx
// `sherpa-onnx-offline-tts` CLI (VITS/piper voice) and plays the WAV with
// `aplay`. Both run as QProcesses — no native linking.
//
// Auto-detected under ~/.local/share/vlearn/asr (override $VLEARN_ASR_DIR):
//   <dir>/sherpa-onnx-*-linux-x64-shared/bin/sherpa-onnx-offline-tts (+ lib/)
//   <dir>/tts/vits-*/{*.onnx, tokens.txt, espeak-ng-data/ | lexicon.txt}
class TtsService : public QObject {
    Q_OBJECT
public:
    explicit TtsService(QObject* parent = nullptr);

    bool isAvailable() const { return m_available; }

    void speak(const QString& text);   // stops any current speech first
    void stop();

private:
    void resolvePaths();
    void play();

    QString m_bin, m_lib, m_model, m_tokens, m_dataDir, m_lexicon, m_wav;
    QProcess* m_synth = nullptr;
    QProcess* m_play  = nullptr;
    bool m_available = false;
};
