import QtQuick 2.0
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import "TextFieldToken.js" as TFT

Rectangle {
    id: textField
    property color wordSelectionColor: "light gray"
    property string typedText: ""
    property double maxFontSize: 20
    property double fontSize: Math.min(sentenceToType.length == 0 ? height * 0.8 : height * 0.35, maxFontSize)
    property var punctuation: ['.', ',', '?', '!']
    property var tokens: []
    property double t0: new Date().valueOf()
    property double wpm: 0
    property double fontScale: sentenceToTypeText.paintedWidth > width * 0.9 ? (width * 0.9 / sentenceToTypeText.paintedWidth) : 1
    property double textXOffset: input.x
    property double highestWPM: 0
    property bool showCandidates: true
    property bool lockToken: false
    property bool charByChar: false
    property string sentenceToType: ""
    property var capitalizedWords: ["John", "Brindle", "Florida", "Dynegy", "Chris", "Foster", "Ava", "Houston", "Mary", "Becky", "Duran", "Greg", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "Mike", "Disney", "Jay", "Portland", "Travis", "ENE", "OK", "Stan", "TK", "Natalie"]
    border.color: "black"
    height: fontSize * 1.5

    onShowCandidatesChanged: updateCandidates()

    onTypedTextChanged: {
        input.fixTextSize()

        // Update wpm
        if (typedText.length === 0) {
            t0 = new Date().valueOf();
        }
        var dt = (new Date().valueOf() - t0) / 60000;
        wpm = typedText.length / (5 * dt);
        if (wpm > highestWPM) highestWPM = wpm;
    }

    Text {
        id: sentenceToTypeText
        text: sentenceToType
        x: input.x
        y: 0.1 * textField.height
        font.pixelSize: fontSize * fontScale
    }

    TextInput {
        id: input
        x: parent.width * 0.01
        y: sentenceToType.length == 0 ? (textField.height - height) / 2 : 0.9 * textField.height - height
        enabled: false
        width: parent.width * 0.98
        font.pixelSize: fontSize * fontScale
        selectionColor: wordSelectionColor
        cursorVisible: true

        onWidthChanged: fixTextSize()
        onHeightChanged: fixTextSize()
        onFontChanged: fixTextSize()

        function fixTextSize() {
            text = typedText;
            for (var i = 0; contentWidth > width && i < typedText.length; i++) {
                text = typedText.substring(i);
            }
        }
    }

    signal newWord(string word)
    signal wordDeleted(string word)
    signal punctAdded(string addedPunct)
    signal spaceAdded();
    signal charAdded(string addedChar);
    signal charDeleted();
    signal candidateChanged(string newCandidate);

    function addPunct(punct) {
        if (lockToken) return;
        charAdded(punct);
        if (charByChar) {
            addChar(punct);
            punctAdded(punct);
            return;
        }

        if (tokens.length == 0 || !tokens[tokens.length - 1].isPunct) {
            verifyNewWord();
            tokens.push(new TFT.Token([punct.trim()], false, 0, true));
        }
        else {
            var token = tokens[tokens.length - 1];
            token.word += punct.trim();
        }
        updateUI();
        punctAdded(punct);
    }

    function addChar(newChar) {
        if (lockToken) return;
        if (tokens.length == 0 || !tokens[tokens.length - 1].charByChar) {
            tokens.push(new TFT.Token([""], true, 0, false, true));
        }
        tokens[tokens.length - 1].word += newChar;
        updateUI();
        charAdded(newChar);
    }

    function addSingleLetter(letter) {
        if (lockToken) return;
        charAdded(letter);
        if (charByChar) {
            addChar(letter);
            return;
        }

        if (tokens.length == 0 || !tokens[tokens.length - 1].isEditing) {
            verifyNewWord();
            tokens.push(new TFT.Token([letter], true));
        }
        else {
            var token = tokens[tokens.length - 1];
            token.word += letter;
        }
        updateUI();
    }

    function changeCandidate(newCandidate) {
        var changed = true;
        if (tokens.length == 0) {
            addWordCandidates([newCandidate]);
        }
        else {
            var token = tokens[tokens.length - 1];
            if (newCandidate === token.word) {
                changed = false;
            }
            else {
                wordDeleted(token.word);
                token.changeCandidate(newCandidate);
                newWord(newCandidate);
            }
        }
        if (changed) {
            updateUI();
            candidateChanged(newCandidate);
        }
    }

    function addSpace() {
        if (lockToken) return;
        spaceAdded();
        if (charByChar) {
            addChar(" ");
            return;
        }

        if (tokens.length == 0) {
            tokens.push(new TFT.Token([""], false, 1));
        }
        else {
            var token = tokens[tokens.length - 1];
            if (token.isEditing) {
                verifyNewWord();
            }
            else {
                token.addExtraSpace();
            }
        }
        updateTypedText();
    }

    function addWordCandidates(words, idx) {
        idx = typeof idx !== 'undefined' ?  idx : 0;
        if ('.,!?'.indexOf(words[idx]) >= 0) {
            addPunct(words[idx]);
            return;
        }

        if (lockToken) return;
        verifyNewWord();
        tokens.push(new TFT.Token(words));
        tokens[tokens.length - 1].changeCandidate(words[idx]);
        updateUI();
        newWord(words[idx]);
    }

    function deleteWord() {
        if (lockToken) return;
        if (tokens.length == 0) return;
        var token = tokens[tokens.length - 1];
        var tokensToAdd = [];
        if (token.word.length > 0) {
            if (token.isPunct) {
                wordDeleted("");
            }
            else {
                if (token.word.indexOf(" ") >= 0) {
                    tokensToAdd = token.word.split(" ");
                    tokensToAdd = tokensToAdd.slice(0, tokensToAdd.length - 1);
                }
                wordDeleted(token.word);
            }
        }
        removeLastToken();
        updateUI();
        for (var i = 0; i < tokensToAdd.length; i++) addWordCandidates([tokensToAdd[i]]);
    }

    function deleteChar() {
        if (lockToken) return;
        if (tokens.length == 0) return;
        charDeleted();
        var token = tokens[tokens.length - 1];
        if (!token.removeExtraSpace()) {
            if (!token.isEditing) wordDeleted(token.word);
            token.removeLastChar();
        }
        if (token.isEmpty()) {
            removeLastToken();
        }
        updateUI();
    }

    function updateUI() {
        updateTypedText();
        updateCandidates();
    }

    function capitalizeIfNeeded(word, capitalize) {
        /*
        for (var i = 0; i < capitalizedWords.length; i++) {
            if (word === capitalizedWords[i].toLowerCase()) return capitalizedWords[i];
        }*/
        if (capitalize)/* ||
            (word.charAt(0) === 'i' &&
             (word.length === 1 || word.charAt(1) === '\''))) */{
            return word.charAt(0).toUpperCase() + word.slice(1);
        }
        return word;
    }

    function updateTypedText() {
        var text = "";
        var isFirst = true;
        var capitalize = true;
        tokens.forEach(function(token) {
            var word = /*token.word;*/capitalizeIfNeeded(token.word, capitalize);
            if (isFirst) {
                capitalize = false;
                isFirst = false;
            }
            else if (token.isPunct) capitalize = token.word !== ",";
            else {
                capitalize = false;
                text += ' ';
            }
            text += word;
            for (var i = 0; i < token.extraSpaces; i++) text += ' ';
        });
        typedText = text;
    }

    function updateCandidates() {
        var candidates = [];
        if (tokens.length > 0) candidates = tokens[tokens.length - 1].candidates;
        typingManager.candidates = candidates;
        if (showCandidates && tokens[tokens.length - 1] && !disableCurrentCandidate) {
            for (var i = 0; i < candidateRepeater.model.length; i++) {
                var candidateButton = candidateRepeater.itemAt(i);
                candidateButton.enabled = true;
            }
        }
    }

    function verifyNewWord() {
        if (tokens.length == 0) return;
        var token = tokens[tokens.length - 1];
        if (token.isEditing) {
            token.isEditing = false;
            newWord(token.word);
        }
    }

    function removeLastToken() {
        if (tokens.length == 0) return;
        tokens = tokens.slice(0, tokens.length - 1);
    }

    function getLastToken() {
        if (tokens.length == 0) return null;
        return tokens[tokens.length - 1];
    }

    function clear() {
        tokens = [];
        updateUI();
    }

    function lastCandidates(includeSelected) {
        var last = getLastToken();
        if (last === null) return [];
        var candidates = [];
        last.candidates.forEach(function(candidate) {
            if (includeSelected || candidate !== last.word) candidates.push(candidate);
        });
        return candidates;
    }
}
