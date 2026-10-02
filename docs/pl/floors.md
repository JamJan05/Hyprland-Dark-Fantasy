# Piętra

[← README](../../README.pl.md) · [English](../floors.md)

**Piętro** grupuje dziesięć pulpitów. Każde piętro ma własne pulpity 1-9 i 0, więc `SUPER + 3` na piętrze I i `SUPER + 3` na piętrze II to dwa różne pulpity. Klawisz `0` znaczy „dziesiąty”, zarówno dla pulpitu, jak i dla piętra (piętro `X`).

HUD w lewym górnym rogu pokazuje bieżące piętro cyfrą rzymską na godle, a pod paskami kwadracik na każdy istniejący pulpit **tego** piętra.

## Sterowanie

| Wejście | Działanie |
|---|---|
| `SUPER + 1..0` | Pulpit na bieżącym piętrze |
| `SUPER + SHIFT + 1..0` | Przeniesienie okna na pulpit bieżącego piętra (fokus idzie za oknem) |
| `SUPER + CTRL + 1..0` | Przejście na piętro, na pulpit, na którym ostatnio z niego wyszedłeś |
| `SUPER + CTRL + ↑` / `↓` | Piętro wyżej / niżej (zatrzymuje się na pierwszym i ostatnim) |
| `SUPER + kółko` | Następny / poprzedni istniejący pulpit piętra, z zawijaniem |
| 3 palce ← / → | Następny / poprzedni pulpit piętra |
| 3 palce ↑ / ↓ | Piętro wyżej / niżej |
| Kliknięcie kwadracika w HUD-zie | Przejście na ten pulpit |
| Kółko nad godłem HUD-u | Zmiana piętra |

Piętro powyżej ustawionej liczby pięter nic nie robi. Na przykład `SUPER + CTRL + 7` przy pięciu piętrach jest ignorowane.

## Gesty

Oba gesty trzema palcami działają z dowolnego miejsca ekranu.

- **W bok** przechodzi po istniejących pulpitach piętra. Nie zawija i **nigdy nie wychodzi poza piętro**. Za ostatnim pulpitem tworzy **jeden** nowy, tak jak natywny swipe, chyba że bieżący pulpit jest pusty albo jest pulpitem 0.
- **W górę / w dół** zmienia piętro.
- **Progi** są te same, których Hyprland używa dla natywnego swipe'a. Ruch musi osiągnąć `workspace_swipe_distance × workspace_swipe_cancel_ratio` (domyślnie 300 × 0,5 = 150 px) albo być szybkim machnięciem, więc przypadkowe drgnięcie nic nie robi.
- **Kierunek** idzie za `gestures:workspace_swipe_invert`. Przy wartości domyślnej palce w lewo dają następny pulpit, a palce w górę następne piętro. Oba kierunki odwrócisz w Zębatce → Hyprland → Wejście: „Następny pulpit / piętro: palce” na „w prawo / w dół”.
- **Pulpit zmienia się po puszczeniu palców**, ze zwykłą animacją workspace'ów. Nie przesuwa się za palcami, bo natywnego gestu nie da się zatrzymać na krańcu piętra. To cena za gesty, które nie wychodzą poza piętro.

Gesty pięter wyłączysz w Zębatce (Cogwheel) → Hyprland → Wejście.

## Liczba pięter i nazwy

Zębatka → Hyprland → Piętra ustawia liczbę pięter (1-10) i nazwę każdego z nich. Nazwa pojawia się w dymku godła, a samo godło zostaje przy cyfrze rzymskiej.

Zmiana liczby pięter nigdy nie przenosi okien. Siatka ma zawsze 10 × 10, a ustawienie tylko ogranicza, na które piętra da się wejść.

## Mapowanie na workspace'y Hyprlanda

Piętra to zwykłe, numerowane workspace'y Hyprlanda:

```
id = (piętro - 1) × 10 + pulpit        (pulpit 0 = 10)

piętro I → 1..10     piętro II → 11..20     …     piętro X → 91..100
```

- Piętro I to dokładnie klasyczne workspace'y 1-10, więc kto nie zmienia pięter, nie zauważy różnicy.
- Workspace'y powstają przy pierwszym wejściu i znikają puste; nic nie jest tworzone z góry.
- Nie ma nazwanych workspace'ów, bo Hyprland nadaje im ujemne numery w kolejności tworzenia, a te zmieniałyby się w każdej sesji.
- Numerów workspace'ów nie widać nigdzie w interfejsie.

## Implementacja

Całość to `config/hypr/floors.lua`, wczytywany przez `hyprland.lua` przez `require("floors")`. Bez wtyczki i bez skryptu w tle.

- **Bieżące piętro jest zawsze liczone z numeru aktywnego workspace'u**, a nie trzymane w zmiennej. Gest, kliknięcie w HUD-zie czy `hyprctl dispatch` z terminala nie sprawią więc, że HUD pokaże złe piętro.
- **Ostatni pulpit każdego piętra** jest zapamiętywany w pliku w katalogu instancji Hyprlanda (`$XDG_RUNTIME_DIR/hypr/<sygnatura instancji>/`), bo przeładowanie konfiguracji uruchamia interpreter Lua od nowa. Nowa sesja zaczyna na piętrze I, pulpicie 1.
- **Stan dla HUD-u.** Po każdej zmianie `floors.lua` zapisuje `floors-stan.json` w tym samym katalogu, podmieniając go w całości przez plik tymczasowy i zmianę nazwy. Powłoka śledzi ten plik, więc nic nie jest odpytywane i nie ma sygnałów.
- **Ustawienia** przychodzą z Zębatki przez `floors.ustaw({ pietra = …, nazwy = { … }, gesty = … })`, wołane z `~/.config/hypr/ustawienia.lua`, a na żywo przez `hyprctl eval`.
- **Akcje zwracają dispatchery**, więc da się ich użyć także z terminala:

  ```sh
  hyprctl dispatch 'floors.desktop(3)'
  ```

  Przy konfiguracji w Lua `hyprctl dispatch X` to skrót od `hl.dispatch(X)`.
