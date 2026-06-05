#include "scenarios/ScenariosPage.h"
#include "api/ApiClient.h"
#include "ui/Theme.h"
#include "ui/ClickableFrame.h"
#include "model/Models.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QLineEdit>
#include <QLabel>
#include <QFrame>
#include <QPushButton>
#include <QButtonGroup>
#include <QVariant>
#include <QSet>
#include <QJsonArray>
#include <QJsonObject>
#include <functional>

static const char* kCefr[] = {"A1", "A2", "B1", "B2", "C1", "C2"};

// A horizontal, scrollbar-less strip that holds chips.
static QScrollArea* chipStrip(QHBoxLayout*& rowOut)
{
    auto* sc = new QScrollArea;
    sc->setWidgetResizable(true);
    sc->setFixedHeight(46);
    sc->setFrameShape(QFrame::NoFrame);
    sc->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    sc->setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    auto* canvas = new QWidget;
    rowOut = new QHBoxLayout(canvas);
    rowOut->setContentsMargins(0, 4, 0, 4);
    rowOut->setSpacing(8);
    rowOut->addStretch(1);
    sc->setWidget(canvas);
    return sc;
}

ScenariosPage::ScenariosPage(ApiClient* api, QWidget* parent)
    : QWidget(parent)
    , m_api(api)
{
    auto* kicker = new QLabel(tr("PRACTICE")); kicker->setObjectName("Kicker");
    auto* title  = new QLabel(tr("Scenarios"));  title->setObjectName("H1");

    m_search = new QLineEdit;
    m_search->setPlaceholderText(tr("Search scenarios…"));
    m_search->setClearButtonEnabled(true);
    connect(m_search, &QLineEdit::textChanged, this, [this](const QString& t) {
        m_query = t.trimmed();
        applyFilter();
    });

    // Category chip strip (rebuilt when data loads).
    m_catGroup = new QButtonGroup(this);
    m_catGroup->setExclusive(true);
    auto* catStrip = chipStrip(m_catRow);

    // CEFR chip strip (built once).
    QHBoxLayout* cefrRow = nullptr;
    auto* cefrStrip = chipStrip(cefrRow);
    m_cefrGroup = new QButtonGroup(this);
    m_cefrGroup->setExclusive(true);
    {
        auto* all = makeChip(tr("All levels"), m_cefrGroup, true);
        cefrRow->insertWidget(cefrRow->count() - 1, all);
        connect(static_cast<QPushButton*>(all), &QPushButton::clicked, this, [this]() {
            m_cefr = 0; applyFilter();
        });
        for (int i = 0; i < 6; ++i) {
            auto* c = makeChip(kCefr[i], m_cefrGroup, false);
            cefrRow->insertWidget(cefrRow->count() - 1, c);
            const int level = i + 1;
            connect(static_cast<QPushButton*>(c), &QPushButton::clicked, this, [this, level]() {
                m_cefr = level; applyFilter();
            });
        }
    }

    m_empty = new QLabel(tr("No scenarios match your filters."));
    m_empty->setObjectName("Sub");
    m_empty->setAlignment(Qt::AlignCenter);
    m_empty->hide();

    auto* canvas = new QWidget;
    m_list = new QVBoxLayout(canvas);
    m_list->setContentsMargins(0, 0, 0, 0);
    m_list->setSpacing(12);
    m_list->addStretch(1);
    auto* scroll = new QScrollArea;
    scroll->setWidgetResizable(true);
    scroll->setFrameShape(QFrame::NoFrame);
    scroll->setWidget(canvas);

    auto* root = new QVBoxLayout(this);
    root->setContentsMargins(40, 28, 40, 20);
    root->setSpacing(8);
    root->addWidget(kicker);
    root->addWidget(title);
    root->addSpacing(4);
    root->addWidget(m_search);
    root->addWidget(catStrip);
    root->addWidget(cefrStrip);
    root->addSpacing(4);
    root->addWidget(m_empty);
    root->addWidget(scroll, 1);
}

QWidget* ScenariosPage::makeChip(const QString& label, QButtonGroup* group, bool checked)
{
    auto* b = new QPushButton(label);
    b->setProperty("variant", QStringLiteral("chip"));
    b->setCheckable(true);
    b->setChecked(checked);
    b->setCursor(Qt::PointingHandCursor);
    group->addButton(b);
    return b;
}

void ScenariosPage::rebuildCategoryChips()
{
    // Clear existing chips (keep trailing stretch).
    while (m_catRow->count() > 1) {
        QLayoutItem* it = m_catRow->takeAt(0);
        if (it->widget()) { m_catGroup->removeButton(qobject_cast<QAbstractButton*>(it->widget()));
                            it->widget()->deleteLater(); }
        delete it;
    }
    // Unique categories from the loaded scenarios, in first-seen order.
    QStringList cats; QSet<QString> seen;
    for (const Scenario& s : m_all)
        if (!s.category.isEmpty() && !seen.contains(s.category)) { seen.insert(s.category); cats << s.category; }

    auto* all = makeChip(tr("All"), m_catGroup, m_category.isEmpty());
    m_catRow->insertWidget(m_catRow->count() - 1, all);
    connect(static_cast<QPushButton*>(all), &QPushButton::clicked, this, [this]() {
        m_category.clear(); applyFilter();
    });
    for (const QString& cat : cats) {
        QString label = cat; if (!label.isEmpty()) label[0] = label[0].toUpper();
        auto* c = makeChip(label, m_catGroup, m_category == cat);
        m_catRow->insertWidget(m_catRow->count() - 1, c);
        connect(static_cast<QPushButton*>(c), &QPushButton::clicked, this, [this, cat]() {
            m_category = cat; applyFilter();
        });
    }
}

QWidget* makeScenarioTile(const Scenario& s, QObject* ctx,
                          std::function<void()> onClick);   // fwd (defined below)

void ScenariosPage::applyFilter()
{
    while (m_list->count() > 1) {
        QLayoutItem* it = m_list->takeAt(0);
        if (it->widget()) it->widget()->deleteLater();
        delete it;
    }
    int matched = 0;
    for (const Scenario& s : m_all) {
        if (!m_category.isEmpty() && s.category != m_category) continue;
        if (m_cefr != 0 && s.cefrLevel != m_cefr) continue;
        if (!m_query.isEmpty()) {
            const QString q = m_query.toLower();
            if (!s.title.toLower().contains(q) && !s.description.toLower().contains(q))
                continue;
        }
        const QString id = s.id, title = s.title;
        QWidget* tile = makeScenarioTile(s, this, [this, id, title]() {
            emit scenarioActivated(id, title);
        });
        m_list->insertWidget(m_list->count() - 1, tile);
        ++matched;
    }
    m_empty->setVisible(matched == 0 && !m_all.isEmpty());
}

void ScenariosPage::refresh()
{
    m_api->listScenarios([this](bool ok, const QJsonValue& d, const QString&) {
        m_all.clear();
        if (ok && d.isArray())
            for (const QJsonValue& v : d.toArray())
                m_all.push_back(Scenario::fromJson(v.toObject()));
        rebuildCategoryChips();
        applyFilter();
    });
}

// ---- Tile factory (shared shape: 48px level badge + texts + chevron) -------
QWidget* makeScenarioTile(const Scenario& s, QObject* ctx, std::function<void()> onClick)
{
    const Theme::Palette& p = Theme::palette();
    auto* card = new ClickableFrame;
    card->setObjectName("ScenarioCard");
    card->setCursor(Qt::PointingHandCursor);
    auto* h = new QHBoxLayout(card);
    h->setContentsMargins(16, 14, 16, 14);
    h->setSpacing(14);

    // Level badge
    const QString lvl = (s.cefrLevel >= 1 && s.cefrLevel <= 6) ? kCefr[s.cefrLevel - 1] : "—";
    auto* badge = new QLabel(lvl);
    badge->setFixedSize(48, 48);
    badge->setAlignment(Qt::AlignCenter);
    badge->setStyleSheet(QStringLiteral(
        "background:%1;color:%2;border-radius:12px;font-family:'%3';font-weight:700;")
        .arg(p.surfaceDeep.name(), p.accentInk.name(), Theme::fontMono()));
    h->addWidget(badge);

    // Texts
    auto* col = new QVBoxLayout; col->setSpacing(3);
    auto* chip = new QLabel(s.category.isEmpty() ? QObject::tr("chat") : s.category);
    chip->setObjectName("CatChip");
    chip->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Fixed);
    auto* title = new QLabel(s.title.isEmpty() ? QObject::tr("Conversation") : s.title);
    title->setObjectName("ScenarioTitle");
    auto* desc = new QLabel(s.description);
    desc->setObjectName("Sub");
    desc->setWordWrap(true);
    auto* meta = new QLabel(QStringLiteral("⏱ %1 min     ⭐ %2 XP")
                                .arg(s.estimatedMinutes).arg(s.xpReward));
    meta->setObjectName("ScenarioMeta");
    col->addWidget(chip);
    col->addWidget(title);
    col->addWidget(desc);
    col->addWidget(meta);
    h->addLayout(col, 1);

    // Chevron
    auto* chev = new QLabel("›");
    chev->setStyleSheet(QStringLiteral("color:%1;font-size:22px;").arg(p.inkSoft.name()));
    h->addWidget(chev);

    QObject::connect(card, &ClickableFrame::clicked, ctx, [onClick]() { onClick(); });
    return card;
}
