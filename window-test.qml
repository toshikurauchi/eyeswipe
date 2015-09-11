import QtQuick 2.0

Item {
    width: 1024
    height: 768

    Rectangle {
        x: 20
        y: 20
        width: 10
        height: 10

        color: "red"

        MouseArea {
            clicked: {
                console.log("whatever");
            }
        }
    }
}
