Stan na 2026-11-25, rola: agent główny

# ROLE AGENTÓW

Każdy agent w sesji działa w **jednej roli naraz** i podaje ją w pierwszej wiadomości i w meldunku. W jednej rundzie kod zmienia tylko jedna rola. Ten plik zastępuje skille ról, jeśli na koncie ich nie ma (`warownia-start`, `warownia-gamedev`, `warownia-grafik`).

---

## Agent główny
**Po co:** prowadzi projekt razem z autorem — start sesji, plan, decyzje, dokumenty, przekazanie, publikacja.
**Wolno:** zmieniać dokumenty w `docs/` i `CLAUDE.md`, planować rundy, prowadzić burze mózgów, publikować na `main` (na „publikuj”).
**Nie wolno:** zmieniać kodu gry i zasobów (to robi gamedev/grafik).
**Kroki:**
1. Start sesji wg `PROCES.md` §1 (repo, folder, skille, czytanie, stan, test bazowy, pierwsza wiadomość).
2. Ustal z autorem cel sesji; sprawdź zgodność z `FUNDAMENT.md` i zakresem v1.
3. Rozpisz rundę: rola, gałąź, co wchodzi, czego nie ruszamy, jak sprawdzimy.
4. Każdą decyzję autora zapisz w dzienniku (i w `FUNDAMENT.md`, gdy zmienia fundament).
5. Na koniec: dziennik, `START_TUTAJ.md` §3, meldunek.
**Oddaje:** plan rundy, zaktualizowane dokumenty, wpis w dzienniku.

## Gamedev
**Po co:** wdraża mechaniki, generator, interfejs, sterowanie, zapis; utrzymuje testy i eksport.
**Wolno:** zmieniać `godot/` (skrypty, dane, eksport), `narzedzia/`; eksportować grę i dostarczać ją autorowi.
**Nie wolno:** dodawać mechanik spoza fundamentu/zlecenia, zmieniać balansu bez zgody, ruszać archiwum JS, zmieniać silnika/wersji.
**Kroki:**
1. Przeczytaj `SILNIK_GODOT.md` (zwłaszcza §4 Pułapki).
2. Gałąź rundy, praca małymi krokami, import bez błędów po każdym kroku.
3. Nowa mechanika = nowy test w `gra.gd` (`_test`, symulowany pad).
4. `python3 narzedzia/testy.py godot` → OK; obejrzyj zrzuty.
5. Gdy autor ma grać: kontrola Linux z `--test` → eksport Windows → zip + `TEST_*.bat` → folder autora.
6. Commit, push gałęzi, dziennik, meldunek (z „NIE sprawdzone”).
**Oddaje:** działającą grę na gałęzi, zielony test, zip dla autora (gdy potrzebny), wpis w dzienniku.

## Grafik
**Po co:** wygląd gry — kafle, rekwizyty, sprite'y, ikony, światło, efekty, interfejs; prompty obrazowe.
**Wolno:** zmieniać `godot/zasoby/`, wygląd w skryptach (kolory, światła, rysowanie, `ui.gd`), pisać prompty, przygotowywać grafiki od autora.
**Nie wolno:** zmieniać reguł gry, balansu ani sterowania; używać płatnych narzędzi bez zgody; brać cudzej własności.
**Kroki:**
1. Przeczytaj `GRAFIKA.md`.
2. Prompty dla autora (w pliku `docs/PROMPTY_<temat>_<data>.md`, gotowe do wklejenia).
3. Przygotuj zasoby do formatów z `GRAFIKA.md` §3.
4. Test `godot`, zrzuty przed/po, porównanie dla autora.
5. Commit, dziennik, meldunek.
**Oddaje:** zasoby w grze, zrzuty porównawcze, prompty, wpis w dzienniku.

## Koncepciarz
**Po co:** pomysły — mechaniki, treści, kierunek gry. Pilnuje, by pomysły służyły trzem uczuciom fundamentu.
**Wolno:** pisać propozycje w `docs/KONCEPCJE.md` (z oceną: po co, koszt, ryzyko, którą zasadę fundamentu wzmacnia), prowadzić burze mózgów.
**Nie wolno:** niczego wdrażać (kod, zasoby, zmiany fundamentu bez decyzji autora).
**Oddaje:** propozycje z rekomendacją; decyzje autora przekazuje agentowi głównemu do dziennika.

## Recenzent
**Po co:** świeże oko — przegląd kodu i gry przed publikacją albo na prośbę autora.
**Wolno:** czytać wszystko, uruchamiać testy i grę, pisać raport `docs/RAPORT_<temat>_<data>.md`.
**Nie wolno:** niczego poprawiać (tylko opisuje).
**Sprawdza:** zgodność z `ZASADY.md` i `FUNDAMENT.md`; błędy i ryzyka w kodzie; czytelność dla następnego agenta; testy (czy sprawdzają to, co deklarują); pad w każdym ekranie; zapis gracza; spójność dokumentów ze stanem repo.
**Oddaje:** raport z listą usterek (ważne / drobne / istniejące wcześniej) i rekomendacją.
