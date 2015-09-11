#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QPixmap>
#include <QList>
#include <QMetaType>
#include <QDebug>

#include "KeyboardManager.h"
#include "SentenceManager.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setOrganizationName("University of São Paulo / Boston University");
    app.setOrganizationDomain("ime.usp.br / cs.bu.edu");
    app.setApplicationName("EyeSwipe");

    int retval;
    KeyboardSetup keyboardSetup;

    // KEYBOARD SETUP
    QQmlApplicationEngine engineKeyboardSetup;
    engineKeyboardSetup.load(QUrl(QStringLiteral("qrc:/eyeswipeqml/experimentPopup.qml")));

    QObject::connect(engineKeyboardSetup.rootObjects()[0], SIGNAL(closed(bool, bool)), &keyboardSetup, SLOT(init(bool, bool)));

    retval = app.exec();

    if (!keyboardSetup.isValid())
    {
        qDebug() << "No keyboard mode selected";
        return 0;
    }

    // EXPERIMENT SETUP
    ExperimentManager expManager;
    if (keyboardSetup.isExperiment())
    {
        QQmlApplicationEngine engineSetup;
        engineSetup.load(QUrl(QStringLiteral("qrc:/eyeswipeqml/setup.qml")));

        QObject::connect(engineSetup.rootObjects()[0], SIGNAL(closed(QString, int, QString, bool)), &expManager, SLOT(setup(QString, int, QString, bool)));

        retval = app.exec();

        if (!expManager.isValid())
        {
            qDebug() << "No valid participant data provided";
            return 0;
        }
    }

    // KEYBOARD

    SentenceManager sentenceManager(expManager.getParticipantDir(), keyboardSetup.isEnglish(), expManager.isTraining());

    QQmlApplicationEngine engineKeyboard;
    QQmlContext *context = engineKeyboard.rootContext();
    context->setContextProperty("expManager", &expManager);
    context->setContextProperty("keyboardSetup", &keyboardSetup);
    engineKeyboard.load(QUrl(QStringLiteral("qrc:/eyeswipeqml/main.qml")));

    qRegisterMetaType<SamplePoint>("SamplePoint");
    qRegisterMetaType<FixationPoint>("FixationPoint");

    QObject *root = engineKeyboard.rootObjects()[0];
    KeyboardManager keyboardManager(root, keyboardSetup.isEnglish());

    context->setContextProperty("predictor", &keyboardManager.getPredictor());
    context->setContextProperty("pointerManager", &keyboardManager.getPointerManager());
    QMetaObject::invokeMethod(root, "connectPointerManager");
    root->setProperty("isExperiment", keyboardSetup.isExperiment());
    root->setProperty("isEnglish", keyboardSetup.isEnglish());
    context->setContextProperty("sentenceManager", &sentenceManager);

    QObject::connect(root, SIGNAL(paused(bool)), &expManager, SLOT(logPaused(bool)));
    QObject::connect(root, SIGNAL(paused(bool)), &keyboardManager, SLOT(toggleConnections(bool)));
    if (!root->property("isPaused").toBool())
    {
        keyboardManager.toggleConnections(false);
    }

    if (keyboardSetup.isExperiment())
    {
        QObject::connect(&keyboardManager.getPointerManager(), SIGNAL(newSample(QPointF, double)), &expManager, SLOT(logSample(QPointF,double)));
        QObject::connect(&keyboardManager.getPointerManager(), SIGNAL(newUnfilteredSample(QPointF,double)), &expManager, SLOT(logUnfilteredSample(QPointF,double)));
        QObject::connect(&keyboardManager.getPointerManager(), SIGNAL(newFixation(QPointF,double,double)), &expManager, SLOT(logFixation(QPointF,double,double)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(startGesture(double)), &expManager, SLOT(logStartGesture(double)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(restartGesture(double)), &expManager, SLOT(logRestartGesture(double)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(finishGesture(double, QString)), &expManager, SLOT(logFinishGesture(double,QString)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(addPunct(QString)), &expManager, SLOT(logAddPunct(QString)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(keystroke(QString)), &expManager, SLOT(logKeystroke(QString)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(cancelGesture(double)), &expManager, SLOT(logGestureCanceled(double)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(typingChanged(bool)), &expManager, SLOT(logTypingChanged(bool)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(newFirstLetters(QString)), &expManager, SLOT(logNewFirstLetters(QString)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(newLastLetters(QString)), &expManager, SLOT(logNewLastLetters(QString)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(startedTyping(double)), &expManager, SLOT(logFSMStartedTyping(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(finishedTyping(double)), &expManager, SLOT(logFSMFinishedTyping(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(cancelTyping(double)), &expManager, SLOT(logFSMCancelTyping(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(showCandidates(double)), &expManager, SLOT(logFSMShowCandidates(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(hideCandidates(double)), &expManager, SLOT(logFSMHideCandidates(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(showDeleteOptions(double)), &expManager, SLOT(logFSMShowDeleteOptions(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(hideDeleteOptions(double)), &expManager, SLOT(logFSMHideDeleteOptions(double)));
        QObject::connect(keyboardManager.getStateMachine(), SIGNAL(deleteWord(double)), &expManager, SLOT(logFSMDeleteWord(double)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(newWord(QString)), &expManager, SLOT(logNewWord(QString)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(wordDeleted(QString)), &expManager, SLOT(logWordRemoved(QString)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(spaceAdded()), &expManager, SLOT(logSpaceAdded()));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(charAdded(QString)), &expManager, SLOT(logCharAdded(QString)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(candidateChanged(QString)), &expManager, SLOT(logCandidateChanged(QString)));
        QObject::connect(&keyboardManager.getPredictor(), SIGNAL(newWordCandidates(QStringList, int)), &expManager, SLOT(logCandidates(QStringList, int)));
    }

    // Hide cursor
    QPixmap nullCursor(16, 16);
    nullCursor.fill(Qt::transparent);
    app.setOverrideCursor(QCursor(nullCursor));

    retval = app.exec();

    return retval;
}
