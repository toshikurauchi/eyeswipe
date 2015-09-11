#include <QDebug>
#include <QFile>
#include <math.h>
#include <limits>
#include <cmath>

#include "WordPredictor.h"
#include "QPointFUtil.h"
#include "Timer.h"
#include "Algorithm.h"

using namespace QPointFUtil;

// ******************** Constants ********************* //

static const double INFTY = std::numeric_limits<double>::max();

// ******************** Comparator Functions ********************* //

bool compareScoresByScore(const WordScore &score1, const WordScore &score2)
{
    return score1.score < score2.score;
}

bool compareScoresByProb(const WordScore &score1, const WordScore &score2)
{
    return score1.prob() > score2.prob();
}

// ******************** DTWScoreComputation ********************* //

DTWScoreComputation::DTWScoreComputation(KeyboardLayout &layout) : ScoreComputation(false, layout)
{
}

double DTWScoreComputation::updateScore(double prevDTW0, double prevDTW1, double *curDTW, QVector<QPointF> idealPath, QPointF sample, int nIdealPoints)
{
    double cost = distanceSq(sample, idealPath.last());
    curDTW[0] = cost + std::min(std::min(curDTW[0], // insertion
                                         prevDTW1), // deletion
                                         prevDTW0); // match
    return 1 / (1 + curDTW[0]);
}

void DTWScoreComputation::initScoreAux(double *scoreAux, int nPoints)
{
    for (int i = 0; i < nPoints; i++) scoreAux[i] = INFTY;
    if (nPoints > 0) scoreAux[nPoints] = -1;
}

double DTWScoreComputation::prevVal0(int idx)
{
    if (idx == 0) return 0;
    return INFTY;
}

double DTWScoreComputation::prevVal1(int idx)
{
    return INFTY;
}

// ******************** FrechetScoreComputation ********************* //

FrechetScoreComputation::FrechetScoreComputation(KeyboardLayout &layout) : ScoreComputation(true, layout)
{
}

// Based in code from: https://gist.github.com/MaxBareiss/ba2f9441d9455b56fbc9
// From paper: http://www.kr.tuwien.ac.at/staff/eiter/et-archive/cdtr9464.pdf
double FrechetScoreComputation::updateScore(double prevCA0, double prevCA1, double *curCA, QVector<QPointF> idealPath, QPointF sample, int nIdealPoints)
{
    int nPoints = idealPath.size();
    for (int i = 0; i < nPoints; i++)
    {
        QPointF curIdeal = idealPath[i];
        double prevCA = curCA[i];
        curCA[i] = std::max(std::min(std::min(curCA[i], prevCA0), prevCA1), distance(sample, curIdeal));
        prevCA0 = prevCA;
        prevCA1 = curCA[i];
    }

    return computeScore(curCA, nPoints, nIdealPoints);
}

void FrechetScoreComputation::initScoreAux(double *scoreAux, int nPoints)
{
    for (int i = 0; i < nPoints; i++) scoreAux[i] = INFTY;
    if (nPoints > 0) scoreAux[nPoints] = -1;
}

double FrechetScoreComputation::prevVal0(int idx)
{
    if (idx == 0) return 0;
    return INFTY;
}

double FrechetScoreComputation::prevVal1(int idx)
{
    return INFTY;
}

// ******************** WordPredictor ********************* //

WordPredictor::WordPredictor(QObject *parent, KeyboardLayout &layout, QObject *typingManager, bool isEnglish, GazeRecalibration &recalibration) :
    layout(layout), scoreComputation(new FrechetScoreComputation(layout)), typing(false), trie(layout, scoreComputation), sentencesTrie(layout, scoreComputation), fixationThreshold(10),
    typingManager(typingManager), filteredShape(parent->findChild<QObject*>("filteredShape")), idealPath(parent->findChild<QObject*>("idealPath")),
    recalibration(recalibration), updating(0), lastUpdatedTstamp(-1)
{
    QString wordFilename = ":/resources/words_mck.txt";
    QString wordFreqFilename = ":/resources/words_mck_1grams.csv";
    //QString sentencesFilename = ":/resources/recorded_sentences.txt";
    int wordIdx = 1;
    int freqIdx = 0;
    if (!isEnglish)
    {
        wordFilename = ":/resources/palavras.txt";
        wordFreqFilename = ":/resources/palavras-freq.csv";
        //sentencesFilename = ":/resources/frases_gravadas.txt";
        wordIdx = 0;
        freqIdx = 1;
    }
    QFile wordList(wordFilename);
    QFile wordFreqList(wordFreqFilename);
    //QFile sentencesList(sentencesFilename);
    trie.load(wordList);
    trie.loadCsv(wordFreqList, '\t', wordIdx, freqIdx, true);
    //sentencesTrie.load(sentencesList);
    qDebug() << "(Trie)" << trie.countNodes() << ("nodes in the trie (" + std::to_string(trie.totalChars)).c_str() << "chars)";
    clearTrieScoreAux();

    punct.append(".");
    punct.append(",");
    punct.append("!");
    punct.append("?");
}

WordPredictor::~WordPredictor()
{
    delete scoreComputation;
}

bool WordPredictor::isTyping()
{
    return typing;
}

void WordPredictor::run()
{
    exec();
}

void WordPredictor::stop()
{
    this->quit();
}

void WordPredictor::onNewFixation(QPointF point, double tstamp, double duration)
{
    if (typing && layout.bellowCandidates(point))
    {
        updatingMutex.lock();
        updating++;
        updatingMutex.unlock();
        samples.append(FixationPoint(point, tstamp, tstamp + duration));
        updateCache(tstamp);
        updatingMutex.lock();
        updating--;
        updatingMutex.unlock();
    }
}

void WordPredictor::onNewIncompleteFixation(QPointF point, double tstamp, double duration)
{
    lastIncompleteFixation = FixationPoint(point, tstamp, tstamp + duration);
}

void WordPredictor::onGestureStarted(double timestamp)
{
    Q_UNUSED(timestamp)
    samples.clear();
    clearTrieScoreAux();
    typing = true;
}

void WordPredictor::onGestureRestarted(double timestamp)
{
    clearTrieScoreAux();
    typing = true;
    QMutableListIterator<FixationPoint> it(samples);
    while (it.hasNext()) {
        if (it.next().getStartTstamp() < timestamp) it.remove();
        else break;
    }
}

void WordPredictor::onGestureFinished(double timestamp, QString selectedWord)
{
    typing = false;
    int pidx = punctIdx(selectedWord);
    if (pidx >= 0)
    {
        emit newWordCandidates(punct, pidx);
    }
    else
    {
        // Debuging
        QVariantList pts;
        foreach (QPointF pt, latestInput.samples) pts.append(pt);
        filteredShape->setProperty("points", pts);
        qDebug() << "FIRST: " << firstLetterCandidates << "LAST: " << lastLetterHistory;
        foreach (WordScore wordScore, latestWordScores)
        {
            qDebug() << QString::fromStdString(wordScore.word) << wordScore.gestureProb << wordScore.occurrenceProb << wordScore.prob();
        }
        qDebug() << "";
        int idx = 0;

        selectedWord = selectedWord.toLower();
        for (int i = 0; i < latestReturnedCandidates.size(); i++) {
            QString candidate = latestReturnedCandidates[i];
            if (candidate.toLower().compare(selectedWord) == 0) {
                idx = i;
                break;
            }
        }
        if (latestReturnedCandidates.length() > 0)
        {
            emit newWordCandidates(latestReturnedCandidates, idx);
            if (latestReturnedCandidates.size())
            {
                QVector<QPointF> idealPath = layout.idealPathFor(selectedWord.toStdString());
                recalibration.addGesture(latestInput.samples.toVector(), idealPath);
            }
        }
    }
    samples.clear();
}

void WordPredictor::onKeystroke(QString letter)
{
    emit newLetter(letter[0].toLower());
}

void WordPredictor::onGestureCanceled(double timestamp)
{
    Q_UNUSED(timestamp);
    typing = false;
    samples.clear();
}

void WordPredictor::newFirstLetters(QString firstLetters)
{
    if (firstLetters == firstLetterCandidates) return;
    firstLetterCandidates = firstLetters;
    qDebug() << "FIRST LETTERS" << firstLetterCandidates;
}

void WordPredictor::newLastLetters(QString lastLetters)
{
    if (lastLetters == lastLetterCandidates) return;
    lastLetterCandidates = lastLetters;
    qDebug() << "LAST LETTERS" << lastLetterCandidates;
    if (lastUpdatedTstamp >= 0)
    {
        updatingMutex.lock();
        updating++;
        updatingMutex.unlock();
        updateCache(lastUpdatedTstamp);
        updatingMutex.lock();
        updating--;
        updatingMutex.unlock();
    }
}

void WordPredictor::addWordToLexicon(QString newWord)
{
    QString word = newWord;
    if (word.indexOf(' ') >= 0)
    {
        sentencesTrie.addWord(word.toStdString());
        foreach (QString w, word.split(' '))
        {
            trie.addWord(w.toStdString());
        }
    }
    else trie.addWord(word.toStdString());
    recalibration.newWord(layout.idealPathFor(newWord.toStdString()));
}

void WordPredictor::removeWordOccurrence(QString deletedWord)
{
    trie.removeOccurrence(deletedWord.toStdString());
    recalibration.removeLastGesture();
}

QStringList WordPredictor::getCandidates(double timestamp)
{
    if (typing && layout.bellowCandidates(lastIncompleteFixation.getCenter()))
    {
        updatingMutex.lock();
        updating++;
        updatingMutex.unlock();
        samples.append(lastIncompleteFixation);
        updateCache(timestamp);
        updatingMutex.lock();
        updating--;
        updatingMutex.unlock();
    }
    waitForUpdate();

    QStringList candidates;
    QVector<WordScore> allScores(wordScoresCache.size() + sentenceScoresCache.size());
    std::merge(wordScoresCache.begin(), wordScoresCache.end(), sentenceScoresCache.begin(), sentenceScoresCache.end(), allScores.begin(), compareScoresByProb);
    allScores = allScores.mid(0, 10);

    if (allScores.isEmpty() && !firstLetterCandidates.isEmpty() && !lastLetterCandidates.isEmpty())
    {
        foreach (QChar c, firstLetterCandidates)
        {
            if (lastLetterCandidates.contains(c))
            {
                std::string singleLetterWord = QString(c).toStdString();
                if (trie.contains(singleLetterWord)) allScores.push_back(WordScore(singleLetterWord, trie.getOccurrencesFor(singleLetterWord), 1));
            }
            if (!allScores.isEmpty()) qSort(allScores.begin(), allScores.end(), compareScoresByProb);
        }
    }
    if (!samples.empty())
    {
        double gestureDuration = timestamp - samples.first().getStartTstamp();
        foreach (WordScore wordScore, allScores)
        {
            QString word = QString::fromStdString(wordScore.word);
            // Sometimes the word sequence is also a recorded sentence
            if (!candidates.contains(word))
            {
                if (expectedDuration(word) <= gestureDuration) candidates.append(word);
                else qDebug() << "REMOVED" << word;
            }
        }
    }

    latestWordScores = QVector<WordScore>(allScores);
    latestReturnedCandidates = candidates;
    return candidates;
}

void WordPredictor::updateTyping(bool isTyping)
{
    typing = isTyping;
}

void WordPredictor::clearTrieScoreAux()
{
    trie.clearScoreAux();
    sentencesTrie.clearScoreAux();
    wordScoresCache.clear();
    sentenceScoresCache.clear();
}

const double WordPredictor::MIN_CHAR_DURATION = 100;

PredictionInput WordPredictor::prepareInput(double lastTstamp)
{
    QList<QPointF> fixations;
    double t0 = -1;
    double t1 = -1;
    int lastIdx = -1;
    QString lastLetters = lastLetterCandidates;
    bool searchingLastLetters = true;
    if (lastLetters.length() > 0) searchingLastLetters = false;

    if (samples.length())
    {
        t0 = samples.first().getStartTstamp();
        for (int i = samples.length() - 1; i >= 0; i--)
        {
            if (i < samples.size() && samples[i].getStartTstamp() <= lastTstamp)
            {
                lastIdx = i;
                t1 = samples[i].getStartTstamp();
                break;
            }
        }
    }
    for (int i = 0; i <= lastIdx; i++)
    {
        if (i < samples.size() && t0 >= 0 && samples[i].getStartTstamp() >= t0)
        {
            fixations.append(samples[i].getCenter());
        }
        if (searchingLastLetters && i < samples.size() && t1 - samples[i].getStartTstamp() < 300 && samples[i].duration() > 20)
        {
            QString newLastLetters = layout.charsClosestTo(samples[i].getCenter(), 3).toLower();
            foreach (QChar c, newLastLetters)
            {
                if (!lastLetters.contains(c)) lastLetters += c;
            }
        }
    }
    return PredictionInput(fixations, lastLetters);
}

void copyArray(double *from, double *to, int size)
{
    for (int i = 0; i < size; i++) to[i] = from[i];
}

char WordPredictor::getButtonValue(QObject *button)
{
    return button->objectName().at(0).toLower().toLatin1();
}

void WordPredictor::updateCache(double timestamp)
{
    // Remove samples that occurred after the final timestamp or that are too far from the others (saccade or noise)
    lastUpdatedTstamp = timestamp;
    PredictionInput input = prepareInput(timestamp);
    latestInput = input;
    // Sanity check
    if (input.samples.size() == 0) return;

    // Test all possible words against the given path
    QVector<WordScore> wordScores;
    if (input.samples.size() > 0)
    {
        lastLetterHistory = input.lastLetters;
        wordScores = trie.findWordsWithStartAndEnd(firstLetterCandidates.toStdString(), input.lastLetters.toStdString(), input.samples);
        wordScores = topN(wordScores, 10, compareScoresByScore);
    }
    QVector<WordScore> sentenceScores;
    sentenceScores = sentencesTrie.findWordsWithStartAndEnd(firstLetterCandidates.toStdString(), input.lastLetters.toStdString(), input.samples);
    sentenceScores = topN(sentenceScores, 10, compareScoresByScore);

    // Compute totals from top-10 candidates
    double totalScores = 0;
    long totalOccurrences = 0;
    foreach (WordScore wordScore, wordScores)
    {
        totalScores += wordScore.score;
        totalOccurrences += wordScore.occurrences;
    }
    foreach (WordScore wordScore, sentenceScores)
    {
        totalScores += wordScore.score;
        totalOccurrences += wordScore.occurrences;
    }

    // Transform occurrences and scores in probabilities
    for (auto it = wordScores.begin(); it != wordScores.end(); it++)
    {
        it->initProbs(totalOccurrences, totalScores);
    }
    for (auto it = sentenceScores.begin(); it != sentenceScores.end(); it++)
    {
        it->occurrenceProb = 1;
        it->initProbs(totalOccurrences, totalScores);
    }
    qSort(wordScores.begin(), wordScores.end(), compareScoresByProb);
    qSort(sentenceScores.begin(), sentenceScores.end(), compareScoresByProb);

    sentenceScoresCache = sentenceScores;
    wordScoresCache = wordScores;
}

void WordPredictor::waitForUpdate()
{
    while (updating > 0) msleep(1);
}

int WordPredictor::punctIdx(QString word)
{
    return punct.indexOf(word);
}

double WordPredictor::expectedDuration(QString word)
{
    if (word.length() == 0) return 0;
    int cleanSize = 1;
    QChar prevChar = word[0];
    for (int i = 1; i < word.length(); i++)
    {
        if (prevChar != word[i]) cleanSize++;
        prevChar = word[i];
    }
    return cleanSize * MIN_CHAR_DURATION;
}
