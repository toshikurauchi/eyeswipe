import QtQuick 2.0
import QtMultimedia 5.0

Rectangle {
    id: kbButton
    property double size: 100
    width: size
    height: size
    property double sensitiveDist: Math.min(width, height) * 0.1
    property double sensitiveDistSq: sensitiveDist * sensitiveDist
    property double centerX: width / 2
    property double centerY: height / 2
    property double radiusRatio: 1 / 8
    x: centerX - width / 2
    y: centerY - height / 2
    // 0 1
    // 2 3
    property var squareBorders: []
    property double dwellTime: 600 // milliseconds
    property double selectionTime: 100 // milliseconds
    property double timeoutTime: 50    // milliseconds
    property double timeinTime: 20     // milliseconds
    property bool clickingEnabled: false
    property bool enabled: true
    property double dwellRef: 0
    property double timeOutRef: 0
    property double mouseInRef: 0
    property double mouseOutRef: 0
    property double curTstamp: 0
    property bool wasIn: false
    property string text: ""
    property bool strikeout: false
    // 0 1 2
    // 3 4 5
    // 6 7 8
    property var gridText: ["","","","","","","","",""]
    property double fontSize: size / 4
    property double gridFontSize: -1
    property color gridTextColor: "black"
    property color gridSelectedTextColor: gridTextColor
    property alias fontScale: label.scale
    property bool isSelected: false
    property color unselectedColor: "white"
    property color selectedColor: "light gray"
    property color disabledColor: "light gray"
    property color borderColor: "black"
    property color visibleColor: !enabled ? disabledColor : isSelected ? selectedColor : unselectedColor
    property color textColor: "black"
    property color textSelectedColor: textColor
    property color textDisabledColor: "gray"
    color: "transparent";

    signal click(var button, double timestamp, bool playSound)
    signal mouseOut(var button)
    signal selected(var button)

    onClick: {
        isSelected = false;
        expManager.logKeyClicked(objectName)
    }

    onMouseOut: {
        if (isSelected) expManager.logKeyOut(objectName);
        wasIn = false;
        isSelected = false;
        dwellRef = 0;
        dwellBar.progress = 0;
    }

    onSelected: {
        if (!isSelected) expManager.logKeySelected(objectName)
        isSelected = true;
    }

    Rectangle {
        id: innerRect
        anchors.centerIn: parent
        width: kbButton.width
        height: kbButton.height
        color: visibleColor
        border.color: borderColor
        radius: height * radiusRatio

        Repeater {
            // This makes the chosen corners square instead of rounded
            model: squareBorders
            Rectangle {
                width: innerRect.width / 2
                height: innerRect.height / 2
                color: visibleColor

                anchors {
                    left: modelData % 2 == 0 ? innerRect.left : undefined
                    right: modelData % 2 == 1 ? innerRect.right : undefined
                    top: Math.floor(modelData / 2) == 0 ? innerRect.top : undefined
                    bottom: Math.floor(modelData / 2) == 1 ? innerRect.bottom : undefined
                }

                // Border
                Rectangle {
                    color: borderColor
                    z: parent.z - 1

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom

                        leftMargin: modelData % 2 == 0 ? -innerRect.border.width : undefined
                        rightMargin: modelData % 2 == 1 ? -innerRect.border.width : undefined
                        topMargin: Math.floor(modelData / 2) == 0 ? -innerRect.border.width : undefined
                        bottomMargin: Math.floor(modelData / 2) == 1 ? -innerRect.border.width : undefined
                    }
                }
            }
        }

        Grid {
            id: grid
            columns: 3
            anchors.centerIn: innerRect
            property double scale: 0.8
            width: innerRect.width * scale
            height: innerRect.height * scale

            Repeater {
                model: 9
                Text {
                    width: grid.width/3
                    height: grid.height/3
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    text: gridText[index]
                    font.pixelSize: gridFontSize > 0 ? gridFontSize : height
                    color: kbButton.enabled ? (kbButton.isSelected ? gridSelectedTextColor : gridTextColor) : textDisabledColor
                }
            }
        }
    }

    Text {
        id: label
        text: kbButton.text;
        font.strikeout: strikeout
        font.pixelSize: kbButton.fontSize;
        anchors.centerIn: innerRect;
        width: innerRect.width * 0.8
        horizontalAlignment: Text.AlignHCenter
        scale: paintedWidth > innerRect.width * 0.8 ? (innerRect.width * 0.8 / paintedWidth) : 1
        color: kbButton.enabled ? (kbButton.isSelected ? textSelectedColor : textColor) : textDisabledColor
        wrapMode: Text.WordWrap
    }

    KeyboardProgressBar {
        id: dwellBar
        width: parent.width * 0.8
        height: parent.height / 8
        x: (parent.width - width) / 2
        y: parent.height - 2 * height
        visible: progress > 0 && progress < 1
    }

    MouseArea {
        anchors.fill: parent
        onPressed: isSelected = true;
        onReleased: isSelected = false;
    }

    function show() {
        visible = true;
    }

    function winPos() {
        return parent.mapToItem(null, x, y);
    }

    function centerWinPos() {
        return parent.mapToItem(null, centerX, centerY);
    }

    function centerXWin() {
        return centerWinPos().x;
    }

    function centerYWin() {
        return centerWinPos().y;
    }

    function textPos(txt) {
        var center = Qt.point(centerX, centerY);
        for (var i = 0; i < gridText.length; i++) {
            if (gridText[i].indexOf(txt) > -1) {
                var pos = Qt.point(x + (i%3+0.5)*width/3, y + (Math.floor(i/3)+0.5)*height/3);
                return pos
            }
        }
        return center;
    }

    function textPosWin(txt) {
        var pos = textPos(txt);
        return parent.mapToItem(null, pos.x, pos.y);
    }

    function containsPoint(point) {
        return distanceSquareToButton(point) <= 1; // EPSILON = 1 px
    }

    function distanceToButton(point) {
        return Math.sqrt(distanceSquareToButton(point));
    }

    function distanceSquareToButton(point) {
        point = parent.mapFromItem(null, point.x, point.y)
        var dx = Math.max(0, Math.abs(point.x - centerX) - width / 2);
        var dy = Math.max(0, Math.abs(point.y - centerY) - height / 2);
        return dx*dx + dy*dy;
    }

    function distanceSquareToCenter(point) {
        point = parent.mapFromItem(null, point.x, point.y);
        var dx = point.x - centerX;
        var dy = point.y - centerY;
        return dx*dx + dy*dy;
    }

    function inSensitiveArea(point) {
        return distanceSquareToButton(point) <= sensitiveDistSq;
    }

    function resetRefs(tstamp) {
        dwellRef = tstamp;
        mouseOutRef = tstamp;
        mouseInRef = tstamp;
        isSelected = false;
    }

    function startSelection(tstamp) {
        dwellRef = tstamp;
    }

    function onNewSample(sample, tstamp, isCurrent, autoStart) {
        curTstamp = tstamp;
        if (typeof(autoStart) === "undefined") autoStart = false;

        if (!enabled) {
            resetRefs(tstamp);
            return;
        }

        if (!inSensitiveArea(sample)) {
            if (wasIn || mouseOutRef == 0) {
                wasIn = false;
                mouseOutRef = tstamp;
            }
            mouseInRef = tstamp;

            if (isCurrent && tstamp - mouseOutRef > timeoutTime) {
                dwellRef = tstamp;
                if (clickingEnabled) mouseOut(kbButton);
            }
            return;
        }
        if (autoStart && dwellRef == 0) dwellRef = tstamp;

        mouseOutRef = tstamp;
        if (!wasIn || mouseInRef == 0) {
            wasIn = true;
            mouseInRef = tstamp;
        }

        if (!isCurrent) return;
        var ellapsed = tstamp - dwellRef;
        if (ellapsed >= selectionTime) {
            if (clickingEnabled) {
                var progress = (curTstamp - dwellRef - selectionTime) / dwellTime;
                dwellBar.setProgress(progress);
            }
            if (clickingEnabled && ellapsed >= dwellTime + selectionTime) {
                click(kbButton, dwellRef, true);
                dwellRef = tstamp;
            }
            else if (!clickingEnabled || !isSelected) {
                selected(kbButton);
                if (!clickingEnabled) dwellRef = tstamp;
            }
        }

    }
}
