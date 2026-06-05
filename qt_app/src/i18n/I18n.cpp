#include "i18n/I18n.h"

#include <QApplication>
#include <QTranslator>
#include <QHash>

namespace {

// English source → translation. Covers the visible UI; anything missing falls
// back to the English source.
const QHash<QString, QString>& koMap()
{
    static const QHash<QString, QString> m = {
        {"  Home", "  홈"}, {"  Scenarios", "  시나리오"},
        {"  Conversation history", "  대화 기록"}, {"  Progress", "  진행 상황"},
        {"  Settings", "  설정"}, {"Quick talk  →", "바로 대화  →"},
        {"Settings", "설정"}, {"Scenarios", "시나리오"}, {"Progress", "진행 상황"},
        {"Conversations", "대화 목록"}, {"Sign out", "로그아웃"},
        {"Type a message…", "메시지를 입력하세요…"}, {"AI Tutor · Online", "AI 튜터 · 온라인"},
        {"Tutor is typing…", "튜터가 입력 중…"}, {"Past conversation", "지난 대화"},
        {"Let's practice some English today.", "오늘도 영어를 연습해 봐요."},
        {"Good morning", "좋은 아침이에요"}, {"Good afternoon", "좋은 오후예요"},
        {"Good evening", "좋은 저녁이에요"}, {"Sessions", "세션"}, {"Minutes", "분"},
        {"Topics", "주제"}, {"Recommended scenarios", "추천 시나리오"},
        {"Theme", "테마"}, {"Language", "언어"}, {"Font", "글꼴"},
        {"Active tutor", "활성 튜터"}, {"Default mode", "기본 모드"},
        {"Bubble style", "말풍선 스타일"}, {"Speech / voice", "음성"},
        {"Change password", "비밀번호 변경"}, {"Appearance", "화면"},
        {"Conversation", "대화"}, {"Account", "계정"}, {"Voice", "음성"},
        {"Back to topics", "주제로 돌아가기"}, {"Start speaking", "말하기 시작"},
        {"Search scenarios…", "시나리오 검색…"}, {"Minutes spoken", "말한 시간(분)"},
        {"Scenarios done", "완료한 시나리오"}, {"Objectives", "목표"},
        {"Phrases worth stealing", "유용한 표현"}, {"YOUR JOURNEY", "나의 여정"},
        {"YOUR HISTORY", "기록"}, {"PRACTICE", "연습"}, {"ACCOUNT", "계정"},
        {"🔥  %1 day streak", "🔥  %1일 연속"},
        {"%1 XP to level %2", "레벨 %2까지 %1 XP"},
    };
    return m;
}

const QHash<QString, QString>& zhMap()
{
    static const QHash<QString, QString> m = {
        {"  Home", "  首页"}, {"  Scenarios", "  场景"},
        {"  Conversation history", "  对话记录"}, {"  Progress", "  进度"},
        {"  Settings", "  设置"}, {"Quick talk  →", "快速对话  →"},
        {"Settings", "设置"}, {"Scenarios", "场景"}, {"Progress", "进度"},
        {"Conversations", "对话记录"}, {"Sign out", "退出登录"},
        {"Type a message…", "输入消息…"}, {"AI Tutor · Online", "AI 导师 · 在线"},
        {"Tutor is typing…", "导师正在输入…"}, {"Past conversation", "历史对话"},
        {"Let's practice some English today.", "今天来练习英语吧。"},
        {"Good morning", "早上好"}, {"Good afternoon", "下午好"},
        {"Good evening", "晚上好"}, {"Sessions", "会话"}, {"Minutes", "分钟"},
        {"Topics", "主题"}, {"Recommended scenarios", "推荐场景"},
        {"Theme", "主题"}, {"Language", "语言"}, {"Font", "字体"},
        {"Active tutor", "当前导师"}, {"Default mode", "默认模式"},
        {"Bubble style", "气泡样式"}, {"Speech / voice", "语音"},
        {"Change password", "修改密码"}, {"Appearance", "外观"},
        {"Conversation", "对话"}, {"Account", "账户"}, {"Voice", "语音"},
        {"Back to topics", "返回主题"}, {"Start speaking", "开始对话"},
        {"Search scenarios…", "搜索场景…"}, {"Minutes spoken", "口语时长(分)"},
        {"Scenarios done", "完成的场景"}, {"Objectives", "目标"},
        {"Phrases worth stealing", "实用短语"}, {"YOUR JOURNEY", "你的旅程"},
        {"YOUR HISTORY", "历史"}, {"PRACTICE", "练习"}, {"ACCOUNT", "账户"},
        {"🔥  %1 day streak", "🔥  连续 %1 天"},
        {"%1 XP to level %2", "距离 %2 级还差 %1 XP"},
    };
    return m;
}

class AppTranslator : public QTranslator {
public:
    QString lang;
    QString translate(const char*, const char* sourceText,
                      const char*, int) const override {
        if (lang == QLatin1String("ko")) return koMap().value(QString::fromUtf8(sourceText));
        if (lang == QLatin1String("zh")) return zhMap().value(QString::fromUtf8(sourceText));
        return QString();   // en → use the source string
    }
};

AppTranslator g_tr;

}  // namespace

namespace I18n {

void install(QApplication& app) { app.installTranslator(&g_tr); }
void setLanguage(const QString& code) { g_tr.lang = (code == "en") ? QString() : code; }
QString currentLanguage() { return g_tr.lang.isEmpty() ? QStringLiteral("en") : g_tr.lang; }

}  // namespace I18n
