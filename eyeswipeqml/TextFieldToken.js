.pragma library

function Token(candidates, isEditing, extraSpaces, isPunct, charByChar) {
    this.candidates = candidates;
    this.word = candidates.length > 0 ? candidates[0] : "";
    this.isEditing = isEditing;
    this.extraSpaces = typeof(extraSpaces) == "undefined" ? 0 : extraSpaces;
    this.isPunct = isPunct;
    this.charByChar = charByChar;

    this.addExtraSpace = function() {
        this.extraSpaces++;
        this.isEditing = false;
    }

    this.removeExtraSpace = function() {
        if (this.extraSpaces > 0) {
            this.extraSpaces--;
            return true;
        }
        return false;
    }

    this.removeLastChar = function() {
        if (this.word.length > 0) this.word = this.word.substring(0, this.word.length - 1);
        this.isEditing = true;
        this.candidates = [];
    }

    this.isEmpty = function() {
        return this.word.length === 0 && this.extraSpaces === 0;
    }

    this.changeCandidate = function(newCandidate) {
        this.word = newCandidate;
    }
}
