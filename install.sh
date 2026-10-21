#!/bin/sh
# Installs Backdrop for the current user: the app goes to ~/.local/share/goldengate-backdrop/app,
# a `goldengate-wallpaper` command to ~/.local/bin, plus the app menu entry and icon. The clone
# isn't needed afterwards; run this again from a newer clone to update.
#   ./install.sh               install or update
#   ./install.sh --uninstall   remove it again (keeps your crash list and option overlays)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
APP="$DATA/goldengate-backdrop/app"
BIN="$HOME/.local/bin/goldengate-wallpaper"
DESKTOP="$DATA/applications/goldengate-wallpaper.desktop"
ICON="$DATA/icons/hicolor/scalable/apps/goldengate-backdrop.svg"

# refresh the icon and app menu caches when the tools are there
refresh_caches() {
    command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "$DATA/icons/hicolor" >/dev/null 2>&1 || true
    command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
}

if [ "$1" = "--uninstall" ]; then
    rm -rf "$APP"
    rm -f "$BIN" "$DESKTOP" "$ICON"
    refresh_caches
    echo "Backdrop is uninstalled."
    exit 0
elif [ -n "$1" ]; then
    echo "usage: $0 [--uninstall]" >&2
    exit 2
fi

# what Backdrop needs to run: warn, but install anyway
if ! python3 -I -c "import PySide6.QtQml, PySide6.QtDBus" >/dev/null 2>&1; then
    echo "warning: PySide6 isn't installed for python3. Install your distribution's package" >&2
    echo "         (Fedora: sudo dnf install python3-pyside6), not the one from pip." >&2
fi
plugin=""
for d in "$DATA" $(echo "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr ':' ' '); do
    [ -f "$d/plasma/wallpapers/com.github.catsout.wallpaperEngineKde/metadata.json" ] && plugin=1
done
if [ -z "$plugin" ]; then
    echo "warning: the Wallpaper Engine KDE plugin isn't installed, so Backdrop can't apply" >&2
    echo "         wallpapers yet. See \"Installing the plugin\" in README.md." >&2
fi

# the app itself: a fresh copy, so files removed upstream don't linger
rm -rf "$APP"
mkdir -p "$APP"
cp -R "$HERE/backdrop" "$HERE"/*.py "$HERE"/*.qml "$HERE/fallback" "$HERE/data" "$APP/"
chmod +x "$APP/backdrop"

# the command, the menu entry and the icon
mkdir -p "$(dirname "$BIN")" "$(dirname "$DESKTOP")"
printf '#!/bin/sh\nexec "%s/backdrop" "$@"\n' "$APP" > "$BIN"
chmod +x "$BIN"
install -Dm644 "$HERE/data/goldengate-backdrop.svg" "$ICON"
# Exec gets the absolute path, quoted (and escaped as the desktop entry spec asks), since
# ~/.local/bin isn't always on the session's PATH
EXEC="$BIN" awk '/^Exec=/ { e = ENVIRON["EXEC"]; gsub(/[\\"`$]/, "\\\\&", e); print "Exec=\"" e "\""; next } { print }' \
    "$HERE/data/goldengate-wallpaper.desktop" > "$DESKTOP"
refresh_caches

echo "Backdrop is installed: open it from your app menu, or run goldengate-wallpaper."
