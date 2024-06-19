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
    property var apartment: undefined

    function update() {
        residentsListModel.clear()
        logic.retrieveApartmentResidents(apartment.id)
    }

    Connections {
        target: logic
        function onApartmentResidentsChanged() {
            residentsListModel.clear()
            for (var i = 0; i < logic.apartmentResidents.length; i++) {
                residentsListModel.append({"user": logic.apartmentResidents[i]})
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
        contentHeight: titleText.height + titleTopMargin + buttonsColumn.height + 20 + buttonsColumn.height + 20 + residentsColumn.height + 20
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
                        // Validate email
                        let regex = new RegExp("^(?=.{1,64}@)[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*@[^-][A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$")
                        if (!data[0].match(regex)) {
                            dialogPopup.showError("Указан неправильный адрес электронной почты", () => {dialogPopup.close()})
                            return
                        }
                        var task = logic.changeApartmentOwner(manageApartmentPage.apartment.id, data[0])
                        wrapTask(task, (task) => {
                            if (task.hasError) {
                                dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                            } else {
                                manageApartmentsPage.update()
                                var data = dynamicFormPage.getData()
                                dialogPopup.clear()
                                dialogPopup.title = "Владелец квартиры изменен"
                                dialogPopup.description = "Пользователь " + data[0] + " стал новым владельцем квартиры!"
                                dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop(); housesStackView.pop()})
                                dialogPopup.open()
                            }
                        })
                    })
                    housesStackView.push(dynamicFormPage)
                }
            }

            RectangleButton {
                text: "Добавить жителя"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    dynamicFormPage.clear()
                    dynamicFormPage.pageTitle = "Добавить жителя"
                    dynamicFormPage.pageDescription = "Укажите нового жителя квартиры №" + apartment.number
                    dynamicFormPage.addTextField("Почта")
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addButton("Изменить", () => {
                        // Getting data from form
                        var data = dynamicFormPage.getData()
                        // Validate email
                        let regex = new RegExp("^(?=.{1,64}@)[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*@[^-][A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$")
                        if (!data[0].match(regex)) {
                            dialogPopup.showError("Указан неправильный адрес электронной почты", () => {dialogPopup.close()})
                            return
                        }
                        var task = logic.addResident(manageApartmentPage.apartment.id, data[0])
                        wrapTask(task, (task) => {
                            if (task.hasError) {
                                dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                            } else {
                                manageApartmentPage.update()
                                var data = dynamicFormPage.getData()
                                dialogPopup.clear()
                                dialogPopup.title = "Житель квартиры добавлен"
                                dialogPopup.description = "Пользователь " + data[0] + " стал новым жителем квартиры!"
                                dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                                dialogPopup.open()
                            }
                        })
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
                        var task = logic.deleteApartment(manageApartmentPage.apartment.id)
                        wrapTask(task, (task) => {
                            if (task.hasError) {
                                dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                            } else {
                                manageApartmentsPage.update()
                                dialogPopup.clear()
                                dialogPopup.title = "Квартира удалена"
                                dialogPopup.description = "Квартира с номером " + manageApartmentPage.apartment.number + " удалена!"
                                dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop(); housesStackView.pop()})
                                dialogPopup.open()
                            }
                        })
                    })
                    housesStackView.push(dynamicFormPage)
                }
            }
        }

        Column {
            id: residentsColumn
            spacing: 10
            anchors {
                top: buttonsColumn.bottom
                left: parent.left
                right: parent.right
                topMargin: 20
                margins: fromBorderMargin
            }

            Repeater {
                id: residentsRepeater

                model: ListModel {
                    id: residentsListModel
                }

                delegate: Card {
                    backgroundBorderWidth: 1
                    backgroundBorderColor: model.user.id === apartment.ownerId ? themeSettings.cardPinkColor : themeSettings.cardBlueColor
                    height: 24 + apartmentTitleText.height + roleText.height
                    anchors {
                        left: parent === null ? undefined : parent.left
                        right: parent === null ? undefined : parent.right
                    }

                    SubTitleText {
                        id: apartmentTitleText
                        text: model.user.name + " " + model.user.surname + "\n" + model.user.email
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
                        text: model.user.id === apartment.ownerId ? "Владелец квартиры" : "Житель квартиры"
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: apartmentTitleText.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: 12
                            rightMargin: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressAndHold: {
                            if (model.user.id === manageApartmentPage.apartment.ownerId) {
                                dialogPopup.showError("Вы не можете удалить владельца квартиры", () => {dialogPopup.close();})
                                return
                            }
                            dynamicFormPage.clear()
                            dynamicFormPage.data = []
                            dynamicFormPage.data.push(model.user)
                            dynamicFormPage.data.push(dialogPopup)
                            dynamicFormPage.data.push(housesStackView)
                            dynamicFormPage.pageTitle = "Удалить жителя"
                            dynamicFormPage.pageDescription = "Удаление " + model.user.name + " " + model.user.surname +  " из квартиры №" + apartment.number
                            dynamicFormPage.addSpacing()
                            dynamicFormPage.addSpacing()
                            dynamicFormPage.addButton("Удалить", () => {
                                var task = logic.deleteResident(manageApartmentPage.apartment.id, dynamicFormPage.data[0].id)
                                wrapTask(task, (task) => {
                                    var dialogPopup = dynamicFormPage.data[1]
                                    var housesStackView = dynamicFormPage.data[2]
                                    var user = dynamicFormPage.data[0]
                                    console.log(dialogPopup)
                                    if (task.hasError) {
                                        dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                                    } else {
                                        manageApartmentPage.update()
                                        dialogPopup.clear()
                                        dialogPopup.title = "Житель квартиры удален"
                                        dialogPopup.description = "Пользователь " + user.name + " " + user.surname + " удален из квартиры"
                                        dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                                        dialogPopup.open()
                                    }
                                })
                            })
                            housesStackView.push(dynamicFormPage)
                        }
                    }
                }
            }
        }
    }
}
