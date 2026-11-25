# WAROWNIA POPIOŁÓW — zasady dla agenta (skrót)

Stan na 2026-11-25, rola: agent główny.

Izometryczny dark fantasy extraction RPG w Godocie 4.7.2: walka Soulsborne + łup i ryzyko jak w Tarkovie + rozbudowa Warowni. Lochy z ziarna. Jeden bohater, Hadræn.

**Ten plik to skrót. Pełne prawo projektu: `docs/ZASADY.md` (obowiązuje w całości).**

## Start sesji (zawsze, w tej kolejności) — szczegóły: `docs/PROCES.md` §1
1. **Repo** `y33bau/extract` podpięte z zapisem (bez repo nie zaczynasz).
2. **Folder autora** `C:\Users\Admin\Desktop\NIGHTBRAND` (gra dla autora → `WAROWNIA_POPIOLOW\`).
3. **Skille**: `warownia-start`, potem `warownia-gamedev` / `warownia-grafik`. Brak → `docs/ROLE.md` + informacja dla autora.
4. **Czytaj**: `docs/START_TUTAJ.md` → `docs/ZASADY.md` → `docs/FUNDAMENT.md` → 3 najnowsze wpisy `docs/DZIENNIK.md` → `docs/PROCES.md` → plik obszaru (`SILNIK_GODOT.md`, `GRAFIKA.md`, `NARZEDZIA.md`).
5. **Stan komendami**: `git fetch`, `git branch -a`, `git log --oneline -8 --all`, `git status`.
6. **Test bazowy** przed zmianami: `python3 narzedzia/testy.py godot` (Godot: `docs/SILNIK_GODOT.md` §8).
7. **Pierwsza wiadomość**: wzór w `docs/PROCES.md` §5.

## Najważniejsze zasady (pełne: `docs/ZASADY.md`)
- Każda funkcja służy `docs/FUNDAMENT.md`. Zakres v1 zamknięty: 2 biotopy, pad wszędzie, bez kooperacji i fabuły.
- Godot 4.7.2, GDScript z typami, Compatibility, offline. Prototyp JS (`zrodlo/`) = archiwum.
- Akcje sterowania tylko w `godot/skrypty/sterowanie.gd`. Reguły rajdu w `rajd.gd`. Dane w `godot/dane/*.json`.
- Ziarno = ten sam loch (strumienie `rng_uklad/rng_lup/rng_wrogowie`).
- Test `testy.py godot` → OK po każdej zmianie; nowa mechanika = nowy test.
- Gałąź na rundę; `main` tylko na „publikuj” / „wrzucaj” autora.
- Dziennik przed i po pracy. W meldunku zawsze „czego NIE sprawdzono”.
- Balansu, zakresu i niezamówionych rzeczy nie zmieniasz bez zgody autora. Nic płatnego i żadnych wtyczek bez zgody.
- Autor: po polsku, krótko, wynik najpierw, jedna polecana opcja; bez gita i terminala po jego stronie; testy jako `TEST_*.bat`.
