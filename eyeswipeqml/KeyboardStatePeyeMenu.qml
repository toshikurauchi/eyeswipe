import QtQuick 2.0

KeyboardState {
    property var mainButton: null
    property var lastSelected: null

    onSelectionRefChanged: {
        if (selectionRef !== mainButton) lastSelected = selectionRef;
    }

    function stateOut() {
        lastSelected = null;
    }
}
