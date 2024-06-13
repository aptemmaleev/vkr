import QtQuick
import QtQuick.Controls

Item {
    property color imageColor: null
    property string imageSource: ""

    property bool imageAsynchronous: true

    ColorImage {
        id: image
        color: imageColor
        anchors.fill: parent
        source: imageSource
        sourceSize.height: parent.height
        sourceSize.width: parent.width
        fillMode: Image.PreserveAspectFit
        asynchronous: imageAsynchronous
        smooth: true
    }
}
