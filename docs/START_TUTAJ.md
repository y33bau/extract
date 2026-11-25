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
- **Silnik: Godot 4.7.2** (decyzja autora 25.11.2026). Gra jest w `godot/`. Przeniesiono cały prototyp JS: Warownia (5 zakładek, kupiec, rozbudowa, umiejętności, skrytka, Relikwiarz), generator lochów z ziarna, rajd (walka combo, parowanie, riposta, blok, unik, łuk, postura, pochodnia vs tarcza, zrzut sakwy, 6 typów wrogów + boss, łucznicy, ciężkie ciosy z czerwonym błyskiem), światło 2D z silnika, mgła wojny, minimapa, okno łupów, ekstrakcja, śmierć, dźwięk (syntezator).
- Zgodnie z fundamentem: po śmierci zaliczana jest połowa doświadczenia z rajdu (w JS było 100%).
- Sterowanie: klawiatura+mysz i pad w każdym miejscu (menu też).
- Prototyp JS (`zrodlo/`) to archiwum.
- Gałęzie nieopublikowane (`main` ich nie zawiera): `start-projektu` → `runda-1-walka` → `fundament-i-dziennik` → `godot-pilot` → `godot-transfer` (każda zawiera poprzednią).

## 4. Środowisko agenta: jak budować i testować
```
# jednorazowo: Godot 4.7.2 (Linux) jako `godot` w PATH
curl -L -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip g.zip && mv Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot
# jednorazowo: szablony eksportu (1,3 GB, ok. 1 min); potrzebne tylko do .exe
curl -L -o t.tpz https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
mkdir -p ~/.local/share/godot/export_templates/4.7.2.stable
unzip -j t.tpz templates/version.txt templates/windows_release_x86_64.exe templates/linux_release.x86_64 -d ~/.local/share/godot/export_templates/4.7.2.stable/
pip install gdtoolkit            # linter (opcjonalnie)

python3 narzedzia/testy.py godot  # test pełnej pętli na symulowanym padzie (wymaga xvfb-run i Mesa)
godot --headless --path godot --export-release "Windows" ../dist/godot/Warownia_Popiolow.exe
```
Gra po uruchomieniu bez `--test` to normalna gra. W edytorze Godota otwórz folder `godot/`.

## 5. Jak rozmawiać z autorem
Po polsku, krótko, wynik najpierw, jedna polecana opcja. Jest początkujący w IT, ale bardzo logiczny: tłumacz decyzje, nie żargon. Nie każ mu używać gita. Zawsze pisz, czego NIE sprawdziłeś. Szczegóły w `CLAUDE.md`, sekcja „Autor”.

## 6. Na koniec sesji
Dopisz wpis na górze `docs/DZIENNIK.md` (wzór jest w pliku). Bez tego następny agent startuje w ciemno.
