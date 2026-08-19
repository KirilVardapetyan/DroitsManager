#pragma once

#include <QAbstractListModel>
#include <QJsonObject>
#include <QList>
#include <QSqlDatabase>
#include <QString>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include <functional>

class DroneStore : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool pollingActive READ pollingActive WRITE setPollingActive NOTIFY pollingActiveChanged)
    Q_PROPERTY(bool gpsPollingActive READ gpsPollingActive WRITE setGpsPollingActive NOTIFY gpsPollingActiveChanged)
    Q_PROPERTY(bool connecting READ connecting NOTIFY connectingChanged)
    Q_PROPERTY(bool uploadingMission READ uploadingMission NOTIFY uploadingMissionChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        IpAddressRole,
        StatusRole,
        LatitudeRole,
        LongitudeRole,
        HasPositionRole,
        SatellitesRole,
    };

    // Values match DroidStatusBadge.Status in QML.
    enum Status {
        Offline = 0,
        Connected = 1,
    };
    Q_ENUM(Status)

    explicit DroneStore(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    bool pollingActive() const;
    void setPollingActive(bool active);

    bool gpsPollingActive() const;
    void setGpsPollingActive(bool active);

    bool connecting() const;
    bool uploadingMission() const;

    Q_INVOKABLE void connectDrone(const QString &name, const QString &ipAddress);
    Q_INVOKABLE void removeDrone(int row);
    Q_INVOKABLE QVariantMap droneAt(int row) const;
    Q_INVOKABLE void uploadMission(const QString &ipAddress, const QVariantList &waypoints);

signals:
    void countChanged();
    void pollingActiveChanged();
    void gpsPollingActiveChanged();
    void connectingChanged();
    void connectSucceeded(const QString &name, const QString &ipAddress);
    void connectFailed(const QString &error);
    void uploadingMissionChanged();
    void missionUploadSucceeded(int uploadedWaypoints);
    void missionUploadFailed(const QString &error);

private:
    struct Drone {
        int id = 0;
        QString name;
        QString ipAddress;
        int status = Offline;
        bool pingInFlight = false;
        double latitude = 0;
        double longitude = 0;
        bool hasPosition = false;
        int satellites = -1;
        bool gpsInFlight = false;
    };

    void openDatabase();
    void loadDrones();
    void addDrone(const QString &name, const QString &ipAddress);
    void pingAll();
    void pollGps();
    void requestCommand(const QString &host, const QString &command, int timeoutMs,
                        std::function<void(bool ok, const QJsonObject &data, const QString &error)> callback,
                        const QJsonObject &params = QJsonObject());
    int rowForId(int id) const;
    void setStatus(int row, int status);
    void applyPosition(int row, const QJsonObject &position);

    QSqlDatabase m_db;
    QList<Drone> m_drones;
    QTimer m_pollTimer;
    QTimer m_gpsPollTimer;
    bool m_connecting = false;
    bool m_uploadingMission = false;
};
