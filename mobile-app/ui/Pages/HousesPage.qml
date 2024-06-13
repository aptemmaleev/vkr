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
    state: "houses"

    Connections {
        target: logic

        function onHousesListChanged() {
            housesListModel.clear()
            logic.housesList.forEach(house => {
                housesListModel.append({"house": house})
            })
            console.log("HousesListModel updated!")
            logic.retrieveApartmentList()
        }

        function onApartmentsListChanged() {
            apartmentsListModel.clear()
            for (let i = 0; i < logic.apartmentsAddresses.length; i++) {
                apartmentsListModel.append({"name": "Квартира #" + (i + 1), "address": logic.apartmentsAddresses[i]})
            }
            console.log("ApartmentsListModel updated!")
        }
    }

    states: [
        State {
            name: "houses"
            PropertyChanges {
                target: housesListView
                visible: true
            }
            PropertyChanges {
                target: titleHouses
                opacity: 1
            }
            PropertyChanges {
                target: apartmentsListView
                visible: false
            }
            PropertyChanges {
                target: titleAppartments
                opacity: 0.5
            }
        },
        State {
            name: "apartments"
            PropertyChanges {
                target: housesListView
                visible: false
            }
            PropertyChanges {
                target: titleHouses
                opacity: 0.5
            }
            PropertyChanges {
                target: apartmentsListView
                visible: true
            }
            PropertyChanges {
                target: titleAppartments
                opacity: 1
            }
        }
    ]

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page Title */
    TitleText {
        id: titleHouses
        opacity: 1
        text: "Дома"
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: fromBorderMargin
            topMargin: titleTopMargin
        }
    }

    MouseArea {
        id: housesMouseArea
        anchors.fill: titleHouses
        onClicked: root.state = "houses"
    }

    /* Page Title */
    TitleText {
        id: titleAppartments
        opacity: 0.5
        text: "Квартиры"
        anchors {
            top: parent.top
            left: titleHouses.right
            leftMargin: fromBorderMargin
            topMargin: titleTopMargin
        }
    }

    MouseArea {
        id: appartmentsMouseArea
        anchors.fill: titleAppartments
        onClicked: root.state = "apartments"
    }

    /* Events List Model */
    ListModel {
        id: housesListModel
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
            top: titleHouses.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: standardMargin
        }

        delegate: Card {
            height: apartmentTitleText.height + apartmentDetailsText.height + standardMargin * 2 + standardMargin - 4 + 16
            anchors {
                left: parent === null ? undefined : parent.left
                right: parent === null ? undefined : parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }

            SubTitleText {
                id: apartmentTitleText
                text: model.name
                horizontalAlignment: Text.AlignLeft
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: 16
                }
            }

            RegularText {
                id: apartmentDetailsText
                text: model.address
                horizontalAlignment: Text.AlignJustify
                anchors {
                    top: apartmentTitleText.bottom
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: standardMargin - 4
                }
            }
        }
    }

    /* Houses List View */
    ListView {
        id: housesListView
        visible: false
        clip: true
        topMargin: 8
        bottomMargin: 8
        spacing: betweenCardsSpacing
        boundsBehavior: Flickable.StopAtBounds
        model: housesListModel

        anchors {
            top: titleHouses.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: standardMargin
        }

        delegate: Card {
            height: houseTitleText.height + houseDetailsText.height + standardMargin * 2 + standardMargin - 4 + 16 + manageButton.height
            anchors {
                left: parent === null ? undefined : parent.left
                right: parent === null ? undefined : parent.right
                leftMargin: fromBorderMargin
                rightMargin: fromBorderMargin
            }

            SubTitleText {
                id: houseTitleText
                text: model.house.address
                horizontalAlignment: Text.AlignLeft
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: 16
                }
            }

            RegularText {
                id: houseDetailsText
                text: model.house.info
                horizontalAlignment: Text.AlignJustify
                anchors {
                    top: houseTitleText.bottom
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: standardMargin - 4
                }
            }

            RectangleButton {
                id: manageButton
                height: model.house.isManager ? 40 : 0
                text: "Управление"
                anchors {
                    top: houseDetailsText.bottom
                    left: parent.left
                    right: parent.right
                    margins: 12
                    topMargin: standardMargin - 4
                }

                onClicked: {
                    manageHousePage.house = model.house
                    housesStackView.push(manageHousePage)
                }
            }
        }
    }

    /* Not conencted to house */
    Item {
        id: notConnectedToHouseItem
        visible: root.state === "apartments" && apartmentsListModel.count === 0
        anchors.fill: parent
        y: 9999999

        /* Not added to house */
        ColorlessSvgImage {
            id: noHousesIllustration
            height: 150
            width: 180
            imageSource: "qrc:/images/illustrations/house.svg"
            anchors.centerIn: parent
        }

        /* Not connected to house text */
        SubTitleText {
            text: "Вы еще не подключены ни к одной квартире"
            width: noHousesIllustration.width + 40
            anchors {
                top: noHousesIllustration.bottom
                topMargin: 12
                horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
