#ifndef GAZERECALIBRATION_H
#define GAZERECALIBRATION_H

#include <Eigen/Dense>
#include <QList>
#include <QLinkedList>
#include <QPointF>

using namespace Eigen;

class IGazeMapper
{
public:
    virtual bool findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists) = 0;
    virtual QPointF remap(QPointF gaze) = 0;
protected:
    int countPoints(QLinkedList<QVector<QPointF> > pointLists);
};

class PolyGazeMapper : public IGazeMapper
{
public:
    bool findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists);
    QPointF remap(QPointF gaze);
private:
    Matrix<double, 6, 2> params;
};

class HomogGazeMapper : public IGazeMapper
{
public:
    bool findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists);
    QPointF remap(QPointF gaze);
private:
    Matrix3d homog;
};

class TranslationGazeMapper : public IGazeMapper
{
public:
    bool findMapping(QLinkedList<QVector<QPointF> > &gazePointLists, QLinkedList<QVector<QPointF> > &idealPointLists);
    QPointF remap(QPointF gaze);
private:
    QPointF translation;
};

class GazeRecalibration
{
public:
    GazeRecalibration();
    ~GazeRecalibration();
    void addGesture(QVector<QPointF> gaze, QVector<QPointF> ideal);
    void newWord(QVector<QPointF> ideal);
    void removeLastGesture();
    QPointF remap(QPointF gaze);
private:
    static const double DISTANCE_THRESHOLD;
    static const double MAX_WORDS;
    TranslationGazeMapper mapper;

    bool ready;
    QLinkedList<QVector<QPointF> > idealPointLists;
    QLinkedList<QVector<QPointF> > gazePointLists;
    QLinkedList<QVector<QPointF> > fullGazePointLists;
};

#endif // GAZERECALIBRATION_H
