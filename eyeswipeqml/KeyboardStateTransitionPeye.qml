import QtQuick 2.0

KeyboardStateTransition {
    property var mainButton: parent.mainButton
    property var lastSelected: parent.lastSelected
    acceptedDataTypes: [stateMachine.gazeDataType.selection]

    function accepts(region) {
        return lastSelected !== null && region === mainButton;
    }
}
