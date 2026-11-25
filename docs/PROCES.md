Stan na 2026-11-25, rola: agent główny

# PROCES PRACY — jak przebiega sesja i runda

Ten plik mówi **krok po kroku**, co robisz od pierwszego promptu do końca sesji. Zasady (czego nie wolno) są w `ZASADY.md`; tu jest kolejność działań.

---

## 1. Start sesji — lista kontrolna (zawsze, w tej kolejności)

| # | Krok | Jak | Gdy się nie uda |
|---|---|---|---|
| 1 | **Repo** | Podepnij `y33bau/extract` z dostępem do zapisu (w Claude: narzędzie dodawania repo, `owner: y33bau`, `repo: extract`, `access: push`), sklonuj płytko: `git clone --depth 1 https://github.com/y33bau/extract /home/claude/extract`. | Powiedz autorowi, czego brakuje (np. połączenia GitHub w ustawieniach Claude). **Nie zaczynaj pracy.** |
| 2 | **Folder autora** | Sprawdź połączony folder `C:\Users\Admin\Desktop\NIGHTBRAND` (narzędzia `remote-devices`: lista folderu). Gra autora: `...\NIGHTBRAND\WAROWNIA_POPIOLOW`. Jeśli folderu nie ma w sesji — poproś o dostęp narzędziem do prośby o folder. | Napisz autorowi: „otwórz ten czat w aplikacji Claude na komputerze i wybierz *Dodaj folder* → `NIGHTBRAND`”. Pracuj w repo, ale nie obiecuj dostarczenia gry. |
| 3 | **Skille** | Na liście skilli sesji szukaj `warownia-start`, `warownia-gamedev`, `warownia-grafik`. Załaduj `warownia-start`, potem skill roli, którą przyjmujesz. | Czytaj role z `docs/ROLE.md` i powiedz autorowi, że skille trzeba dodać na tym koncie (treść w `docs/ROLE.md`). |
| 4 | **Czytanie** | `docs/START_TUTAJ.md` → `docs/ZASADY.md` → `docs/FUNDAMENT.md` → 3 najnowsze wpisy `docs/DZIENNIK.md` → ten plik → plik swojego obszaru. | — |
| 5 | **Stan repo** | `git fetch --depth=50 origin`, `git branch -a`, `git log --oneline -8 --all`, `git status`. Ustal, na której gałęzi jest najnowsza praca (dziennik mówi, od której zaczynać). | Rozbieżność dziennik ↔ git zgłoś autorowi. |
| 6 | **Środowisko** | `godot --version` (ma być 4.7.2). Brak → zainstaluj według `SILNIK_GODOT.md` §8. | Jeśli instalacja się nie uda — zgłoś, nie przechodź na inny silnik. |
| 7 | **Test bazowy** | `python3 narzedzia/testy.py godot` na gałęzi startowej, zanim cokolwiek zmienisz. | Czerwony test przed Twoją pracą = zgłoś autorowi w pierwszej wiadomości. |
| 8 | **Pierwsza wiadomość** | Według wzoru z §5: stan, wynik testu bazowego, plan sesji, pytania. | — |

## 2. Runda — od zlecenia do meldunku

1. **Zrozum zlecenie.** Sprawdź, czy służy `FUNDAMENT.md` i mieści się w zakresie v1. Jeśli nie — powiedz to i zapytaj, zanim zaczniesz.
2. **Wybierz rolę** (`ROLE.md`). Jedna rola zmienia kod w rundzie.
3. **Plan.** Przy zadaniu większym niż drobna poprawka: krótki plan dla autora (co zmienisz, czego nie ruszysz, jak sprawdzisz). Przy zadaniu jasnym i taniego do cofnięcia — zacznij od razu, plan w pierwszej wiadomości.
4. **Gałąź.** `git checkout -b <nazwa-rundy>` od gałęzi wskazanej w dzienniku.
5. **Praca małymi krokami.** Po każdym kroku: import (`godot --headless --path godot --import`) — zero błędów `SCRIPT ERROR`/`Parse Error`.
6. **Test mechaniki.** Nowa mechanika = nowy krok w `_test` w `gra.gd` (symulowany pad).
7. **Testy:** `python3 narzedzia/testy.py godot` → `OK`. Obejrzyj zrzuty ekranu (ścieżka w wyniku testu).
8. **Eksport (gdy autor ma grać):** kontrola Linux z `--test` → eksport Windows → zip z `TEST_*.bat` → do folderu autora (`ZASADY.md` E7).
9. **Commit i push gałęzi** (po polsku, z dopiskiem współautorstwa).
10. **Dziennik:** wpis na górze `docs/DZIENNIK.md`.
11. **Meldunek** dla autora (§6).
12. **Publikacja tylko na „publikuj”** (§7).

## 3. Dziennik — wzór wpisu

```
## RRRR-MM-DD GG:MM — [konto / agent], rola: [agent główny / gamedev / grafik / koncepciarz / recenzent]
- Gałąź i commit:
- Zrobione:
- Testy (godot) i wynik:
- NIE sprawdzone:
- Decyzje autora:
- Następny krok:
```
Dziennik jest dla następnego agenta, który nic nie wie. Pisz konkretnie: nazwy plików, liczby, ścieżki.

## 4. Przekazanie między kontami

Projekt krąży między 2–3 kontami. Nic nie żyje w pamięci rozmowy — wszystko w repo.
- Przed końcem sesji: commit + push gałęzi, wpis w dzienniku z polem „Następny krok”.
- Jeśli zmieniłeś zasady/strukturę — zaktualizuj `START_TUTAJ.md` §3 (stan na dziś).
- Decyzje autora z rozmów głosowych przepisz do dziennika (i do `FUNDAMENT.md`, jeśli zmieniają fundament).
- Nie zostawiaj niezacommitowanych zmian. Jeśli praca jest w połowie — commit z dopiskiem „W TOKU” i opis w dzienniku.

## 5. Pierwsza wiadomość sesji — wzór

```
Rola: [rola]. Repo podpięte (gałąź X, ostatni commit Y), folder: [jest/brak], skille: [są/brak].
Stan wg dziennika: [1–2 zdania]. Test bazowy: [OK n/n | BŁĄD: …].
Plan na sesję: [2–4 punkty].
Pytania: [tylko te, które naprawdę wymagają decyzji autora].
```

## 6. Meldunek po rundzie — wzór

1. **Wynik w jednym zdaniu** (co działa / co dostał autor, gdzie leży plik).
2. **Co zrobione** — krótka lista, językiem gracza, nie programisty.
3. **Sprawdzone** — testy i wynik.
4. **NIE sprawdzone** — zawsze (prawdziwy pad, dźwięk, komputer autora, itch.io…).
5. **Jedna polecana następna rzecz** z uzasadnieniem.

## 7. Publikacja (tylko na „publikuj” / „wrzucaj”)

1. Autor zagrał w wersję z gałęzi (zasada `ZASADY.md` D5) i powiedział „publikuj”.
2. `git fetch`, upewnij się, że gałąź zawiera `origin/main` (jeśli nie — rebase według instrukcji sesji).
3. `git checkout main && git merge --ff-only <gałąź> && git push origin main`.
4. Wpis w dzienniku: „Opublikowano na main: commit …”.
5. Zaktualizuj `START_TUTAJ.md` §3.

## 8. Role — skrót (pełny opis w `ROLE.md`)

| Rola | Co robi | Czy zmienia kod |
|---|---|---|
| Agent główny | Start sesji, plan rund, decyzje z autorem, dokumenty, przekazanie, publikacja | Tylko dokumenty |
| Gamedev | Mechaniki, generator, interfejs, testy, eksport | Tak |
| Grafik | Kafle, sprite'y, oprawa, światło, prompty obrazowe | Tak (zasoby + wygląd) |
| Koncepciarz | Pomysły i propozycje mechanik w `KONCEPCJE.md` | Nie |
| Recenzent | Przegląd kodu i gry, lista usterek i ryzyk | Nie |
