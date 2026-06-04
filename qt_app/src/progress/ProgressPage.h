#pragma once

#include <QWidget>
#include "model/Models.h"

class ApiClient;
class QLabel;

// Progress dashboard: CEFR level hero + activity stats (GET /progress,
// /users/profile). Static, no animation.
class ProgressPage : public QWidget {
    Q_OBJECT
public:
    explicit ProgressPage(ApiClient* api, QWidget* parent = nullptr);
    void refresh();

private:
    ApiClient* m_api;
    QLabel*    m_cefrBig;
    QLabel*    m_cefrSub;
    QLabel*    m_sessions;
    QLabel*    m_minutes;
    QLabel*    m_topics;
};
