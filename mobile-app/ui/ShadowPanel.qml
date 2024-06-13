import QtQuick

Rectangle {
    id: root

    state: "hidden"
    color: themeSettings.primaryColor
    anchors.fill: parent

    states: [
        State {
            name: "showed"
            PropertyChanges {
                target: root
                opacity: 0.2
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: root
                opacity: 0
            }
        }
    ]

    MouseArea {
        enabled: state === "showed"
        anchors.fill: parent
        preventStealing: true
        onClicked: {
            console.log("Bober123")
            mouse.accepted = false;
        }
        onPressed: mouse.accepted = false;
        onReleased: mouse.accepted = false;
        onDoubleClicked: mouse.accepted = false;
        onPositionChanged: mouse.accepted = false;
        onPressAndHold: mouse.accepted = false;
    }
}
