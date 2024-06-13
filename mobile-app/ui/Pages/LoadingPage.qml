import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"

Page {
    id: root

    property int controlHeight: 50
    property int fromBorderMargin: 45
    property var callbackOnDone: []
    property var taskConnection: undefined

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Busy Indicator */
    BusyIndicator {
        width: 60
        height: 60
        anchors.centerIn: parent
        running: true
    }

    Component {
        id: taskConnectionComponent
        Connections {
            function onDone() {
                if (mainStackView.currentItem === loadingPage) {
                    root.callbackOnDone[0](target)
                }
            }
        }
    }

    function show(task, callback) {
        if (task.isDone) {
            console.log("123")
            callback(task)
            return
        }
        taskConnection = taskConnectionComponent.createObject(root, {target: task})
        callbackOnDone = []
        callbackOnDone.push(callback)
        mainStackView.push(loadingPage)
    }
}
