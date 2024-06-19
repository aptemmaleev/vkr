import QtQuick 2.15
import QtQuick.Controls

import "../Buttons"
import "../Texts"
import "../Fields"

Page {
    id: root

    property int controlHeight: 50
    property int fromBorderMargin: 28
    property int titleTopMargin: 128

    /* Background */
    background: Rectangle {
        color: themeSettings.backgroundColor
    }

    /* Page title */
    TitleText {
        id: title
        text: "Профиль"
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: fromBorderMargin
            topMargin: titleTopMargin
        }
    }

    /* User data column */
    Column {
        id: userDataColumn

        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            topMargin: 20
            margins: fromBorderMargin
        }

        /* RegularText */
        SubTitleText {
            id: emailText
            text: "Почта: " + logic.currentUser.email
            font.bold: false
            horizontalAlignment: Text.AlignLeft
            anchors {
                left: parent.left
                right: parent.right
            }
        }

        /* RegularText */
        SubTitleText {
            id: nameText
            text: "Имя: " + logic.currentUser.name + " " + logic.currentUser.surname[0] + '.'
            font.bold: false
            horizontalAlignment: Text.AlignLeft
            anchors {
                left: parent.left
                right: parent.right
            }
        }
    }

    /* Buttons column */
    Column {
        id: buttonsColumn
        spacing: 12
        anchors {
            top: userDataColumn.bottom
            left: parent.left
            right: parent.right
            topMargin: 20
            margins: fromBorderMargin
        }

        RectangleButton {
            text: "Изменить имя"
            height: controlHeight

            anchors {
                left: parent.left
                right: parent.right
            }

            onClicked: {
                dynamicFormPage.clear()
                dynamicFormPage.data = []
                dynamicFormPage.pageTitle = "Изменение имени"
                dynamicFormPage.pageDescription = "Укажите новые имя и фамилию"
                dynamicFormPage.addTextField("Имя")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addTextField("Фамилия")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addSpacing()
                dynamicFormPage.addButton("Изменить", () => {
                    // Getting data from form
                    var data = dynamicFormPage.getData()
                    // Checking for data length
                    if (data[0].length < 3 || data[0].length > 24) {
                        dialogPopup.showError("Имя должно быть от 3 до 24 символов", () => {dialogPopup.close()})
                        return
                    }
                    if (data[1].length < 3 || data[1].length > 16) {
                        dialogPopup.showError("Фамилия должна быть от 3 до 24 символов", () => {dialogPopup.close()})
                        return
                    }
                    dynamicFormPage.data.push(data)
                    var task = logic.updateProfile("", data[0], data[1])
                    wrapTask(task, (task) => {
                        var data = dynamicFormPage.data[0]
                        if (task.hasError) {
                            dialogPopup.showError(task.error, () => {dialogPopup.close(); profileStackView.pop()})
                        } else {
                            dialogPopup.clear()
                            dialogPopup.title = "Имя изменено!"
                            dialogPopup.description = "Имя пользователя изменено на " + data[0] + " " + data[1] + "! Перезагрузите приложение, чтобы изменения вступили в силу."
                            dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); profileStackView.pop()})
                            dialogPopup.open()
                        }
                    })
                })
                profileStackView.push(dynamicFormPage)
            }
        }

        RectangleButton {
            text: "Изменить пароль"
            height: controlHeight

            anchors {
                left: parent.left
                right: parent.right
            }

            onClicked: {
                dynamicFormPage.clear()
                dynamicFormPage.pageTitle = "Смена пароля"
                dynamicFormPage.pageDescription = "Укажите новый пароль дважды"
                dynamicFormPage.addPassordField("Пароль")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addPassordField("Повторите пароль")
                dynamicFormPage.addSpacing()
                dynamicFormPage.addSpacing()
                dynamicFormPage.addButton("Изменить", () => {
                    // Getting data from form
                    var data = dynamicFormPage.getData()
                    var password1 = data[0]
                    var password2 = data[1]

                    // Check password
                    if (data[0] !== data[1]) {
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

                    var task = logic.updateProfile(password1, "", "")
                    wrapTask(task, (task) => {
                        if (task.hasError) {
                            dialogPopup.showError(task.error, () => {dialogPopup.close(); profileStackView.pop()})
                        } else {
                            dialogPopup.clear()
                            dialogPopup.title = "Пароль изменен"
                            dialogPopup.description = "Новый пароль успешно установлен"
                            dialogPopup.addButton("Закрыть", () => {dialogPopup.close(); profileStackView.pop()})
                            dialogPopup.open()
                        }
                    })
                })
                profileStackView.push(dynamicFormPage)
            }
        }
    }

    /* Logout button */
    Column {
        id: logoutButton
        opacity: logoutButtonMouseArea.pressed ? 0.7 : 1
        anchors {
            bottom: parent.bottom
            bottomMargin: fromBorderMargin
            horizontalCenter: parent.horizontalCenter
        }

        CaptionText {
            text: "Выйти из аккаунта"
            color: themeSettings.accentColor
            anchors {
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    /* Not Registered Button Mouse Area */
    MouseArea {
        id: logoutButtonMouseArea
        anchors.fill: logoutButton

        onClicked: {
            logic.logoutUser()
            mainStackView.clear()
            mainStackView.push(loginPage)
        }
    }
}
