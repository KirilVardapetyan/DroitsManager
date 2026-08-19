#pragma once

#include <QByteArray>
#include <QObject>
#include <QQueue>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class QTcpSocket;

class DroneTelemetry : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int updateHz READ updateHz WRITE setUpdateHz NOTIFY updateHzChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

    Q_PROPERTY(bool hasAttitude READ hasAttitude NOTIFY attitudeChanged)
    Q_PROPERTY(double roll READ roll NOTIFY attitudeChanged)
    Q_PROPERTY(double pitch READ pitch NOTIFY attitudeChanged)
    Q_PROPERTY(double yaw READ yaw NOTIFY attitudeChanged)

    Q_PROPERTY(bool hasPosition READ hasPosition NOTIFY positionChanged)
    Q_PROPERTY(double latitude READ latitude NOTIFY positionChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY positionChanged)
    Q_PROPERTY(int satellites READ satellites NOTIFY positionChanged)

public:
    explicit DroneTelemetry(QObject *parent = nullptr);

    QString host() const;
    void setHost(const QString &host);

    bool active() const;
    void setActive(bool active);

    int updateHz() const;
    void setUpdateHz(int hz);

    bool connected() const;

    bool hasAttitude() const;
    double roll() const;
    double pitch() const;
    double yaw() const;

    bool hasPosition() const;
    double latitude() const;
    double longitude() const;
    int satellites() const;

signals:
    void hostChanged();
    void activeChanged();
    void updateHzChanged();
    void connectedChanged();
    void attitudeChanged();
    void positionChanged();

private:
    void onTick();
    void onReadyRead();
    void handleReply(const QString &command, const QByteArray &line);
    void resetLink();

    QTcpSocket *m_socket = nullptr;
    QTimer m_timer;

    QString m_host;
    bool m_active = false;
    int m_updateHz;
    bool m_connected = false;

    bool m_hasAttitude = false;
    double m_roll = 0;
    double m_pitch = 0;
    double m_yaw = 0;

    bool m_hasPosition = false;
    double m_latitude = 0;
    double m_longitude = 0;
    int m_satellites = -1;

    QQueue<QString> m_pending;
    QByteArray m_buffer;
};
