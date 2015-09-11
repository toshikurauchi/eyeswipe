#include <QMutableListIterator>
#include <QVariantList>
#include <QDebug>

#include "ShapeDrawer.h"
#include "QPointFUtil.h"
#include "QListUtil.h"

ShapeDrawer::ShapeDrawer(QObject *root, WordPredictor &predictor) :
    QObject(root), predictor(predictor), shape(root->findChild<QObject*>("shape"))
{
}

void ShapeDrawer::updateShape(QPointF newPoint, double tstamp)
{
    QVariantList positions;
    if (predictor.isTyping())
    {
        QMutableListIterator<SamplePoint> it(points);
        while (it.hasNext())
        {
            SamplePoint point = it.next();
            if (tstamp - point.tstamp > SHAPE_TIME_LENGTH)
                it.remove();
            {
                positions.push_back(point.value);
            }
        }
        if (!currentFixation.empty() && QPointFUtil::distance(QListUtil::avg(currentFixation).value, newPoint) >= FIXATION_RAD_THRESH)
        {
            SamplePoint fixPoint = QListUtil::avg(currentFixation);
            fixPoint.tstamp = currentFixation.last().tstamp;
            foreach (SamplePoint sample, currentFixation)
            {
                sample.value = fixPoint.value;
                positions.push_back(sample.value);
                points.push_back(sample);
            }
            currentFixation.clear();
        }
        currentFixation.push_back(SamplePoint(tstamp, newPoint));
        positions.push_back(QListUtil::avg(currentFixation).value);
        positions.push_back(newPoint);
    }
    else
    {
        points.clear();
        currentFixation.clear();
    }
    shape->setProperty("points", positions);
}
