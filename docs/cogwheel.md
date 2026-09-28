# Cogwheel (settings)

[← README](../README.md) · [Polski](pl/cogwheel.md)

The Cogwheel (*Zębatka* in the Polish UI) is the settings tile. It is laid out like game options: sections on the left, "label … value" rows on the right. Sliders are the same 6 px bars as in the HUD, and switches are small-caps `On / Off` labels.

Open it with `SUPER + U` or from the tile row.

| Where | Keys |
|---|---|
| Section list | `↑` `↓` select, `→` / `Enter` into the options, `Esc` back to the tile row |
| Options | `↑` `↓` row, `←` `→` change value, `Enter` confirm or edit, `Esc` back to the list |

Network and Bluetooth need device lists, passwords and pairing, which do not fit "label … value" rows. They stay mouse-driven cards; the keyboard only scrolls them.

## Sections

### System

| Section | Options |
|---|---|
| **Sound** | Output device, volume, mute, microphone volume, mute microphone, per-app volume of playing programs (from PipeWire) |
| **Display** | Backlight brightness and the device name |
| **Power** | Power profile, CPU power limit per profile, charge limit, resume charging threshold, battery state |
| **Behavior** | Keep screen on (blocks screen off, lock and suspend), HUD bars |
| **Network** | Wi-Fi toggle, network list, connecting with a password (NetworkManager) |
| **Bluetooth** | Power (remembered across reboots), device list, connecting |
| **Language** | English or Polish (see [Language](#language)) |

### Hyprland

| Section | Options |
|---|---|
| **Appearance** | Gap between windows, gap from screen edge, border width, blur, blur strength, opacity of inactive windows, dim inactive windows, dimming strength |
| **Motion** | Animations on / off, animation speed 0.5× - 2× (one multiplier for every animation) |
| **Wallpaper** | Pick a file from the wallpaper folder with a preview, then "Set as wallpaper" |
| **Input** | Touchpad sensitivity (a rule for the touchpad only, not the mouse), natural scrolling, keyboard layout, floor gestures (3 fingers) |
| **Monitor** | Scale (only "clean" scales for the current resolution), refresh rate, position of a second monitor |
| **Floors** | Number of floors (1-10) and a name for each floor |
| **Shortcuts** | Your own application shortcuts, moving the main shortcuts to other keys, and a read-only list of the fixed ones (desktops, mouse, media keys). See [Shortcuts](#shortcuts) |
| **Restore defaults** | Deletes the settings file and reloads Hyprland. It first asks "Restore defaults?" with Yes / No; the cursor starts on No. |

Keyboard layouts offered: `pl`, `us`, `gb`, `de`, `fr`, `es`, `it`, `cz`, `sk`, `ua`.

Scales are limited to "clean" values because the resolution divided by the scale must be an integer. Otherwise Hyprland silently picks a different scale. The list is computed from `hyprctl monitors`.

## Power profile and charge limit

**Power profile.** `SUPER + B` cycles the power-profiles-daemon profile: power saver → balanced → performance. Performance appears only if the hardware reports it. The OSD confirms the new profile. The same choice is in System → Power.

**Charge limit.** Stops charging at a chosen level, for example 75 %, and resumes only 5 points lower. A laptop that stays plugged in keeps its battery healthier this way.

- Writes go to `charge_control_end_threshold` and `charge_control_start_threshold` in `/sys/class/power_supply/BAT0/`. On ThinkPads the `thinkpad_acpi` driver exposes them; other laptops with the same kernel interface work too.
- **Without these files the charge-limit rows are hidden.**
- The files belong to root. Without the [udev rule](installation.md#battery-charge-limit-udev-rule) every change asks for the administrator password (`pkexec`).
- The shell remembers the last limit and restores it at session start, but only silently, which means only with the udev rule installed. ThinkPads also keep the thresholds in the embedded controller.
- From a terminal: `limit-ladowania` prints `start end writable`, and `limit-ladowania 75` sets the limit. The script knows the write order that `thinkpad_acpi` requires.

## CPU power limit

A hard ceiling on CPU power for each power profile, for example 7 W in power saver and 15 W in balanced. One slider per profile, 5-40 W; one step past 40 W means the factory limit. The "CPU power limit" row shows the current limit and the factory one of the current profile.

- The limit covers the CPU with its integrated GPU, not the whole laptop: the screen, Wi-Fi and disk come on top. On an idle desktop it changes nothing, because the CPU draws less anyway. It matters under load: compiling, games, heavy web pages.
- STAPM, PPT fast and PPT slow are all set to the same value, so there is no short boost above it either.
- It is applied on every profile change (Cogwheel, `SUPER + B`, anything else talking to power-profiles-daemon), 800 ms after the slider stops, and re-checked once a minute, because some firmware quietly restores its own limits.
- **ThinkPads have their own limits per profile.** The firmware changes them on every `platform_profile` change (on the tested laptop: 10 W in low-power). The factory value is therefore recorded separately for each profile, on the first call in it after boot.
- **Setup needs root:** ryzenadj, the `df-limit-mocy` script with its sudo rule, and the `iomem=relaxed` kernel parameter. See [installation.md](installation.md#cpu-power-limit-ryzenadj). Until then the rows are hidden; with a partial setup, an error line says what is missing.
- From a terminal: `sudo df-limit-mocy` prints the current and factory limits (six numbers in W), `sudo df-limit-mocy 7` sets 7 W, `sudo df-limit-mocy fabryczny` restores the factory limits.

## Shortcuts

- **Change keys:** select a shortcut, press Enter, then press the new combination. `Esc` cancels. `Delete` restores the default keys. A moved shortcut is marked with `*`.
- **Application shortcut:** choose **New application shortcut**. Search with Enter and typing, pick the application with ← →, set the keys, then choose **save**. It starts the program through `gtk-launch <desktop id>`, like the Arsenal. `Delete` on the shortcut removes it.
- **Refused keys:** keys already used by another shortcut, and keys without `SUPER`, `CTRL` or `ALT` (a single key would stop working for typing). F keys and PrtSc are allowed on their own.
- **While the keys are captured**, Hyprland switches to an empty submap, `df-przechwyt`, so the combination you press does not trigger its current action. The Cogwheel switches back afterwards, and after 10 s without a key it gives up. If Hyprland ever stays stuck without shortcuts, `SUPER + Escape` leaves the submap.
- **Fixed shortcuts** are desktops and floors, the mouse and the laptop's media keys. Change them in `hyprland.lua`.

Changes apply at once and are saved in `ustawienia.lua` (`przypiszSkrot(...)` and `wlasnySkrot(...)` lines). **Restore defaults** removes them all.

## Wallpaper

The Wallpaper section lists `.png`, `.jpg`/`.jpeg` and `.webp` files from `<XDG Pictures>/Wallpapers`. If that folder does not exist but `<XDG Pictures>/Tapety` does, it uses that one. When `xdg-user-dir` is not available, `~/Pictures` is used.

The arrows only select a candidate and show its preview. **Set as wallpaper** then:

1. rewrites `path` in `~/.config/hypr/hyprpaper.conf` and `$tapeta` in `~/.config/hypr/hyprlock.conf`,
2. restarts this session's hyprpaper.

Both files are copies installed by `install.sh`, so this is a local change: it does not appear in `git status`, and reinstalling keeps it unless the repo's version of those files changed (then your version goes to a `.bak-*` backup). The default wallpaper is `~/.local/share/dark-fantasy/wallpaper.png`, a copy of `assets/wallpaper.png`. **Restore defaults** does not touch the wallpaper.

## How settings are saved

The Cogwheel **never edits `hyprland.lua`**. That file is written by hand, with comments. Instead the Cogwheel owns a single file, `~/.config/hypr/ustawienia.lua` (following `$XDG_CONFIG_HOME`):

1. **Every change goes to the compositor immediately** through `hyprctl eval`, for example `hl.config({ general = { gaps_in = 12 } })`. `hyprctl keyword` does not work with a Lua config.
2. **After 600 ms of quiet** the shell rewrites the whole file, not on every slider step.
3. **`hyprland.lua` loads the file at the very end**, so its values override the defaults above it. It is loaded with `dofile` inside `pcall`: an error in the file produces a notification pointing to "Restore defaults" instead of breaking the whole config.
4. **Restore defaults** deletes the file and runs `hyprctl reload`.

Example (abridged):

```lua
-- stan: {"opcje":{"general:gaps_in":12},"tempo":2,"pietra":4,"nazwy":["","Work"],"gesty":true,...}
--
-- FILE MANAGED BY THE SHELL (Cogwheel -> Hyprland).
-- Manual edits will be overwritten by the next change in the Cogwheel.
-- "Restore defaults" deletes this file. It is loaded at the end of hyprland.lua.
-- The "stan" line above is the data this file is generated from.

hl.config({ general = { gaps_in = 12 } })
ustawAnimacje(2)
floors.ustaw({ pietra = 4, nazwy = { "", "Work" }, gesty = true })
```

The first line holds the data the file was generated from. The Cogwheel reads back from it whatever `hyprctl getoption` cannot report: animation speed, touchpad sensitivity, floors and monitor scale. Other values are read from `hyprctl getoption` each time the Cogwheel opens.

The file lives **outside the repository**. It describes this computer, not the desktop configuration.

### Shell settings

Settings that belong to the shell itself go to `~/.local/state/dark-fantasy/powloka.json` (following `$XDG_STATE_HOME`):

| Key | Meaning |
|---|---|
| `hudBars` | HUD bars on / off |
| `limitLadowania` | Last charge limit (0 = never set) |
| `mocOszczedny`, `mocZrownowazony`, `mocWydajny` | CPU power limit in W for power saver, balanced and performance (0 = factory) |
| `jezyk` | Interface language, `en` or `pl` |

## Language

English is the default. **System → Language** switches to Polish instantly, with no restart. Language names are always written in their own language, so the option stays recognisable.

What follows the language:

| Part | How |
|---|---|
| Shell (all panels, tiles, OSD, tooltips) | `services/Tr.qml`: every `Tr.t("English", "Polski")` binding re-evaluates |
| Hyprland shortcut descriptions, screenshot folder name | `T(en, pl)` in `hyprland.lua` reads `powloka.json`; the shell runs `hyprctl reload` after a change |
| Waybar (date, player, temperature tooltip) | Scripts ask `local/bin/df-jezyk`; the shell sends `SIGRTMIN+12` so they refresh at once |
| hyprlock (password prompt, motto) | The shell writes `~/.local/state/dark-fantasy/hyprlock-jezyk.conf`, which `hyprlock.conf` sources |
| SDDM login screen | Set at install time: `sddm/install-theme.sh --apply --lang pl`. Without `--lang` it uses the language from `powloka.json` |

The SDDM greeter runs as the `sddm` user before anyone logs in, so it cannot follow the Cogwheel live. Run `install-theme.sh` again after changing the language.

From a script: `qs -c dark-fantasy ipc call jezyk ustaw pl`.
