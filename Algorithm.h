#ifndef ALGORITHM_H
#define ALGORITHM_H

#include <algorithm>

template<typename T, typename Compare>
inline T topN(T container, int n, Compare comp)
{
    T topElements;
    std::make_heap(container.begin(), container.end(), comp);
    while (n && container.size() > 0)
    {
        topElements.push_back(container.front());
        std::pop_heap(container.begin(), container.end(), comp);
        container.pop_back();
        n--;
    }
    return topElements;
}

#endif // ALGORITHM_H
