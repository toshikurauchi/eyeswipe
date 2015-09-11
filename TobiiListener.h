#ifndef TOBIILISTENER_H
#define TOBIILISTENER_H

#include <QObject>
#include <QList>

#include "SamplePoint.h"

class GazeEmitter : public QObject
{
    Q_OBJECT
public:
    GazeEmitter(QObject *parent) : QObject(parent) {}

signals:
    void newGaze(SamplePoint gaze);
};

class TobiiListener : public QObject
{
    Q_OBJECT
public:
    TobiiListener(QObject *root, bool controlling = true);
    ~TobiiListener();
    void setControlling(bool controlling);

signals:
    void newGaze(SamplePoint gaze);

public slots:
    void controlToggled(bool notControlling);

private slots:
    void onGaze(SamplePoint gaze);

private:
    bool controlling;
};

#endif // TOBIILISTENER_H
