#include <QObject>
#include <QSystemTrayIcon>

#include "enums.h"

class QMenu;
class QAction;
class QActionGroup;
class DeviceInfo;

class TrayIconManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled NOTIFY notificationsEnabledChanged)

public:
    explicit TrayIconManager(QObject *parent = nullptr);

    // LibrePods HiiT: the tooltip reads names and levels from here, not from a status string
    void setDeviceInfo(DeviceInfo *deviceInfo);

    // LibrePods HiiT: icon, tooltip and menu follow AirPodsTrayApp::connectionState
    void updateConnectionState(const QString &state, const QString &pairedName);

    void updateNoiseControlState(AirpodsTrayApp::Enums::NoiseControlMode);

    void updateConversationalAwareness(bool enabled);

    void showNotification(const QString &title, const QString &message);

    void retranslateMenu();

    bool notificationsEnabled() const { return m_notificationsEnabled; }
    void setNotificationsEnabled(bool enabled)
    {
        if (m_notificationsEnabled != enabled)
        {
            m_notificationsEnabled = enabled;
            emit notificationsEnabledChanged(enabled);
        }
    }

signals:
    void notificationsEnabledChanged(bool enabled);

private:
    // LibrePods HiiT: "case" (not connected), "buds" or "headphones" (connected)
    void showIllustration(const QString &name);
    QString m_illustration;

    void refresh();
    QString displayName() const;
    QString tooltipText() const;
    void updateHeader();
    void checkLowBattery();
    bool canConnect() const;
    QString batteryLines() const;
    QString stateText() const;
    void syncControls();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private slots:
    void onTrayIconActivated(QSystemTrayIcon::ActivationReason reason);

private:
    QSystemTrayIcon *trayIcon;
    QMenu *trayMenu;
    QAction *openAction = nullptr;
    QAction *settingsAction = nullptr;
    QAction *caToggleAction;
    QAction *quitAction = nullptr;
    // LibrePods HiiT: read-only header (name, battery or state) and Connect while not connected
    QAction *nameAction = nullptr;
    QAction *detailActions[2] = {nullptr, nullptr};
    QAction *connectAction = nullptr;
    QActionGroup *noiseControlGroup;
    bool m_notificationsEnabled = true;

    // LibrePods HiiT: last values confirmed by the AirPods; the menu only shows these
    DeviceInfo *m_deviceInfo = nullptr;
    QString m_connectionState;
    QString m_pairedName;
    AirpodsTrayApp::Enums::NoiseControlMode m_noiseControlMode = AirpodsTrayApp::Enums::NoiseControlMode::Off;
    bool m_conversationalAwareness = false;
    // LibrePods HiiT: a bud (or headset) at 20% or less and not charging; notified once until
    // it charges again
    uint m_notificationId = 0;
    bool m_lowBattery = false;
    bool m_lowBatteryNotified = false;

    bool isConnected() const { return m_connectionState == QLatin1String("connected"); }

    void setupMenuActions();

signals:
    void trayClicked();
    void noiseControlChanged(AirpodsTrayApp::Enums::NoiseControlMode);
    void conversationalAwarenessToggled(bool enabled);
    void openApp();
    void openSettings();
    void connectRequested();
};
