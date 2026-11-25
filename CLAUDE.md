# WAROWNIA POPIOŁÓW: zasady projektu

Stan na 2026-11-25, rola: agent główny.

Izometryczna gra akcji: Soulsborne (parowanie, blok, unik, postura) + extraction w stylu Tarkova (łup, Relikwiarz, ekstrakcja) + rozbudowa Warowni. Lochy generowane z ziarna.

## !! ZASADA PRYNCYPALNA !!
Na początku każdej sesji poproś autora o dostęp do **repo `y33bau/extract`** i do **folderu z grą na jego komputerze** (`C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_POPIOLOW`). Bez repo nie zaczynaj pracy.

## Kolejność czytania na start (obowiązkowo)
1. `docs/START_TUTAJ.md`: przekazanie (gdzie co jest, co gotowe, co czeka).
2. `docs/FUNDAMENT.md`: czym jest gra. **Każda nowa funkcja musi służyć temu dokumentowi.**
3. `docs/DZIENNIK.md`: ostatnie wpisy innych agentów (projekt krąży między 2–3 kontami).
4. Ten plik.

Przy sprzeczności wygrywa: decyzja autora w czacie > `docs/FUNDAMENT.md` > ten plik > `docs/DZIENNIK.md` (najnowszy wpis) > `docs/KONCEPCJE.md` > reszta.

## Fakty
1. Platforma: PC (Windows). Sterowanie: mysz i klawiatura **oraz pad** (obowiązkowo od pierwszej wersji, także w menu i Warowni). Nie projektujemy pod telefon.
2. Świat: wspólne lore z NightBrand (Hadræn, Goran, Mira, Iwo, Milena, Wierzyciele, Pakt, krainy), ale nowe wątki fabularne. Grafika postaci pochodzi z NightBrand.
3. Repo: `y33bau/extract`. NightBrand (`y33bau/NightBrand-PC`) to osobny projekt i magazyn grafiki: niczego tam nie zmieniamy.
4. Silnik: **Godot 4.7.2, GDScript, renderer Compatibility** (decyzja autora 25.11.2026). Gra żyje w `godot/`. Wersja JavaScript (`zrodlo/`, `zasoby/`, `dist/WAROWNIA_POPIOLOW.html`) to **archiwum prototypu**: nie rozwijamy jej, służy tylko za wzór przy przenoszeniu.
5. Publikacja: itch.io; później wersja Windows. Wgrywa autor.
6. Nie wymyślaj stanu gry ani numerów wersji: sprawdzaj komendami (`git log -5`, `git status`), nie z pamięci ani starych dokumentów.

## Struktura repo (Godot — tu pracujemy)
- `godot/project.godot`: projekt; scena główna `gra.tscn`; autoloady: `Sterowanie` (mapa klawiatura+mysz+pad), `Dane` (JSON z `godot/dane/`), `Profil` (zapis w user://), `Swiatla`, `Dzwiek` (syntezator SFX).
- `godot/skrypty/`: `gra.gd` (Warownia ⇄ rajd ⇄ wynik + **test automatyczny pełnej pętli na symulowanym padzie**), `hub.gd` (5 zakładek Warowni), `rajd.gd` (świat lochu i WSZYSTKIE reguły walki, łupu, ekstrakcji, śmierci), `mapgen.gd` (generator z ziarna, osobne strumienie losowania: układ/łupy/wrogowie), `bohater.gd` / `wrog.gd` (stan i wygląd), `hud.gd`, `okno_lupu.gd`, `efekty.gd`, `iso.gd`, `ui.gd` (wspólny wygląd).
- `godot/dane/*.json`: przedmioty, krainy, Warownia, umiejętności. `godot/zasoby/`: sprite'y postaci, `ikony/`, `kafle/<kraina>/`.
- `godot/export_presets.cfg`: eksport „Windows” (jeden plik .exe z wszytym pck; `dane/*.json` muszą być w include_filter) i „Linux (kontrola agenta)” do sprawdzania spakowanej gry.
- Pliki `.exe` i `dist/godot/` NIE trafiają do repo (rozmiar); autor dostaje zip do swojego folderu.

## Archiwum prototypu JS (nie rozwijamy)
- `zrodlo/index.html`: szkielet strony i HTML interfejsu (wersja robocza; otwiera się wprost z dysku).
- `zrodlo/js/NN_nazwa.js`: zwykłe skrypty, ładowane po kolei, wspólna przestrzeń nazw (moduły ES nie działają z file://).
  01 dane, 02 dźwięk, 03 profil i zapis, 04 grafika i sprite'y, 05 generator map, 06 hub (Warownia), 07 start rajdu, kolizje, widoczność, 08 walka (postura, pochodnia, sakwa), 09 ekwipunek w rajdzie i koniec rajdu, 10 pętla aktualizacji, 11 rysowanie, światło i HUD, 12 sterowanie.
- `zrodlo/tailwind.css`: wygenerowany Tailwind 3. Po dodaniu nowych klas: `npx tailwindcss@3` z content `zrodlo/**/*.{html,js}`.
- `zasoby/sprite/`: arkusze postaci (webp). Bohater 4×6 klatek po 128 px (rzędy przód/bok/tył; boczne patrzą w prawo). Wrogowie 4×2 (chód; atak 3 klatki + śmierć), boss 192 px.
- `narzedzia/zbuduj.py`: składa `dist/WAROWNIA_POPIOLOW.html` (wszystko wszyte w plik).
- `narzedzia/testy.py`: wspólne testy automatyczne (patrz niżej).
- `docs/`: fundament, dziennik, koncepcje, przekazanie, logi rund.

## Zasady pracy
1. Edytujemy `godot/`, `narzedzia/`, `docs/`. Archiwum JS ruszamy tylko, jeśli autor wyraźnie poprosi.
2. Każda runda na nowej gałęzi. Merge do `main` i push na `main` **tylko na wyraźne „publikuj” / „wrzucaj” autora**. Gałęzie robocze wolno pushować.
3. Najpierw fundament, potem funkcje: nie dodajemy mechanik spoza `docs/FUNDAMENT.md` bez zgody autora. Niezamówionych rzeczy nie ruszamy; usterkę zgłaszamy i pytamy.
4. Balansu i liczb ustalonych z autorem nie zmieniamy bez jego zgody.
5. Ziarno mapy ma dawać ten sam loch: losowania układu i łupów idą z ziarna, nie z `Math.random`.
6. Nigdy nie obiecujemy działania na padzie, w dźwięku ani na itch.io bez sprawdzenia. Test symuluje pada; prawdziwy pad sprawdza autor.
7. Pułapka Godota 4.7: akcje `ui_accept`/`ui_cancel` domyślnie NIE mają pada. Dopisujemy je w `Sterowanie` (A/B). Nowe akcje dodajemy tylko tam.

## Testy (obowiązkowe)
Jeden wspólny skrypt, żeby każdy agent robił to samo: **`python3 narzedzia/testy.py godot`**. Uruchamia grę pod wirtualnym ekranem (`xvfb-run`, Mesa) w trybie `--test`: pełna pętla na **symulowanym padzie** (Warownia, zakładki RB, ruch drążkiem, pochodnia, parowanie LB, riposta X, postura, skrzynia A, okno B, zrzut sakwy R3, ekstrakcja, zapis, śmierć, Relikwiarz, połowa PD). Zrzuty ekranu w katalogu tymczasowym: obejrzyj je po zmianach wizualnych. Linter `gdlint` (gdtoolkit) na razie tylko ostrzega.
- **Każda zmiana**: `testy.py godot` musi dać `WYNIK (godot): OK`.
- **Nowa mechanika**: dopisz jej test w `godot/skrypty/gra.gd` (funkcja `_test`).
- **Przed wysłaniem .exe autorowi**: wyeksportuj też „Linux (kontrola agenta)” i uruchom go z `--test` (sprawdza, czy dane weszły do paczki).
- Przygotowanie środowiska agenta (Godot, szablony eksportu): `docs/START_TUTAJ.md`, sekcja 4.
- **Przed każdą publikacją**: autor gra sam, także na padzie. Tylko on ocenia wyczucie.
- Wynik testów wpisujemy do dziennika. Test czerwony = nie kończymy rundy.

## Dziennik (obowiązkowy)
- **Przed pracą** przeczytaj ostatnie wpisy w `docs/DZIENNIK.md`.
- **Przed zakończeniem sesji** dopisz wpis na **górze** dziennika (najnowszy pierwszy), według wzoru z pliku: data i godzina, konto/agent, rola, gałąź i commit, co zrobiono, wynik testów, czego NIE sprawdzono, decyzje autora, następny krok.
- Każda decyzja autora z czatu trafia do dziennika (i do `FUNDAMENT.md`, jeśli zmienia fundament).

## Autor
- Rzeczoznawca majątkowy, w IT początkujący, ale świetnie rozumuje logicznie. Dyktuje po polsku (literówki traktuj życzliwie).
- Rozmawiamy partnersko i szczerze. Odpowiedzi po polsku, krótko, wynik najpierw, jedna polecana opcja z uzasadnieniem.
- Nie każemy mu używać gita ani pisać skryptów. Testy dla niego: pliki `TEST_*.bat`.
- W każdym meldunku: co zrobione, co sprawdzone, **czego NIE sprawdzono**.
- Nowy dokument w `docs/` zaczyna się linią „Stan na RRRR-MM-DD, rola X”.
