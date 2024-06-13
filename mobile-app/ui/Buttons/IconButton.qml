import QtQuick
import QtQuick.Controls

import "../Texts"
import "../Buttons"
import "../Images"

Item {
    id: root

    property string text: ""
    property color imageColor: null
    property string imageSource: ""
    property int iconPadding: 4
    property int buttonRadius: 8
    property int buttonSize: 50

    signal clicked()

    height: buttonSize
    width: buttonSize

    ColoredSvgImage {
        imageColor: root.imageColor
        imageSource: root.imageSource
        opacity: mouseArea.pressed ? 0.5 : 1
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: iconPadding
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
