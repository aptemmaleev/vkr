import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"
import "../Cards"

Page {
    id: root

    property int controlHeight: 50
    property int fromBorderMargin: 28
    property int titleTopMargin: 128

    property var house: undefined

    property var typeToText: {
        "cold_water": "ГВС",
        "hot_water": "ХВС",
        "electricity": "ЭС",
    }


    function update() {
        requestsListModel.clear()
        logic.retrieveRequestsList(house.id)
    }

    Connections {
        target: logic
        function onRequestsListChanged() {
            console.log(logic.requestsList)
            for (var i = 0; i < logic.requestsList.length; i++) {
                requestsListModel.append({"request": logic.requestsList[i]})
            }
        }
    }

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    Flickable {
        id: flickable
        boundsBehavior: Flickable.StopAtBounds
        anchors.fill: parent
        contentHeight: titleText.height + titleTopMargin + requestsColumn.height + 20
        /* Page title */
        TitleText {
            id: titleText
            text: "Список заявок"
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: fromBorderMargin
                topMargin: titleTopMargin
            }
        }

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
            onClicked: housesStackView.pop()
        }

        Column {
            id: requestsColumn
            spacing: 10
            anchors {
                top: titleText.bottom
                left: parent.left
                right: parent.right
                topMargin: 20
                margins: fromBorderMargin
            }

            Repeater {
                id: residentsRepeater

                model: ListModel {
                    id: requestsListModel
                }

                delegate: Card {
                    backgroundBorderWidth: 1
                    backgroundBorderColor: themeSettings.cardBlueColor
                    height: 24 + apartmentTitleText.height + roleText.height + noButton.height + 4
                    anchors {
                        left: parent === null ? undefined : parent.left
                        right: parent === null ? undefined : parent.right
                    }

                    SubTitleText {
                        id: apartmentTitleText
                        text: (model.request.type === "delete" ? "Удаление счетчика " : "Добавление счетчика ") + typeToText[model.request.counterType] + " в кв. " + model.request.apartmentNumber
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                    }

                    RegularText {
                        id: roleText
                        text: "Серийный номер: " + model.request.counterSerial + (model.request.reason !== "" ? "\n" + "Причина: " + model.request.reason : "")
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: apartmentTitleText.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: 12
                            rightMargin: 12
                        }
                    }

                    RectangleButton {
                        id: noButton
                        text: "Отклонить"
                        height: 40
                        width: (parent.width - 32) / 2
                        anchors {
                            top: roleText.bottom
                            left: parent.left
                            leftMargin: 12
                            topMargin: 4
                        }
                        onClicked: {
                            logic.resolveRequest(model.request.id, false)
                            requestsListModel.remove(index, 1)
                        }
                    }

                    RectangleButton {
                        id: yesButton
                        text: "Одобрить"
                        height: 40
                        width: (parent.width - 32) / 2
                        anchors {
                            top: roleText.bottom
                            right: parent.right
                            rightMargin: 12
                            topMargin: 4
                        }
                        onClicked: {
                            logic.resolveRequest(model.request.id, true)
                            requestsListModel.remove(index, 1)
                            if (requestsListModel.count === 0) {
                                housesStackView.pop()
                            }
                        }
                    }
                }
            }
        }
    }
}
