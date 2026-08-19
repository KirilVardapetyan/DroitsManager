#include "DroneShell.h"
#include "DroneProtocol.h"

#include <QTcpSocket>
#include <QTimer>

namespace {
// Control commands wait for autopilot confirmation, which can take a few
// seconds — the protocol asks clients for at least a 5 s read timeout.
constexpr int REPLY_TIMEOUT_MS = 10000;
}

DroneShell::DroneShell(QObject *parent)
    : QObject(parent)
    , m_socket(new QTcpSocket(this))
    , m_replyTimer(new QTimer(this))
{
    m_replyTimer->setSingleShot(true);
    m_replyTimer->setInterval(REPLY_TIMEOUT_MS);

    connect(m_socket, &QTcpSocket::stateChanged, this, &DroneShell::onStateChanged);
    connect(m_socket, &QTcpSocket::readyRead, this, &DroneShell::onReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, [this]() {
        m_buffer.clear();
        setBusy(false);
    });
    connect(m_socket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        emit shellError(m_socket->errorString());
        setBusy(false);
    });
    connect(m_replyTimer, &QTimer::timeout, this, [this]() {
        emit shellError(tr("No reply within %1 s — a late reply will still be shown")
                            .arg(REPLY_TIMEOUT_MS / 1000));
        setBusy(false);
    });
}

QString DroneShell::host() const
{
    return m_host;
}

void DroneShell::setHost(const QString &host)
{
    if (m_host == host)
        return;
    m_host = host;
    emit hostChanged();
}

bool DroneShell::connected() const
{
    return m_connected;
}

bool DroneShell::connecting() const
{
    return m_connecting;
}

bool DroneShell::busy() const
{
    return m_busy;
}

void DroneShell::openConnection()
{
    m_socket->abort();
    m_buffer.clear();
    setBusy(false);
    m_socket->connectToHost(m_host, static_cast<quint16>(DroneProtocol::COMMAND_PORT));
}

void DroneShell::closeConnection()
{
    m_socket->abort();
    m_buffer.clear();
    setBusy(false);
    onStateChanged();
}

void DroneShell::sendLine(const QString &line)
{
    const QString trimmed = line.trimmed();
    if (trimmed.isEmpty())
        return;

    if (!m_connected) {
        emit shellError(tr("Not connected"));
        return;
    }
    if (m_busy)
        return;

    m_socket->write(trimmed.toUtf8() + '\n');
    setBusy(true);
    m_replyTimer->start();
    emit lineSent(trimmed);
}

void DroneShell::onStateChanged()
{
    const auto state = m_socket->state();
    const bool connected = state == QAbstractSocket::ConnectedState;
    const bool connecting = state == QAbstractSocket::HostLookupState
                            || state == QAbstractSocket::ConnectingState;

    if (m_connected != connected) {
        m_connected = connected;
        emit connectedChanged();
    }
    if (m_connecting != connecting) {
        m_connecting = connecting;
        emit connectingChanged();
    }
}

void DroneShell::onReadyRead()
{
    m_buffer.append(m_socket->readAll());

    int newline;
    while ((newline = m_buffer.indexOf('\n')) >= 0) {
        const QByteArray line = m_buffer.left(newline).trimmed();
        m_buffer.remove(0, newline + 1);
        if (line.isEmpty())
            continue;
        setBusy(false);
        m_replyTimer->stop();
        emit lineReceived(QString::fromUtf8(line));
    }
}

void DroneShell::setBusy(bool busy)
{
    if (busy == m_busy)
        return;
    m_busy = busy;
    if (!busy)
        m_replyTimer->stop();
    emit busyChanged();
}
