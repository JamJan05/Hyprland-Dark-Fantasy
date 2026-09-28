# Sprzęt i przenośność

[← README](../../README.pl.md) · [English](../hardware.md)

## Środowisko, na którym to powstało

- Gentoo, profil `default/linux/amd64/23.0/desktop/plasma`, **OpenRC + elogind**
- Hyprland 0.56.2 (`LUA_SINGLE_TARGET=lua5-4`), uruchamiany z TTY, bez uwsm
- Quickshell 0.3.1, Waybar 0.15.0, hyprlock 0.9.6, hyprpaper 0.8.4, libwayland 1.26.0
- Lenovo ThinkPad E16 Gen 3 (AMD), wbudowany ekran `eDP-1` 1920×1200@60, skala 1
- Układ klawiatury `pl`

## Elementy zależne od Gentoo i OpenRC

Konfiguracja jest przygotowana pod Gentoo i była używana tylko tam. Te miejsca zakładają Gentoo albo OpenRC + elogind:

| Miejsce | Założenie | Na innym systemie |
|---|---|---|
| `bootstrap.sh`, `gentoo/` | Portage, `eselect repository`, overlaye GURU i hyproverlay | Pakiety zainstaluj sam; te skrypty nie zadziałają |
| `config/hypr/hypridle.conf`, `config/quickshell/dark-fantasy/services/Sesja.qml` | `loginctl suspend / reboot / poweroff / lock-session` z elogind | `bootstrap.sh` ostrzega, że na systemd te wywołania trzeba podmienić na `systemctl` |
| Autostart w `config/hypr/hyprland.lua` | `gentoo-pipewire-launcher restart` uruchamia PipeWire, pipewire-pulse i WirePlumber, bo OpenRC ich nie startuje | Zastąp tym, czym Twój system uruchamia PipeWire |
| Autostart w `config/hypr/hyprland.lua` | Agent polkit w `/usr/libexec/hyprpolkitagent` | Popraw ścieżkę, jeśli dystrybucja instaluje go gdzie indziej |
| Podpowiedzi `sddm/install-theme.sh` | Usługa menedżera wyświetlania na OpenRC to `display-manager` | Na systemd `systemctl restart display-manager` |
| `udev/99-dark-fantasy-bateria.rules` | Administratorzy są w grupie `wheel`; `/etc/udev/rules.d` może nie istnieć | W razie potrzeby zmień grupę |
| `sudoers/dark-fantasy-moc`, konfiguracja limitu mocy | Grupa `wheel`; `/etc/sudoers.d` może nie istnieć; `iomem=relaxed` dodawany przez GRUB-a | Zmień grupę; dodaj parametr jądra tak, jak robi to Twój bootloader |

## Elementy zależne od sprzętu

| Miejsce | Wartość | Co zrobić na innym sprzęcie |
|---|---|---|
| `config/hypr/hyprland.lua` | `kb_layout = "pl"`, skala monitora `scale = "1"` | Zmień w Zębatce (Wejście, Ekran) albo w pliku |
| `config/hypr/hyprlock.conf` | Pozycje zegara, pola hasła i motta | Przesunięcia w pikselach od środka ekranu |
| `sddm/dark-fantasy/Main.qml` | `width: 1920`, `height: 1200` | To tylko rozmiar zastępczy do podglądu; greeter skaluje się do ekranu sam |
| `local/bin/waybar-temperatura` | `k10temp` (AMD) | Ma awaryjne przejście na `acpitz`; na Intelu warto dopisać `coretemp` |
| HUD, pasek HP (`services/Battery.qml`) | Zakłada obecność baterii | Bez baterii HP to pełny pasek o stałej długości (`Theme.hudHpBezBaterii`) |
| Zębatka → Zasilanie | Wymaga `sys-power/power-profiles-daemon` | Profil „wydajność” pojawia się tylko, gdy sprzęt go zgłasza |
| Zębatka → Zasilanie, limit ładowania | Pliki `charge_control_*` baterii (ThinkPad: `thinkpad_acpi`) | Bez nich rzędy limitu się nie pokazują |
| Zębatka → Zasilanie, limit mocy procesora | Mobilny AMD Ryzen obsługiwany przez ryzenadj; suwak do 40 W, czyli chwilowego limitu profilu wydajności ThinkPada (Ryzen 7 250) | Bez konfiguracji roota rzędy się nie pokazują; dla innego procesora zmień `maksimum` w `services/LimitMocy.qml` |
| Zębatka → Hyprland → Ekran | Skale i odświeżanie | Liczone z `hyprctl monitors` dla bieżącej rozdzielczości; nic nie trzeba zmieniać |
| Zębatka → Wejście, czułość touchpada | Reguła urządzenia dla touchpada z `hyprctl devices` | Bez touchpada rząd jest przygaszony |

Celowo **nie ma** tu wpisanego na sztywno urządzenia podświetlenia, nazwy monitora ani nazwy touchpada. Powłoka, Waybar i hyprpaper wykrywają je same.
