#ifndef QPOINTFUTIL_H
#define QPOINTFUTIL_H

#include <QPointF>
#include <QList>

namespace QPointFUtil {

double distance(QPointF p1, QPointF p2);
double distanceSq(QPointF p1, QPointF p2);
QPointF mean(QList<QPointF> points);

}

#endif // QPOINTFUTIL_H
