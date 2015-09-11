#include <QMetaObject>
#include <QVariant>

#include "TextInputManager.h"

TextInputManager::TextInputManager(QObject *root) :
    QObject(root), textField(root->findChild<QObject*>("textField"))
{
}

void TextInputManager::addSingleLetter(QChar letter)
{
    QMetaObject::invokeMethod(textField, "addSingleLetter", Q_ARG(QVariant, QVariant(letter)));
}

void TextInputManager::addWordCandidates(QStringList words, int idx)
{
    QMetaObject::invokeMethod(textField, "addWordCandidates", Q_ARG(QVariant, QVariant(words)), Q_ARG(QVariant, QVariant(idx)));
}
