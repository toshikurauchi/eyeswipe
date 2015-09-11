import QtQuick 2.0

Canvas {
    id: gazeShape
    property var points: []
    property bool showPath: true
    property color shapeStrokeColor: "red"
    property color shapeFillColor: "red"

    onPaint: {
        if (!visible) return;
        var ctx = gazeShape.getContext('2d');
        ctx.clearRect(gazeShape.x, gazeShape.y, gazeShape.width, gazeShape.height);
        if (points.length <= 1) return;
        var width = 0;
        var widthStep = 5.0 / (points.length - 1);
        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        points.slice(1, points.length).forEach(function(p) {
            width += widthStep;
            ctx.strokeStyle = shapeStrokeColor;
            ctx.lineWidth = width;
            ctx.lineTo(p.x, p.y);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
        });
        points.forEach(function(p) {
            ctx.fillStyle = shapeFillColor;
            ctx.beginPath();
            ctx.arc(p.x, p.y, 4, 0, 2*Math.PI);
            ctx.fill();
        });
    }
    onPointsChanged: requestPaint()
}
