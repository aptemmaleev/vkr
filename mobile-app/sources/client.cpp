#include "include/client.h"
#include <QJsonArray>

Client::Client(QObject *parent)
{
    manager = new QNetworkAccessManager();
    QSettings settings;
    if (settings.contains("token")) {
        token = settings.value("token").toString();
        qDebug() << "GOT TOKEN: " << token;
    }
}

Client::~Client()
{
    delete manager;
}

User Client::getCurrentUser() const
{
    return currentUser;
}

void Client::setCurrentUser(const User &newCurrentUser)
{
    currentUser = newCurrentUser;
    emit currentUserChanged();
}

Task* Client::registerUser(QString email, QString password, QString name, QString surname)
{
    QNetworkRequest request;
    request.setUrl(QUrl(hostname + "register"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    QJsonObject json;
    json.insert("email", email);
    json.insert("password", password);
    json.insert("name", name);
    json.insert("surname", surname);
    QJsonDocument doc(json);
    QByteArray postData = doc.toJson(QJsonDocument::Compact);
    QNetworkReply* reply = manager->post(request, postData);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, email, password, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            emit registerError();
            task->setIsDone(true);
            return;
        } else {
            if (reply->error()) {
                error = reply->errorString();
                reply->deleteLater();
                error = reply->readAll();
                emit registerError();
                task->setIsDone(true);
                return;
            }
        }
        loginUser(email, password);
    });
    return task;
}

Task *Client::retrieveHousesList()
{
    QNetworkReply* reply = makeAuthorizedGet("api/v1/houses/list", QUrlQuery());
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setIsDone(true);
                return;
            }

            QList<House> houses;
            for (auto obj : responseJson.array()) {
                auto object = obj.toObject();
                QString id = object.value("id").toString();
                QString address = object.value("address").toString();
                QString info = object.value("info").toString();
                quint32 startReadingsDay = object.value("start_readings_day").toInt();
                quint32 endReadingsDay = object.value("end_readings_day").toInt();
                QStringList managers;
                for (auto managerObj : object.value("managers").toArray()) {
                    managers.append(managerObj.toString());
                }
                bool isManager = false;
                for (auto managerId : managers) {
                    if (managerId == getCurrentUser().id) isManager = true;
                }
                houses.append({id, address, info, startReadingsDay, endReadingsDay, managers, isManager});
            }

            setHousesList(houses);
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::retrieveApartmentList()
{
    QNetworkReply* reply = makeAuthorizedGet("api/v1/apartments/my", QUrlQuery());
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setIsDone(true);
            }

            QStringList addresses;
            QList<Apartment> apartments;
            apartmentIdByAddresses.clear();
            for (auto obj : responseJson.array()) {
                auto object = obj.toObject();
                QString id = object.value("id").toString();
                QString houseId = object.value("house_id").toString();
                QString ownerId = object.value("owner_id").toString();
                QString entrance = object.value("entrance").toString();
                QString floor = object.value("floor").toString();
                QString number = object.value("number").toString();
                QStringList residents;
                for (auto residentObj : object.value("residents").toArray()) {
                    residents.append(residentObj.toString());
                }
                QString apartmentAddress = getHouseById(houseId).address + ", кв. " + number;
                addresses.append(apartmentAddress);
                apartments.append({id, houseId, ownerId, entrance, floor, number});
                apartmentIdByAddresses.insert(apartmentAddress, id);
            }

            setApartmentsAddresses(addresses);
            setApartmentsList(apartments);
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::retrieveHouseApartmentList(QString houseId)
{
    auto query = QUrlQuery();
    query.addQueryItem("house_id", houseId);
    QNetworkReply* reply = makeAuthorizedGet("api/v1/apartments/list", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setIsDone(true);
            }

            QList<Apartment> apartments;
            for (auto obj : responseJson.array()) {
                auto object = obj.toObject();
                QString id = object.value("id").toString();
                QString houseId = object.value("house_id").toString();
                QString ownerId = object.value("owner_id").toString();
                QString entrance = object.value("entrance").toString();
                QString floor = object.value("floor").toString();
                QString number = object.value("number").toString();
                QStringList residents;
                for (auto residentObj : object.value("residents").toArray()) {
                    residents.append(residentObj.toString());
                }
                apartments.append({id, houseId, ownerId, entrance, floor, number});
            }
            setHouseApartmentsList(apartments);
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::retrieveEventsList()
{
    QNetworkReply* reply = makeAuthorizedGet("api/v1/events/my", QUrlQuery());
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setIsDone(true);
                return;
            }

            QList<Event> events;
            for (auto obj : responseJson.array()) {
                auto object = obj.toObject();
                QString id = object.value("id").toString();
                QString type = object.value("type").toString();
                QString userId = object.value("user_id").toString();
                QString title = object.value("title").toString();
                QString details = object.value("details").toString();
                bool readed = object.value("readed").toBool();
                QString managerId = object.value("manager_id").toString();
                QString createdAt = object.value("created_at").toString();
                QString houseId = object.value("house_id").toString();
                events.append({id, type, userId, title, details, readed, managerId, createdAt, houseId});
            }

            setEventsList(events);
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::retrieveCountersList(QString apartmentId)
{
    auto query = QUrlQuery();
    query.addQueryItem("apartment_id", apartmentId);
    QNetworkReply* reply = makeAuthorizedGet("api/v1/counters/list", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setIsDone(true);
                return;
            }

            QList<Counter> counters;
            for (auto obj : responseJson.array()) {
                auto object = obj.toObject();
                QString id = object.value("id").toString();
                QString type = object.value("type").toString();
                QString name = object.value("name").toString();
                QString serialNumber = object.value("serial_number").toString();
                QString apartmentId = object.value("apartment_id").toString();
                bool hasReading = object.value("has_reading").toBool(false);
                counters.append({id, type, name, serialNumber, apartmentId, hasReading});
            }

            setCountersList(counters);
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::retrieveReadingsList(QString counterId)
{
    auto query = QUrlQuery();
    query.addQueryItem("counter_id", counterId);
    QNetworkReply* reply = makeAuthorizedGet("api/v1/counters/readings/list", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setIsDone(true);
                return;
            }

            QList<Reading> readings;
            for (auto obj : responseJson.array()) {
                auto object = obj.toObject();
                QString id = object.value("id").toString();
                float value = object.value("value").toDouble();
                QString userId = object.value("user_id").toString();
                QString createdAt = object.value("created_at").toString();
                QString counterId = object.value("counter_id").toString();
                int year = object.value("year").toInt();
                int month = object.value("month").toInt();
                readings.append({id, value, userId, createdAt, counterId, year, month});
            }

            setReadingsList(readings);
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::createCounter(QString apartmentId, QString serialNumber, QString type, QString name, float value)
{
    auto query = QUrlQuery();
    query.addQueryItem("apartment_id", apartmentId);
    query.addQueryItem("serial_number", serialNumber);
    query.addQueryItem("type", type);
    query.addQueryItem("name", name);
    query.addQueryItem("value", QString::number(value));
    QNetworkReply* reply = makeAuthorizedGet("api/v1/counters/add", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::deleteCounter(QString counterId)
{
    auto query = QUrlQuery();
    query.addQueryItem("counter_id", counterId);
    QNetworkReply* reply = makeAuthorizedGet("api/v1/counters/remove", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::addCounterReading(QString counterId, float value)
{
    auto query = QUrlQuery();
    query.addQueryItem("counter_id", counterId);
    query.addQueryItem("value", QString::number(value));
    qDebug() << QString::number(value);
    if (QString::number(value) == "nan") {
        Task* task = new Task;
        task->setHasError(true, "Неизвестаня ошибка");
        task->setIsDone(true);
        return task;
    }
    QNetworkReply* reply = makeAuthorizedGet("api/v1/counters/readings/add", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::deleteCounterReading(QString readingId)
{
    auto query = QUrlQuery();
    query.addQueryItem("reading_id", readingId);
    QNetworkReply* reply = makeAuthorizedGet("api/v1/counters/readings/remove", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::changeHouse(QString houseId, QString info, int startReadingsDay, int endReadingsDay)
{
    auto query = QUrlQuery();
    query.addQueryItem("house_id", houseId);
    query.addQueryItem("info", info);
    query.addQueryItem("start_readings_day", QString::number(startReadingsDay));
    query.addQueryItem("end_readings_day", QString::number(endReadingsDay));
    QNetworkReply* reply = makeAuthorizedGet("api/v1/houses/info/update", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::createEvent(QString houseId, QString type, QString title, QString details)
{
    auto query = QUrlQuery();
    query.addQueryItem("house_id", houseId);
    query.addQueryItem("type", type);
    query.addQueryItem("title", title);
    query.addQueryItem("details", details);
    QNetworkReply* reply = makeAuthorizedGet("api/v1/events/add", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::createApartment(QString houseId, QString ownerEmail, int entrance, int number, int floor)
{
    auto query = QUrlQuery();
    query.addQueryItem("house_id", houseId);
    query.addQueryItem("owner_email", ownerEmail);
    query.addQueryItem("entrance", QString::number(entrance));
    query.addQueryItem("number", QString::number(number));
    query.addQueryItem("floor", QString::number(floor));
    QNetworkReply* reply = makeAuthorizedGet("api/v1/apartments/add", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

Task *Client::updateProfile(QString password, QString name, QString surname)
{
    auto query = QUrlQuery();
    if (password != "") query.addQueryItem("password", password);
    if (name != "") query.addQueryItem("name", name);
    if (surname != "") query.addQueryItem("surname", surname);

    QNetworkReply* reply = makeAuthorizedGet("users/me/update", query);
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                task->setHasError(true, obj.value("error").toString());
                task->setIsDone(true);
                return;
            }
            task->setIsDone(true);
        }
    });

    return task;
}

void Client::markEvent(QString eventId, bool read)
{
    auto query = QUrlQuery();
    query.addQueryItem("event_id", eventId);
    query.addQueryItem("read", (read ? "true" : "false"));
    QNetworkReply* reply = makeAuthorizedGet("api/v1/events/mark", query);
    connect(reply, &QNetworkReply::finished, [reply, this] () {
        if (reply->error()) {
            error = reply->errorString();
            qDebug() << "error" << error;
            reply->deleteLater();
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                qDebug() << "error" << error;
                reply->deleteLater();
                return;
            }
            auto obj = responseJson.object();
            if (obj.contains("error")) {
                qDebug() << "error";
                return;
            }
        }
    });
}

Apartment Client::getApartmentById(const QString &id)
{
    for (auto& apartment : apartmentsList) {
        if (apartment.id == id) {
            return apartment;
        }
    }
    return Apartment();
}



House Client::getHouseById(const QString &houseId)
{
    for (auto house : housesList) {
        if (house.id == houseId) {
            return house;
        }
    }
    return House();
}

Apartment Client::getApartmentByAddress(const QString &address)
{
    return getApartmentById(apartmentIdByAddresses.value(address));
}

Task* Client::loginUser(QString email, QString password)
{
    QNetworkRequest request(QUrl(hostname + "token"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    QNetworkReply* reply = manager->post(request, QString("username=%0&password=%1").arg(email).arg(password).toUtf8());
    Task* task = new Task;
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            emit loginError();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
        } else {
            QByteArray responseData = reply->readAll();
            QJsonParseError parseError;
            QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
            if (parseError.error != QJsonParseError::NoError) {
                error = "JSON parsing error: " + parseError.errorString();
                reply->deleteLater();
                emit loginError();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            if (!responseJson.isObject() || !responseJson.object().contains("access_token")) {
                error = "Access token not found in response";
                reply->deleteLater();
                emit loginError();
                task->setHasError(true, "Неизвестная ошибка, попробуйте выполнить это действие позже");
                task->setIsDone(true);
                return;
            }
            QSettings settings;
            QString accessToken = responseJson.object().value("access_token").toString();
            settings.setValue("token", accessToken);
            settings.sync();
            token = accessToken;
            task->setIsDone(true);
        }
    });

    return task;
}

Task* Client::checkLogged()
{
    Task* task = new Task;
    if (!hasToken()) {
        emit loginError();
        task->setHasError(true, "Нет текущей сессии");
        task->setIsDone(true);
        return task;
    };
    QNetworkReply* reply = makeAuthorizedGet("users/me", QUrlQuery());
    connect(reply, &QNetworkReply::finished, [reply, this, task] () {
        if (reply->error()) {
            error = reply->errorString();
            reply->deleteLater();
            emit loginError();
            task->setHasError(true, "Не удалось установить соединение с сервером. Проверьте подключение к интернету");
            task->setIsDone(true);
            return;
        }
        bool ok;
        auto object = parseResponseData(ok, reply);
        if (!ok) {
            task->setHasError(true, "Не удалось автоматически войти в ваш аккаунт");
            task->setIsDone(true);
            return;
        }
        QString id = object.value("id").toString();
        QString mail = object.value("email").toString();
        QString name = object.value("name").toString();
        QString surname = object.value("surname").toString();
        QString role = object.value("role").toString();
        User user = {id, mail, name, surname, role};
        setCurrentUser(user);
        isLogged = true;
        emit loggedIn();
        task->setIsDone(true);
    });
    return task;
}

void Client::logout()
{
    setCurrentUser(User());
    token = "";
    QSettings settings;
    settings.setValue("token", "");
    settings.sync();
}

QString &Client::errorString()
{
    return error;
}

QNetworkReply *Client::makeAuthorizedGet(QString method, QUrlQuery query) {
    QNetworkRequest request;
    QUrl url(hostname + method);
    url.setQuery(query);
    request.setUrl(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer " + token).toUtf8());
    QNetworkReply* reply = manager->get(request);
    return reply;
}

QList<Apartment> Client::getHouseApartmentsList() const
{
    return houseApartmentsList;
}

void Client::setHouseApartmentsList(const QList<Apartment> &newHouseApartmentsList)
{
    houseApartmentsList = newHouseApartmentsList;
    emit houseApartmentsListChanged();
}

QList<Reading> Client::getReadingsList() const
{
    return readingsList;
}

void Client::setReadingsList(const QList<Reading> &newReadingsList)
{
    readingsList = newReadingsList;
    emit readingsListChanged();
}

QList<Counter> Client::getCountersList() const
{
    return countersList;
}

void Client::setCountersList(const QList<Counter> &newCountersList)
{
    countersList = newCountersList;
    emit countersListChanged();
}

QList<Event> Client::getEventsList() const
{
    return eventsList;
}

void Client::setEventsList(const QList<Event> &newEventsList)
{
    eventsList = newEventsList;
    emit eventsListChanged();
}

QStringList Client::getApartmentsAddresses() const
{
    return apartmentsAddresses;
}

void Client::setApartmentsAddresses(const QStringList &newApartmentsAddresses)
{
    apartmentsAddresses = newApartmentsAddresses;
    emit apartmentsAddressesChanged();
}

QList<Apartment> Client::getApartmentsList() const
{
    return apartmentsList;
}

void Client::setApartmentsList(const QList<Apartment> &newApartmentsList)
{
    apartmentsList = newApartmentsList;
    emit apartmentsListChanged();
}

void Client::setHousesList(const QList<House> &newHousesList)
{
    housesList = newHousesList;
    emit housesListChanged();
}

QList<House> Client::getHousesList()
{
    return housesList;
}

bool Client::getIsLogged() const
{
    return isLogged;
}

bool Client::hasToken()
{
    return token != "";
}

QJsonObject Client::parseResponseData(bool &ok, QNetworkReply* reply)
{
    if (reply->error()) {
        error = reply->errorString();
        reply->deleteLater();
        ok = false;
        error = "Nwgative response";
        return QJsonObject();
    }
    QJsonParseError parseError;
    QByteArray responseData = reply->readAll();
    QJsonDocument responseJson = QJsonDocument::fromJson(responseData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        error = "JSON parsing error: " + parseError.errorString();
        reply->deleteLater();
        ok = false;
        return QJsonObject();
    }
    ok = true;
    return responseJson.object();
}

bool Task::getHasError() const
{
    return hasError;
}

QString Task::getError() const
{
    return error;
}
