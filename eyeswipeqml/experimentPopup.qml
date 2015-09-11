import QtQuick 2.0
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1

ApplicationWindow {
    id: win
    visible: true
    width: 300
    height: 100
    title: qsTr("Choose keyboard mode")

    signal closed(bool isExperiment, bool isEnglish)

    Action {
        shortcut: "Ctrl+Q"
        onTriggered: Qt.quit();
    }

    GridLayout {
        columns: 3
        anchors.fill: parent
        anchors.margins: 10

        Label {
            text: "Language:"
        }
        ComboBox {
            id: languageCombo
            Layout.columnSpan: 2
            Layout.fillWidth: true
            currentIndex: 0
            model: ["English", "Português"]
            property bool isEnglish: currentIndex === 0
        }

        Label {
            Layout.row: 1
            Layout.column: 0
            text: "Mode:"
        }
        ExclusiveGroup { id: modeGroup }
        RadioButton {
            Layout.row: 1
            Layout.column: 1
            text: "Full"
            exclusiveGroup: modeGroup
        }
        RadioButton {
            id: isExperiment
            Layout.row: 1
            Layout.column: 2
            Layout.alignment: Qt.AlignRight
            text: "Experiment"
            checked: true
            exclusiveGroup: modeGroup
        }

        Button {
            Layout.row: 2
            Layout.column: 2
            Layout.alignment: Qt.AlignRight
            text: "Ok"

            onClicked: {
                closed(isExperiment.checked, languageCombo.isEnglish);
                Qt.quit();
            }
        }
    }
}
