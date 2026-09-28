# Keybindings

[← README](../README.md) · [Polski](pl/keybindings.md)

Every binding is defined in `config/hypr/hyprland.lua` with a description. The same list, straight from the compositor, is in Cogwheel → Hyprland → Shortcuts. There you can also move most of them to other keys and add your own application shortcuts (see [cogwheel.md](cogwheel.md#shortcuts)). The tables below show the default keys.

## Shell and apps

| Keys | Action |
|---|---|
| `SUPER + R` | Tile menu (pause), opened on Arsenal |
| `SUPER + U` | Cogwheel (settings) |
| `SUPER + O` | Media player panel |
| `SUPER + B` | Next power profile |
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + W` | File manager (yazi) |
| `SUPER + SHIFT + V` | Clipboard history (rofi) |
| `SUPER + L` | Lock screen |
| `SUPER + M` | Log out |

`SUPER + R`, `U`, `O` and `B` reach the shell through global shortcuts (`quickshell:menuToggle`, `systemToggle`, `mediaToggle`, `profilZasilania`). If the shell is not running they do nothing. `hyprctl globalshortcuts` lists what is registered.

## Windows

| Keys | Action |
|---|---|
| `SUPER + C` | Close window |
| `SUPER + V` | Floating / tiled window |
| `SUPER + P` | Pseudotile |
| `SUPER + J` | Toggle split direction (dwindle) |
| `SUPER + ←` `→` `↑` `↓` | Move focus |
| `SUPER + left mouse button` | Move window |
| `SUPER + right mouse button` | Resize window |
| `SUPER + S` | Show / hide scratchpad |
| `SUPER + SHIFT + X` | Move window to scratchpad |

## Desktops and floors

| Keys | Action |
|---|---|
| `SUPER + 1..0` | Desktop on the current floor |
| `SUPER + SHIFT + 1..0` | Move window to a desktop on the current floor |
| `SUPER + CTRL + 1..0` | Floor, returning to its last desktop |
| `SUPER + CTRL + ↑` / `↓` | Floor up / down |
| `SUPER + scroll` | Next / previous desktop on this floor |
| 3 fingers ← / → | Next / previous desktop of the floor (creates one past the last, never leaves the floor) |
| 3 fingers ↑ / ↓ | Floor up / down |

See [floors.md](floors.md).

## Screenshots

| Keys | Action |
|---|---|
| `SUPER + SHIFT + S` | Selected area |
| `SHIFT + Print` | Selected area |
| `Print` | Whole monitor |
| `SUPER + Print` | Chosen window |

Screenshots are saved to `<XDG Pictures>/Screenshots` (`Zrzuty ekranu` in Polish) and copied to the clipboard.

## Media keys

These also work while the screen is locked.

| Key | Action |
|---|---|
| Volume up / down | ±5 % (volume keys repeat when held) |
| Mute / Mic mute | Toggle output / microphone mute |
| Brightness up / down | ±5 % |
| Play, Pause | Play / pause (playerctl) |
| Next, Previous | Next / previous track |

## Inside the menus

**Tile row (pause)**

| Keys | Action |
|---|---|
| `←` `→` | Change tile (wraps) |
| `↓` / `Enter` | Enter the tile |
| `Esc` | Back one level / leave the pause |

**Arsenal**

| Keys | Action |
|---|---|
| typing | Filter programs |
| arrows | Move in the grid |
| `Enter` | Launch |
| `Backspace` | Delete a character |
| `Esc` | Clear the search, then back to the row |

**Cogwheel**

| Keys | Action |
|---|---|
| `↑` `↓` | Section / option |
| `→` / `Enter` | Into the options; confirm or edit a value |
| `←` `→` | Change a value |
| `Esc` | Back |

**Tidings**

| Keys | Action |
|---|---|
| `↑` `↓` | Scroll the history |
| `Delete` | Clear the whole history |
| `Esc` | Back to the row |

**Bonfire**

| Keys | Action |
|---|---|
| `↑` `↓` | Select an entry |
| `Enter` | Run it. Log out, Restart and Shut down need a second `Enter`. |
| `Esc` | Cancel / back |

**Media panel**

| Keys | Action |
|---|---|
| `←` `→` | Previous / next track |
| `Enter` / `Space` | Play / pause |
| `Esc` | Close |
