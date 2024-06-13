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

    property int tagsHeight: 28
    property int itemsSpacing: 8
    property int betweenTagsSpacing: 8
    property int standardMargin: 10
    property int betweenCardsSpacing: 16

    Connections {
        target: logic

        function onEventsListChanged() {
            // Updating houses list
            houseTagPicker.categoryListModel.clear()
            let housesAddreses = [];
            for (let i = 0; i < logic.eventsList.length; i++) {
                let event = logic.eventsList[i]
                let house = logic.getHouseById(event.houseId)
                if (!housesAddreses.includes(house.address)) {
                    housesAddreses.push(house.address)
                    houseTagPicker.categoryListModel.append({"name": house.address})
                }
            }
            houseTagPicker.categoryCheckBoxRepeater.update()
            root.updateEvents()
        }
    }

    Connections {
        target: typeTagPicker
        function onCheckedChanged() {
            tagsListModel.update()
            updateEvents()
        }
    }

    Connections {
        target: houseTagPicker
        function onCheckedChanged() {
            updateEvents()
        }
    }

    function updateEvents() {
        // Updating events cards
        let checkedTypes = typeTagPicker.getChecked()
        let checkedAddresses = houseTagPicker.getChecked()
        eventsListModel.clear()
        for (let i = 0; i < logic.eventsList.length; i++) {
            let event = logic.eventsList[i]
            let type = event.type === "news" ? "Новости" : "Уведомления"
            if (!checkedTypes.includes(type)) continue
            if (!checkedTypes.includes("Непрочитанное") && event.readed) continue
            let color = event.type === "news" ? themeSettings.cardBlueColor : themeSettings.cardYellowColor
            let house = logic.getHouseById(event.houseId)
            if (!event.readed) {
                logic.markEvent(event.id, true)
            }
            if (!checkedAddresses.includes(house.address)) continue
            eventsListModel.append({"type": type, "color": color, "readed": event.readed, "date": new Date(event.createdAt).toLocaleDateString(Qt.locale("ru_RU")).split(", ")[1], "title": event.title, "address": house.address})
        }
        console.log("EventsListModel updated!")
    }

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page Title */
    TitleText {
        id: title
        text: "События"
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: fromBorderMargin
            topMargin: titleTopMargin
        }
    }

    /* Settings Button */
    IconButton {
        id: settingsButton
        buttonSize: 30
        imageColor: themeSettings.primaryColor
        imageSource: "qrc:/images/settings.svg"
        anchors {
            right: parent.right
            rightMargin: fromBorderMargin
            verticalCenter: title.verticalCenter
        }
        onClicked: tagPickerDrawer.open()
    }

    /* Tags List Model */
    ListModel {
        id: tagsListModel

        function update() {
            clear()
            let checkedTypes = typeTagPicker.getChecked()
            if (checkedTypes.includes("Новости")) tagsListModel.append({"name": "Новости", "color": themeSettings.cardBlueColor})
            if (checkedTypes.includes("Уведомления")) tagsListModel.append({"name": "Уведомления", "color": themeSettings.cardYellowColor})
            if (checkedTypes.includes("Непрочитанное")) tagsListModel.append({"name": "Непрочитанное", "color": themeSettings.cardPinkColor})
        }

        Component.onCompleted: {
            tagsListModel.update()
        }
    }

    /* Filters ListView */
    ListView {
        id: filtersListView
        clip: true
        height: tagsHeight
        spacing: betweenTagsSpacing

        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds

        model: tagsListModel

        displaced: Transition {
            NumberAnimation {
                properties: "x"
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }

        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            margins: fromBorderMargin
            topMargin: standardMargin
        }

        delegate: Rectangle {
            id: tagDelegate
            color: model.color
            height: tagsHeight
            width: tagDelegateText.implicitWidth + itemsSpacing * 3 + tagCloseButton.width
            radius: height / 2

            RegularText {
                id: tagDelegateText
                text: model.name
                color: themeSettings.backgroundColor
                anchors {
                    left: parent.left
                    leftMargin: itemsSpacing
                    verticalCenter: parent.verticalCenter
                }
            }

            ColoredSvgImage {
                id: tagCloseButton
                height: 8
                width: 8
                imageSource: "qrc:/images/close.svg"
                imageColor: themeSettings.backgroundColor
                anchors {
                    left: tagDelegateText.right
                    leftMargin: itemsSpacing
                    verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    typeTagPicker.setChecked(model.name, false)
                    tagsListModel.update()
                    updateEvents()
                }
            }
        }
    }

    /* Events List Model */
    ListModel {
        id: eventsListModel
    }

    /* Events List View */
    ListView {
        id: eventsListView
        clip: true
        topMargin: 8
        spacing: betweenCardsSpacing
        boundsBehavior: Flickable.StopAtBounds
        model: eventsListModel

        anchors {
            top: filtersListView.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: standardMargin
            bottomMargin: standardMargin
        }

        delegate: Card {
            height: 16 * 2 + cardHeader.height + cardTitleText.height + cardAddressText.height + standardMargin * 2
            anchors {
                left: parent === null ? undefined : parent.left
                right: parent === null ? undefined : parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }

            Item {
                id: cardHeader
                height: cardHeaderRow.implicitHeight
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 16
                    leftMargin: 12
                }

                Row {
                    id: cardHeaderRow
                    spacing: itemsSpacing

                    Rectangle {
                        height: 12
                        visible: !model.readed
                        width: 12
                        radius: height / 2
                        color: themeSettings.accentColor
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        id: cardHeaderTag
                        color: model.color
                        height: 22
                        width: cardHeaderTagText.implicitWidth + itemsSpacing * 2
                        radius: height / 2

                        CaptionText {
                            id: cardHeaderTagText
                            text: model.type
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
                        text: model.date
                        color: themeSettings.primaryColor
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            SubTitleText {
                id: cardTitleText
                text: model.title
                horizontalAlignment: Text.AlignLeft
                anchors {
                    top: cardHeader.bottom
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: standardMargin
                }
            }

            RegularText {
                id: cardAddressText
                text: model.address
                horizontalAlignment: Text.AlignJustify
                anchors {
                    top: cardTitleText.bottom
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: standardMargin - 4
                }
            }
        }
    }

    Drawer {
        id: tagPickerDrawer

        edge: Qt.BottomEdge
        height: 250
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
            id: typeTagPicker
            categoryName: "Тип события:"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 40
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }

            Component.onCompleted: {
                categoryListModel.append({"name": "Новости", "color": themeSettings.cardBlueColor})
                categoryListModel.append({"name": "Уведомления", "color": themeSettings.cardYellowColor})
                categoryListModel.append({"name": "Непрочитанное", "color": themeSettings.cardPinkColor})
                categoryCheckBoxRepeater.update()
            }
        }

        TagPicker {
            id: houseTagPicker
            categoryName: "Дом:"
            anchors {
                top: typeTagPicker.bottom
                left: parent.left
                right: parent.right
                topMargin: standardMargin
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }
        }
    }
}
