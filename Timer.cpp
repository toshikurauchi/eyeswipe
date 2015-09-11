#include <QDateTime>

#include "Timer.h"

const qint64 t0 = QDateTime::currentMSecsSinceEpoch();

double Timer::timestamp()
{
    return (double) (QDateTime::currentMSecsSinceEpoch() - t0);
}
