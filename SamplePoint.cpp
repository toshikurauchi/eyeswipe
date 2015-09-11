
#include "SamplePoint.h"
#include "QPointFUtil.h"

double FixationPoint::FIXATION_THRESHOLD = 10;

FixationPoint::FixationPoint(SamplePoint sample) : completed(false)
{
    samples.append(sample);
    update();
}

FixationPoint::FixationPoint(QPointF center, double startTstamp, double endTstamp) :
    center(center), startTstamp(startTstamp), endTstamp(endTstamp), completed(true)
{
}

QPointF FixationPoint::getCenter()
{
    return center;
}

double FixationPoint::getStartTstamp()
{
    return startTstamp;
}

double FixationPoint::getEndTstamp()
{
    return endTstamp;
}

double FixationPoint::duration()
{
    return endTstamp - startTstamp;
}

bool FixationPoint::isCompleted()
{
    return completed;
}

bool FixationPoint::addSample(SamplePoint sample)
{
    if (completed) return false;
    if (samples.size() == 0 || QPointFUtil::distance(center, sample.value) <= FIXATION_THRESHOLD)
    {
        samples.append(sample);
        update();
        return true;
    }
    SamplePoint first = samples.takeFirst();
    if (samples.size() == 0 || QPointFUtil::distance(meanPoint(), sample.value) <= FIXATION_THRESHOLD)
    {
        samples.append(sample);
        update();
        return true;
    }
    samples.prepend(first);
    update();
    completed = true;
    return false;
}

QPointF FixationPoint::meanPoint()
{
    double totalX = 0;
    double totalY = 0;
    foreach(SamplePoint sample, samples)
    {
        totalX += sample.value.x();
        totalY += sample.value.y();
    }
    if (samples.size() > 0) return QPointF(totalX/samples.size(), totalY/samples.size());
    return QPointF(0, 0);
}

void FixationPoint::update()
{
    double totalX = 0;
    double totalY = 0;
    startTstamp = -1;
    endTstamp = -1;
    foreach(SamplePoint sample, samples)
    {
        totalX += sample.value.x();
        totalY += sample.value.y();
        if (startTstamp == -1 || startTstamp > sample.tstamp) startTstamp = sample.tstamp;
        if (endTstamp == -1 || endTstamp < sample.tstamp) endTstamp = sample.tstamp;
    }
    if (samples.size() > 0) center = QPointF(totalX/samples.size(), totalY/samples.size());
}
