#ifndef WORDPREDICTOR_H
#define WORDPREDICTOR_H

#include <QObject>
#include <QThread>
#include <QMutex>
#include <QList>

#include "KeyboardLayout.h"
#include "SamplePoint.h"
#include "Trie.h"
#include "GazeRecalibration.h"

class ScoreComputationThread;

struct PredictionInput
{
    PredictionInput() : PredictionInput(QList<QPointF>(), "") {}
    PredictionInput(QList<QPointF> samples, QString lastLetters) :
        samples(samples), lastLetters(lastLetters) {}

    QList<QPointF> samples;
    QString lastLetters;
};

class DTWScoreComputation : public ScoreComputation
{
public:
    DTWScoreComputation(KeyboardLayout &layout);
    double updateScore(double prevDTW0, double prevDTW1, double *curDTW, QVector<QPointF> idealPath, QPointF sample, int nIdealPoints);
    void initScoreAux(double *scoreAux, int nPoints);
    double prevVal0(int idx);
    double prevVal1(int idx);
};

class FrechetScoreComputation : public ScoreComputation
{
public:
    FrechetScoreComputation(KeyboardLayout &layout);
    double updateScore(double prevCA0, double prevCA1, double *curCA, QVector<QPointF> idealPath, QPointF sample, int nIdealPoints);
    void initScoreAux(double *scoreAux, int nPoints);
    double prevVal0(int idx);
    double prevVal1(int idx);
};

class WordPredictor : public QThread
{
    Q_OBJECT
public:
    WordPredictor(QObject *parent, KeyboardLayout &layout, QObject *typingManager, bool isEnglish, GazeRecalibration &recalibration);
    ~WordPredictor();
    bool isTyping();
    void run();
    void stop();

signals:
    void newLetter(QChar letter);
    void newWordCandidates(QStringList candidates, int idx);

public slots:
    void onNewFixation(QPointF point, double tstamp, double duration);
    void onNewIncompleteFixation(QPointF point, double tstamp, double duration);
    void onGestureStarted(double timestamp);
    void onGestureRestarted(double timestamp);
    void onGestureFinished(double timestamp, QString selectedWord);
    void onKeystroke(QString letter);
    void onGestureCanceled(double timestamp);
    void newFirstLetters(QString firstLetters);
    void newLastLetters(QString lastLetters);
    void addWordToLexicon(QString newWord);
    void removeWordOccurrence(QString deletedWord);
    Q_INVOKABLE QStringList getCandidates(double timestamp);
    void updateTyping(bool isTyping);
    void clearTrieScoreAux();

private:
    const static double MIN_CHAR_DURATION;
    KeyboardLayout &layout;
    ScoreComputation *scoreComputation;
    bool typing;
    Trie trie;
    Trie sentencesTrie;
    QString firstLetterCandidates;
    QString lastLetterCandidates;
    QString lastLetterHistory;
    QList<FixationPoint> samples;
    SamplePoint latestSample;
    double fixationThreshold;
    QObject *typingManager;
    QObject *filteredShape;
    QObject *idealPath;
    QStringList exceptions;
    GazeRecalibration &recalibration;
    int updating;
    QVector<WordScore> wordScoresCache;
    QVector<WordScore> sentenceScoresCache;
    QStringList punct;
    QStringList latestReturnedCandidates;
    QVector<WordScore> latestWordScores;
    PredictionInput latestInput;
    QMutex updatingMutex;
    double lastUpdatedTstamp;
    FixationPoint lastIncompleteFixation;

    PredictionInput prepareInput(double timestamp);
    char getButtonValue(QObject *button);
    QStringList getStartEndLetters(QList<QPointF> &samplePoints);
    void updateCache(double timestamp);
    void waitForUpdate();
    int punctIdx(QString word);
    double expectedDuration(QString word);
};

#endif // WORDPREDICTOR_H
