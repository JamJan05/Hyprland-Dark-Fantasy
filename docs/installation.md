# Installation

[← README](../README.md) · [Polski](pl/installation.md)

Three scripts install this desktop. Each one **shows a plan and changes nothing** until you add `--apply`.

| Script | What it does | Needs root |
|---|---|---|
| [`install.sh`](../install.sh) | Copies `config/` and friends into `~/.config` and `~/.local` | no |
| [`bootstrap.sh`](../bootstrap.sh) | From-scratch Gentoo setup: overlays, Portage files, packages, clone, `install.sh --apply`, udev rule | through `sudo` |
| [`sddm/install-theme.sh`](../sddm/install-theme.sh) | Installs the SDDM login theme and makes it the default | through `sudo` |

## Option A: from scratch with `bootstrap.sh`

Show the plan first:

```sh
curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh | bash
```

Then run it for real:

```sh
curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh | bash -s -- --apply
```

The dry run is the default on purpose. A script piped from `curl` into a shell should not install dozens of packages and change the system before you have seen what it is going to do.

What `--apply` does, in order:

1. Checks that the system is Gentoo, that `emerge`, `git` and `sudo` exist, and that the script is **not** running as root. It also detects OpenRC or systemd.
2. Asks for the `sudo` password once, up front. With `curl | bash` it reads the password from `/dev/tty`.
3. Enables the **GURU** and **hyproverlay** overlays with `eselect repository` and syncs them.
4. Clones the repository into `~/hyprland-dark-fantasy`. Set `HYPR_REPO_DIR` to use a different path. If the script is run from inside a clone, it uses that clone.
5. Copies `gentoo/package.accept_keywords/hyprland-desktop` and `gentoo/package.use/hyprland-desktop` into `/etc/portage/`, unless they already exist. If Portage still cannot see `dev-libs/wayland` 1.26 (an older copy of the file), it appends that one entry.
6. Upgrades `dev-libs/wayland` to 1.26 (`emerge --oneshot --update`), then installs the packages with `emerge --ask --verbose --changed-use`. Compiling Hyprland and the Qt dependencies takes a while.
7. Runs `install.sh --apply`.
8. Installs the battery udev rule, but only if the battery exposes charge thresholds.
9. On OpenRC, installs and enables the [`dark-fantasy-stan` service](#state-before-login-openrc-service).

The script is idempotent: running it again skips whatever is already done. `./bootstrap.sh --help` prints the same summary. The installed desktop does not need the clone in `~/hyprland-dark-fantasy`; you can delete it afterwards.

If `sudo` cannot ask for a password because there is no terminal, download the script and run it directly:

```sh
curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh -o bootstrap.sh
bash bootstrap.sh --apply
```

`bootstrap.sh` deliberately does **not** install user programs such as browsers, messengers or games. Arsenal simply shows whatever is installed.

## Option B: install the packages yourself

Enable the overlays:

```sh
sudo eselect repository enable guru
sudo eselect repository enable hyproverlay
sudo emaint sync -r guru -r hyproverlay
```

Copy the Portage files. They add keywords for the `~amd64` packages and the USE flags this setup needs:

```sh
sudo cp gentoo/package.accept_keywords/hyprland-desktop /etc/portage/package.accept_keywords/
sudo cp gentoo/package.use/hyprland-desktop             /etc/portage/package.use/
```

Hyprland 0.56 does not work with the stable `dev-libs/wayland` 1.25, and 1.26 is still `~amd64`. The file above unmasks it; upgrade it first, as a dependency only:

```sh
sudo emerge --ask --oneshot --update ">=dev-libs/wayland-1.26.0"
```

Install the same list as the `PAKIETY` array in `bootstrap.sh`:

```sh
sudo emerge --ask --verbose --changed-use \
  gui-wm/hyprland gui-apps/waybar gui-apps/swaync gui-apps/hyprlock \
  gui-apps/hypridle gui-apps/hyprpaper gui-apps/hyprshot gui-apps/wl-clipboard \
  app-misc/cliphist gui-apps/rofi-wayland sys-auth/hyprpolkitagent \
  gui-libs/xdg-desktop-portal-hyprland media-fonts/nerdfonts media-sound/playerctl \
  media-video/pipewire media-video/wireplumber gui-apps/grim gui-apps/slurp \
  app-misc/jq x11-terms/kitty app-misc/brightnessctl \
  sys-power/power-profiles-daemon net-wireless/bluez app-misc/yazi app-misc/tty-clock \
  media-fonts/eb-garamond x11-themes/adw-gtk3 x11-themes/papirus-icon-theme \
  x11-themes/bibata-xcursors sys-process/btop dev-python/pillow gui-apps/quickshell
```

Notes on the list:

- **Waybar** needs USE `backlight network wifi mpris tray pipewire pulseaudio upower`. Without `wifi` the network module shows no SSID or signal strength.
- **Quickshell** stays on its default USE flags. Its crash handler pulls in `dev-cpp/cpptrace`, which needs USE `unwind` (set in `gentoo/package.use`).
- **Theme packages**: `eb-garamond` provides the lettering font, `adw-gtk3` the GTK theme, `papirus-icon-theme` the icons in GTK and in Arsenal, and `bibata-xcursors` the cursor. `btop` backs the Status tile. `pillow` processes the cover art on the bar, the tile icons and the textures. `adw-gtk3` and `bibata-xcursors` come from GURU.
- **Without a package**, the matching element falls back to a default look or shows an "unavailable" state; the desktop still starts.
- **SDDM** and **fish** are not on the list. The SDDM theme and `config/fish/config.fish` are optional.

Then install the configuration:

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/hyprland-dark-fantasy
cd ~/hyprland-dark-fantasy
./install.sh
./install.sh --apply
```

## What `install.sh` copies

Every entry is **copied** from the repository; no symlinks are created. After `--apply` the repository folder can be deleted. To change something later, clone it again, edit, run `./install.sh --apply` and delete the folder again.

| Area | Source in the repo | Target |
|---|---|---|
| Hyprland | `config/hypr/hyprland.lua`, `floors.lua`, `hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf` | `~/.config/hypr/` |
| Waybar | `config/waybar/config.jsonc`, `style.css` | `~/.config/waybar/` |
| SwayNC (inactive fallback) | `config/swaync/config.json`, `style.css` | `~/.config/swaync/` |
| fish | `config/fish/config.fish` | `~/.config/fish/config.fish` |
| rofi, kitty | `config/rofi/dark-fantasy.rasi`, `config/kitty/kitty.conf`, `panel.conf` | `~/.config/rofi/`, `~/.config/kitty/` |
| yazi, btop | `config/yazi/theme.toml`, `config/btop/btop.conf`, `themes/dark-fantasy.theme` | `~/.config/yazi/`, `~/.config/btop/` |
| GTK | `config/gtk-3.0/` and `config/gtk-4.0/` `settings.ini`, `gtk.css` | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` |
| Portals | `config/xdg-desktop-portal/hyprland-portals.conf` | `~/.config/xdg-desktop-portal/` |
| Quickshell | the whole `config/quickshell/dark-fantasy/` directory | `~/.config/quickshell/dark-fantasy` |
| Helper scripts | `local/bin/*` | `~/.local/bin/` |
| Notification daemon | `local/share/dbus-1/services/org.freedesktop.Notifications.service` | `~/.local/share/dbus-1/services/` |
| Tile icons | `assets/ikony-menu/256/` (generated) | `~/.local/share/dark-fantasy/ikony-menu` |
| Default wallpaper | `assets/wallpaper.png` | `~/.local/share/dark-fantasy/wallpaper.png` |

`~/.local/share` above means `$XDG_DATA_HOME` when that variable is set.

The installer records a SHA-256 checksum of every file it installs in `~/.local/state/dark-fantasy/instalacja.sha256`. On each run it compares, for every file, the repo version, the system version and the checksum from the last install, and does one of these:

| Situation | What happens |
|---|---|
| The system file is identical to the repo | nothing |
| The system file is missing | the repo version is copied |
| The system file is unchanged since the last install | it is overwritten with the repo version (an update) |
| You changed the system file, and the repo file is unchanged since the last install | your local change is **kept** |
| Both changed, or there is no record yet (first install) | the system file is moved to `<file>.bak-YYYYMMDD-HHMMSS`, then the repo version is copied |

Symlinks left by older versions of the installer are replaced by copies automatically. Directories (Quickshell and the tile icons) are copied file by file. A file that disappeared from the repo is deleted from the system copy if you have not modified it; otherwise it is kept and the installer prints a warning.

It also does two more things:

- **Tile icons.** With `--apply` it runs `tools/skaluj-ikony-menu.py`, which needs `python3` with Pillow, to make 256 px copies of the originals in `assets/ikony-menu/`. If an original is missing, that tile shows a dark square with its name, and the installer prints a warning.
- **Wallpaper folder.** Cogwheel lists images from `<XDG Pictures>/Wallpapers`, or from an existing `<XDG Pictures>/Tapety`. If that folder has no images, `--apply` copies `assets/wallpaper.png` into it, so the list is not empty on a fresh install.

`kde-gtk-config`, the Plasma GTK settings module, can overwrite `gtk.css` when you change the theme in Plasma. For `install.sh` that is just a local change, so it keeps it unless the repo's `gtk.css` changed too. To force the repo palette back, delete `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`, then run `./install.sh --apply`.

## After installation

`install.sh --apply` finishes by printing these manual steps:

1. **Portage files**, unless `bootstrap.sh` already copied them (see Option B).
2. **Login screen** (optional): `cd sddm && ./install-theme.sh --apply`.
3. **Battery charge limit without a password prompt**, on laptops with charge thresholds: see [the udev rule](#battery-charge-limit-udev-rule).
4. **CPU power limit per profile** (optional, AMD Ryzen laptops): see [CPU power limit](#cpu-power-limit-ryzenadj).
5. **Backlight and Num Lock before login** (OpenRC): see [the service](#state-before-login-openrc-service).
6. **Reload**: `hyprctl reload`, or start Hyprland (from a TTY: `Hyprland`).

`bootstrap.sh` adds one more: **Bluetooth**. The bar shows Bluetooth as off until the service runs.

```sh
sudo rc-service bluetooth start && sudo rc-update add bluetooth default   # OpenRC
sudo systemctl enable --now bluetooth                                     # systemd
```

Everything else, including the wallpaper, gaps, animations and keyboard layout, is set in the Cogwheel (`SUPER + U`). See [cogwheel.md](cogwheel.md).

## Login screen (SDDM)

`sddm/dark-fantasy/` holds an original SDDM theme in the same palette. It has a blurred wallpaper with grain, a large clock, a password field for the last user (no user list), a session picker and a motto at the bottom. Its labels use EB Garamond, so install `media-fonts/eb-garamond` before the theme.

```sh
cd sddm
./install-theme.sh                                    # show the plan
./install-theme.sh --apply                            # install and set as default
./install-theme.sh --apply --wallpaper /path/to/image.png --lang pl
```

| Option | Meaning |
|---|---|
| `--apply` | Really install (uses `sudo`) |
| `--wallpaper FILE` | Login wallpaper. Default: the `path` from `~/.config/hypr/hyprpaper.conf`, then `assets/wallpaper.png` |
| `--lang en\|pl` | Login screen language. Default: the language chosen in Cogwheel → Language, otherwise `en` |
| `-h`, `--help` | Show help |

Preview the theme without logging out:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/dark-fantasy
```

Things worth knowing:

- **SDDM is not hyprlock.** hyprlock is the *lock* screen inside your session (hyprlang config). SDDM is the *login* screen before the session (QML / Qt 6). They look alike but share no code.
- **The wallpaper is copied into the theme directory.** The greeter runs as the `sddm` user and cannot read your home directory; a path in `~/` would give a black background without any error.
- **The config file is named `zz-dark-fantasy.conf` on purpose.** SDDM reads `/etc/sddm.conf.d/*.conf` alphabetically, and a **later file overrides an earlier one** (`src/common/ConfigReader.cpp`). This is the opposite of systemd. The `zz-` prefix sorts after `kde_settings.conf`, which Plasma's SDDM module manages and which sets `breeze`. The installer also removes an older, ineffective `10-dark-fantasy.conf`, and checks at the end which theme actually wins.
- **A value with a comma in `theme.conf` must be quoted.** SDDM reads the file through QSettings, which turns an unquoted comma into a list.
- **On Gentoo with OpenRC the service is `display-manager`, not `sddm`.** Its configuration is in `/etc/conf.d/display-manager`. Restart it with `sudo rc-service display-manager restart`, which **closes the current graphical session**.

## Battery charge limit (udev rule)

Cogwheel → System → Power can stop charging at a chosen level. The kernel exposes this as `charge_control_end_threshold` and `charge_control_start_threshold`, and those files belong to root. Without the rule, every change asks for the administrator password through `pkexec`. The rule gives the `wheel` group write access:

```sh
sudo mkdir -p /etc/udev/rules.d      # may not exist: Gentoo keeps package rules in /lib/udev/rules.d
sudo cp udev/99-dark-fantasy-bateria.rules /etc/udev/rules.d/
sudo udevadm trigger --subsystem-match=power_supply --action=change
```

`bootstrap.sh` installs the rule automatically when `/sys/class/power_supply/BAT*/charge_control_end_threshold` exists. For more on the charge limit, see [cogwheel.md](cogwheel.md#power-profile-and-charge-limit).

## State before login (OpenRC service)

`pamiec-ustawien` remembers the screen and keyboard backlight, volume, mute and Num Lock, but it runs from the Hyprland autostart, so the state comes back only after you log in. Before that the screen starts at full brightness and the SDDM greeter starts with Num Lock off.

`openrc/dark-fantasy-stan` fills that gap. At boot, before the display manager, it reads the most recently modified `/home/*/.local/state/dark-fantasy/ustawienia-sprzetu` (the file `pamiec-ustawien` keeps up to date). Then it sets the screen and keyboard backlight and writes `Numlock=on|off` to `/etc/sddm.conf.d/zz-dark-fantasy-numlock.conf`. It checks every value from that user file before writing it as root. To use a different file, set `DF_STAN_PLIK=/path` in `/etc/conf.d/dark-fantasy-stan`.

```sh
sudo install -o root -g root -m 0755 openrc/dark-fantasy-stan /etc/init.d/
sudo rc-update add dark-fantasy-stan default
```

`bootstrap.sh` does this on OpenRC. On systemd, `systemd-backlight` already restores the screen backlight.

## CPU power limit (ryzenadj)

Cogwheel → System → Power can set a hard CPU power limit for each power profile, for example 7 W in power saver and 15 W in balanced. It works on AMD Ryzen laptops through [ryzenadj](https://github.com/FlyGoat/RyzenAdj). The shell calls the root-owned `/usr/local/sbin/df-limit-mocy`, which calls ryzenadj. Until all three steps are done, the rows stay hidden. Neither `install.sh` nor `bootstrap.sh` does them.

**1. ryzenadj.** It is not in the Gentoo tree or GURU. Build it from source (needs `sys-apps/pciutils`):

```sh
git clone https://github.com/FlyGoat/RyzenAdj.git && cd RyzenAdj
mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make
sudo install -o root -g root -m 0755 ryzenadj /usr/local/bin/
```

**2. The script and the sudo rule.** The rule lets the `wheel` group run that one script without a password and without a log line each time (the shell re-checks the limit once a minute). Run from the repository:

```sh
sudo install -o root -g root -m 0755 sbin/df-limit-mocy /usr/local/sbin/
sudo install -d -o root -g root -m 0750 /etc/sudoers.d     # may not exist on Gentoo
sudo visudo -cf sudoers/dark-fantasy-moc && sudo install -o root -g root -m 0440 sudoers/dark-fantasy-moc /etc/sudoers.d/
sudo grep -n includedir /etc/sudoers                         # must print @includedir /etc/sudoers.d
```

If the last command prints nothing, add `@includedir /etc/sudoers.d` at the end of `/etc/sudoers` with `sudo visudo`. Never copy a file into `/etc/sudoers.d` without `visudo -c` first: a broken one locks sudo out.

**3. `iomem=relaxed`.** ryzenadj reaches the CPU through `/dev/mem`, which the kernel blocks with `CONFIG_STRICT_DEVMEM=y`, as in the Gentoo dist kernel. The parameter relaxes that block, which slightly weakens the protection of hardware memory from root. With GRUB (if `/etc/default/grub` already has an active `GRUB_CMDLINE_LINUX_DEFAULT`, add the parameter to it instead):

```sh
echo 'GRUB_CMDLINE_LINUX_DEFAULT="iomem=relaxed"' | sudo tee -a /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

After a reboot, `sudo df-limit-mocy` should print six numbers: the current limits and the factory ones, in watts. More in [cogwheel.md](cogwheel.md#cpu-power-limit).

## Backup and restore

### The repository is the backup

After `install.sh --apply` the files in `~/.config` are copies, not links. Editing them does not show up in `git status`, and editing the repo does not change the desktop until you run `./install.sh --apply`. The repository is still the backup, but a change made on the system has to be carried back into it by hand:

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/hyprland-dark-fantasy
cp ~/.config/hypr/hyprland.lua ~/hyprland-dark-fantasy/config/hypr/hyprland.lua
cd ~/hyprland-dark-fantasy
git add -A && git commit -m "describe the change" && git push
```

It is simpler to edit in the clone in the first place, commit, and run `./install.sh --apply`.

### What `install.sh` does not cover

These live in system directories and need root. If you change them, copy them back into the repo yourself.

| File | Installed by |
|---|---|
| `/etc/portage/package.accept_keywords/hyprland-desktop`, `/etc/portage/package.use/hyprland-desktop` | `bootstrap.sh` or by hand |
| `/usr/share/sddm/themes/dark-fantasy/` | `sddm/install-theme.sh` |
| `/etc/udev/rules.d/99-dark-fantasy-bateria.rules` | `bootstrap.sh` or by hand |
| `/etc/init.d/dark-fantasy-stan` (writes `/etc/sddm.conf.d/zz-dark-fantasy-numlock.conf` at boot) | `bootstrap.sh` or by hand, see [State before login](#state-before-login-openrc-service) |
| `/usr/local/sbin/df-limit-mocy`, `/etc/sudoers.d/dark-fantasy-moc`, `/usr/local/bin/ryzenadj`, `iomem=relaxed` in `/etc/default/grub` | By hand, see [CPU power limit](#cpu-power-limit-ryzenadj) |

Some state is deliberately **outside** the repository, because it belongs to one computer and is not part of the desktop configuration:

- `~/.config/hypr/ustawienia.lua`: Hyprland settings from the Cogwheel (also listed in `.gitignore`),
- `~/.local/state/dark-fantasy/powloka.json`: shell settings (language, HUD bars, charge limit, CPU power limits).

**The wallpaper is local too.** Choosing a wallpaper in the Cogwheel rewrites `path` in `~/.config/hypr/hyprpaper.conf` and `$tapeta` in `~/.config/hypr/hyprlock.conf`. Those are copies, so the change is local: it does not show up in `git status`, and `install.sh --apply` keeps it unless the repo's version of either file changed since the last install (then your version goes to a `.bak-*` backup and you pick the wallpaper again). Copy these files into the repo only if the image path also exists on your other machines.

> [!NOTE]
> A `<file>.bak-YYYYMMDD-HHMMSS` next to a config file is a version that `install.sh` moved aside because both it and the repo file had changed (or it was the first install). Compare it with the new file, carry over what you need, then delete it. See [troubleshooting.md](troubleshooting.md#bak-files-next-to-the-config).

### Restoring after a system reinstall

On a fresh Gentoo with network access and `git`:

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/hyprland-dark-fantasy
cd ~/hyprland-dark-fantasy
./bootstrap.sh              # plan
./bootstrap.sh --apply      # overlays, packages, configuration, udev rule
cd sddm && ./install-theme.sh --apply && cd ..            # optional
sudo rc-service bluetooth start && sudo rc-update add bluetooth default
```

After you log in to Hyprland, everything starts from the autostart in `hyprland.lua`.

**The repository cannot restore** passwords and keys, application data (browser bookmarks, player sessions), Cogwheel settings, or packages outside the list above.
