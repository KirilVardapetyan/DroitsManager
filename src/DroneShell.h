#pragma once

#include <QByteArray>
#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class QTcpSocket;
class QTimer;

class DroneShell : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(bool connecting READ connecting NOTIFY connectingChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit DroneShell(QObject *parent = nullptr);

    QString host() const;
    void setHost(const QString &host);

    bool connected() const;
    bool connecting() const;
    bool busy() const;

    Q_INVOKABLE void openConnection();
    Q_INVOKABLE void closeConnection();
    Q_INVOKABLE void sendLine(const QString &line);

signals:
    void hostChanged();
    void connectedChanged();
    void connectingChanged();
    void busyChanged();

    void lineSent(const QString &line);
    void lineReceived(const QString &line);
    void shellError(const QString &message);

private:
    void onStateChanged();
    void onReadyRead();
    void setBusy(bool busy);

    QTcpSocket *m_socket = nullptr;
    QTimer *m_replyTimer = nullptr;

    QString m_host;
    bool m_connected = false;
    bool m_connecting = false;
    bool m_busy = false;
    QByteArray m_buffer;
};
