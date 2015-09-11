import QtQuick 2.0
import QtGraphicalEffects 1.0
import "tutorial.js" as Tutorial

Item {
    id: tutorial
    property bool active: true
    property int lesson: 0
    property var lessons: []
    property var curLesson: lessons[lesson]
    property bool lockStep: false
    property var instructions: instruct
    property var instructionsRectangle: instructionsRect;
    z: 150

    signal started()

    onLessonChanged: {
        if (lesson < lessons.length) curLesson = lessons[lesson];
        else curLesson = null;
    }

    signal ended()

    Rectangle {
        id: instructionsRect
        color: Qt.rgba(0.9, 0.9, 0.9, 0.7)
        x: win.width / 2 - width / 2
        y: win.height / 2 - height / 2
        width: win.width / 4
        height: win.height / 4
        visible: active

        Text {
            id: instruct
            anchors.centerIn: parent
            font.pixelSize: 30
            width: 0.9 * instructionsRect.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: "Press <SPACE> to start the tutorial"
        }
    }

    function findKey(name) {
        var keyWithName;
        win.keyObjs.forEach(function(key) {
            if (key.objectName === name) {
                keyWithName = key;
            }
        });
        return keyWithName;
    }

    Connections {
        target: textField
        onNewWord: {
            if (curLesson) curLesson.onNewWord(word);
        }
        onWordDeleted: {
            if (curLesson) curLesson.onWordDeleted(word);
        }
        onCharAdded: {
            if (curLesson) curLesson.onCharAdded(addedChar);
        }
        onCharDeleted: {
            if (curLesson) curLesson.onCharDeleted();
        }
    }

    Connections {
        target: pEyeGesture
        onClick: {
            if (curLesson) curLesson.onGestureToggled();
        }
    }

    Connections {
        target: typingManager
        onCancelGesture: {
            if (curLesson) curLesson.onGestureCanceled();
        }
    }

    onEnded: {
        gazeTimer.stop();
        active = false;
        giveUserControl();
    }

    function nextStep() {
        if (!gazeTimer.running) {
            started();
            gazeTimer.start();
        }
        if (curLesson) {
            if (!curLesson.nextStep()) {
                nextLesson();
            }
        }
        else ended();
    }

    Component.onCompleted: {
        initLessons();
    }

    function initLessons() {
    }

    property var gazeTimer: Timer {
        id: gazeTimer
        interval: 30
        running: false
        repeat: true
        property double centerX: 0
        property double centerY: 0
        property double amplitude: 10
        property double period: 600
        property double t0: 0
        property bool oscilating: true

        function moveTo(cx, cy) {
            pointer.visible = true;
            centerX = cx;
            centerY = cy;
        }

        onTriggered: {
            if (!t0) t0 = new Date().valueOf();
            var dt = new Date().valueOf() - t0;
            pointer.centerX = centerX + (oscilating ? amplitude * Math.cos(2 * Math.PI / period * dt) : 0);
            pointer.centerY = centerY + (oscilating ? amplitude * Math.cos(2 * Math.PI / period * dt) : 0);
        }
    }

    function giveUserControl() {
        instructionsRect.visible = false;
        pointer.visible = false;
        win.isPaused = false;
        lockStep = true;
    }

    function resumeTutorial() {
        instructionsRect.visible = true;
        win.isPaused = true;
        lockStep = false;
    }

    function nextLesson() {
        pointer.visible = false;
        canvas.points = [];
        textField.clear();
        lesson++;
        nextStep();
    }

    function processKeys(event) {
        if (!active) return false;
        if (event.key === Qt.Key_Space) {
            if (!lockStep) nextStep();
            return true;
        }
        return false;
    }

    DropShadow {
        anchors.fill: instructionsRect
        horizontalOffset: 3
        verticalOffset: 3
        radius: 5
        source: instructionsRect
        visible: instructionsRect.visible
    }
}

