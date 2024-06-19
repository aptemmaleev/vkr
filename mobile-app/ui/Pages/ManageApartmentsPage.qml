import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"
import "../Images"
import "../Cards"

Page {
    id: root

    readonly property int fromBorderMargin: 28
    readonly property int titleTopMargin: 128
    property int itemsSpacing: 8
    property int betweenTagsSpacing: 8
    property int standardMargin: 10
    property int betweenCardsSpacing: 16
    property var house: undefined

    Connections {
        target: logic

        function onHouseApartmentsListChanged() {
            apartmentsListModel.clear()
            for (let i = 0; i < logic.houseApartmentsList.length; i++) {
                var apartment = logic.houseApartmentsList[i]
                apartmentsListModel.append({"name": "Квартира №" + apartment.number, "address": "(подъезд: " + apartment.entrance + ", этаж: " + apartment.floor + ")", "apartment": apartment})
            }
        }
    }

    function update() {
        apartmentsListModel.clear()
        logic.retrieveHouseApartmentList(house.id)
    }

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
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

    /* Page Title */
    TitleText {
        id: titleText
        opacity: 1
        text: "Квартиры в доме"
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: fromBorderMargin
            topMargin: titleTopMargin
        }
    }

    /* Address filter */
    RegularText {
        id: addressText
        text: house === undefined ? "" : house.address
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

    /* Add reading button */
    RectangleButton {
        id: addApartmentButton
        height: 50
        text: "Добавить квартиру"
        anchors {
            top: addressText.bottom
            left: parent.left
            right: parent.right
            margins: fromBorderMargin
            topMargin: standardMargin
        }
        onClicked:{
            dynamicFormPage.clear()
            dynamicFormPage.data = []
            dynamicFormPage.pageTitle = "Добавить квартиру"
            dynamicFormPage.pageDescription = "Укажите электронную почту владельца, подъезд, этаж и номер для создания новой квартиры"
            dynamicFormPage.addTextField("Почта владельца")
            dynamicFormPage.addSpacing()
            dynamicFormPage.addTextField("Подъезд")
            dynamicFormPage.addSpacing()
            dynamicFormPage.addTextField("Этаж")
            dynamicFormPage.addSpacing()
            dynamicFormPage.addTextField("Номер квартиры")
            dynamicFormPage.addSpacing()
            dynamicFormPage.addSpacing()
            dynamicFormPage.addButton("Добавить", () => {
                // Getting data from form
                var data = dynamicFormPage.getData()
                var ownerEmail = data[0]
                var entrance = data[1]
                var floor = data[2]
                var number = data[3]
                // Validate email
                let regex = new RegExp("^(?=.{1,64}@)[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*@[^-][A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$")
                if (!ownerEmail.match(regex)) {
                    dialogPopup.showError("Неправильно введена почта", () => {dialogPopup.close()})
                    return
                }
                // Validate entrance
                regex = new RegExp("[0-9]{1,2}")
                if (!entrance.match(regex)) {
                    dialogPopup.showError("Номер подъезда не должен превышать число 99", () => {dialogPopup.close()})
                    return
                }
                // Validate number
                regex = new RegExp("[0-9]{1,3}")
                if (!floor.match(regex)) {
                    dialogPopup.showError("Номер этажа не должен превышать число 999", () => {dialogPopup.close()})
                    return
                }
                // Validate number
                regex = new RegExp("[0-9]{1,3}")
                if (!number.match(regex)) {
                    dialogPopup.showError("Номер квартиры не должен превышать число 999", () => {dialogPopup.close()})
                    return
                }
                entrance = parseInt(data[1])
                floor = parseInt(data[2])
                number = parseInt(data[3])
                dynamicFormPage.data.push(data)

                var task = logic.createApartment(manageHousePage.house.id, data[0], entrance, number, floor)
                wrapTask(task, (task) => {
                    var data = dynamicFormPage.data[0]
                    if (task.hasError) {
                        dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                    } else {
                        logic.retrieveHouseApartmentList(manageHousePage.house.id)
                        dialogPopup.clear()
                        dialogPopup.title = "Квартира добавлена"
                        dialogPopup.description = "Квартира №" + data[3] + " была добавлена в дом по адресу " + manageHousePage.house.address
                        dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                        dialogPopup.open()
                    }
                })
            })
            housesStackView.push(dynamicFormPage)
        }
    }

    /* Apartments List Model */
    ListModel {
        id: apartmentsListModel
    }

    /* Apartments List View */
    ListView {
        id: apartmentsListView
        clip: true
        topMargin: 8
        bottomMargin: 8
        spacing: betweenCardsSpacing
        boundsBehavior: Flickable.StopAtBounds
        model: apartmentsListModel

        anchors {
            top: addApartmentButton.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: standardMargin
        }

        delegate: Card {
            backgroundBorderWidth: 1
            backgroundBorderColor: themeSettings.cardBlueColor
            height: 24 + apartmentTitleText.height + standardMargin - 4 + manageButton.height
            anchors {
                left: parent === null ? undefined : parent.left
                right: parent === null ? undefined : parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }

            SubTitleText {
                id: apartmentTitleText
                text: model.name + " " + model.address
                horizontalAlignment: Text.AlignLeft
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: 12
                }
            }

            RectangleButton {
                id: manageButton
                height: 40
                text: "Управление"
                anchors {
                    top: apartmentTitleText.bottom
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: standardMargin - 4
                }
                onClicked: {
                    manageApartmentPage.house = house
                    manageApartmentPage.apartment = model.apartment
                    manageApartmentPage.update()
                    housesStackView.push(manageApartmentPage)
                }
            }
        }
    }
}
