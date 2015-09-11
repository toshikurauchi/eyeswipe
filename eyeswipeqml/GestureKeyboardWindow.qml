import QtQuick 2.3
import QtGraphicalEffects 1.0

KeyboardWindow {
    // TODO Things to log
    // - Start timer for dwell (sometimes we switch the current button - make sure we log that)
    // - Punctuation, space, candidate and cancel keys

    id: win

    // ******************** Properties ********************
    // Layout
    property bool highlightOnGaze: false
    property bool showRegions: true
    property bool showPrevWord: false
    property bool dimInGesture: true
    property bool showSelectionFeedback: false
    property bool greenActionColor: false
    property bool disableCurrentCandidate: false
    property bool staticCandidates: false
    property bool backspaceWithCandidates: false
    property bool freePunctMode: false
    property bool punctMode: false
    property bool showLiveGaze: inGesture && liveGazeOn
    property bool liveGazeOn: false
    property var keyObjs: getKeys()
    property var candObjs: getCandidatesKeys()
    property var regionRefs: [keysRegion, textRegion, candidatesRegion]
    property var keysRegionRef: keysRegion
    property var textRegionRef: textRegion
    property var candidatesRegionRef: candidatesRegion
    property var backspaceKeyRef: backspaceKey
    property var punctKeyRef: punctKey
    property var textFieldRef: textField
    property var typingManagerRef: typingManager
    // Keyboard
    property alias inGesture: typingManager.onTypingMode
    property string firstLetters: ""
    property string lastLetters: ""
    property alias candidates: typingManager.candidates
    property string deletionContext: ""
    property alias inDeletion: candidateRepeater.inDeletion
    property alias showCandidates: typingManager.showCandidates
    property string currentWord: ""
    property bool changeWordOnSelection: true

    // ******************** Functions ********************
    function updateReferenceX(x) {
        pEyeGesture.updateReferenceX(x);
    }
    // Regions
    function bellowCandidates(point) {
        return point.y > candidatesRegionY + candidatesRegion.height * 1.1;
    }
    function inKeysRegion(point) {
        return keysRegion.contains(point);
    }
    function inSpaceRegion(point) {
        return spaceKey.containsPoint(point);
    }
    // Repeaters
    function getKeys() {
        var allKeys = [];
        for (var i = 0; i < keyRepeater.count; i++) {
            for (var j = 0; j < keyRepeater.itemAt(i).count; j++) {
                allKeys.push(keyRepeater.itemAt(i).itemAt(j));
            }
        }
        return allKeys;
    }
    function getCandidatesKeys() {
        var allKeys = [];
        for (var i = 0; i < candidateRepeater.count; i++) {
            allKeys.push(candidateRepeater.itemAt(i));
        }
        return allKeys;
    }
    function getCancelKeys() {
        var allKeys = [];
        for (var i = 0; i < cancelRepeater.count; i++) {
            allKeys.push(cancelRepeater.itemAt(i));
        }
        return allKeys;
    }

    // ******************** Signals ********************
    signal startGesture(double timestamp)
    signal restartGesture(double timestamp)
    signal finishGesture(double timestamp, string selectedWord)
    signal addPunct(string punct);
    signal cancelGesture(double timestamp)
    signal newFirstLetters(string letters)
    signal newLastLetters(string letters)
    signal keySelected(var button, double timestamp);

    // ******************** Slots ********************
    onStartGesture: typingManager.startGesture(timestamp);
    onRestartGesture: typingManager.restartGesture(timestamp);
    onFinishGesture: typingManager.finishGesture(timestamp, selectedWord);
    onAddPunct: typingManager.addPunct(punct);
    onCancelGesture: typingManager.cancelGesture(timestamp);
    onNewFirstLetters: typingManager.newFirstLetters(letters);
    onNewLastLetters: typingManager.newLastLetters(letters);

    // Layout slots
    onBackspaceWithCandidatesChanged: {
        if (backspaceWithCandidates) backspaceKey.parent = candidatesRegion;
        else backspaceKey.parent = textRegion;
    }

    // Gaze slots
    onNewSample: {
        if (!isPaused) {
            dwellTimeSelection.onNewSample(sample, tstamp);
            stateMachine.onNewSample(sample, tstamp);
        }
    }
    onNewFixation: {
        if (!isPaused) {
            stateMachine.onNewFixation(fixation, tstamp, duration);
        }
    }
    onNewIncompleteFixation: {
        if (!isPaused) stateMachine.onIncompleteFixation(fixation, tstamp, duration);
    }

    onLogKeys: {
        keysRegion.logKeys();
        candidatesRegion.logKeys();
        textRegion.logKeys();
    }

    Rectangle {
        visible: isExperiment && !experimentStarted
        color: "white"
        anchors.fill: parent
        z: 200

        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: experimentFinished ? i18n("Thank you!") : i18n("Session ") + sessionCount + i18n("\nPress <Space> to start")
            font.pixelSize: 40
        }
    }

    function handleKeyPress(event) {
        if (event.key === Qt.Key_C) {
            liveGazeOn = !liveGazeOn;
            return true;
        }
        return false;
    }

    // GAZE FEEDBACK
    LiveGazeShape {
        // Current shape
        id: canvas
        z: 99
        objectName: "shape"
        anchors.fill: parent
        visible: showLiveGaze
    }

    GazeShape {
        // Shape used for prediction
        objectName: "filteredShape"
        z: 100
        anchors.fill: parent
        visible: false
        shapeStrokeColor: Qt.rgba(255, 0, 0, 255)
        shapeFillColor: Qt.rgba(0, 0, 255, 255)
    }

    GazeShape {
        objectName: "idealPath"
        z: 100
        anchors.fill: parent
        visible: false
        shapeStrokeColor: Qt.rgba(255, 255, 0, 255)
        shapeFillColor: Qt.rgba(0, 255, 255, 255)
    }

    Item {
        id: dwellTimeSelection
        property bool active: dwellKeyboard

        onActiveChanged: expManager.logUsingDwell(active)

        function onNewSample(sample, tstamp) {
            modeKey.onNewSample(sample, tstamp, true, true);

            if (!active) return;
            keyObjs.forEach(function (key) {
                key.onNewSample(sample, tstamp, true, true);
            });
            spaceKey.onNewSample(sample, tstamp, true, true);
            backspaceKey.onNewSample(sample, tstamp, true, true);
        }
    }

    Item {
        id: typingManager
        objectName: "typingManager"
        property var candidates: []
        property bool showCandidates: false
        property bool onTypingMode: false
        property string firstLetters: win.firstLetters
        property string lastLetters: win.lastLetters

        signal startGesture(double timestamp)
        signal restartGesture(double timestamp)
        signal finishGesture(double timestamp, string selectedWord)
        signal addPunct(string punct);
        signal cancelGesture(double timestamp)
        signal typingChanged(bool isTyping)
        signal keystroke(string letter)
        signal newFirstLetters(string letters)
        signal newLastLetters(string letters)

        onOnTypingModeChanged: {
            typingChanged(onTypingMode);
        }

        onStartGesture: {
            onTypingMode = true;
        }

        onRestartGesture: {
            onTypingMode = true;
        }

        onFinishGesture: {
            onTypingMode = false;
        }

        onAddPunct: {
            textField.addPunct(punct);
        }

        onCancelGesture: {
            onTypingMode = false;
        }

        onFirstLettersChanged: {
            newFirstLetters(firstLetters);
        }

        onLastLettersChanged: {
            newLastLetters(lastLetters);
        }
    }

    KBRegion {
        id: textRegion
        objectName: "textRegion"
        buttons: backspaceWithCandidates ? [] : [backspaceKey]
        regionId: stateMachine.regions.text
        x: textRegionX0 - margin - extraSpace
        y: textRegionY0
        width: textRegionWidth + 2 * margin + extraSpace
        height: keySize + 2 * margin
        showRegion: showRegions
        property double extraSpace: staticCandidates ? 0 : keySize + keySpace

        onXChanged: logKeys()
        onYChanged: logKeys()
        onWidthChanged: logKeys()
        onHeightChanged: logKeys()

        SmartTextField {
            id: textField
            objectName: "textField"
            radius: height / 8
            x: parent.margin
            y: parent.margin
            width: pEyeGesture.width + textRegion.extraSpace
            height: keySize
            wordSelectionColor: win.wordSelectionColor
            maxFontSize: textHeight
            charByChar: dwellKeyboard
            property string lastWord: ""
            property string secondToLastWord: ""

            onTypedTextChanged: {
                lastWord = textField.tokens.length > 0 ? textField.tokens[textField.tokens.length - 1].word : "";
                var spacePos = lastWord.lastIndexOf(" ");
                if (spacePos > 0) {
                    secondToLastWord = lastWord.substring(0, spacePos);
                }
                else {
                    secondToLastWord = textField.tokens.length > 1 ? textField.tokens[textField.tokens.length - 2].word : "";
                    secondToLastWord = secondToLastWord.substring(secondToLastWord.lastIndexOf(" ") + 1);
                }
                lastWord = lastWord.substring(spacePos + 1);
            }

            onPunctAdded: {
                sentenceTyped();
            }
        }

        Key {
            id: backspaceKey
            objectName: "backspaceKey"
            text: cancelMode ? i18n("Cancel") : "\u2190\n" + textField.lastWord
            textSelectedColor: "white"
            enabled: cancelMode || textField.lastWord.length > 0
            clickingEnabled: dwellKeyboard
            size: keySize
            width: size
            height: size
            selectedColor: greenActionColor ? gestureSelectedColor : actionSelectedColor
            unselectedColor: greenActionColor ? gestureUnselectedColor : actionUnselectedColor
            disabledColor: greenActionColor ? unselectedColor : "light gray"
            centerX: pEyeGesture.x + pEyeGesture.parent.x - parent.x + pEyeGesture.width + keySpace + halfKeySize
            centerY: halfKeySize + parent.margin
            property double latestSelection: -1
            property bool cancelMode: false

            onSelected: {
                latestSelection = curTstamp;
            }

            onClick: {
                stateMachine.deleteWord(curTstamp);
            }
        }
    }

    KBRegion {
        id: candidatesRegion
        objectName: "candidatesRegion"
        property var otherButtons: backspaceWithCandidates ? getCancelKeys().concat([pEyeGesture, backspaceKey]) : getCancelKeys().concat([pEyeGesture])
        buttons: getCandidatesKeys().concat(otherButtons)
        regionId: stateMachine.regions.candidates
        x: keysX0 - margin
        y: candidatesRegionY - margin
        width: 2 * (margin + keySpace + keySize) + gestureKeyWidth
        height: 2 * margin + keySize
        showRegion: showRegions

        onXChanged: logKeys()
        onYChanged: logKeys()
        onWidthChanged: logKeys()
        onHeightChanged: logKeys()

        GestureKey {
            id: pEyeGesture
            objectName: "pEyeGesture"
            size: spaceKey.size
            width: gestureKeyWidth
            height: spaceKey.height
            borderColor: typingManager.showCandidates ? "transparent" : menuBorderColor
            disabledColor: typingManager.showCandidates ? "transparent" : gestureUnselectedColor
            enabled: false
            displayedText: ""
            centerX: win.width / 2 - parent.x
            centerY: height / 2 + parent.margin
            referenceX: win.width / 2
            visible: !staticCandidates

            candidateRepeater: candidateRepeater
            candidateObjects: candObjs
            inGesture: win.inGesture

            function updateReferenceX(x) {
                var half = candidateKeySize / 2;
                referenceX = Math.min(Math.max(x, pEyeGesture.x + half), pEyeGesture.x + pEyeGesture.width - half);
            }
        }

        Repeater {
            id: candidateRepeater
            model: centers(pEyeGesture.referenceX, pEyeGesture.x + parent.x, pEyeGesture.width, candidateWidth + keySpace)
            property bool inDeletion: false
            property var prevWord: showPrevWord ? (inDeletion ? deletionContext : textField.lastWord) : ""
            property var unfilteredCandidates: (keysRegion.inPunct && !freePunctMode) ? punctKey.punctMarks : typingManager.candidates
            property var candidateList: (freePunctMode && unfilteredCandidates.length > 0 && textField.punctuation.indexOf(unfilteredCandidates[0]) >= 0) ? [] : unfilteredCandidates
            property int maxCandidates: 6
            property double candidateWidth: staticCandidates ? (pEyeGesture.width - (maxCandidates - 1) * keySpace) / maxCandidates : candidateKeySize

            function centers(refx, x0, w, sz) {
                var x = [];
                var i;
                if (staticCandidates) {
                    for (i = 0; i < maxCandidates; i++) {
                        x.push(pEyeGesture.x + candidateWidth / 2 + i * sz);
                    }
                    return x;
                }

                refx = Math.max(refx, candidateWidth / 2 + x0);
                var maxLeft = Math.max(0, Math.floor((refx - x0 - sz / 2) / sz));
                var maxRight = Math.max(0, Math.floor((x0 + w - refx - sz / 2) / sz));

                var left = 0;
                var right = 0;
                var indices = [0];
                var added = true;
                for (i = 1; added; i++) {
                    if (i % 2 == 1) {
                        left++;
                        if (left <= maxLeft) indices.push(-left);
                        else {
                            right++;
                            if (right <= maxRight) indices.push(right);
                            else added = false;
                        }
                    }
                    else {
                        right++;
                        if (right <= maxRight) indices.push(right);
                        else {
                            left++;
                            if (left <= maxLeft) indices.push(-left);
                            else added = false;
                        }
                    }
                }
                for (i = 0; i < indices.length; i++) {
                    x.push(refx - candidatesRegion.x + indices[i] * sz + candidatesRegion.margin);
                }
                return x;
            }

            Key {
                id: currentCandidate
                objectName: "candidate_" + index

                onSelected: {
                    if (changeWordOnSelection) currentWord = text;
                }

                text: index < candidateRepeater.candidateList.length ? candidateRepeater.candidateList[index] : ""
                strikeout: candidateRepeater.inDeletion && index == 0
                gridText: ["",candidateRepeater.prevWord,"","","","","","",""]
                gridFontSize: (height - candidateFontSize) / 4
                textColor: "black"
                textSelectedColor: "white"
                gridTextColor: yellowSelectedColor
                gridSelectedTextColor: yellowUnselectedColor
                fontSize: candidateFontSize
                radiusRatio: pEyeGesture.radiusRatio
                property bool isCurrent: text === currentWord
                enabled: text.length > 0 && index < candidateRepeater.maxCandidates && (!disableCurrentCandidate || !isCurrent)
                disabledColor: disableCurrentCandidate ? "light gray" : pEyeGesture.unselectedColor
                size: candidateRepeater.candidateWidth
                width: candidateRepeater.candidateWidth
                height: pEyeGesture.height
                selectedColor: gestureSelectedColor
                unselectedColor: gestureUnselectedColor
                borderColor: menuBorderColor
                centerX: modelData
                centerY: pEyeGesture.centerY
                shouldLog: staticCandidates
                visible: staticCandidates || ((disableCurrentCandidate || enabled) && index < candidateRepeater.maxCandidates && typingManager.showCandidates && text.length > 0 && (inGesture || pEyeGesture.displayedText.length == 0))
                selectionTime: 50
            }
        }

        Repeater {
            id: cancelRepeater
            model: 2
            Key {
                id: curCancelKey
                objectName: "pEyeCancel" + index
                text: i18n("Cancel")
                enabled: (inGesture || inDeletion) && !staticCandidates
                visible: !staticCandidates
                size: keySize
                width: size
                height: size
                selectedColor: yellowSelectedColor
                unselectedColor: yellowUnselectedColor
                disabledColor: unselectedColor
                centerX: index * (pEyeGesture.width + 2 * keySpace + keySize) + halfKeySize + parent.margin
                centerY: pEyeGesture.centerY
                textSelectedColor: "white"

                onSelected: {
                    candObjs.concat(getCancelKeys()).concat([backspaceKey]).forEach(function(key) {
                        if (key !== curCancelKey) {
                            key.mouseOut(key);
                        }
                    });
                }

                onClick: {
                    typingManager.cancelGesture(tstamp);
                }
            }
        }
    }

    KBRegion {
        id: keysRegion
        objectName: "keysRegion"
        buttons: spaceKey.visible ? getKeys().concat([spaceKey, punctKey]) : getKeys().concat([punctKey])
        regionId: stateMachine.regions.keys
        property bool inPunct: false
        x: keysX0 - margin
        y: keysY0 - margin
        width: keysRegionWidth + 2 * margin
        height: keysRegionHeight + 2 * margin
        showRegion: showRegions

        onXChanged: logKeys()
        onYChanged: logKeys()
        onWidthChanged: logKeys()
        onHeightChanged: logKeys()

        function contains(point) {
            point = mapFromItem(null, point.x, point.y);
            var offX = (keyRepeater.maxX - keyRepeater.minX) * 0.1;
            var offY = (keyRepeater.maxY - keyRepeater.minY) * 0.1;
            return point.x >= keyRepeater.minX - offX && point.x <= keyRepeater.maxX + offX &&
                   point.y >= keyRepeater.minY - offY && point.y <= spaceKey.y + spaceKey.height + offY;
        }

        onHandleNewFixation: {
            inPunct = punctKey.containsPoint(fixation);
        }

        Repeater {
            id: keyRepeater
            model: [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
                       ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
                         ["z", "x", "c", "v", "b", "n", "m", "'"]]
            property int minX: -1
            property int maxX: -1
            property int minY: -1
            property int maxY: -1

            function updatePositions() {
                minX = -1;
                maxX = -1;
                minY = -1;
                maxY = -1;
                keyObjs.forEach(function(key) {
                    if (minX == -1 || key.x < minX) minX = key.x;
                    if (maxX == -1 || key.x + key.width > maxX) maxX = key.x + key.width;
                    if (minY == -1 || key.y < minY) minY = key.y;
                    if (maxY == -1 || key.y + key.height > maxY) maxY = key.y + key.height;
                });
            }

            Repeater {
                model: modelData
                property int rowIndex: index

                Key {
                    id: curKey
                    objectName: modelData.trim() + "Key"
                    size: keySize

                    property bool dim: dimInGesture
                    selectedColor: dwellKeyboard ? keySelectedColor : (showSelectionFeedback ? keySelectedColor : unselectedColor)
                    unselectedColor: dim ? "transparent" : keyUnselectedColor
                    borderColor: dim ? "transparent" : keyBorderColor
                    centerX: (1 + index + rowIndex / 2) * (size + keySpace) + size / 2 + parent.margin
                    centerY: rowIndex * (size + keySpace) + halfKeySize + parent.margin
                    text: modelData.length <= 1 ? modelData.toUpperCase() : ""
                    gridText: modelData.length >= 3 ? ["","","",modelData[0].trim().toUpperCase(),modelData[1].trim().toUpperCase(),modelData[2].trim().toUpperCase(),"","",""] : ["","","","","","","","",""]
                    clickingEnabled: dwellKeyboard
                    property bool highlight: highlightOnGaze && distanceSquareToButton(win.latestFixation) === 0
                    property bool strongHighlight: false
                    property color strongHighlightColor: Qt.rgba(255/255., 50/255., 155/255.)
                    property color highlightColor: Qt.rgba(0.5, 0.5, 0.5)
                    textColor: strongHighlight ? strongHighlightColor : (highlight ? highlightColor : "black")

                    onClick: typingManager.keystroke(curKey.text[0])

                    onXChanged: keyRepeater.updatePositions()
                    onYChanged: keyRepeater.updatePositions()
                    onWidthChanged: keyRepeater.updatePositions()
                    onHeightChanged: keyRepeater.updatePositions()
                }
            }
        }

        Key {
            id: punctKey
            objectName: "punctKey"
            size: keySize
            disabledColor: unselectedColor
            selectedColor: freePunctMode ? keySelectedColor : (greenActionColor ? gestureSelectedColor : actionSelectedColor)
            unselectedColor: freePunctMode ? keyUnselectedColor : (greenActionColor ? gestureUnselectedColor : actionUnselectedColor)
            borderColor: keyBorderColor
            centerX: parent.width - halfKeySize - parent.margin
            centerY: (freePunctMode || isExperiment) ? 2 * (size + keySpace) + halfKeySize + parent.margin : spaceKey.centerY
            gridText: ["",".","","?","",",","","!",""]
            enabled: freePunctMode ? punctMode : typingManager.onTypingMode
            text: ""
            gridSelectedTextColor: freePunctMode ? gridTextColor : "white"

            property var punctMarks: [".", ",", "?", "!"]
            property double latestSelection: -1
            property bool selectedRecently: curTstamp - latestSelection < 1000

            onSelected: {
                latestSelection = curTstamp;
            }
        }

        Key {
            id: spaceKey
            objectName: "spaceKey"
            size: keySize
            width: size
            height: size
            selectionTime: 0
            property bool dim: inGesture
            selectedColor: dwellKeyboard ? keySelectedColor : (showSelectionFeedback ? keySelectedColor : unselectedColor)
            unselectedColor: dim ? "transparent" : keyUnselectedColor
            borderColor: dim ? "transparent" : keyBorderColor
            centerX: win.width / 2 - parent.x
            centerY: parent.height - halfKeySize - parent.margin + (visible ? 0 : keySize + keySpace)
            text: "___"
            textSelectedColor: "white"
            clickingEnabled: dwellKeyboard
            visible: !isExperiment
            sensitiveDist: halfKeySize

            onClick: {
                textField.addSpace();
            }
        }
    }

    Key {
        id: modeKey
        objectName: "modeKey"
        width: backspaceKey.width
        height: backspaceKey.height
        centerX: keysX0 + halfKeySize
        centerY: spaceKey.centerY
        selectedColor: keySelectedColor
        unselectedColor: keyUnselectedColor
        borderColor: keyBorderColor
        text: modeName(isGesture)
        textSelectedColor: "white"
        visible: false //!dwellKeyboard && !isExperiment
        property bool isGesture: true
        clickingEnabled: true
        dwellTime: 1000

        function modeName(isGesture) {
            return isGesture ? i18n("Continuous") : i18n("Single")
        }

        onClick: modeKey.isGesture = !modeKey.isGesture
    }

    onInGestureChanged: {
        if (!inGesture && !disableCurrentCandidate) {
            candObjs.forEach(function(button) {
                button.enabled = true;
            });
        }
    }
}
