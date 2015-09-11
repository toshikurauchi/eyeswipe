#ifndef SHAPEDRAWER_H
#define SHAPEDRAWER_H

#include <QObject>
#include <QList>

#include "SamplePoint.h"
#include "WordPredictor.h"

#define SHAPE_TIME_LENGTH 100 // milliseconds
#define FIXATION_RAD_THRESH 10 // pixels

class ShapeDrawer : public QObject
{
    Q_OBJECT
public:
    ShapeDrawer(QObject *root, WordPredictor &predictor);

public slots:
    void updateShape(QPointF newPoint, double tstamp);

private:
    WordPredictor &predictor;
    QObject *shape;
    QList<SamplePoint> points;
    QList<SamplePoint> currentFixation;
};

#endif // SHAPEDRAWER_H
