import QtQuick 2.3

GestureKeyboardWindow {
    id: win
    title: isExperiment ? qsTr("Keyboard RED") : qsTr("EyeSwipe")

    showRegions: false
    dimInGesture: false
    showSelectionFeedback: true
    showCandidates: true
    changeWordOnSelection: false
    disableCurrentCandidate: true
    staticCandidates: true
    backspaceWithCandidates: true
    freePunctMode: true
    punctMode: stateMachine.punctMode
    liveGazeOn: true

    property var keysActionRegionRef: keysActionRegion
    property var candidatesActionRegionRef: candidatesActionRegion
    property var backspaceActionRegionRef: backspaceActionRegion
    property var punctActionRegionRef: punctActionRegion

    onKeySelected: {
        stateMachine.onNewSelection(button, timestamp);
    }

    KBPeyeRegion {
        id: keysActionRegion
        objectName: "keysActionRegion"
        regionId: stateMachine.regions.actionKeys
        x: refButton ? refButton.centerXWin() - leftDist : 0
        y: refButton ? refButton.centerYWin() - upDist : 0
        acceptOffset: 2 * keySize
        buttons: refButton ? [refButton, gesturePeye] : [gesturePeye]
        property string firstCandidate: "-"

        function updateFirstCandidate() {
            var newCandidates = predictor.getCandidates(latestTstamp);
            if (newCandidates.length > 0) firstCandidate = newCandidates[0];
            else firstCandidate = "-";
        }

        PEyeButton {
            id: gesturePeye
            objectName: "gesturePeye"
            visible: parent.enabled
            position: 1
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: inGesture ? keysActionRegion.firstCandidate : i18n("Start")
            textSelectedColor: "white"
        }
    }

    KBPeyeRegion {
        id: candidatesActionRegion
        objectName: "candidatesActionRegion"
        regionId: stateMachine.regions.actionCandidates
        x: refButton ? refButton.centerXWin() - leftDist : 0
        y: refButton ? refButton.centerYWin() - upDist : 0
        acceptOffset: 2 * keySize
        buttons: refButton ? [refButton, candidatesPeye] : [candidatesPeye]

        PEyeButton {
            id: candidatesPeye
            objectName: "candidatesPeye"
            enabled: parent.refButton && parent.refButton.enabled
            visible: parent.enabled && enabled
            position: 1
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: i18n("Select")
            textSelectedColor: "white"
        }
    }

    KBPeyeRegion {
        id: backspaceActionRegion
        objectName: "backspaceActionRegion"
        regionId: stateMachine.regions.actionBackspace
        x: refButton ? refButton.centerXWin() - leftDist : 0
        y: refButton ? refButton.centerYWin() - upDist : 0
        acceptOffset: 2 * keySize
        buttons: refButton ? [refButton, backspacePeye] : [backspacePeye]

        PEyeButton {
            id: backspacePeye
            objectName: "backspacePeye"
            visible: parent.enabled
            position: 1
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: backspaceKeyRef.cancelMode ? i18n("Cancel") : i18n("Delete")
            textSelectedColor: "white"
        }
    }

    KBPeyeRegion {
        id: punctActionRegion
        objectName: "punctActionRegion"
        regionId: stateMachine.regions.actionPunct
        x: refButton ? refButton.centerXWin() - leftDist : 0
        y: refButton ? refButton.centerYWin() - upDist : 0
        acceptOffset: 2 * keySize
        buttons: refButton ? [refButton, dotPeye, exclamationPeye, questionPeye, commaPeye] : [dotPeye, exclamationPeye, questionPeye, commaPeye]

        PEyeButton {
            id: dotPeye
            objectName: "dotPeye"
            visible: parent.enabled
            position: 1
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: "."
            textSelectedColor: "white"
        }

        PEyeButton {
            id: commaPeye
            objectName: "commaPeye"
            visible: parent.enabled
            position: 3
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: ","
            textSelectedColor: "white"
        }

        PEyeButton {
            id: exclamationPeye
            objectName: "exclamationPeye"
            visible: parent.enabled
            position: 5
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: "!"
            textSelectedColor: "white"
        }

        PEyeButton {
            id: questionPeye
            objectName: "questionPeye"
            visible: parent.enabled
            position: 7
            refX: parent.refX
            refY: parent.refY
            timeoutTime: 1000
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            text: "?"
            textSelectedColor: "white"
        }
    }

    EyeSwipeStateMachine {
        id: stateMachine
        backspaceKey: backspaceKeyRef
        allKeys: getKeys()
        allCandidateKeys: getCandidatesKeys()
        punctKey: punctKeyRef
        regionRefs: win.regionRefs
        keysActionRegion: win.keysActionRegionRef
        candidatesActionRegion: win.candidatesActionRegionRef
        backspaceActionRegion: win.backspaceActionRegionRef
        punctActionRegion: win.punctActionRegionRef

        onNewFirstLetter: {
            firstLetters = letter;
        }

        onNewLastLetter: {
            lastLetters = letter;
        }

        onStartedTyping: {
            startGesture(tstamp);
            resetCandidates();
        }

        onFinishedTyping: {
            if (keysActionRegion.firstCandidate !== "-") {
                finishGesture(tstamp, keysActionRegion.firstCandidate);
                currentWord = keysActionRegion.firstCandidate;
            }
            else cancelGesture(tstamp);
        }

        onCandidateSelected: {
            if (candidate) {
                textFieldRef.changeCandidate(candidate);
                currentWord = candidate;
            }
        }

        onCancelTyping: {
            cancelGesture(tstamp);
        }

        onDeleteWord: {
            textFieldRef.deleteWord();
            resetCandidates();
        }

        onCancelModeChanged: {
            backspaceKey.cancelMode = cancelMode;
        }

        onPunctuationTyped: {
            addPunct(punctuation);
        }

        function resetCandidates() {
            candidates = [];
            currentWord = "";
        }
    }
}
