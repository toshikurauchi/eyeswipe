import QtQuick 2.0
import QtGraphicalEffects 1.0
import "tutorial.js" as Tutorial

Tutorial {
    id: tutorial
    lessons: [
        howToTypeWordI,
        typeWordI,
        howToDeleteChar,
        deleteChar,
        howToAddPunct,
        addPunct,
        typeSentence
    ]
    property var howToTypeWordI: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeWordI: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToDeleteChar: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var deleteChar: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToAddPunct: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var addPunct: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeSentence: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);

    function initLessons() {
        initHowToTypeWordI();
        initTypeWordI();
        initHowToDeleteChar();
        initDeleteChar();
        initHowToAddPunct();
        initAddPunct();
        initTypeSentence();
    }

    function initHowToTypeWordI() {
        var iKey = findKey("iKey");
        var lesson = howToTypeWordI;
        lesson.addStep(new Tutorial.Step({text: "Let's try typing the word \"I\""}));
        lesson.addStep(new Tutorial.Step({text: "Just look at the \"i\" key",
                                          pointTo: iKey,
                                          select: iKey}));
        lesson.addStep(new Tutorial.Step({text: "... and wait until you hear a click"}));
        lesson.addStep(new Tutorial.Step({click: iKey}));
        lesson.addStep(new Tutorial.Step({text: "The typed key will appear in the text box",
                                          textFieldPointerOffset: 0,
                                          addChar: "i".charCodeAt(0)}));
    }

    function initTypeWordI() {
        var lesson = typeWordI;
        lesson.addStep(new Tutorial.Step({text: "Try typing the \"i\" key"}));
        lesson.addStep(new Tutorial.Step({sentence: "Type the \"i\" key",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onCharAdded: function (c) {
            if (c === "i") {
                instructions.text = "Congratulations, you typed your first key!"
                resumeTutorial();
                return true;
            }
            return false;
        }}));
        lesson.addStep(new Tutorial.Step({text: "Spaces are added in the same way: just keep looking at the space bar until you hear the click"}));
    }

    function initHowToDeleteChar() {
        var lesson = howToDeleteChar;
        lesson.addStep(new Tutorial.Step({text: "To delete a character just look at the \"" + backspaceKey.text + "\" key",
                                          addChar: "a".charCodeAt(0),
                                          pointTo: backspaceKey,
                                          select: backspaceKey}));
        lesson.addStep(new Tutorial.Step({text: "... until you hear the click"}));
        lesson.addStep(new Tutorial.Step({click: backspaceKey}));
    }

    function initDeleteChar() {
        var lesson = deleteChar;
        lesson.addStep(new Tutorial.Step({text: "Try deleting a character",
                                          addChar: "a".charCodeAt(0)}));
        lesson.addStep(new Tutorial.Step({sentence: "Delete a character",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onCharDeleted: function () {
            instructions.text = "Congratulations!"
            resumeTutorial();
            return true;
        }}));
    }

    function initHowToAddPunct() {
        var lesson = howToAddPunct;
        lesson.addStep(new Tutorial.Step({text: "To add a punctuation mark look at the punctuation key (\"" + punctKey.text + "\")",
                                          pointTo: punctKey,
                                          select: punctKey}));
        lesson.addStep(new Tutorial.Step({text: "A menu will pop up with the possible punctuation marks"}));
        lesson.addStep(new Tutorial.Step({text: "Just look at the desired punctuation mark",
                                          pointTo: pEyeQuestion,
                                          select: pEyeQuestion}));
        lesson.addStep(new Tutorial.Step({text: "... and wait until you hear the click"}));
        lesson.addStep(new Tutorial.Step({click: pEyeQuestion}));
    }

    function initAddPunct() {
        var lesson = addPunct;
        lesson.addStep(new Tutorial.Step({text: "Try adding a \"!\""}));
        lesson.addStep(new Tutorial.Step({sentence: "Add a \"!\"",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onCharAdded: function (c) {
            if (c === "!") {
                instructions.text = "Congratulations!"
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initTypeSentence() {
        var sentence = "I'm ready to go!";
        var lesson = typeSentence;
        lesson.addStep(new Tutorial.Step({text: "Try typing: \"" + sentence + "\""}));
        lesson.addStep(new Tutorial.Step({sentence: sentence,
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onCharAdded: function (c) {
            textField.updateUI();
            if (textField.typedText === sentence) {
                instructions.text = "Congratulations!";
                sentenceToType.text = "";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }
}
