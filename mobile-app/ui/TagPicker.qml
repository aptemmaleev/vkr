import QtQuick 2.0
import QtQuick.Controls 2.15

import "../ui/Texts"


Item {
    id: tagPicker

    property alias categoryCheckBoxRepeater: categoryCheckBoxRepeater
    property alias categoryListModel: categoryListModel

    property string categoryName: ""

    property bool singleChecked: false
    property int buttonsTopMargin: 10
    property int standardMargin: 10
    property int betweenElementsMargin: 4

    height: categoryText.height + betweenElementsMargin + flow.implicitHeight

    signal checkedChanged()

    function getChecked() {
        let checkedTags = []
        flow.children.forEach(child => {
            if (child !== categoryCheckBoxRepeater) {
                if (child.isChecked()) checkedTags.push(child.getName())
            }
        })
        return checkedTags
    }

    function setChecked(name, checked) {
        flow.children.forEach(child => {
            if (child !== categoryCheckBoxRepeater) {
                if (child.getName() === name) child.checked = checked
            }
        })
    }

    RegularText {
        id: categoryText
        font.bold: true
        text: categoryName
        anchors {
            top: parent.top
            left: parent.left
        }
    }

    Flow {
        id: flow
        spacing: 5
        height: flow.implicitHeight

        anchors {
            top: categoryText.bottom
            left: parent.left
            right: parent.right
            topMargin: betweenElementsMargin
        }

        Repeater {
            id: categoryCheckBoxRepeater

            model: ListModel {
                id: categoryListModel
            }

            delegate: Item {
                id: categoryCheckBox

                function isChecked() {
                    return checked
                }

                function getName() {
                    return model.name
                }

                property bool checked: singleChecked ? (index === 0 ? true : false) : true
                height: externalRectangle.height
                width: externalRectangle.width + 5 + checkBoxText.implicitWidth

                Rectangle {
                    id: externalRectangle
                    radius: 6
                    height: 20
                    width: 20
                    color: themeSettings.backgroundColor
                    border.color: themeSettings.accentColor
                    border.width: 1
                    anchors {
                        top: parent.top
                        left: parent.left
                        bottom: parent.bottom
                    }
                }

                Rectangle {
                    id: internalRectangle
                    visible: (parent.checked)
                    radius: 4
                    height: 14
                    width: 14
                    color: themeSettings.accentColor
                    anchors.centerIn: externalRectangle
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (parent.checked === false) {
                            parent.checked = true

                            if (tagPicker.singleChecked) {
                                flow.children.forEach(child => {
                                    if (child !== categoryCheckBoxRepeater && child !== parent) {
                                        child.checked = false
                                    }
                                })
                            }

                            tagPicker.checkedChanged()
                            return
                        }
                        if (!tagPicker.singleChecked) {
                            parent.checked = false
                            tagPicker.checkedChanged()
                        }
                    }
                }

                RegularText {
                    id: checkBoxText
                    text: model.name
                    anchors {
                        left: externalRectangle.right
                        right: parent.right
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
