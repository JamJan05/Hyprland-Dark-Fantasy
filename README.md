# Hyprland Dark Fantasy

A complete Hyprland desktop for Gentoo Linux that borrows the feel of the Dark Souls 3 menus through shapes, palette and typography alone. It is made for **ThinkPad laptops**.

**English** · [Polski](README.pl.md)

![Desktop: the HUD in the top-left corner, the "now" frame on the bar, yazi and tty-clock](assets/zrzuty/desktop.jpg)

| | |
|---|---|
| ![Arsenal](assets/zrzuty/arsenal.jpg) | ![Cogwheel](assets/zrzuty/cogwheel.jpg) |
| **Arsenal**: every installed program, with an item-style description | **Cogwheel**: settings laid out like in-game options |
| ![Bonfire](assets/zrzuty/bonfire.jpg) | ![Media panel](assets/zrzuty/media.jpg) |
| **Bonfire**: lock, suspend, log out, restart, shut down | **Media panel**: the current player, from the bar or `SUPER + O` |
| ![Tidings](assets/zrzuty/tidings.jpg) | |
| **Tidings**: notification history and "do not disturb" | |

## Features

- **Hyprland configured in Lua** (`hyprland.lua`, the `hl.*` API), not the `.conf` format that Hyprland 0.57 removes.
- **HUD in the top-left corner**: the floor emblem, HP / FP / stamina bars for battery, memory and CPU, the floor's desktops, and warnings that only appear when network traffic or CPU temperature is high.
- **A row of six tiles** instead of a dock and an app menu: Arsenal (apps), Satchel (files), Status (btop), Tidings (notifications), Cogwheel (settings), Bonfire (session). The row hides while windows are open and comes back when the cursor touches the bottom edge.
- **A pause menu you can drive from the keyboard**: press `SUPER + R` and start typing a program name. Arrows, Enter and Esc work in every tile.
- **Floors**: up to ten floors of desktops, each with its own desktops 1-0, plus three-finger gestures.
- **Live settings** in the Cogwheel: sound, brightness, power profile, battery charge limit, network, Bluetooth, gaps, blur, animation speed, wallpaper, keyboard layout, monitor scale, floors.
- **A "now" frame on Waybar** with the clock, the date and the current track. The player zone appears only while some application is playing.
- **Quickshell handles notifications, the OSD and the media panel**, so there is no separate daemon. swaync is installed only as a fallback notification daemon.
- **The same look everywhere**: hyprlock, an SDDM login theme, GTK 3/4, kitty, yazi, btop and the rofi clipboard picker.
- **English or Polish**, switched instantly.
- **Installers that show a plan first**: a copying installer that keeps your local changes and backs up the rest, and a from-scratch Gentoo bootstrap.

The design is original. The repository contains no assets, images, fonts or texts from Dark Souls or any other game.

## Quick start

These commands install the configuration. The packages have to be installed already (see [Requirements](#requirements)).

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/hyprland-dark-fantasy
cd ~/hyprland-dark-fantasy
./install.sh            # dry run: prints what would be copied, changes nothing
./install.sh --apply    # copies config/ into ~/.config, backs up files you changed
hyprctl reload          # or log out and start a Hyprland session
```

After `--apply` the files in `~/.config` are copies, so the repository folder can be deleted. To change something later, clone it again, edit, run `./install.sh --apply` and delete the folder again. Your local edits in `~/.config` survive a reinstall unless the same file changed in the repo; see [installation.md](docs/installation.md#what-installsh-copies). The installer also prints the steps that need root: Portage files, the SDDM theme and the udev rule.

> [!NOTE]
> The default keyboard layout is `pl`. Change it in Cogwheel → Hyprland → Input → Keyboard layout, or in `kb_layout` in `config/hypr/hyprland.lua`.

**Installing Gentoo from scratch?** [`bootstrap.sh`](bootstrap.sh) enables the overlays, installs the packages, clones the repository and runs `install.sh --apply`. It also shows a plan first. See [docs/installation.md](docs/installation.md).

## Requirements

- **A ThinkPad.** The setup was built and tested on a Lenovo ThinkPad E16 Gen 3 (AMD). The battery charge limit (`thinkpad_acpi`) and the CPU power limit (AMD Ryzen, ryzenadj) assume ThinkPad hardware. On other laptops the desktop still works, but those Cogwheel rows are hidden. Details in [docs/hardware.md](docs/hardware.md).
- **Gentoo Linux** with the **GURU** and **hyproverlay** overlays. The package files are in `gentoo/`. The configuration was built on OpenRC + elogind; the Gentoo-specific parts are listed in [docs/hardware.md](docs/hardware.md).
- **Hyprland 0.56+** with the Lua config, **Quickshell** (tested with 0.3.1), **Waybar** with USE `backlight network wifi mpris tray pipewire pulseaudio upower`.
- hyprlock, hypridle, hyprpaper (0.8 syntax), hyprshot, wl-clipboard + cliphist, rofi-wayland, hyprpolkitagent, xdg-desktop-portal-hyprland.
- PipeWire + WirePlumber, playerctl, brightnessctl, power-profiles-daemon and BlueZ. The network section relies on NetworkManager and the battery readout on UPower.
- kitty, yazi, btop, tty-clock, jq, Pillow (`dev-python/pillow`), and dbus-python + PyGObject for the Bluetooth pairing agent.
- Fonts: **EB Garamond** and **JetBrainsMono Nerd Font** (`media-fonts/nerdfonts` with USE `jetbrainsmono`).
- Theme: **adw-gtk3**, **Papirus-Dark** icons, **Bibata-Original-Classic** cursor.

<details>
<summary>The full package list (the same as <code>bootstrap.sh</code>)</summary>

```sh
sudo emerge --ask --verbose --changed-use \
  gui-wm/hyprland gui-apps/waybar gui-apps/swaync gui-apps/hyprlock \
  gui-apps/hypridle gui-apps/hyprpaper gui-apps/hyprshot gui-apps/wl-clipboard \
  app-misc/cliphist gui-apps/rofi-wayland sys-auth/hyprpolkitagent \
  gui-libs/xdg-desktop-portal-hyprland media-fonts/nerdfonts media-sound/playerctl \
  media-video/pipewire media-video/wireplumber gui-apps/grim gui-apps/slurp \
  app-misc/jq x11-terms/kitty app-misc/brightnessctl \
  sys-power/power-profiles-daemon net-wireless/bluez dev-python/dbus-python dev-python/pygobject \
  app-misc/yazi app-misc/tty-clock \
  media-fonts/eb-garamond x11-themes/adw-gtk3 x11-themes/papirus-icon-theme \
  x11-themes/bibata-xcursors sys-process/btop dev-python/pillow gui-apps/quickshell
```

Copy `gentoo/package.accept_keywords/hyprland-desktop` and `gentoo/package.use/hyprland-desktop` into `/etc/portage/` first, then upgrade libwayland with `sudo emerge --ask --oneshot --update ">=dev-libs/wayland-1.26.0"` (Hyprland 0.56 does not work with the stable 1.25). SDDM is not in the list; install it yourself if you want the login theme.

</details>

## Essential keybindings

| Keys | Action |
|---|---|
| `SUPER + R` | Tile menu, opened on Arsenal (type to search) |
| `SUPER + U` | Cogwheel (settings) |
| `SUPER + O` | Media panel |
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + W` | File manager (yazi) |
| `SUPER + C` | Close window |
| `SUPER + V` | Toggle floating / tiled window |
| `SUPER + L` | Lock screen |
| `SUPER + SHIFT + V` | Clipboard history |
| `SUPER + SHIFT + S` | Screenshot of a selected area |
| `SUPER + 1..0` | Desktop on the current floor |
| `SUPER + SHIFT + 1..0` | Move window to a desktop on the current floor |
| `SUPER + CTRL + 1..0` | Switch floor |
| `SUPER + B` | Next power profile |

The full list is in [docs/keybindings.md](docs/keybindings.md), or open Cogwheel → Hyprland → Shortcuts to see it with descriptions.

## Language

The interface is in **English** by default. You can switch to **Polish** in **Cogwheel → System → Language**. The change is instant, and Waybar, the lock screen and the shortcut descriptions follow it. The SDDM login theme has its own language setting: `sddm/install-theme.sh --apply --lang pl`. Details are in [docs/cogwheel.md](docs/cogwheel.md#language).

## Documentation

| Page | Contents |
|---|---|
| [Installation](docs/installation.md) | `install.sh`, `bootstrap.sh`, SDDM theme, udev rule, backup and restore |
| [Interface](docs/interface.md) | Visual rules, tile row, HUD, bar, media panel, notifications, lock screen |
| [Cogwheel](docs/cogwheel.md) | Every settings section, how settings are saved, language |
| [Floors](docs/floors.md) | Desktops grouped into floors, gestures, how it maps to workspaces |
| [Keybindings](docs/keybindings.md) | All shortcuts and the keys inside menus |
| [Troubleshooting](docs/troubleshooting.md) | Pitfalls found while building this setup |
| [Hardware and portability](docs/hardware.md) | Tested environment, Gentoo- and hardware-specific parts |
| [Repository layout](docs/repository.md) | Directory map, helper scripts, tools |

The same pages in Polish are in [docs/pl/](docs/pl/installation.md).

## Credits / License

- The look is inspired by the menus of Dark Souls 3. The repository contains no assets, images, fonts or texts from the game.
- The tile icons (`assets/ikony-menu/`) and the default wallpaper (`assets/wallpaper.png`) are the author's own work.
- Built on [Hyprland](https://hypr.land), [Quickshell](https://quickshell.org), [Waybar](https://github.com/Alexays/Waybar) and the other projects listed under Requirements.

License: [MIT](LICENSE)
