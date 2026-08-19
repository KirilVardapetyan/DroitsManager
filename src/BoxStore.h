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

class BoxStore : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool pollingActive READ pollingActive WRITE setPollingActive NOTIFY pollingActiveChanged)
    Q_PROPERTY(bool gpsPollingActive READ gpsPollingActive WRITE setGpsPollingActive NOTIFY gpsPollingActiveChanged)
    Q_PROPERTY(bool connecting READ connecting NOTIFY connectingChanged)

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

    explicit BoxStore(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    bool pollingActive() const;
    void setPollingActive(bool active);

    bool gpsPollingActive() const;
    void setGpsPollingActive(bool active);

    bool connecting() const;

    Q_INVOKABLE void connectBox(const QString &name, const QString &ipAddress);
    Q_INVOKABLE void removeBox(int row);
    Q_INVOKABLE QVariantMap boxAt(int row) const;
    Q_INVOKABLE QString videoUriFor(const QString &ipAddress) const;

signals:
    void countChanged();
    void pollingActiveChanged();
    void gpsPollingActiveChanged();
    void connectingChanged();
    void connectSucceeded(const QString &name, const QString &ipAddress);
    void connectFailed(const QString &error);

private:
    struct Box {
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
    void loadBoxes();
    void addBox(const QString &name, const QString &ipAddress);
    void pingAll();
    void pollGps();
    void requestCommand(const QString &host, const QString &command, int timeoutMs,
                        std::function<void(bool ok, const QJsonObject &data, const QString &error)> callback);
    int rowForId(int id) const;
    void setStatus(int row, int status);
    void applyPosition(int row, const QJsonObject &position);

    QSqlDatabase m_db;
    QList<Box> m_boxes;
    QTimer m_pollTimer;
    QTimer m_gpsPollTimer;
    bool m_connecting = false;
};
