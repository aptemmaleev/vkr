#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFile>
#include "include/client.h"
#include "include/client.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName("CounterUtility");
    QCoreApplication::setApplicationVersion("0.1");
    QCoreApplication::setOrganizationName("AptemMaleev");
    QCoreApplication::setOrganizationDomain("gsprivate.ru");

    qmlRegisterType<Client>("Client", 1, 0, "Client");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("vkr", "Main");

    return app.exec();
}
