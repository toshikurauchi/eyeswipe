#ifndef QLISTUTIL_H
#define QLISTUTIL_H

#include <QList>

class QListUtil
{
public:
    template<typename T>
    static T avg(QList<T> const& list)
    {
        T mean;
        foreach(T t, list)
        {
            mean += t;
        }
        if (list.length() == 0) return mean;
        return mean / list.length();
    }
};

#endif // QLISTUTIL_H
