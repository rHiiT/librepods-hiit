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

void TrayIconManager::TrayIconManager::updateBatteryStatus(const QString &status)
{
    trayIcon->setToolTip(tr("Battery Status: ") + status);
    updateIconFromBattery(status);
}

void TrayIconManager::updateNoiseControlState(NoiseControlMode mode)
{
    QList<QAction *> actions = noiseControlGroup->actions();
    for (QAction *action : actions)
    {
        action->setChecked(action->data().toInt() == (int)mode);
    }
}

void TrayIconManager::updateConversationalAwareness(bool enabled)
{
    caToggleAction->setChecked(enabled);
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
            { emit conversationalAwarenessToggled(checked); });

    trayMenu->addSeparator();

    // Noise Control Options
    noiseControlGroup = new QActionGroup(trayMenu);
    const NoiseControlMode noiseOptions[] = {
        NoiseControlMode::Adaptive,
        NoiseControlMode::Transparency,
        NoiseControlMode::NoiseCancellation,
        NoiseControlMode::Off};

    for (auto mode : noiseOptions)
    {
        QAction *action = new QAction(trayMenu);
        action->setCheckable(true);
        action->setData((int)mode);
        noiseControlGroup->addAction(action);
        trayMenu->addAction(action);
        connect(action, &QAction::triggered, this, [this, mode]()
                { emit noiseControlChanged(mode); });
    }

    trayMenu->addSeparator();

    // Quit action
    quitAction = new QAction(trayMenu);
    trayMenu->addAction(quitAction);
    connect(quitAction, &QAction::triggered, qApp, &QApplication::quit);

    retranslateMenu();
}

// LibrePods HiiT: texts are set here so a language change can refresh them
void TrayIconManager::retranslateMenu()
{
    openAction->setText(tr("Open"));
    settingsAction->setText(tr("Settings"));
    caToggleAction->setText(tr("Toggle Conversational Awareness"));
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
}

void TrayIconManager::updateIconFromBattery(const QString &status)
{
    // LibrePods HiiT: the icon shows the connection, not the battery (that stays in the
    // tooltip): the case while waiting, the earbuds (or headphones) once connected
    if (status.isEmpty())
    {
        showIllustration("case");
        return;
    }

    const bool headset = status.startsWith("Headset");
    showIllustration(headset ? "headphones" : "buds");
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
