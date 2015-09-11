import QtQuick 2.0

BaseStateMachine {
    curState: starting

    property var backspaceKey: null
    property var allKeys: []
    property var allCandidateKeys: []
    property var punctKey: null
    property bool cancelMode: curState === canceling || curState === cancelAction || curState === typing || curState === finishAction
    property bool punctMode: !cancelMode

    property var keysActionRegion: null
    property var candidatesActionRegion: null
    property var backspaceActionRegion: null
    property var punctActionRegion: null
    actionRegionRefs: [keysActionRegion, candidatesActionRegion, backspaceActionRegion, punctActionRegion].filter(function(reg) {return reg});

    signal newFirstLetter(string letter)
    signal newLastLetter(string letter)
    signal candidateSelected(string candidate)
    signal punctuationTyped(string punctuation)

    KeyboardState {
        id: starting
        regionId: regions.keys

        KeyboardStateTransition {
            to: selectingCandidates
            onActivated: {
                console.log("STARTING->CANDIDATES");
            }
        }

        KeyboardStateTransition {
            to: startAction
            accept: allKeys
            acceptedDataTypes: [gazeDataType.selection]
            onActivated: {
                console.log("STARTING->START TYPING");
                startAction.mainButton = starting.selectionRef;
            }
        }

        KeyboardStateTransition {
            to: punctAction
            accept: [punctKey]
            acceptedDataTypes: [gazeDataType.selection]
            onActivated: {
                console.log("STARTING->TYPING PUNCT");
                punctAction.mainButton = starting.selectionRef;
            }
        }
    }

    KeyboardState {
        id: typing
        regionId: regions.keys

        KeyboardStateTransition {
            to: finishAction
            accept: allKeys
            acceptedDataTypes: [gazeDataType.selection]
            onActivated: {
                console.log("TYPING->FINISH TYPING");
                finishAction.mainButton = typing.selectionRef;
                newLastLetter(finishAction.mainButton.objectName[0]);
                keysActionRegion.updateFirstCandidate();
            }
        }

        KeyboardStateTransition {
            to: canceling
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("TYPING->CANCELING");
            }
        }
    }

    KeyboardState {
        id: canceling
        regionId: regions.candidates

        KeyboardStateTransition {
            to: typing
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("CANCELING->TYPING");
            }
        }

        KeyboardStateTransition {
            to: cancelAction
            accept: [backspaceKey]
            acceptedDataTypes: [gazeDataType.selection]
            onActivated: {
                console.log("CANCELING->CANCEL ACTION");
                cancelAction.mainButton = canceling.selectionRef;
            }
        }
    }

    KeyboardState {
        id: selectingCandidates
        regionId: regions.candidates

        KeyboardStateTransition {
            to: starting
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("CANDIDATES->STARTING");
            }
        }

        KeyboardStateTransition {
            to: candidateAction
            accept: allCandidateKeys
            acceptedDataTypes: [gazeDataType.selection]
            onActivated: {
                console.log("CANDIDATES->SELECT CANDIDATE");
                candidateAction.mainButton = selectingCandidates.selectionRef;
            }
        }

        KeyboardStateTransition {
            to: deleteAction
            accept: [backspaceKey]
            acceptedDataTypes: [gazeDataType.selection]
            onActivated: {
                console.log("CANDIDATES->DELETING");
                deleteAction.mainButton = selectingCandidates.selectionRef;
            }
        }
    }

    KeyboardStatePeyeMenu {
        id: cancelAction
        regionId: regions.actionBackspace
        onMainButtonChanged: {
            if (backspaceActionRegion) backspaceActionRegion.refButton = mainButton;
        }

        KeyboardStateTransition {
            to: typing
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("CANCEL ACTION->TYPING");
            }
        }

        KeyboardStateTransition {
            to: canceling
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("CANCEL ACTION->CANCELING");
            }
        }

        KeyboardStateTransitionPeye {
            to: selectingCandidates
            onActivated: {
                console.log("CANCEL ACTION->CANCELED->CANDIDATES");
                cancelTyping(curFixTstamp);
            }
        }
    }

    KeyboardStatePeyeMenu {
        id: deleteAction
        regionId: regions.actionBackspace
        onMainButtonChanged: {
            if (backspaceActionRegion) backspaceActionRegion.refButton = mainButton;
        }

        KeyboardStateTransition {
            to: starting
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("DELETING->STARTING");
            }
        }

        KeyboardStateTransition {
            to: selectingCandidates
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("DELETING->CANDIDATES");
            }
        }

        KeyboardStateTransitionPeye {
            to: selectingCandidates
            onActivated: {
                console.log("DELETING->DELETED->CANDIDATES");
                deleteWord(curFixTstamp);
            }
        }
    }

    KeyboardStatePeyeMenu {
        id: candidateAction
        regionId: regions.actionCandidates
        onMainButtonChanged: {
            if (candidatesActionRegion) candidatesActionRegion.refButton = mainButton;
        }

        KeyboardStateTransition {
            to: starting
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("SELECT CANDIDATE->STARTING");
            }
        }

        KeyboardStateTransition {
            to: selectingCandidates
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("SELECT CANDIDATE->CANDIDATES");
            }
        }

        KeyboardStateTransitionPeye {
            to: selectingCandidates
            onActivated: {
                var candidate = "no candidate selected";
                if (mainButton) {
                    candidate = mainButton.text;
                    candidateSelected(candidate);
                }
                console.log("SELECT CANDIDATE->SELECTED (" + candidate + ")->CANDIDATES");
            }
        }
    }

    KeyboardStatePeyeMenu {
        id: startAction
        regionId: regions.actionKeys
        onMainButtonChanged: {
            if (keysActionRegion) keysActionRegion.refButton = mainButton;
        }

        KeyboardStateTransition {
            to: starting
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("START TYPING->STARTING");
            }
        }

        KeyboardStateTransition {
            to: selectingCandidates
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("START TYPING->CANDIDATES");
            }
        }

        KeyboardStateTransitionPeye {
            to: typing
            onActivated: {
                newFirstLetter(mainButton.objectName[0]);
                console.log("START TYPING->TYPING");
                startedTyping(curFixTstamp);
            }
        }
    }

    KeyboardStatePeyeMenu {
        id: finishAction
        regionId: regions.actionKeys

        onMainButtonChanged: {
            if (keysActionRegion) keysActionRegion.refButton = mainButton;
        }

        KeyboardStateTransition {
            to: typing
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("FINISH TYPING->TYPING");
            }
        }

        KeyboardStateTransition {
            to: canceling
            acceptedDataTypes: [gazeDataType.fixation]
            onActivated: {
                console.log("FINISH TYPING->CANCELING");
            }
        }

        KeyboardStateTransitionPeye {
            to: starting
            onActivated: {
                console.log("FINISH TYPING->STARTING");
                finishedTyping(finishAction.lastActivation);
            }
        }
    }

    KeyboardStatePeyeMenu {
        id: punctAction
        regionId: regions.actionPunct
        onMainButtonChanged: {
            if (punctActionRegion) punctActionRegion.refButton = mainButton;
        }

        KeyboardStateTransition {
            to: starting
            onActivated: {
                console.log("TYPING PUNCT->STARTING");
            }
        }

        KeyboardStateTransition {
            to: selectingCandidates
            onActivated: {
                console.log("TYPING PUNCT->CANDIDATES");
            }
        }

        KeyboardStateTransitionPeye {
            to: starting
            onActivated: {
                console.log("TYPING PUNCT->TYPED (" + lastSelected.text + ")->STARTING");
                punctuationTyped(lastSelected.text);
            }
        }
    }
}
