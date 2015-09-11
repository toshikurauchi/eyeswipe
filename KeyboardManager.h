#ifndef KEYBOARDMANAGER_H
#define KEYBOARDMANAGER_H

#include <QObject>

#include "PointerManager.h"
#include "MouseListener.h"
#include "TobiiListener.h"
#include "KeyboardLayout.h"
#include "WordPredictor.h"
#include "ShapeDrawer.h"
#include "TextInputManager.h"
#include "ExperimentManager.h"
#include "GazeRecalibration.h"

class KeyboardSetup : public QObject
{
    Q_OBJECT
public:
    explicit KeyboardSetup();
    bool isValid();
    bool isExperiment();
    bool isEnglish();

public slots:
    void init(bool experiment, bool english);

private:
    bool experiment;
    bool english;
    bool valid;
};

class KeyboardManager : public QObject
{
    Q_OBJECT
public:
    explicit KeyboardManager(QObject *root, bool isEnglish);
    ~KeyboardManager();

    WordPredictor& getPredictor();
    PointerManager& getPointerManager();
    QObject* getTypingManager();
    QObject* getStateMachine();
    QObject* getTextField();

public slots:
    void toggleConnections(bool isPaused);

private:
    QObject *root;
    QObject *pointer;
    QObject *typingManager;
    QObject *stateMachine;
    QObject *textField;
    bool mouseControlling;
    PointerManager pointerManager;
    KeyboardLayout layout;
    MouseListener mouseListener;
    TobiiListener tobiiListener;
    WordPredictor predictor;
    ShapeDrawer drawer;
    TextInputManager input;
    GazeRecalibration recalibration;
};

#endif // KEYBOARDMANAGER_H
