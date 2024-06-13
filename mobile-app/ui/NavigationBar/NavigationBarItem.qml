import QtQuick

import "../Images"
import "../Texts"

Item {
    id: root

    property string text: ""
    property string imageSource: ""

    property color color: themeSettings.accentColor

    property int imageSize: 22
    property int standardPadding: 6

    implicitWidth: max(icon.width, label.width)
    height: icon.height + standardPadding + label.height

    state: "highlighted"

    states: [
        State {
            name: "highlighted"
            PropertyChanges {
                target: icon
                imageColor: themeSettings.accentColor
            }
            PropertyChanges {
                target: label
                color: themeSettings.accentColor
            }
            PropertyChanges {
                target: root
                opacity: 1
            }
        },
        State {
            name: "default"
            PropertyChanges {
                target: icon
                imageColor: themeSettings.primaryColor
            }
            PropertyChanges {
                target: label
                color: themeSettings.primaryColor
            }
            PropertyChanges {
                target: root
                opacity: 0.6
            }
        }

    ]

    signal clicked()

    ColoredSvgImage {
        id: icon
        height: imageSize
        width: imageSize
        imageColor: root.color
        imageSource: root.imageSource
        opacity: mouseArea.pressed ? 0.8 : 1
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
    }

    CaptionText {
        id: label
        text: root.text
        color: root.color
        opacity: mouseArea.pressed ? 0.8 : 1
        anchors {
            top: icon.bottom
            topMargin: standardPadding
            horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }

    function max(a, b) {
        return a > b ? a : b
    }
}
