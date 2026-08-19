#include "DroneTelemetry.h"
#include "DroneProtocol.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QTcpSocket>

namespace {
// Telemetry poll rate. One shared timer drives every read on the connection,
// so changing the rate here (or via the updateHz property) retunes all of it.
constexpr int DEFAULT_UPDATE_HZ = 5;
// Ticks are skipped while this many replies are outstanding, so a slow link
// degrades to a lower rate instead of building an ever-growing backlog.
constexpr int MAX_PENDING_REPLIES = 4;
}

DroneTelemetry::DroneTelemetry(QObject *parent)
    : QObject(parent)
    , m_socket(new QTcpSocket(this))
    , m_updateHz(DEFAULT_UPDATE_HZ)
{
    m_timer.setInterval(1000 / m_updateHz);
    connect(&m_timer, &QTimer::timeout, this, &DroneTelemetry::onTick);

    connect(m_socket, &QTcpSocket::readyRead, this, &DroneTelemetry::onReadyRead);
    connect(m_socket, &QTcpSocket::stateChanged, this, [this]() {
        const bool connected = m_socket->state() == QAbstractSocket::ConnectedState;
        if (m_connected == connected)
            return;
        m_connected = connected;
        if (!connected)
            resetLink();
        emit connectedChanged();
    });
    connect(m_socket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        // Back to UnconnectedState so the next tick can retry the connect.
        m_socket->abort();
    });
}

QString DroneTelemetry::host() const
{
    return m_host;
}

void DroneTelemetry::setHost(const QString &host)
{
    if (m_host == host)
        return;
    m_host = host;
    m_socket->abort();
    emit hostChanged();
}

bool DroneTelemetry::active() const
{
    return m_active;
}

void DroneTelemetry::setActive(bool active)
{
    if (m_active == active)
        return;
    m_active = active;

    if (active) {
        m_timer.start();
        onTick();
    } else {
        m_timer.stop();
        m_socket->abort();
    }
    emit activeChanged();
}

int DroneTelemetry::updateHz() const
{
    return m_updateHz;
}

void DroneTelemetry::setUpdateHz(int hz)
{
    const int clamped = qBound(1, hz, 50);
    if (m_updateHz == clamped)
        return;
    m_updateHz = clamped;
    m_timer.setInterval(1000 / m_updateHz);
    emit updateHzChanged();
}

bool DroneTelemetry::connected() const
{
    return m_connected;
}

bool DroneTelemetry::hasAttitude() const
{
    return m_hasAttitude;
}

double DroneTelemetry::roll() const
{
    return m_roll;
}

double DroneTelemetry::pitch() const
{
    return m_pitch;
}

double DroneTelemetry::yaw() const
{
    return m_yaw;
}

bool DroneTelemetry::hasPosition() const
{
    return m_hasPosition;
}

double DroneTelemetry::latitude() const
{
    return m_latitude;
}

double DroneTelemetry::longitude() const
{
    return m_longitude;
}

int DroneTelemetry::satellites() const
{
    return m_satellites;
}

void DroneTelemetry::onTick()
{
    if (m_host.isEmpty())
        return;

    if (m_socket->state() == QAbstractSocket::UnconnectedState) {
        m_socket->connectToHost(m_host, static_cast<quint16>(DroneProtocol::COMMAND_PORT));
        return;
    }
    if (m_socket->state() != QAbstractSocket::ConnectedState)
        return;
    if (m_pending.size() >= MAX_PENDING_REPLIES)
        return;

    // Responses arrive strictly in request order on the connection, so the
    // queue of command names is enough to match them.
    m_socket->write(QByteArrayLiteral("{\"command\": \"get_attitude\"}\n"
                                      "{\"command\": \"get_gps\"}\n"));
    m_pending.enqueue(QStringLiteral("get_attitude"));
    m_pending.enqueue(QStringLiteral("get_gps"));
}

void DroneTelemetry::onReadyRead()
{
    m_buffer.append(m_socket->readAll());

    int newline;
    while ((newline = m_buffer.indexOf('\n')) >= 0) {
        const QByteArray line = m_buffer.left(newline);
        m_buffer.remove(0, newline + 1);
        if (line.trimmed().isEmpty() || m_pending.isEmpty())
            continue;
        handleReply(m_pending.dequeue(), line);
    }
}

void DroneTelemetry::handleReply(const QString &command, const QByteArray &line)
{
    const QJsonDocument doc = QJsonDocument::fromJson(line);
    if (!doc.isObject())
        return;

    const QJsonObject reply = doc.object();
    const bool ok = reply.value(QStringLiteral("success")).toBool();
    const QJsonObject data = reply.value(QStringLiteral("data")).toObject();

    if (command == QLatin1String("get_attitude")) {
        if (!ok) {
            if (m_hasAttitude) {
                m_hasAttitude = false;
                emit attitudeChanged();
            }
            return;
        }
        m_roll = data.value(QStringLiteral("roll")).toDouble();
        m_pitch = data.value(QStringLiteral("pitch")).toDouble();
        m_yaw = data.value(QStringLiteral("yaw")).toDouble();
        m_hasAttitude = true;
        emit attitudeChanged();
        return;
    }

    if (command == QLatin1String("get_gps")) {
        if (!ok)
            return;
        const QJsonValue satellitesValue = data.value(QStringLiteral("satellites"));
        if (satellitesValue.isDouble())
            m_satellites = satellitesValue.toInt();
        // Position fields are null while there is no fix — keep the last
        // known coordinates in that case.
        if (data.value(QStringLiteral("latitude")).isDouble()
            && data.value(QStringLiteral("longitude")).isDouble()) {
            m_latitude = data.value(QStringLiteral("latitude")).toDouble();
            m_longitude = data.value(QStringLiteral("longitude")).toDouble();
            m_hasPosition = true;
        }
        emit positionChanged();
    }
}

void DroneTelemetry::resetLink()
{
    m_pending.clear();
    m_buffer.clear();
    if (m_hasAttitude) {
        m_hasAttitude = false;
        emit attitudeChanged();
    }
}
