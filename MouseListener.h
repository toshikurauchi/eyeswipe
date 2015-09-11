#ifndef MOUSELISTENER_H
#define MOUSELISTENER_H

#include <QObject>
#include <QThread>
#include <QTimer>

#include "SamplePoint.h"

class MouseListener : public QObject
{
    Q_OBJECT
public:
    explicit MouseListener(QObject *root, bool controlling = true);
    ~MouseListener();
    void setControlling(bool controlling);

signals:
    void newMouse(SamplePoint mouse);

public slots:
    void controlToggled(bool isControlling);

private slots:
    void queryMouse();

private:
    bool controlling;
    QTimer timer;
};

#endif // MOUSELISTENER_H
