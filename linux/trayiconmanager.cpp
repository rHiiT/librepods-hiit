#include "trayiconmanager.h"

#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QApplication>
#include <QPainter>
#include <QFont>
#include <QColor>
#include <QActionGroup>
#include <QPalette>

#include "IconImageProvider.hpp"

using namespace AirpodsTrayApp::Enums;

TrayIconManager::TrayIconManager(QObject *parent) : QObject(parent)
{
    // Initialize tray icon
    trayIcon = new QSystemTrayIcon(defaultIcon(), this);
    trayMenu = new QMenu();

    // Setup basic menu actions
    setupMenuActions();

    // Connect signals
    trayIcon->setContextMenu(trayMenu);
    connect(trayIcon, &QSystemTrayIcon::activated, this, &TrayIconManager::onTrayIconActivated);

    trayIcon->show();
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
    // LibrePods HiiT: no status (e.g. right after a disconnect) shows the device icon, not "0%"
    if (status.isEmpty())
    {
        trayIcon->setIcon(defaultIcon());
        return;
    }

    int leftLevel = 0;
    int rightLevel = 0;
    int minLevel = 0;

    // Parse the battery status string
    QStringList parts = status.split(", ");
    if (parts.size() >= 2) {
        leftLevel = parts[0].split(": ")[1].replace("%", "").toInt();
        rightLevel = parts[1].split(": ")[1].replace("%", "").toInt();
        minLevel = (leftLevel == 0) ? rightLevel : (rightLevel == 0) ? leftLevel
                                                                : qMin(leftLevel, rightLevel);
    } else if (parts.size() == 1) {
        minLevel = parts[0].split(": ")[1].replace("%", "").toInt();
    }

    // LibrePods HiiT: the number alone in Departure Mono (crisp at multiples of 11px), in the
    // system text color so it stays visible on light panels; red when low. The full status
    // stays in the tooltip.
    const QColor textColor = minLevel <= 20 ? QColor("#ef4444")
                                            : QApplication::palette().color(QPalette::WindowText);
    QFont font("Departure Mono");
    font.setPixelSize(minLevel >= 100 ? 33 : 44);

    QPixmap pixmap(64, 64);
    pixmap.fill(Qt::transparent);
    QPainter painter(&pixmap);
    painter.setPen(textColor);
    painter.setFont(font);
    painter.drawText(pixmap.rect(), Qt::AlignCenter, QString::number(minLevel));
    painter.end();

    trayIcon->setIcon(QIcon(pixmap));
}

void TrayIconManager::onTrayIconActivated(QSystemTrayIcon::ActivationReason reason)
{
    if (reason == QSystemTrayIcon::Trigger)
    {
        emit trayClicked();
    }
}


// LibrePods HiiT: generic headphones illustration instead of a product photo
QIcon TrayIconManager::defaultIcon()
{
    const QColor color = QApplication::palette().color(QPalette::WindowText);
    return QIcon(QPixmap::fromImage(IconImageProvider::render("headphones", color, QSize(64, 64))));
}
