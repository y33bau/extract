# WAROWNIA POPIOŁÓW: zasady projektu

Stan na 2026-11-25, rola: agent główny.

Izometryczna gra akcji: Soulsborne (parowanie, blok, unik, stamina) + extraction w stylu Tarkova (łup, Relikwiarz, ekstrakcja) + rozbudowa Warowni. Lochy generowane z ziarna.

## Fakty
1. Platforma: komputer (Windows, klawiatura i mysz; pad później). Nie projektujemy pod telefon.
2. Świat: wspólne lore z NightBrand (Hadræn, Goran, Mira, Iwo, Milena, Wierzyciele, Pakt, krainy), ale nowe wątki fabularne. Grafika postaci pochodzi z NightBrand.
3. Repo: `y33bau/extract`. NightBrand (`y33bau/NightBrand-PC`) to osobny projekt i magazyn grafiki: niczego tam nie zmieniamy.
4. Silnik: canvas 2D, rzut izometryczny, bez Three.js i bez bibliotek z internetu. Gra musi działać offline po dwukliku.
5. Publikacja: itch.io (jeden plik HTML). Wgrywa autor.

## Struktura
- `zrodlo/index.html`: szkielet strony i HTML interfejsu (wersja robocza; otwiera się wprost z dysku).
- `zrodlo/js/NN_nazwa.js`: zwykłe skrypty, ładowane po kolei. Wspólna przestrzeń nazw, bez modułów ES (nie działają z file://).
  01 dane, 02 dźwięk, 03 profil i zapis, 04 grafika i sprite'y, 05 generator map, 06 hub (Warownia), 07 start rajdu i kolizje, 08 walka, 09 ekwipunek w rajdzie i koniec rajdu, 10 pętla aktualizacji, 11 rysowanie i światło, 12 sterowanie.
- `zrodlo/tailwind.css`: wygenerowany Tailwind 3 (klasy z `zrodlo/`). Po dodaniu nowych klas Tailwinda trzeba go przegenerować (`npx tailwindcss@3`, content: `zrodlo/**/*.{html,js}`).
- `zasoby/sprite/`: arkusze postaci (webp). Bohater: 4×6 klatek po 128 px (rzędy: przód / bok / tył; boczne patrzą w prawo). Wrogowie: 4×2 (chód; atak 3 klatki + śmierć), boss 192 px.
- `narzedzia/zbuduj.py`: skleja wszystko w `dist/WAROWNIA_POPIOLOW.html` (CSS, skrypty i sprite'y wszyte w plik).
- `docs/`: koncepcje, decyzje, logi sesji.

## Zasady pracy
1. Edytujemy tylko `zrodlo/`, `zasoby/`, `narzedzia/`, `docs/`. Pliku `dist/` nie poprawiamy ręcznie: zawsze `python3 narzedzia/zbuduj.py`.
2. Każda runda na nowej gałęzi od `main`. Merge do `main` i push na `main` tylko na wyraźne „publikuj” / „wrzucaj” autora.
3. Po każdej zmianie: budowa + test w przeglądarce (brak błędów konsoli, start rajdu, walka, koniec rajdu).
4. W meldunku zawsze wypisz, czego NIE sprawdzono (granie ręczne, dźwięk, pad, itch.io).
5. Ziarno mapy ma dawać ten sam loch. Nowe losowania układu/łupów idą z ziarna, nie z `Math.random`.
6. Autor: odpowiedzi po polsku, krótko, wynik najpierw, jedna polecana opcja. Nie każemy mu używać gita; testy dla niego jako `TEST_*.bat`.
7. Nowy dokument w `docs/` zaczyna się linią „Stan na RRRR-MM-DD, rola X”.
