#ifndef BLUETOOTHMONITOR_H
#define BLUETOOTHMONITOR_H

#include <QObject>
#include <QtDBus/QtDBus>

// Forward declarations for D-Bus types
typedef QMap<QDBusObjectPath, QMap<QString, QVariantMap>> ManagedObjectList;
Q_DECLARE_METATYPE(ManagedObjectList)

class BluetoothMonitor : public QObject, protected QDBusContext
{
    Q_OBJECT
public:
    explicit BluetoothMonitor(QObject *parent = nullptr);
    ~BluetoothMonitor();

    bool checkAlreadyConnectedDevices();

    // LibrePods HiiT: AirPods paired with this computer but not connected, as {address, name}
    QList<QPair<QString, QString>> pairedDisconnectedAirPods();

    // LibrePods HiiT: asks BlueZ to connect a device (org.bluez.Device1.Connect), asynchronously
    void connectDevice(const QString &address);

signals:
    void deviceConnected(const QString &macAddress, const QString &deviceName);
    void deviceDisconnected(const QString &macAddress, const QString &deviceName);
    void pairedDevicesChanged();
    void connectFinished(bool success, const QString &error);

private slots:
    void onPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps);

private:
    QDBusConnection m_dbus;
    void registerDBusService();
    bool isAirPodsDevice(const QString &devicePath);
    QString getDeviceName(const QString &devicePath);
    ManagedObjectList managedObjects();
};

#endif // BLUETOOTHMONITOR_H