#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>
#include <QJsonObject>
#include <QJsonDocument>
#include <QEventLoop>
#include <QUrlQuery>
#include <QSettings>
#include <QThread>

/* Task Class */
class Task : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isDone READ getIsDone WRITE setIsDone NOTIFY done FINAL)
    Q_PROPERTY(bool hasError READ getHasError CONSTANT FINAL)
    Q_PROPERTY(QString error READ getError CONSTANT FINAL)
    Q_PROPERTY(QString result READ getResult CONSTANT FINAL)
public:
    bool getIsDone() const {
        return isDone;
    }
    void setIsDone(bool newIsDone) {
        isDone = true;
        emit done();
    }
    void setHasError(bool newHasError, QString newError) {
        hasError = newHasError;
        error = newError;
    }
    void setResult(QString newResult) {
        result = newResult;
    }
    bool getHasError() const;
    QString getError() const;

    QString getResult() const;

signals:
    void done();

private:
    bool hasError = false;
    QString result = "";
    QString error = "";
    bool isDone = false;
};

/* User struct */
struct User
{
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString email MEMBER email)
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(QString surname MEMBER surname)
    Q_PROPERTY(QString role MEMBER role)

public:
    QString id;
    QString email;
    QString name;
    QString surname;
    QString role;
};

/* House struct */
struct House
{
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString address MEMBER address)
    Q_PROPERTY(QString info MEMBER info)
    Q_PROPERTY(quint32 startReadingDay MEMBER startReadingDay)
    Q_PROPERTY(quint32 endReadingDay MEMBER endReadingDay)
    Q_PROPERTY(QStringList managers MEMBER managers)
    Q_PROPERTY(bool isManager MEMBER isManager)

public:
    QString id;
    QString address = "Неизвестный адрес";
    QString info;
    quint32 startReadingDay;
    quint32 endReadingDay;
    QStringList managers;
    bool isManager = false;
};

/* Apartment struct */
struct Apartment
{
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString houseId MEMBER houseId)
    Q_PROPERTY(QString ownerId MEMBER ownerId)
    Q_PROPERTY(QString entrance MEMBER entrance)
    Q_PROPERTY(QString floor MEMBER floor)
    Q_PROPERTY(QString number MEMBER number)
    Q_PROPERTY(QStringList residents MEMBER residents)

public:
    QString id;
    QString houseId;
    QString ownerId;
    QString entrance;
    QString floor;
    QString number;
    QStringList residents;
};

/* Event struct */
struct Event
{
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString type MEMBER type)
    Q_PROPERTY(QString userId MEMBER userId)
    Q_PROPERTY(QString title MEMBER title)
    Q_PROPERTY(QString details MEMBER details)
    Q_PROPERTY(bool readed MEMBER readed)
    Q_PROPERTY(QString managerId MEMBER managerId)
    Q_PROPERTY(QString createdAt MEMBER createdAt)
    Q_PROPERTY(QString houseId MEMBER houseId)

public:
    QString id;
    QString type;
    QString userId;
    QString title;
    QString details;
    bool readed;
    QString managerId;
    QString createdAt;
    QString houseId;
};

/* Readings struct */
struct Reading
{
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(float value MEMBER value)
    Q_PROPERTY(QString userId MEMBER userId)
    Q_PROPERTY(QString createdAt MEMBER createdAt)
    Q_PROPERTY(QString counterId MEMBER counterId)
    Q_PROPERTY(int year MEMBER year)
    Q_PROPERTY(int month MEMBER month)

public:
    QString id;
    float value;
    QString userId;
    QString createdAt;
    QString counterId;
    int year;
    int month;
};

/* Counters struct */
struct Counter
{
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString type MEMBER type)
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(QString serialNumber MEMBER serialNumber)
    Q_PROPERTY(QString apartmentId MEMBER apartmentId)
    Q_PROPERTY(bool hasReading MEMBER hasReading)
    Q_PROPERTY(bool active MEMBER active)

public:
    QString id;
    QString type;
    QString name;
    QString serialNumber;
    QString apartmentId;
    bool hasReading;
    bool active;
};

struct Request {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString type MEMBER type)
    Q_PROPERTY(QString reason MEMBER reason)
    Q_PROPERTY(QString counterType MEMBER counterType)
    Q_PROPERTY(QString counterSerial MEMBER counterSerial)
    Q_PROPERTY(QString apartmentNumber MEMBER apartmentNumber)

public:
    QString id;
    QString type;
    QString reason;
    QString counterType;
    QString counterSerial;
    QString apartmentNumber;
};

/* Declare types */
Q_DECLARE_METATYPE(User);
Q_DECLARE_METATYPE(Task);
Q_DECLARE_METATYPE(House);
Q_DECLARE_METATYPE(Apartment);
Q_DECLARE_METATYPE(Event);
Q_DECLARE_METATYPE(Reading);
Q_DECLARE_METATYPE(Counter);

/* Client class */
class Client : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasToken READ hasToken CONSTANT FINAL)
    Q_PROPERTY(bool isLogged READ getIsLogged CONSTANT FINAL)
    Q_PROPERTY(User currentUser READ getCurrentUser WRITE setCurrentUser NOTIFY currentUserChanged FINAL)
    Q_PROPERTY(QList<House> housesList READ getHousesList WRITE setHousesList NOTIFY housesListChanged FINAL)
    Q_PROPERTY(QList<Apartment> apartmentsList READ getApartmentsList WRITE setApartmentsList NOTIFY apartmentsListChanged FINAL)
    Q_PROPERTY(QStringList apartmentsAddresses READ getApartmentsAddresses WRITE setApartmentsAddresses NOTIFY apartmentsAddressesChanged FINAL)
    Q_PROPERTY(QList<Event> eventsList READ getEventsList WRITE setEventsList NOTIFY eventsListChanged FINAL)
    Q_PROPERTY(QList<Counter> countersList READ getCountersList WRITE setCountersList NOTIFY countersListChanged FINAL)
    Q_PROPERTY(QList<Reading> readingsList READ getReadingsList WRITE setReadingsList NOTIFY readingsListChanged FINAL)
    Q_PROPERTY(QList<Apartment> houseApartmentsList READ getHouseApartmentsList WRITE setHouseApartmentsList NOTIFY houseApartmentsListChanged FINAL)
    Q_PROPERTY(QList<User> apartmentResidents READ getApartmentResidents WRITE setApartmentResidents NOTIFY apartmentResidentsChanged FINAL)
    Q_PROPERTY(QList<Request> requestsList READ getRequestsList WRITE setRequestsList NOTIFY requestsListChanged FINAL)

public:
    explicit Client(QObject *parent = nullptr);
    ~Client();

    bool getIsLogged() const;
    User getCurrentUser() const;
    void setCurrentUser(const User &newCurrentUser);

    QList<House> getHousesList();
    void setHousesList(const QList<House> &newHousesList);

    QList<Apartment> getApartmentsList() const;
    void setApartmentsList(const QList<Apartment> &newApartmentsList);

    QStringList getApartmentsAddresses() const;
    void setApartmentsAddresses(const QStringList &newApartmentsAddresses);

    QList<Event> getEventsList() const;
    void setEventsList(const QList<Event> &newEventsList);

    QList<Counter> getCountersList() const;
    void setCountersList(const QList<Counter> &newCountersList);

    QList<Reading> getReadingsList() const;
    void setReadingsList(const QList<Reading> &newReadingsList);

    QList<Apartment> getHouseApartmentsList() const;
    void setHouseApartmentsList(const QList<Apartment> &newHouseApartmentsList);

    QList<User> getApartmentResidents() const;
    void setApartmentResidents(const QList<User> &newApartmentResidents);

    QList<Request> getRequestsList() const;
    void setRequestsList(const QList<Request> &newRequestsList);

public slots:
    void logoutUser();
    Task* checkLogged();
    Task* loginUser(QString email, QString password);
    Task* registerUser(QString email, QString password, QString name, QString surname);
    Task* retrieveHousesList();
    Task* retrieveApartmentList();
    Task* retrieveHouseApartmentList(QString houseId);
    Task* retrieveEventsList();
    Task* retrieveCountersList(QString apartmentId);
    Task* retrieveReadingsList(QString counterId);
    Task* retrieveRequestsList(QString houseId);

    // Task* retrieveUser();
    Task* createCounter(QString apartmentId, QString serialNumber, QString type, QString name, float value);
    Task* deleteCounter(QString counterId);
    Task* addCounterReading(QString counterId, float value);
    Task* deleteCounterReading(QString readingId);
    Task* changeHouse(QString houseId, QString info = "", int startReadingDay = 0, int endReadingDay = 0);
    Task* createEvent(QString houseId, QString type, QString title, QString details);
    Task* createApartment(QString houseId, QString ownerEmail, int entrance, int number, int floor);
    Task* deleteApartment(QString apartmentId);
    Task* updateProfile(QString password = "", QString name = "", QString surname = "");
    Task* retrieveApartmentResidents(QString apartmentId);
    Task* changeApartmentOwner(QString apartmentId, QString ownerEmail);
    Task* addResident(QString apartmentId, QString residentEmail);
    Task* deleteResident(QString apartmentId, QString residentId);
    Task* formTable(QString houseId, int year, int month);
    void markEvent(QString eventId, bool read);
    void resolveRequest(QString requestId, bool positive);

    Apartment getApartmentById(const QString& id);
    House getHouseById(const QString& houseId);
    Apartment getApartmentByAddress(const QString& address);

    QString &errorString();

private:
    bool hasToken();
    QJsonObject parseResponseData(bool &ok, QNetworkReply* reply);
    QNetworkReply *makeAuthorizedGet(QString method, QUrlQuery query);

signals:
    void registerError();
    void loginError();
    void loggedIn();
    void loggedOut();

    void currentUserChanged();
    void housesListChanged();
    void apartmentsListChanged();
    void apartmentsAddressesChanged();

    void eventsListChanged();
    void countersListChanged();
    void readingsListChanged();

    void houseApartmentsListChanged();

    void apartmentResidentsChanged();

    void requestsListChanged();

private:
    bool isLogged;

    User currentUser;
    QString token = "";
    QString hostname = "https://vkr123.devoidai.com/";

    QList<Request> requestsList;
    QList<House> housesList;
    QList<Apartment> apartmentsList;
    QList<Apartment> houseApartmentsList;
    QList<Event> eventsList;
    QList<Counter> countersList;
    QList<Reading> readingsList;
    QList<User> apartmentResidents;
    QStringList apartmentsAddresses;
    QMap<QString, QString> apartmentIdByAddresses;

    QNetworkAccessManager *manager;
    QString error;
};

#endif // CLIENT_H
