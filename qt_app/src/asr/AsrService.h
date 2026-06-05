#pragma once

#include <QObject>
#include <QString>

class QProcess;

// Offline push-to-talk ASR: records the mic with `arecord` (16 kHz mono WAV),
// then transcribes with the bundled sherpa-onnx `sherpa-onnx-offline` CLI via
// QProcess. No native linking, no extra Qt modules.
//
// Engine + model are auto-detected under ~/.local/share/vlearn/asr
// (override with $VLEARN_ASR_DIR):
//   <dir>/sherpa-onnx-*-linux-x64-shared/bin/sherpa-onnx-offline   (+ lib/)
//   <dir>/models/sherpa-onnx-whisper-*/{*-encoder.int8.onnx, *-decoder.int8.onnx, *-tokens.txt}
class AsrService : public QObject {
    Q_OBJECT
public:
    explicit AsrService(QObject* parent = nullptr);

    bool isAvailable()  const { return m_available; }
    bool isRecording()  const { return m_recording; }
    bool isBusy()       const { return m_busy; }

    void startRecording();
    void stopAndTranscribe();
    void cancel();

signals:
    void transcribed(const QString& text);
    void failed(const QString& error);
    void stateChanged();   // recording/busy changed

private:
    void resolvePaths();
    void runTranscribe();

    QString m_bin, m_lib, m_encoder, m_decoder, m_tokens, m_wav;
    QProcess* m_rec = nullptr;   // arecord
    QProcess* m_asr = nullptr;   // sherpa-onnx-offline
    bool m_available = false;
    bool m_recording = false;
    bool m_busy = false;
};
