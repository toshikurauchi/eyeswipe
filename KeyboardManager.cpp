#include <QDebug>
#include <QThread>

#include "KeyboardManager.h"

// ************** KeyboardSetup ************** //

KeyboardSetup::KeyboardSetup() : valid(false)
{}

bool KeyboardSetup::isValid()
{
    return valid;
}

bool KeyboardSetup::isExperiment()
{
    return experiment;
}

bool KeyboardSetup::isEnglish()
{
    return english;
}

void KeyboardSetup::init(bool experiment, bool english)
{
    this->experiment = experiment;
    this->english = english;
    this->valid = true;
}

// ************** KeyboardManager ************** //

KeyboardManager::KeyboardManager(QObject *root, bool isEnglish) :
    QObject(root),
    root(root),
    pointer(root->findChild<QObject*>("pointer")),
    typingManager(root->findChild<QObject*>("typingManager")),
    stateMachine(root->findChild<QObject*>("stateMachine")),
    textField(root->findChild<QObject*>("textField")),
    mouseControlling(root->property("isMouseControlling").toBool()),
    pointerManager(root, pointer, root->findChild<QObject*>("uncalibPointer"), root->findChild<QObject*>("realPointer"), !mouseControlling, recalibration),
    layout(root),
    mouseListener(root, mouseControlling),
    tobiiListener(root, !mouseControlling),
    predictor(root, layout, typingManager, isEnglish, recalibration),
    drawer(root, predictor),
    input(root)
{
    predictor.start(QThread::HighestPriority);
    connect(typingManager, SIGNAL(typingChanged(bool)), &predictor, SLOT(updateTyping(bool)));

    connect(root, SIGNAL(pointerToggled(bool)), &mouseListener, SLOT(controlToggled(bool)));
    connect(root, SIGNAL(pointerToggled(bool)), &tobiiListener, SLOT(controlToggled(bool)));
    connect(root, SIGNAL(pointerToggled(bool)), &pointerManager, SLOT(setIsMouse(bool)));
    connect(&mouseListener, SIGNAL(newMouse(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
    connect(&tobiiListener, SIGNAL(newGaze(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
}

KeyboardManager::~KeyboardManager()
{
    predictor.stop();
}

WordPredictor& KeyboardManager::getPredictor()
{
    return predictor;
}

PointerManager& KeyboardManager::getPointerManager()
{
    return pointerManager;
}

QObject* KeyboardManager::getTypingManager()
{
    return typingManager;
}

QObject* KeyboardManager::getStateMachine()
{
    return stateMachine;
}

QObject* KeyboardManager::getTextField()
{
    return textField;
}

void KeyboardManager::toggleConnections(bool isPaused)
{
    if (isPaused)
    {
        //disconnect(root, SIGNAL(pointerToggled(bool)), &mouseListener, SLOT(controlToggled(bool)));
        //disconnect(root, SIGNAL(pointerToggled(bool)), &tobiiListener, SLOT(controlToggled(bool)));
        //disconnect(root, SIGNAL(pointerToggled(bool)), &pointerManager, SLOT(setIsMouse(bool)));
        //disconnect(&mouseListener, SIGNAL(newMouse(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        //disconnect(&tobiiListener, SIGNAL(newGaze(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        disconnect(&pointerManager, SIGNAL(newFixation(QPointF,double,double)), &predictor, SLOT(onNewFixation(QPointF,double,double)));
        disconnect(&pointerManager, SIGNAL(incompleteFixation(QPointF,double,double)), &predictor, SLOT(onNewIncompleteFixation(QPointF,double,double)));
        //disconnect(&pointerManager, SIGNAL(newSample(QPointF, double)), &predictor, SLOT(onNewSample(QPointF, double)));
        disconnect(&pointerManager, SIGNAL(newSample(QPointF, double)), &drawer, SLOT(updateShape(QPointF, double)));
        disconnect(typingManager, SIGNAL(startGesture(double)), &predictor, SLOT(onGestureStarted(double)));
        disconnect(typingManager, SIGNAL(restartGesture(double)), &predictor, SLOT(onGestureRestarted(double)));
        disconnect(typingManager, SIGNAL(finishGesture(double, QString)), &predictor, SLOT(onGestureFinished(double, QString)));
        disconnect(typingManager, SIGNAL(keystroke(QString)), &predictor, SLOT(onKeystroke(QString)));
        disconnect(typingManager, SIGNAL(cancelGesture(double)), &predictor, SLOT(onGestureCanceled(double)));
        disconnect(typingManager, SIGNAL(newFirstLetters(QString)), &predictor, SLOT(newFirstLetters(QString)));
        disconnect(typingManager, SIGNAL(newLastLetters(QString)), &predictor, SLOT(newLastLetters(QString)));
        disconnect(textField, SIGNAL(newWord(QString)), &predictor, SLOT(addWordToLexicon(QString)));
        disconnect(textField, SIGNAL(wordDeleted(QString)), &predictor, SLOT(removeWordOccurrence(QString)));
        disconnect(&predictor, SIGNAL(newLetter(QChar)), &input, SLOT(addSingleLetter(QChar)));
        disconnect(&predictor, SIGNAL(newWordCandidates(QStringList, int)), &input, SLOT(addWordCandidates(QStringList, int)));
    }
    else
    {
        //connect(root, SIGNAL(pointerToggled(bool)), &mouseListener, SLOT(controlToggled(bool)));
        //connect(root, SIGNAL(pointerToggled(bool)), &tobiiListener, SLOT(controlToggled(bool)));
        //connect(root, SIGNAL(pointerToggled(bool)), &pointerManager, SLOT(setIsMouse(bool)));
        //connect(&mouseListener, SIGNAL(newMouse(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        //connect(&tobiiListener, SIGNAL(newGaze(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        connect(&pointerManager, SIGNAL(newFixation(QPointF,double,double)), &predictor, SLOT(onNewFixation(QPointF,double,double)));
        connect(&pointerManager, SIGNAL(incompleteFixation(QPointF,double,double)), &predictor, SLOT(onNewIncompleteFixation(QPointF,double,double)));
        //connect(&pointerManager, SIGNAL(newSample(QPointF, double)), &predictor, SLOT(onNewSample(QPointF, double)));
        connect(&pointerManager, SIGNAL(newSample(QPointF, double)), &drawer, SLOT(updateShape(QPointF, double)));
        connect(typingManager, SIGNAL(startGesture(double)), &predictor, SLOT(onGestureStarted(double)));
        connect(typingManager, SIGNAL(restartGesture(double)), &predictor, SLOT(onGestureRestarted(double)));
        connect(typingManager, SIGNAL(finishGesture(double, QString)), &predictor, SLOT(onGestureFinished(double, QString)));
        connect(typingManager, SIGNAL(keystroke(QString)), &predictor, SLOT(onKeystroke(QString)));
        connect(typingManager, SIGNAL(cancelGesture(double)), &predictor, SLOT(onGestureCanceled(double)));
        connect(typingManager, SIGNAL(newFirstLetters(QString)), &predictor, SLOT(newFirstLetters(QString)));
        connect(typingManager, SIGNAL(newLastLetters(QString)), &predictor, SLOT(newLastLetters(QString)));
        connect(textField, SIGNAL(newWord(QString)), &predictor, SLOT(addWordToLexicon(QString)));
        connect(textField, SIGNAL(wordDeleted(QString)), &predictor, SLOT(removeWordOccurrence(QString)));
        connect(&predictor, SIGNAL(newLetter(QChar)), &input, SLOT(addSingleLetter(QChar)));
        connect(&predictor, SIGNAL(newWordCandidates(QStringList, int)), &input, SLOT(addWordCandidates(QStringList, int)));
    }
}
