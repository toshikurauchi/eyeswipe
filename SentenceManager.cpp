#include <algorithm>
#include <ctime>
#include <cstdlib>
#include <QTextStream>

#include "SentenceManager.h"

SentenceManager::SentenceManager(QDir participantDir, bool isEnglish, bool training, QObject *parent) :
    QObject(parent),
    usedSentencesFile(participantDir.absoluteFilePath("usedSentences.txt")),
    isEnglish(isEnglish),
    training(training)
{
    loadSentences(true);
}

SentenceManager::~SentenceManager()
{
    if (usedSentencesFile.open(QIODevice::Append))
    {
        QTextStream out(&usedSentencesFile);
        foreach(QString sentence, usedSentences)
        {
            out << sentence << '\n';
        }
    }
}

QString SentenceManager::randomSentence()
{
    if (sentences.isEmpty()) loadSentences(false);
    QString sentence = sentences.first();
    sentences.removeFirst();
    usedSentences.push_back(sentence);
    return sentence;
}

void SentenceManager::loadSentences(bool ignoreUsedSentences)
{
    if (training)
    {
        sentences.append("I love chocolate.");
        sentences.append("Keep it clean.");
        sentences.append("That was an amazing restaurant.");
        sentences.append("We missed you.");
        sentences.append("Can i get an extension.");
        sentences.append("He gave an awesome talk.");
    }
    else
    {
        QString filename = ":/resources/sentencesEN.txt";
        if (!isEnglish) filename = ":/resources/sentencesPT.txt";
        QFile sentencesFile(filename);
        if (sentencesFile.open(QIODevice::ReadOnly))
        {
            QTextStream in(&sentencesFile);
            while (!in.atEnd())
            {
                QString line = in.readLine();
                QString sentence = line.trimmed();
                sentences.append(sentence);
            }
            sentencesFile.close();
        }

        if (ignoreUsedSentences && usedSentencesFile.exists() && usedSentencesFile.open(QIODevice::ReadOnly))
        {
            QTextStream in(&usedSentencesFile);
            while (!in.atEnd())
            {
                QString sentence = in.readLine().trimmed();
                sentences.removeAll(sentence);
            }
        }
        usedSentencesFile.close();
    }
    std::srand(unsigned(std::time(0)));
    std::random_shuffle(sentences.begin(), sentences.end());
}
