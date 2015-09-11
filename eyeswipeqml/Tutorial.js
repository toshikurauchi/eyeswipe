.pragma library

var t0 = new Date().valueOf()

function Lesson(instructions, gazePointer, pEyeGesture, textField, sentenceToType) {
    this.steps = [];
    this.curStep = 0;
    this.instructions = instructions;
    this.gazePointer = gazePointer;
    this.pEyeGesture = pEyeGesture;
    this.textField = textField;
    this.sentenceToType = sentenceToType;
}

Lesson.prototype.addStep = function (newStep) {
    this.steps.push(newStep);
}

Lesson.prototype.nextStep = function () {
    var step = this.currentStep();
    if (!step) return false;
    this.sentenceToType.text = step.sentence;
    if (step.text) this.instructions.text = step.text;
    if (typeof step.textFieldPointerOffset !== 'undefined') this.gazePointer.moveTo(this.textField.x + this.textField.height / 2 + step.textFieldPointerOffset, this.textField.y + this.textField.height / 2);
    if (step.pointTo) this.gazePointer.moveTo(step.pointTo.centerX, step.pointTo.centerY);
    if (step.select) step.select.selected(step.select);
    if (step.click) step.click.click(step.click, new Date().valueOf() - t0, true);
    if (step.pEyeGestureText) this.pEyeGesture.text = step.pEyeGestureText;
    if (step.addCandidates) {
        this.textField.clear();
        this.textField.addWordCandidates(step.addCandidates);
    }
    if (step.addChar) this.textField.addSingleLetter(step.addChar);
    if (step.func) step.func();
    if (!step.isUserControl()) this.curStep++;
    return true;
}

Lesson.prototype.onEvent = function (handler, arg) {
    var step = this.currentStep();
    if (!step || !step[handler]) return;
    var ret;
    if (arg) ret = step[handler](arg);
    else ret = step[handler]();
    if (ret) this.curStep++;
}

Lesson.prototype.onNewWord = function (word) {
    this.onEvent("onNewWord", word);
}

Lesson.prototype.onWordDeleted = function (word) {
    this.onEvent("onWordDeleted", word);
}

Lesson.prototype.onGestureToggled = function () {
    this.onEvent("onGestureToggled");
}

Lesson.prototype.onGestureCanceled = function () {
    this.onEvent("onGestureCanceled");
}

Lesson.prototype.onCharAdded = function (addedChar) {
    this.onEvent("onCharAdded", addedChar);
}

Lesson.prototype.onCharDeleted = function () {
    this.onEvent("onCharDeleted");
}

Lesson.prototype.currentStep = function () {
    if (this.curStep >= this.steps.length) return null;
    return this.steps[this.curStep];
}

function Step(args) {
    this.text = args["text"];
    this.textFieldPointerOffset = args["textFieldPointerOffset"];
    this.pointTo = args["pointTo"];
    this.select = args["select"];
    this.click = args["click"];
    this.sentence = args["sentence"] ? args["sentence"] : "";
    this.pEyeGestureText = args["pEyeGestureText"];
    this.addCandidates = args["addCandidates"];
    this.addChar = args["addChar"];
    this.func = args["func"];
    this.onNewWord = args["onNewWord"];
    this.onWordDeleted = args["onWordDeleted"];
    this.onGestureToggled = args["onGestureToggled"];
    this.onGestureCanceled = args["onGestureCanceled"];
    this.onCharAdded = args["onCharAdded"];
    this.onCharDeleted = args["onCharDeleted"];
}

Step.prototype.isUserControl = function () {
    return this.onNewWord || this.onWordDeleted || this.onGestureToggled || this.onGestureCanceled || this.onCharAdded || this.onCharDeleted;
}
