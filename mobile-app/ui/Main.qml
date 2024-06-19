import QtQuick
import QtQuick.Controls
import Client 1.0

import "../ui/Pages"
import "../ui/Popups"
import "../ui/NavigationBar"

ApplicationWindow {
    id: mainWindow
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    Client {
        id: logic

        onLoginError: console.log("Login error!")
        onLoggedIn: {
            logic.retrieveHousesList()
        }
        onHousesListChanged: {
            logic.retrieveApartmentList()
            logic.retrieveEventsList()
        }

        Component.onCompleted: {
            if (!logic.hasToken) return
            var task = checkLogged()
            loadingPage.show(task, (task) => {
                if (logic.isLogged) {
                    mainStackView.clear()
                    mainStackView.push(mainSwipeView)
                } else {
                    dialogPopup.clear()
                    dialogPopup.title = "Ошибка"
                    dialogPopup.description = "Не удалось автоматически войти в ваш аккаунт"
                    dialogPopup.addButton("Закрыть", () => {dialogPopup.close();})
                    mainStackView.clear()
                    mainStackView.push(loginPage)
                    dialogPopup.open()
                }
            })
        }
    }

    FontLoader {
        id: nunitoSemiBold
        source: "qrc:/Nunito-SemiBold.ttf"
    }

    /*#########################*/
    /*        StackView        */
    /*#########################*/
    SwipeView {
        id: mainSwipeView
        visible: false
        interactive: false

        StackView {
            id: housesStackView
            initialItem: housesPage
        }

        StackView {
            id: eventsStackView
            initialItem: eventsPage
        }

        StackView {
            id: countersStackView
            initialItem: countersPage
        }

        StackView {
            id: profileStackView
            initialItem: profilePage
        }

        Component.onCompleted: setCurrentIndex(1)
    }

    StackView {
        id: mainStackView
        anchors.fill: parent
        initialItem: loginPage

        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                easing.type: Easing.Linear
                from: 0
                to: 1
                duration: 120
            }
        }

        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                easing.type: Easing.Linear
                from: 1
                to: 0
                duration: 250
            }
        }

        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 250
            }
        }

        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 250
            }
        }
    }

    footer: NavigationBar {
        id: navigationBar
        visible: mainStackView.currentItem === mainSwipeView
    }

    /*#########################*/
    /*          Pages          */
    /*#########################*/
    /* Login Page */
    LoginPage {
        id: loginPage
        visible: false
    }

    /* Register Page */
    RegistrationPage {
        id: registrationPage
        visible: false
    }

    /* Houses Page */
    HousesPage {
        id: housesPage
        visible: false
    }

    /* Events Page */
    EventsPage {
        id: eventsPage
        visible: false
    }

    /* Profile Page */
    ProfilePage {
        id: profilePage
        visible: false
    }

    /* Counters Page */
    CountersPage {
        id: countersPage
        visible: false
    }

    /* Counter Page */
    CounterPage {
        id: counterPage
        visible: false
    }

    /* Statistics Page */
    StatisticsPage {
        id: statisticsPage
        visible: false
    }

    /* Loading Page */
    LoadingPage {
        id: loadingPage
        visible: false
    }

    /* Manage House Page */
    ManageHousePage {
        id: manageHousePage
        visible: false
    }

    /* Dynamic Form Page */
    DynamicFormPage {
        id: dynamicFormPage
        visible: false
    }

    /* Shadow Panel */
    ShadowPanel {
        id: shadowPanel
        y: 99999
    }

    /* ManageApartmentsPage */
    ManageApartmentsPage {
        id: manageApartmentsPage
        visible: false
    }

    /* ManageApartmentPage */
    ManageApartmentPage {
        id: manageApartmentPage
        visible: false
    }

    ExportTablePage {
        id: exportTablePage
        visible: false
    }

    ManageRequestsPage {
        id: manageRequestsPage
        visible: false
    }

    /* Dialog Popup */
    DialogPopup {
        id: dialogPopup
        y: 100000
        onVisibleChanged: {
            if (visible) {
                shadowPanel.state = "showed"
            } else {
                shadowPanel.state = "hidden"
            }
        }
    }

    Component {
        id: taskCover
        Connections {
            property var callback: []

            function onDone() {
                callback[0](target)
            }
        }
    }

    function wrapTask(task, func) {
        taskCover.createObject(this, {target: task, callback: [func]})
    }

    /* ThemeSettings */
    Item {
        id: themeSettings

        readonly property color backgroundColor: "#F4F5F7"
        readonly property color panelsColor: "#FFD1DC"
        readonly property color accentColor: "#7400B8"
        readonly property color primaryColor: "#333333"

        readonly property color cardBlueColor: "#5FACD6"
        readonly property color cardYellowColor: "#D6AD5B"
        readonly property color cardPinkColor: "#D65C8E"

        readonly property color warningColor: "#FFAA00"
    }

    Connections {
        target: mainWindow

        function onClosing(close) {
            console.log("MainStackView depth: " + mainStackView.depth)
            if (mainStackView.depth > 1) {
                close.accepted = false
                mainStackView.pop()
            } else {
                close.accepted = true
            }
        }
    }
}
