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

    property var house: undefined

    onHouseChanged: {
        console.log("house changed")
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
        contentHeight: titleTopMargin + title.height + addressText.height

        IconButton {
            id: backButton
            buttonSize: 32
            imageColor: themeSettings.primaryColor
            imageSource: "qrc:/images/navigation/back.svg"
            anchors {
                left: parent.left
                bottom: title.top
                leftMargin: fromBorderMargin - 4
                bottomMargin: 30
            }
            onClicked: housesStackView.pop()
        }

        /* Page Title */
        TitleText {
            id: title
            text: "Управление домом"
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
                top: title.bottom
                left: parent.left
                right: parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }
        }

        /* Buttons column */
        Column {
            id: buttonsColumn
            spacing: 12
            anchors {
                top: addressText.bottom
                left: parent.left
                right: parent.right
                topMargin: 20
                margins: fromBorderMargin
            }

            RectangleButton {
                text: "Редактировать описание"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    dynamicFormPage.clear()
                    dynamicFormPage.data = []
                    dynamicFormPage.data.push(house)
                    dynamicFormPage.pageTitle = "Изменение описания"
                    dynamicFormPage.pageDescription = "Укажите описание для дома по адресу " + house.address
                    dynamicFormPage.addTextArea("Описание", house.info,  400)
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addButton("Изменить", () => {
                        // Getting data from form
                        var data = dynamicFormPage.getData()
                        // Checking for data length
                        if (data[0].length === 0) {
                            dialogPopup.showError("Описание не может быть пустым")
                            return
                        }
                        if (data[0].length > 500) {
                            dialogPopup.showError("Описание не может быть больше 500 символов")
                            return
                        }

                        var task = logic.changeHouse(manageHousePage.house.id, data[0])
                        wrapTask(task, (task) => {
                            var house = dynamicFormPage.data[0]
                            if (task.hasError) {
                                dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                            } else {
                                logic.retrieveHousesList()
                                dialogPopup.clear()
                                dialogPopup.title = "Описание дома изменено!"
                                dialogPopup.description = "Установлено новое описание для дома " + house.address + "."
                                dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                                dialogPopup.open()
                            }
                        })
                    })
                    housesStackView.push(dynamicFormPage)
                }
            }

            RectangleButton {
                text: "Создать уведомление"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    dynamicFormPage.clear()
                    dynamicFormPage.pageTitle = "Создание события"
                    dynamicFormPage.pageDescription = "Укажите тип, название и описание события"
                    dynamicFormPage.addComboBox("Тип события", ["Уведомление", "Новость"])
                    dynamicFormPage.addTextField("Название события")
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addTextArea("Описание события", "", 240)
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addButton("Создать", () => {
                        // Getting data from form
                        var data = dynamicFormPage.getData()
                        // Checking for data length
                        if (data[1].length < 3 || data[1].length > 32) {
                            dialogPopup.showError("Название события должно быть от 3 до 32 символов")
                            return
                        }
                        if (data[2].length === 0) {
                            dialogPopup.showError("Описание события не может быть пустым")
                            return
                        }
                        if (data[2].length > 128) {
                            dialogPopup.showError("Описание события не может быть больше 128 символов")
                            return
                        }
                        var type = ""
                        if (data[0] === "Уведомление") type = "notification"
                        if (data[0] === "Новость") type = "news"
                        var task = logic.createEvent(manageHousePage.house.id, type, data[1], data[2])
                        wrapTask(task, (task) => {
                            var house = dynamicFormPage.data[0]
                            if (task.hasError) {
                                dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                            } else {
                                logic.retrieveEventsList()
                                dialogPopup.clear()
                                dialogPopup.title = "Событие создано!"
                                dialogPopup.description = "Событие создано и разослано всем жителям дома " + manageHousePage.house.address + "."
                                dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                                dialogPopup.open()
                            }
                        })
                    })
                    housesStackView.push(dynamicFormPage)
                }
            }

            RectangleButton {
                text: "Указать дату показаний"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    dynamicFormPage.clear()
                    dynamicFormPage.pageTitle = "Дата показаний"
                    dynamicFormPage.pageDescription = "Укажите с какого по какое число каждого месяца собирать показания ИПУ"
                    var fromTexts = []
                    var toTexts = []
                    for (var i = 1; i < 31; i++) {
                        fromTexts.push("Начинать сбор с " + i + " числа")
                        toTexts.push("Заканчивать сбор " + i +" числа")
                    }

                    dynamicFormPage.addComboBox("", fromTexts, house.startReadingDay - 1)
                    dynamicFormPage.addComboBox("", toTexts, house.endReadingDay - 1)
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addSpacing()
                    dynamicFormPage.addButton("Установить", () => {
                        dynamicFormPage.data = []
                        // Getting data from form
                        var data = dynamicFormPage.getData()
                        var first = parseInt(data[0].split(' ')[3])
                        var second = parseInt(data[1].split(' ')[2])
                        dynamicFormPage.data.push(manageHousePage.house)
                        dynamicFormPage.data.push(first)
                        dynamicFormPage.data.push(second)
                        // Checking for right range
                        if (first > second) {
                            dialogPopup.showError("Последний день сбора показаний не может быть раньше начала", () => {dialogPopup.close()})
                            return
                        }
                        var task = logic.changeHouse(manageHousePage.house.id, "", first, second)
                        wrapTask(task, (task) => {
                            var house = dynamicFormPage.data[0]
                            var first = dynamicFormPage.data[1]
                            var second = dynamicFormPage.data[2]
                            if (task.hasError) {
                                dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                            } else {
                                logic.retrieveHousesList()
                                countersPage.update()
                                dialogPopup.clear()
                                dialogPopup.title = "Дни сбора установлены!"
                                dialogPopup.description = "Сбор показаний будет производиться с " + first + " по " + second + " число каждого месяца"
                                dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); housesStackView.pop()})
                                dialogPopup.open()
                            }
                        })
                    })
                    housesStackView.push(dynamicFormPage)
                }
            }

            RectangleButton {
                text: "Экспорт показаний"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    exportTablePage.house = house
                    housesStackView.push(exportTablePage)
                }
            }

            RectangleButton {
                text: "Список квартир"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    manageApartmentsPage.house = house
                    manageApartmentsPage.update()
                    housesStackView.push(manageApartmentsPage)
                }
            }

            RectangleButton {
                text: "Заявки по счетчикам"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    manageRequestsPage.house = house
                    manageRequestsPage.update()
                    housesStackView.push(manageRequestsPage)
                }
            }
        }
    }
}
