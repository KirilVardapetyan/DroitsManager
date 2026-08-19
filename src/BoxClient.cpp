#include "BoxClient.h"
#include "BoxProtocol.h"

#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTcpSocket>
#include <QTimer>

namespace {
constexpr int COMMAND_TIMEOUT_MS = 3000;
}

BoxClient::BoxClient(QObject *parent)
    : QObject(parent)
    , m_socket(new QTcpSocket(this))
    , m_timer(new QTimer(this))
    , m_port(BoxProtocol::COMMAND_PORT)
{
    m_timer->setSingleShot(true);
    m_timer->setInterval(COMMAND_TIMEOUT_MS);

    connect(m_socket, &QTcpSocket::connected, this, &BoxClient::onConnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &BoxClient::onReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &BoxClient::onDisconnected);
    connect(m_socket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError error) {
        if (!m_busy)
            return;
        // The peer closing after its reply is a normal end of exchange, not a failure.
        if (error == QAbstractSocket::RemoteHostClosedError)
            return;
        finish(false, m_socket->errorString());
    });
    connect(m_timer, &QTimer::timeout, this, &BoxClient::onTimeout);
}

QString BoxClient::host() const
{
    return m_host;
}

void BoxClient::setHost(const QString &host)
{
    if (m_host == host)
        return;
    m_host = host;
    emit hostChanged();
}

int BoxClient::port() const
{
    return m_port;
}

void BoxClient::setPort(int port)
{
    if (m_port == port)
        return;
    m_port = port;
    emit portChanged();
}

bool BoxClient::busy() const
{
    return m_busy;
}

QString BoxClient::statusMessage() const
{
    return m_statusMessage;
}

bool BoxClient::hasError() const
{
    return m_hasError;
}

void BoxClient::openBox()
{
    sendCommand(QStringLiteral("open"));
}

void BoxClient::closeBox()
{
    sendCommand(QStringLiteral("close"));
}

void BoxClient::sendCommand(const QString &command)
{
    if (m_busy)
        return;

    m_socket->abort();
    m_buffer.clear();
    m_pendingCommand = command;
    ++m_requestId;

    m_busy = true;
    m_hasError = false;
    m_statusMessage = QStringLiteral("Connecting…");
    emit busyChanged();
    emit hasErrorChanged();
    emit statusMessageChanged();

    m_timer->start();
    m_socket->connectToHost(m_host, static_cast<quint16>(m_port));
}

void BoxClient::onConnected()
{
    if (!m_busy)
        return;

    m_statusMessage = QStringLiteral("Sending %1…").arg(m_pendingCommand);
    emit statusMessageChanged();

    const QJsonObject request{
        { QStringLiteral("id"), m_requestId },
        { QStringLiteral("command"), m_pendingCommand },
    };
    m_socket->write(QJsonDocument(request).toJson(QJsonDocument::Compact) + '\n');
}

void BoxClient::onReadyRead()
{
    if (!m_busy)
        return;

    m_buffer.append(m_socket->readAll());
    if (m_buffer.contains('\n'))
        evaluateReply();
}

void BoxClient::onDisconnected()
{
    if (!m_busy)
        return;

    m_buffer.append(m_socket->readAll());
    evaluateReply();
}

void BoxClient::onTimeout()
{
    if (!m_busy)
        return;

    const bool connected = m_socket->state() == QAbstractSocket::ConnectedState;
    finish(false,
           connected ? QStringLiteral("No reply from box (timed out)")
                     : QStringLiteral("Connection timed out"));
}

void BoxClient::evaluateReply()
{
    const int newline = m_buffer.indexOf('\n');
    const QByteArray line = newline >= 0 ? m_buffer.left(newline) : m_buffer;

    if (line.trimmed().isEmpty()) {
        finish(false, QStringLiteral("Connection closed before a reply arrived"));
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(line);
    if (!doc.isObject()) {
        finish(false, QStringLiteral("Invalid reply: %1").arg(QString::fromUtf8(line.trimmed())));
        return;
    }

    const QJsonObject reply = doc.object();
    if (reply.value(QStringLiteral("status")).toString() != QLatin1String("ok")) {
        const QJsonObject error = reply.value(QStringLiteral("error")).toObject();
        const QString message = error.value(QStringLiteral("message")).toString();
        finish(false, message.isEmpty() ? QStringLiteral("Box reported an error") : message);
        return;
    }

    finish(true,
           m_pendingCommand == QLatin1String("open") ? QStringLiteral("Box opened")
                                                     : QStringLiteral("Box closed"));
}

void BoxClient::finish(bool success, const QString &message)
{
    const QString command = m_pendingCommand;

    // Cleared first so the signals emitted by abort() are ignored by the handlers.
    m_busy = false;
    m_timer->stop();
    m_socket->abort();
    m_buffer.clear();
    m_pendingCommand.clear();

    m_statusMessage = message;
    m_hasError = !success;
    emit statusMessageChanged();
    emit hasErrorChanged();
    emit busyChanged();

    if (success) {
        emit commandSucceeded(command);
        return;
    }

    qWarning() << "[BoxClient] command" << command << "failed:" << message;
    emit commandFailed(command, message);
}
