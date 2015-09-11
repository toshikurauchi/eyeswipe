import QtQuick 2.0
import QtGraphicalEffects 1.0
import "tutorial.js" as Tutorial

Tutorial {
    id: tutorial
    lessons: [
        howToTypeWordGovernment,
        typeWordGovernment,
        //howToTypeWordI,
        //typeWordI,
        howToChangeCandidates,
        changeCandidates,
        typeSomeWords,
        howToCancelAGesture,
        //cancelAGesture,
        howToDeleteWord,
        //deleteAWord,
        //typeWordIm,
        typeSentence,
        howToAddPunctuation,
        addPunctuation,
        typeSomeSentences,
        congratulations
    ]
    property var howToTypeWordI: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToCancelAGesture: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var cancelAGesture: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToDeleteWord: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var deleteAWord: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeWordI: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToTypeWordGovernment: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeWordGovernment: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeWordIm: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToChangeCandidates: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var changeCandidates: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeSentence: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeSomeWords: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var howToAddPunctuation: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var addPunctuation: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var typeSomeSentences: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);
    property var congratulations: new Tutorial.Lesson(instructions, gazeTimer, pEyeGesture, textField, sentenceToType);

    function findCandidateKey(idx) {
        var key;
        if (idx < win.candObjs.length) key = win.candObjs[idx];
        return key;
    }

    function initLessons() {
        initHowToTypeWordI();
        initHowToCancelAGesture();
        initCancelAGesture();
        initHowToDeleteWord();
        initDeleteAWord();
        initTypeWordI();
        initHowToTypeWordGovernment();
        initTypeWordGovernment();
        initTypeWordIm();
        initHowToChangeCandidates();
        initChangeCandidates();
        initTypeSentence();
        initTypeSomeWords();
        initHowToAddPunctuation();
        initAddPunctuation();
        initTypeSomeSentences();
        initCongratulations();
    }

    function initHowToTypeWordI() {
        var iKey = findKey("iKey");
        var lesson = howToTypeWordI;
        lesson.addStep(new Tutorial.Step({text: "Let's try typing the word \"I\""}));
        //lesson.addStep(new Tutorial.Step({text: "This keyboard is based on words instead of single letters"}));
        lesson.addStep(new Tutorial.Step({text: "Every time you want to type a word you have to indicate where its first letter is"}));
        lesson.addStep(new Tutorial.Step({text: "You can do that by just looking at it",
                                          pointTo: iKey,
                                          select: iKey}));
        lesson.addStep(new Tutorial.Step({text: "When you look at a key the keyboard will show you the possible actions"}));
        lesson.addStep(new Tutorial.Step({text: "In this case we want to indicate that the word starts with an \"i\""}));
        lesson.addStep(new Tutorial.Step({text: "When you look at the \"Start\" button its color will change"}));
        lesson.addStep(new Tutorial.Step({pointTo: pEyeGesture,
                                          select: pEyeGesture}));
        lesson.addStep(new Tutorial.Step({text: "To select this option just look back at the \"i\" key"}));
        lesson.addStep(new Tutorial.Step({pointTo: iKey,
                                          click: pEyeGesture}));
        lesson.addStep(new Tutorial.Step({text: "Now we have to indicate that the word also ends with the letter \"i\""}));
        lesson.addStep(new Tutorial.Step({text: "If you keep looking at the \"i\" key the keyboard will show you the new set of possible actions"}));
        lesson.addStep(new Tutorial.Step({select: iKey,
                                          pEyeGestureText: "i"}));
        lesson.addStep(new Tutorial.Step({text: "The button shows the word \"I\", which is the one we want to type"}));
        lesson.addStep(new Tutorial.Step({text: "Once again, if you look at the button with the word \"I\" both the original key and the button will change their colors"}));
        lesson.addStep(new Tutorial.Step({pointTo: pEyeGesture,
                                          select: pEyeGesture}));
        lesson.addStep(new Tutorial.Step({text: "To type the word \"I\" look back at the \"i\" key"}));
        lesson.addStep(new Tutorial.Step({pointTo: iKey,
                                          click: pEyeGesture}));
        lesson.addStep(new Tutorial.Step({text: "The typed word will appear in the text field",
                                          addCandidates: ["i"],
                                          textFieldPointerOffset: 0}));
    }

    function initHowToCancelAGesture() {
        var lesson = howToCancelAGesture;
        lesson.addStep(new Tutorial.Step({text: "Suppose you selected the wrong first letter"}));
        lesson.addStep(new Tutorial.Step({func: function() {animateSelection(findKey("oKey"))}}));
        lesson.addStep(new Tutorial.Step({text: "You can cancel this last selection by looking at the " + backspaceKey.text + " key"}));
        lesson.addStep(new Tutorial.Step({pointTo: backspaceKey,
                                          select: backspaceKey}));
    }

    function initCancelAGesture() {
        var lesson = cancelAGesture;
        lesson.addStep(new Tutorial.Step({text: "Try canceling a wrong first letter"}));
        lesson.addStep(new Tutorial.Step({text: "First, select any letter as the first one"}));
        lesson.addStep(new Tutorial.Step({sentence: "Select any letter",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onGestureToggled: function () {
            if (!pEyeGesture.isStart) {
                instructions.text = "Now try canceling the current path";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
        lesson.addStep(new Tutorial.Step({sentence: "Cancel the current path",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onGestureCanceled: function (){
            instructions.text = "Congratulations! You successfully canceled a word!"
            resumeTutorial();
            return true;
        }}));
    }

    function initHowToDeleteWord() {
        var lesson = howToDeleteWord;
        lesson.addStep(new Tutorial.Step({text: "What if the wrong word is typed?"}));
        lesson.addStep(new Tutorial.Step({addCandidates: ["oops"],
                                          textFieldPointerOffset: 2 * textField.height / 2}));
        lesson.addStep(new Tutorial.Step({text: "Use the " + backspaceKey.text + " key to delete the last typed word",
                                          poinTo: backspaceKey,
                                          select: backspaceKey}));
        lesson.addStep(new Tutorial.Step({text: "... and then looking back at the original key",
                                          pointTo: backspaceKey}));
        lesson.addStep(new Tutorial.Step({text: "The last typed key will then be deleted",
                                          textFieldPointerOffset: 2 * textField.height / 2,
                                          func: function () {
                                              backspacePEyeMenu.hide();
                                              textField.deleteWord();
                                          }}));
    }

    function initDeleteAWord() {
        var lesson = deleteAWord;
        lesson.addStep(new Tutorial.Step({text: "Try deleting the word \"oops\"",
                                          addCandidates: ["oops"]}));
        lesson.addStep(new Tutorial.Step({sentence: "Delete the word \"oops\"",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onWordDeleted: function (word) {
            if (word === "oops") {
                instructions.text = "Congratulations! Now let's try typing a word!";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initTypeWordI() {
        var lesson = typeWordI;
        lesson.addStep(new Tutorial.Step({text: "Try typing the word \"I\""}));
        lesson.addStep(new Tutorial.Step({sentence: "Type the word \"I\" (don't worry about capitalizing it)",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onNewWord: function (word) {
            if (word === "i") {
                instructions.text = "Congratulations! You have typed your first word!";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initHowToTypeWordGovernment() {
        var gKey = findKey("gKey");
        var tKey = findKey("tKey");
        var lesson = howToTypeWordGovernment;
        lesson.addStep(new Tutorial.Step({text: "Let's try typing the word \"government\"",
                                          func: function () {
                                              textField.clear();
                                              instructionsRectangle.y = gKey.y + 1.5 * gKey.height;
                                          }}));
        lesson.addStep(new Tutorial.Step({text: "We first select the first letter (\"G\") by looking at it",
                                          pointTo: gKey,
                                          select: gKey}));
        lesson.addStep(new Tutorial.Step({text: "... looking at the \"Start\" button",
                                          pointTo: pEyeGesture,
                                          select: pEyeGesture}));
        lesson.addStep(new Tutorial.Step({text: "... and back at the \"G\" key, the first letter is selected",
                                          pointTo: gKey,
                                          click: pEyeGesture,
                                          func: function() {canvas.points = [Qt.point(gKey.centerX, gKey.centerY)]}}));
        lesson.addStep(new Tutorial.Step({text: "Then you just have to look at the letters of the word sequentially",
                                          func: function () {showGesture("government")}}));
        lesson.addStep(new Tutorial.Step({text: "Finally we select the last letter (\"T\") by looking at it",
                                          pointTo: tKey,
                                          select: tKey,
                                          pEyeGestureText: "government",
                                          func: function () {canvas.points = canvas.points.concat([Qt.point(tKey.centerX, tKey.centerY)])}}));
        lesson.addStep(new Tutorial.Step({text: "... looking at the word to be typed (\"government\")",
                                          pointTo: pEyeGesture,
                                          select: pEyeGesture,
                                          func: function () {}}));
        lesson.addStep(new Tutorial.Step({text: "... and finally back at the \"T\" key"}));
        lesson.addStep(new Tutorial.Step({pointTo: tKey,
                                          click: pEyeGesture,
                                          func: function () {canvas.points = []}}));
        lesson.addStep(new Tutorial.Step({text: "The typed word will appear in the text box",
                                          addCandidates: ["government"],
                                          textFieldPointerOffset: textField.height / 2}));
        lesson.addStep(new Tutorial.Step({text: "The keyboard uses the gaze path to predict the word to be typed"}));
        lesson.addStep(new Tutorial.Step({text: "For this reason after the selection of the first letter, you don't have to wait when typing the middle of the word"}));
        lesson.addStep(new Tutorial.Step({text: "As long as you looked at a key you can move on to the next key until the last letter. Then you can select the last letter"}));
        lesson.addStep(new Tutorial.Step({func: showRealGesture}));
    }

    function initTypeWordGovernment() {
        var lesson = typeWordGovernment;
        lesson.addStep(new Tutorial.Step({text: "Try typing the word \"government\""}));
        lesson.addStep(new Tutorial.Step({sentence: "Type the word \"government\"",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onNewWord: function (word) {
            if (word === "government") {
                instructions.text = "Congratulations!";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initTypeWordIm() {
        var apostropheKey = findKey("'Key");
        var lesson = typeWordIm;
        lesson.addStep(new Tutorial.Step({text: "When using apostrophe treat it as a single word",
                                          pointTo: apostropheKey}));
        lesson.addStep(new Tutorial.Step({text: "Try typing \"I'm\""}));
        lesson.addStep(new Tutorial.Step({sentence: "Type the word \"I'm\"",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onNewWord: function (word) {
            if (word === "i'm") {
                instructions.text = "Congratulations!";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initHowToChangeCandidates() {
        var candidate1 = findCandidateKey(1);
        var candidate2 = findCandidateKey(2);
        var lesson = howToChangeCandidates;
        lesson.addStep(new Tutorial.Step({text: "The keyboard may eventually make mistakes when predicting the typed word"}));
        lesson.addStep(new Tutorial.Step({text: "For this reason, other possible candidates are displayed below the text box",
                                          addCandidates: ["to", "too", "trio", "treo", "two"]}));
        lesson.addStep(new Tutorial.Step({text: "If the correct candidate is, for example, the word \"too\" you can just look at it",
                                          pointTo: candidate1,
                                          select: candidate1}));
        lesson.addStep(new Tutorial.Step({text: "... and choose the \"" + pEyeSelectCandidate.text + "\" action by looking at it",
                                          pointTo: pEyeSelectCandidate,
                                          select: pEyeSelectCandidate}));
        lesson.addStep(new Tutorial.Step({text: "... and back at the candidate",
                                          pointTo: candidate1,
                                          click: pEyeSelectCandidate}));
    }

    function initChangeCandidates() {
        var lesson = changeCandidates;
        lesson.addStep(new Tutorial.Step({sentence: "Type the word \"too\"",
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onNewWord: function (word) {
            if (word === "too") {
                instructions.text = "Congratulations!";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initTypeSentence() {
        var sentence = "Computers are good at following instructions";

        function checkTypedText(ignoreArg) {
            textField.updateUI();
            if (textField.typedText.toLowerCase() === sentence.toLowerCase()) {
                instructions.text = "Congratulations!";
                resumeTutorial();
                return true;
            }
            return false;
        }

        var lesson = typeSentence;
        lesson.addStep(new Tutorial.Step({text: "When typing sentences you don't have to worry about adding the spaces"}));
        lesson.addStep(new Tutorial.Step({text: "Just keep typing the words and the keyboard automatically adds the spaces between them!"}));
        lesson.addStep(new Tutorial.Step({text: "Try typing: \"" + sentence + "\""}));
        lesson.addStep(new Tutorial.Step({sentence: sentence,
                                          func: giveUserControl}));
        lesson.addStep(new Tutorial.Step({onNewWord: checkTypedText,
                                          onWordDeleted: checkTypedText}));
    }

    function initTypeSomeWords() {
        function makeCompareWord(expected) {
            return function(word) {
                if (word === expected) {
                    instructions.text = "Congratulations!";
                    textField.clear();
                    resumeTutorial();
                    return true;
                }
                return false;
            }
        }

        var lesson = typeSomeWords;
        var words = ["victory", "awesome", "passion"];

        lesson.addStep(new Tutorial.Step({text: "Let's try typing some more words"}));
        for (var i = 0; i < words.length; i++) {
            lesson.addStep(new Tutorial.Step({text: "Try typing the word \"" + words[i] + "\""}));
            lesson.addStep(new Tutorial.Step({sentence: "Type the word \"" + words[i] + "\"",
                                              func: giveUserControl}));
            lesson.addStep(new Tutorial.Step({onNewWord: makeCompareWord(words[i])}));
        }
    }

    function initHowToAddPunctuation() {
        var lesson = howToAddPunctuation;
        lesson.addStep(new Tutorial.Step({text: "The last thing you have to learn is how to add punctuation"}));
        lesson.addStep(new Tutorial.Step({text: "Just look at the punctuation key (\"" + punctKey.text + "\" key)",
                                          pointTo: punctKey,
                                          select: punctKey}));
        lesson.addStep(new Tutorial.Step({text: "... and select the punctuation mark you want by looking at it",
                                          pointTo: pEyeExclamation,
                                          select: pEyeExclamation}));
        lesson.addStep(new Tutorial.Step({text: "... and looking back at the punctuation key",
                                          pointTo: punctKey,
                                          click: pEyeExclamation}));
    }

    function initAddPunctuation() {
        var lesson = addPunctuation;
        lesson.addStep(new Tutorial.Step({text: "Try adding a \"?\""}));
        lesson.addStep(new Tutorial.Step({sentence: "Add a \"?\"",
                                          func: function () {
            textField.addWordCandidates(["are"]);
            textField.addWordCandidates(["we"]);
            textField.addWordCandidates(["done"]);
            giveUserControl();
        }}));
        lesson.addStep(new Tutorial.Step({onCharAdded: function (c) {
            if (c === "?") {
                instructions.text = "Congratulations!";
                sentenceToType = "";
                resumeTutorial();
                return true;
            }
            return false;
        }}));
    }

    function initTypeSomeSentences() {
        function makeCompareSentence(expected) {
            return function(ignoreArg) {
                textField.updateUI();
                if (textField.typedText.toLowerCase() === expected.toLowerCase()) {
                    instructions.text = "Congratulations!";
                    resumeTutorial();
                    return true;
                }
                return false;
            }
        }

        var lesson = typeSomeSentences;
        var sentences = ["I am typing with my gaze.",
                         "Keep calm and love programming.",
                         "Computer science department at boston university."];

        lesson.addStep(new Tutorial.Step({text: "Let's try typing some more sentences"}));
        for (var i = 0; i < sentences.length; i++) {
            lesson.addStep(new Tutorial.Step({text: "Try typing: \"" + sentences[i] + "\"",
                                              func: function () {textField.clear()}}));
            lesson.addStep(new Tutorial.Step({sentence: sentences[i],
                                              func: giveUserControl}));
            lesson.addStep(new Tutorial.Step({onCharAdded: makeCompareSentence(sentences[i].substring(0,sentences[i].length - 1))}));
        }
    }

    function initCongratulations() {
        var lesson = congratulations;
        lesson.addStep(new Tutorial.Step({text: "This concludes our tutorial!"}));
    }

    function showGesture(word) {
        lockStep = true;
        pointer.visible = true;
        gestureAnimation.text = word;
        gestureAnimation.start();
    }

    Timer {
        id: gestureAnimation
        interval: 30
        repeat: true
        property string text: ""
        property double t0: -1
        property double movingTime: 300

        onRunningChanged: lockStep = running

        onTriggered: {
            if (text.length <= 1) {
                nextStep();
                stop();
                gazeTimer.oscilating = true;
                t0 = -1;
                return;
            }
            if (t0 == -1) t0 = new Date().valueOf();
            var dt = new Date().valueOf() - t0;
            var alpha = dt / movingTime;
            if (alpha > 1) alpha = 1;
            var c = text[0];
            var c1 = text[1];
            var key = findKey(c + "Key");
            var nextKey = findKey(c1 + "Key");
            gazeTimer.oscilating = false;
            var x = (1 - alpha) * key.centerX + alpha * nextKey.centerX;
            var y = (1 - alpha) * key.centerY + alpha * nextKey.centerY;
            gazeTimer.moveTo(x, y);
            canvas.points = canvas.points.concat([Qt.point(x, y)]);
            if (alpha >= 1) {
                t0 = -1;
                text = text.substring(1);
            }
        }
    }

    function showRealGesture() {
        lockStep = true;
        pointer.visible = true;
        gazeTimer.oscilating = false;
        realGestureAnimation.start();
    }

    Timer {
        id: realGestureAnimation
        property point qKey: Qt.point(106.528, 489.843)
        property point mKey: Qt.point(911.213, 721.788)
        property point qKeyToMKeyDist: Qt.point(mKey.x - qKey.x, mKey.y - qKey.y)
        property int curFrame: 0
        property double t0: new Date().valueOf()
        property var events: null;
        property bool showCandidate: false
        interval: 15
        repeat: true

        onRunningChanged: {
            if (running) t0 = new Date().valueOf();
            lockStep = running;
        }

        function applyEventsIfNeeded(tstamp, dt) {
            for (var i = 0; i < events.length; i++) {
                var event = events[i];
                if (event["done"]) continue;
                if (event["tstamp"] - data[0][0] <= dt) {
                    var key = event["key"];
                    if (event["type"] === "sel") {
                        key.selected(key);
                        if (showCandidate) pEyeGesture.text = "government";
                    }
                    else {
                        key.click(key, tstamp, true);
                        showCandidate = true;
                    }
                    event["done"] = true;
                }
            }
        }

        onTriggered: {
            var curQ = findKey("qKey");
            var curM = findKey("mKey");
            var curG = findKey("gKey");
            var curT = findKey("tKey");

            if (!events) {
                events = [
                    {key: curG, tstamp: 77064, type: "sel", done: false},
                    {key: pEyeGesture, tstamp: 77464, type: "sel", done: false},
                    {key: pEyeGesture, tstamp: 78001, type: "click", done: false},
                    {key: curT, tstamp: 81485, type: "sel", done: false},
                    {key: pEyeGesture, tstamp: 81848, type: "sel", done: false},
                    {key: pEyeGesture, tstamp: 82296, type: "click", done: false}
                ];
            }

            var dt = new Date().valueOf() - t0;
            if (data.length == 0 || dt >= data[data.length - 1][0] - data[0][0]) {
                if (data.length > 0)
                    applyEventsIfNeeded(data[data.length - 1][0], dt)

                nextStep();
                stop();
                gazeTimer.oscilating = true;
                curFrame = 0;
                return;
            }
            var curMQDist = Qt.point(curM.centerX - curQ.centerX, curM.centerY - curQ.centerY);
            var xScale = qKeyToMKeyDist.x / curMQDist.x;
            var yScale = qKeyToMKeyDist.y / curMQDist.y;

            var tstamp = data[curFrame][0];
            var prevFrame = curFrame;
            while (curFrame + 1 < data.length) {
                if (data[curFrame + 1][0] - data[0][0] <= dt) {
                    tstamp = data[curFrame + 1][0];
                    curFrame++;
                }
                else break;
            }
            var x = (data[curFrame][1] - qKey.x) * xScale + curQ.centerX;
            var y = (data[curFrame][2] - qKey.y) * yScale + curQ.centerY;
            gazeTimer.moveTo(x, y);
            while (prevFrame < curFrame) {
                canvas.points = canvas.points.concat([Qt.point(data[prevFrame][1], data[prevFrame][2])]);
                prevFrame++;
            }
            applyEventsIfNeeded(tstamp, dt);
        }

        property var data: [
            [77055,623.826,600.291],
            [77101,627.829,599.95],
            [77132,631.595,599.615],
            [77145,632.203,600.064],
            [77174,629.227,601.269],
            [77189,628.02,603.383],
            [77218,623.863,600.545],
            [77264,622.012,593.675],
            [77280,623.693,593.438],
            [77309,624.077,591.25],
            [77324,624.834,582.638],
            [77354,622.07,557.005],
            [77370,618.812,531.108],
            [77401,612.415,488.869],
            [77416,609.017,467.682],
            [77431,605.876,450.845],
            [77446,605.679,449.395],
            [77460,608.14,453.433],
            [77489,612.832,455.455],
            [77506,616.463,461.976],
            [77552,615.373,466.219],
            [77580,614.319,466.972],
            [77596,613.969,466.892],
            [77624,612.804,465.974],
            [77639,611.807,465.314],
            [77669,612.118,462.241],
            [77714,614.866,457.147],
            [77730,614.662,458.59],
            [77759,613.672,459.337],
            [77774,612.564,460.281],
            [77806,611.381,461.666],
            [77823,609.462,465.891],
            [77851,620.687,492.258],
            [77867,636.075,530.076],
            [77896,653.923,569.537],
            [77910,652.461,582.667],
            [77939,643.654,580.414],
            [77954,633.715,573.868],
            [78001,627.354,574.905],
            [78029,622.351,582.686],
            [78046,621.18,583.591],
            [78074,622.167,585.041],
            [78089,623.73,584.458],
            [78126,624.294,588.4],
            [78181,623.092,593.264],
            [78191,623.891,592.956],
            [78220,626.593,590.309],
            [78235,628.135,587.437],
            [78259,628.625,587.131],
            [78274,627.154,590.542],
            [78309,627.138,594.377],
            [78325,627.67,595.715],
            [78344,627.93,593.381],
            [78363,628.091,590.528],
            [78401,630.494,585.581],
            [78453,844.056,524.39],
            [78484,904.154,512.379],
            [78497,932.766,507.369],
            [78526,983.288,497.633],
            [78548,995.507,495.728],
            [78571,994.294,496.103],
            [78621,992.265,497.977],
            [78635,992.721,498.336],
            [78668,994.991,499.986],
            [78677,997.526,502.087],
            [78713,1000.18,504.91],
            [78725,1000.26,504.481],
            [78760,999.558,503.368],
            [78771,996.226,502.296],
            [78802,899.491,551.948],
            [78815,775.252,615.827],
            [78843,651.514,680.433],
            [78860,618.333,696.675],
            [78907,598.995,702.836],
            [78934,587.516,704.939],
            [78958,585.73,704.225],
            [78978,582.361,707.265],
            [78999,578.176,710.648],
            [79032,567.466,723.851],
            [79075,557.791,733.936],
            [79089,550.367,734.113],
            [79122,543.132,728.852],
            [79132,534.961,723.133],
            [79164,533.348,716.567],
            [79176,536.016,714.359],
            [79212,530.838,705.674],
            [79222,512.534,687.453],
            [79250,479.576,647.602],
            [79266,441.419,596.187],
            [79294,404.1,541.22],
            [79310,385.196,511.542],
            [79358,372.349,488.716],
            [79384,364.233,473.967],
            [79429,366.375,480.105],
            [79448,367.28,486.671],
            [79473,366.599,487.516],
            [79525,362.585,474.051],
            [79540,362.604,474.109],
            [79567,414.625,491.353],
            [79583,501.599,520.191],
            [79610,610.32,557.936],
            [79630,672.917,580.749],
            [79656,799.328,634.59],
            [79670,904.177,680.765],
            [79700,1003.08,725.788],
            [79711,1001.6,730.575],
            [79744,999.225,733.994],
            [79759,979.711,734.57],
            [79808,928.674,731.222],
            [79832,877.494,735.136],
            [79857,867.244,735.836],
            [79885,849.921,745.396],
            [79906,850.288,748.562],
            [79943,849.574,752.098],
            [79986,848.285,742.455],
            [79997,851.088,725.907],
            [80020,852.304,722.506],
            [80034,853.209,724.993],
            [80060,860.044,722.64],
            [80074,865.307,723.919],
            [80110,872.681,718.867],
            [80120,882.542,715.035],
            [80130,893.875,712.309],
            [80153,897.733,714.551],
            [80168,906.904,716.867],
            [80196,912.889,724.684],
            [80208,914.637,726.728],
            [80254,901.756,713.225],
            [80286,829.84,651.767],
            [80300,739.988,615.388],
            [80311,617.716,559.245],
            [80333,555.28,541.6],
            [80344,455.339,512.627],
            [80372,370.985,488.997],
            [80419,379.401,492.708],
            [80440,385.18,497.571],
            [80463,383.89,497.765],
            [80484,382.765,497.744],
            [80509,381.216,496.048],
            [80528,382.348,493.762],
            [80569,388.153,492.338],
            [80573,389.809,492.414],
            [80599,394.024,492.655],
            [80614,395.499,492.889],
            [80643,398.349,493.857],
            [80659,394.779,496.97],
            [80670,405.1,507.7],
            [80706,432.016,527.387],
            [80735,609.134,627.8],
            [80755,659.006,655.764],
            [80764,753.601,710.369],
            [80787,767.429,720.922],
            [80801,770.102,723.006],
            [80823,777.33,729.257],
            [80870,769.188,724.422],
            [80885,765.951,722.696],
            [80915,765.945,723.881],
            [80933,766,724.756],
            [80942,767.094,724.822],
            [80959,767.853,724.181],
            [80984,766.961,723.505],
            [81003,763.543,725.08],
            [81026,762.244,726.894],
            [81038,764.812,727.435],
            [81052,765.774,727.489],
            [81069,767.427,727.602],
            [81077,765.559,727.696],
            [81100,762.534,727.769],
            [81115,751.52,730.097],
            [81159,693.642,687.821],
            [81185,601.746,558.161],
            [81202,581.137,530.629],
            [81231,538.307,474.432],
            [81248,538.287,471.148],
            [81273,537.802,470.731],
            [81316,539.274,474.864],
            [81334,539.546,475.844],
            [81365,536.619,474.418],
            [81383,532.248,470.96],
            [81412,528.714,468.521],
            [81430,527.946,469.596],
            [81466,528.679,475.023],
            [81502,531.019,477.332],
            [81514,532.059,477.931],
            [81547,533.879,478.69],
            [81557,532.613,475.538],
            [81605,529.412,475.042],
            [81638,533.454,485.467],
            [81650,538.349,469.126],
            [81683,544.983,449.172],
            [81697,549.655,422.086],
            [81731,552.614,397.329],
            [81772,554.884,365.708],
            [81784,552.072,370.326],
            [81818,551.821,370.8],
            [81829,551.863,371.188],
            [81860,553.593,368.147],
            [81874,555.113,364.148],
            [81905,556.196,360.242],
            [81924,555.494,359.577],
            [81955,553.693,359.928],
            [81972,551.493,360.605],
            [81998,549.658,360.985],
            [82007,549.303,361.145],
            [82053,549.631,361.235],
            [82088,550.784,360.735],
            [82100,550.993,360.533],
            [82135,553.829,375.326],
            [82156,559.158,411.229],
            [82174,559.995,416.603],
            [82222,567.379,457.655],
            [82232,572.062,489.533],
            [82264,570.752,490],
            [82281,568.066,490.152],
            [82312,566.037,489.152]]
    }

    function animateSelection(key) {
        lockStep = true;
        selectionAnimation.key = key;
        selectionAnimation.start();
    }

    Timer {
        id: selectionAnimation
        interval: 750
        repeat: true
        property var key: null
        property int animStep: 0

        onRunningChanged: lockStep = running

        onTriggered: {
            switch (animStep) {
            case 0:
                gazeTimer.moveTo(key.centerX, key.centerY);
                pointer.visible = true;
                key.selected(key);
                break;
            case 1:
                gazeTimer.moveTo(pEyeGesture.centerX, pEyeGesture.centerY);
                pEyeGesture.selected(pEyeGesture);
                break;
            case 2:
                gazeTimer.moveTo(key.centerX, key.centerY);
                pEyeGesture.click(pEyeGesture, new Date().valueOf() - tutorial.t0, true);
                keysPEyeMenu.hide();
                break;
            default:
                stop();
                nextStep();
            }
            animStep++;
        }
    }
}

