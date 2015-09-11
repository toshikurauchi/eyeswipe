import QtQuick 2.0

Key {
    id: gestureKey
    property double referenceX: -1
    property int centerIndex: 0
    property string displayedText: ""
    property var candidateRepeater: null
    property var candidateObjects: null
    property bool inGesture: false

    onReferenceXChanged: {
        if (candidateRepeater === null) return;
        var total = candidateRepeater.count;
        if (total === 0) return;

        var closest = 0;
        var closestDist = Math.abs(candidateRepeater.itemAt(0).centerX - referenceX);
        for (var i = 1; i < total; i++) {
            var dist = Math.abs(candidateRepeater.itemAt(i).centerX - referenceX);
            if (dist < closestDist) {
                closest = i;
                closestDist = dist;
            }
        }
        centerIndex = closest;
    }

    Text {
        x: Math.min(Math.max(referenceX - gestureKey.x - paintedWidth / 2, 0), gestureKey.width - paintedWidth)
        y: (gestureKey.height - paintedHeight) / 2
        font.pixelSize: fontSize
        scale: paintedWidth > size ? (size / paintedWidth) : 1

        text: displayedText
    }
}
