# LibrePods HiiT — modifications

LibrePods HiiT is a fork of [LibrePods](https://github.com/kavishdevar/librepods)
(Copyright (C) 2025 LibrePods contributors), distributed under the same
GNU General Public License v3.0 (see `LICENSE`). This file lists the changes
made in the fork, as required by section 5(a) of the GPL.

Changed code is also marked with a `LibrePods HiiT` comment: at the top of
rewritten or new files, and next to the change in the C++ sources.

## 2026-09-24 — Linux app: design system

- New component kit in the shadcn/ui style (`linux/Ui*.qml`), with design
  tokens in `linux/Theme.qml` that follow the system light/dark preference.
- UI font changed to Departure Mono; SF Pro and SF Symbols removed.
- Icons changed to Lucide, rendered in any color by `linux/IconImageProvider.hpp`.
- AirPods product images replaced by original line-art illustrations
  (`linux/assets/illustrations/`), also used for the tray icon.
- `Main.qml`, `SegmentedControl.qml`, `BatteryIndicator.qml`, `PodColumn.qml` and
  `KeysQRDialog.qml` rebuilt on the kit. Behavior changes:
  - the noise control selector keeps following the device after the first click;
  - switches only send commands on user action (`toggled`), not on backend updates;
  - connection status and battery level no longer rely on color alone;
  - the settings page gains a header with a back button (also `Esc`).

## 2026-09-24 — Linux app: connection states and feedback

- The backend exposes `connectionState` (`off`, `searching`, `connecting`,
  `connected`, `failed`) and the `retryConnection()` and `powerOnBluetooth()` actions.
- The main window shows a status panel for each non-connected state, with a hint
  and, when possible, an action ("Turn on Bluetooth", "Try again"). Battery and
  controls are hidden until the AirPods are connected.
- `renameAirPods()` and `setPhoneMac()` return an error message; the settings page
  shows it under the field, or a confirmation toast on success.
- The name field starts with the current name; the phone address field only
  accepts hex digits and separators and explains where to find the address.
- The connection retry counter was a `static` shared by every connection and
  never reset on success; it is now a member reset on connect and on retry.

## 2026-09-24 — Linux app: settings in sections

- Settings moved from `Main.qml` to `linux/SettingsPage.qml` and grouped in cards:
  AirPods, Controls, App, Android and Advanced (collapsed by default).
- The AirPods card explains that the AirPods must be connected instead of hiding
  its options; the phone address only shows when Cross-Device Connectivity is on.
- Short descriptions added to Cross-Device Connectivity, retry attempts and the
  Magic Cloud Keys QR code.
- `UiCard` can collapse; new `UiLabel` for themed text.

## 2026-09-24 — Linux app: tray battery number

- The tray icon draws the lowest battery level in Departure Mono and the system
  text color (it was white Arial, invisible on light panels), in red at 20% or less.
- With no battery status (e.g. right after a disconnect) the tray shows the device
  icon instead of "0%".

## 2026-09-24 — Linux app: Brazilian Portuguese and translation build

- New Brazilian Portuguese translation (`linux/translations/librepods_pt_BR.ts`), complete.
- Italian and Traditional Chinese were never built (only Turkish was listed in
  `TS_FILES`); all four languages are now compiled.
- Translation files regenerated with `lupdate`; strings that moved from `Main.qml`
  to `SettingsPage.qml` keep their existing Italian, Turkish and Chinese translations.
  New strings stay untranslated (shown in English) in those three languages.
- `.qm` files are written to `<build dir>/translations`, where the app looks for them.

## 2026-09-24 — Linux app: frameless window and HiiT Edition branding

- The main window is frameless (`Qt.FramelessWindowHint`) with its own title bar
  (`linux/TitleBar.qml`): "LibrePods" logo with "HiiT Edition" below, settings,
  minimize and close-to-tray buttons. Dragging the bar moves the window and the
  edges resize it (`linux/WindowResizeHandles.qml`), both through the window manager.
- The AirPods name moved from the page heading to the connection badge
  ("Connected · <name>"), which elides long names.
- The settings page heading is smaller so it does not compete with the logo.

## 2026-09-24 — Linux app: language selector

- Settings > App has a Language option (system default, English, Português
  (Brasil), Italiano, Türkçe, 繁體中文). The choice is saved and applied at once,
  to the window and the tray menu, without restarting.
- Translation loading moved from `main()` to `AirPodsTrayApp`
  (`loadAppTranslation`), which also handles region fallback (e.g. `tr_TR` → `tr`).
- The Magic Cloud Keys QR dialog texts are translatable.

## 2026-09-24 — Linux app: connect AirPods detected nearby

- New `nearby` connection state: when the BLE scan recognizes the known AirPods
  (by their IRK) and they are not connected here, the window shows
  "<name> is nearby" with a Connect button. The state expires after 15 s
  without new advertisements.
- Connect runs `bluetoothctl connect` on the last known address, saved when
  the AirPods connect (`DeviceInfo/lastAddress`); the usual BlueZ flow then
  opens the control channel.
- The "searching" hint no longer says opening the case is enough to connect.
- The feature is experimental and off by default: Settings > Experimental
  (collapsed, with a warning) turns it on. When off, the "searching" hint tells
  the user to connect the AirPods in the system's Bluetooth settings.

## 2026-09-24 — Linux app: case battery state

- When both buds are out of the case the AirPods report the case as disconnected;
  the level kept from before is now shown dimmed as "Last reading" instead of
  as a live value (`Battery::caseLastKnown`).
- Charging components show a "Charging" label, not only the charging icon.

## 2026-09-24 — Linux app: Italian and Turkish completed, Traditional Chinese removed

- Italian and Turkish translate all 90 strings (57 new ones each), keeping the
  terms already chosen by their previous translators. They were written by an
  AI assistant and would benefit from a review by native speakers.
- Traditional Chinese (`librepods_zh_TW.ts`, contributed upstream) is removed from
  the fork: Departure Mono has no CJK glyphs (194 of the characters it needs are
  missing), so the text fell back to another font. Users with a Chinese system
  language now see English.
- The language selector only offers languages the font can draw.

## 2026-09-24 — Linux app: paired AirPods offered with a Connect button

- New `paired` connection state: when the AirPods are paired with this computer
  (BlueZ `Paired`) but not connected, the window shows their name and a Connect
  button, with one line of help: if they do not connect when taken out of the case,
  click Connect.
- The former "searching" state becomes `unpaired`: "No AirPods paired", three short
  pairing steps and an "Open Bluetooth settings" button (KDE, GNOME or Blueman).
- The case illustration is the main symbol of these states, since pairing and
  reconnecting start from the case.
- Connect (`connectKnownDevice`) uses the paired address, or the last used one.
## 2026-09-24 — Linux app: Hearing Aid shown as status, not as a switch

- The Hearing Aid switch leaves the main window. Hearing Aid is set up once from an
  iPhone or iPad after a hearing test, so an everyday toggle could only switch an
  accessibility feature off by mistake.
- Settings > AirPods shows "Hearing Aid — On. Set up from an iPhone or iPad." while
  it is enabled.

## 2026-09-24 — Linux app: own app icon

- `linux/assets/librepods.svg` is replaced by the HiiT Edition icon: the case
  illustration on a dark rounded tile, instead of the LibrePods logo.
- The icon is also the window icon, and the desktop entry is named
  "LibrePods HiiT Edition".
## 2026-09-24 — Linux app: theme selector

- Settings > App has a Theme option: System default, Light or Dark. The choice is
  saved (`app/theme`) and applied at once; System default keeps following the
  desktop's light/dark preference.

## 2026-09-25 — Linux app: audio stuck on the "off" profile

- Fixed AirPods staying connected with no sound. Right after connecting, the
  Bluetooth card may not exist in PipeWire yet; A2DP activation failed once and
  was never retried, so the card kept the profile WirePlumber restored (often
  "off", saved when both buds were taken out). `MediaController` now looks the
  card up again and retries the activation for up to 10 seconds.

## 2026-09-25 — Linux app: tray icons and fixed window size

- The tray icon shows the connection instead of the battery number: the charging
  case while not connected, both earbuds (or headphones, for a headset) once
  connected (`linux/assets/illustrations/buds.svg`). The battery stays in the tooltip.
- The tray icon is redrawn when the system palette changes, so it follows a switch
  between light and dark color schemes without restarting the app.
- The main window has a fixed size (451×570); the resize edges
  (`linux/WindowResizeHandles.qml`) were removed.

## 2026-09-25 — Linux app: tray menu shows only confirmed state

- Noise control and Conversational Awareness in the tray menu are disabled while
  the AirPods are not connected, and only show what the AirPods confirmed: Qt used
  to check a clicked item even when nothing was sent.
- Noise control modes follow the order of the main window's selector.
- The tray tooltip is translated and built from `DeviceInfo` and `Battery`: device
  name, then each bud, the case and charging; a case out of reach is shown as the
  last reading, not as 0%. While not connected it shows the connection state.
- The tray icon follows `connectionState` instead of the battery status string.

## 2026-09-25 — Linux app: minimize and close to tray

- The minimize button hides the window in the tray instead of leaving a second
  entry in the taskbar.
- New setting "Close to tray" (Settings > App, on by default): when off, closing
  the window quits the app. Saved as `app/closeToTray`.
- New Lucide icon `panel-bottom-close` (`linux/assets/icons/`).

## 2026-09-25 — Linux app: pause when one bud is removed

- Fixed "Pause when removing AirPods: one removed" never pausing, and the
  Conversational Awareness volume change never applying, on PipeWire.
  `MediaController::isActiveOutputDeviceAirPods()` looked for the address as
  `D0_3E_...` in the default sink name, which PipeWire writes as
  `bluez_output.D0:3E:...`; both forms now match.

## 2026-09-25 — Linux app: window only in the tray

- On KDE Plasma the window no longer gets a taskbar entry: the app is reached
  from the tray icon. Wayland does not let an app skip the taskbar by itself
  (`Qt::Tool` has no effect there), so `linux/kwintaskbarrule.hpp` adds a KWin
  window rule for the app id (`kwinrulesrc`, group `librepods-hiit-skip-taskbar`)
  and removes it when the new "Show in taskbar" setting (Settings > App,
  `app/showInTaskbar`, off by default) is turned on. Other window rules are kept.
- New Lucide icon `app-window` (`linux/assets/icons/`).

## 2026-09-25 — Linux app: status and Connect in the tray menu

- The tray menu opens with the device name and, below it, the battery of each
  bud and the case, or the connection state while not connected (disabled items,
  since DBusMenu has no plain text rows).
- "Connect" appears in the tray menu when the AirPods are paired but not
  connected (also nearby or after a failed attempt), like the main window button.
- Menu order: status, noise control and Conversational Awareness, Open and
  Settings, Quit.
- Low battery (a bud or headset at 20% or less, not charging) shows a red dot on
  the tray icon and one notification, repeated only after it charges again.

## 2026-09-25 — Linux app: desktops without a tray

- The app checks whether the desktop has a system tray (`trayAvailable`, updated
  when `org.kde.StatusNotifierWatcher` appears or goes away). Without one (GNOME
  without the AppIndicator extension, for example) the minimize button minimizes
  as usual, closing quits, the "Close to tray" and "Show in taskbar" settings are
  hidden and the KWin taskbar rule is removed, so the window can always be reached.
- Notifications are sent to `org.freedesktop.Notifications` over D-Bus, so they
  also show without a tray; the tray balloon is only used when that service does
  not answer. A new notification replaces the previous one.

## 2026-09-25 — Linux app: AppImage

- `linux/packaging/build-appimage.sh` builds `LibrePods-HiiT-x86_64.AppImage` with
  linuxdeploy (Qt, QML, Wayland and X11 plugins, OpenSSL, libpulse) and appimagetool,
  whose static runtime does not need libfuse2 on the host.
- `.github/workflows/ci-linux.yml` now builds the AppImage on Ubuntu 22.04 with
  Qt 6.8.3, on pull requests, on `main` and on `v*` tags (published as a release
  asset). The previous workflow was manual only and missed OpenSSL and libpulse.
- Running from an AppImage, the app writes its own app menu entry and icon to
  `~/.local/share` (pointing at the AppImage file, refreshed if it moves), which
  Wayland needs for the window and tray icons. Entries from a regular install are
  left alone. Autostart points at the AppImage file too, and translations are also
  looked up in `<prefix>/share/librepods/translations`.

## 2026-09-25 — README for the fork

- `README.md` rewritten for LibrePods HiiT Edition: unofficial fork notice, AppImage
  download, changes from upstream, desktop support, build steps, license and credits.
  The upstream README remains available in the upstream repository and in git history.
- Screenshots of the Linux app in `imgs/hiit/`.

## 2026-09-25 — Linux app: version

- The fork follows Semantic Versioning, starting at 0.1.0 (`project(... VERSION)` in
  `linux/CMakeLists.txt`); release tags are `v<VERSION>`.
- The app knows its version (`QCoreApplication::applicationVersion`) and shows it at
  the bottom of Settings.
- The Linux workflow refuses a `v*` tag that does not match that version.

## 2026-09-25 — Linux app: Magic Cloud Keys QR code removed

- Settings > Advanced no longer shows the Magic Cloud Keys QR code. It encoded a
  `librepods://add-magic-keys` link that the Android app no longer handles (its
  intent filter is commented out; the app now asks the AirPods for the keys itself),
  so scanning it did nothing while it displayed the keys on screen.
- Removed `KeysQRDialog.qml`, `QRCodeImageProvider.hpp`, the bundled
  QR-Code-generator library (`linux/thirdparty/`) and the `qr-code` icon.
- The app still requests the keys from the AirPods: they identify the AirPods in
  BLE advertisements and decrypt their battery data.

## 2026-09-25 — Linux app: Android cross-device link removed

- Removed "Cross-Device Connectivity with Android": the L2CAP link to the
  LibrePods Android app (packet relay, status and disconnect requests), the phone
  Bluetooth address (`PHONE_MAC_ADDRESS`), the Android card in Settings, the
  `AirPodsPackets::Phone` packets and the `smartphone` icon. Android is not a
  target of this fork. The old `crossdevice/enabled` setting is deleted on start.
- The app no longer asks BlueZ to connect the AirPods when media starts playing.
  With an iPhone the AirPods keep one connection at a time, so this could not take
  them over, and the blocking `bluetoothctl connect` froze the window while the
  AirPods were out of reach.

## 2026-09-25 — Linux app: autostart from the AppImage

- The application name is set to `librepods` instead of taken from the executable.
  Inside the AppImage the binary starts as `AppRun`, so the autostart entry was
  looked up as `AppRun.desktop`: an existing entry was never refreshed to the
  AppImage path, and the setting showed as off.

## 2026-09-25 — Linux app: connected state after a reconnect

- The app marks the AirPods as connected on the first packet received on the
  control channel. It used to wait for the metadata packet (name, model), which the
  AirPods do not always send again after reconnecting, leaving the app searching
  while the AirPods were connected.

## Third-party assets

| Asset | Path | License |
|---|---|---|
| Departure Mono 1.500, © Helena Zhang | `linux/assets/fonts/` | SIL Open Font License 1.1 (`DepartureMono-OFL.txt`) |
| Lucide icons 1.48.0, © Lucide Icons and Contributors | `linux/assets/icons/` | ISC (`LICENSE`) |
