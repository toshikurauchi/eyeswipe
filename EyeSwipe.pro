TEMPLATE = app

QT += qml quick widgets sql

CONFIG += c++11

SOURCES += main.cpp \
    TobiiListener.cpp \
    MouseListener.cpp \
    KeyboardLayout.cpp \
    PointerManager.cpp \
    Trie.cpp \
    WordPredictor.cpp \
    ShapeDrawer.cpp \
    TextInputManager.cpp \
    Timer.cpp \
    QPointFUtil.cpp \
    ExperimentManager.cpp \
    SentenceManager.cpp \
    KeyboardManager.cpp \
    GazeRecalibration.cpp \
    SamplePoint.cpp

HEADERS += \
    TobiiListener.h \
    MouseListener.h \
    KeyboardLayout.h \
    PointerManager.h \
    Trie.h \
    WordPredictor.h \
    ShapeDrawer.h \
    SamplePoint.h \
    TextInputManager.h \
    Timer.h \
    QPointFUtil.h \
    ExperimentManager.h \
    SentenceManager.h \
    QListUtil.h \
    KeyboardManager.h \
    GazeRecalibration.h \
    Algorithm.h

RESOURCES += qml.qrc \
    res.qrc

INCLUDEPATH += $$PWD/include

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

win32 {
    # Copy DLLs
    DEST = $${OUT_PWD}

    !contains(QMAKE_TARGET.arch, x86_64) {
        ## Windows x86 (32bit)
        message("x86 build")
        SRC = $$PWD/lib/x86/Tobii.EyeX.Client.dll
        LIBS += -L$$PWD/lib/x86/ -lTobii.EyeX.Client
    } else {
        ## Windows x64 (64bit)
        message("x86_64 build")
        SRC = $$PWD/lib/x64/Tobii.EyeX.Client.dll
        LIBS += -L$$PWD/lib/x64/ -lTobii.EyeX.Client
    }

    SRC ~= s,/,\\,g
    DEST ~= s,/,\\,g

    copydata.commands = $(COPY_DIR) $$SRC $$DEST
    first.depends = $(first) copydata
    export(first.depends)
    export(copydata.commands)
    QMAKE_EXTRA_TARGETS += first copydata
}

# Copy ngrams.db
ngrams.path    = $${OUT_PWD}
ngrams.files   = $${PDW}/parameterSearch/ngrams.db

INSTALLS       += ngrams

OTHER_FILES += README.md
