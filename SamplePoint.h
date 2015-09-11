#ifndef SAMPLEPOINT_H
#define SAMPLEPOINT_H

#include <QPointF>
#include <QList>

struct SamplePoint
{
    SamplePoint() : tstamp(-1) {}
    SamplePoint(double tstamp, QPointF value) :
        tstamp(tstamp), value(value) {}
    double tstamp;
    QPointF value;

    SamplePoint& operator+=(const SamplePoint &rhs)
    {
        tstamp = std::min(tstamp, rhs.tstamp);
        value += rhs.value;
        return *this;
    }
    SamplePoint& operator-=(const SamplePoint &rhs)
    {
        tstamp = std::min(tstamp, rhs.tstamp);
        value -= rhs.value;
        return *this;
    }
    SamplePoint& operator/=(const qreal &rhs)
    {
        value /= rhs;
        return *this;
    }
};

inline SamplePoint operator+(SamplePoint lhs, SamplePoint rhs)
{
    return SamplePoint(std::min(lhs.tstamp, rhs.tstamp), lhs.value + rhs.value);
}
inline SamplePoint operator-(SamplePoint lhs, SamplePoint rhs)
{
    return SamplePoint(std::min(lhs.tstamp, rhs.tstamp), lhs.value - rhs.value);
}
inline SamplePoint operator/(SamplePoint lhs, qreal rhs)
{
    return SamplePoint(lhs.tstamp, lhs.value / rhs);
}

class FixationPoint
{
public:
    FixationPoint() : startTstamp(-1), endTstamp(-1), completed(false) {}
    FixationPoint(SamplePoint sample);
    FixationPoint(QPointF center, double startTstamp, double endTstamp);

    static double FIXATION_THRESHOLD;

    QPointF getCenter();
    double getStartTstamp();
    double getEndTstamp();
    double duration();
    bool isCompleted();
    bool addSample(SamplePoint sample);

private:
    QPointF center;
    QList<SamplePoint> samples;
    double startTstamp;
    double endTstamp;
    bool completed;

    QPointF meanPoint();
    void update();
};

#endif // SAMPLEPOINT_H
