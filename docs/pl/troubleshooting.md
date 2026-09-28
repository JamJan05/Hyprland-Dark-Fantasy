# Pułapki i rozwiązywanie problemów

[← README](../../README.pl.md) · [English](../troubleshooting.md)

Każdą z tych rzeczy wykryto przy budowaniu tej konfiguracji. Większość kończy się cichą awarią, bez śladu w logu.

## Częste pytania

**Po zalogowaniu nie widać rzędu kafli.** To zamierzone. Układ powitalny otwiera okna, a przy otwartych oknach rząd się chowa. Zjedź kursorem do dolnej krawędzi albo naciśnij `SUPER + R`.

**Zmiana limitu ładowania za każdym razem pyta o hasło.** Wgraj [regułę udev](installation.md#limit-ładowania-baterii-reguła-udev).

**Nie ma rzędów limitu ładowania.** Bateria nie ma w sysfs plików `charge_control_*`, więc na tym sprzęcie ta opcja nie jest dostępna.

**Nie ma rzędów limitu mocy procesora.** Powłoka nie może uruchomić `sudo -n /usr/local/sbin/df-limit-mocy`: brakuje skryptu albo reguły sudo. Patrz [installation.md](installation.md#limit-mocy-procesora-ryzenadj). `sudo -n -l /usr/local/sbin/df-limit-mocy` powinno wypisać ścieżkę bez pytania o hasło.

**Zębatka pisze, że brakuje iomem=relaxed.** ryzenadj nie ma dostępu do procesora. Sprawdź `grep -o iomem=relaxed /proc/cmdline`; jeśli nic nie wypisze, parametr nie trafił do konfiguracji bootloadera albo komputer nie został uruchomiony ponownie.

**Po `./install.sh --apply` wróciła domyślna tapeta.** Tapeta wybrana w Zębatce (Cogwheel) jest zapisana w `hyprpaper.conf` i `hyprlock.conf` jako lokalna zmiana. Instalator ją zachowuje, chyba że w repo zmieniła się wersja tych plików; wtedy Twoja wersja leży obok w pliku `.bak-*`. Wybierz tapetę ponownie w Zębatce. Patrz [installation.md](installation.md#czego-installsh-nie-obejmuje).

**Ustawienie z Zębatki zepsuło Hyprlanda.** Hyprland pokaże powiadomienie wskazujące `ustawienia.lua`. Użyj Zębatka → Hyprland → Przywróć domyślne albo usuń `~/.config/hypr/ustawienia.lua` i uruchom `hyprctl reload`.

**`SUPER + R`, `U` albo `O` nic nie robią.** Powłoka nie działa. Uruchom ją przez `qs -n -c dark-fantasy`. `hyprctl globalshortcuts` pokaże, czy jej skróty są zarejestrowane.

**Co drugie kliknięcie w panel nie działa.** Działają dwie instancje powłoki, a `hyprctl layers` pokazuje dwie warstwy `quickshell-kafle`. Dlatego autostart używa `qs -n` (bez duplikatów); zabij nadmiarową instancję.

**Sprawdzenie autostartu bez wylogowania.** Autostart jest wystawiony jako funkcja globalna, a każdy program w nim jest chroniony przed podwójnym uruchomieniem:

```sh
hyprctl dispatch '(function() __autostart(); return hl.dsp.no_op() end)()'
```

## Skopiowana konfiguracja

### Zmiana w `~/.config` nie trafia do gita

Własne dodatki do Hyprlanda, np. zmienną środowiskową, regułę okna albo skrót, wpisuj do `~/.config/hypr/lokalne.lua` zamiast edytować `hyprland.lua`. `install.sh` nigdy tego pliku nie rusza (patrz [installation.md](installation.md#czego-installsh-nie-obejmuje)).

`install.sh` kopiuje konfigurację, więc `~/.config/...` i repozytorium to osobne pliki. Zmiana w systemie działa, ale `git status` w klonie jej nie widzi. Żeby ją zachować, skopiuj plik do klonu i zrób commit:

```sh
cp ~/.config/hypr/hyprland.lua ~/Hyprland-Dark-Fantasy/config/hypr/
cd ~/Hyprland-Dark-Fantasy && git add -A && git commit -m "opis zmiany"
```

W drugą stronę: zmiana w repo nic nie robi, dopóki nie uruchomisz `./install.sh --apply`. Lokalne zmiany, których nie przeniesiesz do repo, i tak przetrwają ponowną instalację: `install.sh` je zachowuje, chyba że ten sam plik zmienił się też w repo.

`sed -i` i edytory z „zapisem atomowym” niczego już nie psują; problem dotyczył tylko dowiązań tworzonych przez starsze instalacje.

### Pliki `.bak` obok konfiguracji

Plik w rodzaju `hyprland.lua.bak-20260912-143005` to wersja, którą `install.sh --apply` odłożył na bok, bo nie mógł jej zachować: od ostatniej instalacji zmieniła się i Twoja kopia, i plik w repo, albo nie było jeszcze zapisu (pierwsza instalacja na istniejącą konfigurację). Na miejscu jest teraz wersja z repo. Porównaj oba pliki, przenieś, co chcesz zachować, i usuń kopię. Własne linie z `hyprland.lua` przenieś do `~/.config/hypr/lokalne.lua`, żeby to się nie powtórzyło:

```sh
diff ~/.config/hypr/hyprland.lua.bak-20260912-143005 ~/.config/hypr/hyprland.lua
```

Żeby zobaczyć, co instalator zrobi, zanim to zrobi, uruchom `./install.sh` bez `--apply`.

## Hyprland z konfiguracją w Lua

**`hyprctl dispatch` przyjmuje Lua, nie hyprlang.** `hyprctl dispatch workspace 9` kończy się błędem `')' expected near '9'`. Zamiast tego: `hyprctl dispatch 'hl.dsp.focus({ workspace = 9 })'`. Dotyczy to wszystkich gotowców z internetu i konfiguracji Waybara.

**`hyprctl keyword` nie działa.** Odczyt po zapisie zwraca starą wartość. Ustawienia na żywo zmienia się przez `hyprctl eval '<lua>'`, i tak robi Zębatka.

**Polecenie w `hl.exec_cmd()` nie może zaczynać się od `[`.** Hyprland traktuje wiodące `[...]` jako regułę okna, spadek po `exec-once = [workspace 2] firefox`. Warunek w rodzaju `[ "$(...)" = 2 ] || ...` zostaje zjedzony jako reguła i nic się nie wykonuje. Używaj `test`.

**Program uruchomiony przez `&` w `hl.exec_cmd()` ginie.** Hyprland od razu zamyka powłokę. Używaj `setsid --fork` i przekierowuj wyjście do `/dev/null`.

**`hl.exec_cmd()` poza zdarzeniem `hyprland.start` rusza za wcześnie.** Wykonuje się w trakcie czytania konfiguracji, zanim powstanie gniazdo Waylanda, więc programy graficzne nie mają się z czym połączyć. Autostart w `hyprland.lua` jest rejestrowany przez `hl.on("hyprland.start", ...)`.

**`hl.timer` wywołany w trakcie czytania konfiguracji kończy się segfaultem**, także przy `Hyprland --verify-config`. Timery uruchamiaj dopiero ze zdarzeń.

**Podmiana `hyprland.lua` na żywo przez `cat >` raz zostawiła sesję bez żadnego skrótu.** Autoreload najpewniej złapał plik w połowie zapisu. Bezpieczniej: zapis do pliku tymczasowego w tym samym katalogu, `mv` na miejsce, potem sprawdzenie `hyprctl binds -j | jq length`.

**Klasa okna to nie nazwa pliku `.desktop`.** Kate ma plik `org.kde.kate.desktop`, ale ustawia `StartupWMClass=kate`. Ma to znaczenie przy regułach okien. Sprawdzisz przez `hyprctl clients -j | grep '"class"'`.

## Procesy

**`pkill -x` nie trafi w proces o nazwie dłuższej niż 15 znaków.** Tyle jądro trzyma w `comm`, więc `pkill -x` kończy się cicho z kodem 1. Dopasuj wtedy pełny wiersz poleceń: `pkill -f '^nazwa'`. Kotwica `^` nie pozwala trafić we własną powłokę.

**`pgrep -f` w warunku powłoki trafia w samą powłokę**, bo jej wiersz poleceń zawiera szukany wzorzec. Dlatego autostart używa `pgrep -x` / `pgrep -cx` na nazwie procesu.

## hyprlock

**Nie zabijaj `hyprlock` przez `pkill`, gdy ekran jest zablokowany.** To klient `ext-session-lock`, a jego ubicie potrafi wywrócić całą sesję Hyprlanda. API Hyprlanda ma na tę okoliczność funkcję ratunkową:

```sh
hyprctl dispatch 'hl.clear_crashed_lockscreen()'
```

Bezpieczny podgląd ekranu blokady to `hyprlock --grace 30`: przez 30 sekund ruch myszą odblokowuje bez hasła.

**`~` w ścieżce tapety działa w hyprpaperze i hyprlocku.** hyprlock przepuszcza ścieżkę tła przez `absolutePath()`, które rozwija wiodące `~`.

**hyprpaper 0.8 zmienił składnię.** Stare klucze `preload = ...` i `wallpaper = ,...` wczytują się bez błędu i nie pokazują tapety. Obecny format to blok `wallpaper { ... }`, jak w `config/hypr/hyprpaper.conf`.

## Kroje

**Pango gubi „ł” w kapitalikach EB Garamond.** Waybar i hyprlock rysują tekst Pangiem, a cecha `smcp` w EB Garamond 0.016 nie ma glifu „ł”, więc w jego miejscu zostaje dziura. W tych miejscach napisy używają osobnej rodziny **„EB Garamond SC”**.

**Cyfry nautyczne wymagają `lnum`.** Bez tej cechy EB Garamond rysuje cyfry starodawne i „11” w kapitalikach wygląda jak rzymskie „II”.

## Powłoka i sysfs

**Bateria w sysfs nie wysyła zdarzeń inotify.** `FileView` z `watchChanges` milczy, choć `energy_now` spada. Dlatego HUD czyta baterię co 10 s i przeładowuje stan od razu, gdy UPower zgłosi zmianę przez D-Bus. Progi ładowania są odczytywane przy otwarciu sekcji Zasilanie.

## Powiadomienia: cztery pakiety chcą tej samej nazwy D-Bus

mako, swaync, portal Plasmy i powłoka Quickshell zgłaszają `org.freedesktop.Notifications` do aktywacji przez D-Bus, a wygrywa ten, kto wystartuje pierwszy. Plik `local/share/dbus-1/services/org.freedesktop.Notifications.service` rozstrzyga to na korzyść powłoki, bo katalog użytkownika jest przeszukiwany przed systemowym.

Nazwę może trzymać tylko jeden proces, więc **SwayNC nie może startować razem z powłoką**. Gdyby zdążył pierwszy, powłoka nie zobaczyłaby ani jednego powiadomienia. Dlatego nie ma go w autostarcie.

**Powrót do SwayNC.** Pakiet jest nadal zainstalowany, a jego konfiguracja nadal jest kopiowana. Przywróć `run_once("swaync")` w autostarcie w `config/hypr/hyprland.lua` i zmień `Exec` w pliku `.service` z powrotem na `/usr/bin/swaync`.

**Który proces trzyma nazwę:**

```sh
gdbus call --session --dest org.freedesktop.DBus \
  --object-path /org/freedesktop/DBus \
  --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications
```

## Waybar

**Waybar 0.14.0 wypisuje `'swap-icon-label' must be a bool`**, gdy tego klucza nie ma w `hyprland/window`. Jawne ustawienie go na `false` ucisza ostrzeżenie.

**Waybar 0.14.0 nie ma modułu cava.** Nie ma do niego flagi USE. Cava działa tylko jako osobny program.

**`"interval": 0` to nie to samo co brak interwału.** Moduł custom z samym `"signal"` uruchamia się raz, a potem odświeża na sygnał. Dopisanie `"interval": 0` wyłącza odświeżanie na sygnał, i dlatego `custom/zasoby` nie ma klucza interval.

## SDDM

Pułapki SDDM (kolejność plików konfiguracyjnych, usługa `display-manager` na OpenRC, uprawnienia do tapety, cudzysłowy przy przecinkach) opisuje [installation.md](installation.md#ekran-logowania-sddm).
