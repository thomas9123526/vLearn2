#pragma once

#include <QFrame>
#include <QMouseEvent>

// A QFrame that emits clicked() — used for card-style tappable tiles.
class ClickableFrame : public QFrame {
    Q_OBJECT
public:
    explicit ClickableFrame(QWidget* parent = nullptr) : QFrame(parent) {
        // Required so QSS background/border paint on a QFrame *subclass*.
        setAttribute(Qt::WA_StyledBackground, true);
    }

signals:
    void clicked();

protected:
    void mousePressEvent(QMouseEvent* e) override {
        if (e->button() == Qt::LeftButton) emit clicked();
        QFrame::mousePressEvent(e);
    }
};
