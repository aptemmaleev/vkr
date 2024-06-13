import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"

Page {
    id: root

    property int controlHeight: 50
    property int fromBorderMargin: 45
    property int betweenElementsMargin: 40
    property int controlSpacing: 20
    property int contentTopMargin: 130

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page content */
    Item {
        id: pageContent
        height: title.implicitHeight + controlHeight * 5 + betweenElementsMargin * 2 + controlSpacing * 3
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: contentTopMargin
            margins: fromBorderMargin
        }

        /* Page Title */
        TitleText {
            id: title
            text: "Регистрация"
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
        }

        /* Login field */
        EmailField {
            id: emailField
            height: controlHeight
            placeholderText: "Email"
            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                topMargin: betweenElementsMargin
            }
        }

        /* Password field */
        PasswordField {
            id: passwordField
            height: controlHeight
            placeholderText: "Пароль"
            anchors {
                top: emailField.bottom
                left: parent.left
                right: parent.right
                topMargin: controlSpacing
            }
        }

        /* Password field */
        PasswordField {
            id: passwordFieldSecond
            height: controlHeight
            placeholderText: "Пароль еще раз"
            anchors {
                top: passwordField.bottom
                left: parent.left
                right: parent.right
                topMargin: controlSpacing
            }
        }

        /* Login field */
        EmailField {
            id: nameField
            height: controlHeight
            placeholderText: "Имя"
            anchors {
                top: passwordFieldSecond.bottom
                left: parent.left
                right: parent.right
                topMargin: controlSpacing
            }
        }

        /* Login field */
        EmailField {
            id: surnameField
            height: controlHeight
            placeholderText: "Фамилия"
            anchors {
                top: nameField.bottom
                left: parent.left
                right: parent.right
                topMargin: controlSpacing
            }
        }

        /* Login in button */
        RectangleButton {
            text: "Зарегистрироваться"
            height: controlHeight
            anchors {
                top: surnameField.bottom
                left: parent.left
                right: parent.right
                topMargin: betweenElementsMargin
            }

            onClicked: {
                let email = emailField.text
                let password1 = emailField.text
                let password2 = emailField.text
                let name = emailField.text
                let surname = emailField.text

                // Validate email
                let regex = new RegExp("^(?=.{1,64}@)[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*@[^-][A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$")
                if (!email.match(regex)) {
                    dialogPopup.showError("Указан неправильный адрес электронной почты", () => {dialogPopup.close()})
                    return
                }
                // Validate password
                if (password1 !== password2) {
                    dialogPopup.showError("Пароли отличаются!", () => {dialogPopup.close()})
                    return
                }
                else if (password1.length < 8 || password1.length > 20) {
                    dialogPopup.showError("Длина пароля должна быть от 8 до 20 символов!", () => {dialogPopup.close()})
                    return
                }
                else if (!password1.match(/[A-Z]/)) {
                    dialogPopup.showError("Пароль должен содержать хотя бы одну заглавную букву!", () => {dialogPopup.close()})
                    return
                }
                else if (!password1.match(/[a-z]/)) {
                    dialogPopup.showError("Пароль должен содержать хотя бы одну строчную букву!", () => {dialogPopup.close()})
                    return
                }
                else if (!password1.match(/[0-9]/)) {
                    dialogPopup.showError("Пароль должен содержать хотя бы одну цифру!", () => {dialogPopup.close()})
                    return
                }
                else if (!password1.match(/[^\w\s]/)) {
                    dialogPopup.showError("Пароль должен содержать хотя бы один специальный символ!", () => {dialogPopup.close()})
                    return
                }
                // Validate name and surname
                if (name < 3 || name > 24) {
                    dialogPopup.showError("Имя должно быть от 3 до 24 символов", () => {dialogPopup.close()})
                    return
                }
                if (surname < 3 || surname > 16) {
                    dialogPopup.showError("Фамилия должна быть от 3 до 24 символов", () => {dialogPopup.close()})
                    return
                }

                logic.registerUser(email, password1, name, surname)
            }
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
            text: "У вас уж есть аккаунт?"
            opacity: 0.5
        }

        CaptionText {
            text: "Войти"
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
            mainStackView.replace(loginPage)
        }
    }
}
