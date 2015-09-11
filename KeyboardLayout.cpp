#include <QVariant>
#include <QList>
#include <QMetaObject>
#include <QDebug>
#include <QTransform>

#include "KeyboardLayout.h"
#include "QPointFUtil.h"

// Button

Button::Button() :
    button(nullptr),
    valid(false),
    x(-1),
    y(-1),
    width(-1),
    height(-1)
{}

Button::Button(QObject *button) :
    button(button),
    valid(button != nullptr),
    x(-1),
    y(-1),
    width(valid ? button->property("width").toDouble() : -1),
    height(valid ? button->property("height").toDouble() : -1),
    text(valid ? button->property("text").toString() : ""),
    gridText(valid ? button->property("gridText").toStringList() : QStringList())
{
    if (valid)
    {
        QVariant posVar;
        QMetaObject::invokeMethod(button, "winPos", Q_RETURN_ARG(QVariant, posVar));
        QPointF pos = posVar.toPointF();
        x = pos.x();
        y = pos.y();
    }
}

QPointF Button::center()
{
    return QPointF(x + width / 2, y + height / 2);
}

QPointF Button::letterPos(char letter)
{
    return center();
    QVariant pos;
    QMetaObject::invokeMethod(button, "textPosWin", Q_RETURN_ARG(QVariant, pos), Q_ARG(QVariant, QString(letter)));
    return pos.toPointF();
}

// KeyboardButton

KeyboardButton::KeyboardButton() : value(0)
{}

KeyboardButton::KeyboardButton(QObject *button, char value) :
    Button(button),
    value(value)
{}

// KeyboardLayout

KeyboardLayout::KeyboardLayout(QObject *root) :
    QObject(root), root(root), pEyeMenu(nullptr), updateNeeded(false)
{
    if (root != nullptr)
    {
        updateButtons();
        connect(root, SIGNAL(resized()), this, SLOT(setUpdateNeeded()));
    }
}

QVector<QPointF> KeyboardLayout::idealPathFor(std::string word)
{
    if (updateNeeded) updateButtons();
    QVector<QPointF> points(word.length());
    for (int i = 0; i < word.length(); i++)
    {
        char c = word[i];
        points[i] = buttons[tolower(c)].letterPos(tolower(c));
    }
    return points;
}

QPointF KeyboardLayout::idealPositionFor(char c)
{
    if (updateNeeded) updateButtons();
    return buttons[tolower(c)].letterPos(tolower(c));
}

QString KeyboardLayout::charsClosestTo(QPointF point, int n)
{
    if (updateNeeded) updateButtons();
    QMap<double, char> chars;
    double keySizeSq = buttons['a'].width;
    keySizeSq *= keySizeSq;
    QString closestChars = "";

    foreach (char key, buttons.keys())
    {
        double distSq = QPointFUtil::distanceSq(point, buttons[key].center());
        while (chars.contains(distSq)) distSq -= 0.1;
        chars.insert(distSq, key);
    }
    for (int i = 0; i < n; i++)
    {
        double distSq = chars.keys()[i];
        if (distSq <= keySizeSq) closestChars += chars[distSq];
        else break;
    }
    return closestChars;
}

double KeyboardLayout::keySize()
{
    if (updateNeeded) updateButtons();
    return keySizeVal;
}

bool KeyboardLayout::bellowCandidates(QPointF point)
{
    QVariant retval;
    QMetaObject::invokeMethod(root, "bellowCandidates", Q_RETURN_ARG(QVariant, retval), Q_ARG(QVariant, QVariant::fromValue(point)));
    return retval.toBool();
}

bool KeyboardLayout::inKeysRegion(QPointF point)
{
    QVariant retval;
    QMetaObject::invokeMethod(root, "inKeysRegion", Q_RETURN_ARG(QVariant, retval), Q_ARG(QVariant, QVariant::fromValue(point)));
    return retval.toBool();
}

bool KeyboardLayout::inSpaceRegion(QPointF point)
{
    QVariant retval;
    QMetaObject::invokeMethod(root, "inSpaceRegion", Q_RETURN_ARG(QVariant, retval), Q_ARG(QVariant, QVariant::fromValue(point)));
    return retval.toBool();
}

void KeyboardLayout::setUpdateNeeded()
{
    updateNeeded = true;
}

void KeyboardLayout::updateButtons()
{
    keySizeVal = root->property("keySize").toDouble();
    QVariantList objs = root->property("keyObjs").toList();
    foreach (QVariant button, objs)
    {
        QObject *btn=button.value<QObject*>();
        if (btn == nullptr) continue;
        foreach(QChar c, btn->objectName().left(btn->objectName().length()-3))
        {
            KeyboardButton newButton(btn, c.toLower().toLatin1());
            buttons[newButton.value] = newButton;
            qDebug() << newButton.value << buttons[newButton.value].center();
        }
    }
    QObject *spaceKey = root->findChild<QObject*>("spaceKey");
    if (spaceKey != nullptr)
    {
        KeyboardButton space(spaceKey, ' ');
        buttons[' '] = space;
        qDebug() << '_' << buttons[' '].center();
    }
    pEyeMenu = root->findChild<QObject*>("pEyeMenu");
    updateNeeded = false;
}
