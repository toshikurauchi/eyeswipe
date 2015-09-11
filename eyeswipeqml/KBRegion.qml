import QtQuick 2.0

Rectangle {
    id: curRegion

    property var buttons
    property var curActiveButton: null
    property var lastSelectedButton: null
    property bool enabled: true
    property bool showRegion: true
    property double latestTstamp: 0
    property int regionId: -1
    color: showRegion ? "light gray" : "transparent"
    radius: 10
    border.color: showRegion ? enabled ? "black" : "dark gray" : "transparent"
    width: childrenRect.width + 2 * margin
    height: childrenRect.height + 2 * margin
    property int margin: 20

    signal handleNewSample(var sample, double tstamp);
    signal handleNewFixation(var fixation, double tstamp, double duration);
    signal handleIncompleteFixation(var fixation, double tstamp, double duration);

    onEnabledChanged: {
        if (enabled) {
            lastSelectedButton = null;
            buttons.forEach(function(button) {
                button.resetRefs(latestTstamp);
            });
        }
    }

    function contains(point) {
        return point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height;
    }

    function logKeys() {
        expManager.logKeyPos(curRegion.objectName, Qt.point(x, y), Qt.point(width, height))
        buttons.forEach(function(key) {
            expManager.logKeyPos(key.objectName, curRegion.mapToItem(null, key.centerX, key.centerY), Qt.point(key.width, key.height))
        });
    }

    function onNewSample(sample, tstamp) {
        latestTstamp = tstamp;
        if (!enabled) return;

        for (var i = 0; i < buttons.length; i++) {
            var button = buttons[i];
            var isCurrent = (button === curActiveButton);
            button.onNewSample(sample, tstamp, isCurrent);

            if (!button.enabled) continue;

            // Mouse is inside button
            if (curActiveButton === null && tstamp - button.mouseInRef > 0) {
                curActiveButton = button;
                curActiveButton.startSelection(tstamp);
            }
            else if (!isCurrent && tstamp - button.mouseInRef > button.timeinTime) {
                curActiveButton.mouseOut(curActiveButton);
                curActiveButton = button;
                curActiveButton.startSelection(tstamp);
            }
            // Timeout
            else if (isCurrent && tstamp - button.mouseOutRef > button.timeoutTime) {
                curActiveButton.mouseOut(curActiveButton);
                curActiveButton = null;
            }
            if (button.isSelected) lastSelectedButton = button;
        }
        handleNewSample(sample, tstamp);
    }

    function onNewFixation(fixation, tstamp, duration) {
        if (enabled) handleNewFixation(fixation, tstamp, duration);
    }

    function onIncompleteFixation(fixation, tstamp, duration) {
        if (enabled) handleIncompleteFixation(fixation, tstamp, duration);
    }

    Repeater {
        model: buttons
        Item {
            Connections {
                target: modelData
                onSelected: {
                    win.keySelected(modelData, latestTstamp);
                }
            }
        }
    }
}
