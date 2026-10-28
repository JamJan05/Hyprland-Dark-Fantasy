# Hyprland Dark Fantasy - Portage overlay

[Polski](#po-polsku) · [desktop repository (`main`)](https://github.com/JamJan05/Hyprland-Dark-Fantasy)

This branch is a Portage overlay with one package, **`x11-themes/dark-fantasy`**, a live ebuild that installs the [Hyprland Dark Fantasy](https://github.com/JamJan05/Hyprland-Dark-Fantasy) desktop on Gentoo. It contains only the overlay files (`profiles/`, `metadata/`, `x11-themes/`); the desktop itself lives on `main` and the ebuild fetches it from there.

What the package does:

- pulls in the whole dependency list (Hyprland, Waybar with the right USE flags, Quickshell, hyprlock, kitty, fonts, themes…);
- puts the desktop files in `/usr/share/dark-fantasy`;
- installs the root-side parts that `install.sh` otherwise only prints: the udev rule for the battery charge limit, the sudo rule and `/usr/sbin/df-limit-mocy` for the CPU power limit, the OpenRC service `dark-fantasy-stan`, and with USE `sddm` the login theme set as the default (`l10n_pl` makes the login screen Polish);
- adds `dark-fantasy-install`, which copies the desktop into **your** home. Portage cannot write there, so this step stays yours.

## Install

```sh
# 1. The overlay - from this branch, not from main.
sudo tee /etc/portage/repos.conf/dark-fantasy.conf >/dev/null <<'EOF'
[dark-fantasy]
location = /var/db/repos/dark-fantasy
sync-type = git
sync-uri = https://github.com/JamJan05/Hyprland-Dark-Fantasy.git
sync-git-clone-extra-opts = --branch overlay --single-branch
EOF
sudo emaint sync -r dark-fantasy

# 2. Keywords: the package is live (**), and the Hyprland stack is ~amd64.
#    GURU and hyproverlay must be enabled, they ship Hyprland and Quickshell.
echo 'x11-themes/dark-fantasy **' | sudo tee /etc/portage/package.accept_keywords/dark-fantasy
sudo curl -fsSL -o /etc/portage/package.accept_keywords/hyprland-desktop \
  https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/gentoo/package.accept_keywords/hyprland-desktop
sudo curl -fsSL -o /etc/portage/package.use/hyprland-desktop \
  https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/gentoo/package.use/hyprland-desktop

# 3. The package.
sudo emerge --ask --verbose x11-themes/dark-fantasy

# 4. Your home - as yourself, not root.
dark-fantasy-install            # dry run: shows the plan, changes nothing
dark-fantasy-install --apply    # copies into ~/.config, keeps your local edits
hyprctl reload                  # or log in again
```

## Updating

A live ebuild is not rebuilt by a plain `emerge --update`. To get the newest desktop:

```sh
sudo emaint sync -r dark-fantasy
sudo emerge @live-rebuild        # or: smart-live-rebuild
dark-fantasy-install --apply     # refresh ~/.config
```

`dark-fantasy-install` is `install.sh` from `main` run from `/usr/share/dark-fantasy`, with the same checksum manifest: files you changed in `~/.config` are kept, files changed upstream are replaced and the old copy goes to `.bak-<date>`.

## USE flags

| Flag | Effect |
|---|---|
| `sddm` | Installs the login theme into `/usr/share/sddm/themes/dark-fantasy` and makes it the default through `/etc/sddm.conf.d/zz-dark-fantasy.conf` |
| `l10n_pl` | Login screen in Polish (`language=pl` in the theme's `theme.conf`) |

---

## Po polsku

Ta gałąź to overlay Portage z jednym pakietem, **`x11-themes/dark-fantasy`**: ebuildem live, który instaluje pulpit [Hyprland Dark Fantasy](https://github.com/JamJan05/Hyprland-Dark-Fantasy) na Gentoo. Są tu tylko pliki overlaya (`profiles/`, `metadata/`, `x11-themes/`); sam pulpit żyje na `main` i stamtąd ebuild go pobiera.

Co robi pakiet:

- ciągnie całą listę zależności (Hyprland, Waybar z właściwymi flagami USE, Quickshell, hyprlock, kitty, czcionki, motywy…);
- kładzie pliki pulpitu w `/usr/share/dark-fantasy`;
- instaluje części wymagające roota, które `install.sh` tylko wypisuje: regułę udev do limitu ładowania baterii, regułę sudo i `/usr/sbin/df-limit-mocy` do limitu mocy procesora, usługę OpenRC `dark-fantasy-stan`, a z flagą USE `sddm` motyw logowania ustawiony jako domyślny (`l10n_pl` daje polski ekran logowania);
- dodaje `dark-fantasy-install`, które kopiuje pulpit do **Twojego** katalogu domowego. Portage nie może tam pisać, więc ten krok zostaje po Twojej stronie.

### Instalacja

```sh
# 1. Overlay - z tej gałęzi, nie z main.
sudo tee /etc/portage/repos.conf/dark-fantasy.conf >/dev/null <<'EOF'
[dark-fantasy]
location = /var/db/repos/dark-fantasy
sync-type = git
sync-uri = https://github.com/JamJan05/Hyprland-Dark-Fantasy.git
sync-git-clone-extra-opts = --branch overlay --single-branch
EOF
sudo emaint sync -r dark-fantasy

# 2. Słowa kluczowe: pakiet jest live (**), a stos Hyprlanda jest ~amd64.
#    Overlaye GURU i hyproverlay muszą być włączone, to one mają Hyprlanda i Quickshella.
echo 'x11-themes/dark-fantasy **' | sudo tee /etc/portage/package.accept_keywords/dark-fantasy
sudo curl -fsSL -o /etc/portage/package.accept_keywords/hyprland-desktop \
  https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/gentoo/package.accept_keywords/hyprland-desktop
sudo curl -fsSL -o /etc/portage/package.use/hyprland-desktop \
  https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/gentoo/package.use/hyprland-desktop

# 3. Pakiet.
sudo emerge --ask --verbose x11-themes/dark-fantasy

# 4. Katalog domowy - jako Ty, nie root.
dark-fantasy-install            # próba na sucho: pokazuje plan, niczego nie zmienia
dark-fantasy-install --apply    # kopiuje do ~/.config, zachowuje Twoje lokalne zmiany
hyprctl reload                  # albo zaloguj się ponownie
```

### Aktualizacja

Ebuildu live zwykłe `emerge --update` nie przebudowuje. Najnowszy pulpit:

```sh
sudo emaint sync -r dark-fantasy
sudo emerge @live-rebuild        # albo: smart-live-rebuild
dark-fantasy-install --apply     # odświeża ~/.config
```

`dark-fantasy-install` to `install.sh` z `main` uruchomiony z `/usr/share/dark-fantasy`, z tym samym manifestem sum kontrolnych: pliki zmienione przez Ciebie w `~/.config` zostają, pliki zmienione w repozytorium są podmieniane, a stara kopia trafia do `.bak-<data>`.

### Flagi USE

| Flaga | Efekt |
|---|---|
| `sddm` | Instaluje motyw logowania do `/usr/share/sddm/themes/dark-fantasy` i ustawia go jako domyślny przez `/etc/sddm.conf.d/zz-dark-fantasy.conf` |
| `l10n_pl` | Polski ekran logowania (`language=pl` w `theme.conf` motywu) |
