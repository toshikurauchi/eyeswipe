import QtQuick 2.3

Rectangle {
    border.color: "black"
    radius: height / 4
    property double progress: 0
    property color fillColor: "black"

    function reset() {
        progress = 0;
    }

    function setProgress(newProgress) {
        progress = newProgress;
        if (progress >= 1) {
            progress = 1;
            return false;
        }
        if (progress < 0) {
            progress = 0;
            return false;
        }
        return true;
    }

    function increaseProgress(inc) {
        return setProgress(progress + inc);
    }

    function decreaseProgress(dec) {
        return setProgress(progress - dec);
    }

    Rectangle {
        x: 0
        y: 0
        width: parent.width * parent.progress
        height: parent.height
        radius: parent.radius
        border.color: parent.border.color
        visible: parent.visible
        color: fillColor
    }
}
