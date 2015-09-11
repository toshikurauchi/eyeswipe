import QtQuick 2.0

Item {
    property alias regions: regionName
    property alias gazeDataType: gazeDataTypeName
    property var curState: null
    property var prevState: null
    property int curRegion: curState.regionId
    property bool inKeys: curRegion === regions.keys
    property double curFixTstamp: -1
    property double latestTstamp: -1
    property var regionRefs: []
    property var actionRegionRefs: []
    property var allRegionRefs: regionRefs.concat(actionRegionRefs)
    property var curRegionRef: null

    signal startedTyping(double tstamp)
    signal finishedTyping(double tstamp)
    signal cancelTyping(double tstamp)
    signal showCandidates(double tstamp)
    signal hideCandidates(double tstamp)
    signal deleteWord(double tstamp);
    signal changeCandidate(string candidate);
    signal showDeleteOptions(double tstamp);
    signal hideDeleteOptions(double tstamp);

    Item {
        id: regionName

        // Constants
        property int none: 0
        property int keys: 1
        property int candidates: 2
        property int text: 3
        property int actionKeys: 4
        property int actionCandidates: 5
        property int actionBackspace: 6
        property int actionPunct: 7

        function getName(regEnum) {
            var names = ["None", "Keys", "Candidates", "Text", "Action Keys", "Action Candidates", "Action Backspace", "Action Punctuation"];
            return names[regEnum];
        }
    }

    Item {
        id: gazeDataTypeName

        // Constants
        property int fixation: 0
        property int incompleteFixation: 1
        property int sample: 2
        property int selection: 3
        property var all: [fixation, incompleteFixation, sample]
    }

    function point2Region(point) {
        if (curRegionRef && curRegionRef.contains(point)) return curRegionRef.regionId;
        for (var i = 0; i < allRegionRefs.length; i++) {
            var region = allRegionRefs[i];
            if (region.contains(point)) return region.regionId;
        }
        return regions.none;
    }

    function onNewSample(sample, tstamp) {
        latestTstamp = Math.max(latestTstamp, tstamp);
        allRegionRefs.forEach(function (region) {
            region.onNewSample(sample, tstamp);
        });
        curState = curState.nextState(point2Region(sample), tstamp, 0, gazeDataType.sample);
    }

    function onNewFixation(fixation, tstamp, duration) {
        allRegionRefs.forEach(function (region) {
            region.onNewFixation(fixation, tstamp, duration);
        });
        if (curFixTstamp < tstamp) curFixTstamp = tstamp;
        var fixRegion = point2Region(fixation);
        curState = curState.nextState(fixRegion, tstamp, duration, gazeDataType.fixation);
    }

    function onIncompleteFixation(fixation, tstamp, duration) {
        allRegionRefs.forEach(function (region) {
            region.onIncompleteFixation(fixation, tstamp, duration);
        });
        curState = curState.nextState(point2Region(fixation), tstamp, duration, gazeDataType.incompleteFixation);
    }

    function onNewSelection(button, tstamp) {
        curState = curState.nextState(button, tstamp, 0, gazeDataType.selection);
    }

    onCurStateChanged: {
        if (prevState === curState) return; // Didn't change
        if (prevState !== null && prevState !== curState) prevState.stateOut();
        prevState = curState;
        curState.stateEnter();
    }

    onCurRegionChanged: {
        if (curRegionRef && curRegionRef.regionId === curRegion) return // Didn't change
        var newRegionRef = null;
        allRegionRefs.forEach(function(region) {
            region.enabled = (region.regionId === curRegion);
            if (region.enabled) newRegionRef = region;
        });
        curRegionRef = newRegionRef;
    }
}
