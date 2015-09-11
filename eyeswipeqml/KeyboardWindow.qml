import QtQuick 2.3
import QtQuick.Controls 1.2
import "i18n.js" as I18N

ApplicationWindow {
    id: win
    visible: true
    color: "whitesmoke"
    //visibility: "Maximized"
    x: 240
    y: 30
    width: 1440
    height: 1080

    Rectangle {
        anchors.fill: parent
        color: win.color
    }

    // ******************** Layout Properties ********************
    property double realAspect: width / height
    property double aspect: Math.min(Math.max(realAspect, 1), 1.5)
    property double availableWidth: Math.min(height * aspect, width)
    property double availableHeight: availableWidth / aspect;
    property double layoutX0: (width - availableWidth) / 2
    property double layoutY0: (height - availableHeight) / 2
    property double textHeight: Math.min(50, keySize)
    property double textVSpace: textHeight / 5
    property double keySpaceRatio: 0.25
    property double keySize: availableWidth / (14 + 11 * keySpaceRatio)
    property double halfKeySize: keySize / 2
    property double candidateKeySize: 1.5 * keySize
    property double keySpace: keySpaceRatio * keySize
    property double kbX0: keySize
    property double kbY0: layoutY0 + 2 * textVSpace + 2 * keySize
    property double keysX0: layoutX0 + kbX0
    property double keysY0: layoutY0 + kbY0 + emptyVSpace
    property double textRegionX0: keysX0 + keySize + keySpace
    property double textRegionY0: layoutY0 + textVSpace
    property double textRegionWidth: keysRegionWidth - keySize - keySpace
    property double keysRegionWidth: 12 * keySize + 11 * keySpace
    property double keysRegionHeight: (isExperiment ? 3 : 4) * keySize + 3 * keySpace
    property double candidatesRegionY: 2 * textVSpace + keySize + emptyVSpace / 2
    property double gestureKeyWidth: 10 * keySize + 9 * keySpace
    property double emptyVSpace: availableHeight - kbY0 - 5 * keySize - 3 * keySpace
    property double textFontSize: availableHeight * 0.03
    property double candidateFontSize: candidateRef !== null ? candidateRef.fontSize : textFontSize

    // Candidate font size
    Key {
        id: candidateRef

        text: "aaaaaa"
        fontSize: textFontSize
        radiusRatio: pEyeGesture.radiusRatio
        enabled: false
        size: candidateKeySize
        width: candidateKeySize
        height: pEyeGesture.height
        visible: false
        clickingEnabled: false

        onFontScaleChanged: {
            if (fontScale < 1 && fontSize > 5) fontSize -= 1;
        }
    }

    // ******************** Keyboard Properties ********************
    property bool isExperiment: true // Set this to false to access the keyboard with extra options
    property bool experimentStarted: false
    property bool experimentFinished: false
    property bool showArrows: false
    property bool isPaused: isExperiment
    property bool dwellKeyboard: false
    property bool keysLogged: false
    property bool isEnglish: true
    property double sessionDuration: 5 * 60 * 1000
    property int sessionCount: expManager ? expManager.getCurrentSessionID() : 1
    property int totalSessions: expManager ? expManager.getTotalSessions() : 3
    property bool isMouseControlling: false
    property bool waitingForStart: false

    onIsEnglishChanged: {
        if (isEnglish) I18N.setLanguage(I18N.Languages.EN);
        else I18N.setLanguage(I18N.Languages.PT);
    }

    // ******************** Gaze Properties ********************
    property var latestSample: null
    property var latestFixation: null
    property var latestIncompleteFixation: null

    onNewSample: {
        if (pointer.active) {
           pointer.centerX = sample.x;
           pointer.centerY = sample.y;
        }

        if (isPaused) {
            startNextRegion.onNewSample(sample, tstamp);
            return;
        }

        latestSample = sample;
    }

    onNewFixation: {
        if (isPaused) {
            startNextRegion.onNewFixation(fixation, tstamp, duration);
            return;
        }
        latestFixation = fixation;
    }

    onNewIncompleteFixation: {
        if (isPaused) {
            startNextRegion.onIncompleteFixation(fixation, tstamp, duration);
            return;
        }
        latestIncompleteFixation = fixation;
    }

    function connectPointerManager() {
        Qt.createQmlObject(
       "import QtQuick 2.3;
        Connections {
            target: pointerManager;
            onNewSample: newSample(sample, tstamp);
            onNewFixation: newFixation(fixation, tstamp, duration);
            onIncompleteFixation: newIncompleteFixation(fixation, tstamp, duration);
        }",
         win, "main");
    }

    // ******************** Colors ********************
    property color pointerColor: Qt.rgba(59/255., 102/255., 255/255.)
    property color wordSelectionColor: Qt.rgba(115/255., 161/255., 126/255.)
    property color keyUnselectedColor: "white"
    property color keySelectedColor: "light gray"
    property color keyBorderColor: "black"
    property color gestureUnselectedColor: Qt.rgba(183/255., 255/255., 201/255.)
    property color gestureSelectedColor: Qt.rgba(115/255., 161/255., 126/255.)
    property color keystrokeUnselectedColor: gestureUnselectedColor
    property color keystrokeSelectedColor: gestureSelectedColor
    property color actionUnselectedColor: Qt.rgba(186/255., 119/255., 148/255.)
    property color actionSelectedColor: Qt.rgba(161/255., 103/255., 128/255.)
    property color candidateUnselectedColor: actionUnselectedColor
    property color candidateSelectedColor: actionSelectedColor
    property color yellowSelectedColor: Qt.darker(yellowUnselectedColor)
    property color yellowUnselectedColor: Qt.rgba(230/255., 185/255., 30/255.)
    property color menuBorderColor: "black"
    function pathColor(alpha) {
        return Qt.rgba(59/255., 102/255., 255/255., alpha);
    }

    // ******************** Signals ********************
    // Gaze signals
    signal newSample(var sample, double tstamp);
    signal newFixation(var fixation, double tstamp, double duration);
    signal newIncompleteFixation(var fixation, double tstamp, double duration);
    // Layout signals
    signal resized();
    // Control signals
    signal pointerToggled(bool isMouse);
    signal paused(bool isPaused);
    // Experiment signals
    signal logKeys();

    onWidthChanged: resized();
    onHeightChanged: resized();
    onIsPausedChanged: paused(isPaused);
    onLogKeys: {
        startNextRegion.logKeys();
    }

    // ******************** Functions ********************
    function mapToWindow(point) {
        return Qt.point(point.x - win.x, point.y - win.y);
    }
    function mapFromRegion(obj, point) {
        if (obj.parent) return obj.parent.mapToItem(null, point.x, point.y);
        return point;
    }

    function i18n(word) {
        return I18N.tr(word);
    }

    function startExperiment() {
        experimentStarted = true;
        expManager.startExperiment();

        if (!keysLogged) {
            logKeys();
            keysLogged = true;
        }

        waitForStart();
    }

    function sentenceTyped() {
        if (!isExperiment) return;
        isPaused = true;
        expManager.logTypedSentence(textField.typedText);
        if (expManager.sessionEllapsedTime() > sessionDuration) {
            expManager.stopExperiment();
            sessionCount = expManager.getCurrentSessionID();
            if (expManager.ended()) experimentFinished = true;
            experimentStarted = false;
        }
        else waitForStart();
    }

    function waitForStart() {
        waitingForStart = true;
    }

    function showNextSentence() {
        if (!experimentStarted) return;

        textField.clear();
        textField.sentenceToType = sentenceManager.randomSentence();
        expManager.logExpectedSentence(textField.sentenceToType);
    }

    // Overwrite this function to handle keyboard input
    function handleKeyPress(event) {
        // Return true if handled (will stop propagation)
        return false;
    }
    Item {
        focus: true
        Keys.onPressed: {
            if (handleKeyPress(event)) return;
            if (event.key === Qt.Key_T) {
                isMouseControlling = !isMouseControlling;
                pointerToggled(isMouseControlling);
            }
            else if (event.key === Qt.Key_R) {
                expManager.logRecalibrated();
                recalibratedAnimation.start();
            }
            else if (event.key === Qt.Key_S) {
                pointer.visible = !pointer.visible;
            }
            else if (event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier)) {
                Qt.quit();
            }
            else if (event.key === Qt.Key_P) {
                wpmText.visible = !wpmText.visible;
            }
            else if (event.key === Qt.Key_M) {
                showArrows = !showArrows;
            }
            else if (event.key === Qt.Key_Space) {
                if (experimentFinished) Qt.quit();
                else if (experimentStarted || !isExperiment) isPaused = !isPaused;
                else startExperiment();
            }
        }
    }

    // ******************** Components ********************
    // Pointers
    Rectangle {
        id: pointer
        objectName: "pointer"
        width: 10
        height: 10
        property int centerX: 5
        property int centerY: 5
        property bool active: visible
        x: centerX - width/2
        y: centerY - height/2
        z: 100
        color: pointerColor
        visible: false
        radius: 5
    }
    Rectangle {
        id: uncalibPointer
        objectName: "uncalibPointer"
        width: 10
        height: 10
        property int centerX: 5
        property int centerY: 5
        property bool active: visible
        x: centerX - width/2
        y: centerY - height/2
        z: 100
        color: "red"
        visible: pointer.visible
        radius: 5
    }
    Rectangle {
        id: realPointer
        objectName: "realPointer"
        width: 10
        height: 10
        property int centerX: 5
        property int centerY: 5
        property bool active: visible
        x: centerX - width/2
        y: centerY - height/2
        z: 100
        color: "green"
        visible: pointer.visible
        radius: 5
    }
    // Info
    Text {
        id: wpmText
        text: "Current: " + formatWPM(textField.wpm) + "Highest: " + formatWPM(textField.highestWPM)
        visible: false
        font.pixelSize: 20
        x: 10
        y: 10
        z: 100

        function formatWPM(value) {
            return parseFloat(Math.round(value * 100) / 100).toFixed(2) + " wpm";
        }
    }
    Timer {
        id: recalibratedAnimation
        interval: 1000
        repeat: false
    }
    Text {
        anchors.centerIn: parent
        text: i18n(recalibratedAnimation.running ? "Recalibrated" : "Paused")
        font.pointSize: 30
        visible: (isPaused && !waitingForStart) || recalibratedAnimation.running
        z: 150
    }
    // Experiment start
    KBRegion {
        id: startNextRegion
        objectName: "startNextRegion"
        visible: waitingForStart
        color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
        anchors.fill: parent
        z: 100
        buttons: [startNextKey]
        enabled: visible

        Key {
            id: startNextKey
            objectName: "startNextKey"
            width: Math.max(Math.min(4 * keySize, win.width / 3), keySize)
            height: 2 * keySize
            centerX: win.width / 2
            centerY: 3 * keySize
            enabled: visible
            visible: parent.visible
            clickingEnabled: true
            dwellTime: 500
            text: "Start"

            onClick: {
                waitingForStart = false;
                showNextSentence();
                isPaused = false;
            }
        }
    }
}
