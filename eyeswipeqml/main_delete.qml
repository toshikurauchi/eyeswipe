import QtQuick 2.3

GestureKeyboardWindow {
    // TODO Set TypingActivation threshold depending on training

    id: win
    title: isExperiment ? qsTr("Keyboard GREEN") : qsTr("EyeSwipe2")

    highlightOnGaze: false
    showRegions: true
    dimInGesture: true
    showPrevWord: true
    greenActionColor: true
    liveGazeOn: false

    // ******************** Slots ********************
    onNewFixation: {
        if (!isPaused) {
            typingActivation.onNewFixation(fixation, stateMachine.point2Region(fixation), tstamp, duration);
        }
    }

    // ******************** Typing activation ********************
    TypingActivation {
        id: typingActivation
        fixationThreshold: halfKeySize
        active: stateMachine.inKeys
        onTypingMode: typingManagerRef.onTypingMode

        onStart: {
            startGesture(tstamp);
            restartFeedbackAnimation.restart(fixation);
        }

        onRestart: {
            restartGesture(tstamp);
            restartFeedbackAnimation.restart(fixation);
        }
    }

    // ******************** Restart feedback ********************
    Timer {
        id: restartFeedbackAnimation
        interval: 500
        repeat: false
        property var reference: null
        property var highlightedKeys: []
        property double distThreshold: keySize
        property double distThresholdSq: distThreshold * distThreshold
        property int maxLetters: 5

        function getLetters(keys) {
            var letters = "";
            for (var i = 0; i < keys.length; i++) letters += keys[i].objectName[0];
            return letters;
        }

        function restart(fixation) {
            stop();
            reference = fixation;
            start();
        }

        onRunningChanged: {
            var highlight = running;
            getKeys().forEach(function(key) {
                if (highlight && highlightedKeys.indexOf(key) >= 0) key.strongHighlight = true;
                else key.strongHighlight = false;
            });
        }

        onHighlightedKeysChanged: {
            firstLetters = getLetters(restartFeedbackAnimation.highlightedKeys);
        }

        onReferenceChanged: {
            if (reference === null) {
                highlightedKeys = [];
                return;
            }
            var dist2key = ({});
            var distances = [];
            getKeys().forEach(function(key) {
                var dist = key.distanceSquareToCenter(reference);
                if (dist < distThresholdSq) {
                    while (dist in dist2key) dist -= 0.01;
                    dist2key[dist] = key;
                    distances.push(dist);
                }
            });
            distances.sort();
            var newHighlightedKeys = [];
            for (var i = 0; i < distances.length && i < maxLetters; i++) newHighlightedKeys.push(dist2key[distances[i]]);
            highlightedKeys = newHighlightedKeys;
        }
    }

    // ******************** State Machine ********************
    EyeSwipe2StateMachine {
        id: stateMachine
        objectName: "stateMachine"

        restartAfterPunct: !isExperiment
        onTypingMode: inGesture
        regionRefs: win.regionRefs
        backspaceKey: win.backspaceKeyRef
        cancelKeys: win.getCancelKeys()

        onStartedTyping: {
            startGesture(tstamp);
        }

        onFinishedTyping: {
            finishGesture(tstamp, currentWord);
        }

        onCancelTyping: {
            cancelGesture(tstamp);
        }

        onShowCandidates: {
            inDeletion = false;
            updateReferenceX(win.latestSample.x);
            var newCandidates = predictor.getCandidates(tstamp);
            if (keysRegionRef.inPunct || (newCandidates.length === 0 && punctKeyRef.selectedRecently)) {
                candidates = punctKeyRef.punctMarks;
            }
            else {
                candidates = newCandidates;
            }
            win.showCandidates = true;
            if (!win.disableCurrentCandidate) {
                candObjs.forEach(function(button) {
                    button.enabled = true;
                });
            }
        }

        onHideCandidates: {
            win.showCandidates = false;
            currentWord = "";
        }

        onChangeCandidate: {
            textFieldRef.changeCandidate(candidate);
            currentWord = candidate;
        }

        onShowDeleteOptions: {
            updateReferenceX(win.x + win.width);
            candidates = [textFieldRef.lastWord].concat(textFieldRef.lastCandidates(false));
            deletionContext = textFieldRef.secondToLastWord;
            inDeletion = true;
            win.showCandidates = true;
        }

        onHideDeleteOptions: {
            win.showCandidates = false;
            inDeletion = false;
            deletionContext = ""
            candidates = [];
        }

        onDeleteWord: {
            textFieldRef.deleteWord();
        }
    }
}
