import QtQuick 2.0

KBRegion {
    property var refButton: null
    property double leftDist: margin + computeLeft(buttons)
    property double rightDist: margin + computeRight(buttons)
    property double upDist: margin + computeUp(buttons)
    property double downDist: margin + computeDown(buttons)
    property double refX: leftDist
    property double refY: upDist
    property double acceptOffset: 1
    property double acceptTime: 300
    property double t0Outside: -1
    width: leftDist + rightDist
    height: upDist + downDist
    showRegion: false

    function computeOffset(buttons, fullPositions, halfPositions, isHorizontal) {
        if (refButton === null) return 0;
        var offset = refButton.height / 2;
        if (isHorizontal) offset = refButton.width / 2;
        buttons.forEach(function(button) {
            var off = button.offsetY;
            var half = button.height / 2;
            if (isHorizontal) {
                off = button.offsetX;
                half = button.width / 2
            }

            if (fullPositions.indexOf(button.position) >= 0)
                offset = Math.max(off + half, offset);
            else if (halfPositions.indexOf(button.position) >= 0)
                offset = Math.max(half, offset);
        });
        return offset;
    }

    function computeLeft(buttons) {
        return computeOffset(buttons, [0, 7, 6], [1, 5], true);
    }
    function computeRight(buttons) {
        return computeOffset(buttons, [2, 3, 4], [1, 5], true);
    }
    function computeUp(buttons) {
        return computeOffset(buttons, [0, 1, 2], [3, 7], false);
    }
    function computeDown(buttons) {
        return computeOffset(buttons, [4, 5, 6], [3, 7], false);
    }

    function contains(point) {
        if (!enabled || !refButton) {
            t0Outside = -1;
            return false;
        }
        var threshold = acceptOffset * acceptOffset;
        var dist = threshold + 1; // infinity
        buttons.forEach(function(button) {
            dist = Math.min(dist, button.distanceSquareToButton(point));
        });
        if (dist < 1) {
            t0Outside = latestTstamp;
            return true;
        }
        if (dist > threshold) {
            t0Outside = -1;
            return false;
        }
        if (latestTstamp - t0Outside <= acceptTime) {
            return true;
        }
        return false;
    }
}
