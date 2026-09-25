#!/usr/bin/env bash
# LibrePods HiiT: builds LibrePods-HiiT-x86_64.AppImage from the linux/ sources.
#
# Usage: linux/packaging/build-appimage.sh [output dir]
#   QMAKE=/path/to/qmake6  Qt to bundle (default: qmake6 from PATH)
#   TOOLS_DIR=/path        where linuxdeploy and appimagetool are kept (default: build dir)
#
# The AppImage runs on distributions with a glibc at least as new as the build machine's,
# so release builds are made on an old base (see .github/workflows/ci-linux.yml).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$SRC_DIR/build-appimage}"
OUT_DIR="$(realpath -m "${1:-$BUILD_DIR}")"
APPDIR="$BUILD_DIR/AppDir"
TOOLS_DIR="${TOOLS_DIR:-$BUILD_DIR/tools}"
export QMAKE="${QMAKE:-$(command -v qmake6 || command -v qmake)}"

download() {
    local url="$1" file="$TOOLS_DIR/$(basename "$1")"
    [ -x "$file" ] || { curl -fsSL -o "$file" "$url" && chmod +x "$file"; }
}

mkdir -p "$TOOLS_DIR" "$OUT_DIR"
download https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
download https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
# appimagetool embeds the static runtime: the AppImage does not need libfuse2 on the host
download https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage

# Build and install into the AppDir under /usr
QT_PREFIX="$("$QMAKE" -query QT_INSTALL_PREFIX)"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_PREFIX_PATH="$QT_PREFIX"
cmake --build "$BUILD_DIR"
rm -rf "$APPDIR"
DESTDIR="$APPDIR" cmake --install "$BUILD_DIR"

# Qt libraries, QML modules and plugins. Wayland and X11 are both bundled; the platform
# plugin is libqwayland-generic.so up to Qt 6.8 and libqwayland.so later.
PLUGINS_DIR="$("$QMAKE" -query QT_INSTALL_PLUGINS)"
wayland_plugin="$(basename "$(ls "$PLUGINS_DIR"/platforms/libqwayland-generic.so "$PLUGINS_DIR"/platforms/libqwayland.so 2>/dev/null | head -n1)")"
export EXTRA_PLATFORM_PLUGINS="$wayland_plugin"
export EXTRA_QT_MODULES="waylandcompositor"
export EXTRA_QT_PLUGINS="wayland-shell-integration;wayland-decoration-client;wayland-graphics-integration-client;iconengines;imageformats"
export QML_SOURCES_PATHS="$SRC_DIR"
# The xdg-desktop-portal theme lets the bundled Qt follow the desktop's light/dark setting
if [ -e "$PLUGINS_DIR/platformthemes/libqxdgdesktopportal.so" ]; then
    export EXTRA_QT_PLUGINS="$EXTRA_QT_PLUGINS;platformthemes/libqxdgdesktopportal.so"
fi

# linuxdeploy resolves libraries like the dynamic loader does: point it at the chosen Qt,
# or it may bundle another Qt found on the system next to this Qt's plugins
export LD_LIBRARY_PATH="$("$QMAKE" -query QT_INSTALL_LIBS)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$TOOLS_DIR"
APPIMAGE_EXTRACT_AND_RUN=1 ./linuxdeploy-x86_64.AppImage --appdir "$APPDIR" --plugin qt \
    --desktop-file "$APPDIR/usr/share/applications/me.kavishdevar.librepods.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/librepods.svg"

APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 ./appimagetool-x86_64.AppImage --no-appstream \
    "$APPDIR" "$OUT_DIR/LibrePods-HiiT-x86_64.AppImage"
echo "Built $OUT_DIR/LibrePods-HiiT-x86_64.AppImage"
