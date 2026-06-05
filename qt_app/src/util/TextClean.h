#pragma once

#include <QString>
#include <QRegularExpression>

// Clean a tutor/assistant reply for display + TTS. Reasoning/instruct models
// sometimes leak scaffolding into the answer — `<think>…</think>` blocks,
// "*Draft:*"/"*Final:*" labels, markdown emphasis, wrapping quotes. The backend
// returns res.content raw, so we defensively normalize it client-side.
inline QString sanitizeReply(QString s)
{
    if (s.isEmpty()) return s;
    const QString original = s;

    // 1) Remove <think>…</think> chain-of-thought (closed blocks), then keep
    //    whatever follows the last </think> if one remains.
    s.remove(QRegularExpression(QStringLiteral("<think>[\\s\\S]*?</think>"),
                                QRegularExpression::CaseInsensitiveOption));
    const int closeIdx = s.lastIndexOf(QStringLiteral("</think>"), -1, Qt::CaseInsensitive);
    if (closeIdx >= 0) s = s.mid(closeIdx + 8);

    // 2) If the model drafted then finalized, keep only the final answer.
    //    Requires a "final[ …]:" label (colon/dash) so normal prose with the
    //    word "final" is not truncated.
    QRegularExpression finalLabel(
        QStringLiteral("[*_`>\\s]*final(?:\\s+(?:answer|reply|response|version))?\\s*[:\\-]\\s*[*_`\"]*"),
        QRegularExpression::CaseInsensitiveOption);
    int lastPos = -1, lastLen = 0;
    auto it = finalLabel.globalMatch(s);
    while (it.hasNext()) { const auto m = it.next(); lastPos = m.capturedStart(); lastLen = m.capturedLength(); }
    if (lastPos >= 0) s = s.mid(lastPos + lastLen);

    // 3) Strip a single leading label (Draft:/Tutor:/Assistant:/Reply:).
    s.remove(QRegularExpression(
        QStringLiteral("^[*_`>\\s]*(?:draft|tutor|assistant|reply|response)\\s*[:\\-]\\s*[*_`\"]*"),
        QRegularExpression::CaseInsensitiveOption));

    // 4) Drop markdown emphasis / code markers.
    s.remove(QRegularExpression(QStringLiteral("[*_`]+")));

    // 5) Normalize whitespace.
    s.replace(QRegularExpression(QStringLiteral("[ \\t]+")), QStringLiteral(" "));
    s.replace(QRegularExpression(QStringLiteral("\\n{3,}")), QStringLiteral("\n\n"));
    s = s.trimmed();

    // 6) Unwrap one surrounding pair of quotes.
    if (s.size() >= 2) {
        const QChar a = s.front(), b = s.back();
        const bool dq = (a == '"'  || a == QChar(0x201C)) && (b == '"'  || b == QChar(0x201D));
        const bool sq = (a == '\'' || a == QChar(0x2018)) && (b == '\'' || b == QChar(0x2019));
        if (dq || sq) s = s.mid(1, s.size() - 2).trimmed();
    }

    // Never return empty from a non-empty input (e.g. reasoning-only output).
    return s.isEmpty() ? original.trimmed() : s;
}
