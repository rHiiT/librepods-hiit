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

## Third-party assets

| Asset | Path | License |
|---|---|---|
| Departure Mono 1.500, © Helena Zhang | `linux/assets/fonts/` | SIL Open Font License 1.1 (`DepartureMono-OFL.txt`) |
| Lucide icons 1.48.0, © Lucide Icons and Contributors | `linux/assets/icons/` | ISC (`LICENSE`) |
