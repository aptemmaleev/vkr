import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    property int radius: 16
    property int backgroundBorderWidth: 0
    property color backgroundBorderColor: themeSettings.primaryColor

    /* Card Background */
    Rectangle {
        id: background
        radius: root.radius
        border.width: backgroundBorderWidth
        border.color: backgroundBorderColor
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
        shadowOpacity: 0.2
        shadowColor: Qt.lighter(Qt.lighter(themeSettings.primaryColor))
        shadowVerticalOffset: 2
        shadowHorizontalOffset: 2
    }
}
