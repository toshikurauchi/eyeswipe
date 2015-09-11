import QtQuick 2.0

GazeShape {
    id: liveGazeShape

    function pathColor(alpha) {
        return Qt.rgba(59/255., 102/255., 255/255., alpha);
    }

    onPaint: {
        var ctx = canvas.getContext('2d');
        ctx.clearRect(canvas.x, canvas.y, canvas.width, canvas.height);
        if (points.length <= 1) return;
        var alpha = 0;
        var alphaStep = 0.8 / (points.length - 1);
        var width = 0;
        var widthStep = 5.0 / (points.length - 1);
        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        points.slice(1, points.length).forEach(function(p) {
            alpha += alphaStep;
            width += widthStep;
            ctx.strokeStyle = pathColor(alpha);
            ctx.lineWidth = width;
            ctx.lineTo(p.x, p.y);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
        });
    }
}
