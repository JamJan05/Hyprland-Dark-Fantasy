# Instalacja

[← README](../../README.pl.md) · [English](../installation.md)

Pulpit instalują trzy skrypty. Każdy z nich **pokazuje plan i niczego nie zmienia**, dopóki nie dodasz `--apply`.

| Skrypt | Co robi | Root |
|---|---|---|
| [`install.sh`](../../install.sh) | Kopiuje `config/` i resztę do `~/.config` i `~/.local` | nie |
| [`bootstrap.sh`](../../bootstrap.sh) | Instalacja Gentoo od zera: overlaye, pliki Portage, pakiety, klon, `install.sh --apply`, reguła udev | przez `sudo` |
| [`sddm/install-theme.sh`](../../sddm/install-theme.sh) | Instaluje motyw logowania SDDM i ustawia go jako domyślny | przez `sudo` |

## Wariant A: od zera przez `bootstrap.sh`

Najpierw sam plan:

```sh
curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh | bash
```

Potem wykonanie:

```sh
curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh | bash -s -- --apply
```

Próba na sucho jest domyślna celowo. Skrypt podany z `curl` wprost do powłoki nie powinien instalować kilkudziesięciu pakietów i przestawiać systemu, zanim zobaczysz, co zamierza zrobić.

Co robi `--apply`, po kolei:

1. Sprawdza, czy to Gentoo, czy są `emerge`, `git` i `sudo` i czy skrypt **nie** działa jako root. Rozpoznaje też OpenRC albo systemd.
2. Od razu na początku raz prosi o hasło `sudo`. Przy `curl | bash` czyta je z `/dev/tty`.
3. Włącza overlaye **GURU** i **hyproverlay** przez `eselect repository` i je synchronizuje.
4. Klonuje repozytorium do `~/Hyprland-Dark-Fantasy`. Jeśli tam jeszcze nie ma klonu, a jest w `~/hyprland-dark-fantasy` (wcześniejsza domyślna ścieżka), i nie ustawiono `HYPR_REPO_DIR`, używa tamtego. Inną ścieżkę podasz w `HYPR_REPO_DIR`. Uruchomiony z wnętrza klonu, bez ustawionego `HYPR_REPO_DIR`, używa tego klonu. Jeśli docelową ścieżkę zajmuje coś, co nie jest klonem, skrypt zatrzymuje się z komunikatem i niczego tam nie rusza.
5. Kopiuje `gentoo/package.accept_keywords/hyprland-desktop` i `gentoo/package.use/hyprland-desktop` do `/etc/portage/`, jeśli ich tam jeszcze nie ma. Jeśli Portage nadal nie widzi `dev-libs/wayland` 1.26 (starsza kopia pliku), dopisuje ten jeden wpis.
6. Podnosi `dev-libs/wayland` do 1.26 (`emerge --oneshot --update`), a potem instaluje pakiety przez `emerge --ask --verbose --changed-use`. Kompilacja Hyprlanda i zależności Qt trochę trwa.
7. Uruchamia `install.sh --apply`.
8. Wgrywa regułę udev dla baterii, ale tylko wtedy, gdy bateria ma progi ładowania.
9. Na OpenRC instaluje i włącza [usługę `dark-fantasy-stan`](#stan-przed-zalogowaniem-usługa-openrc).

Skrypt jest idempotentny: przy ponownym uruchomieniu pomija to, co już zrobione. `./bootstrap.sh --help` wypisuje to samo streszczenie. Zainstalowany pulpit nie potrzebuje klonu w `~/Hyprland-Dark-Fantasy`; możesz go potem usunąć.

Jeśli `sudo` nie może zapytać o hasło, bo nie ma terminala, pobierz skrypt na dysk i uruchom go bezpośrednio:

```sh
curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh -o bootstrap.sh
bash bootstrap.sh --apply
```

`bootstrap.sh` celowo **nie** instaluje programów użytkownika, czyli przeglądarek, komunikatorów czy gier. Uzbrojenie (Arsenal) pokazuje po prostu to, co jest zainstalowane.

## Wariant B: pakiety samodzielnie

Włącz overlaye:

```sh
sudo eselect repository enable guru
sudo eselect repository enable hyproverlay
sudo emaint sync -r guru -r hyproverlay
```

Skopiuj pliki Portage. Dodają keywordy dla pakietów `~amd64` i flagi USE, których ta konfiguracja potrzebuje:

```sh
sudo cp gentoo/package.accept_keywords/hyprland-desktop /etc/portage/package.accept_keywords/
sudo cp gentoo/package.use/hyprland-desktop             /etc/portage/package.use/
```

Hyprland 0.56 nie działa ze stabilnym `dev-libs/wayland` 1.25, a 1.26 jest wciąż `~amd64`. Powyższy plik go odmaskowuje; podnieś go najpierw, tylko jako zależność:

```sh
sudo emerge --ask --oneshot --update ">=dev-libs/wayland-1.26.0"
```

Zainstaluj tę samą listę, co tablica `PAKIETY` w `bootstrap.sh`:

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

Uwagi do listy:

- **Waybar** potrzebuje USE `backlight network wifi mpris tray pipewire pulseaudio upower`. Bez `wifi` moduł sieci nie pokaże SSID ani siły sygnału.
- **Quickshell** zostaje na domyślnych flagach USE. Jego obsługa awarii ciągnie `dev-cpp/cpptrace`, któremu potrzebne jest USE `unwind` (ustawione w `gentoo/package.use`).
- **Pakiety wyglądu**: `eb-garamond` to krój napisów, `adw-gtk3` motyw GTK, `papirus-icon-theme` ikony w GTK i w Uzbrojeniu, a `bibata-xcursors` kursor. `btop` obsługuje kafel Status. `pillow` przetwarza okładkę na pasku, ikony kafli i tekstury. `adw-gtk3` i `bibata-xcursors` pochodzą z GURU.
- **Bez któregoś pakietu** odpowiadający mu element wraca do domyślnego wyglądu albo pokazuje stan „niedostępne”; pulpit i tak wstaje.
- **SDDM** i **fish** nie są na liście. Motyw SDDM i `config/fish/config.fish` są opcjonalne.

Potem zainstaluj konfigurację:

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/Hyprland-Dark-Fantasy
cd ~/Hyprland-Dark-Fantasy
./install.sh
./install.sh --apply
```

## Co kopiuje `install.sh`

Każdy wpis jest **kopiowany** z repozytorium; instalator nie tworzy dowiązań symbolicznych. Po `--apply` katalog z repozytorium można usunąć. Żeby coś później zmienić, sklonuj repo ponownie, wprowadź zmianę, uruchom `./install.sh --apply` i znowu usuń katalog.

| Obszar | Źródło w repo | Cel |
|---|---|---|
| Hyprland | `config/hypr/hyprland.lua`, `floors.lua`, `hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf` | `~/.config/hypr/` |
| Waybar | `config/waybar/config.jsonc`, `style.css` | `~/.config/waybar/` |
| SwayNC (nieaktywny, droga odwrotu) | `config/swaync/config.json`, `style.css` | `~/.config/swaync/` |
| fish | `config/fish/config.fish` | `~/.config/fish/config.fish` |
| rofi, kitty | `config/rofi/dark-fantasy.rasi`, `config/kitty/kitty.conf`, `panel.conf` | `~/.config/rofi/`, `~/.config/kitty/` |
| yazi, btop | `config/yazi/theme.toml`, `config/btop/btop.conf`, `themes/dark-fantasy.theme` | `~/.config/yazi/`, `~/.config/btop/` |
| GTK | `settings.ini` i `gtk.css` z `config/gtk-3.0/` i `config/gtk-4.0/` | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` |
| Portale | `config/xdg-desktop-portal/hyprland-portals.conf` | `~/.config/xdg-desktop-portal/` |
| Quickshell | cały katalog `config/quickshell/dark-fantasy/` | `~/.config/quickshell/dark-fantasy` |
| Skrypty | `local/bin/*` | `~/.local/bin/` |
| Demon powiadomień | `local/share/dbus-1/services/org.freedesktop.Notifications.service` | `~/.local/share/dbus-1/services/` |
| Ikony kafli | `assets/ikony-menu/256/` (generowane) | `~/.local/share/dark-fantasy/ikony-menu` |
| Domyślna tapeta | `assets/wallpaper.png` | `~/.local/share/dark-fantasy/wallpaper.png` |

`~/.local/share` oznacza `$XDG_DATA_HOME`, jeśli ta zmienna jest ustawiona.

Instalator zapisuje sumę kontrolną SHA-256 każdego zainstalowanego pliku w `~/.local/state/dark-fantasy/instalacja.sha256`. Przy każdym uruchomieniu porównuje dla każdego pliku wersję w repo, wersję w systemie i sumę z ostatniej instalacji, po czym robi jedno z poniższych:

| Sytuacja | Co się dzieje |
|---|---|
| Plik w systemie jest identyczny z repo | nic |
| Pliku w systemie nie ma | wersja z repo jest kopiowana |
| Plik w systemie nie zmienił się od ostatniej instalacji | zostaje nadpisany wersją z repo (aktualizacja) |
| Plik w systemie zmieniłeś, a plik w repo nie zmienił się od ostatniej instalacji | Twoja lokalna zmiana **zostaje** |
| Zmieniły się oba albo nie ma jeszcze zapisu (pierwsza instalacja) | plik z systemu trafia do `<plik>.bak-RRRRMMDD-GGMMSS`, a potem kopiowana jest wersja z repo |

Dowiązania zostawione przez starsze wersje instalatora są automatycznie zastępowane kopiami. Katalogi (Quickshell i ikony kafli) są kopiowane plik po pliku. Plik, który zniknął z repo, jest usuwany z kopii w systemie, jeśli go nie zmieniałeś; w przeciwnym razie zostaje, a instalator wypisuje ostrzeżenie.

Instalator robi jeszcze dwie rzeczy:

- **Ikony kafli.** Przy `--apply` uruchamia `tools/skaluj-ikony-menu.py` (potrzebny `python3` z Pillow), który robi kopie 256 px z oryginałów w `assets/ikony-menu/`. Jeśli brakuje oryginału, kafel pokazuje ciemny kwadrat z nazwą, a instalator wypisuje ostrzeżenie.
- **Katalog tapet.** Zębatka (Cogwheel) listuje obrazy z `<XDG Pictures>/Wallpapers` albo z istniejącego `<XDG Pictures>/Tapety`. Jeśli w tym katalogu nie ma obrazów, `--apply` kopiuje do niego `assets/wallpaper.png`, żeby lista nie była pusta na świeżej instalacji.

`kde-gtk-config`, moduł ustawień GTK z Plasmy, potrafi przy zmianie motywu w Plasmie nadpisać `gtk.css`. Dla `install.sh` to zwykła lokalna zmiana, więc ją zachowa, chyba że w repo zmienił się też `gtk.css`. Żeby wymusić z powrotem paletę z repo, usuń `~/.config/gtk-3.0/gtk.css` i `~/.config/gtk-4.0/gtk.css`, a potem uruchom `./install.sh --apply`.

## Po instalacji

`install.sh --apply` kończy się listą ręcznych kroków:

1. **Pliki Portage**, jeśli nie skopiował ich już `bootstrap.sh` (patrz wariant B).
2. **Ekran logowania** (opcjonalnie): `cd sddm && ./install-theme.sh --apply`.
3. **Limit ładowania baterii bez pytania o hasło**, na laptopach z progami ładowania: patrz [reguła udev](#limit-ładowania-baterii-reguła-udev).
4. **Limit mocy procesora dla profili** (opcjonalnie, laptopy z AMD Ryzen): patrz [limit mocy procesora](#limit-mocy-procesora-ryzenadj).
5. **Jasność i Num Lock przed zalogowaniem** (OpenRC): patrz [usługa](#stan-przed-zalogowaniem-usługa-openrc).
6. **Przeładowanie**: `hyprctl reload` albo uruchomienie Hyprlanda (z TTY: `Hyprland`).

`bootstrap.sh` dokłada jeszcze jeden: **Bluetooth**. Pasek pokazuje Bluetooth jako wyłączony, dopóki usługa nie działa.

```sh
sudo rc-service bluetooth start && sudo rc-update add bluetooth default   # OpenRC
sudo systemctl enable --now bluetooth                                     # systemd
```

Resztę, w tym tapetę, odstępy, animacje i układ klawiatury, ustawisz w Zębatce (`SUPER + U`). Patrz [cogwheel.md](cogwheel.md).

## Ekran logowania (SDDM)

W `sddm/dark-fantasy/` leży autorski motyw SDDM w tej samej palecie. Ma rozmytą tapetę z ziarnem, duży zegar, pole hasła dla ostatniego użytkownika (bez listy użytkowników), wybór sesji i motto na dole. Napisy są w EB Garamond, więc motyw instaluj po `media-fonts/eb-garamond`.

```sh
cd sddm
./install-theme.sh                                    # plan
./install-theme.sh --apply                            # instalacja i ustawienie jako domyślny
./install-theme.sh --apply --wallpaper /ścieżka/obraz.png --lang pl
```

| Opcja | Znaczenie |
|---|---|
| `--apply` | Naprawdę instaluje (używa `sudo`) |
| `--wallpaper PLIK` | Tapeta logowania. Domyślnie: `path` z `~/.config/hypr/hyprpaper.conf`, potem `assets/wallpaper.png` |
| `--lang en\|pl` | Język ekranu logowania. Domyślnie: język wybrany w Zębatce → Język, a bez niego `en` |
| `-h`, `--help` | Pomoc |

Podgląd bez wylogowywania:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/dark-fantasy
```

Co warto wiedzieć:

- **SDDM to nie hyprlock.** hyprlock to ekran *blokady* w Twojej sesji (konfiguracja w hyprlangu). SDDM to ekran *logowania* przed sesją (QML / Qt 6). Wyglądają podobnie, ale nie dzielą kodu.
- **Tapeta jest kopiowana do katalogu motywu.** Greeter działa jako użytkownik `sddm` i nie widzi Twojego katalogu domowego; ścieżka w `~/` dałaby czarne tło bez żadnego komunikatu.
- **Plik konfiguracyjny nazywa się `zz-dark-fantasy.conf` celowo.** SDDM czyta `/etc/sddm.conf.d/*.conf` alfabetycznie, a **późniejszy plik nadpisuje wcześniejszy** (`src/common/ConfigReader.cpp`), odwrotnie niż w systemd. Przedrostek `zz-` sortuje się po `kde_settings.conf`, którym zarządza moduł SDDM w Plasmie i który ustawia `breeze`. Instalator usuwa też stary, nieskuteczny `10-dark-fantasy.conf` i na końcu sprawdza, który motyw faktycznie wygrywa.
- **Wartość z przecinkiem w `theme.conf` musi być w cudzysłowie.** SDDM czyta plik przez QSettings, które z wartości z przecinkiem bez cudzysłowu robi listę.
- **Na Gentoo z OpenRC usługa nazywa się `display-manager`, nie `sddm`.** Konfiguracja jest w `/etc/conf.d/display-manager`. Restart to `sudo rc-service display-manager restart`, który **zamyka bieżącą sesję graficzną**.

## Limit ładowania baterii (reguła udev)

Zębatka → System → Zasilanie potrafi zatrzymać ładowanie na wybranym poziomie. Jądro wystawia to jako `charge_control_end_threshold` i `charge_control_start_threshold`, a te pliki należą do roota. Bez reguły każda zmiana pyta o hasło administratora przez `pkexec`. Reguła daje grupie `wheel` prawo zapisu:

```sh
sudo mkdir -p /etc/udev/rules.d      # może nie istnieć: Gentoo trzyma reguły pakietów w /lib/udev/rules.d
sudo cp udev/99-dark-fantasy-bateria.rules /etc/udev/rules.d/
sudo udevadm trigger --subsystem-match=power_supply --action=change
```

`bootstrap.sh` wgrywa regułę sam, jeśli istnieje `/sys/class/power_supply/BAT*/charge_control_end_threshold`. Więcej o limicie ładowania w [cogwheel.md](cogwheel.md#profil-zasilania-i-limit-ładowania).

## Stan przed zalogowaniem (usługa OpenRC)

`pamiec-ustawien` pamięta jasność ekranu i podświetlenie klawiatury, głośność, wyciszenie i Num Lock, ale działa z autostartu Hyprlanda, więc stan wraca dopiero po zalogowaniu. Wcześniej ekran startuje z pełną jasnością, a ekran logowania SDDM z wyłączonym Num Lockiem.

`openrc/dark-fantasy-stan` zamyka tę lukę. Przy starcie systemu, przed menedżerem logowania, czyta najświeższy plik `/home/*/.local/state/dark-fantasy/ustawienia-sprzetu` (ten, który na bieżąco zapisuje `pamiec-ustawien`). Potem ustawia jasność ekranu i klawiatury oraz zapisuje `Numlock=on|off` w `/etc/sddm.conf.d/zz-dark-fantasy-numlock.conf`. Każdą wartość z pliku użytkownika sprawdza, zanim zapisze ją jako root. Inny plik wskażesz przez `DF_STAN_PLIK=/ścieżka` w `/etc/conf.d/dark-fantasy-stan`.

```sh
sudo install -o root -g root -m 0755 openrc/dark-fantasy-stan /etc/init.d/
sudo rc-update add dark-fantasy-stan default
```

`bootstrap.sh` robi to sam na OpenRC. Na systemd jasność ekranu przywraca już `systemd-backlight`.

## Limit mocy procesora (ryzenadj)

Zębatka → System → Zasilanie może ustawić twardy limit mocy procesora dla każdego profilu zasilania, np. 7 W w oszczędnym i 15 W w zrównoważonym. Działa na laptopach z AMD Ryzen przez [ryzenadj](https://github.com/FlyGoat/RyzenAdj). Powłoka woła należący do roota `/usr/local/sbin/df-limit-mocy`, a ten woła ryzenadj. Dopóki nie zrobisz wszystkich trzech kroków, rzędy się nie pokazują. Nie robi ich ani `install.sh`, ani `bootstrap.sh`.

**1. ryzenadj.** Nie ma go w drzewie Gentoo ani w GURU. Zbuduj go ze źródeł (wymaga `sys-apps/pciutils`):

```sh
git clone https://github.com/FlyGoat/RyzenAdj.git && cd RyzenAdj
mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make
sudo install -o root -g root -m 0755 ryzenadj /usr/local/bin/
```

**2. Skrypt i reguła sudo.** Reguła pozwala grupie `wheel` uruchamiać ten jeden skrypt bez hasła i bez wpisu w logu za każdym razem (powłoka sprawdza limit co minutę). Z katalogu repozytorium:

```sh
sudo install -o root -g root -m 0755 sbin/df-limit-mocy /usr/local/sbin/
sudo install -d -o root -g root -m 0750 /etc/sudoers.d     # na Gentoo może nie istnieć
sudo visudo -cf sudoers/dark-fantasy-moc && sudo install -o root -g root -m 0440 sudoers/dark-fantasy-moc /etc/sudoers.d/
sudo grep -n includedir /etc/sudoers                         # musi wypisać @includedir /etc/sudoers.d
```

Jeśli ostatnie polecenie nic nie wypisze, dopisz `@includedir /etc/sudoers.d` na końcu `/etc/sudoers` przez `sudo visudo`. Nigdy nie kopiuj pliku do `/etc/sudoers.d` bez wcześniejszego `visudo -c`: uszkodzony plik blokuje sudo.

**3. `iomem=relaxed`.** ryzenadj sięga do procesora przez `/dev/mem`, a jądro blokuje to przy `CONFIG_STRICT_DEVMEM=y`, tak jak w dystrybucyjnym jądrze Gentoo. Parametr luzuje tę blokadę, co nieco osłabia ochronę pamięci sprzętu przed rootem. Z GRUB-em (jeśli `/etc/default/grub` ma już aktywną linię `GRUB_CMDLINE_LINUX_DEFAULT`, dopisz parametr do niej):

```sh
echo 'GRUB_CMDLINE_LINUX_DEFAULT="iomem=relaxed"' | sudo tee -a /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Po restarcie `sudo df-limit-mocy` powinno wypisać sześć liczb: obecne limity i fabryczne, w watach. Więcej w [cogwheel.md](cogwheel.md#limit-mocy-procesora).

## Kopia zapasowa i przywracanie

### Repozytorium jest kopią

Po `install.sh --apply` pliki w `~/.config` są kopiami, nie dowiązaniami. Ich edycja nie pojawia się w `git status`, a edycja w repo nie zmienia pulpitu, dopóki nie uruchomisz `./install.sh --apply`. Repozytorium nadal jest kopią zapasową, ale zmianę zrobioną w systemie trzeba do niego przenieść ręcznie:

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/Hyprland-Dark-Fantasy
cp ~/.config/hypr/hyprland.lua ~/Hyprland-Dark-Fantasy/config/hypr/hyprland.lua
cd ~/Hyprland-Dark-Fantasy
git add -A && git commit -m "opis zmiany" && git push
```

Prościej od razu edytować w klonie, zrobić commit i uruchomić `./install.sh --apply`.

### Czego `install.sh` nie obejmuje

Te pliki leżą w katalogach systemowych i wymagają roota. Jeśli je zmienisz, skopiuj je do repo samodzielnie.

| Plik | Instaluje go |
|---|---|
| `/etc/portage/package.accept_keywords/hyprland-desktop`, `/etc/portage/package.use/hyprland-desktop` | `bootstrap.sh` albo ręcznie |
| `/usr/share/sddm/themes/dark-fantasy/` | `sddm/install-theme.sh` |
| `/etc/udev/rules.d/99-dark-fantasy-bateria.rules` | `bootstrap.sh` albo ręcznie |
| `/etc/init.d/dark-fantasy-stan` (przy starcie zapisuje `/etc/sddm.conf.d/zz-dark-fantasy-numlock.conf`) | `bootstrap.sh` albo ręcznie, patrz [stan przed zalogowaniem](#stan-przed-zalogowaniem-usługa-openrc) |
| `/usr/local/sbin/df-limit-mocy`, `/etc/sudoers.d/dark-fantasy-moc`, `/usr/local/bin/ryzenadj`, `iomem=relaxed` w `/etc/default/grub` | Ręcznie, patrz [limit mocy procesora](#limit-mocy-procesora-ryzenadj) |

Część stanu celowo zostaje **poza** repozytorium, bo dotyczy jednego komputera, a nie konfiguracji pulpitu:

- `~/.config/hypr/ustawienia.lua`: ustawienia Hyprlanda z Zębatki (wpisane też do `.gitignore`),
- `~/.config/hypr/lokalne.lua`: Twoje własne, pisane ręcznie dodatki do Hyprlanda dla tego komputera (patrz niżej),
- `~/.local/state/dark-fantasy/powloka.json`: ustawienia powłoki (język, paski HUD-u, limit ładowania, limity mocy procesora).

**Tapeta też jest lokalna.** Wybór tapety w Zębatce przepisuje `path` w `~/.config/hypr/hyprpaper.conf` i `$tapeta` w `~/.config/hypr/hyprlock.conf`. To kopie, więc zmiana jest lokalna: nie pojawia się w `git status`, a `install.sh --apply` ją zachowuje, chyba że od ostatniej instalacji zmieniła się wersja któregoś z tych plików w repo (wtedy Twoja wersja trafia do kopii `.bak-*` i tapetę wybierasz ponownie). Przenoś te pliki do repo tylko wtedy, gdy ścieżka obrazu istnieje też na Twoich innych komputerach.

> [!NOTE]
**Własne dodatki do Hyprlanda wpisuj do `~/.config/hypr/lokalne.lua`**, a nie do `hyprland.lua`. Chodzi np. o zmienną środowiskową dla jednego programu, regułę okna albo dodatkowy skrót. `hyprland.lua` wczytuje ten plik po swoich ustawieniach domyślnych, więc może je nadpisać, a przed `ustawienia.lua` z Zębatki, więc ustawienie z Zębatki nadal wygrywa. `install.sh` nigdy go nie rusza, więc przetrwa każdą ponowną instalację, a linia dopisana do samego `hyprland.lua` trafiłaby do kopii `.bak-*`. To zwykły Lua z tym samym API `hl.*`. Po edycji uruchom `hyprctl reload`. Przy ustawionej (i niepustej) zmiennej `XDG_CONFIG_HOME` plik leży w `$XDG_CONFIG_HOME/hypr/lokalne.lua`, obok `ustawienia.lua`. Jeśli plik ma błąd, Hyprland pokaże powiadomienie z jego nazwą, a reszta konfiguracji i tak się wczyta.

```lua
-- ~/.config/hypr/lokalne.lua
hl.env("JAKAS_ZMIENNA", "wartosc")
hl.window_rule({ name = "moja-regula", match = { class = "^foo$" }, float = true })
```

> Plik `<plik>.bak-RRRRMMDD-GGMMSS` obok pliku konfiguracji to wersja, którą `install.sh` odłożył na bok, bo zmieniła się i ona, i plik w repo (albo była to pierwsza instalacja). Porównaj go z nowym plikiem, przenieś, co potrzebne, i usuń. Patrz [troubleshooting.md](troubleshooting.md#pliki-bak-obok-konfiguracji).

### Przywracanie po reinstalacji systemu

Na świeżym Gentoo z siecią i `git`:

```sh
git clone https://github.com/JamJan05/Hyprland-Dark-Fantasy.git ~/Hyprland-Dark-Fantasy
cd ~/Hyprland-Dark-Fantasy
./bootstrap.sh              # plan
./bootstrap.sh --apply      # overlaye, pakiety, konfiguracja, reguła udev
cd sddm && ./install-theme.sh --apply && cd ..            # opcjonalnie
sudo rc-service bluetooth start && sudo rc-update add bluetooth default
```

Po zalogowaniu do Hyprlanda wszystko wstaje z autostartu w `hyprland.lua`.

**Repozytorium nie odtworzy** haseł i kluczy, danych aplikacji (zakładki przeglądarki, sesje odtwarzaczy), ustawień z Zębatki ani pakietów spoza powyższej listy.
