import QtQuick 2.0
import "gaze.js" as Gaze

Item {
    property var fixations: []
    property var latestFixation: null
    property double fixationThreshold: 10 // px
    property double restartThreshold: 800 // ms
    property double typingModeThreshold: keyboardSetup.isTraining() ? 500 : 50 // ms
    property bool active: true
    property bool onTypingMode: false
    property double lastRestartTstamp: -1
    property double curTstamp: -1
    property var curFix: null

    signal start(var fixation, double tstamp);
    signal restart(var fixation, double tstamp);

    onActiveChanged: {
        if (!active) {
            fixations = [];
            latestFixation = null;
        }
    }

    function onNewFixation(fixation, fixationRegion, tstamp, duration) {
        curFix = fixation;
        curTstamp = tstamp;
        if (!active || fixationRegion !== stateMachine.regions.keys) return;
        var newFixation = new Gaze.Fixation(fixation, tstamp, duration);
        if (latestFixation !== null && latestFixation.distanceTo(newFixation) < fixationThreshold) {
            latestFixation.merge(newFixation);
        }
        else {
            fixations.push(newFixation);
            latestFixation = newFixation;
        }

        if (onTypingMode && latestFixation.duration > restartThreshold && lastRestartTstamp !== latestFixation.timestamp) {
            fixations = [latestFixation];
            restart(latestFixation.position, latestFixation.timestamp);
            lastRestartTstamp = latestFixation.timestamp;
        }
        else if (!onTypingMode && latestFixation.duration > typingModeThreshold) {
            start(curFix, curTstamp);
            lastRestartTstamp = latestFixation.timestamp;
        }
    }
}
