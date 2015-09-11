import QtQuick 2.0

Item {
    id: menu
    property var mainButtons: []
    property var currentButton: null
    property double dwellReference: 0
    property double inMenuButNoButtonTime: 500 // milliseconds
    property double enterTimestamp: 0
    property double curTstamp: 0
    property double t0: new Date().valueOf()
    property bool active: false
    property var lastFocusedButton: null
    property var buttons: []
    property var alwaysVisibleButtons: []
    property var allButtons: buttons.concat(alwaysVisibleButtons)
    property bool buttonsVisible: false
    property bool showArrows: false
    property bool shouldUpdateKeys: true
    property double menuTransparency: 0.2
    z: 98

    signal displayed()
    signal hidden()

    onActiveChanged: {
        if (!active) {
            hide();
        }
    }

    Repeater {
        model: buttons
        Arrow {
            id: arrow
            fromX: menu.currentButton ? menu.currentButton.centerX : 0
            fromY: menu.currentButton ? menu.currentButton.centerY : 0
            toX: modelData.centerX
            toY: modelData.centerY
            offsetBefore: menu.currentButton ? menu.currentButton.size / 2 : 0
            offsetAfter: modelData.size / 2
            visible: modelData.visible && showArrows
            inverted: modelData.isSelected
            z: 80
        }
    }

    Repeater {
        model: mainButtons
        Item {
            Connections {
                target: modelData
                onSelected: {
                    if (!active) {
                        if (buttonsVisible) hide();
                        return;
                    }

                    if (buttonsVisible && currentButton === button) {
                        if (lastFocusedButton && !lastFocusedButton.clickingEnabled) {
                            lastFocusedButton.click(currentButton, enterTimestamp, true);
                            hide();
                        }
                    }
                    else {
                        hide();
                        resetT0();
                        enterTimestamp = curTstamp
                        currentButton = button;
                        show();
                    }
                }
            }
        }
    }
    Repeater {
        model: allButtons
        Item {
            Connections {
                target: modelData
                onSelected: {
                    if (buttonsVisible) {
                        if (currentButton) currentButton.isSecondSelect = true;
                        lastFocusedButton = button;
                        buttons.forEach(function (button) {
                            if (button !== lastFocusedButton) {
                                button.mouseOut(button);
                            }
                        });
                    }
                }
                onClick: {
                    if (buttonsVisible) {
                        hide();
                    }
                }
            }
        }
    }

    function resetT0() {
        t0 = new Date().valueOf();
    }

    function show() {
        displayed();
        menu.opacity = menuTransparency;
        buttons.forEach(function (button, idx, arr) {
            button.refX = currentButton.centerX;
            button.refY = currentButton.centerY;
            button.show();
        });
        buttonsVisible = true;
    }

    function hide() {
        buttonsVisible = false;
        buttons.forEach(function (button, idx, arr) {
            button.visible = false;
            button.mouseOut(button);
        });
        mainButtons.concat(alwaysVisibleButtons).forEach(function(button) {
            button.mouseOut(button);
        });
        if (currentButton) currentButton.isSecondSelect = false;
        lastFocusedButton = null;
        currentButton = null;
        hidden();
    }

    function contains(point) {
        if (!currentButton) return false;
        var minX, maxX, minY, maxY;
        var someRegionContains = false;
        allButtons.forEach(function (button, idx, arr) {
            minX = Math.min(button.x, currentButton.x) - button.keySize / 5;
            maxX = Math.max(button.x + button.width, currentButton.x + currentButton.width) + button.keySize / 5;
            minY = Math.min(button.y, currentButton.y) - button.keySize / 5;
            maxY = Math.max(button.y + button.height, currentButton.y + currentButton.height) + button.keySize / 5;
            if (button.visible && point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY) someRegionContains = true;
        });
        return someRegionContains;
    }

    function onNewSample(sample, tstamp) {
        curTstamp = tstamp;
        if (!active) return;
        if (buttonsVisible) {
            if (!currentButton || currentButton.containsPoint(sample) ||
                (lastFocusedButton && lastFocusedButton.containsPoint(sample))) {
                resetT0();
                dwellReference = tstamp;
            }
            var selectedStateChanged = false;
            allButtons.forEach(function (button, idx, arr) {
                if (button.visible) {
                    var prev = button.isSelected;
                    button.onNewSample(sample, tstamp);
                    if (prev !== button.isSelected) {
                        menu.opacity = (button.isSelected ? 1 : menuTransparency)
                        selectedStateChanged = true;
                    }
                }
            });
            if (currentButton) currentButton.onNewSample(sample, tstamp);
            if (tstamp - dwellReference > inMenuButNoButtonTime) {
                hide();
            }
        }
        if (!contains(sample) && shouldUpdateKeys) {
            mainButtons.forEach(function(button) {
                if (button.visible) button.onNewSample(sample, tstamp);
            });
        }
    }
}
