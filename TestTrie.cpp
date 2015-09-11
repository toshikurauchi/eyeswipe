#include <QtTest/QtTest>
#include <string>
#include <QFile>
#include <QSet>

#include "Trie.h"

class TestTrie : public QObject
{
    Q_OBJECT
private slots:
    void doesntThinkSubstringIsWord();
    void findsWordInTrie();
    void loadsFileCorrectly();
    void loadsCSVFileCorrectly();
    void loadsOnlyOccurencesWhenRequested();
    void computesFrequencyCorrectly();
    void ignoresCase();
    void listsNoWordWithStartAndEndIfThereIsntAny();
    void listsWordsWithStartAndEnd();
    void listsWordsWithStartAndEndAndSingleLetter();
    void listsWordsWithStartAndEndAndOccurences();
    void removesWordOccurences();
    void removingWordOccurencesDontBringItToLessThanOne();
    void addsWordOccurences();
    void caseInsensitive();
    void listWordsNotInDict();

private:
    Trie *createTrie();
};

void TestTrie::doesntThinkSubstringIsWord()
{
    Trie *trie = createTrie();
    QVERIFY(!trie->contains("test"));
    delete trie;
}

void TestTrie::findsWordInTrie()
{
    Trie *trie = createTrie();
    QVERIFY(trie->contains("tested"));
    delete trie;
}

void TestTrie::loadsFileCorrectly()
{
    QFile wordList(":/resources/words.txt");
    Trie trie(wordList);
    QVERIFY(trie.contains("information"));
    QVERIFY(!trie.contains("NOTAWORD"));
}

void TestTrie::loadsCSVFileCorrectly()
{
    QFile wordFrequencies(":/resources/word-freq-5000.csv");
    Trie trie(wordFrequencies, ',', 1, 3);
    QVERIFY(trie.contains("production"));
    QCOMPARE(trie.getOccurencesFor("production"), 42052l);
    QVERIFY(!trie.contains("NOTAWORD"));
}

void TestTrie::loadsOnlyOccurencesWhenRequested()
{
    QFile wordFrequencies(":/resources/wikipedia_wordfreq.csv");
    Trie trie;
    trie.addWord("word");
    trie.loadCsv(wordFrequencies, '\t', 0, 1, true);
    QVERIFY(!trie.contains("from"));
    QCOMPARE(trie.getOccurencesFor("word"), 161069l);
}

void::TestTrie::computesFrequencyCorrectly()
{
    Trie trie;
    trie.addWord("test");
    trie.addWord("test");
    trie.addWord("tested");
    trie.addWord("tested");
    trie.addWord("tested");
    QCOMPARE(trie.getOccurencesFor("test"), 2l);
    QCOMPARE(trie.getOccurencesFor("tested"), 3l);
}

void TestTrie::ignoresCase()
{
    Trie trie;
    trie.addWord("CAPITAL");
    QVERIFY(trie.contains("capital"));
}

void TestTrie::listsNoWordWithStartAndEndIfThereIsntAny()
{
    Trie trie;
    QCOMPARE(trie.findWordsWithStartAndEnd('a', 'a').getList().size(), 0);
}

void TestTrie::listsWordsWithStartAndEnd()
{
    Trie trie;
    // Should list
    trie.addWord("placed");
    trie.addWord("produced");
    trie.addWord("painted");
    trie.addWord("postponed");
    // Shouldn't list
    trie.addWord("product");
    trie.addWord("place");
    trie.addWord("some");
    trie.addWord("other");
    trie.addWord("words");

    QList<std::string> words = trie.findWordsWithStartAndEnd('p', 'd').getWords();
    QCOMPARE(words.size(), 4);
    QVERIFY(words.contains("placed"));
    QVERIFY(words.contains("produced"));
    QVERIFY(words.contains("painted"));
    QVERIFY(words.contains("postponed"));
    QVERIFY(!words.contains("product"));
    QVERIFY(!words.contains("place"));
    QVERIFY(!words.contains("some"));
    QVERIFY(!words.contains("other"));
    QVERIFY(!words.contains("words"));
}

void TestTrie::listsWordsWithStartAndEndAndSingleLetter()
{
    Trie trie;
    trie.addWord("i");
    trie.addWord("a");

    QVERIFY(trie.contains("i"));
    QVERIFY(trie.contains("a"));

    QList<std::string> words = trie.findWordsWithStartAndEnd('i', 'i').getWords();
    QCOMPARE(words.size(), 1);
    QVERIFY(words.contains("i"));
    words = trie.findWordsWithStartAndEnd('a', 'a').getWords();
    QCOMPARE(words.size(), 1);
    QVERIFY(words.contains("a"));
}

void TestTrie::listsWordsWithStartAndEndAndOccurences()
{
    Trie trie;
    // Should list
    trie.addWord("placed");
    trie.addWord("placed");
    trie.addWord("produced");
    trie.addWord("produced");
    trie.addWord("produced");
    trie.addWord("painted");
    trie.addWord("postponed");
    trie.addWord("postponed");
    trie.addWord("postponed");
    trie.addWord("postponed");
    // Shouldn't list
    trie.addWord("product");
    trie.addWord("product");
    trie.addWord("place");
    trie.addWord("post");
    trie.addWord("post");
    trie.addWord("some");
    trie.addWord("other");
    trie.addWord("words");

    WordOccurencesList wordOccurences = trie.findWordsWithStartAndEnd('p', 'd');
    QList<std::string> words = wordOccurences.getWords();
    QCOMPARE(words.size(), 4);
    QVERIFY(words.contains("placed"));
    QCOMPARE(wordOccurences.getOccurencesFor("placed"), 2l);
    QVERIFY(words.contains("produced"));
    QCOMPARE(wordOccurences.getOccurencesFor("produced"), 3l);
    QVERIFY(words.contains("painted"));
    QCOMPARE(wordOccurences.getOccurencesFor("painted"), 1l);
    QVERIFY(words.contains("postponed"));
    QCOMPARE(wordOccurences.getOccurencesFor("postponed"), 4l);
    QVERIFY(!words.contains("product"));
    QCOMPARE(wordOccurences.getOccurencesFor("product"), 0l);
    QVERIFY(!words.contains("place"));
    QCOMPARE(wordOccurences.getOccurencesFor("place"), 0l);
    QVERIFY(!words.contains("post"));
    QCOMPARE(wordOccurences.getOccurencesFor("post"), 0l);
    QVERIFY(!words.contains("some"));
    QCOMPARE(wordOccurences.getOccurencesFor("some"), 0l);
    QVERIFY(!words.contains("other"));
    QCOMPARE(wordOccurences.getOccurencesFor("other"), 0l);
    QVERIFY(!words.contains("words"));
    QCOMPARE(wordOccurences.getOccurencesFor("words"), 0l);
}

void TestTrie::removesWordOccurences()
{
    Trie trie;

    std::string popular = "popular";
    trie.addWord(popular, 1000);
    trie.removeOccurence(popular);
    QCOMPARE(trie.getOccurencesFor(popular), 999l);
}

void TestTrie::removingWordOccurencesDontBringItToLessThanOne()
{
    Trie trie;

    std::string unpopular = "unpopular";
    trie.addWord(unpopular, 3);
    trie.removeOccurence(unpopular);
    QCOMPARE(trie.getOccurencesFor(unpopular), 2l);
    trie.removeOccurence(unpopular);
    QCOMPARE(trie.getOccurencesFor(unpopular), 1l);
    trie.removeOccurence(unpopular);
    QCOMPARE(trie.getOccurencesFor(unpopular), 1l);
    trie.removeOccurence(unpopular);
    QCOMPARE(trie.getOccurencesFor(unpopular), 1l);
}

void TestTrie::addsWordOccurences()
{
    Trie trie;

    std::string popular = "popular";
    trie.addWord(popular, 10);
    trie.addWord(popular);
    QCOMPARE(trie.getOccurencesFor(popular), 11l);
    trie.addWord(popular);
    QCOMPARE(trie.getOccurencesFor(popular), 12l);
    trie.addWord(popular);
    QCOMPARE(trie.getOccurencesFor(popular), 13l);
}

void TestTrie::caseInsensitive()
{
    Trie trie;

    trie.addWord("case", 10);
    trie.addWord("INSENSITIVE");
    QVERIFY(trie.contains("CaSe"));
    QVERIFY(trie.contains("insensitive"));
    QCOMPARE(trie.findWordsWithStartAndEnd('C', 'E').getWords()[0], std::string("case"));
    QCOMPARE(trie.findWordsWithStartAndEnd('I', 'e').getWords()[0], std::string("insensitive"));
    QCOMPARE(trie.getOccurencesFor("CaSe"), 10l);
    QCOMPARE(trie.getOccurencesFor("insensitive"), 1l);
    trie.removeOccurence("CaSe");
    QCOMPARE(trie.getOccurencesFor("CaSe"), 9l);
}

void TestTrie::listWordsNotInDict()
{
    Trie trie;
    QFile wordList(":/resources/words.txt");
    QFile wordFreqList(":/resources/wikipedia_wordfreq.csv");
    trie.load(wordList);
    trie.loadCsv(wordFreqList, '\t', 0, 1, true);

    QSet<QString> unavailable;

    // load sentences
    QFile auxFile("sentences_temp.txt");
    QFile sentencesFile(":/resources/sentences.txt");
    QRegularExpression punct("[\\?!\\.,]");
    if (sentencesFile.open(QIODevice::ReadOnly) && auxFile.open(QIODevice::WriteOnly))
    {
        QTextStream in(&sentencesFile);
        QTextStream out(&auxFile);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            QStringList row = line.split('\t');
            QString sentence = row[1].trimmed().replace(punct, "");
            if (sentence.length() > 75 || sentence.contains('\'')) continue;
            out << row[0] << '\t' << sentence[0].toUpper()+sentence.right(sentence.length()-1) << (sentence[sentence.length() - 1] == '.' ? "\n" : ".\n");
            foreach(QString word, sentence.split(" "))
            {
                if (!trie.contains(word.toStdString()))
                {
                    unavailable.insert(word.toLower());
                }
            }
        }
        sentencesFile.close();
    }
    if (!unavailable.empty()) qDebug() << QStringList(unavailable.toList()).join("\n");
}

Trie *TestTrie::createTrie()
{
    Trie *trie = new Trie;
    trie->addWord("testing");
    trie->addWord("tested");
    trie->addWord("some");
    trie->addWord("other");
    trie->addWord("words");
    return trie;
}

QTEST_MAIN(TestTrie)
#include "TestTrie.moc"
