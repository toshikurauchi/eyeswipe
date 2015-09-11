import QtQuick 2.0

Item {
    id: thisState
    property int regionId: -1
    property alias stateTransitions: thisState.children
    property double activationTstamp: -1
    property double lastActivation: -1
    property int selectionDataType: stateMachine.gazeDataType.selection
    property var selectionRef: null

    onActivationTstampChanged: {
        if (activationTstamp > lastActivation) lastActivation = activationTstamp;
    }

    function nextState(region, tstamp, duration, dataType) {
        if (dataType === selectionDataType) thisState.selectionRef = region; // region is the button in this case
        for (var i = 0; i < stateTransitions.length; i++) {
            var stateTransition = stateTransitions[i];
            if (stateTransition.acceptedDataTypes.indexOf(dataType) >= 0 && stateTransition.accepts(region)) {
                thisState.activationTstamp = -1;
                stateTransition.to.activationTstamp = tstamp;
                stateTransition.activated(tstamp);
                return stateTransition.to;
            }
        }
        return thisState;
    }

    function stateEnter() {
        // Do any initialization you may need in this function
    }

    function stateOut() {
        // Do any cleanup you may need in this function
    }
}
