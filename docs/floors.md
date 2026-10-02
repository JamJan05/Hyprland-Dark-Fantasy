# Floors

[← README](../README.md) · [Polski](pl/floors.md)

A **floor** groups ten desktops. Each floor has its own desktops 1-9 and 0, so `SUPER + 3` on floor I and `SUPER + 3` on floor II are two different desktops. The key `0` means "tenth", both for a desktop and for a floor (floor `X`).

The HUD in the top-left corner shows the current floor as a Roman numeral on the emblem, with a square for each existing desktop of **that** floor below the bars.

## Controls

| Input | Action |
|---|---|
| `SUPER + 1..0` | Desktop on the current floor |
| `SUPER + SHIFT + 1..0` | Move the window to a desktop on the current floor (focus follows) |
| `SUPER + CTRL + 1..0` | Go to a floor, returning to the desktop you last used there |
| `SUPER + CTRL + ↑` / `↓` | Floor up / down (stops at the first and last floor) |
| `SUPER + scroll` | Next / previous existing desktop of the floor, wrapping around |
| 3 fingers ← / → | Next / previous desktop of the floor |
| 3 fingers ↑ / ↓ | Floor up / down |
| Click a square in the HUD | Switch to that desktop |
| Scroll over the HUD emblem | Change floor |

A floor beyond the configured number of floors does nothing. For example, `SUPER + CTRL + 7` with five floors is ignored.

## Gestures

Both three-finger gestures work from anywhere on the screen.

- **Sideways** moves through the existing desktops of the floor. It never wraps and **never leaves the floor**. Past the last desktop it creates **one** new desktop, as the native swipe does, except when the current desktop is empty or is desktop 0.
- **Up / down** changes the floor.
- **Thresholds** are the ones Hyprland uses for its native swipe. The movement must reach `workspace_swipe_distance × workspace_swipe_cancel_ratio` (default 300 × 0.5 = 150 px) or be a fast flick, so an accidental twitch does nothing.
- **Direction** follows `gestures:workspace_swipe_invert`. With the default, fingers to the left go to the next desktop and fingers up go to the next floor. To reverse both, set "Next desktop / floor: fingers" to "right / down" in Cogwheel → Hyprland → Input.
- **The desktop changes when you lift your fingers**, with the normal workspace animation. It does not follow the fingers, because the native gesture cannot be stopped at the edge of a floor. That is the trade-off for keeping gestures inside the floor.

Floor gestures can be turned off in Cogwheel → Hyprland → Input.

## Number of floors and names

Cogwheel → Hyprland → Floors sets the number of floors (1-10) and a name for each. The name appears in the emblem's tooltip, and the emblem itself keeps the Roman numeral.

Changing the number of floors never moves windows. The grid is always 10 × 10; the setting only limits which floors can be entered.

## How it maps to Hyprland workspaces

Floors are plain numbered Hyprland workspaces:

```
id = (floor - 1) × 10 + desktop        (desktop 0 = 10)

floor I  → 1..10     floor II → 11..20     …     floor X → 91..100
```

- Floor I is exactly the classic workspaces 1-10, so if you never change floors nothing is different.
- Workspaces appear on first entry and vanish when empty; nothing is created in advance.
- Named workspaces are not used, because Hyprland gives them negative ids in creation order, which would change every session.
- Workspace numbers are not shown anywhere in the interface.

## Implementation

Everything lives in `config/hypr/floors.lua`, loaded by `hyprland.lua` through `require("floors")`. There is no plugin and no background script.

- **The current floor is always computed from the active workspace id**, never stored in a variable. A gesture, a HUD click or `hyprctl dispatch` from a terminal therefore cannot make the HUD show the wrong floor.
- **The last desktop of each floor** is remembered in a file in the Hyprland instance directory (`$XDG_RUNTIME_DIR/hypr/<instance signature>/`), because a config reload restarts the Lua interpreter. A new session starts on floor I, desktop 1.
- **State for the HUD.** After every change `floors.lua` writes `floors-stan.json` to the same directory, replacing it atomically through a temporary file and a rename. The shell watches that file, so nothing is polled and no signals are sent.
- **Settings** come from the Cogwheel through `floors.ustaw({ pietra = …, nazwy = { … }, gesty = … })`, which is called from `~/.config/hypr/ustawienia.lua` and live through `hyprctl eval`.
- **Actions return dispatchers**, so they can be used from a terminal too:

  ```sh
  hyprctl dispatch 'floors.desktop(3)'
  ```

  With a Lua config, `hyprctl dispatch X` is shorthand for `hl.dispatch(X)`.
