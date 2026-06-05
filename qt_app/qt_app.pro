# vLearn2 — Qt Widgets chat client (Ubuntu / Qt 5.12), FreeTalk-themed.
#
# Open this file in Qt Creator (Desktop Qt 5.12.12 GCC 64bit kit), then
# Build (Ctrl+B) and Run (Ctrl+R) / Debug (F5).
#
# Command line:  qmake && make -j$(nproc) && ./vlearn_chat

QT       += core gui network widgets
CONFIG   += c++17
TEMPLATE  = app
TARGET    = vlearn_chat

INCLUDEPATH += src

SOURCES += \
    src/main.cpp \
    src/config/AppConfig.cpp \
    src/ui/Theme.cpp \
    src/asr/AsrService.cpp \
    src/asr/TtsService.cpp \
    src/api/ApiClient.cpp \
    src/auth/LoginDialog.cpp \
    src/home/HomePage.cpp \
    src/scenarios/ScenariosPage.cpp \
    src/scenarios/ScenarioBriefPage.cpp \
    src/progress/ProgressPage.cpp \
    src/settings/SettingsPage.cpp \
    src/chat/ChatPage.cpp \
    src/chat/HistoryPage.cpp \
    src/shell/MainShell.cpp

HEADERS += \
    src/model/Models.h \
    src/config/AppConfig.h \
    src/ui/Theme.h \
    src/ui/ClickableFrame.h \
    src/asr/AsrService.h \
    src/asr/TtsService.h \
    src/api/ApiClient.h \
    src/auth/LoginDialog.h \
    src/home/HomePage.h \
    src/scenarios/ScenariosPage.h \
    src/scenarios/ScenarioBriefPage.h \
    src/progress/ProgressPage.h \
    src/settings/SettingsPage.h \
    src/chat/ChatPage.h \
    src/chat/HistoryPage.h \
    src/shell/MainShell.h

RESOURCES += assets.qrc

# Copy app_config.json next to the built binary so the app finds it when run
# from Qt Creator's shadow-build directory.
copyconfig.target   = $$OUT_PWD/app_config.json
copyconfig.depends  = $$PWD/app_config.json
copyconfig.commands = $(COPY_FILE) $$shell_path($$PWD/app_config.json) $$shell_path($$OUT_PWD/app_config.json)
QMAKE_EXTRA_TARGETS += copyconfig
PRE_TARGETDEPS      += $$OUT_PWD/app_config.json
