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

## Third-party assets

| Asset | Path | License |
|---|---|---|
| Departure Mono 1.500, © Helena Zhang | `linux/assets/fonts/` | SIL Open Font License 1.1 (`DepartureMono-OFL.txt`) |
| Lucide icons 1.48.0, © Lucide Icons and Contributors | `linux/assets/icons/` | ISC (`LICENSE`) |
