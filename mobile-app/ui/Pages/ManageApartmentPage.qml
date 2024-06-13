import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"

Page {
    id: root

    property int controlHeight: 50
    property int fromBorderMargin: 28
    property int titleTopMargin: 128

    property var house: undefined
    property var apartment: undefined

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page title */
    TitleText {
        id: titleText
        text: apartment === undefined ? "" : "Квартира №" + apartment.number
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

    /* Buttons column */
    Column {
        id: buttonsColumn
        spacing: 12
        anchors {
            top: titleText.bottom
            left: parent.left
            right: parent.right
            topMargin: 20
            margins: fromBorderMargin
        }

        RectangleButton {
            text: "Изменить владельца"
            height: controlHeight

            anchors {
                left: parent.left
                right: parent.right
            }

            onClicked: {
                dynamicFormPage.clear()
                dynamicFormPage.pageTitle = "Владелец квартиры"
                dynamicFormPage.pageDescription = "Укажите нового владельца квартиры №" + apartment.number
                dynamicFormPage.addTextField("Почта")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addSpacing()
                dynamicFormPage.addButton("Изменить", () => {
                    // Getting data from form
                    var data = dynamicFormPage.getData()
                    // Dialog if counter added
                    dialogPopup.clear()
                    dialogPopup.title = "Владелец квартиры изменен"
                    dialogPopup.description = "Пользователь " + data[0] + " стал новым владельцем квартиры!"
                    dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                    dialogPopup.open()
                })
                housesStackView.push(dynamicFormPage)
            }
        }

        RectangleButton {
            text: "Удалить квартиру"
            height: controlHeight

            anchors {
                left: parent.left
                right: parent.right
            }

            onClicked: {
                dynamicFormPage.clear()
                dynamicFormPage.pageTitle = "Удаление квартиры"
                dynamicFormPage.pageDescription = "Подтвердите удаление"
                dynamicFormPage.addButton("Удалить", () => {
                    // Dialog if counter added
                    dialogPopup.clear()
                    dialogPopup.title = "Квартира удалена"
                    dialogPopup.description = "Квартира с новмером " + apartment.number + " удалена!"
                    dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop(); housesStackView.pop()})
                    dialogPopup.open()
                })
                housesStackView.push(dynamicFormPage)
            }
        }
    }
}
