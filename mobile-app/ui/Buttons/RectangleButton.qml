import QtQuick
import QtQuick.Controls

import "../Texts"

Item {
    id: root

    property bool interactive: true
    property string text: ""
    readonly property int buttonRadius: 8

    signal clicked()

    Rectangle {
        implicitHeight: height
        radius: buttonRadius
        opacity: mouseArea.pressed ? 0.7 : 1
        color: themeSettings.accentColor
        anchors.fill: parent
    }

    RegularText {
        anchors.centerIn: parent
        text: root.text
        color: themeSettings.backgroundColor
    }

    MouseArea {
        id: mouseArea
        enabled: interactive
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
