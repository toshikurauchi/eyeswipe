#ifndef POINTERCONTROL_H
#define POINTERCONTROL_H

#include <QObject>
#include <QList>
#include <random>
#include <QVariant>

#include "SamplePoint.h"
#include "GazeRecalibration.h"

class PointerManager : public QObject
{
    Q_OBJECT
public:
    PointerManager(QObject *root, QObject *pointer, QObject *uncalibPointer, QObject *realPointer, bool filtering, GazeRecalibration &recalibration);
    ~PointerManager();

signals:
    void newUnfilteredSample(QPointF sample, double tstamp);
    void newSample(QPointF sample, double tstamp);
    void newFixation(QPointF fixation, double tstamp, double duration);
    void incompleteFixation(QPointF fixation, double tstamp, double duration);

public slots:
    void updatePointer(SamplePoint newPosition);
    void setIsMouse(bool isMouse);
    QList<QVariant> latestCompletedFixations(double interval);

private:
    QObject *root;
    QObject *pointer;
    QObject *uncalibPointer;
    QObject *realPointer;
    bool filtering;
    FixationPoint currentFixation;
    QList<SamplePoint> samples;
    QList<FixationPoint> latestFixations;
    GazeRecalibration &recalibration;

    QPointF mapToWindow(QVariant globalPosition);
    QPointF filteredSample();
    std::normal_distribution<double> dist;
    std::default_random_engine generator;
};

#endif // POINTERCONTROL_H
