Stan na 2026-11-25, rola: agent główny

# START TUTAJ: przekazanie dla nowego agenta

Jeśli jesteś nowym agentem (inne konto, nowa sesja), przeczytaj ten plik w całości, zanim cokolwiek zmienisz.

## 1. Czym jest projekt
**Warownia Popiołów**: izometryczny dark fantasy extraction RPG. Walka wręcz w stylu Soulsborne, łup i ryzyko w stylu Tarkova, rozbudowa Warowni między rajdami. Jeden bohater: Hadræn. Świat wspólny z grą NightBrand tego samego autora, ale z nowymi wątkami.
Pełny opis: `docs/FUNDAMENT.md` (to jest kompas: każda funkcja ma mu służyć).

## 2. Gdzie co jest
- Repo: `y33bau/extract`. `main` = wersja opublikowana przez autora; praca na gałęziach.
- Folder autora z grą: `C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_POPIOLOW\` (gra do grania + `TEST_WAROWNIA_POPIOLOW.bat`).
- Grafika źródłowa: folder `C:\Users\Admin\Desktop\NIGHTBRAND\` (projekt NightBrand). Arkusze bohaterów z nazwami: `bohaterowie_do_x2\` (plus `MAPA.json`). Wrogowie: `NightBrand-itch-test\assets\wrogowie\` (nazwy to hasze; wybrane już są w `zasoby/sprite/`).
- Zasady pracy, testów i dziennika: `CLAUDE.md`.
- Dziennik wszystkich agentów: `docs/DZIENNIK.md`.
- Pomysły autora z ocenami (nie wszystkie wchodzą do v1!): `docs/KONCEPCJE.md`.
- Tekst instrukcji do ustawień projektu Claude: `docs/INSTRUKCJE_PROJEKTU.md`.

## 3. Stan na dziś (sprawdź komendą `git log --oneline -5` i dziennikiem)
- Działający prototyp w JavaScript (canvas 2D): hub Warowni (skrytka, kupiec, 4 budynki, 5 umiejętności), rajd z ziarnem, walka (combo, parowanie, riposta, blok, unik, łuk, postura), pochodnia vs tarcza, zrzut sakwy, 6 typów wrogów + boss, ekstrakcja, śmierć z Relikwiarzem.
- Gałęzie nieopublikowane (`main` ich nie zawiera): `start-projektu`, `runda-1-walka`, `fundament-i-dziennik`.
- **Otwarta decyzja: silnik.** Wstępnie Godot, jeśli agent może go uruchamiać i testować automatycznie. Do decyzji NIE dodajemy nowych mechanik do wersji JS. Aktualny etap: patrz najnowszy wpis w dzienniku.

## 4. Jak budować i testować (wersja JS)
```
python3 narzedzia/zbuduj.py          # składa dist/WAROWNIA_POPIOLOW.html
python3 narzedzia/testy.py szybki    # po drobnej zmianie
python3 narzedzia/testy.py pelny     # po dużej zmianie (pełna pętla gry)
```
Wymaga: Python 3, `pip install playwright` + `python -m playwright install chromium`.

## 5. Jak rozmawiać z autorem
Po polsku, krótko, wynik najpierw, jedna polecana opcja. Jest początkujący w IT, ale bardzo logiczny: tłumacz decyzje, nie żargon. Nie każ mu używać gita. Zawsze pisz, czego NIE sprawdziłeś. Szczegóły w `CLAUDE.md`, sekcja „Autor”.

## 6. Na koniec sesji
Dopisz wpis na górze `docs/DZIENNIK.md` (wzór jest w pliku). Bez tego następny agent startuje w ciemno.
