#include "trayiconmanager.h"

#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QApplication>
#include <QColor>
#include <QActionGroup>
#include <QPalette>
#include <QEvent>
#include <QPainter>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QGuiApplication>

#include "IconImageProvider.hpp"
#include "deviceinfo.hpp"

using namespace AirpodsTrayApp::Enums;

TrayIconManager::TrayIconManager(QObject *parent) : QObject(parent)
{
    // Initialize tray icon
    trayIcon = new QSystemTrayIcon(this);
    showIllustration("case");
    trayMenu = new QMenu();

    // Setup basic menu actions
    setupMenuActions();

    // Connect signals
    trayIcon->setContextMenu(trayMenu);
    connect(trayIcon, &QSystemTrayIcon::activated, this, &TrayIconManager::onTrayIconActivated);

    trayIcon->show();

    // LibrePods HiiT: redraw the icon when the system color scheme changes
    qApp->installEventFilter(this);
}

bool TrayIconManager::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == qApp && event->type() == QEvent::ApplicationPaletteChange)
        showIllustration(m_illustration);
    return QObject::eventFilter(watched, event);
}

// LibrePods HiiT: notifications go straight to the desktop's notification service
// (org.freedesktop.Notifications), so they also show where there is no tray; the tray
// balloon is only the fallback when no service answers
void TrayIconManager::showNotification(const QString &title, const QString &message)
{
    if (!m_notificationsEnabled)
        return;

    QDBusMessage notify = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
        QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("Notify"));
    const QString appId = QGuiApplication::desktopFileName();
    QVariantMap hints;
    hints.insert(QStringLiteral("desktop-entry"), appId);
    notify << QStringLiteral("LibrePods") << m_notificationId << appId << title << message
           << QStringList() << hints << 5000;

    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(notify), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, title, message](QDBusPendingCallWatcher *call) {
        QDBusPendingReply<uint> reply = *call;
        if (reply.isError())
            trayIcon->showMessage(title, message, QSystemTrayIcon::Information, 5000);
        else
            m_notificationId = reply.value(); // the next one replaces it instead of piling up
        call->deleteLater();
    });
}

// LibrePods HiiT: the menu and tooltip are built from the DeviceInfo state instead of the
// "Left: 90%, Right: 94%, Case: 0%" status string, which was English-only and showed a case
// out of reach as 0% or as a live reading
void TrayIconManager::setDeviceInfo(DeviceInfo *deviceInfo)
{
    m_deviceInfo = deviceInfo;
    connect(deviceInfo->getBattery(), &Battery::batteryStatusChanged, this, &TrayIconManager::refresh);
    connect(deviceInfo, &DeviceInfo::deviceNameChanged, this, &TrayIconManager::refresh);
    refresh();
}

void TrayIconManager::updateConnectionState(const QString &state, const QString &pairedName)
{
    m_connectionState = state;
    m_pairedName = pairedName;
    syncControls();
    refresh();
}

void TrayIconManager::updateNoiseControlState(NoiseControlMode mode)
{
    m_noiseControlMode = mode;
    syncControls();
}

void TrayIconManager::updateConversationalAwareness(bool enabled)
{
    m_conversationalAwareness = enabled;
    syncControls();
}

// LibrePods HiiT: Qt checks a menu item as soon as it is clicked, even when nothing reached the
// AirPods. The menu shows only what the AirPods confirmed, and nothing while they are away.
void TrayIconManager::syncControls()
{
    const bool connected = isConnected();
    for (QAction *action : noiseControlGroup->actions())
    {
        action->setEnabled(connected);
        action->setChecked(connected && action->data().toInt() == (int)m_noiseControlMode);
    }
    caToggleAction->setEnabled(connected);
    caToggleAction->setChecked(connected && m_conversationalAwareness);
}

void TrayIconManager::refresh()
{
    checkLowBattery();
    const bool headset = m_deviceInfo
                         && m_deviceInfo->getBattery()->getPrimaryPod() == Battery::Component::Headset;
    showIllustration(!isConnected() ? "case" : headset ? "headphones" : "buds");
    trayIcon->setToolTip(tooltipText());
    updateHeader();
}

QString TrayIconManager::displayName() const
{
    QString name = m_deviceInfo ? m_deviceInfo->deviceName() : QString();
    if (name.isEmpty())
        name = m_pairedName;
    if (name.isEmpty())
        name = QStringLiteral("LibrePods");
    return name;
}

QString TrayIconManager::tooltipText() const
{
    const QString details = isConnected() ? batteryLines() : stateText();
    return details.isEmpty() ? displayName() : displayName() + '\n' + details;
}

// LibrePods HiiT: the top of the menu repeats the tooltip, since the icon no longer shows the
// battery and a tooltip needs hovering
void TrayIconManager::updateHeader()
{
    if (!nameAction)
        return;
    nameAction->setText(displayName());

    const QStringList lines = (isConnected() ? batteryLines() : stateText()).split('\n', Qt::SkipEmptyParts);
    for (int i = 0; i < 2; ++i)
    {
        detailActions[i]->setVisible(i < lines.size());
        detailActions[i]->setText(i < lines.size() ? lines.at(i) : QString());
    }
    connectAction->setVisible(canConnect());
}

// Same states that offer Connect in the main window, plus a failed attempt
bool TrayIconManager::canConnect() const
{
    return m_connectionState == QLatin1String("paired") || m_connectionState == QLatin1String("nearby")
           || m_connectionState == QLatin1String("failed");
}

void TrayIconManager::checkLowBattery()
{
    int lowest = -1;
    bool charging = false;
    if (m_deviceInfo && isConnected())
    {
        const Battery *battery = m_deviceInfo->getBattery();
        auto consider = [&](bool available, int level, bool isCharging) {
            if (!available || level <= 0)
                return;
            if (lowest < 0 || level < lowest)
                lowest = level;
            charging = charging || isCharging;
        };
        if (battery->getPrimaryPod() == Battery::Component::Headset)
            consider(battery->isHeadsetAvailable(), battery->getHeadsetLevel(), battery->isHeadsetCharging());
        else
        {
            consider(battery->isLeftPodAvailable(), battery->getLeftPodLevel(), battery->isLeftPodCharging());
            consider(battery->isRightPodAvailable(), battery->getRightPodLevel(), battery->isRightPodCharging());
        }
    }

    m_lowBattery = lowest >= 0 && lowest <= 20 && !charging;
    if (lowest > 20 || charging)
        m_lowBatteryNotified = false; // charged again: warn again next time
    if (m_lowBattery && !m_lowBatteryNotified)
    {
        m_lowBatteryNotified = true;
        showNotification(tr("Low battery"), tr("%1: %2% left").arg(displayName()).arg(lowest));
    }
}

QString TrayIconManager::batteryLines() const
{
    if (!m_deviceInfo)
        return {};
    const Battery *battery = m_deviceInfo->getBattery();

    auto level = [](const QString &label, int level, bool charging) {
        const QString text = label.arg(level);
        return charging ? tr("%1, charging").arg(text) : text;
    };

    if (battery->getPrimaryPod() == Battery::Component::Headset)
        return battery->isHeadsetAvailable()
                   ? level(tr("Battery %1%"), battery->getHeadsetLevel(), battery->isHeadsetCharging())
                   : QString();

    QStringList pods;
    if (battery->isLeftPodAvailable())
        pods << level(tr("Left %1%"), battery->getLeftPodLevel(), battery->isLeftPodCharging());
    if (battery->isRightPodAvailable())
        pods << level(tr("Right %1%"), battery->getRightPodLevel(), battery->isRightPodCharging());

    QStringList lines;
    if (!pods.isEmpty())
        lines << pods.join(QStringLiteral(" · "));
    if (battery->isCaseAvailable())
    {
        const QString caseText = level(tr("Case %1%"), battery->getCaseLevel(), battery->isCaseCharging());
        lines << (battery->isCaseLastKnown() ? tr("%1, last reading").arg(caseText) : caseText);
    }
    return lines.join('\n');
}

QString TrayIconManager::stateText() const
{
    const QString &state = m_connectionState;
    if (state == QLatin1String("off"))
        return tr("Bluetooth is off");
    if (state == QLatin1String("connecting"))
        return tr("Connecting…");
    if (state == QLatin1String("failed"))
        return tr("Couldn't connect");
    if (state == QLatin1String("paired"))
        return tr("Not connected");
    if (state == QLatin1String("nearby"))
        return tr("Nearby");
    if (state == QLatin1String("unpaired"))
        return tr("No AirPods paired");
    return tr("Looking for your AirPods…");
}

void TrayIconManager::setupMenuActions()
{
    // LibrePods HiiT: status header, then the controls, then the app actions. DBusMenu has no
    // plain text rows, so the header lines are disabled actions.
    nameAction = new QAction(trayMenu);
    nameAction->setEnabled(false);
    trayMenu->addAction(nameAction);
    for (QAction *&action : detailActions)
    {
        action = new QAction(trayMenu);
        action->setEnabled(false);
        trayMenu->addAction(action);
    }

    connectAction = new QAction(trayMenu);
    trayMenu->addAction(connectAction);
    connect(connectAction, &QAction::triggered, this, [this]() { emit connectRequested(); });

    trayMenu->addSeparator();

    // Noise Control Options
    // LibrePods HiiT: same order as the selector in the main window; none is checked while
    // the AirPods are not connected
    noiseControlGroup = new QActionGroup(trayMenu);
    noiseControlGroup->setExclusionPolicy(QActionGroup::ExclusionPolicy::ExclusiveOptional);
    const NoiseControlMode noiseOptions[] = {
        NoiseControlMode::Off,
        NoiseControlMode::NoiseCancellation,
        NoiseControlMode::Transparency,
        NoiseControlMode::Adaptive};

    for (auto mode : noiseOptions)
    {
        QAction *action = new QAction(trayMenu);
        action->setCheckable(true);
        action->setData((int)mode);
        noiseControlGroup->addAction(action);
        trayMenu->addAction(action);
        connect(action, &QAction::triggered, this, [this, mode]()
                {
                    emit noiseControlChanged(mode);
                    syncControls(); // checked again when the AirPods confirm the new mode
                });
    }

    // Conversational Awareness Toggle
    caToggleAction = new QAction(trayMenu);
    caToggleAction->setCheckable(true);
    trayMenu->addAction(caToggleAction);
    connect(caToggleAction, &QAction::triggered, this, [this](bool checked)
            {
                emit conversationalAwarenessToggled(checked);
                syncControls();
            });

    trayMenu->addSeparator();

    // Open action
    openAction = new QAction(trayMenu);
    trayMenu->addAction(openAction);
    connect(openAction, &QAction::triggered, qApp, [this](){emit openApp();});

    // Settings Menu
    settingsAction = new QAction(trayMenu);
    trayMenu->addAction(settingsAction);
    connect(settingsAction, &QAction::triggered, qApp, [this](){emit openSettings();});

    trayMenu->addSeparator();

    // Quit action
    quitAction = new QAction(trayMenu);
    trayMenu->addAction(quitAction);
    connect(quitAction, &QAction::triggered, qApp, &QApplication::quit);

    syncControls();
    retranslateMenu();
    updateHeader();
}

// LibrePods HiiT: texts are set here so a language change can refresh them
void TrayIconManager::retranslateMenu()
{
    openAction->setText(tr("Open"));
    settingsAction->setText(tr("Settings"));
    caToggleAction->setText(tr("Conversational Awareness"));
    quitAction->setText(tr("Quit"));
    connectAction->setText(tr("Connect"));

    for (QAction *action : noiseControlGroup->actions())
    {
        switch (static_cast<NoiseControlMode>(action->data().toInt()))
        {
        case NoiseControlMode::Adaptive: action->setText(tr("Adaptive")); break;
        case NoiseControlMode::Transparency: action->setText(tr("Transparency")); break;
        case NoiseControlMode::NoiseCancellation: action->setText(tr("Noise Cancellation")); break;
        default: action->setText(tr("Off")); break;
        }
    }
    trayIcon->setToolTip(tooltipText());
    updateHeader();
}

void TrayIconManager::onTrayIconActivated(QSystemTrayIcon::ActivationReason reason)
{
    if (reason == QSystemTrayIcon::Trigger)
    {
        emit trayClicked();
    }
}


// LibrePods HiiT: drawn illustrations instead of product photos, in the system text color
// so they stay visible on light and dark panels
void TrayIconManager::showIllustration(const QString &name)
{
    m_illustration = name;
    const QColor color = QApplication::palette().color(QPalette::WindowText);
    QImage image = IconImageProvider::render(name, color, QSize(64, 64));

    // LibrePods HiiT: low battery is a red dot on the earbuds, the level stays in the menu
    if (m_lowBattery && name != QLatin1String("case"))
    {
        QPainter painter(&image);
        painter.setRenderHint(QPainter::Antialiasing);
        painter.setPen(Qt::NoPen);
        painter.setBrush(QColor("#ef4444"));
        painter.drawEllipse(QRectF(40, 2, 22, 22));
    }
    trayIcon->setIcon(QIcon(QPixmap::fromImage(image)));
}
