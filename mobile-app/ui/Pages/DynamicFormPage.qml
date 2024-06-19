import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"
import "../Cards"
import "../Images"

Page {
    id: root

    property int fromBorderMargin: 28
    property int titleTopMargin: 128
    property int controlHeight: 50
    property int cardTagHeight: 22
    property int itemsSpacing: 8
    property int betweenTagsSpacing: 8
    property int standardMargin: 10
    property int betweenCardsSpacing: 16
    property int cardFromBorderMargin: 12

    property int i: 0
    property var data: []
    property var dynamicObjects: []
    property string pageTitle: ""
    property string pageDescription: ""

    function addTextField(name) {
        var obj = textFieldComponent.createObject(controlsColumn, {index: root.i + 0, fieldName: name})
        root.i = root.i + 1
        dynamicObjects.push(obj)
    }

    function addTextFieldFloat(name) {
        var obj = textFieldFloatComponent.createObject(controlsColumn, {index: root.i + 0, fieldName: name})
        root.i = root.i + 1
        dynamicObjects.push(obj)
    }

    function addTextArea(name, initText, areaHeight) {
        var obj = textAreaComponent.createObject(controlsColumn, {fieldName: name, text: initText, height: areaHeight})
        root.i = root.i + 1
        dynamicObjects.push(obj)
    }

    function addPassordField(name) {
        var obj = passwordFieldComponent.createObject(controlsColumn, {index: root.i + 0, fieldName: name})
        root.i = root.i + 1
        dynamicObjects.push(obj)
    }

    function setActive(active) {
        for (var i = 0; i < dynamicObjects.length; i++) {
            dynamicObjects[i].active = active
        }
    }

    function addComboBox(name, optionsList, i = 0) {
        var obj = spacingComponent.createObject(controlsColumn, {height: 2})
        dynamicObjects.push(obj)
        obj = comboBoxComponent.createObject(controlsColumn, {fieldName: name, options: optionsList, currentIndex: i})
        root.i = root.i + 1
        dynamicObjects.push(obj)
        obj = spacingComponent.createObject(controlsColumn, {height: 2})
        dynamicObjects.push(obj)
    }

    function addButton(name, func) {
        var obj = buttonComponent.createObject(controlsColumn, {text: name, callback: [func]})
        root.i = root.i + 1
        dynamicObjects.push(obj)
    }

    function addSpacing() {
        var obj = spacingComponent.createObject(controlsColumn, {})
        root.i = root.i + 1
        dynamicObjects.push(obj)
    }

    function clear() {
        root.i = 0
        root.data = []
        for (var i = 0; i < dynamicObjects.length; i++) {
            dynamicObjects[i].destroy()
        }
        dynamicObjects = []
        pageTitle = ""
        pageDescription = ""
    }

    function getData() {
        var data = []
        for (var i = 0; i < dynamicObjects.length; i++) {
            var obj = dynamicObjects[i]
            if (!obj.isControl()) continue
            data.push(obj.getData())
        }
        return data
    }

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page Flickable */
    Flickable {
        id: contentListView
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        anchors.fill: parent
        // contentHeight: titleTopMargin + title.height + descriptionText.height

        IconButton {
            id: backButton
            buttonSize: 32
            imageColor: themeSettings.primaryColor
            imageSource: "qrc:/images/navigation/back.svg"
            anchors {
                left: parent.left
                bottom: titleText.top
                leftMargin: fromBorderMargin - 4
                bottomMargin: 30
            }
            onClicked: {
                if (housesStackView.currentItem === dynamicFormPage) housesStackView.pop()
                if (eventsStackView.currentItem === dynamicFormPage) eventsStackView.pop()
                if (countersStackView.currentItem === dynamicFormPage) countersStackView.pop()
                if (profileStackView.currentItem === dynamicFormPage) profileStackView.pop()
                if (mainStackView.currentItem === dynamicFormPage) mainStackView.pop()
            }
        }

        /* Page Title */
        TitleText {
            id: titleText
            text: root.pageTitle
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: fromBorderMargin
                topMargin: titleTopMargin
            }
        }

        /* Address filter */
        RegularText {
            id: descriptionText
            text: root.pageDescription
            horizontalAlignment: Text.AlignLeft
            opacity: 0.5
            anchors {
                top: titleText.bottom
                left: parent.left
                right: parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }
        }

        /* ControlsColumn */
        Column {
            id: controlsColumn
            anchors {
                top: descriptionText.bottom
                left: parent.left
                right: parent.right
                topMargin: fromBorderMargin
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }
        }
    }

    Component {
        id: textAreaComponent

        TextArea {
            property bool active: true
            property string fieldName: ""
            readonly property int fieldRadius: 8
            readonly property int focusAnimationDuration: 300
            placeholderText: fieldName
            font.family: nunitoSemiBold.name
            font.pointSize: 16
            padding: 12
            wrapMode: TextEdit.WordWrap
            anchors {
                left: parent.left
                right: parent.right
            }
            function isControl() {return true}
            function getData() {return text}
            Keys.onReturnPressed: {
                event.accepted = true
            }
        }
    }

    Component {
        id: passwordFieldComponent

        TextField {
            id: passwordTextField
            property int index: 0
            property bool active: true
            property string fieldName: ""
            readonly property int fieldRadius: 8
            readonly property int focusAnimationDuration: 300
            echoMode: TextInput.Password
            passwordCharacter: "•"
            placeholderText: fieldName
            font.family: nunitoSemiBold.name
            font.pointSize: 16
            padding: 12
            anchors {
                left: parent.left
                right: parent.right
            }
            function isControl() {return true}
            function getData() {return text}
            Keys.onReturnPressed: {
                focus = false
                if (index === root.i - 1) return
                root.dynamicObjects[index + 2].focus = true
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
    }

    Component {
        id: textFieldComponent

        TextField {
            property int index: 0
            property bool active: true
            property string fieldName: ""
            readonly property int fieldRadius: 8
            readonly property int focusAnimationDuration: 300
            placeholderText: fieldName
            font.family: nunitoSemiBold.name
            font.pointSize: 16
            padding: 12
            anchors {
                left: parent.left
                right: parent.right
            }
            Keys.onReturnPressed: {
                console.log(index)
                focus = false
                if (index === root.i - 1) return
                root.dynamicObjects[index + 2].focus = true
            }
            function isControl() {return true}
            function getData() {return text}
        }
    }

    Component {
        id: textFieldFloatComponent

        TextField {
            property int index: 0
            property string previousText: ""
            property bool active: true
            property string fieldName: ""
            readonly property int fieldRadius: 8
            readonly property int focusAnimationDuration: 300
            placeholderText: fieldName
            font.family: nunitoSemiBold.name
            font.pointSize: 16
            padding: 12
            anchors {
                left: parent.left
                right: parent.right
            }
            function isControl() {return true}
            function getData() {return text}
            Keys.onReturnPressed: {
                focus = false
                if (index === root.i - 1) return
                root.dynamicObjects[index + 2].focus = true
            }
            onTextChanged: {
                let regex = new RegExp("^\\d+(\\.(\\d{1})?)?$")
                if (text.match(regex) || text === "") {
                    previousText = text
                } else {
                    text = previousText
                }
            }
        }
    }

    Component {
        id: comboBoxComponent

        ComboBox {
            property int index: 0
            property bool active: true
            property var options: []
            property string fieldName: ""
            height: controlHeight + 20
            model: options
            anchors {
                left: parent.left
                right: parent.right
            }
            Keys.onReturnPressed: {
                focus = false
                if (i === root.i - 1) return
                root.dynamicObjects[i + 1].focus = true
            }
            function isControl() {return true}
            function getData() {return displayText}
        }
    }

    Component {
        id: buttonComponent

        RectangleButton {
            property bool active: true
            property var callback: undefined
            interactive: active
            opacity: active ? 1 : 0.5
            height: controlHeight
            anchors {
                left: parent.left
                right: parent.right
            }
            onClicked: {
                if (callback === undefined) return
                callback[0]()
            }
            function isControl() {return false}
        }
    }

    Component {
        id: spacingComponent
        Item {
            property bool active: true
            height: itemsSpacing
            anchors {
                left: parent.left
                right: parent.right
            }
            function isControl() {return false}
        }
    }
}
