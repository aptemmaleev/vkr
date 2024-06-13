import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"

Page {
    id: root

    property int controlHeight: 50
    property int fromBorderMargin: 45

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page Title */
    TitleText {
        id: title
        text: "Авторизация"
        anchors {
            top: parent.top
            topMargin: 250
            horizontalCenter: parent.horizontalCenter
        }
    }

    /* Login field */
    EmailField {
        id: loginField
        height: controlHeight
        text: "test@mail.ru"
        placeholderText: "Email"
        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            topMargin: 40
            leftMargin: fromBorderMargin
            rightMargin: fromBorderMargin
        }
    }

    /* Password field */
    PasswordField {
        id: passwordField
        height: controlHeight
        text: "12345678Aa!"
        placeholderText: "Password"
        anchors {
            top: loginField.bottom
            left: parent.left
            right: parent.right
            topMargin: 20
            leftMargin: fromBorderMargin
            rightMargin: fromBorderMargin
        }
    }

    /* Forget Password button */
    CaptionText {
        id: forgetPasswordButton
        text: "Забыли пароль?"
        opacity: 0.5

        anchors {
            top: passwordField.bottom
            topMargin: 12
            horizontalCenter: parent.horizontalCenter
        }
    }

    /* Login in button */
    RectangleButton {
        text: "Войти"
        height: controlHeight
        anchors {
            top: forgetPasswordButton.bottom
            left: parent.left
            right: parent.right
            topMargin: 80
            leftMargin: fromBorderMargin
            rightMargin: fromBorderMargin
        }

        onClicked: {
            // Get data
            let email = loginField.text
            let password = passwordField.text
            // Validate data
            let regex = new RegExp("^(?=.{1,64}@)[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*@[^-][A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$")
            if (!email.match(regex)) {
                dialogPopup.showError("Указан неправильный адрес электронной почты", () => {dialogPopup.close()})
                return
            }

            mainSwipeView.setCurrentIndex(1)
            var task = logic.loginUser(loginField.text, passwordField.text)
            loadingPage.show(task, (task) => {
                if (task.hasError) {
                    mainStackView.clear()
                    mainStackView.push(loginPage)
                    dialogPopup.showError(task.error, () => {dialogPopup.close()})
                } else {
                    mainStackView.clear()
                    mainStackView.push(mainSwipeView)
                }
            })
        }
    }

    /* Not registered */
    Column {
        id: notRegisteredButton
        opacity: notRegisteredMouseArea.pressed ? 0.7 : 1
        anchors {
            bottom: parent.bottom
            bottomMargin: fromBorderMargin
            horizontalCenter: parent.horizontalCenter
        }

        CaptionText {
            text: "У вас еще нет аккаунта?"
            opacity: 0.5
        }

        CaptionText {
            text: "Зарегистрироваться"
            color: themeSettings.accentColor
            anchors {
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    /* Not Registered Button Mouse Area */
    MouseArea {
        id: notRegisteredMouseArea
        anchors.fill: notRegisteredButton

        onClicked: {
            mainStackView.replace(registrationPage)
        }
    }
}
