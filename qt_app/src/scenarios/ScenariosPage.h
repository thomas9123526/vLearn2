#pragma once

#include <QWidget>
#include <QVector>
#include "model/Models.h"

class ApiClient;
class QVBoxLayout;
class QHBoxLayout;
class QLineEdit;
class QLabel;
class QButtonGroup;

// Browse scenarios (GET /scenarios) with a search box + category and CEFR
// filter chips (client-side filtering, like the Flutter scenarios screen).
// Clicking a tile emits scenarioActivated(id, title).
class ScenariosPage : public QWidget {
    Q_OBJECT
public:
    explicit ScenariosPage(ApiClient* api, QWidget* parent = nullptr);
    void refresh();

signals:
    void scenarioActivated(const QString& scenarioId, const QString& title);

private:
    void rebuildCategoryChips();
    void applyFilter();
    QWidget* makeChip(const QString& label, QButtonGroup* group, bool checked);

    ApiClient*    m_api;
    QLineEdit*    m_search;
    QHBoxLayout*  m_catRow;
    QButtonGroup* m_catGroup;
    QButtonGroup* m_cefrGroup;
    QVBoxLayout*  m_list;
    QLabel*       m_empty;

    QVector<Scenario> m_all;
    QString m_category;     // empty = all
    int     m_cefr = 0;     // 0 = all levels
    QString m_query;
};
