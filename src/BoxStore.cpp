#include "BoxStore.h"
#include "BoxProtocol.h"

#include <QDebug>
#include <QDir>
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
// A gps reply can take a few seconds on real hardware (the box reads its
// GPS module) — the protocol asks for a read timeout of at least 5 s.
constexpr int GPS_TIMEOUT_MS = 6000;
constexpr int GPS_POLL_INTERVAL_MS = 5000;
}

BoxStore::BoxStore(QObject *parent)
    : QAbstractListModel(parent)
{
    openDatabase();
    loadBoxes();

    m_pollTimer.setInterval(POLL_INTERVAL_MS);
    connect(&m_pollTimer, &QTimer::timeout, this, &BoxStore::pingAll);

    m_gpsPollTimer.setInterval(GPS_POLL_INTERVAL_MS);
    connect(&m_gpsPollTimer, &QTimer::timeout, this, &BoxStore::pollGps);
}

void BoxStore::openDatabase()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    m_db.setDatabaseName(dir + QStringLiteral("/boxes.db"));
    if (!m_db.open()) {
        qWarning() << "[BoxStore] failed to open database:" << m_db.lastError().text();
        return;
    }

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS boxes ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "name TEXT NOT NULL, "
            "ip_address TEXT NOT NULL)"))) {
        qWarning() << "[BoxStore] failed to create table:" << query.lastError().text();
    }
}

void BoxStore::loadBoxes()
{
    if (!m_db.isOpen())
        return;

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral("SELECT id, name, ip_address FROM boxes ORDER BY id"))) {
        qWarning() << "[BoxStore] failed to load boxes:" << query.lastError().text();
        return;
    }

    beginResetModel();
    m_boxes.clear();
    while (query.next()) {
        Box box;
        box.id = query.value(0).toInt();
        box.name = query.value(1).toString();
        box.ipAddress = query.value(2).toString();
        m_boxes.append(box);
    }
    endResetModel();
    emit countChanged();
}

int BoxStore::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_boxes.size();
}

QVariant BoxStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_boxes.size())
        return {};

    const Box &box = m_boxes.at(index.row());
    switch (role) {
    case NameRole:
        return box.name;
    case IpAddressRole:
        return box.ipAddress;
    case StatusRole:
        return box.status;
    case LatitudeRole:
        return box.latitude;
    case LongitudeRole:
        return box.longitude;
    case HasPositionRole:
        return box.hasPosition;
    case SatellitesRole:
        return box.satellites;
    }
    return {};
}

QHash<int, QByteArray> BoxStore::roleNames() const
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

int BoxStore::count() const
{
    return m_boxes.size();
}

bool BoxStore::pollingActive() const
{
    return m_pollTimer.isActive();
}

void BoxStore::setPollingActive(bool active)
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

bool BoxStore::gpsPollingActive() const
{
    return m_gpsPollTimer.isActive();
}

void BoxStore::setGpsPollingActive(bool active)
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

bool BoxStore::connecting() const
{
    return m_connecting;
}

void BoxStore::connectBox(const QString &name, const QString &ipAddress)
{
    if (m_connecting)
        return;

    const QString trimmedName = name.trimmed();
    const QString trimmedIp = ipAddress.trimmed();
    if (trimmedName.isEmpty() || trimmedIp.isEmpty()) {
        emit connectFailed(tr("Name and IP address are required"));
        return;
    }

    for (const Box &box : std::as_const(m_boxes)) {
        if (box.ipAddress == trimmedIp) {
            emit connectFailed(tr("A box with this IP address is already added"));
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

        addBox(trimmedName, trimmedIp);
        applyPosition(m_boxes.size() - 1, data.value(QStringLiteral("gps")).toObject());
        emit connectSucceeded(trimmedName, trimmedIp);
    });
}

void BoxStore::addBox(const QString &name, const QString &ipAddress)
{
    Box box;
    box.name = name;
    box.ipAddress = ipAddress;
    box.status = Connected;

    if (m_db.isOpen()) {
        QSqlQuery query(m_db);
        query.prepare(QStringLiteral("INSERT INTO boxes (name, ip_address) VALUES (?, ?)"));
        query.addBindValue(name);
        query.addBindValue(ipAddress);
        if (query.exec())
            box.id = query.lastInsertId().toInt();
        else
            qWarning() << "[BoxStore] failed to insert box:" << query.lastError().text();
    }

    beginInsertRows(QModelIndex(), m_boxes.size(), m_boxes.size());
    m_boxes.append(box);
    endInsertRows();
    emit countChanged();
}

void BoxStore::removeBox(int row)
{
    if (row < 0 || row >= m_boxes.size())
        return;

    const int id = m_boxes.at(row).id;
    if (m_db.isOpen() && id > 0) {
        QSqlQuery query(m_db);
        query.prepare(QStringLiteral("DELETE FROM boxes WHERE id = ?"));
        query.addBindValue(id);
        if (!query.exec())
            qWarning() << "[BoxStore] failed to delete box:" << query.lastError().text();
    }

    beginRemoveRows(QModelIndex(), row, row);
    m_boxes.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

QVariantMap BoxStore::boxAt(int row) const
{
    if (row < 0 || row >= m_boxes.size())
        return {};

    const Box &box = m_boxes.at(row);
    return {
        { QStringLiteral("name"), box.name },
        { QStringLiteral("ipAddress"), box.ipAddress },
        { QStringLiteral("status"), box.status },
        { QStringLiteral("latitude"), box.latitude },
        { QStringLiteral("longitude"), box.longitude },
        { QStringLiteral("hasPosition"), box.hasPosition },
        { QStringLiteral("satellites"), box.satellites },
    };
}

QString BoxStore::videoUriFor(const QString &ipAddress) const
{
    if (ipAddress.trimmed().isEmpty())
        return {};
    return BoxProtocol::videoUri(ipAddress.trimmed());
}

void BoxStore::pingAll()
{
    for (int row = 0; row < m_boxes.size(); ++row) {
        Box &box = m_boxes[row];
        if (box.pingInFlight)
            continue;
        box.pingInFlight = true;

        const int id = box.id;
        requestCommand(box.ipAddress, QStringLiteral("ping"), PING_TIMEOUT_MS,
                       [this, id](bool ok, const QJsonObject &data, const QString &) {
            const int row = rowForId(id);
            if (row < 0)
                return;
            m_boxes[row].pingInFlight = false;
            setStatus(row, ok ? Connected : Offline);
            if (ok)
                applyPosition(row, data.value(QStringLiteral("gps")).toObject());
        });
    }
}

void BoxStore::pollGps()
{
    for (int row = 0; row < m_boxes.size(); ++row) {
        Box &box = m_boxes[row];
        if (box.gpsInFlight)
            continue;
        box.gpsInFlight = true;

        const int id = box.id;
        requestCommand(box.ipAddress, QStringLiteral("gps"), GPS_TIMEOUT_MS,
                       [this, id](bool ok, const QJsonObject &data, const QString &) {
            const int row = rowForId(id);
            if (row < 0)
                return;

            if (ok) {
                m_boxes[row].gpsInFlight = false;
                applyPosition(row, data);
                return;
            }

            // A failure (unreachable, GPS_NO_FIX, ...) keeps the last known
            // position instead of dropping the marker off the map.
            if (m_boxes[row].hasPosition) {
                m_boxes[row].gpsInFlight = false;
                return;
            }

            // Nothing to draw yet: the box caches its last fix and reports it
            // in ping — use that until a live read succeeds.
            requestCommand(m_boxes[row].ipAddress, QStringLiteral("ping"), PING_TIMEOUT_MS,
                           [this, id](bool ok, const QJsonObject &data, const QString &) {
                const int row = rowForId(id);
                if (row < 0)
                    return;
                m_boxes[row].gpsInFlight = false;
                if (ok)
                    applyPosition(row, data.value(QStringLiteral("gps")).toObject());
            });
        });
    }
}

void BoxStore::applyPosition(int row, const QJsonObject &position)
{
    if (row < 0 || row >= m_boxes.size())
        return;
    if (!position.value(QStringLiteral("latitude")).isDouble()
        || !position.value(QStringLiteral("longitude")).isDouble())
        return;

    const double latitude = position.value(QStringLiteral("latitude")).toDouble();
    const double longitude = position.value(QStringLiteral("longitude")).toDouble();
    const QJsonValue satellitesValue = position.value(QStringLiteral("satellites"));
    const int satellites = satellitesValue.isDouble() ? satellitesValue.toInt() : -1;

    Box &box = m_boxes[row];
    if (box.hasPosition && box.latitude == latitude && box.longitude == longitude
        && (satellites < 0 || box.satellites == satellites))
        return;

    box.latitude = latitude;
    box.longitude = longitude;
    box.hasPosition = true;
    if (satellites >= 0)
        box.satellites = satellites;
    const QModelIndex modelIndex = index(row);
    emit dataChanged(modelIndex, modelIndex,
                     { LatitudeRole, LongitudeRole, HasPositionRole, SatellitesRole });
}

int BoxStore::rowForId(int id) const
{
    for (int row = 0; row < m_boxes.size(); ++row) {
        if (m_boxes.at(row).id == id)
            return row;
    }
    return -1;
}

void BoxStore::setStatus(int row, int status)
{
    if (m_boxes.at(row).status == status)
        return;
    m_boxes[row].status = status;
    const QModelIndex modelIndex = index(row);
    emit dataChanged(modelIndex, modelIndex, { StatusRole });
}

void BoxStore::requestCommand(const QString &host, const QString &command, int timeoutMs,
                              std::function<void(bool, const QJsonObject &, const QString &)> callback)
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
            finish(false, {}, tr("Invalid reply from box"));
            return true;
        }

        const QJsonObject reply = doc.object();
        if (reply.value(QStringLiteral("status")).toString() == QLatin1String("ok")) {
            finish(true, reply.value(QStringLiteral("data")).toObject(), {});
        } else {
            const QString message = reply.value(QStringLiteral("error")).toObject()
                                        .value(QStringLiteral("message")).toString();
            finish(false, {}, message.isEmpty() ? tr("Box reported an error") : message);
        }
        return true;
    };

    timer->setSingleShot(true);
    timer->setInterval(timeoutMs);
    connect(timer, &QTimer::timeout, socket, [finish]() {
        finish(false, {}, tr("Box did not respond (timed out)"));
    });

    connect(socket, &QTcpSocket::connected, socket, [socket, command]() {
        const QJsonObject request{
            { QStringLiteral("id"), 1 },
            { QStringLiteral("command"), command },
        };
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
    socket->connectToHost(host, static_cast<quint16>(BoxProtocol::COMMAND_PORT));
}
