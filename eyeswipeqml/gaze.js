.pragma library

function Fixation(fixation, timestamp, duration) {
    this.position = fixation;
    this.timestamp = timestamp;
    this.duration = duration;

    this.distanceTo = function(other) {
        var dx = this.position.x - other.position.x;
        var dy = this.position.y - other.position.y;
        return Math.sqrt(dx*dx + dy*dy);
    }

    this.merge = function(other) {
        var alpha = this.duration / (this.duration + other.duration);
        var x = this.position.x * alpha + (1 - alpha) * other.position.x;
        var y = this.position.y * alpha + (1 - alpha) * other.position.y;

        var duration;
        if (this.timestamp < other.timestamp) {
            duration = other.timestamp - this.timestamp + other.duration;
        }
        else {
            duration = this.timestamp - other.timestamp + this.duration;
        }

        this.position = Qt.point(x, y);
        this.timestamp = Math.min(this.timestamp, other.timestamp);
        this.duration = duration;
    }
}
