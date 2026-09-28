# Interface

[← README](../README.md) · [Polski](pl/interface.md)

The shell is written in Quickshell (`config/quickshell/dark-fantasy/`). It provides the HUD, the tile row, the panels, the OSD and the notification daemon. Waybar draws the bar, hyprlock the lock screen, and Hyprland itself the window frames and blur.

## Visual rules

These rules apply everywhere: Hyprland, the shell, Waybar, hyprlock, SDDM and GTK.

- **Sharp rectangles.** No rounded corners anywhere.
- **1 px frames** in faded gold. Whatever is active gets full gold.
- **Grain** in Hyprland's blur and under the shell panels ("ash, not smooth black").
- **EB Garamond in small caps** for lettering, **JetBrainsMono Nerd Font** for numbers.
- **Motion is a crossfade only.** No springs, no sliding, nothing pops out.
- **Ember is reserved for alarms and charging.** Even today's date in the calendar is gold, not ember.

The look comes entirely from shapes, palette and typography. No graphics, fonts or texts from the game are included.

### Palette

The palette is the same in every file (CSS, Lua, QML, hyprlang). In the shell the single source is `config/quickshell/dark-fantasy/Theme.qml`.

| Role | Colour |
|---|---|
| Background | `#0b0b0c` |
| Surface | `#151311` |
| Surface, alternate | `#201c18` |
| Text | `#d7d0c5` |
| Muted text | `#81786b` |
| Gold (accent) | `#b19a67` |
| Ember (alarms and charging only) | `#8f4935` |
| Iron | `#55504a` |
| HP bar (battery) | `#7a2c26` |
| FP bar (memory) | `#3f5566` |
| Stamina bar (CPU) | `#4f5d3a` |

## Tile row

Six tiles sit centred at the bottom of the screen. They replace the dock and the app menu, and a tile's content opens **above** the row.

| # | Tile | Polish UI | What it does |
|---|---|---|---|
| 1 | **Arsenal** | Uzbrojenie | All programs. A slot grid on the left, an "item description" of the selected program on the right (name, generic name, `Comment=` from the `.desktop` file, the `Exec` command). Typing filters the grid, Enter launches. |
| 2 | **Satchel** | Sakwa | Files: yazi in kitty, as a regular tiled window (`local/bin/menedzer-plikow`). |
| 3 | **Status** | Status | btop in a floating window, 70 × 70 % of the screen, that dims its surroundings (`local/bin/monitor-systemu`, window class `df-panel`). |
| 4 | **Tidings** | Wieści | Notification history and "do not disturb". A counter in the tile's corner shows waiting notifications. |
| 5 | **Cogwheel** | Zębatka | Settings. See [cogwheel.md](cogwheel.md). |
| 6 | **Bonfire** | Ognisko | Lock, suspend, log out, restart, shut down. The last three ask for confirmation. |

### When the row shows

The row reacts to what is on the desktop instead of using a timeout:

| Situation | Row |
|---|---|
| Empty desktop | visible |
| A window appears | hides |
| The last window closes | comes back |
| Cursor at the bottom edge | shows, even over windows |
| Cursor on the row | stays |
| Cursor moves away | hides again after 0.45 s |

Layer-shell surfaces such as bars, notifications and the wallpaper do not count as windows. Scratchpad windows count only while the scratchpad is shown. The cursor is detected by the window's input mask (a 3 px strip at the edge plus the row outline), so nothing polls in the background.

After login, the welcome layout (`local/bin/uklad-startowy`) opens a terminal, `tty-clock` and yazi. Because there are windows, the row starts hidden. That is intended, not a bug.

### Pause

`SUPER + R` (opens straight into Arsenal, ready for typing) or a click on the strip at the bottom edge opens the **pause**. The desktop dims, including the bar and HUD, gold lines appear above and below the row, and the keyboard works like a gamepad:

| Keys | Action |
|---|---|
| `←` `→` | Change tile, wrapping around |
| `↓` / `Enter` | Enter the tile's content |
| `Esc` | Back one level; on the row, leave the pause |
| typing | On a tile with content, jumps straight into it |

With the mouse, **one click uses a tile**: Satchel and Status launch their program, and the others open their content in the pause.

Keys inside each tile are listed in [keybindings.md](keybindings.md#inside-the-menus).

### Tile icons

- The originals are six PNG files of 512 × 512 px in `assets/ikony-menu/`: `uzbrojenie.png`, `sakwa.png`, `status.png`, `wiesci.png`, `zebatka.png`, `ognisko.png`. Each has its own frame and relief, so the shell draws no second frame around the tile.
- `tools/skaluj-ikony-menu.py` makes 256 × 256 copies (Lanczos) in `assets/ikony-menu/256/`. That directory is build output and is listed in `.gitignore`.
- `install.sh --apply` runs the script and copies `256/` to `~/.local/share/dark-fantasy/ikony-menu`, the fixed path the shell reads from.
- The icons are the repository owner's own work. They are not taken from the game.

## HUD in the top-left corner

The HUD is a separate shell layer window above the left end of the bar. It has the same height, background and outline as the Waybar frames. The layout is a game HUD: an emblem on the left, three bars next to it, and a row of statuses below.

- **Emblem.** The current floor as a Roman numeral (`I` … `X`) in a double frame. The tooltip shows the floor number and its name from the Cogwheel. **Scrolling** over the emblem changes the floor.
- **Three 6 px bars.** Length shows the machine's "stats" and the fill shows the current state. Numbers appear only in the tooltips.

  | Bar | Fill | Length |
  |---|---|---|
  | HP | battery level | 4 px per design Wh (`energy_full_design`), shortened by battery health (`energy_full`). A worn battery has a shorter bar, like lost max HP. |
  | FP | used RAM | 14 px per GiB |
  | Stamina | CPU load | 12 px per thread |

  While charging, the HP outline turns ember. Without a battery, HP is a full bar of fixed length.
- **The floor's desktops.** One square per existing desktop. The active desktop is filled with gold, and a desktop whose window wants attention is ember. Click a square to switch.
- **Build-up statuses.** They appear only while something is happening and fade after 5 s of quiet: network transfer above 100 KiB/s (gold) and CPU temperature above 70 °C (ember).

The bars can be turned off in Cogwheel → System → Behavior → HUD bars. CPU, memory and battery then appear as numbers on the right side of Waybar (`custom/zasoby`).

## Bar (Waybar)

- **Left:** the active window title, offset past the HUD.
- **Centre, the "now" frame:** `HH:MM` in the mono font, the date in small caps, the cover art (desaturated, with a vignette) and the title and artist. When no application is playing, the cover art, the title and the buttons hide and the frame shrinks to the clock and the date.
  - Hover the clock for a calendar. Scroll to change month; right-click to toggle month / year.
  - Hover the title to reveal previous / play-pause / next buttons.
  - Click the title or the cover to open the media panel.
- **Right:** resource numbers (only when the HUD bars are off), temperature, network, Bluetooth, tray.
  - **Temperature:** the tooltip adds CPU load, memory use and the integrated GPU state. The module turns ember above 70 °C, the same threshold as the HUD.
  - **Network:** left click opens a quick Wi-Fi panel with a toggle, the network list and connecting with a password (WPA/WPA2/WPA3-PSK). Right click opens `nmtui` for everything else, such as enterprise EAP networks.
  - **Bluetooth:** left click opens a quick panel with power, devices, one-click connect and headset battery. Right click opens `bluetoothctl` for pairing with a PIN, trust and blocking.

Volume and brightness are not on the bar. They live in the Cogwheel, the media keys work as usual, and the OSD confirms each change.

## Media panel

Open it with `SUPER + O`, or by clicking the title or cover in the "now" frame. It shows the current player: a "Now playing" header, the cover as an "item" (desaturated, vignetted), the track, progress as a 6 px HUD bar, and bare glyph buttons. When nothing plays it says so.

| Keys | Action |
|---|---|
| `←` / `→` | Previous / next track |
| `Enter` / `Space` | Play / pause |
| `Esc` or a click outside | Close |

## Notifications and OSD

- **Notification daemon.** The shell owns `org.freedesktop.Notifications`. The file `local/share/dbus-1/services/org.freedesktop.Notifications.service` makes D-Bus activation start the shell instead of mako, swaync or Plasma. SwayNC stays installed and configured as a fallback; see [troubleshooting.md](troubleshooting.md#notifications-four-packages-want-the-same-d-bus-name).
- **Popups** appear in the top-right corner below the bar, on the overlay layer, so they stay visible over fullscreen windows.
- **Tidings** keeps the history with "Clear" and "do not disturb". "Do not disturb" is remembered across a shell restart, a logout and a reboot. Opening Tidings hides the popups on screen.
- **OSD.** A short preview at the bottom of the screen when volume, brightness, mute or the power profile changes. It stays quiet at shell startup and while the Cogwheel is open, because the Cogwheel shows the same values.

## Lock screen and idle

`config/hypr/hypridle.conf` sets the idle chain:

| After | Action |
|---|---|
| 5 min | Screen off |
| 10 min | Lock (`loginctl lock-session` → hyprlock) |
| 30 min | Suspend (`loginctl suspend`) |

The session is also locked before sleep. Cogwheel → System → Behavior → **Keep screen on** blocks all three.

hyprlock (`config/hypr/hyprlock.conf`) shows the wallpaper, a clock, the password field and the motto. `SUPER + L` locks on demand and does not start a second instance. The lock screen texts follow the interface language (see [cogwheel.md](cogwheel.md#language)).

## Screenshots and clipboard

- **Screenshots** use `hyprshot`: it copies to the clipboard, saves a file and sends a notification. Files go to `<XDG Pictures>/Screenshots` (`Zrzuty ekranu` when the interface is Polish), created on first use. The older `local/bin/zrzut-ekranu` (grim + slurp) still works as a fallback.
- **Clipboard history:** `wl-paste --watch cliphist store` runs for text and images, and `SUPER + SHIFT + V` opens the history in rofi with the `dark-fantasy.rasi` theme.

## Controlling the shell from scripts

The shell exposes IPC targets. `qs -c dark-fantasy ipc show` lists them all. Examples:

```sh
qs -c dark-fantasy ipc call media toggle            # media panel
qs -c dark-fantasy ipc call system toggle           # Cogwheel
qs -c dark-fantasy ipc call kafle toggle            # tile menu pause
qs -c dark-fantasy ipc call notifications toggleDnd # do not disturb
qs -c dark-fantasy ipc call hud przelaczPaski       # HUD bars on / off
qs -c dark-fantasy ipc call zasilanie przelaczProfil
qs -c dark-fantasy ipc call jezyk ustaw pl           # interface language
qs -c dark-fantasy ipc call idle toggle             # keep screen on
```
