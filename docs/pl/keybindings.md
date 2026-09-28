# Skróty

[← README](../../README.pl.md) · [English](../keybindings.md)

Każdy skrót jest zdefiniowany w `config/hypr/hyprland.lua` razem z opisem. Tę samą listę, prosto z kompozytora, znajdziesz w Zębatce (Cogwheel) → Hyprland → Skróty. Tam też przeniesiesz większość z nich na inne klawisze i dodasz własne skróty do aplikacji (patrz [cogwheel.md](cogwheel.md#skróty)). Tabele poniżej pokazują klawisze domyślne.

## Powłoka i programy

| Skrót | Działanie |
|---|---|
| `SUPER + R` | Menu kafli (pauza), otwarte na Uzbrojeniu |
| `SUPER + U` | Zębatka (ustawienia) |
| `SUPER + O` | Panel odtwarzacza |
| `SUPER + B` | Następny profil zasilania |
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + W` | Menedżer plików (yazi) |
| `SUPER + SHIFT + V` | Historia schowka (rofi) |
| `SUPER + L` | Blokada ekranu |
| `SUPER + M` | Wylogowanie |

`SUPER + R`, `U`, `O` i `B` trafiają do powłoki przez skróty globalne (`quickshell:menuToggle`, `systemToggle`, `mediaToggle`, `profilZasilania`). Gdy powłoka nie działa, nic nie robią. `hyprctl globalshortcuts` pokazuje, co jest zarejestrowane.

## Okna

| Skrót | Działanie |
|---|---|
| `SUPER + C` | Zamknij okno |
| `SUPER + V` | Okno pływające / kafelkowane |
| `SUPER + P` | Pseudokafelkowanie |
| `SUPER + J` | Zmień kierunek podziału (dwindle) |
| `SUPER + ←` `→` `↑` `↓` | Przesuń fokus |
| `SUPER + lewy przycisk myszy` | Przesuń okno |
| `SUPER + prawy przycisk myszy` | Zmień rozmiar okna |
| `SUPER + S` | Pokaż / ukryj scratchpad |
| `SUPER + SHIFT + X` | Przenieś okno do scratchpada |

## Pulpity i piętra

| Skrót | Działanie |
|---|---|
| `SUPER + 1..0` | Pulpit na bieżącym piętrze |
| `SUPER + SHIFT + 1..0` | Przenieś okno na pulpit bieżącego piętra |
| `SUPER + CTRL + 1..0` | Piętro, powrót na jego ostatni pulpit |
| `SUPER + CTRL + ↑` / `↓` | Piętro wyżej / niżej |
| `SUPER + kółko` | Następny / poprzedni pulpit piętra |
| 3 palce ← / → | Następny / poprzedni pulpit piętra (za ostatnim tworzy nowy, poza piętro nie wychodzi) |
| 3 palce ↑ / ↓ | Piętro wyżej / niżej |

Patrz [floors.md](floors.md).

## Zrzuty ekranu

| Skrót | Działanie |
|---|---|
| `SUPER + SHIFT + S` | Zaznaczony obszar |
| `SHIFT + Print` | Zaznaczony obszar |
| `Print` | Cały monitor |
| `SUPER + Print` | Wskazane okno |

Zrzuty trafiają do `<XDG Pictures>/Zrzuty ekranu` (przy angielskim interfejsie `Screenshots`) i do schowka.

## Klawisze multimedialne

Działają także przy zablokowanym ekranie.

| Klawisz | Działanie |
|---|---|
| Głośniej / ciszej | ±5 % (przytrzymanie powtarza) |
| Wyciszenie / wyciszenie mikrofonu | Przełącza wyciszenie wyjścia / mikrofonu |
| Jaśniej / ciemniej | ±5 % |
| Play, Pause | Odtwarzanie / pauza (playerctl) |
| Next, Previous | Następny / poprzedni utwór |

## W menu

**Rząd kafli (pauza)**

| Klawisze | Działanie |
|---|---|
| `←` `→` | Zmiana kafla (z zawijaniem) |
| `↓` / `Enter` | Wejście w kafel |
| `Esc` | Poziom wyżej / wyjście z pauzy |

**Uzbrojenie (Arsenal)**

| Klawisze | Działanie |
|---|---|
| pisanie | Filtrowanie programów |
| strzałki | Ruch po siatce |
| `Enter` | Uruchomienie |
| `Backspace` | Usunięcie znaku |
| `Esc` | Najpierw czyści wyszukiwanie, potem powrót do rzędu |

**Zębatka (Cogwheel)**

| Klawisze | Działanie |
|---|---|
| `↑` `↓` | Sekcja / opcja |
| `→` / `Enter` | Do opcji; zatwierdzenie albo edycja wartości |
| `←` `→` | Zmiana wartości |
| `Esc` | Powrót |

**Wieści (Tidings)**

| Klawisze | Działanie |
|---|---|
| `↑` `↓` | Przewijanie historii |
| `Delete` | Wyczyszczenie całej historii |
| `Esc` | Powrót do rzędu |

**Ognisko (Bonfire)**

| Klawisze | Działanie |
|---|---|
| `↑` `↓` | Wybór pozycji |
| `Enter` | Wykonanie. Wylogowanie, restart i wyłączenie wymagają drugiego `Enter`. |
| `Esc` | Anulowanie / powrót |

**Panel odtwarzacza**

| Klawisze | Działanie |
|---|---|
| `←` `→` | Poprzedni / następny utwór |
| `Enter` / `Spacja` | Odtwarzanie / pauza |
| `Esc` | Zamknięcie |
