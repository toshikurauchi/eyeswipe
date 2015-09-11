import QtQuick 2.0

KBButton {
    id: pEyeButton
    property double refX: 2 * size
    property double refY: 2 * size
    property double offsetX: 1.5 * width
    property double offsetY: 1.5 * height
    // Positions:
    //    0   1   2
    //    7  ref  3
    //    6   5   4
    property int position: 1
    radiusRatio: 0.5
    visibleColor: isSelected ? selectedColor : unselectedColor
    onRefXChanged: updateCenter()
    onRefYChanged: updateCenter()
    onOffsetXChanged: updateCenter()
    onOffsetYChanged: updateCenter()
    onPositionChanged: updateCenter()

    function updateCenter() {
        switch (position) {
        case 0:
            centerX = refX - offsetX;
            centerY = refY - offsetY;
            break;
        case 1:
            centerX = refX;
            centerY = refY - offsetY;
            break;
        case 2:
            centerX = refX + offsetX;
            centerY = refY - offsetY;
            break;
        case 3:
            centerX = refX + offsetX;
            centerY = refY;
            break;
        case 4:
            centerX = refX + offsetX;
            centerY = refY + offsetY;
            break;
        case 5:
            centerX = refX;
            centerY = refY + offsetY;
            break;
        case 6:
            centerX = refX - offsetX;
            centerY = refY + offsetY;
            break;
        case 7:
            centerX = refX - offsetX;
            centerY = refY;
            break;
        default:
            console.log("Invalid position:", position);
        }
    }
}
