import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Fields"
import "../Images"

TextField {
    id: passwordTextField

    property string fieldName: ""
    readonly property int fieldRadius: 8
    readonly property int focusAnimationDuration: 300

    passwordCharacter: "•"
    placeholderText: fieldName
    font.family: nunitoSemiBold.name
    echoMode: TextInput.Password
    font.pointSize: 16
    padding: 12
    anchors {
        left: parent.left
        right: parent.right
    }

    RoundButton {
        width: height
        flat: true
        display: AbstractButton.IconOnly

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom

            margins: 8
        }

        onClicked: {
            if (passwordTextField.echoMode === TextInput.Password) {
                passwordTextField.echoMode = TextInput.Normal
                passwordEyeIcon.state = "showing"
            } else {
                passwordTextField.echoMode = TextInput.Password
                passwordEyeIcon.state = "hidding"
            }
        }

        Item {
            id: passwordEyeIcon
            state: "hidding"
            states: [
                State {
                    name: "showing"
                    PropertyChanges {eyeIcon.opacity: 1.0}
                },
                State {
                    name: "hidding"
                    PropertyChanges {eyeIcon.opacity: 0.5}
                }

            ]
            anchors {
                fill: parent
                margins: 6
            }

            ColoredSvgImage {
                id: eyeIcon
                anchors.fill: parent
                imageSource: "qrc:/images/show.svg"
                imageColor: themeSettings.primaryColor
            }
        }
    }
}
