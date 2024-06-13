import QtQuick
import QtQuick.Controls

Text {
    color: themeSettings.primaryColor

    textFormat: Text.PlainText
    elide: Text.ElideRight

    font.family: nunitoSemiBold.name
    font.pointSize: 14
    font.bold: false

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    wrapMode: Text.WordWrap
}
