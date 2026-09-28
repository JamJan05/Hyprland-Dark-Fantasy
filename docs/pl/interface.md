# Interfejs

[← README](../../README.pl.md) · [English](../interface.md)

Powłoka jest napisana w Quickshellu (`config/quickshell/dark-fantasy/`). Odpowiada za HUD, rząd kafli, panele, OSD i demona powiadomień. Pasek rysuje Waybar, ekran blokady hyprlock, a ramki okien i rozmycie sam Hyprland.

## Zasady wyglądu

Te zasady obowiązują wszędzie: w Hyprlandzie, powłoce, Waybarze, hyprlocku, SDDM i GTK.

- **Ostre prostokąty.** Ani jednego zaokrąglenia.
- **Ramki 1 px** w spłowiałym złocie. To, co aktywne, dostaje pełne złoto.
- **Ziarno** w rozmyciu Hyprlanda i pod panelami powłoki („popiół, a nie gładka czerń”).
- **EB Garamond w kapitalikach** na napisy, **JetBrainsMono Nerd Font** na liczby.
- **Ruch tylko przez przenikanie.** Bez sprężyn, bez wysuwania, nic nie wyskakuje.
- **Żar jest zarezerwowany dla alarmów i ładowania.** Nawet dzisiejsza data w kalendarzu jest złota, nie w żarze.

Cały wygląd wynika z kształtów, palety i typografii. Repozytorium nie zawiera grafik, krojów ani tekstów z gry.

### Paleta

Paleta jest taka sama we wszystkich plikach (CSS, Lua, QML, hyprlang). W powłoce jedynym źródłem jest `config/quickshell/dark-fantasy/Theme.qml`.

| Rola | Kolor |
|---|---|
| Tło | `#0b0b0c` |
| Powierzchnia | `#151311` |
| Powierzchnia, wariant | `#201c18` |
| Tekst | `#d7d0c5` |
| Tekst przygaszony | `#81786b` |
| Złoto (akcent) | `#b19a67` |
| Żar (tylko alarmy i ładowanie) | `#8f4935` |
| Żelazo | `#55504a` |
| Pasek HP (bateria) | `#7a2c26` |
| Pasek FP (pamięć) | `#3f5566` |
| Pasek staminy (procesor) | `#4f5d3a` |

## Rząd kafli

Sześć kafli wyśrodkowanych u dołu ekranu. Zastępują dok i menu aplikacji, a zawartość kafla otwiera się **nad** rzędem.

| # | Kafel | Nazwa angielska | Co robi |
|---|---|---|---|
| 1 | **Uzbrojenie** | Arsenal | Wszystkie programy. Po lewej siatka slotów, po prawej „opis przedmiotu” zaznaczonego programu (nazwa, nazwa ogólna, `Comment=` z pliku `.desktop`, polecenie `Exec`). Pisanie filtruje siatkę, Enter uruchamia. |
| 2 | **Sakwa** | Satchel | Pliki: yazi w kitty, jako zwykłe okno układu (`local/bin/menedzer-plikow`). |
| 3 | **Status** | Status | btop w pływającym oknie 70 × 70 % ekranu, które przyciemnia otoczenie (`local/bin/monitor-systemu`, klasa okna `df-panel`). |
| 4 | **Wieści** | Tidings | Historia powiadomień i tryb „nie przeszkadzać”. Licznik w rogu kafla pokazuje czekające powiadomienia. |
| 5 | **Zębatka** | Cogwheel | Ustawienia. Patrz [cogwheel.md](cogwheel.md). |
| 6 | **Ognisko** | Bonfire | Blokada, uśpienie, wylogowanie, restart, wyłączenie. Trzy ostatnie pytają o potwierdzenie. |

### Kiedy rząd jest widoczny

Rząd reaguje na to, co jest na pulpicie, a nie na timeout:

| Sytuacja | Rząd |
|---|---|
| Pusty pulpit | widoczny |
| Pojawia się okno | chowa się |
| Zamykasz ostatnie okno | wraca |
| Kursor przy dolnej krawędzi | pokazuje się, także nad oknami |
| Kursor na rzędzie | zostaje |
| Kursor odjeżdża | po 0,45 s znów się chowa |

Powierzchnie layer-shell, czyli paski, powiadomienia i tapeta, nie liczą się jako okna. Okna scratchpada liczą się tylko wtedy, gdy scratchpad jest pokazany. Kursor wykrywa maska wejścia okna (pasek 3 px przy krawędzi plus obrys rzędu), więc nic nie odpytuje w tle.

Po zalogowaniu układ powitalny (`local/bin/uklad-startowy`) otwiera terminal, `tty-clock` i yazi. Skoro są okna, rząd startuje schowany. To zamierzone, a nie błąd.

### Pauza

`SUPER + R` (od razu w Uzbrojeniu, gotowe do pisania) albo kliknięcie w pasek przy dolnej krawędzi otwiera **pauzę**. Pulpit przyciemnia się razem z paskiem i HUD-em, nad rzędem i pod nim pojawiają się złote kreski, a klawiatura działa jak pad:

| Klawisze | Działanie |
|---|---|
| `←` `→` | Zmiana kafla, z zawijaniem |
| `↓` / `Enter` | Wejście w zawartość kafla |
| `Esc` | Poziom wyżej; na rzędzie wyjście z pauzy |
| pisanie | Na kaflu z zawartością od razu do niej przechodzi |

Myszą **jedno kliknięcie używa kafla**: Sakwa i Status uruchamiają swój program, a pozostałe otwierają zawartość w pauzie.

Klawisze wewnątrz kafli są w [keybindings.md](keybindings.md#w-menu).

### Ikony kafli

- Oryginały to sześć plików PNG 512 × 512 px w `assets/ikony-menu/`: `uzbrojenie.png`, `sakwa.png`, `status.png`, `wiesci.png`, `zebatka.png`, `ognisko.png`. Każdy ma własną ramkę i relief, więc powłoka nie rysuje wokół kafla drugiej ramki.
- `tools/skaluj-ikony-menu.py` robi z nich kopie 256 × 256 (filtr Lanczos) w `assets/ikony-menu/256/`. Ten katalog to wynik, nie źródło, i jest w `.gitignore`.
- `install.sh --apply` uruchamia skrypt i kopiuje `256/` do `~/.local/share/dark-fantasy/ikony-menu`, stałej ścieżki, z której czyta powłoka.
- Ikony są autorstwa właściciela repozytorium. Nie pochodzą z gry.

## HUD w lewym górnym rogu

HUD to osobne okno warstwy powłoki nad lewym końcem paska. Ma tę samą wysokość, tło i obwódkę co ramki Waybara. Układ jest jak HUD z gry: godło po lewej, obok trzy paski, pod nimi rządek statusów.

- **Godło.** Bieżące piętro cyfrą rzymską (`I` … `X`) w podwójnej ramce. W dymku numer piętra i nazwa nadana w Zębatce. **Kółko myszy** nad godłem zmienia piętro.
- **Trzy paski 6 px.** Długość pokazuje „statystyki” komputera, a wypełnienie bieżący stan. Liczby są tylko w dymkach.

  | Pasek | Wypełnienie | Długość |
  |---|---|---|
  | HP | poziom baterii | 4 px na projektowy Wh (`energy_full_design`), skrócone o kondycję baterii (`energy_full`). Zużyty akumulator ma krótszy pasek, jak utracone max HP. |
  | FP | zajęta pamięć RAM | 14 px na GiB |
  | Stamina | obciążenie procesora | 12 px na wątek |

  Podczas ładowania obwódka HP zmienia kolor na żar. Bez baterii HP to pełny pasek o stałej długości.
- **Pulpity piętra.** Kwadracik na każdy istniejący pulpit. Aktywny jest wypełniony złotem, a pulpit z oknem wołającym o uwagę jest w żarze. Kliknięcie w kwadracik przełącza pulpit.
- **Statusy narastające.** Pojawiają się tylko, gdy coś się dzieje, i gasną po 5 s ciszy: transfer sieci powyżej 100 KiB/s (złoto) i temperatura procesora powyżej 70 °C (żar).

Paski wyłączysz w Zębatce → System → Zachowanie → Paski HUD-u. Procesor, pamięć i baterię pokazuje wtedy prawa strona Waybara jako liczby (`custom/zasoby`).

## Pasek (Waybar)

- **Lewa strona:** tytuł aktywnego okna, odsunięty za HUD.
- **Środek, ramka „teraz”:** `HH:MM` w kroju mono, data kapitalikami, okładka (zdesaturowana, z winietą) oraz tytuł i wykonawca. Gdy żaden program nic nie odtwarza, okładka, tytuł i przyciski się chowają, a ramka zwęża się do zegara i daty.
  - Najechanie na zegar pokazuje kalendarz. Kółko zmienia miesiąc, prawy przycisk przełącza miesiąc / rok.
  - Najechanie na tytuł wysuwa przyciski: poprzedni / pauza / następny.
  - Kliknięcie w tytuł albo okładkę otwiera panel odtwarzacza.
- **Prawa strona:** liczby zasobów (tylko przy wyłączonych paskach HUD-u), temperatura, sieć, Bluetooth, zasobnik.
  - **Temperatura:** dymek dokłada obciążenie procesora, zajętość pamięci i stan zintegrowanej grafiki. Moduł zmienia kolor na żar powyżej 70 °C, przy tym samym progu co HUD.
  - **Sieć:** lewy przycisk wysuwa szybki panel Wi-Fi z przełącznikiem, listą sieci i łączeniem z hasłem (WPA/WPA2/WPA3-PSK). Prawy otwiera `nmtui` do całej reszty, np. sieci firmowych z EAP.
  - **Bluetooth:** lewy przycisk wysuwa szybki panel z zasilaniem, urządzeniami, łączeniem jednym kliknięciem i poziomem baterii słuchawek. Prawy otwiera `bluetoothctl` do parowania z PIN-em, zaufania i blokowania.

Głośności i jasności nie ma na pasku. Są w Zębatce, klawisze multimedialne działają jak zwykle, a każdą zmianę potwierdza OSD.

## Panel odtwarzacza

Otwiera go `SUPER + O` albo kliknięcie w tytuł lub okładkę w ramce „teraz”. Pokazuje bieżący odtwarzacz: nagłówek „Teraz gra”, okładkę jako „przedmiot” (zdesaturowaną, z winietą), utwór, postęp jako 6-pikselowy pasek z HUD-u i gołe glify zamiast przycisków. Gdy nic nie gra, panel to mówi.

| Klawisze | Działanie |
|---|---|
| `←` / `→` | Poprzedni / następny utwór |
| `Enter` / `Spacja` | Odtwarzanie / pauza |
| `Esc` albo kliknięcie obok | Zamknięcie |

## Powiadomienia i OSD

- **Demon powiadomień.** Nazwę `org.freedesktop.Notifications` trzyma powłoka. Plik `local/share/dbus-1/services/org.freedesktop.Notifications.service` sprawia, że aktywacja D-Bus uruchamia powłokę, a nie mako, swaync czy Plasmę. SwayNC zostaje zainstalowany i skonfigurowany jako droga odwrotu; patrz [troubleshooting.md](troubleshooting.md#powiadomienia-cztery-pakiety-chcą-tej-samej-nazwy-d-bus).
- **Dymki** pojawiają się w prawym górnym rogu pod paskiem, na warstwie overlay, więc są widoczne także nad oknem pełnoekranowym.
- **Wieści** trzymają historię z przyciskiem „Wyczyść” i trybem „nie przeszkadzać”. Otwarcie Wieści chowa dymki, które akurat są na ekranie.
- **OSD.** Krótki podgląd na dole ekranu przy zmianie głośności, jasności, wyciszenia albo profilu zasilania. Milczy przy starcie powłoki i przy otwartej Zębatce, bo Zębatka pokazuje te same wartości.

## Blokada i bezczynność

`config/hypr/hypridle.conf` ustawia łańcuch bezczynności:

| Po | Działanie |
|---|---|
| 5 min | Wygaszenie ekranu |
| 10 min | Blokada (`loginctl lock-session` → hyprlock) |
| 30 min | Uśpienie (`loginctl suspend`) |

Sesja jest też blokowana przed uśpieniem. Zębatka → System → Zachowanie → **Nie wygaszaj ekranu** wstrzymuje wszystkie trzy.

hyprlock (`config/hypr/hyprlock.conf`) pokazuje tapetę, zegar, pole hasła i motto. `SUPER + L` blokuje na żądanie i nie uruchamia drugiej instancji. Napisy ekranu blokady idą za językiem interfejsu (patrz [cogwheel.md](cogwheel.md#język)).

## Zrzuty ekranu i schowek

- **Zrzuty ekranu** robi `hyprshot`: kopiuje do schowka, zapisuje plik i wysyła powiadomienie. Pliki trafiają do `<XDG Pictures>/Zrzuty ekranu` przy polskim interfejsie albo `<XDG Pictures>/Screenshots` przy angielskim; katalog powstaje przy pierwszym zrzucie. Starszy `local/bin/zrzut-ekranu` (grim + slurp) nadal działa jako zapasowy.
- **Historia schowka:** `wl-paste --watch cliphist store` działa dla tekstu i obrazów, a `SUPER + SHIFT + V` otwiera historię w rofi z motywem `dark-fantasy.rasi`.

## Sterowanie powłoką ze skryptów

Powłoka wystawia cele IPC. `qs -c dark-fantasy ipc show` wypisuje wszystkie. Przykłady:

```sh
qs -c dark-fantasy ipc call media toggle            # panel odtwarzacza
qs -c dark-fantasy ipc call system toggle           # Zębatka
qs -c dark-fantasy ipc call kafle toggle            # pauza menu kafli
qs -c dark-fantasy ipc call notifications toggleDnd # nie przeszkadzać
qs -c dark-fantasy ipc call hud przelaczPaski       # paski HUD-u wł. / wył.
qs -c dark-fantasy ipc call zasilanie przelaczProfil
qs -c dark-fantasy ipc call jezyk ustaw pl          # język interfejsu
qs -c dark-fantasy ipc call idle toggle             # nie wygaszaj ekranu
```
