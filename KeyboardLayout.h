#ifndef KEYBOARDLAYOUT_H
#define KEYBOARDLAYOUT_H

#include <QObject>
#include <QStringList>
#include <QVector>
#include <QPointF>
#include <QMap>
#include <string>

struct Button
{
    Button();
    Button(QObject *button);
    QObject *button;
    bool valid;
    double x, y, width, height;
    QString text;
    QStringList gridText;

    QPointF center();
    QPointF letterPos(char letter);
};

struct KeyboardButton : public Button
{
    KeyboardButton();
    KeyboardButton(QObject *button, char value);
    char value;
};

class KeyboardLayout : public QObject
{
    Q_OBJECT
public:
    KeyboardLayout(QObject *root);
    QVector<QPointF> idealPathFor(std::string word);
    QPointF idealPositionFor(char c);
    QString charsClosestTo(QPointF point, int n);
    double keySize();
    bool bellowCandidates(QPointF point);
    bool inKeysRegion(QPointF point);
    bool inSpaceRegion(QPointF point);

private slots:
    void setUpdateNeeded();

private:
    QObject *root;
    QObject *pEyeMenu;
    QMap<char, KeyboardButton> buttons;
    bool updateNeeded;
    double keySizeVal;

    void updateButtons();
};

#endif // KEYBOARDLAYOUT_H
