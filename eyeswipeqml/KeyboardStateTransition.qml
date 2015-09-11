import QtQuick 2.0

Item {
    property var to
    property var accept: to ? [to.regionId] : []
    property var acceptedDataTypes: [0, 1, 2] // All gaze data types

    function accepts(region) {
        return accept.indexOf(region) >= 0;
    }

    signal activated(double tstamp);
}
