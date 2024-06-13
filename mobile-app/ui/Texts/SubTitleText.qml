import QtQuick
import QtQuick.Controls

Text {
    color: themeSettings.primaryColor

    textFormat: Text.PlainText
    elide: Text.ElideRight

    font.family: nunitoSemiBold.name
    font.pointSize: 18
    font.bold: true

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    wrapMode: Text.WordWrap
}
