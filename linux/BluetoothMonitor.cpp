#include "BluetoothMonitor.h"
#include "logger.h"

#include <QDebug>
#include <QDBusObjectPath>
#include <QDBusMetaType>

BluetoothMonitor::BluetoothMonitor(QObject *parent)
    : QObject(parent), m_dbus(QDBusConnection::systemBus())
{
    // Register meta-types for D-Bus interaction
    qDBusRegisterMetaType<QDBusObjectPath>();
    qDBusRegisterMetaType<ManagedObjectList>();

    if (!m_dbus.isConnected())
    {
        LOG_WARN("Failed to connect to system D-Bus");
        return;
    }

    registerDBusService();
    checkAlreadyConnectedDevices(); // Check for already connected devices on startup
}

BluetoothMonitor::~BluetoothMonitor()
{
    m_dbus.disconnectFromBus(m_dbus.name());
}

void BluetoothMonitor::registerDBusService()
{
    // Match signals for PropertiesChanged on any BlueZ Device interface
    if (!m_dbus.connect("", "", "org.freedesktop.DBus.Properties", "PropertiesChanged",
                        this, SLOT(onPropertiesChanged(QString, QVariantMap, QStringList))))
    {
        LOG_WARN("Failed to connect to D-Bus PropertiesChanged signal");
    }
}

bool BluetoothMonitor::isAirPodsDevice(const QString &devicePath)
{
    QDBusInterface deviceInterface("org.bluez", devicePath, "org.freedesktop.DBus.Properties", m_dbus);

    // Get UUIDs to check if it's an AirPods device
    QDBusReply<QVariant> uuidsReply = deviceInterface.call("Get", "org.bluez.Device1", "UUIDs");
    if (!uuidsReply.isValid())
    {
        return false;
    }

    QStringList uuids = uuidsReply.value().toStringList();
    return uuids.contains("74ec2172-0bad-4d01-8f77-997b2be0722a");
}

QString BluetoothMonitor::getDeviceName(const QString &devicePath)
{
    QDBusInterface deviceInterface("org.bluez", devicePath, "org.freedesktop.DBus.Properties", m_dbus);
    QDBusReply<QVariant> nameReply = deviceInterface.call("Get", "org.bluez.Device1", "Name");
    if (nameReply.isValid())
    {
        return nameReply.value().toString();
    }
    return "Unknown";
}

bool BluetoothMonitor::checkAlreadyConnectedDevices()
{
    QDBusInterface objectManager("org.bluez", "/", "org.freedesktop.DBus.ObjectManager", m_dbus);
    QDBusMessage reply = objectManager.call("GetManagedObjects");

    if (reply.type() == QDBusMessage::ErrorMessage)
    {
        LOG_WARN("Failed to get managed objects: " << reply.errorMessage());
        return false;
    }

    QVariant firstArg = reply.arguments().constFirst();
    QDBusArgument arg = firstArg.value<QDBusArgument>();
    ManagedObjectList managedObjects;
    arg >> managedObjects;

    bool deviceFound = false;

    for (auto it = managedObjects.constBegin(); it != managedObjects.constEnd(); ++it)
    {
        const QDBusObjectPath &objPath = it.key();
        const QMap<QString, QVariantMap> &interfaces = it.value();

        if (interfaces.contains("org.bluez.Device1"))
        {
            const QVariantMap &deviceProps = interfaces.value("org.bluez.Device1");

            // Check if the device has the necessary properties
            if (!deviceProps.contains("UUIDs") || !deviceProps.contains("Connected") ||
                !deviceProps.contains("Address") || !deviceProps.contains("Name"))
            {
                continue;
            }

            QStringList uuids = deviceProps["UUIDs"].toStringList();
            bool isAirPods = uuids.contains("74ec2172-0bad-4d01-8f77-997b2be0722a");

            if (isAirPods)
            {
                bool connected = deviceProps["Connected"].toBool();
                if (connected)
                {
                    QString macAddress = deviceProps["Address"].toString();
                    QString deviceName = deviceProps["Name"].toString();
                    emit deviceConnected(macAddress, deviceName);
                    LOG_DEBUG("Found already connected AirPods: " << macAddress << " Name: " << deviceName);
                    deviceFound = true;
                }
            }
        }
    }
    return deviceFound;
}

ManagedObjectList BluetoothMonitor::managedObjects()
{
    ManagedObjectList objects;
    QDBusInterface objectManager("org.bluez", "/", "org.freedesktop.DBus.ObjectManager", m_dbus);
    QDBusMessage reply = objectManager.call("GetManagedObjects");
    if (reply.type() == QDBusMessage::ErrorMessage)
    {
        LOG_WARN("Failed to get managed objects: " << reply.errorMessage());
        return objects;
    }
    reply.arguments().constFirst().value<QDBusArgument>() >> objects;
    return objects;
}

void BluetoothMonitor::connectDevice(const QString &address)
{
    // Calling BlueZ directly avoids `bluetoothctl connect`, which in non-interactive mode can
    // run before it has loaded the device list and report a paired device as "not available"
    const ManagedObjectList objects = managedObjects();
    QString path;
    for (auto it = objects.constBegin(); it != objects.constEnd(); ++it)
    {
        const QVariantMap deviceProps = it.value().value("org.bluez.Device1");
        if (deviceProps.value("Address").toString().compare(address, Qt::CaseInsensitive) == 0)
        {
            path = it.key().path();
            break;
        }
    }
    if (path.isEmpty())
    {
        emit connectFinished(false, QStringLiteral("device %1 not found in BlueZ").arg(address));
        return;
    }

    QDBusMessage call = QDBusMessage::createMethodCall("org.bluez", path, "org.bluez.Device1", "Connect");
    auto *watcher = new QDBusPendingCallWatcher(m_dbus.asyncCall(call, 30000), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *w) {
        const QDBusPendingReply<> reply = *w;
        w->deleteLater();
        emit connectFinished(!reply.isError(), reply.error().message());
    });
}

QList<QPair<QString, QString>> BluetoothMonitor::pairedDisconnectedAirPods()
{
    QList<QPair<QString, QString>> result;
    const ManagedObjectList objects = managedObjects();

    for (auto it = objects.constBegin(); it != objects.constEnd(); ++it)
    {
        const QVariantMap deviceProps = it.value().value("org.bluez.Device1");
        if (deviceProps.isEmpty())
            continue;
        if (!deviceProps.value("UUIDs").toStringList().contains("74ec2172-0bad-4d01-8f77-997b2be0722a"))
            continue;
        if (deviceProps.value("Paired").toBool() && !deviceProps.value("Connected").toBool())
            result.append({deviceProps.value("Address").toString(), deviceProps.value("Name").toString()});
    }
    return result;
}

void BluetoothMonitor::onPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps)
{
    Q_UNUSED(invalidatedProps);

    if (interface != "org.bluez.Device1")
    {
        return;
    }

    // LibrePods HiiT: pairing or unpairing changes what the UI can offer to connect. On a first
    // pairing BlueZ reports Connected before service discovery fills UUIDs, so the Connected
    // change below does not recognize the AirPods yet; when UUIDs arrive, pick the connection up.
    if (changedProps.contains("Paired") || changedProps.contains("UUIDs"))
    {
        const QString path = QDBusContext::message().path();
        if (isAirPodsDevice(path))
        {
            emit pairedDevicesChanged();

            QDBusInterface properties("org.bluez", path, "org.freedesktop.DBus.Properties", m_dbus);
            const QDBusReply<QVariant> connectedReply = properties.call("Get", "org.bluez.Device1", "Connected");
            const QDBusReply<QVariant> addressReply = properties.call("Get", "org.bluez.Device1", "Address");
            if (changedProps.contains("UUIDs") && !changedProps.contains("Connected")
                && connectedReply.isValid() && connectedReply.value().toBool() && addressReply.isValid())
            {
                const QString macAddress = addressReply.value().toString();
                emit deviceConnected(macAddress, getDeviceName(path));
                LOG_DEBUG("AirPods identified after connecting:" << macAddress);
            }
        }
    }

    if (changedProps.contains("Connected"))
    {
        bool connected = changedProps["Connected"].toBool();
        QString path = QDBusContext::message().path();

        if (!isAirPodsDevice(path))
        {
            return;
        }

        QDBusInterface deviceInterface("org.bluez", path, "org.freedesktop.DBus.Properties", m_dbus);

        // Get the device address
        QDBusReply<QVariant> addrReply = deviceInterface.call("Get", "org.bluez.Device1", "Address");
        if (!addrReply.isValid())
        {
            return;
        }
        QString macAddress = addrReply.value().toString();
        QString deviceName = getDeviceName(path);

        if (connected)
        {
            emit deviceConnected(macAddress, deviceName);
            LOG_DEBUG("AirPods device connected:" << macAddress << " Name:" << deviceName);
        }
        else
        {
            emit deviceDisconnected(macAddress, deviceName);
            LOG_DEBUG("AirPods device disconnected:" << macAddress << " Name:" << deviceName);
        }
    }
}