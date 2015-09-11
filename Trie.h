#ifndef TRIE_H
#define TRIE_H

#include <map>
#include <set>
#include <string>
#include <QFile>
#include <QList>
#include <QSet>

#include "KeyboardLayout.h"

struct WordScore
{
    WordScore() :
        word(""),
        occurrences(0),
        score(0),
        occurrenceProb(-1),
        gestureProb(-1),
        initialized(false),
        probVal(-1) {}
    WordScore(std::string word, double probVal) :
        word(word),
        occurrences(0),
        score(0),
        occurrenceProb(-1),
        gestureProb(-1),
        initialized(true),
        probVal(probVal) {}
    WordScore(std::string word, double occurrences, double score) :
        word(word),
        occurrences(occurrences),
        score(score),
        occurrenceProb(-1),
        gestureProb(-1),
        initialized(false),
        probVal(-1)
    {}

    std::string word;
    double occurrences;
    double score;
    double occurrenceProb;
    double gestureProb;

    void initProbs(double totalOccurrences, double totalScores);
    double prob() const;

private:
    bool initialized;
    double probVal;
};

class ScoreComputation
{
public:
    ScoreComputation(bool subsample, KeyboardLayout &layout);
    virtual double updateScore(double prevDTW0, double prevDTW1, double *curDTW, QVector<QPointF> idealPath, QPointF sample, int nIdealPoints) = 0;
    virtual void initScoreAux(double *scoreAux, int nPoints) = 0;
    virtual double computeScore(double *scoreAux, int nPoints, int nIdealPoints);
    virtual double prevVal0(int idx) = 0;
    virtual double prevVal1(int idx) = 0;
    bool needsSubsampling();
private:
    bool subsample;
    KeyboardLayout &layout;
};

class Trie
{
public:
    Trie(KeyboardLayout &layout, ScoreComputation *scoreComputation);
    ~Trie();
    void load(QFile &wordList);
    void loadCsv(QFile &wordList, char delimiter = ',', int wordIdx = 0, int freqIdx = 1, bool occurrencesOnly = false);
    void addWord(const std::string &word, long occurrences = 1);
    void removeOccurrence(const std::string &word);
    bool contains(const std::string &word);
    long getOccurrencesFor(const std::string &word);
    QVector<WordScore> findWordsWithStartAndEnd(std::string start, std::string end, QList<QPointF> samplePoints);
    void clearScoreAux();
    int countNodes();

    int totalChars;
private:
    class Node
    {
    public:
        Node();
        Node(char value, int nIdealPoints);
        ~Node();
        char getValue();
        void setWord(bool word);
        bool isWord();
        long getOccurrences();
        Node *getChildAt(char pos);
        void addChild(Node *child);
        void addWordEnd(char end);
        void addOccurrences(long occurrences);
        bool hasChildWithEnd(char end);
        bool hasChildWithEnd(QSet<char> end);
        QList<char> getChildrenFirstLetter();
        double *scoreAux;
        QVector<QPointF> idealPath;
        QPointF firstPoint;
        int nIdealPoints;

    private:
        char value;
        bool word;
        long occurrences;
        std::map<char, Node*> children;
        std::set<char> wordEndings;

        friend class Trie;
    };

    Node *root;
    KeyboardLayout &layout;
    ScoreComputation *scoreComputation;

    QVector<WordScore> findWordsWithEnd(Node *current, QSet<char> end, std::string word, double prevVal0, double prevVal1, QPointF samplePoint, QPointF lastIdeal, int idx);
    Node *findNodeFor(const std::string &word, bool createIfNotFound = false, bool addWordEnd = false);
    int countNodesRec(Node *node);
    void clearScoreAux(Node *node);
    QList<QPointF> subsample(QList<QPointF> points, double step = 100);
};

#endif // TRIE_H
