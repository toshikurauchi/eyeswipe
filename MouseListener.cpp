#include <QDebug>
#include <QCursor>

#include "MouseListener.h"
#include "Timer.h"

MouseListener::MouseListener(QObject *root, bool controlling) :
    QObject(root), controlling(controlling), timer(0)
{
    timer.setInterval(15);
    connect(&timer, SIGNAL(timeout()), this, SLOT(queryMouse()));
    if (controlling) timer.start();
}

MouseListener::~MouseListener()
{
}

void MouseListener::setControlling(bool controlling)
{
    this->controlling = controlling;
}

void MouseListener::controlToggled(bool isControlling)
{
    controlling = isControlling;
    if (isControlling)
    {
        timer.start();
    }
    else
    {
        timer.stop();
    }
}

void MouseListener::queryMouse()
{
    emit newMouse(SamplePoint(Timer::timestamp(), QCursor::pos()));
}
