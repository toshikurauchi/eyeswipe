import QtQuick 2.0

Canvas {
    width: length
    height: 3 * lineWidth

    property double fromX: 0
    property double fromY: 0
    property double toX: 20
    property double toY: 20
    property double offsetBefore: 0
    property double offsetAfter: 0
    property double lineWidth: 10
    property double length: Math.sqrt((toX - fromX) * (toX - fromX) + (toY - fromY) * (toY - fromY))
    property double visibleLength: length - offsetAfter - offsetBefore
    property double tip: Math.min(1.5 * lineWidth, visibleLength / 2)
    property double rotAngle: Math.atan2(toY - fromY, toX - fromX) * 180 / Math.PI
    property double positiveRotAngle: rotAngle < 0 ? rotAngle + 360 : rotAngle
    property color fillColor: "gray"
    property bool inverted: false

    transform: [
        Rotation {
            origin.x: x
            origin.y: y + height / 2
            angle: positiveRotAngle
        },
        Translate {
            x: fromX
            y: fromY - 1.5 * lineWidth
        }
    ]

    onFromXChanged: requestPaint()
    onFromYChanged: requestPaint()
    onToXChanged: requestPaint()
    onToYChanged: requestPaint()
    onLineWidthChanged: requestPaint()
    onTipChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onRotAngleChanged: requestPaint()
    onInvertedChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.save();
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = fillColor;

        ctx.beginPath();
        if (inverted) {
            ctx.moveTo(length - offsetAfter, lineWidth);
            ctx.lineTo(offsetBefore + tip, lineWidth);
            ctx.lineTo(offsetBefore + tip, 0);
            ctx.lineTo(offsetBefore, 1.5 * lineWidth);
            ctx.lineTo(offsetBefore + tip, 3 * lineWidth);
            ctx.lineTo(offsetBefore + tip, 2 * lineWidth);
            ctx.lineTo(length - offsetAfter, 2 * lineWidth);
        }
        else {
            ctx.moveTo(offsetBefore, lineWidth);
            ctx.lineTo(length - tip - offsetAfter, lineWidth);
            ctx.lineTo(length - tip - offsetAfter, 0);
            ctx.lineTo(length - offsetAfter, 1.5 * lineWidth);
            ctx.lineTo(length - tip - offsetAfter, 3 * lineWidth);
            ctx.lineTo(length - tip - offsetAfter, 2 * lineWidth);
            ctx.lineTo(offsetBefore, 2 * lineWidth);
        }
        ctx.closePath();
        ctx.fill();
        ctx.restore();
    }
}

