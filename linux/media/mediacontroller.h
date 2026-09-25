#ifndef MEDIACONTROLLER_H
#define MEDIACONTROLLER_H

#include <QObject>
#include "pulseaudiocontroller.h"

class QProcess;
class QTimer;
class EarDetection;
class PlayerStatusWatcher;
class QDBusInterface;

class MediaController : public QObject
{
  Q_OBJECT
public:
  enum MediaState
  {
    Playing,
    Paused,
    Stopped
  };
  Q_ENUM(MediaState)
  enum EarDetectionBehavior
  {
    PauseWhenOneRemoved,
    PauseWhenBothRemoved,
    Disabled
  };
  Q_ENUM(EarDetectionBehavior)

  explicit MediaController(QObject *parent = nullptr);
  ~MediaController();

  void handleEarDetection(EarDetection*);
  bool isActiveOutputDeviceAirPods();
  void handleConversationalAwareness(const QByteArray &data);
  void activateA2dpProfile();
  void removeAudioOutputDevice();
  void setConnectedDeviceMacAddress(const QString &macAddress);
  bool isA2dpProfileAvailable();
  QString getPreferredA2dpProfile();
  bool restartWirePlumber();

  void setEarDetectionBehavior(EarDetectionBehavior behavior);
  inline EarDetectionBehavior getEarDetectionBehavior() const { return earDetectionBehavior; }

  void play();
  void pause();
  MediaState getCurrentMediaState() const;

private:
  MediaState mediaStateFromPlayerctlOutput(const QString &output) const;
  QString getAudioDeviceName();
  bool resolveDeviceOutputName();
  QStringList getPlayingMediaPlayers();

  QStringList pausedByAppServices;
  int initialVolume = -1;
  QString connectedDeviceMacAddress;
  EarDetectionBehavior earDetectionBehavior = PauseWhenOneRemoved;
  QString m_deviceOutputName;
  PulseAudioController *m_pulseAudio = nullptr;
  QString m_cachedA2dpProfile;
  // LibrePods HiiT: the Bluetooth card can appear in PipeWire a few seconds after
  // the device connects, so a pending A2DP activation is retried until it shows up.
  QTimer *m_a2dpRetryTimer = nullptr;
  int m_a2dpRetriesLeft = 0;
};

#endif // MEDIACONTROLLER_H