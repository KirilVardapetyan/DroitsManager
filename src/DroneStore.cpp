#include "DroneStore.h"
#include "DroneProtocol.h"

#include <QDebug>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QTcpSocket>

#include <memory>

namespace {
constexpr int PING_TIMEOUT_MS = 2000;
constexpr int POLL_INTERVAL_MS = 3000;
// The protocol asks for a read timeout of at least 5 s on autopilot commands.
constexpr int GPS_TIMEOUT_MS = 6000;
constexpr int GPS_POLL_INTERVAL_MS = 5000;
// upload_mission runs the full MAVLink mission handshake and reads the
// mission back to verify it — give it plenty of time.
constexpr int UPLOAD_TIMEOUT_MS = 20000;
// Mode change and arming wait for autopilot confirmation.
constexpr int CONTROL_TIMEOUT_MS = 15000;
const QString DB_CONNECTION_NAME = QStringLiteral("drones");
}

DroneStore::DroneStore(QObject *parent)
    : QAbstractListModel(parent)
{
    openDatabase();
    loadDrones();

    m_pollTimer.setInterval(POLL_INTERVAL_MS);
    connect(&m_pollTimer, &QTimer::timeout, this, &DroneStore::pingAll);

    m_gpsPollTimer.setInterval(GPS_POLL_INTERVAL_MS);
    connect(&m_gpsPollTimer, &QTimer::timeout, this, &DroneStore::pollGps);
}

void DroneStore::openDatabase()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), DB_CONNECTION_NAME);
    m_db.setDatabaseName(dir + QStringLiteral("/drones.db"));
    if (!m_db.open()) {
        qWarning() << "[DroneStore] failed to open database:" << m_db.lastError().text();
        return;
    }

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS drones ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "name TEXT NOT NULL, "
            "ip_address TEXT NOT NULL)"))) {
        qWarning() << "[DroneStore] failed to create table:" << query.lastError().text();
    }
}

void DroneStore::loadDrones()
{
    if (!m_db.isOpen())
        return;

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral("SELECT id, name, ip_address FROM drones ORDER BY id"))) {
        qWarning() << "[DroneStore] failed to load drones:" << query.lastError().text();
        return;
    }

    beginResetModel();
    m_drones.clear();
    while (query.next()) {
        Drone drone;
        drone.id = query.value(0).toInt();
        drone.name = query.value(1).toString();
        drone.ipAddress = query.value(2).toString();
        m_drones.append(drone);
    }
    endResetModel();
    emit countChanged();
}

int DroneStore::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_drones.size();
}

QVariant DroneStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_drones.size())
        return {};

    const Drone &drone = m_drones.at(index.row());
    switch (role) {
    case NameRole:
        return drone.name;
    case IpAddressRole:
        return drone.ipAddress;
    case StatusRole:
        return drone.status;
    case LatitudeRole:
        return drone.latitude;
    case LongitudeRole:
        return drone.longitude;
    case HasPositionRole:
        return drone.hasPosition;
    case SatellitesRole:
        return drone.satellites;
    }
    return {};
}

QHash<int, QByteArray> DroneStore::roleNames() const
{
    return {
        { NameRole, "name" },
        { IpAddressRole, "ipAddress" },
        { StatusRole, "status" },
        { LatitudeRole, "latitude" },
        { LongitudeRole, "longitude" },
        { HasPositionRole, "hasPosition" },
        { SatellitesRole, "satellites" },
    };
}

int DroneStore::count() const
{
    return m_drones.size();
}

bool DroneStore::pollingActive() const
{
    return m_pollTimer.isActive();
}

void DroneStore::setPollingActive(bool active)
{
    if (active == m_pollTimer.isActive())
        return;

    if (active) {
        m_pollTimer.start();
        pingAll();
    } else {
        m_pollTimer.stop();
    }
    emit pollingActiveChanged();
}

bool DroneStore::gpsPollingActive() const
{
    return m_gpsPollTimer.isActive();
}

void DroneStore::setGpsPollingActive(bool active)
{
    if (active == m_gpsPollTimer.isActive())
        return;

    if (active) {
        m_gpsPollTimer.start();
        pollGps();
    } else {
        m_gpsPollTimer.stop();
    }
    emit gpsPollingActiveChanged();
}

bool DroneStore::connecting() const
{
    return m_connecting;
}

void DroneStore::connectDrone(const QString &name, const QString &ipAddress)
{
    if (m_connecting)
        return;

    const QString trimmedName = name.trimmed();
    const QString trimmedIp = ipAddress.trimmed();
    if (trimmedName.isEmpty() || trimmedIp.isEmpty()) {
        emit connectFailed(tr("Name and IP address are required"));
        return;
    }

    for (const Drone &drone : std::as_const(m_drones)) {
        if (drone.ipAddress == trimmedIp) {
            emit connectFailed(tr("A drone with this IP address is already added"));
            return;
        }
    }

    m_connecting = true;
    emit connectingChanged();

    requestCommand(trimmedIp, QStringLiteral("ping"), PING_TIMEOUT_MS,
                   [this, trimmedName, trimmedIp](bool ok, const QJsonObject &data, const QString &error) {
        m_connecting = false;
        emit connectingChanged();

        if (!ok) {
            emit connectFailed(error);
            return;
        }

        addDrone(trimmedName, trimmedIp);
        applyPosition(m_drones.size() - 1, data.value(QStringLiteral("gps")).toObject());
        emit connectSucceeded(trimmedName, trimmedIp);
    });
}

void DroneStore::addDrone(const QString &name, const QString &ipAddress)
{
    Drone drone;
    drone.name = name;
    drone.ipAddress = ipAddress;
    drone.status = Connected;

    if (m_db.isOpen()) {
        QSqlQuery query(m_db);
        query.prepare(QStringLiteral("INSERT INTO drones (name, ip_address) VALUES (?, ?)"));
        query.addBindValue(name);
        query.addBindValue(ipAddress);
        if (query.exec())
            drone.id = query.lastInsertId().toInt();
        else
            qWarning() << "[DroneStore] failed to insert drone:" << query.lastError().text();
    }

    beginInsertRows(QModelIndex(), m_drones.size(), m_drones.size());
    m_drones.append(drone);
    endInsertRows();
    emit countChanged();
}

void DroneStore::removeDrone(int row)
{
    if (row < 0 || row >= m_drones.size())
        return;

    const int id = m_drones.at(row).id;
    if (m_db.isOpen() && id > 0) {
        QSqlQuery query(m_db);
        query.prepare(QStringLiteral("DELETE FROM drones WHERE id = ?"));
        query.addBindValue(id);
        if (!query.exec())
            qWarning() << "[DroneStore] failed to delete drone:" << query.lastError().text();
    }

    beginRemoveRows(QModelIndex(), row, row);
    m_drones.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

QVariantMap DroneStore::droneAt(int row) const
{
    if (row < 0 || row >= m_drones.size())
        return {};

    const Drone &drone = m_drones.at(row);
    return {
        { QStringLiteral("name"), drone.name },
        { QStringLiteral("ipAddress"), drone.ipAddress },
        { QStringLiteral("status"), drone.status },
        { QStringLiteral("latitude"), drone.latitude },
        { QStringLiteral("longitude"), drone.longitude },
        { QStringLiteral("hasPosition"), drone.hasPosition },
        { QStringLiteral("satellites"), drone.satellites },
    };
}

void DroneStore::pingAll()
{
    for (int row = 0; row < m_drones.size(); ++row) {
        Drone &drone = m_drones[row];
        if (drone.pingInFlight)
            continue;
        drone.pingInFlight = true;

        const int id = drone.id;
        requestCommand(drone.ipAddress, QStringLiteral("ping"), PING_TIMEOUT_MS,
                       [this, id](bool ok, const QJsonObject &data, const QString &) {
            const int row = rowForId(id);
            if (row < 0)
                return;
            m_drones[row].pingInFlight = false;
            setStatus(row, ok ? Connected : Offline);
            if (ok)
                applyPosition(row, data.value(QStringLiteral("gps")).toObject());
        });
    }
}

bool DroneStore::uploadingMission() const
{
    return m_uploadingMission;
}

void DroneStore::uploadMission(const QString &ipAddress, const QVariantList &waypoints)
{
    if (m_uploadingMission)
        return;

    m_uploadingMission = true;
    emit uploadingMissionChanged();

    const QJsonObject params{
        { QStringLiteral("waypoints"), QJsonArray::fromVariantList(waypoints) },
    };
    requestCommand(ipAddress, QStringLiteral("upload_mission"), UPLOAD_TIMEOUT_MS,
                   [this](bool ok, const QJsonObject &data, const QString &error) {
        m_uploadingMission = false;
        emit uploadingMissionChanged();
        if (ok)
            emit missionUploadSucceeded(data.value(QStringLiteral("uploaded_waypoints")).toInt());
        else
            emit missionUploadFailed(error);
    }, params);
}

bool DroneStore::startingMission() const
{
    return m_startingMission;
}

void DroneStore::startMission(const QString &ipAddress)
{
    if (m_startingMission)
        return;

    m_startingMission = true;
    emit startingMissionChanged();

    // AUTO first, then arm: the armed vehicle immediately flies the stored
    // mission from its takeoff item.
    const QJsonObject params{
        { QStringLiteral("mode"), QStringLiteral("AUTO") },
    };
    requestCommand(ipAddress, QStringLiteral("set_flight_mode"), CONTROL_TIMEOUT_MS,
                   [this, ipAddress](bool ok, const QJsonObject &, const QString &error) {
        if (!ok) {
            m_startingMission = false;
            emit startingMissionChanged();
            emit missionStartFailed(tr("Flight mode: %1").arg(error));
            return;
        }

        requestCommand(ipAddress, QStringLiteral("arm"), CONTROL_TIMEOUT_MS,
                       [this](bool ok, const QJsonObject &, const QString &error) {
            m_startingMission = false;
            emit startingMissionChanged();
            if (ok)
                emit missionStartSucceeded();
            else
                emit missionStartFailed(tr("Arm: %1").arg(error));
        });
    }, params);
}

void DroneStore::pollGps()
{
    for (int row = 0; row < m_drones.size(); ++row) {
        Drone &drone = m_drones[row];
        if (drone.gpsInFlight)
            continue;
        drone.gpsInFlight = true;

        const int id = drone.id;
        requestCommand(drone.ipAddress, QStringLiteral("get_gps"), GPS_TIMEOUT_MS,
                       [this, id](bool ok, const QJsonObject &data, const QString &) {
            const int row = rowForId(id);
            if (row < 0)
                return;

            if (ok) {
                m_drones[row].gpsInFlight = false;
                // Without a satellite fix the call succeeds with null position
                // fields — applyPosition ignores those.
                applyPosition(row, data);
                return;
            }

            // A failure (unreachable, PIXHAWK_UNAVAILABLE, ...) keeps the last
            // known position instead of dropping the marker off the map.
            if (m_drones[row].hasPosition) {
                m_drones[row].gpsInFlight = false;
                return;
            }

            // Nothing to draw yet: ping answers even with a dead autopilot and
            // carries fresh coordinates when the drone has them.
            requestCommand(m_drones[row].ipAddress, QStringLiteral("ping"), PING_TIMEOUT_MS,
                           [this, id](bool ok, const QJsonObject &data, const QString &) {
                const int row = rowForId(id);
                if (row < 0)
                    return;
                m_drones[row].gpsInFlight = false;
                if (ok)
                    applyPosition(row, data.value(QStringLiteral("gps")).toObject());
            });
        });
    }
}

void DroneStore::applyPosition(int row, const QJsonObject &position)
{
    if (row < 0 || row >= m_drones.size())
        return;
    if (!position.value(QStringLiteral("latitude")).isDouble()
        || !position.value(QStringLiteral("longitude")).isDouble())
        return;

    const double latitude = position.value(QStringLiteral("latitude")).toDouble();
    const double longitude = position.value(QStringLiteral("longitude")).toDouble();
    const QJsonValue satellitesValue = position.value(QStringLiteral("satellites"));
    const int satellites = satellitesValue.isDouble() ? satellitesValue.toInt() : -1;

    Drone &drone = m_drones[row];
    if (drone.hasPosition && drone.latitude == latitude && drone.longitude == longitude
        && (satellites < 0 || drone.satellites == satellites))
        return;

    drone.latitude = latitude;
    drone.longitude = longitude;
    drone.hasPosition = true;
    if (satellites >= 0)
        drone.satellites = satellites;
    const QModelIndex modelIndex = index(row);
    emit dataChanged(modelIndex, modelIndex,
                     { LatitudeRole, LongitudeRole, HasPositionRole, SatellitesRole });
}

int DroneStore::rowForId(int id) const
{
    for (int row = 0; row < m_drones.size(); ++row) {
        if (m_drones.at(row).id == id)
            return row;
    }
    return -1;
}

void DroneStore::setStatus(int row, int status)
{
    if (m_drones.at(row).status == status)
        return;
    m_drones[row].status = status;
    const QModelIndex modelIndex = index(row);
    emit dataChanged(modelIndex, modelIndex, { StatusRole });
}

void DroneStore::requestCommand(const QString &host, const QString &command, int timeoutMs,
                                std::function<void(bool, const QJsonObject &, const QString &)> callback,
                                const QJsonObject &params)
{
    auto *socket = new QTcpSocket(this);
    auto *timer = new QTimer(socket);
    auto buffer = std::make_shared<QByteArray>();
    auto settled = std::make_shared<bool>(false);

    auto finish = [socket, settled, callback](bool ok, const QJsonObject &data, const QString &error) {
        if (*settled)
            return;
        *settled = true;
        socket->abort();
        socket->deleteLater();
        callback(ok, data, error);
    };

    auto evaluate = [buffer, finish]() {
        const int newline = buffer->indexOf('\n');
        if (newline < 0)
            return false;

        const QJsonDocument doc = QJsonDocument::fromJson(buffer->left(newline));
        if (!doc.isObject()) {
            finish(false, {}, tr("Invalid reply from drone"));
            return true;
        }

        const QJsonObject reply = doc.object();
        if (reply.value(QStringLiteral("success")).toBool()) {
            finish(true, reply.value(QStringLiteral("data")).toObject(), {});
        } else {
            const QString message = reply.value(QStringLiteral("error")).toObject()
                                        .value(QStringLiteral("message")).toString();
            finish(false, {}, message.isEmpty() ? tr("Drone reported an error") : message);
        }
        return true;
    };

    timer->setSingleShot(true);
    timer->setInterval(timeoutMs);
    connect(timer, &QTimer::timeout, socket, [finish]() {
        finish(false, {}, tr("Drone did not respond (timed out)"));
    });

    connect(socket, &QTcpSocket::connected, socket, [socket, command, params]() {
        // The envelope is strict: "command" (+ optional "params") only.
        QJsonObject request{
            { QStringLiteral("command"), command },
        };
        if (!params.isEmpty())
            request.insert(QStringLiteral("params"), params);
        socket->write(QJsonDocument(request).toJson(QJsonDocument::Compact) + '\n');
    });

    connect(socket, &QTcpSocket::readyRead, socket, [socket, buffer, evaluate]() {
        buffer->append(socket->readAll());
        evaluate();
    });

    connect(socket, &QTcpSocket::disconnected, socket, [socket, buffer, evaluate, finish]() {
        buffer->append(socket->readAll());
        if (!evaluate())
            finish(false, {}, tr("Connection closed before a reply arrived"));
    });

    connect(socket, &QTcpSocket::errorOccurred, socket,
            [socket, finish](QAbstractSocket::SocketError error) {
        if (error == QAbstractSocket::RemoteHostClosedError)
            return;
        finish(false, {}, socket->errorString());
    });

    timer->start();
    socket->connectToHost(host, static_cast<quint16>(DroneProtocol::COMMAND_PORT));
}
