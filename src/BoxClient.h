#pragma once

#include <QByteArray>
#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class QTcpSocket;
class QTimer;

class BoxClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged)
    Q_PROPERTY(int port READ port WRITE setPort NOTIFY portChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY hasErrorChanged)

public:
    explicit BoxClient(QObject *parent = nullptr);

    QString host() const;
    void setHost(const QString &host);

    int port() const;
    void setPort(int port);

    bool busy() const;
    QString statusMessage() const;
    bool hasError() const;

    Q_INVOKABLE void openBox();
    Q_INVOKABLE void closeBox();

signals:
    void hostChanged();
    void portChanged();
    void busyChanged();
    void statusMessageChanged();
    void hasErrorChanged();

    void commandSucceeded(const QString &command);
    void commandFailed(const QString &command, const QString &error);

private:
    void sendCommand(const QString &command);
    void onConnected();
    void onReadyRead();
    void onDisconnected();
    void onTimeout();
    void evaluateReply();
    void finish(bool success, const QString &message);

    QTcpSocket *m_socket = nullptr;
    QTimer *m_timer = nullptr;

    QString m_host;
    int m_port;
    bool m_busy = false;
    bool m_hasError = false;
    QString m_statusMessage;

    QString m_pendingCommand;
    int m_requestId = 0;
    QByteArray m_buffer;
};
