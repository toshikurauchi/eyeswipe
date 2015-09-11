import QtQuick 2.0

KBButton {
    id: keyboardKey
    property bool isStart: false
    property bool isSecondSelect: false
    property color secondSelectColor: Qt.rgba(0.62, 0.98, 1, 1)
    property bool shouldLog: true
    fontSize: size / 4
    visibleColor: !enabled ? disabledColor : isSecondSelect ? secondSelectColor : isSelected ? selectedColor : unselectedColor

    signal keySelected(var key);
    signal keyUnselected(var key);

    function logPosition() {
        if (shouldLog) {
            expManager.logKeyPos(objectName, parent.mapToItem(null, centerX, centerY), Qt.point(width, height));
        }
    }

    onCenterXChanged: logPosition()
    onCenterYChanged: logPosition()
    onWidthChanged: logPosition()
    onHeightChanged: logPosition()
}
