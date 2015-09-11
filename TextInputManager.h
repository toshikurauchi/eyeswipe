#ifndef TEXTINPUTMANAGER_H
#define TEXTINPUTMANAGER_H

#include <QObject>
#include <QStringList>

class TextInputManager : public QObject
{
    Q_OBJECT
public:
    TextInputManager(QObject *root);

public slots:
    void addSingleLetter(QChar letter);
    void addWordCandidates(QStringList words, int idx);

private:
    QObject *textField;
};

#endif // TEXTINPUTMANAGER_H
