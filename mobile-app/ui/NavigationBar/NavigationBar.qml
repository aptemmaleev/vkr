import QtQuick
import QtQuick.Effects

Item {
    id: root

    property int navigationBarHeight: 70
    property int navigationBarRadius: 16
    property int navigationItemsSpacing: 25
    property int maxItemWidth: 0

    height: navigationBarHeight

    /* Background */
    Rectangle {
        id: background
        radius: navigationBarRadius
        color: themeSettings.backgroundColor
        anchors.fill: parent
    }

    /* Background shadow */
    MultiEffect {
        id: multiEffect
        source: background
        anchors.fill: background
        shadowBlur: 1.0
        shadowEnabled: true
        shadowOpacity: 0.3
        shadowColor: Qt.lighter(themeSettings.primaryColor)
        shadowVerticalOffset: 0
        shadowHorizontalOffset: 0
    }

    /* Navigation Bar Items */
    Row {
        id: itemsRow

        height: housesItem.height
        spacing: navigationItemsSpacing
        width: (root.maxItemWidth * children.length) + ((children.length - 1) * navigationItemsSpacing)
        anchors.centerIn: parent

        NavigationBarItem {
            id: housesItem
            state: mainSwipeView.currentItem === housesStackView ? "highlighted" : "default"
            width: root.maxItemWidth
            imageSource: "qrc:/images/navigation/house.svg"
            text: "Дома"
            onClicked: {
                if (mainSwipeView.currentItem === housesStackView) return
                if (dialogPopup.opened) dialogPopup.close()
                mainSwipeView.setCurrentIndex(0)
            }
        }

        NavigationBarItem {
            id: eventsItem
            state: mainSwipeView.currentItem === eventsStackView ? "highlighted" : "default"
            width: root.maxItemWidth
            imageSource: "qrc:/images/navigation/bell.svg"
            text: "События"
            onClicked: {
                if (mainSwipeView.currentItem === eventsStackView) return
                if (dialogPopup.opened) dialogPopup.close()
                mainSwipeView.setCurrentIndex(1)
            }
        }

        NavigationBarItem {
            id: readingsItem
            state: mainSwipeView.currentItem === countersStackView ? "highlighted" : "default"
            width: root.maxItemWidth
            imageSource: "qrc:/images/navigation/readings.svg"
            text: "Показания"
            onClicked: {
                if (mainSwipeView.currentItem === countersStackView) return
                if (dialogPopup.opened) dialogPopup.close()
                mainSwipeView.setCurrentIndex(2)
            }
        }

        NavigationBarItem {
            id: profileItem
            state: mainSwipeView.currentItem === profileStackView ? "highlighted" : "default"
            width: root.maxItemWidth
            imageSource: "qrc:/images/navigation/profile.svg"
            text: "Профиль"
            onClicked: {
                if (mainSwipeView.currentItem === profileStackView) return
                if (dialogPopup.opened) dialogPopup.close()
                mainSwipeView.setCurrentIndex(3)
            }
        }

        Component.onCompleted: {
            children.forEach((item) => {
                if (item.implicitWidth > root.maxItemWidth) {
                    root.maxItemWidth = item.implicitWidth
                }
            });
        }
    }
}
