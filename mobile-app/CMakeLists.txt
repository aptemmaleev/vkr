cmake_minimum_required(VERSION 3.16)
project(vkr VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

if (ANDROID)
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
endif()

qt_add_executable(appvkr
    main.cpp
    include/client.h
    sources/client.cpp

    assets/assets.qrc
)

if (ANDROID)
    add_android_openssl_libraries(appvkr)
endif()

qt_add_qml_module(appvkr
    URI vkr
    VERSION 1.0
        QML_FILES ui/Main.qml
        QML_FILES ui/Pages/LoginPage.qml
        QML_FILES ui/Texts/TitleText.qml
        QML_FILES ui/Texts/SubTitleText.qml
        QML_FILES ui/Texts/RegularText.qml
        QML_FILES ui/Buttons/RectangleButton.qml
        QML_FILES ui/Texts/CaptionText.qml
        QML_FILES ui/Fields/EmailField.qml
        QML_FILES ui/Fields/PasswordField.qml
        QML_FILES ui/Images/ColoredSvgImage.qml
        QML_FILES ui/Pages/HousesPage.qml
        QML_FILES ui/NavigationBar/NavigationBar.qml
        QML_FILES ui/NavigationBar/NavigationBarItem.qml
        QML_FILES ui/Pages/EventsPage.qml
        QML_FILES ui/Pages/ProfilePage.qml
        QML_FILES ui/Pages/CountersPage.qml
        QML_FILES ui/Images/ColorlessSvgImage.qml
        QML_FILES ui/Pages/RegistrationPage.qml
        QML_FILES ui/Pages/ManageHousePage.qml
        QML_FILES ui/Pages/CounterPage.qml
        QML_FILES ui/Pages/StatisticsPage.qml
        QML_FILES ui/Cards/Card.qml
        QML_FILES ui/Buttons/IconButton.qml
        SOURCES
        QML_FILES ui/TagPicker.qml
        QML_FILES ui/Pages/LoadingPage.qml
        QML_FILES ui/Popups/DialogPopup.qml
        QML_FILES
        QML_FILES ui/Pages/DynamicFormPage.qml
        QML_FILES ui/ShadowPanel.qml
        QML_FILES ui/Pages/ManageApartmentsPage.qml
        QML_FILES ui/Pages/ManageApartmentPage.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appvkr PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appvkr
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appvkr
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appvkr
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
