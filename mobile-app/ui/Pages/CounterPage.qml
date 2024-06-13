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
    property var counter: undefined
    property string apartmentAddress: ""

    property var typeToUnit: {
        "cold_water": "куб. м.",
        "hot_water": "куб. м.",
        "electricity": "кВт·ч",
    }

    onCounterChanged: {
        update()
    }

    function update() {
        if (counter === undefined) return
        readingsListModel.clear()
        logic.retrieveReadingsList(counter.id)
    }

    function averageConsumption(days) {
        var count = 0
        var summ = 0

        var i = logic.readingsList.length - 2
        while(i >= 0 && days > 0) {
            summ += logic.readingsList[i].value - logic.readingsList[i + 1].value
            count += 1
            days -= 1
            i -= 1
            console.log(count, summ)
        }

        console.log(count, summ)

        if (count === 0) return 0
        return (summ / count).toFixed(1)
    }

    Connections {
        target: logic

        function onReadingsListChanged() {
            for (let i = 0; i < logic.readingsList.length; i++) {
                var reading = logic.readingsList[i]
                readingsListModel.append({
                                             "date": new Date(reading.createdAt).toLocaleDateString(Qt.locale("ru_RU")).split(", ")[1],
                                             "value": reading.value.toFixed(1) + " " + typeToUnit[counter.type],
                                             "author": "Александр Л.",
                                             "reading": reading})
            }

            console.log(averageConsumption(3))
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
        height: contentHeight > parent.height ? parent.height : contentHeight
        contentHeight: titleTopMargin + title.height + addressText.height + addReadingButton.height + standardMargin * 4 + countersColumn.implicitHeight
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

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
            onClicked: countersStackView.pop()
        }

        /* Page Title */
        TitleText {
            id: title
            text: counter === undefined ? "" : counter.name
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
            text: apartmentAddress
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

        /* Add reading button */
        RectangleButton {
            id: addReadingButton
            height: controlHeight
            text: "Внести показания"
            anchors {
                top: addressText.bottom
                left: parent.left
                right: parent.right
                margins: fromBorderMargin
                topMargin: standardMargin
            }
            onClicked: {
                if (counter.hasReading) {
                    dialogPopup.showError("Вы уже внесли показания в этом месяце. Удалите предыдущее значение, чтобы добавить новое", () => {dialogPopup.close()})
                    return
                }
                addReadingsDrawer.open()
            }
        }

        /* Cards Column */
        Column {
            id: countersColumn
            spacing: itemsSpacing
            anchors {
                top: addReadingButton.bottom
                left: parent.left
                right: parent.right
                topMargin: standardMargin
            }

            ListModel {
                id: readingsListModel
            }

            Repeater {
                model: readingsListModel

                delegate: Card {
                    height: cardFromBorderMargin * 2 + cardTitleText.height + cardValueText.height + cardAuthorText.height
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: fromBorderMargin
                        rightMargin: fromBorderMargin
                    }

                    SubTitleText {
                        id: cardTitleText
                        text: model.date
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: cardFromBorderMargin
                            topMargin: cardFromBorderMargin
                        }
                    }

                    IconButton {
                        id: deleteReadingButton
                        visible: model.reading.year === new Date().getFullYear() && model.reading.month === (new Date().getMonth() + 1)
                        buttonSize: 12
                        iconPadding: 0
                        imageColor: themeSettings.primaryColor
                        imageSource: "qrc:/images/close.svg"
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: cardFromBorderMargin
                        }
                        onClicked: {
                            dynamicFormPage.clear()
                            dynamicFormPage.data.push(reading)
                            dynamicFormPage.data.push(dialogPopup)
                            dynamicFormPage.data.push(countersStackView)
                            dynamicFormPage.pageTitle = "Предупреждение"
                            dynamicFormPage.pageDescription = "Вы действительно хотите удалить значение из стории показаний?"
                            dynamicFormPage.addSpacing()
                            dynamicFormPage.addButton("Продолжить", () => {
                                var task = logic.deleteCounterReading(dynamicFormPage.data[0].id)
                                wrapTask(task, (task) => {
                                    var dialogPopup = dynamicFormPage.data[1]
                                    var countersStackView = dynamicFormPage.data[2]
                                    if (task.hasError) {
                                        dialogPopup.showError(task.error, () => {dialogPopup.close(); countersStackView.pop()})
                                    } else {
                                        countersPage.update()
                                        dialogPopup.clear()
                                        dialogPopup.title = "Значение удалено"
                                        dialogPopup.description = "Значение " + dynamicFormPage.data[0].value.toFixed(1) + " удалено из истории показаний!"
                                        dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); countersStackView.pop(); countersStackView.pop()})
                                        dialogPopup.open()
                                    }
                                })
                            })
                            countersStackView.push(dynamicFormPage)
                        }
                    }

                    RegularText {
                        id: cardValueText
                        text: "Значение: " + model.value
                        horizontalAlignment: Text.AlignJustify
                        anchors {
                            top: cardTitleText.bottom
                            left: parent.left
                            right: parent.right
                            margins: cardFromBorderMargin
                            topMargin: 0
                        }
                    }
                    RegularText {
                        id: cardAuthorText
                        text: "Внесено: " + model.author
                        horizontalAlignment: Text.AlignJustify
                        anchors {
                            top: cardValueText.bottom
                            left: parent.left
                            right: parent.right
                            margins: cardFromBorderMargin
                            topMargin: 0
                        }
                    }
                }
            }
        }
    }

    /* Apartments picker */
    Drawer {
        id: addReadingsDrawer

        edge: Qt.BottomEdge
        height: 600
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

        ColorlessSvgImage {
            id: counterTypeIcon
            height: 32
            width: height
            imageSource: "qrc:/images/counters/hot_water.svg"

            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: fromBorderMargin
            }
        }

        SubTitleText {
            id: counterTypeText
            text: "Горячее водоснабжение"
            anchors {
                left: counterTypeIcon.right
                bottom: counterTypeIcon.bottom
                leftMargin: itemsSpacing
            }
        }

        Column {
            id: counterParamsColumn
            anchors {
                top: counterTypeText.bottom
                left: parent.left
                right: parent.right
                margins: fromBorderMargin
                topMargin: standardMargin
            }

            Item {
                height: counterNumberText.height
                anchors {
                    left: parent.left
                    right: parent.right
                }

                RegularText {
                    id: counterNumberText
                    text: "Номер счетчика:"
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                }

                RegularText {
                    text: counter === undefined ? "" : counter.serialNumber
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                }
            }

            Item {
                height: counterAvgConsumptionText.height
                anchors {
                    left: parent.left
                    right: parent.right
                }

                RegularText {
                    id: counterAvgConsumptionText
                    text: "Средний расход:"
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                }

                RegularText {
                    text: counter === undefined ? "" : averageConsumption(3) + " " + typeToUnit[counter.type] + "/мес."
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                }
            }

            Item {
                height: deadlineDateText.height
                anchors {
                    left: parent.left
                    right: parent.right
                }

                RegularText {
                    id: deadlineDateText
                    text: "Внесение показаний:"
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                }

                RegularText {
                    text: house === undefined ? "" : "до " + house.endReadingDay + " " + countersPage.getWordMonthForm(new Date().getMonth() + 1)
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                }
            }

            Item {
                height: lastReadingsValueText.height
                anchors {
                    left: parent.left
                    right: parent.right
                }

                RegularText {
                    id: lastReadingsValueText
                    text: "Предыдущие показания:"
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                }

                RegularText {
                    text: logic.readingsList.length === 0 ? "" : logic.readingsList[0].value.toFixed(1) + " " + typeToUnit[counter.type]
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                }
            }
        }

        SubTitleText {
            id: currentReadingText
            text: "Текущие показания:"
            anchors {
                top: counterParamsColumn.bottom
                left: parent.left
                topMargin: standardMargin * 2
                leftMargin: fromBorderMargin
            }
        }

        TextField {
            id: currentReadingsTextField
            placeholderText: "Текущее значение"
            property string previousText: ""
            anchors {
                top: currentReadingText.bottom
                left: parent.left
                right: parent.right
                margins: fromBorderMargin
                topMargin: itemsSpacing
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

        RectangleButton {
            id: addCurrentReadingButton
            height: controlHeight
            text: "Внести"
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: fromBorderMargin
                bottomMargin: standardMargin * 3
            }
            onClicked: {
                var prevValue = logic.readingsList[0].value
                var currentValue = currentReadingsTextField.text
                console.log("TEXT", currentReadingsTextField.text)
                var avgValue = averageConsumption(3)
                var valueDiff = currentValue - prevValue
                // If value not written
                if (currentValue.length === 0) {
                    dialogPopup.showError("Значение не введено", () => {dialogPopup.close()})
                    return
                }
                // If value incorrect
                let regex = new RegExp("^\\d+(\\.(\\d{1})?)?$")
                if (!currentValue.match(regex)) {
                    dialogPopup.showError("Необходимо ввести корректное значение счетчика", () => {dialogPopup.close()})
                    return
                }
                currentValue = parseFloat(currentValue).toFixed(1)
                console.log("TEXT2", currentValue)
                // If value is less then previous
                if (currentValue <= prevValue) {
                    dialogPopup.showError("Значение счетчика не может быть меньше либо равно предыдущему", () => {dialogPopup.close()})
                    return
                }
                // Detect over consumption
                var diff = 0
                if (counter.type === "cold_water") diff = 2
                if (counter.type === "hot_water") diff = 2
                if (counter.type === "electricity") diff = 40

                console.log("valueDiff", valueDiff)
                console.log("avgValue", avgValue)
                if (valueDiff > avgValue) {
                    if (valueDiff - avgValue > diff) {
                        addReadingsDrawer.close()
                        dynamicFormPage.clear()
                        dynamicFormPage.data = []
                        dynamicFormPage.data.push(currentValue)
                        dynamicFormPage.pageTitle = "Предупреждение"
                        var overCons = (valueDiff - avgValue).toFixed(1)
                        dynamicFormPage.pageDescription = "Вы пытаетесь внести показания превышающие средний расход энергоресурса на " + overCons + " " + typeToUnit[counter.type] + " (средний расход - " + avgValue.toFixed(1) + " " + typeToUnit[counter.type] + ", текущий - " + valueDiff.toFixed(1) + " " + typeToUnit[counter.type] + ")"
                        dynamicFormPage.addSpacing()
                        dynamicFormPage.addButton("Продолжить", () => {
                            var task = logic.addCounterReading(counterPage.counter.id, dynamicFormPage.data[0])
                            wrapTask(task, (task) => {
                                if (task.hasError) {
                                    dialogPopup.showError(task.error, () => {dialogPopup.close(); countersStackView.pop()})
                                } else {
                                    countersPage.update()
                                    dialogPopup.clear()
                                    dialogPopup.title = "Показания добавлены"
                                    dialogPopup.description = "Значение " + dynamicFormPage.data[0] + " добавлено в историю показаний!"
                                    dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); countersStackView.pop(); countersStackView.pop();})
                                    dialogPopup.open()
                                }
                            })
                        })
                        countersStackView.push(dynamicFormPage)
                        return
                    }
                }
                addReadingsDrawer.close()
                dynamicFormPage.data = []
                dynamicFormPage.data.push(currentValue)
                var task = logic.addCounterReading(counterPage.counter.id, dynamicFormPage.data[0])
                wrapTask(task, (task) => {
                    if (task.hasError) {
                        dialogPopup.showError(task.error, () => {dialogPopup.close(); countersStackView.pop()})
                    } else {
                        countersPage.update()
                        dialogPopup.clear()
                        dialogPopup.title = "Показания добавлены"
                        dialogPopup.description = "Значение " + dynamicFormPage.data[0] + " добавлено в историю показаний!"
                        dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); countersStackView.pop(); countersStackView.pop();})
                        dialogPopup.open()
                    }
                })
            }
        }
    }

    /* Loading item */
    Item {
        visible: readingsListModel.count === 0
        anchors {
            top: contentListView.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        /* Busy Indicator */
        BusyIndicator {
            width: 60
            height: 60
            anchors.centerIn: parent
            running: true
        }
    }
}
