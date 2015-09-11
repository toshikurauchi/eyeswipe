#include <QDebug>

#include "QPointFUtil.h"
#include "GazeRecalibration.h"

// ************* IGazeMapper *********** //

int IGazeMapper::countPoints(QLinkedList<QVector<QPointF> > pointLists)
{
    int n = 0;
    foreach (QVector<QPointF> idealPoints, pointLists)
    {
        n += idealPoints.size();
    }
    return n;
}

// ************* PolyGazeMapper *********** //

bool PolyGazeMapper::findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists)
{
    int n = countPoints(idealPointLists);
    if (n < 10) return false;

    MatrixXd A(n, 6);
    MatrixXd b(n, 2);
    int i = 0;
    auto idealPts = idealPointLists.begin();
    auto gazePts = gazePointLists.begin();
    while (idealPts != idealPointLists.end() && gazePts != gazePointLists.end())
    {
        auto idealPt = idealPts->begin();
        auto gazePt = gazePts->begin();
        while (idealPt != idealPts->end() && gazePt != gazePts->end())
        {
            double x = idealPt->x();
            double y = idealPt->y();
            A(i, 0) = x*x;
            A(i, 1) = y*y;
            A(i, 2) = x*y;
            A(i, 3) = x;
            A(i, 4) = y;
            A(i, 5) = 1;

            b(i, 0) = gazePt->x();
            b(i, 1) = gazePt->y();
            i++;

            idealPt++;
            gazePt++;
        }
        idealPts++;
        gazePts++;
    }
    params = A.jacobiSvd(ComputeThinU | ComputeThinV).solve(b);
    return true;
}

QPointF PolyGazeMapper::remap(QPointF gaze)
{
    double x = gaze.x();
    double y = gaze.y();
    Matrix<double, 1, 6> gazeV;
    gazeV << x*x, y*y, x*y, x, y, 1;
    Matrix<double, 1, 2> remapped = gazeV * params;
    return QPointF(remapped(0, 0), remapped(0, 1));
}

// ************* HomogGazeMapper *********** //

bool HomogGazeMapper::findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists)
{
    int n = countPoints(idealPointLists);
    if (n < 8) return false;

    MatrixXd A(2 * n, 8);
    MatrixXd b(2 * n, 1);
    int i = 0;
    auto idealPts = idealPointLists.begin();
    auto gazePts = gazePointLists.begin();
    while (idealPts != idealPointLists.end() && gazePts != gazePointLists.end())
    {
        auto idealPt = idealPts->begin();
        auto gazePt = gazePts->begin();
        while (idealPt != idealPts->end() && gazePt != gazePts->end())
        {
            double xp = idealPt->x();
            double yp = idealPt->y();
            double x = gazePt->x();
            double y = gazePt->y();
            A(i, 0) = 0;
            A(i, 1) = 0;
            A(i, 2) = 0;
            A(i, 3) = -x;
            A(i, 4) = -y;
            A(i, 5) = -1;
            A(i, 6) = yp * x;
            A(i, 7) = yp * y;

            A(i+1, 0) = x;
            A(i+1, 1) = y;
            A(i+1, 2) = 1;
            A(i+1, 3) = 0;
            A(i+1, 4) = 0;
            A(i+1, 5) = 0;
            A(i+1, 6) = -xp * x;
            A(i+1, 7) = -xp * y;

            b(i, 0) = -yp;
            b(i+1, 0) = xp;
            i += 2;

            idealPt++;
            gazePt++;
        }
        idealPts++;
        gazePts++;
    }
    MatrixXd h = A.jacobiSvd(ComputeThinU | ComputeThinV).solve(b);
    homog << h(0, 0), h(1, 0), h(2, 0), h(3, 0), h(4, 0), h(5, 0), h(6, 0), h(7, 0), 1;
    return true;
}

QPointF HomogGazeMapper::remap(QPointF gaze)
{
    Vector3d gazeV;
    gazeV << gaze.x(), gaze.y(), 1;
    Vector3d remapped = homog * gazeV;
    QPointF newpt(remapped(0) / remapped(2), remapped(1) / remapped(2));
    return newpt;
}

// ************* TranslationGazeMapper *********** //

bool TranslationGazeMapper::findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists)
{
    int n = countPoints(idealPointLists);
    if (n < 5) return false;

    QList<double> xs;
    QList<double> ys;
    auto idealPts = idealPointLists.begin();
    auto gazePts = gazePointLists.begin();
    while (idealPts != idealPointLists.end() && gazePts != gazePointLists.end())
    {
        auto idealPt = idealPts->begin();
        auto gazePt = gazePts->begin();
        while (idealPt != idealPts->end() && gazePt != gazePts->end())
        {
            xs.append(idealPt->x() - gazePt->x());
            ys.append(idealPt->y() - gazePt->y());

            idealPt++;
            gazePt++;
        }
        idealPts++;
        gazePts++;
    }
    if (xs.size() > 0)
    {
        std::sort(xs.begin(), xs.end());
        std::sort(ys.begin(), ys.end());
        translation = QPointF(xs[xs.size() / 2], ys[ys.size() / 2]);
        return true;
    }
    return false;
}

QPointF TranslationGazeMapper::remap(QPointF gaze)
{
    return gaze + translation;
}

// ************* GazeRecalibration *********** //

const double GazeRecalibration::DISTANCE_THRESHOLD = 50;
const double GazeRecalibration::MAX_WORDS = 10;

GazeRecalibration::GazeRecalibration() :
    ready(false)
{
}

GazeRecalibration::~GazeRecalibration()
{
}

void GazeRecalibration::addGesture(QVector<QPointF> gaze, QVector<QPointF> ideal)
{
    QVector<QPointF> matchedIdeal;
    QVector<QPointF> matchedGaze;

    foreach(QPointF idealPoint, ideal)
    {
        QPointF bestMatch;
        double bestDistance;
        bool found = false;

        foreach(QPointF gazePoint, gaze)
        {
            double d = QPointFUtil::distance(idealPoint, gazePoint);
            if (d < GazeRecalibration::DISTANCE_THRESHOLD && (!found || d < bestDistance))
            {
                bestMatch = gazePoint;
                bestDistance = d;
                found = true;
            }
        }

        if (found)
        {
            matchedIdeal.append(idealPoint);
            matchedGaze.append(bestMatch);
        }
    }

    if (matchedIdeal.size() > 0)
    {
        idealPointLists.append(matchedIdeal);
        gazePointLists.append(matchedGaze);
        if (fullGazePointLists.size() == gazePointLists.size()) fullGazePointLists.removeLast();
        fullGazePointLists.append(gaze);
        ready = false;
    }
    while (idealPointLists.size() > GazeRecalibration::MAX_WORDS)
    {
        idealPointLists.removeFirst();
        gazePointLists.removeFirst();
        fullGazePointLists.removeFirst();
        ready = false;
    }
}

void GazeRecalibration::newWord(QVector<QPointF> ideal)
{
    while (fullGazePointLists.size() > gazePointLists.size() + 1) fullGazePointLists.removeLast();
    if (fullGazePointLists.size() == gazePointLists.size() + 1)
    {
        addGesture(fullGazePointLists.last(), ideal);
    }
}

void GazeRecalibration::removeLastGesture()
{
    while (fullGazePointLists.size() > gazePointLists.size()) fullGazePointLists.removeLast();
    if (gazePointLists.size()) gazePointLists.removeLast();
    if (idealPointLists.size()) idealPointLists.removeLast();
}

QPointF GazeRecalibration::remap(QPointF gaze)
{
    if (!ready)
    {
        // We don't want to use the last word because the user is
        // likely to replace it by another candidate
        if (gazePointLists.size() == 0 || idealPointLists.size() == 0) return gaze;
        auto lastGazePointList = gazePointLists.last();
        auto lastIdealPointList = idealPointLists.last();
        gazePointLists.removeLast();
        idealPointLists.removeLast();
        ready = mapper.findMapping(gazePointLists, idealPointLists);
        gazePointLists.append(lastGazePointList);
        idealPointLists.append(lastIdealPointList);
    }
    if (!ready) return gaze;

    return mapper.remap(gaze);
}
