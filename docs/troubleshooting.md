# Troubleshooting and pitfalls

[← README](../README.md) · [Polski](pl/troubleshooting.md)

Each item below was found while building this configuration. Most of them fail silently, with nothing in the log.

## Common questions

**The tile row is not visible after login.** This is intended. The welcome layout opens windows, and the row hides while windows are open. Move the cursor to the bottom edge or press `SUPER + R`.

**Changing the charge limit asks for a password every time.** Install the [udev rule](installation.md#battery-charge-limit-udev-rule).

**The charge-limit rows are missing.** The battery has no `charge_control_*` files in sysfs, so the option is not available on this hardware.

**The CPU power limit rows are missing.** The shell cannot run `sudo -n /usr/local/sbin/df-limit-mocy`: the script or the sudo rule is not installed. See [installation.md](installation.md#cpu-power-limit-ryzenadj). `sudo -n -l /usr/local/sbin/df-limit-mocy` should print the path without asking for a password.

**Cogwheel says "iomem=relaxed is missing".** ryzenadj cannot reach the CPU. Check `grep -o iomem=relaxed /proc/cmdline`; if it prints nothing, the parameter did not make it into the boot loader config, or the machine was not rebooted.

**The wallpaper went back to the default after `./install.sh --apply`.** The wallpaper you pick in the Cogwheel is saved in `hyprpaper.conf` and `hyprlock.conf` as a local change. The installer keeps it unless the repo's version of those files changed; then your version is in a `.bak-*` file next to it. Pick the wallpaper again in the Cogwheel. See [installation.md](installation.md#what-installsh-does-not-cover).

**A setting from the Cogwheel broke Hyprland.** Hyprland shows a notification pointing to `ustawienia.lua`. Use Cogwheel → Hyprland → Restore defaults, or delete `~/.config/hypr/ustawienia.lua` and run `hyprctl reload`.

**`SUPER + R`, `U` or `O` do nothing.** The shell is not running. Start it with `qs -n -c dark-fantasy`. `hyprctl globalshortcuts` shows whether its shortcuts are registered.

**Every other click on a panel is ignored.** Two shell instances are running, and `hyprctl layers` shows two `quickshell-kafle` layers. The autostart uses `qs -n` (no duplicates) for this reason; kill the extra instance.

**Checking the autostart without logging out.** The autostart is exposed as a global function, and every program in it is guarded against starting twice:

```sh
hyprctl dispatch '(function() __autostart(); return hl.dsp.no_op() end)()'
```

## Copied configuration

### A change in `~/.config` is not in git

For your own additions to Hyprland, such as an environment variable, a window rule or a bind, use `~/.config/hypr/lokalne.lua` instead of editing `hyprland.lua`. `install.sh` never touches it (see [installation.md](installation.md#what-installsh-does-not-cover)).

`install.sh` copies the configuration, so `~/.config/...` and the repository are separate files. An edit on the system works, but `git status` in a clone does not see it. To keep it, copy the file into a clone and commit:

Use your clone's path: `~/Hyprland-Dark-Fantasy` by default, `~/hyprland-dark-fantasy` for a clone made before the rename, or the one you set in `HYPR_REPO_DIR`.

```sh
cp ~/.config/hypr/hyprland.lua ~/Hyprland-Dark-Fantasy/config/hypr/
cd ~/Hyprland-Dark-Fantasy && git add -A && git commit -m "describe the change"
```

The other way round, an edit in the repo does nothing until you run `./install.sh --apply`. Local changes you do not copy back still survive a reinstall: `install.sh` keeps them, unless the same file changed in the repo too.

`sed -i` and editors that save "atomically" no longer break anything; that only affected the symlinks created by older installs.

### `.bak` files next to the config

A file like `hyprland.lua.bak-20260912-143005` is a version that `install.sh --apply` moved aside because it could not keep it: since the last install both your copy and the repo file changed, or there was no record yet (a first install over an existing config). The repo version is now in place. Compare the two, carry over what you still want, then delete the backup. For your own lines in `hyprland.lua`, move them to `~/.config/hypr/lokalne.lua` so this does not happen again:

```sh
diff ~/.config/hypr/hyprland.lua.bak-20260912-143005 ~/.config/hypr/hyprland.lua
```

To see what the installer is going to do before it does it, run `./install.sh` without `--apply`.

## Hyprland with a Lua config

**`hyprctl dispatch` takes Lua, not hyprlang.** `hyprctl dispatch workspace 9` fails with `')' expected near '9'`. Use `hyprctl dispatch 'hl.dsp.focus({ workspace = 9 })'` instead. This affects every snippet from the internet and every Waybar config.

**`hyprctl keyword` does not work.** Reading the option back after writing still gives the old value. Change settings live with `hyprctl eval '<lua>'`, which is what the Cogwheel does.

**A command in `hl.exec_cmd()` must not start with `[`.** Hyprland treats a leading `[...]` as a window rule, a leftover from `exec-once = [workspace 2] firefox`. A condition like `[ "$(...)" = 2 ] || ...` is swallowed as a rule and nothing runs. Use `test` instead.

**A program started with `&` in `hl.exec_cmd()` dies.** Hyprland closes the shell immediately. Use `setsid --fork` and redirect the output to `/dev/null`.

**`hl.exec_cmd()` outside the `hyprland.start` event runs too early.** It fires while the config is being read, before the Wayland socket exists, so graphical programs have nothing to connect to. The autostart in `hyprland.lua` is registered with `hl.on("hyprland.start", ...)`.

**`hl.timer` called while the config is being read segfaults**, including under `Hyprland --verify-config`. Start timers only from events.

**Replacing `hyprland.lua` live with `cat >` once left the session with no keybindings at all.** Autoreload probably caught a half-written file. Safer: write to a temporary file in the same directory, `mv` it into place, then check `hyprctl binds -j | jq length`.

**The window class is not the `.desktop` file name.** Kate ships `org.kde.kate.desktop` but sets `StartupWMClass=kate`. This matters for window rules. Check with `hyprctl clients -j | grep '"class"'`.

## Processes

**`pkill -x` cannot match a process name longer than 15 characters.** The kernel keeps only that much in `comm`, so `pkill -x` quietly exits with code 1. Match the full command line instead: `pkill -f '^name'`. The `^` anchor keeps it from matching your own shell.

**`pgrep -f` inside a shell condition matches the shell itself**, because the command line of that shell contains the pattern. The autostart uses `pgrep -x` / `pgrep -cx` on the process name for this reason.

## hyprlock

**Do not kill `hyprlock` with `pkill` while the screen is locked.** It is an `ext-session-lock` client, and killing it can bring down the whole Hyprland session. Hyprland's API even has a rescue function for this case:

```sh
hyprctl dispatch 'hl.clear_crashed_lockscreen()'
```

To look at the lock screen safely, use `hyprlock --grace 30`: for 30 seconds any mouse movement unlocks without a password.

**`~` in the wallpaper path works in both hyprpaper and hyprlock.** hyprlock passes the background path through `absolutePath()`, which expands a leading `~`.

**hyprpaper 0.8 changed its syntax.** The old `preload = ...` and `wallpaper = ,...` keys load without an error and show no wallpaper. The current format is a `wallpaper { ... }` block, as in `config/hypr/hyprpaper.conf`.

## Fonts

**Pango drops "ł" in EB Garamond small caps.** Waybar and hyprlock render text with Pango, and the `smcp` feature in EB Garamond 0.016 has no "ł" glyph, so an empty gap appears in its place. Those places use the separate **"EB Garamond SC"** family instead.

**Lining figures need `lnum`.** Without it, EB Garamond draws old-style figures and "11" in small caps looks like the Roman "II".

## Shell and sysfs

**The battery in sysfs sends no inotify events.** A `FileView` with `watchChanges` stays silent while `energy_now` drops. The HUD therefore reads the battery every 10 s and reloads immediately when UPower reports a state change over D-Bus. The charge thresholds are read when the Power section opens.

## Notifications: four packages want the same D-Bus name

mako, swaync, the Plasma portal and the Quickshell shell all register `org.freedesktop.Notifications` for D-Bus activation, and whichever is started first wins. The file `local/share/dbus-1/services/org.freedesktop.Notifications.service` settles this in favour of the shell, because the user directory is searched before the system one.

Only one process can own the name, so **SwayNC must not start alongside the shell**. If it got there first, the shell would not see a single notification. That is why it is not in the autostart.

**Going back to SwayNC.** The package is still installed and its config is still copied. Restore `run_once("swaync")` in the autostart in `config/hypr/hyprland.lua`, and change `Exec` in the `.service` file back to `/usr/bin/swaync`.

**Which process owns the name:**

```sh
gdbus call --session --dest org.freedesktop.DBus \
  --object-path /org/freedesktop/DBus \
  --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications
```

## Waybar

**Waybar 0.14.0 logs `'swap-icon-label' must be a bool`** when that key is missing from `hyprland/window`. Setting it to `false` explicitly silences the warning.

**Waybar 0.14.0 has no cava module.** There is no USE flag for it. Cava only works as a standalone program.

**`"interval": 0` is not the same as no interval.** A custom module with only `"signal"` runs once and then refreshes on the signal. Adding `"interval": 0` stops the signal refreshes, which is why `custom/zasoby` has no interval key.

## SDDM

The SDDM pitfalls (config file order, the `display-manager` service on OpenRC, wallpaper permissions, quoting commas) are in [installation.md](installation.md#login-screen-sddm).
