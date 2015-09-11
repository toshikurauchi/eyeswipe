#include <QTextStream>
#include <QDebug>
#include <cmath>

#include "Trie.h"
#include "QPointFUtil.h"

using namespace QPointFUtil;

// ******************** WordScore ********************* //

void WordScore::initProbs(double totalOccurrences, double totalScores)
{
    if (occurrenceProb < 0) occurrenceProb = occurrences / totalOccurrences;
    if (gestureProb < 0) gestureProb = score / totalScores;
    if (probVal < 0) probVal = gestureProb * occurrenceProb;
    initialized = true;
}

double WordScore::prob() const
{
    if (initialized) return probVal;
    qDebug() << "Score used without initialization:" << QString::fromStdString(word) << score << occurrences;
    return 0;
}

// ******************** ScoreComputation ********************* //

const double EPSILON = 1;

ScoreComputation::ScoreComputation(bool subsample, KeyboardLayout &layout) :
    subsample(subsample), layout(layout)
{
}

double ScoreComputation::computeScore(double *scoreAux, int nPoints, int nIdealPoints)
{
    if (nPoints <= 0) return 0;
    return nIdealPoints / (1 + pow(scoreAux[nPoints - 1] / layout.keySize(), 6.6));
}

bool ScoreComputation::needsSubsampling()
{
    return subsample;
}

// Trie

Trie::Trie(KeyboardLayout &layout, ScoreComputation *scoreComputation) : root(new Node), layout(layout), scoreComputation(scoreComputation)
{
}

Trie::~Trie()
{
    if (root != nullptr) delete root;
}

void Trie::load(QFile &wordList)
{
    if (wordList.open(QIODevice::ReadOnly))
    {
        QTextStream in(&wordList);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            addWord(line.trimmed().toStdString());
            totalChars += line.trimmed().length();
        }
        wordList.close();
    }
}

void Trie::loadCsv(QFile &wordList, char delimiter, int wordIdx, int freqIdx, bool occurrencesOnly)
{
    if (wordList.open(QIODevice::ReadOnly))
    {
        QTextStream in(&wordList);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            QStringList row = line.split(delimiter);
            std::string word = row[wordIdx].trimmed().toStdString();
            if (!occurrencesOnly || contains(word))
            {
                addWord(word, row[freqIdx].trimmed().toLong());
            }
        }
        wordList.close();
    }
}

void Trie::addWord(const std::string &word, long occurrences)
{
    Node *node = findNodeFor(word, true, true);
    if (node)
    {
        node->addOccurrences(occurrences);
        node->setWord(true);
    }
}

void Trie::removeOccurrence(const std::string &word)
{
    Node *node = findNodeFor(word);
    if (node) node->addOccurrences(-1);
}

bool Trie::contains(const std::string &word)
{
    Node *node = findNodeFor(word);
    return node && node->isWord();
}

long Trie::getOccurrencesFor(const std::string &word)
{
    Node *node = findNodeFor(word);
    if (node) return node->getOccurrences();
    return 0;
}

QVector<WordScore> Trie::findWordsWithStartAndEnd(std::string start, std::string end, QList<QPointF> samplePoints)
{
    QSet<char> startChars;
    QSet<char> endChars;
    foreach(char startChar, start)
    {
        startChars.insert(tolower(startChar));
    }
    foreach(char endChar, end)
    {
        endChars.insert(tolower(endChar));
    }

    if (scoreComputation->needsSubsampling())
    {
        samplePoints = subsample(samplePoints);
    }

    QVector<WordScore> occurrences;
    foreach(char startChar, startChars)
    {
        Node *startNode = root->getChildAt(startChar);
        if (startNode == nullptr) continue;
        QPointF newStart = layout.idealPositionFor(startChar);
        if (startNode->idealPath.size() == 0 || distanceSq(startNode->idealPath.last(), newStart) > EPSILON)
        {
            startNode->idealPath.append(newStart);
            if (startNode->scoreAux != nullptr) delete[] startNode->scoreAux;
            startNode->scoreAux = new double[2];
            scoreComputation->initScoreAux(startNode->scoreAux, 1);
        }
        QVector<WordScore> newOccurrences;
        double score;
        double prevVal = startNode->scoreAux[0];
        for (int i = 1 + (int) startNode->scoreAux[1]; i < samplePoints.size(); i++)
        {
            if (i < 0)
            {
                qDebug() << "score_aux error occurred i =" << i;
                scoreComputation->initScoreAux(startNode->scoreAux, 1);
                i = 0;
            }
            startNode->scoreAux[1] = i;
            prevVal = startNode->scoreAux[0];
            QPointF samplePoint = samplePoints[i];
            score = scoreComputation->updateScore(scoreComputation->prevVal0(i), scoreComputation->prevVal1(i), startNode->scoreAux, startNode->idealPath, samplePoint, startNode->nIdealPoints);
            newOccurrences = findWordsWithEnd(startNode, endChars, std::string() + startChar, prevVal, startNode->scoreAux[0], samplePoint, startNode->idealPath.last(), i);
        }
        if (newOccurrences.size() == 0)
        {
            newOccurrences = findWordsWithEnd(startNode, endChars, std::string() + startChar, prevVal, startNode->scoreAux[0], samplePoints.last(), startNode->idealPath.last(), samplePoints.size());
            score = scoreComputation->computeScore(startNode->scoreAux, startNode->idealPath.size(), startNode->nIdealPoints);
        }
        occurrences.append(newOccurrences);
        if (endChars.contains(startChar) && startNode->isWord()) occurrences.append(WordScore(std::string() + startChar, startNode->getOccurrences(), score));
    }

    return occurrences;
}

void Trie::clearScoreAux()
{
    clearScoreAux(root);
}

int Trie::countNodes()
{
    return countNodesRec(root);
}

QVector<WordScore> Trie::findWordsWithEnd(Node *current, QSet<char> end, std::string word, double prevVal0, double prevVal1, QPointF samplePoint, QPointF lastIdeal, int idx)
{
    QVector<WordScore> occurrences;
    if (current == nullptr) return occurrences;
    QList<char> firstLetters = current->getChildrenFirstLetter();
    foreach (char firstLetter, firstLetters)
    {
        Node *child = current->getChildAt(firstLetter);
        if (child != nullptr)
        {
            double score;
            char value = child->getValue();
            QPointF newIdeal = layout.idealPositionFor(value);
            int nPoints = child->idealPath.size();
            if (nPoints == 0 || distanceSq(lastIdeal, child->firstPoint) > EPSILON || distanceSq(newIdeal, child->idealPath.last()) > EPSILON)
            {
                child->firstPoint = lastIdeal;
                QList<QPointF> ideal;
                ideal.append(lastIdeal);
                ideal.append(newIdeal);
                child->idealPath = subsample(ideal).mid(1).toVector();
                nPoints = child->idealPath.size();

                if (child->scoreAux != nullptr) delete[] child->scoreAux;
                child->scoreAux = new double[nPoints + 1];
                scoreComputation->initScoreAux(child->scoreAux, nPoints);
            }
            double prevVal = child->scoreAux[nPoints - 1];
            if ((int) child->scoreAux[nPoints] < idx)
            {
                child->scoreAux[nPoints] = idx;
                score = scoreComputation->updateScore(prevVal0, prevVal1, child->scoreAux, child->idealPath, samplePoint, child->nIdealPoints);
            }
            else score = scoreComputation->computeScore(child->scoreAux, nPoints, child->nIdealPoints);
            occurrences.append(findWordsWithEnd(child, end, word + value, prevVal, child->scoreAux[nPoints - 1], samplePoint, child->idealPath.last(), idx));
            if (end.contains(child->getValue()) && child->isWord()) occurrences.append(WordScore(word + child->getValue(), child->getOccurrences(), score / (word.length() + 1)));
        }
    }
    return occurrences;
}

Trie::Node* Trie::findNodeFor(const std::string &word, bool createIfNotFound, bool addWordEnd)
{
    Node *current = root;
    if (word.length() == 0) return nullptr;

    char wordEnd = tolower(*(word.end()-1));
    char prevC = '*';
    int nIdealPoints = 0;
    for (unsigned i = 0; i < word.length(); i++)
    {
        char c = tolower(word[i]);
        if (c != prevC) nIdealPoints++;
        prevC = c;
        Node *child = current->getChildAt(c);
        if (child == nullptr)
        {
            if (createIfNotFound)
            {
                child = new Node(c, nIdealPoints);
                current->addChild(child);
            }
            else
            {
                return nullptr;
            }
        }
        else if (!createIfNotFound && !child->hasChildWithEnd(wordEnd)) return nullptr;
        if (addWordEnd) child->addWordEnd(wordEnd);
        current = child;
    }
    return current;
}

int Trie::countNodesRec(Node *node)
{
    int count = 1;
    if (node == nullptr) return 0;
    for (auto it = node->children.begin(); it != node->children.end(); it++)
    {
        count += countNodesRec(it->second);
    }
    return count;
}

void Trie::clearScoreAux(Node *node)
{
    if (node == nullptr) return;
    scoreComputation->initScoreAux(node->scoreAux, node->idealPath.size());
    for (auto it = node->children.begin(); it != node->children.end(); it++)
    {
        clearScoreAux(it->second);
    }
}

QList<QPointF> Trie::subsample(QList<QPointF> points, double step)
{
    QList<QPointF> subsampled;
    if (points.size() <= 1)
    {
        subsampled.append(points.last());
        return subsampled;
    }
    for (int i = 0; i < points.size(); i++)
    {
        QPointF cur = points[i];
        subsampled.append(cur);
        if (i < points.size() - 1)
        {
            QPointF next = points[i+1];
            double dist = distance(cur, next);
            QPointF direction = next - cur;
            direction /= dist;
            for (double alpha = step; alpha < dist; alpha += step)
            {
                subsampled.append(cur + direction * alpha);
            }
        }
    }
    return subsampled;
}

// Trie::Node

Trie::Node::Node() : Node(' ', 0)
{}

Trie::Node::Node(char value, int nIdealPoints) : scoreAux(nullptr), nIdealPoints(nIdealPoints), value(value), word(false), occurrences(0)
{}

Trie::Node::~Node()
{
    for (auto it = children.cbegin(); it != children.cend();)
    {
        Node *node = it->second;
        children.erase(it++);
        delete node;
    }
    if (scoreAux != nullptr) delete[] scoreAux;
}

char Trie::Node::getValue()
{
    return value;
}

void Trie::Node::setWord(bool word)
{
    this->word = word;
}

bool Trie::Node::isWord()
{
    return word;
}

long Trie::Node::getOccurrences()
{
    return occurrences;
}

Trie::Node *Trie::Node::getChildAt(char pos)
{
    auto it = children.find(pos);
    if (it == children.end()) return nullptr;
    return it->second;
}

void Trie::Node::addChild(Trie::Node *child)
{
    children[child->getValue()] = child;
}

void Trie::Node::addWordEnd(char end)
{
    wordEndings.insert(end);
}

void Trie::Node::addOccurrences(long occurrences)
{
    this->occurrences += occurrences;
    if (this->occurrences < 1) this->occurrences = 1;
}

bool Trie::Node::hasChildWithEnd(char end)
{
    return wordEndings.find(end) != wordEndings.end();
}

bool Trie::Node::hasChildWithEnd(QSet<char> end)
{
    foreach(char e, end)
    {
        if (wordEndings.find(e) != wordEndings.end()) return true;
    }
    return false;
}

QList<char> Trie::Node::getChildrenFirstLetter()
{
    QList<char> firstLetters;
    for (auto it = children.begin(); it != children.end(); it++)
    {
        firstLetters.push_back(it->first);
    }
    return firstLetters;
}

