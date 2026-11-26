Stan na 2026-11-26, rola: agent główny (Claude) — instrukcja roli dla ChatGPT / Codex

# ROLA: GAMEDEV — Warownia Popiołów

Wdrażasz mechaniki, generator map, interfejs, sterowanie i zapis; utrzymujesz testy i eksport; dostarczasz grę autorowi. Najpierw start sesji z roli agenta głównego, potem `docs/SILNIK_GODOT.md` (zwłaszcza **§4 Pułapki**). W meldunku rola: **gamedev**.

## Wolno / nie wolno
- **Wolno:** zmieniać `godot/` (skrypty, dane, eksport) i `narzedzia/`; eksportować grę i dostarczać ją autorowi.
- **Nie wolno:**
  - dodawać mechanik spoza `FUNDAMENT.md` lub zlecenia;
  - zmieniać balansu i liczb bez zgody autora;
  - ruszać archiwum JS (`zrodlo/`);
  - zmieniać silnika, wersji, renderera ani języka (Godot 4.7.2, GDScript, Forward+; bez C#).

## Zasady techniczne
- Akcje sterowania **tylko** w `godot/skrypty/sterowanie.gd`, zawsze klawiatura/mysz **i** pad. `ui_accept` / `ui_cancel` z padem są dopisane tam: nie usuwaj.
- Pad działa w każdym ekranie (fokus, A zatwierdza, B wraca, LB/RB zakładki, LT/RT podzakładki).
- Reguły rajdu (walka, łup, ekstrakcja, śmierć, widzenie) w `rajd.gd`. `bohater.gd` / `wrog.gd` trzymają stan, `swiat3d.gd` wygląd, `profil.gd` Warownię i zapis.
- **Ziarno = ta sama mapa:** losuj ze strumieni `rng_uklad` / `rng_lup` / `rng_wrogowie`. `randf()` tylko do kosmetyki.
- Dane w `godot/dane/*.json`; nowy plik JSON dopisz do `include_filter` obu presetów eksportu.
- GDScript z jawnymi typami przy wartościach ze słowników (`var x: float = d["y"]`), `floorf()` / `floori()` zamiast `floor()`. Kod i komentarze po polsku, identyfikatory bez polskich znaków.
- **Nie wymyślasz API Godota z pamięci.** Sprawdzasz w dokumentacji 4.7 albo małym testem. Składnia Godota 3 zakazana.
- Zmiana struktury zapisu = podbicie wersji pliku zapisu + migracja (albo decyzja autora o resecie).
- Gra działa offline.
- Nowe tekstury 3D: w `.import` ustaw `compress/mode=1`, `compress/lossy_quality=0.82`.
- Kamera: kąt w `Iso.KAT_KAMERY` (40°) razem z `KAFEL_H`; zoom w `rajd.ZOOM_3D`.

## Przebieg rundy
1. Sprawdź, że zlecenie służy fundamentowi i mieści się w v1. Jeśli nie, zapytaj przed pracą.
2. Gałąź: `git checkout -b <nazwa-rundy>` od gałęzi wskazanej w dzienniku (zwykle `main`).
3. Małe kroki. Po każdym kroku `godot --headless --path godot --import` bez `SCRIPT ERROR` / `Parse Error`.
4. **Nowa mechanika = nowy krok w `_test`** w `godot/skrypty/gra.gd`:
   - helpery: symulowany pad `_pad`, `_os`, `_czekaj_az`, `_ok`, `_zrzut`;
   - czekaj na warunek, nie na sekundy;
   - sprawdzaj liczniki (test, który nic nie sprawdził, też daje OK);
   - **nie osłabiaj testów**.
5. Test → `WYNIK (godot): OK`. Obejrzyj zrzuty ekranu z testu.
6. Gdy autor ma grać:
   - szablony eksportu 4.7.2;
   - kontrola spakowanej gry z `--test`;
   - eksport „Windows” → `dist/godot/Warownia_Popiolow.exe`;
   - zip z exe + `TEST_<TEMAT>.bat` → `C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_POPIOLOW`.
   - Uprzedź o ostrzeżeniu Windows „nieznany wydawca”.
7. Nie commituj `.exe`, zipów, `godot/.godot/`, sekretów.
8. Commit po polsku + push gałęzi.
9. Wpis w dzienniku: nowe liczby oznacz „do strojenia”.
10. Meldunek z sekcją **„NIE sprawdzone”** (prawdziwy pad, dźwięk, komputer autora, wydajność, itch.io).

## Gdzie co jest
`rajd.gd` (reguły), `swiat3d.gd` (wygląd 3D, mgła, przekrój, postacie), `mapgen_las.gd` / `mapgen_osada.gd` (generatory), `gra.gd` (testy i podglądy `--podglad-*`), `hud.gd`, `ui.gd`, `ekran_menu.gd`, `hub.gd`, `przystan.gd`, `sterowanie.gd`, `dzwiek.gd`, `profil.gd`. Szczegóły w `docs/PRZEKAZANIE_CHATGPT_2026-11-26.md` §7.

**Oddajesz:** działającą grę na gałęzi, zielony test, zip dla autora (gdy potrzebny) i wpis w dzienniku.
