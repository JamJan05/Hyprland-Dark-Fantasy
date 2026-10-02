# Struktura repozytorium

[← README](../../README.pl.md) · [English](../repository.md)

```
config/              lustro ~/.config; install.sh kopiuje je jeden do jednego
  hypr/              kompozytor, piętra, blokada, bezczynność, tapeta
  waybar/            pasek i jego style
  quickshell/        powłoka QtQuick: HUD, rząd kafli, panele, OSD, powiadomienia
  swaync/            nieaktywny; powiadomienia obsługuje powłoka
  rofi/ kitty/ yazi/ btop/
  gtk-3.0/ gtk-4.0/  wygląd aplikacji GTK: motyw, ikony, kursor, paleta
  xdg-desktop-portal/ kolejność backendów portali
  fish/              interaktywna konfiguracja fish (fastfetch)
  fastfetch/         moduły fastfetch: domyślne, bez lokalnego IP
assets/              oryginały ikon kafli (ikony-menu/), wallpaper.png, zrzuty ekranu (zrzuty/)
local/
  bin/               skrypty wołane przez Waybara, kafle i skróty
  share/dbus-1/      wskazanie powłoki jako demona powiadomień
gentoo/              keywordy i flagi USE dla Portage
udev/                reguła: progi ładowania baterii zapisywalne dla wheel
openrc/              dark-fantasy-stan: jasność i Num Lock w SDDM przed zalogowaniem
sbin/                df-limit-mocy: limit mocy procesora przez ryzenadj (root, /usr/local/sbin)
sudoers/             reguła: df-limit-mocy bez hasła dla wheel
sddm/                motyw logowania (QML) i jego instalator
tools/               skalowanie ikon, tekstury i generatory glifów dla powłoki
install.sh           kopiuje config/ do ~/.config
bootstrap.sh         instalacja od zera: overlaye, pakiety, konfiguracja
docs/                dokumentacja (docs/pl/ po polsku)
```

Układ `config/` **celowo** odwzorowuje `~/.config`, zamiast trzymać `hypr/` i `waybar/` na najwyższym poziomie. Dzięki temu `install.sh` jest prostym mapowaniem jeden do jednego, bez wyjątków.

## Co gdzie leży

| Element | Plik |
|---|---|
| Kompozytor | `config/hypr/hyprland.lua` |
| Piętra | `config/hypr/floors.lua` |
| Ustawienia z Zębatki (generowane, poza repo) | `~/.config/hypr/ustawienia.lua` |
| Własne dodatki do Hyprlanda (poza repo) | `~/.config/hypr/lokalne.lua` |
| Ekran blokady | `config/hypr/hyprlock.conf` |
| Bezczynność, wygaszanie, uśpienie | `config/hypr/hypridle.conf` |
| Tapeta | `config/hypr/hyprpaper.conf`, `assets/wallpaper.png` |
| Pasek | `config/waybar/` |
| Punkt wejścia powłoki i IPC | `config/quickshell/dark-fantasy/shell.qml` |
| Paleta, rozmiary, kroje | `config/quickshell/dark-fantasy/Theme.qml` |
| Rząd kafli i kafle | `config/quickshell/dark-fantasy/kafle/` |
| HUD | `config/quickshell/dark-fantasy/hud/` |
| Sekcje Zębatki | `config/quickshell/dark-fantasy/system/` |
| Usługi (dźwięk, bateria, sieć, tłumaczenia…) | `config/quickshell/dark-fantasy/services/` |
| Picker schowka | `config/rofi/dark-fantasy.rasi` |
| Terminal i okno panelu Status | `config/kitty/kitty.conf`, `config/kitty/panel.conf` |
| Motywy yazi i btop | `config/yazi/`, `config/btop/` |
| Wygląd GTK | `config/gtk-3.0/`, `config/gtk-4.0/` |
| Ekran logowania | `sddm/` |

Nazwy plików i identyfikatorów w kodzie są w dużej części polskie (`kafle`, `Zebatka` = Cogwheel, `Uzbrojenie` = Arsenal, `Sakwa` = Satchel, `Wiesci` = Tidings, `Ognisko` = Bonfire, `pietra`). Komentarze w kodzie są po angielsku.

## Skrypty pomocnicze (`local/bin/`)

`install.sh` kopiuje je do `~/.local/bin/`.

| Skrypt | Wołany przez | Co robi |
|---|---|---|
| `menedzer-plikow` | `SUPER + W`, kafel Sakwa | Uruchamia yazi w kitty jako zwykłe okno układu. Istnieje, bo skróty i wpisy `.desktop` przyjmują jedno słowo. |
| `monitor-systemu` | Kafel Status | btop w oknie panelu: klasa `df-panel` (reguła w `hyprland.lua`) i osobny config kitty `panel.conf` |
| `limit-ladowania` | Zębatka → Zasilanie, terminal | Odczytuje albo ustawia progi ładowania baterii we właściwej kolejności; bez prawa zapisu woła `pkexec` |
| `pamiec-ustawien` | Autostart | Przywraca jasność ekranu i podświetlenie klawiatury, głośność i wyciszenie sprzed wyłączenia, potem co kilka sekund zapisuje je do `~/.local/state/dark-fantasy/ustawienia-sprzetu`. Num Lock z tego samego pliku czyta `hyprland.lua`. |
| `df-agent-bt` | Autostart | Agent parowania Bluetooth (NoInputNoOutput). Bez agenta BlueZ w ogóle nie paruje. Zgadza się na parowanie i usługi tylko dla urządzeń oznaczonych jako zaufane, co Zębatka robi przed parowaniem. |
| `uklad-startowy` | Autostart | Buduje układ powitalny: terminal i `tty-clock` po lewej, yazi po prawej. Pomija, gdy na pulpicie jest już okno. |
| `df-blokada` | SUPER+L, hypridle, kafel Ognisko | Blokuje ekran hyprlockiem, chyba że ta sesja jest już zablokowana |
| `df-jezyk` | Skrypty Waybara, hyprlock | Wypisuje język interfejsu, `en` albo `pl` |
| `waybar-data` | `custom/data` | Data obok zegara w języku interfejsu, bez zera wiodącego |
| `waybar-okladka` | `image#okladka` | Pobiera okładkę z MPRIS i robi z niej zdesaturowaną rycinę z winietą; bez odtwarzacza nic nie wypisuje (moduł się chowa) |
| `waybar-odtwarzacz` | `custom/odtwarzacz` | Słucha `playerctl --follow` i wypisuje tytuł z wykonawcą; bez odtwarzacza pusty tekst (moduł się chowa) |
| `waybar-temperatura` | `custom/temperatura` | Temperatura procesora jako JSON, w dymku obciążenie, pamięć i grafika |
| `zrzut-ekranu` | *(zapasowy)* | Poprzedni skrypt zrzutów na grim + slurp; skróty używają dziś `hyprshot` |

Logika chowania rzędu kafli nie jest skryptem; siedzi w `config/quickshell/dark-fantasy/kafle/RzadKafli.qml`.

## Narzędzia (`tools/`)

| Narzędzie | Wynik |
|---|---|
| `skaluj-ikony-menu.py` | Ikony kafli 256 px w `assets/ikony-menu/256/` (uruchamiane przez `install.sh --apply`) |
| `generuj-szum.py` | Tekstura szumu pod powierzchniami powłoki i SDDM |
| `generuj-winiete.py` | Winieta nad ikonami programów w Uzbrojeniu |
| `generuj-ikony-quickshell.py` | Kody glifów Nerd Font dla powłoki |

Wszystkie wymagają Pythona 3; narzędzia graficzne także Pillow.

## Pliki ignorowane i generowane

`.gitignore` wyklucza sekrety, kopie zapasowe (`*.bak-*` z instalatorów), cache, `config/hypr/ustawienia.lua`, `config/hypr/lokalne.lua`, `assets/ikony-menu/256/`, kopię tapety w `sddm/dark-fantasy/backgrounds/` oraz pliki `colors.css` / `window_decorations.css`, które generuje `kde-gtk-config`.
