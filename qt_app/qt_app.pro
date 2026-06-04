# vLearn2 — Qt Widgets chat client (Ubuntu / Qt 5.12)
#
# Open this file in Qt Creator (Desktop Qt 5.12.12 GCC 64bit kit), then
# Build (Ctrl+B) and Run (Ctrl+R) / Debug (F5).
#
# Command line:  qmake && make -j$(nproc) && ./vlearn_chat

QT       += core gui network widgets
CONFIG   += c++17
TEMPLATE  = app
TARGET    = vlearn_chat

# Treat the src/ dir as an include root so headers resolve cleanly.
INCLUDEPATH += src

SOURCES += \
    src/main.cpp \
    src/config/AppConfig.cpp \
    src/api/ApiClient.cpp \
    src/auth/LoginDialog.cpp \
    src/chat/ChatWindow.cpp

HEADERS += \
    src/model/Models.h \
    src/config/AppConfig.h \
    src/api/ApiClient.h \
    src/auth/LoginDialog.h \
    src/chat/ChatWindow.h

# Copy app_config.json next to the built binary so the app finds it when run
# from Qt Creator's shadow-build directory. Edit the copy in the build dir, or
# the source one and rebuild.
copyconfig.target   = $$OUT_PWD/app_config.json
copyconfig.depends  = $$PWD/app_config.json
copyconfig.commands = $(COPY_FILE) $$shell_path($$PWD/app_config.json) $$shell_path($$OUT_PWD/app_config.json)
QMAKE_EXTRA_TARGETS += copyconfig
PRE_TARGETDEPS      += $$OUT_PWD/app_config.json
