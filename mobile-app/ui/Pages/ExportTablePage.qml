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
    property var months: ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]

    Component.onCompleted: {
        var i = new Date().getMonth() + 1
        root.months = root.months.slice(0, i)
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
        contentHeight: titleTopMargin + title.height + addressText.height + buttonsColumn.height + 40 + historyColumn.height

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
            text: "Экспорт показаний"
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
            text: "На этой странице производится экспорт показаний ИПУ в онлайн таблицу Google Sheets. Выберите год и месяц, за которые необходим отчет и далее нажмите на кнопку Сформировать. Это процесс может занять до 5 минут!"
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

            ComboBox {
                height: controlHeight + 20
                model: ["2024 год"]
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            ComboBox {
                id: monthComboBox
                height: controlHeight + 20
                model: root.months
                currentIndex: new Date().getMonth()
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            RectangleButton {
                text: "Cформировать отчет"
                height: controlHeight

                anchors {
                    left: parent.left
                    right: parent.right
                }

                onClicked: {
                    var year = 2024
                    var month = monthComboBox.currentIndex + 1
                    var task = logic.formTable(house.id, year, month)

                    wrapTask(task, (task) => {
                        if (task.hasError) {
                            dialogPopup.showError(task.error, () => {dialogPopup.close(); housesStackView.pop()})
                        } else {
                            historyListModel.append({"result": task.result, "year": "2024", "month": monthComboBox.currentText, "date": new Date().toLocaleDateString(Qt.locale("ru_RU"))})
                            Qt.openUrlExternally(task.result);
                            console.log(task.result)
                        }
                    })
                }
            }
        }

        Column {
            id: historyColumn
            spacing: 10
            anchors {
                top: buttonsColumn.bottom
                left: parent.left
                right: parent.right
                topMargin: 20
                margins: fromBorderMargin
            }

            Repeater {
                id: historyRepeater

                model: ListModel {
                    id: historyListModel
                }

                delegate: Card {
                    backgroundBorderWidth: 1
                    backgroundBorderColor: themeSettings.cardBlueColor
                    height: 24 + exportTitleText.height + createdText.height
                    anchors {
                        left: parent === null ? undefined : parent.left
                        right: parent === null ? undefined : parent.right
                    }

                    SubTitleText {
                        id: exportTitleText
                        text: model.month + " " + model.year
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                    }

                    RegularText {
                        id: createdText
                        text: "Сформирован " + model.date
                        horizontalAlignment: Text.AlignLeft
                        anchors {
                            top: exportTitleText.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: 12
                            rightMargin: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Qt.openUrlExternally(model.result);
                        }
                    }
                }
            }
        }
    }
}
