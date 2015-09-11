#include <cmath>

#include "QPointFUtil.h"

namespace QPointFUtil {

double distance(QPointF p1, QPointF p2)
{
    QPointF disp = p2 - p1;
    return sqrt(QPointF::dotProduct(disp, disp));
}

double distanceSq(QPointF p1, QPointF p2)
{
    QPointF disp = p2 - p1;
    return QPointF::dotProduct(disp, disp);
}

QPointF mean(QList<QPointF> points)
{
    double totalX = 0;
    double totalY = 0;
    foreach(QPointF point, points)
    {
        totalX += point.x();
        totalY += point.y();
    }
    if (points.size() == 0) return QPointF(0, 0);
    return QPointF(totalX/points.size(), totalY/points.size());
}

}
