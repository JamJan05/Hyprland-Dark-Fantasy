# Repository layout

[← README](../README.md) · [Polski](pl/repository.md)

```
config/              mirror of ~/.config; install.sh copies it one to one
  hypr/              compositor, floors, lock screen, idle, wallpaper
  waybar/            bar and its styles
  quickshell/        QtQuick shell: HUD, tile row, panels, OSD, notifications
  swaync/            inactive; the shell handles notifications
  rofi/ kitty/ yazi/ btop/
  gtk-3.0/ gtk-4.0/  look of GTK apps: theme, icons, cursor, palette
  xdg-desktop-portal/ order of portal backends
  fish/              interactive fish config (fastfetch)
assets/              tile icon originals (ikony-menu/), wallpaper.png, screenshots (zrzuty/)
local/
  bin/               scripts called by Waybar, tiles and keybindings
  share/dbus-1/      makes the shell the notification daemon
gentoo/              keywords and USE flags for Portage
udev/                rule: battery charge thresholds writable by wheel
sbin/                df-limit-mocy: CPU power limit via ryzenadj (root, /usr/local/sbin)
sudoers/             rule: df-limit-mocy without a password for wheel
sddm/                login theme (QML) and its installer
tools/               icon scaling, textures and glyph generators for the shell
install.sh           copies config/ into ~/.config
bootstrap.sh         from-scratch install: overlays, packages, configuration
docs/                documentation (docs/pl/ in Polish)
```

`config/` deliberately mirrors `~/.config` instead of putting `hypr/` and `waybar/` at the top level. That keeps `install.sh` a simple one-to-one mapping with no exceptions.

## What is where

| Part | File |
|---|---|
| Compositor | `config/hypr/hyprland.lua` |
| Floors | `config/hypr/floors.lua` |
| Cogwheel settings (generated, not in the repo) | `~/.config/hypr/ustawienia.lua` |
| Lock screen | `config/hypr/hyprlock.conf` |
| Idle, screen off, suspend | `config/hypr/hypridle.conf` |
| Wallpaper | `config/hypr/hyprpaper.conf`, `assets/wallpaper.png` |
| Bar | `config/waybar/` |
| Shell entry point and IPC | `config/quickshell/dark-fantasy/shell.qml` |
| Palette, sizes, fonts | `config/quickshell/dark-fantasy/Theme.qml` |
| Tile row and tiles | `config/quickshell/dark-fantasy/kafle/` |
| HUD | `config/quickshell/dark-fantasy/hud/` |
| Cogwheel sections | `config/quickshell/dark-fantasy/system/` |
| Services (audio, battery, network, translations…) | `config/quickshell/dark-fantasy/services/` |
| Clipboard picker | `config/rofi/dark-fantasy.rasi` |
| Terminal and the Status panel window | `config/kitty/kitty.conf`, `config/kitty/panel.conf` |
| yazi and btop themes | `config/yazi/`, `config/btop/` |
| GTK look | `config/gtk-3.0/`, `config/gtk-4.0/` |
| Login screen | `sddm/` |

Many file and identifier names in the code are Polish (`kafle` = tiles, `Zebatka` = Cogwheel, `Uzbrojenie` = Arsenal, `Sakwa` = Satchel, `Wiesci` = Tidings, `Ognisko` = Bonfire, `pietra` = floors). Code comments are in English.

## Helper scripts (`local/bin/`)

`install.sh` copies them into `~/.local/bin/`.

| Script | Called by | What it does |
|---|---|---|
| `menedzer-plikow` | `SUPER + W`, Satchel tile | Runs yazi in kitty as a regular tiled window. It exists because keybindings and `.desktop` entries take a single word. |
| `monitor-systemu` | Status tile | Runs btop in a panel window: class `df-panel` (rule in `hyprland.lua`) and the separate kitty config `panel.conf` |
| `limit-ladowania` | Cogwheel → Power, terminal | Reads or sets the battery charge thresholds in the right order; uses `pkexec` without write access |
| `pamiec-ustawien` | Autostart | Restores the screen and keyboard backlight, volume and mute from before the shutdown, then saves them every few seconds to `~/.local/state/dark-fantasy/ustawienia-sprzetu`. Num Lock from the same file is read by `hyprland.lua`. |
| `uklad-startowy` | Autostart | Builds the welcome layout: terminal and `tty-clock` on the left, yazi on the right. Skips when the desktop already has a window. |
| `df-jezyk` | Waybar scripts, hyprlock | Prints the interface language, `en` or `pl` |
| `waybar-data` | `custom/data` | Date next to the clock in the interface language, without a leading zero |
| `waybar-okladka` | `image#okladka` | Downloads the MPRIS cover art and turns it into a desaturated engraving with a vignette; prints nothing (the module hides) when no player is running |
| `waybar-odtwarzacz` | `custom/odtwarzacz` | Follows `playerctl --follow` and prints the title and artist; empty text (the module hides) when no player is running |
| `waybar-temperatura` | `custom/temperatura` | CPU temperature as JSON, with CPU load, memory and GPU in the tooltip |
| `zrzut-ekranu` | *(fallback)* | The previous grim + slurp screenshot script; the keybindings now use `hyprshot` |

The tile row hiding logic is not a script; it lives in `config/quickshell/dark-fantasy/kafle/RzadKafli.qml`.

## Tools (`tools/`)

| Tool | Output |
|---|---|
| `skaluj-ikony-menu.py` | 256 px tile icons in `assets/ikony-menu/256/` (run by `install.sh --apply`) |
| `generuj-szum.py` | The noise texture laid under shell and SDDM surfaces |
| `generuj-winiete.py` | The vignette over program icons in Arsenal |
| `generuj-ikony-quickshell.py` | Nerd Font glyph code points for the shell |

All of them need Python 3; the image tools need Pillow.

## Ignored and generated files

`.gitignore` excludes secrets, backups (`*.bak-*` from the installers), caches, `config/hypr/ustawienia.lua`, `assets/ikony-menu/256/`, the wallpaper copy in `sddm/dark-fantasy/backgrounds/`, and the `colors.css` / `window_decorations.css` files that `kde-gtk-config` generates.
