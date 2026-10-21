# Backdrop

A control app for [Wallpaper Engine](https://store.steampowered.com/app/431960/) wallpapers on KDE Plasma, built on the [Wallpaper Engine KDE plugin](https://github.com/catsout/wallpaper-engine-kde-plugin).

<img src="data/goldengate-backdrop.svg" width="96" alt="Backdrop icon">

Backdrop lets you browse your Wallpaper Engine library and apply wallpapers per screen. It also lets you tune everything the plugin can do, plus the per-wallpaper options Wallpaper Engine shows on Windows.

## Features

- **Library:** your Workshop subscriptions and your own projects, with animated previews on hover. You can search titles and tags, filter by Scenes, Videos, Web or Favourites, and sort by name, newest or size. Favourites are shared with the plugin's own settings.
- **Per screen:** apply a wallpaper to one screen or all of them, or switch a screen back to a static image.
- **This wallpaper:** Fit, Fill or Stretch, sound and volume, and playback speed, stored per wallpaper.
- **Wallpaper options:** the wallpaper's own settings (switches, sliders, colours, dropdowns), like the options panel on Windows.
  - Scene wallpapers get a private patched copy with your values written in, because the Linux renderer doesn't apply them itself.
  - Web wallpapers receive your values live (this needs the plugin patch below).
  - Options that only feed a wallpaper's scripts can't work on Linux. They are shown greyed out with the reason.
- **This screen:** frame rate, when to pause (fullscreen, maximised, focused and so on), mouse interaction, video player (Qt Multimedia or mpv), and automatic rotation.
- **Playback:** pause or resume every screen, and jump to a random wallpaper.
- **Crash guard:** some scenes crash the plugin's renderer, and with it Plasma. If Plasma dies right after you apply a scene, Backdrop restores the previous wallpaper, starts Plasma again, and marks that scene "Crashes Plasma on Linux" so it isn't applied again.

## Requirements

- KDE Plasma 6 (Wayland or X11)
- Python 3 with **PySide6 built against your system Qt 6**. Use your distribution's package (Fedora: `python3-pyside6`), not `pip install PySide6`, because the optional `org.goldengate.glass` module is a native Qt plugin and must match the Qt that loads it.
- The [Wallpaper Engine KDE plugin](https://github.com/catsout/wallpaper-engine-kde-plugin), built and installed (see [Installing the plugin](#installing-the-plugin)). Without it Backdrop can't apply wallpapers: a screen switched to a plugin Plasma can't find just shows black.
- Wallpaper Engine owned on Steam, with its content downloaded (the plugin reads it from your Steam library)
- Optional: the `org.goldengate.glass` QML module (not yet published). When it's installed (in `~/.local/lib64/qt6/qml`, which the launcher adds to `QML_IMPORT_PATH`), Backdrop uses its controls and theme. Without it, Backdrop runs on simple built-in stand-ins (`fallback/`) with solid panes.

## Install

```sh
git clone https://github.com/NoctoCodes/backdrop
cd backdrop
./install.sh
```

Backdrop is now in your app menu, and `goldengate-wallpaper` starts it from a terminal. Everything is installed for your user only, so no `sudo` is needed:

| What | Where |
|---|---|
| the app | `~/.local/share/goldengate-backdrop/app/` |
| the command | `~/.local/bin/goldengate-wallpaper` |
| menu entry and icon | `~/.local/share/applications/`, `~/.local/share/icons/` |

The installer warns you if PySide6 or the Wallpaper Engine plugin is missing. You can delete the clone afterwards.

- **Update:** `git pull`, then `./install.sh` again.
- **Uninstall:** `./install.sh --uninstall`. Your crash list and option overlays in `~/.local/share/goldengate-backdrop/` are kept; delete that folder to remove them too.
- **Run without installing:** `./backdrop` from the clone.

## Installing the plugin

Backdrop controls the [Wallpaper Engine KDE plugin](https://github.com/catsout/wallpaper-engine-kde-plugin), which has to be built from source.

> **Note:** the plugin was archived in May 2026. Its author continues the work as [Waywallen](https://github.com/waywallen/waywallen), a standalone wallpaper manager that Backdrop doesn't control. The plugin's last version still builds for Plasma 6, but a future Plasma update could break it.

These steps are for Fedora 44 with [RPM Fusion](https://rpmfusion.org/Configuration) enabled, and were tested with Plasma 6.7.5 on Wayland. On Fedora 44 the mpv package is `mpv-devel`, not the `mpv-libs-devel` the plugin's older instructions name.

1. Install the build dependencies:

   ```sh
   sudo dnf install mpv-devel lz4-devel vulkan-headers plasma-workspace-devel libplasma-devel \
       kf6-kpackage-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtwebchannel-devel \
       qt6-qtwebsockets-devel python3-websockets extra-cmake-modules cmake ninja-build gcc-c++
   ```

2. Get the source, with its scene renderer (a git submodule):

   ```sh
   git clone https://github.com/catsout/wallpaper-engine-kde-plugin
   cd wallpaper-engine-kde-plugin
   git submodule update --init --force --recursive
   ```

3. Build it, and install it in two parts. The compiled renderer goes into the system Qt folder (`/usr/lib64/qt6/qml`), which needs `sudo`. The wallpaper package goes into your home (`~/.local/share/plasma/wallpapers/`):

   ```sh
   cmake -B build -S . -GNinja -DUSE_PLASMAPKG=ON
   cmake --build build
   sudo cmake --install build
   cmake --build build --target install_pkg
   ```

4. Restart Plasma so it picks the plugin up:

   ```sh
   systemctl --user restart plasma-plasmashell
   ```

Backdrop notices the plugin within a few seconds, with no restart needed. If any screens went black before the plugin was installed, Backdrop's **Use Images** button puts them back on their static image.

To remove the plugin, first switch your screens to another wallpaper (Backdrop's **Use Image**), then:

```sh
sudo rm -r /usr/lib64/qt6/qml/com/github/catsout/wallpaperEngineKde
kpackagetool6 -t Plasma/Wallpaper -r com.github.catsout.wallpaperEngineKde
```

## Appearance

Backdrop adapts to what your KWin provides. It checks at start and every few seconds after, so turning an effect on or off updates it live.

- **Background blur:** with a blur effect running (KDE's own Blur works), the sidebar and inspector are frosted panes over your desktop. Without one, they're solid.
- **Rounded corners:** if a rounded-corners effect such as [KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners) is running, Backdrop lets it round the window and draw the outline, so it matches your other windows. Otherwise Backdrop rounds its own window and draws its own outline.

To preview the plain-blur or no-blur look on any setup:

```sh
BACKDROP_COMPOSITOR=blur ./backdrop     # or: none
```

## Optional: plugin improvements

Backdrop works with the stock plugin. These changes to the plugin make more of it work.

- **Pause button:** Backdrop's "pause all screens" needs a `ManualPause` setting in the plugin: one line in `contents/ui/main.qml`, where the `ok` binding becomes `... && !wallpaper.configuration.ManualPause`, plus a matching `ManualPause` Bool entry in `contents/config/main.xml`. Without it, the button does nothing.
- **Web wallpaper options:** `contents/ui/backend/QtWebView.qml` needs to merge `background.curOpt.user_properties` into the properties it sends to the page, and send them again when they change.
- **Renderer fixes:** the scene renderer had several bugs that made layered wallpapers render wrongly:
  - missing solid-colour layers
  - links between layers capturing the whole screen
  - zero texture resolutions for linked layers
  - an unset `g_TextureReductionScale`
  - skipped composition layers
  - shaders rejected over a vertex/fragment type mismatch
  - effect targets cleared to an opaque colour

  These fixes are planned as a pull request to the plugin. Until then they are available as a patch to `src/backend_scene`.

## How it works

- **Global and per-screen settings** are the plugin's own: they're read and written through Plasma's scripting interface (`org.kde.PlasmaShell.evaluateScript`), so the plugin's settings dialog always agrees with Backdrop.
- **Per-wallpaper settings and options** live in `~/.config/wekde/wallpaper/<id>.json`, the plugin's own per-wallpaper file, and Backdrop tells the plugin to reload them.
- **Scene options:** a scene's `scene.pkg` is unpacked into `~/.local/share/goldengate-backdrop/overlays/<id>/` with your values written into every property linked to an option, and the screen is pointed at that copy. Two copies alternate, so each change gives the plugin a new path to reload. Reset deletes them.

## Files

| File | What it is |
|---|---|
| `backdrop` | the launcher |
| `install.sh` | installs Backdrop for your user (`--uninstall` removes it) |
| `fallback/` | built-in stand-ins used when `org.goldengate.glass` isn't installed |
| `wallpaper.py` | the backend: library, settings, options, crash guard, compositor detection |
| `wepkg.py` | reads Wallpaper Engine `.pkg` files and builds the option overlays |
| `Main.qml` | the window |
| `Card.qml`, `SideRow.qml`, `Segmented.qml` | the cards, sidebar rows and segmented controls |
| `make_icon.py` | generates the icon (`data/goldengate-backdrop.svg`) |
| `data/` | desktop entry and icon |

## Licence

Backdrop is released under the [MIT licence](LICENSE).

## Credits and licences

- Uses the **org.goldengate.glass** QML module when it's installed (not yet published; it keeps its own licence notices). The stand-ins in `fallback/` are Backdrop's own.
- Built for the [Wallpaper Engine KDE plugin](https://github.com/catsout/wallpaper-engine-kde-plugin) by catsout (GPL-2.0).
- Not affiliated with Wallpaper Engine.
