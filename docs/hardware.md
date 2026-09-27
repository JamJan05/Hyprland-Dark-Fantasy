# Hardware and portability

[← README](../README.md) · [Polski](pl/hardware.md)

## Tested environment

- Gentoo, profile `default/linux/amd64/23.0/desktop/plasma`, **OpenRC + elogind**
- Hyprland 0.56.2 (`LUA_SINGLE_TARGET=lua5-4`), started from a TTY, without uwsm
- Quickshell 0.3.1, Waybar 0.14.0, hyprlock 0.9.6
- Lenovo ThinkPad E16 Gen 3 (AMD), built-in display `eDP-1` at 1920×1200@60, scale 1
- Keyboard layout `pl`

## Gentoo- and OpenRC-specific parts

This setup targets Gentoo and has only been used there. The following places assume Gentoo or OpenRC + elogind:

| Place | Assumption | On another system |
|---|---|---|
| `bootstrap.sh`, `gentoo/` | Portage, `eselect repository`, GURU and hyproverlay overlays | Install the packages yourself; the scripts will not run |
| `config/hypr/hypridle.conf`, `config/quickshell/dark-fantasy/services/Sesja.qml` | `loginctl suspend / reboot / poweroff / lock-session` from elogind | `bootstrap.sh` warns that on systemd these calls should be replaced with `systemctl` |
| Autostart in `config/hypr/hyprland.lua` | `gentoo-pipewire-launcher restart` starts PipeWire, pipewire-pulse and WirePlumber, because OpenRC does not start them | Replace it with however your system starts PipeWire |
| Autostart in `config/hypr/hyprland.lua` | The polkit agent at `/usr/libexec/hyprpolkitagent` | Adjust the path if your distribution installs it elsewhere |
| `sddm/install-theme.sh` hints | The display manager service is `display-manager` on OpenRC | `systemctl restart display-manager` on systemd |
| `udev/99-dark-fantasy-bateria.rules` | Administrators are in the `wheel` group; `/etc/udev/rules.d` may not exist | Change the group if needed |
| `sudoers/dark-fantasy-moc`, CPU power limit setup | The `wheel` group; `/etc/sudoers.d` may not exist; `iomem=relaxed` added through GRUB | Change the group; add the kernel parameter the way your boot loader does |

## Hardware-dependent parts

| Place | Value | What to do on other hardware |
|---|---|---|
| `config/hypr/hyprland.lua` | `kb_layout = "pl"`, monitor `scale = "1"` | Change them in the Cogwheel (Input, Monitor) or in the file |
| `config/hypr/hyprlock.conf` | Positions of the clock, password field and motto | Pixel offsets from the screen centre |
| `sddm/dark-fantasy/Main.qml` | `width: 1920`, `height: 1200` | Only the placeholder size for the preview; the greeter scales to the screen |
| `local/bin/waybar-temperatura` | `k10temp` (AMD) | Falls back to `acpitz`; on Intel consider adding `coretemp` |
| HUD, HP bar (`services/Battery.qml`) | Assumes a battery | Without one, HP is a full bar of fixed length (`Theme.hudHpBezBaterii`) |
| Cogwheel → Power | Requires `sys-power/power-profiles-daemon` | "Performance" appears only when the hardware reports it |
| Cogwheel → Power, charge limit | Battery `charge_control_*` files (ThinkPad: `thinkpad_acpi`) | Without them the rows are hidden |
| Cogwheel → Power, CPU power limit | AMD Ryzen mobile supported by ryzenadj; slider top 40 W, the burst limit of the ThinkPad's performance profile (Ryzen 7 250) | Without the root setup the rows are hidden; for another CPU change `maksimum` in `services/LimitMocy.qml` |
| Cogwheel → Monitor | Scales and refresh rates | Computed from `hyprctl monitors` for the current resolution; nothing to change |
| Cogwheel → Input, touchpad sensitivity | A device rule for the touchpad found in `hyprctl devices` | Without a touchpad the row is dimmed |

Deliberately **not** hard-coded: the backlight device, the monitor name and the touchpad name. The shell, Waybar and hyprpaper detect them.
