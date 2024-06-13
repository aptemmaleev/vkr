import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"
import "../Cards"
import "../Images"

Popup {
    id: root

    property int fromBorderMargin: 28
    property int titleTopMargin: 128
    property int controlHeight: 40
    property int cardTagHeight: 22
    property int itemsSpacing: 8
    property int betweenTagsSpacing: 8
    property int standardMargin: 10
    property int betweenCardsSpacing: 16
    property int cardFromBorderMargin: 12

    property var dynamicObjects: []
    property string title: ""
    property string description: ""

    function clear() {
        for (var i = 0; i < dynamicObjects.length; i++) {
            dynamicObjects[i].destroy()
        }
        dynamicObjects = []
        title = ""
        description = ""
    }

    function showError(error, func = () => {}) {
        clear()
        title = "Ошибка"
        description = error
        addButton("Закрыть", () => {
            func()
        })
        open()
    }

    function addButton(name, func) {
        var obj = buttonComponent.createObject(controlsColumn, {text: name, callback: [func]})
        dynamicObjects.push(obj)
    }

    closePolicy: Popup.NoAutoClose

    topInset: 0
    leftInset: 0
    rightInset: 0
    bottomInset: 0

    topPadding: standardMargin
    leftPadding: standardMargin
    rightPadding: standardMargin
    bottomPadding: standardMargin

    height: titleText.height + descriptionText.height + controlsColumn.height + standardMargin * 2 + itemsSpacing * 2
    width: mainWindow.width - fromBorderMargin * 2
    anchors.centerIn: parent

    background: Rectangle {
        radius: 12
        color: themeSettings.backgroundColor
    }

    SubTitleText {
        id: titleText
        text: root.title
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: itemsSpacing
        }
    }

    RegularText {
        id: descriptionText
        text: root.description
        anchors {
            top: titleText.bottom
            left: parent.left
            right: parent.right
        }
    }

    Column {
        id: controlsColumn
        spacing: itemsSpacing
        anchors {
            top: descriptionText.bottom
            left: parent.left
            right: parent.right
            topMargin: itemsSpacing
        }
    }

    Component {
        id: buttonComponent

        RectangleButton {
            property var callback: undefined
            height: controlHeight
            anchors {
                left: parent.left
                right: parent.right
            }
            onClicked: {
                if (callback === undefined) return
                callback[0]()
            }
        }
    }
}
