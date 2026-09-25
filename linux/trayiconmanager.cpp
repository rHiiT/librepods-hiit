#include "trayiconmanager.h"

#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QApplication>
#include <QColor>
#include <QActionGroup>
#include <QPalette>
#include <QEvent>

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

void TrayIconManager::showNotification(const QString &title, const QString &message)
{
    if (!m_notificationsEnabled)
        return;
    trayIcon->showMessage(title, message, QSystemTrayIcon::Information, 3000);
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
    const bool headset = m_deviceInfo
                         && m_deviceInfo->getBattery()->getPrimaryPod() == Battery::Component::Headset;
    showIllustration(!isConnected() ? "case" : headset ? "headphones" : "buds");
    trayIcon->setToolTip(tooltipText());
}

QString TrayIconManager::tooltipText() const
{
    QString name = m_deviceInfo ? m_deviceInfo->deviceName() : QString();
    if (name.isEmpty())
        name = m_pairedName;
    if (name.isEmpty())
        name = QStringLiteral("LibrePods");

    const QString details = isConnected() ? batteryLines() : stateText();
    return details.isEmpty() ? name : name + '\n' + details;
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
    // Open action
    openAction = new QAction(trayMenu);
    trayMenu->addAction(openAction);
    connect(openAction, &QAction::triggered, qApp, [this](){emit openApp();});

    // Settings Menu

    settingsAction = new QAction(trayMenu);
    trayMenu->addAction(settingsAction);
    connect(settingsAction, &QAction::triggered, qApp, [this](){emit openSettings();});

    trayMenu->addSeparator();

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

    trayMenu->addSeparator();

    // Quit action
    quitAction = new QAction(trayMenu);
    trayMenu->addAction(quitAction);
    connect(quitAction, &QAction::triggered, qApp, &QApplication::quit);

    syncControls();
    retranslateMenu();
}

// LibrePods HiiT: texts are set here so a language change can refresh them
void TrayIconManager::retranslateMenu()
{
    openAction->setText(tr("Open"));
    settingsAction->setText(tr("Settings"));
    caToggleAction->setText(tr("Conversational Awareness"));
    quitAction->setText(tr("Quit"));

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
    trayIcon->setIcon(QIcon(QPixmap::fromImage(IconImageProvider::render(name, color, QSize(64, 64)))));
}
