import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"
import "../Cards"
import "../Images"
import "../../ui"

Page {
    id: root

    readonly property int fromBorderMargin: 28
    readonly property int titleTopMargin: 128

    property int cardTagHeight: 22
    property int itemsSpacing: 8
    property int betweenTagsSpacing: 8
    property int standardMargin: 10
    property int betweenCardsSpacing: 16
    property int cardFromBorderMargin: 12

    property var house: undefined

    property var typeToIcons: {
        "hot_water": "qrc:/images/counters/hot_water.svg",
        "cold_water": "qrc:/images/counters/cold_water.svg",
        "electricity": "qrc:/images/counters/electricity.svg",
    }

    ListModel {
        id: apartmentsListModel
    }

    function update() {
        countersListModel.clear()
        addressFilterText.text = houseTagPicker.getChecked()[0]
        let apartment = logic.getApartmentByAddress(addressFilterText.text)
        let apartmentId = apartment.id;
        root.house = logic.getHouseById(apartment.houseId)
        logic.retrieveCountersList(apartmentId);
    }

    function getWordMonthForm(month) {
        switch (month) {
            case 1: return "января"
            case 2: return "февраля"
            case 3: return "марта"
            case 4: return "апреля"
            case 5: return "мая"
            case 6: return "июня"
            case 7: return "июля"
            case 8: return "августа"
            case 9: return "сентября"
            case 10: return "октября"
            case 11: return "ноября"
            case 12: return "декабря"
            default: return "неверный месяц"
        }
    }

    function getWordDayForm(day) {
        if (day > 10) return "дней"
        if (day === 1) {
            return "день";
        } else if (day === 2 || day === 3 || day === 4) {
            return "дня";
        } else {
            return "дней";
        }
    }

    Connections {
        target: logic

        function onApartmentsListChanged() {
            houseTagPicker.categoryListModel.clear()
            for (let i = 0; i < logic.apartmentsAddresses.length; i++) {
                if (i === 0) {
                    addressFilterText.text = logic.apartmentsAddresses[i]
                }
                houseTagPicker.categoryListModel.append({"name": logic.apartmentsAddresses[i]})
            }
            houseTagPicker.categoryCheckBoxRepeater.update()
            root.update()
        }

        function onCountersListChanged() {
            var currentDate = new Date()
            var currentDay = currentDate.getDate()
            var currentMonth = currentDate.getMonth() + 1
            var daysDiff = house.end
            var description = ""
            var daysLeft = ""

            // console.log(currentDay.day, currentMonth.m)
            console.log(currentDate, currentDay, currentMonth)

            countersListModel.clear()
            for (let i = 0; i < logic.countersList.length; i++) {
                let counter = logic.countersList[i]
                let overdue = false
                let notStarted = false

                if (counter.hasReading) {
                    description = "Показания в этом месяце поданы"
                } else {
                    if (currentDay < house.startReadingDay) {
                        daysDiff = house.startReadingDay - currentDay
                        daysLeft = "Через " + daysDiff + " " + getWordDayForm(daysDiff)
                        description = "Сбор покананий начнется через " + daysDiff + " " + getWordDayForm(daysDiff);
                        notStarted = true
                    } else if (currentDay >= house.startReadingDay && currentDay <= house.endReadingDay) {
                        daysDiff = house.endReadingDay - currentDay
                        daysLeft = "Осталось " + daysDiff + " " + getWordDayForm(daysDiff)
                        description = "Необходимо внести показания на этот месяц"
                    } else {
                        description = "Вы просрочили внесение показаний в этом месяце"
                        overdue = true
                    }
                }

                daysDiff = house.endReadingDay - currentDay

                countersListModel.append({
                    "icon": typeToIcons[counter.type],
                    "name": counter.name,
                    "description": description,
                    "endDate": house.endReadingDay + " " + getWordMonthForm(currentMonth),
                    "daysLeft": daysLeft,
                    "hasReading": counter.hasReading,
                    "overdue": overdue,
                    "notStarted": notStarted,
                    "counter": counter
                })
            }
        }
    }

    Connections {
        target: houseTagPicker

        function onCheckedChanged() {
            root.update()
        }
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
        contentHeight: titleTopMargin + title.height + addressFilterText.height + countersColumn.height + standardMargin * 2

        /* Page Title */
        TitleText {
            id: title
            text: "Счетчики"
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: fromBorderMargin
                topMargin: titleTopMargin
            }
        }

        /* Settings Button */
        IconButton {
            id: addButton
            buttonSize: 30
            imageColor: themeSettings.primaryColor
            imageSource: "qrc:/images/add.svg"
            anchors {
                right: parent.right
                rightMargin: fromBorderMargin
                verticalCenter: title.verticalCenter
            }
            onClicked: {
                dynamicFormPage.setActive(false)
                dynamicFormPage.clear()
                dynamicFormPage.pageTitle = "Добавление счетчика"
                dynamicFormPage.pageDescription = "Укажите информацию об установленном в вашей квартире приборе учета"
                dynamicFormPage.addComboBox("Тип счетчика", ["Горячее водоснабжение", "Холодное водоснабжение", "Электричество"])
                dynamicFormPage.addTextField("Имя счетчика")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addTextField("Серийный номер")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addTextFieldFloat("Начальное значение")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addSpacing()
                dynamicFormPage.addButton("Добавить", () => {
                    // Getting data from form
                    var data = dynamicFormPage.getData()
                    // Checking for data length
                    if (data[1].length < 3 || data[1].length > 24) {
                        dialogPopup.showError("Название счетчика должно быть от 3 до 24 символов", () => {dialogPopup.close()})
                        return
                    }
                    if (data[2].length < 3 || data[2].length > 16) {
                        dialogPopup.showError("Серийный номер счетчика должен быть от 3 до 16 символов", () => {dialogPopup.close()})
                        return
                    }
                    let regex = new RegExp("^\\d+(\\.(\\d{1})?)?$")
                    if (data[3].length === 0 || !data[3].match(regex)) {
                        dialogPopup.showError("Необходимо ввести корректное начально значение счетчика", () => {dialogPopup.close()})
                        return
                    }
                    let apartmentId = logic.getApartmentByAddress(addressFilterText.text).id;
                    let type = ""
                    if (data[0] === "Горячее водоснабжение") type = "hot_water"
                    if (data[0] === "Холодное водоснабжение") type = "cold_water"
                    if (data[0] === "Электричество") type = "electricity"
                    var task = logic.createCounter(apartmentId, data[2], type, data[1], parseFloat(data[3]))
                    wrapTask(task, (task, apartmentId) => {
                        console.log(apartmentId)
                        if (task.hasError) {
                            dialogPopup.showError(task.error, () => {dialogPopup.close(); countersStackView.pop()})
                        } else {
                            countersPage.update()
                            dialogPopup.clear()
                            dialogPopup.title = "Счетчик добавлен"
                            dialogPopup.description = "Счетчик \"" + data[0] + "\"" + " с заводским номером " + data[1] + " успешно добавлен!"
                            dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); countersStackView.pop()})
                            dialogPopup.open()
                        }
                    })
                })
                countersStackView.push(dynamicFormPage)
            }
        }

        /* Address filter */
        RegularText {
            id: addressFilterText
            text: ""
            horizontalAlignment: Text.AlignLeft
            color: themeSettings.accentColor
            opacity: addressFilterMouseArea.pressed ? 0.3 : 0.5
            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }

            MouseArea {
                id: addressFilterMouseArea
                anchors.fill: parent
                onClicked: apartmentsDrawer.open()
            }
        }

        /* Cards Column */
        Column {
            id: countersColumn
            spacing: betweenCardsSpacing
            anchors {
                top: addressFilterText.bottom
                left: parent.left
                right: parent.right
                topMargin: standardMargin
            }

            ListModel {
                id: countersListModel
            }

            Repeater {
                model: countersListModel

                delegate: Card {
                    backgroundBorderColor: overdue ? themeSettings.cardPinkColor : notStarted ? themeSettings.cardBlueColor : themeSettings.warningColor
                    backgroundBorderWidth: model.hasReading ? 0 : 1
                    opacity: cardMouseArea.pressed ? 0.9 : 1

                    height: cardFromBorderMargin * 2 + (model.hasReading ? 0 : cardHeader.height + (standardMargin - 4)) + cardTitleText.height + cardAddressText.height
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: fromBorderMargin
                        rightMargin: fromBorderMargin
                    }

                    Item {
                        id: cardHeader
                        visible: !model.hasReading
                        height: cardHeaderRow.implicitHeight
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            topMargin: cardFromBorderMargin
                            leftMargin: cardFromBorderMargin
                        }

                        Row {
                            id: cardHeaderRow
                            spacing: itemsSpacing

                            Rectangle {
                                id: cardHeaderTag
                                color: overdue ? themeSettings.cardPinkColor : notStarted ? themeSettings.cardBlueColor : themeSettings.warningColor
                                height: cardTagHeight
                                width: cardHeaderTagText.implicitWidth + itemsSpacing * 2
                                radius: height / 2

                                CaptionText {
                                    id: cardHeaderTagText
                                    text: overdue ? "Просрочено" : daysLeft
                                    color: themeSettings.backgroundColor
                                    anchors {
                                        left: parent.left
                                        leftMargin: itemsSpacing
                                        verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            CaptionText {
                                id: cardHeaderDateText
                                opacity: 0.5
                                text: "до " + model.endDate
                                color: themeSettings.primaryColor
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    ColorlessSvgImage {
                        id: cardIcon
                        height: 38
                        width: 38
                        imageSource: model.icon
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: cardFromBorderMargin
                        }
                    }

                    SubTitleText {
                        id: cardTitleText
                        text: model.name
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: model.hasReading ? parent.top : cardHeader.bottom
                            left: parent.left
                            right: parent.right
                            margins: cardFromBorderMargin
                            topMargin: model.hasReading ? cardFromBorderMargin : standardMargin - 4
                        }
                    }

                    RegularText {
                        id: cardAddressText
                        text: model.description
                        horizontalAlignment: Text.AlignJustify
                        anchors {
                            top: cardTitleText.bottom
                            left: parent.left
                            right: parent.right
                            margins: cardFromBorderMargin
                            topMargin: 0
                        }
                    }

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        onClicked: {
                            counterPage.house = root.house
                            counterPage.counter = model.counter
                            counterPage.apartmentAddress = addressFilterText.text
                            countersStackView.push(counterPage)
                        }

                        onPressAndHold: {
                            dynamicFormPage.clear()
                            dynamicFormPage.pageTitle = "Удаление счетчика"
                            dynamicFormPage.pageDescription = "Вы действительно хотите удалить счетчик?"
                            dynamicFormPage.addSpacing()
                            dynamicFormPage.addSpacing()
                            var counterId = model.counter.id
                            dynamicFormPage.data.push(counterId)
                            dynamicFormPage.data.push(dialogPopup)
                            dynamicFormPage.data.push(countersStackView)
                            dynamicFormPage.addButton("Удалить", (counterId) => {
                                var task = logic.deleteCounter(dynamicFormPage.data[0])
                                wrapTask(task, (task) => {
                                    var dialogPopup = dynamicFormPage.data[1]
                                    var countersStackView = dynamicFormPage.data[2]
                                    if (task.hasError) {
                                        dialogPopup.showError(task.error, () => {dialogPopup.close(); countersStackView.pop()})
                                    } else {
                                        countersPage.update()
                                        dialogPopup.clear()
                                        dialogPopup.title = "Счетчик удален"
                                        dialogPopup.description = ""
                                        dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); countersStackView.pop()})
                                        dialogPopup.open()
                                    }
                                })
                            })
                            countersStackView.push(dynamicFormPage)
                        }
                    }
                }
            }
        }
    }

    /* Apartments picker */
    Drawer {
        id: apartmentsDrawer

        edge: Qt.BottomEdge
        height: 160
        width: parent.width

        closePolicy: Popup.CloseOnReleaseOutside
        dragMargin: 0
        Material.theme: Material.Light

        background: Rectangle {
            anchors.fill: parent
            radius: 20
            color: themeSettings.panelsColor
            Rectangle {
                height: 4
                width: 40
                color: themeSettings.primaryColor
                opacity: 0.5
                anchors {
                    top: parent.top
                    topMargin: 15
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                height: parent.radius
                color: parent.color
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
            }
        }

        TagPicker {
            id: houseTagPicker
            singleChecked: true
            categoryName: "Квартира:"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 40
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }
        }
    }
}
