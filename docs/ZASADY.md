Stan na 2026-11-25, rola: agent główny

# KODEKS PROJEKTU — ZASADY NIENARUSZALNE

To jest prawo projektu Warownia Popiołów. Obowiązuje każdego agenta na każdym koncie, w każdej sesji, bez wyjątków.
**Złamanie którejkolwiek zasady = runda nie jest skończona**, nawet jeśli gra działa.
Jeśli zasada blokuje pracę albo wydaje się błędna: zatrzymaj się, opisz problem autorowi i zapytaj. Nie obchodź jej.

Hierarchia przy sprzeczności: **decyzja autora w czacie > ten kodeks > `FUNDAMENT.md` > `SILNIK_GODOT.md` / `PROCES.md` / `GRAFIKA.md` / `NARZEDZIA.md` > najnowszy wpis `DZIENNIK.md` > `KONCEPCJE.md` > reszta.**
Decyzja autora, która zmienia kodeks albo fundament, musi zostać wpisana do odpowiedniego pliku w tej samej sesji.

---

## A. START SESJI (zanim zmienisz cokolwiek)

**A1. Podepnij repo `y33bau/extract`.** Bez repo nie zaczynasz pracy. Jeśli nie możesz go podpiąć, powiedz autorowi dokładnie, czego brakuje, i czekaj.
**A2. Podepnij folder autora** `C:\Users\Admin\Desktop\NIGHTBRAND` (gra w podfolderze `WAROWNIA_POPIOLOW`). Bez folderu możesz pracować w repo, ale nie dostarczysz gry — powiedz o tym autorowi na starcie.
**A3. Załaduj skill swojej roli** (`warownia-start`, potem `warownia-gamedev` / `warownia-grafik`). Jeśli skilli nie ma na tym koncie, czytasz role z `docs/ROLE.md` i mówisz autorowi, że skille trzeba dodać.
**A4. Przeczytaj w kolejności:** `START_TUTAJ.md` → `ZASADY.md` (ten plik) → `FUNDAMENT.md` → 3 najnowsze wpisy `DZIENNIK.md` → `PROCES.md` → plik swojej roli/obszaru (`SILNIK_GODOT.md`, `GRAFIKA.md`, `NARZEDZIA.md`).
**A5. Sprawdź stan komendami, nie z pamięci:** `git fetch`, `git branch -a`, `git log --oneline -8`, `git status`. Porównaj z dziennikiem. Rozbieżność zgłoś autorowi.
**A6. Zanim cokolwiek zmienisz, uruchom test bazowy** (`python3 narzedzia/testy.py godot`). Jeśli jest czerwony przed Twoją pracą — zgłoś to, nie naprawiaj po cichu.
**A7. Pierwsza wiadomość do autora:** krótki stan (gałąź, ostatni wpis dziennika, wynik testu bazowego) + plan sesji + pytania. Dopiero potem praca.

## B. FUNDAMENT I ZAKRES

**B1. Każda funkcja służy `FUNDAMENT.md`**: strach (o ekwipunek i życie), adrenalina (walka Soulsborne), dopamina (łup, ekstrakcja, postęp). Jeśli funkcja nie wzmacnia żadnego z trzech uczuć — nie wchodzi.
**B2. Zakres pierwszej wersji jest zamknięty:** dwa biotopy (Spalona Osada, Czarnobór — decyzja autora 26.11.2026; Dolne Miasto później) z bossami; mapy 128×128 m, rajd 20 min, jeden bohater (Hadræn, broń = klasa), mysz+klawiatura ORAZ pad, PC. **Bez kooperacji, bez zadań fabularnych, bez pozostałych biotopów.** Poszerzenie zakresu tylko decyzją autora.
**B3. Najpierw fundament, potem funkcje.** Nie dodajesz mechanik spoza fundamentu ani niezamówionych przez autora — nawet „małych”, nawet „przy okazji”. Pomysł zapisujesz w `KONCEPCJE.md` i pytasz.
**B4. Balans i liczby ustalone z autorem są nietykalne** bez jego zgody. Nowe liczby (pierwsze przymiarki) oznaczasz w dzienniku jako „do strojenia”.
**B5. Niezamówionych rzeczy nie ruszasz.** Usterkę poza zakresem zgłaszasz w meldunku i pytasz, czy naprawić.

## C. TECHNIKA

**C1. Silnik: Godot 4.7.2, GDScript, renderer Forward+** (decyzja autora 25.11.2026: grafika 3D jakości AAA; awaryjnie Compatibility, gdy brak Vulkana). Nie zmieniasz wersji silnika, renderera ani języka bez decyzji autora. Nie dodajesz C#/.NET.
**C2. Gra działa offline** po rozpakowaniu i dwukliku. Zero zależności od internetu w działającej grze.
**C3. Pad działa wszędzie** — w walce, w menu, w Warowni, w oknach. Każdy nowy ekran musi dać się obsłużyć samym padem (fokus, A zatwierdza, B wraca). Mysz i klawiatura też wszędzie.
**C4. Akcje sterowania definiujesz tylko w `godot/skrypty/sterowanie.gd`.** Nigdzie indziej nie sprawdzasz klawiszy ani przycisków „na sztywno”.
**C5. Ziarno daje ten sam loch.** Wszystko, co dotyczy układu, łupów i wrogów, losujesz ze strumieni `mapa.rng_uklad` / `rng_lup` / `rng_wrogowie`. `randf()` wolno tylko dla efektów kosmetycznych (cząsteczki, migotanie).
**C6. Reguły gry w jednym miejscu:** walka, łup, ekstrakcja i śmierć liczą się w `rajd.gd`; `bohater.gd` i `wrog.gd` trzymają stan i wygląd. Nie rozpraszasz reguł po węzłach wizualnych.
**C7. Dane gry w `godot/dane/*.json`**, nie w kodzie. Nowy plik JSON = dopisz go do `include_filter` eksportu.
**C8. GDScript z typami.** Wartości ze słowników typujesz jawnie (`var x: float = d["y"]`). Kod po polsku (nazwy zmiennych, komentarze), czytelny dla następnego agenta.
**C9. Nie wymyślasz API Godota z pamięci.** Gdy nie masz pewności, sprawdzasz w dokumentacji 4.7 (docs.godotengine.org/en/4.7) albo małym testem w środowisku. Składnia Godota 3 jest zakazana.
**C10. Nie łamiesz zapisu gracza.** Zmiana struktury zapisu = podbicie wersji pliku zapisu i migracja starego zapisu (albo świadoma decyzja autora o resecie).

## D. JAKOŚĆ I TESTY

**D1. `python3 narzedzia/testy.py godot` musi dać `WYNIK (godot): OK`** po każdej zmianie. Czerwony test = runda nieskończona.
**D2. Nowa mechanika = nowy test** w `godot/skrypty/gra.gd` (`_test`), najlepiej na symulowanym padzie.
**D3. Po każdej zmianie wizualnej oglądasz zrzuty ekranu** z testu i opisujesz, co widać.
**D4. Przed wysłaniem gry autorowi:** eksport „Linux (kontrola agenta)” i uruchomienie z `--test` — sprawdza, czy dane weszły do paczki. Dopiero potem eksport Windows.
**D5. Przed każdą publikacją na `main` gra autor**, także na padzie. Tylko on ocenia wyczucie.
**D6. Nie usuwasz ani nie osłabiasz testów**, żeby przeszły. Test niestabilny (zależny od czasu) przerabiasz na czekanie na warunek.

## E. PROCES I REPO

**E1. Każda runda na nowej gałęzi** od najnowszej opublikowanej bazy (albo od gałęzi wskazanej w dzienniku). Nazwa po polsku, opisowa: `runda-2-halas`, `grafika-spalona-osada`.
**E2. `main` tylko na wyraźne „publikuj” / „wrzucaj” autora.** Merge `--ff-only`. Gałęzie robocze wolno pushować.
**E3. W jednej rundzie kod zmienia jedna rola.** Koncepciarz i recenzent niczego nie wdrażają.
**E4. Dziennik:** czytasz przed pracą, dopisujesz przed końcem sesji (wpis na górze, według wzoru). Każda decyzja autora trafia do dziennika.
**E5. Nie commitujesz:** plików `.exe`, zipów, katalogu `godot/.godot/`, sekretów, plików autora spoza repo.
**E6. Commity po polsku**, z opisem co i dlaczego, z dopiskiem współautorstwa z instrukcji sesji.
**E7. Gra dla autora trafia do jego folderu** (`NIGHTBRAND\WAROWNIA_POPIOLOW`) jako zip z plikiem `TEST_*.bat` — nie tylko na czat.

## F. ETYKA PRACY

**F1. Prawda zamiast uspokajania.** W każdym meldunku piszesz, co zrobione, co sprawdzone i **czego NIE sprawdzono**.
**F2. Nie obiecujesz działania na prawdziwym padzie, w dźwięku, na itch.io ani na komputerze autora**, jeśli tego nie sprawdziłeś. Test symuluje pada — to nie to samo.
**F3. Nie udajesz, że coś działa.** Jeśli coś zawiodło, mówisz to wprost na początku meldunku.
**F4. Nie zgadujesz.** Stanu repo, wersji, zachowania gry nie bierzesz z pamięci ani ze starych dokumentów — sprawdzasz.
**F5. Szanujesz czas autora:** wynik najpierw, krótko, jedna polecana opcja z uzasadnieniem. Pytasz tylko o decyzje, które naprawdę należą do niego.
**F6. Rozmawiasz partnersko i szczerze.** Jeśli pomysł autora szkodzi grze, mówisz to i proponujesz lepszy — decyzja należy do niego.
**F7. Nie kopiujesz cudzej własności:** żadnych postaci, logotypów, muzyki ani tekstów chronionych prawem. Grafika pochodzi z NightBrand (projekt autora) albo jest generowana na jego zlecenie.

## G. KOMUNIKACJA Z AUTOREM

**G1. Po polsku**, prostym językiem. Autor jest początkujący w IT, ale świetnie rozumuje logicznie: tłumacz decyzje, nie żargon.
**G2. Nie każesz mu używać gita, terminala ani pisać skryptów.** Testy dla niego: pliki `TEST_*.bat` w jego folderze.
**G3. Dyktuje głosem** — literówki i skróty traktujesz życzliwie; gdy coś jest niejasne, pytasz krótko.
**G4. Nowy dokument w `docs/` zaczyna się linią** „Stan na RRRR-MM-DD, rola X”.
