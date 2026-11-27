Stan na 2026-11-26 (23:30), rola: agent główny (Claude) — przekazanie dla ChatGPT / Codex

# WAROWNIA POPIOŁÓW — PRZEKAZANIE PROJEKTU DLA CHATGPT

Ten dokument jest dla Ciebie, ChatGPT (także w Codexie). **Do niedzieli przejmujesz pracę nad grą.** Autor chce, żebyś przede wszystkim **pilnował formy graficznej i spójności kodu**. Tak samo pracowaliśmy przy NightBrand.

Przeczytaj dokument w całości. Potem przeczytaj pliki w repo, w kolejności z §6. Role, w których pracujesz, są w osobnych plikach w `docs/chatgpt/` (§10).

**Repo jest jedynym źródłem prawdy.** Stanu gry nie zgadujesz z pamięci ani z tego dokumentu. Sprawdzasz go w gicie i w `docs/DZIENNIK.md` (najnowszy wpis na górze).

---

## 1. Gra w pigułce

- **Warownia Popiołów**: izometryczny, mroczny **extraction RPG** (dark fantasy) w prawdziwym 3D. Łączy trzy rzeczy:
  - walkę wręcz jak w grach Soulsborne (parowanie, blok, unik, postura);
  - łup i ryzyko jak w Tarkovie (wszystko, co niesiesz, możesz stracić);
  - rozbudowę Warowni, czyli bazy między wyprawami.
- **Jedno zdanie gry:** „Wchodzę w mrok, walczę o każdy krok, biorę więcej, niż powinienem, i ledwo wracam do domu.”
- **Trzy uczucia (kompas każdej decyzji):**
  - **strach** — o ekwipunek i życie;
  - **adrenalina** — walka;
  - **dopamina** — łup, udana ekstrakcja, postęp.
  - Funkcja, która nie wzmacnia żadnego z nich, nie wchodzi do gry.
- **Pętla gry:** Warownia (przygotowanie) → rajd 20 min na mapie 128×128 m z ziarna → ekstrakcja albo śmierć → Warownia (zakupy, rozbudowa).
- **Bohater:** jeden, Hadræn. **Broń jest klasą** (miecz, miecz z tarczą, dwuręczny, topór, glewia, pięści). Śmierć zabiera wszystko poza Relikwiarzem (mała bezpieczna kieszeń) i połową zdobytego doświadczenia.
- **Pierwsza wersja (zakres zamknięty):**
  - biotopy **Spalona Osada** i **Czarnobór** (knieja), każdy z bossem;
  - PC (Windows), mysz z klawiaturą **oraz pad wszędzie**;
  - bez kooperacji i bez zadań fabularnych;
  - Dolne Miasto i reszta biotopów dopiero później.
- **Mapy:** biotopy otwarte (las, wieś), a nie lochy. Gracz chodzi siecią **wyznaczonych ścieżek jak w Dragon's Dogma**: nie za wąskich, nie za szerokich. To samo ziarno daje tę samą mapę.

## 2. Inspiracja: NightBrand (poprzednia gra autora)

- **NightBrand** (dawniej Piętno Nocy) to poprzednia gra autora: roguelike dark fantasy w duchu Berserka, w JavaScripcie z three.js, wydawany na itch.io.
  - 5 bohaterów: Hadræn (Rycerz), Goran (Kat), Mira (Zabójczyni), Iwo (Dzwonnik), Milena (Woskownica).
  - 6 rozdziałów: I Spalona Osada, II Dolne Miasto, III Solne Nabrzeże, IV Upadły Złotogród, V Czarnobór, VI Cytadela Wierzycieli.
- **Warownia dzieli z NightBrand świat (lore), bohatera Hadræna i grafikę**, ale ma nowe wątki fabularne i inny gatunek. NightBrand to doświadczenie i magazyn grafiki, a nie wzór do kopiowania 1:1.
- **Repo NightBrand:**
  - `y33bau/NightBrand-PC` — z Warowni **tylko czytamy i bierzemy grafiki, niczego tam nie zmieniamy**;
  - `y33bau/nightbrand-backup` — kopia zapasowa;
  - `y33bau/nightbrand` — stara strona, zamrożona.
- **Co przeniesiono z NightBrand do Warowni:**
  - liczby walki: cios w fazach zamach → cięcie → powrót, nietykalność po trafieniu 0,45 s, okno parowania;
  - styl menu: lista po lewej, szczegóły po prawej, zakładki LB/RB, jedno złote podświetlenie fokusu, Cinzel tylko w nagłówkach, tekst szeryfowy;
  - **ostrzeżenia jako podświetlenie wroga, nie ikony**;
  - zasada „czytelność ponad nastrój”;
  - pad ma pierwszeństwo przed myszą;
  - dźwięki (mapa `SFX_SAMPLE_MAP` z `zrodlo/main/08_sprite_sheets.js`).
- **Wiedza do sięgnięcia w NightBrand-PC:**
  - `docs/PODRECZNIK_AGENTA.md` (mapa kodu, liczby, pułapki), `docs/STAN.md`, `docs/logi/`;
  - kod walki `zrodlo/main/12_walka.js`, wrogów `13_wrogowie.js`, pada i menu `24_pad_samouczek_bledy.js`, `27_menu_usprawnienia.js`;
  - tekstury modeli 3D: pary `nazwa:{g:'…glb',k:'…webp'}` w `zrodlo/main/06_three_siatki_rozdzialow.js`;
  - spis nazw: `docs/INDEKS_ASSETOW.json`.

## 3. Repozytoria, foldery i ścieżki

### Repozytoria (GitHub)
| Repo | Adres | Co |
|---|---|---|
| **Warownia (robocze)** | https://github.com/y33bau/extract | cała gra; tu pracujesz |
| NightBrand (źródło grafiki i wiedzy) | https://github.com/y33bau/NightBrand-PC | **tylko odczyt** |
| NightBrand kopia | https://github.com/y33bau/nightbrand-backup | nie dotyczy Warowni |

Klon NightBrand, na którym Codex pracował u autora: `C:\Users\Admin\Desktop\A D R I A N\Projekt GPT\PietnoNocy\work\NightBrand-PC`. Klon Warowni możesz założyć obok, na przykład `...\Projekt GPT\Warownia\extract` (to propozycja, ten folder jeszcze nie istnieje).

### Folder autora (Windows)
Główny folder: `C:\Users\Admin\Desktop\NIGHTBRAND\`
| Ścieżka | Co tam jest |
|---|---|
| `NIGHTBRAND\WAROWNIA_POPIOLOW\` | **paczki gry dla autora** (zip z `Warownia_Popiolow.exe` + `TEST_*.bat`), instrukcje mentora (`ZADANIE_*`, `OCENA_*`, `INSTRUKCJA_PRZEBUDOWY_MENU_WAROWNIA_2026-11-26.md`), `PAKIET_MENU_NIGHTBRAND.zip`, zrzuty porównawcze |
| `NIGHTBRAND\WAROWNIA_GRAFIKA\Biblioteka_grafik_NightBrand.zip` | **pełna biblioteka grafik NightBrand** pod czytelnymi nazwami (225 MB): 202 modele 3D z teksturami i miniaturami, 91 tekstur, 118 obrazków 2D, 15 teł, opis `CZYTAJ.md` w środku (kopia także w `WAROWNIA_POPIOLOW\`) |
| `NIGHTBRAND\NightBrand_test_912\assets\dzwieki\` | dźwięki NightBrand (nazwy to hasze; nazwy czytelne w `SFX_SAMPLES`, NightBrand-PC `zrodlo/main/08_sprite_sheets.js`) |
| `NIGHTBRAND\NightBrand_test_911\assets\` | grafiki UI (`ui\`) i ikony HUD (`ikony\`) wybrane przez autora |
| `NIGHTBRAND\GRAFIKI_SWIAT.zip` | źródło tekstur podłóg i murów lochów (nazwy hasze; mapa: `narzedzia/gra_3d/tekstury_swiat.json`) |
| `NIGHTBRAND\bohaterowie_do_x2\` | arkusze postaci 2D NightBrand (`MAPA.json`) — archiwum ery 2D |
| `NIGHTBRAND\NightBrand-itch-test\assets\wrogowie\` | arkusze wrogów 2D (hasze) |
| `NIGHTBRAND\meshy\`, `modele_meshy\`, `NOWE MODELE\`, `WAROWNIA_POPIOLOW\3D modele warownia\`, `WAROWNIA_POPIOLOW\PILOT_3D\` | modele z Meshy i nowe modele autora (**nie sprawdzałem zawartości**) |
| `NIGHTBRAND\WAROWNIA_POPIOLOW\PRZEKAZANIE_CHATGPT\` | ten dokument i instrukcje ról (kopie z repo `docs/`) |

### W repo Warowni
| Ścieżka | Co |
|---|---|
| `godot/` | **gra (projekt Godota)**; scena główna `godot/gra.tscn` → `skrypty/gra.gd` |
| `godot/skrypty/` | cały kod (opis w §7) |
| `godot/dane/*.json` | dane: `krainy.json`, `przedmioty.json`, `umiejetnosci.json`, `warownia.json`, `wyglad_bohatera.json` |
| `godot/zasoby/3d/postacie/` | Hadræn, 6 wrogów, 4 NPC (`.glb` z Meshy, animacje Mixamo) |
| `godot/zasoby/3d/las/` | **modele biblioteki NightBrand w grze** (las + osada + łup), każdy `.glb` z teksturą `.webp` o tej samej nazwie; runo 2D w `las/runo/` |
| `godot/zasoby/3d/swiat/` | tekstury PBR podłoży i murów (`<nazwa>_albedo.jpg`, `_normal.png`, `_rh.png`): `kat_*`, `pod_*`, `kry_*`, `las_*`, `os_*` |
| `godot/zasoby/3d/shadery/` | `teren`, `mur`, `otoczenie`, `mgla`, `woda`, `obrys`, `czastka`, `wyostrz` + wspólny `mgla_gladka.gdshaderinc` |
| `godot/zasoby/dzwieki/` | 31 próbek NightBrand pod czytelnymi nazwami |
| `godot/zasoby/ui/` | grafiki menu i HUD (`ui/menu/`, `ui/hud/`, `ui/9/`) |
| `magazyn/nightbrand/` | wybór z biblioteki pod biotopy v1 (poza `godot/`, gra tego nie importuje), `pelny_spis_nightbrand.json`, `katalog.json`, `arkusze/`, `podglad/` (miniatury), `BIBLIOTEKA_CZYTAJ.md` |
| `narzedzia/` | `testy.py` (test), `gra_3d/` (potok tekstur i modeli: `tekstury_swiat.py`, `tekstury_osady.py`), `magazyn_nightbrand.py`, `podglad_lasu.py`, `podglad_osady.py`, `paczka_czesci.py`, `menu_zasoby.py` |
| `docs/` | dokumenty projektu (§6) |
| `zrodlo/` | **archiwum** dawnej wersji JS (nie rozwijamy) |

## 4. Zasady projektu (skrót; pełny kodeks `docs/ZASADY.md` obowiązuje w całości)

Hierarchia przy sprzeczności: **decyzja autora w czacie > `ZASADY.md` > `FUNDAMENT.md` > `SILNIK_GODOT.md` / `PROCES.md` / `GRAFIKA.md` / `NARZEDZIA.md` > najnowszy wpis `DZIENNIK.md` > `KONCEPCJE.md` > reszta.**

1. **Najpierw fundament, potem funkcje.** Nie dodajesz mechanik spoza `FUNDAMENT.md` ani niezamówionych, nawet „małych przy okazji”. Pomysł zapisujesz w `KONCEPCJE.md` i pytasz.
2. **Balansu i liczb ustalonych z autorem nie zmieniasz bez jego zgody.** Zgoda na oprawę to nie zgoda na balans. Nowe liczby oznaczasz w dzienniku „do strojenia”. Usterki poza zakresem zgłaszasz, a nie naprawiasz po cichu.
3. **Każda runda na nowej gałęzi** (nazwa po polsku, np. `grafika-czarnobor-swiatlo`). **`main` tylko na wyraźne „publikuj” / „wrzucaj” autora**, merge `--ff-only`. Gałęzie robocze wolno pushować.
4. **Po każdej zmianie test musi dać `WYNIK (godot): OK`.** Nowa mechanika = nowy test w `godot/skrypty/gra.gd` (`_test`). Testów nie osłabiasz, żeby przeszły.
5. **Pad działa w każdym ekranie.** Akcje sterowania definiujesz **tylko** w `godot/skrypty/sterowanie.gd` (klawiatura/mysz **i** pad).
6. **To samo ziarno = ta sama mapa.** Układ, łup i wrogów losujesz ze strumieni `rng_uklad` / `rng_lup` / `rng_wrogowie`. `randf()` / `randi()` tylko do kosmetyki.
7. **Reguły gry w jednym miejscu:** walka, łup, ekstrakcja i śmierć w `rajd.gd`; stan i wygląd w `bohater.gd`, `wrog.gd`, `swiat3d.gd`. Dane w `godot/dane/*.json`.
8. **Godot 4.7.2, GDScript z jawnymi typami, renderer Forward+.** Nie wymyślasz API z pamięci: sprawdzasz w dokumentacji 4.7 albo małym testem. Składnia Godota 3 jest zakazana. Bez C#.
9. **Gra dla autora:** zip z `TEST_*.bat` w jego folderze `NIGHTBRAND\WAROWNIA_POPIOLOW`. Przedtem kontrola spakowanej gry (eksport Linux + `--test` albo eksport Windows + `--test`).
10. **Dziennik:** czytasz przed pracą, dopisujesz wpis na górze przed końcem sesji. Każda decyzja autora trafia do dziennika.
11. **W jednej rundzie kod zmienia jedna rola i jeden wykonawca** (albo ChatGPT/Codex, albo Claude). Recenzent i koncepciarz niczego nie wdrażają.
12. **Nigdy nie obiecujesz działania na prawdziwym padzie, w dźwięku, na itch.io ani na komputerze autora bez sprawdzenia.** W każdym meldunku piszesz, **czego NIE sprawdzono**.
13. **Nic płatnego i żadnych wtyczek w repo bez zgody autora.** NightBrand-PC tylko czytasz.
14. **Grafika świata najpierw z biblioteki NightBrand.** Dopiero gdy czegoś brakuje, kolejno: shader w Godocie → prompt dla autora (ChatGPT/Gemini) → model z malunku autora (Meshy/TripoSG tylko za zgodą). **Gotowych modeli z galerii nie bierzemy.**
15. Nowy dokument w `docs/` zaczyna się linią „Stan na RRRR-MM-DD, rola X”. Kod i komentarze po polsku, identyfikatory bez polskich znaków.

## 5. Jak pracujemy (autor i agenci)

### Autor
- Rzeczoznawca majątkowy, w IT początkujący, ale bardzo logiczny („jestem twórcą, nie programistą”). Często dyktuje głosem, więc literówki traktuj życzliwie, a w razie wątpliwości dopytaj jednym zdaniem.
- **Rozmawiacie po polsku, partnersko i szczerze.** Jest przełożonym w projekcie, ale też kolegą. Jeśli jego pomysł szkodzi grze, powiedz to i zaproponuj lepszy. Decyzja należy do niego.
- **Odpowiedź: wynik najpierw, krótko, jedna polecana opcja z uzasadnieniem.** Termin techniczny tłumaczysz jednym zdaniem.
- **Nie każesz mu używać gita, terminala ani pisać skryptów.** Testy dla niego to pliki `TEST_*.bat`.
- Ocenia wygląd słowami „świetnie / za małe / za duże / kuleje”. Zmiany proponuj małymi krokami i **pokazuj obraz** (zrzut przed/po) zanim wdrożysz coś dużego w grafice.
- Zwykle odpowiada „tak”, „pasuje”, „publikuj”. Długie polecenia przerywa, więc dziel pracę na krótkie kroki i melduj często.

### Rytm rundy
1. Autor zleca (często listą uwag po zagraniu).
2. Agent sprawdza, czy zlecenie służy fundamentowi. Proste zlecenie od razu robi, przy kosztownym albo niejasnym pyta jednym pytaniem.
3. Gałąź → małe kroki → test po każdym kroku → zrzuty ekranu dla siebie i porównanie dla autora.
4. Eksport → zip z `TEST_<TEMAT>.bat` → folder autora `NIGHTBRAND\WAROWNIA_POPIOLOW`.
5. Commit i push gałęzi, wpis w dzienniku, **meldunek**.
6. Autor gra i ocenia. Mówi „publikuj” → merge do `main` (ff-only) → wpis w dzienniku i aktualizacja `docs/START_TUTAJ.md` §3.

### Meldunek po rundzie (wzór)
1. Wynik w jednym zdaniu (co działa, gdzie leży plik).
2. Co zrobione, językiem gracza, nie programisty.
3. Co sprawdzone (testy, wynik).
4. **Czego NIE sprawdzono** (prawdziwy pad, dźwięk, karta graficzna autora, płynność, itch.io).
5. Jedna polecana następna rzecz.

### Pierwsza wiadomość sesji (wzór)
```
Rola: [rola]. Repo: [gałąź, ostatni commit]. Folder autora: [jest/brak].
Stan wg dziennika: [1–2 zdania]. Test bazowy: [OK n/n | BŁĄD …].
Plan: [2–4 punkty]. Pytania: [tylko decyzje autora].
```

### Wpis w dzienniku (wzór; najnowszy na górze `docs/DZIENNIK.md`)
```
## RRRR-MM-DD GG:MM — [konto / agent], rola: […]
- Gałąź i commit:
- Zrobione:
- Testy (godot) i wynik:
- NIE sprawdzone:
- Decyzje autora:
- Następny krok:
```

### Podział pracy Claude ↔ ChatGPT
- Do niedzieli **Ty prowadzisz projekt**: jesteś agentem głównym, pilnujesz grafiki i spójności kodu, a w razie potrzeby pracujesz jako gamedev albo grafik.
- Jeśli autor równolegle uruchomi Claude, obowiązuje zasada **jeden wykonawca kodu na rundę**. Drugi agent robi wtedy przegląd, dokumentację albo prompty. Nie pracujcie na tej samej gałęzi naraz.
- Przy zmianie wykonawcy: commit + push gałęzi i wpis w dzienniku z polem „Następny krok”. Niedokończona praca dostaje commit „W TOKU”.

## 6. Kolejność czytania na start
`docs/START_TUTAJ.md` → `docs/ZASADY.md` → `docs/FUNDAMENT.md` → **ten plik** → 3 najnowsze wpisy `docs/DZIENNIK.md` → `docs/PROCES.md` → plik obszaru:
- `docs/SILNIK_GODOT.md` (architektura, konwencje, **§4 pułapki**, test, eksport, instalacja);
- `docs/GRAFIKA.md` (styl, formaty, kolory, menu, las);
- `docs/NARZEDZIA.md`;
- opcjonalnie `docs/pilot_czarnobor/README.md` i `docs/pilot_osada/README.md` (generatory map);
- `magazyn/nightbrand/BIBLIOTEKA_CZYTAJ.md` (biblioteka grafik).

Uwaga: część starszych akapitów `GRAFIKA.md` (§1–§3: „pixel-art 2.5D”, kafle 64×32) opisuje **erę 2D**. Od 25.11 gra jest w 3D. Aktualne są §4 (oprawa walki, las), §6 (menu) i dziennik.

## 7. Mapa kodu (`godot/skrypty/`)
| Plik | Rola |
|---|---|
| `gra.gd` | scena główna, przejścia Warownia ↔ rajd, **wszystkie testy (`_test`)** i podglądy dla agenta (`--podglad-*`, `--pomiar`) |
| `rajd.gd` | **reguły rajdu**: walka (fazy ciosu, parowanie, riposta, postura, nietykalność), wrogowie (AI, rozstawienie), łup, zwłoki, ekstrakcja, śmierć, pole widzenia i mgła wojny (`_licz_widok`) |
| `swiat3d.gd` | **cały wygląd rajdu w 3D**: materiały wg krainy (`WYGLAD`), mapa z MultiMeshy (kwadraty 16×16 m), las (`_pole_lasu`), osada (`_pole_osady`), wystrój, mgła (`odswiez_widok`, `_krok_mgly`), przekrój murów i drzew przed bohaterem, postacie, obrys i zapowiedź ciosu wroga, rozpad poległych w pył |
| `mapgen.gd` / `mapgen_las.gd` / `mapgen_osada.gd` | generatory: lochy (stare), Czarnobór, Spalona Osada. Wspólny interfejs: `siatka` (typy `K`), `komnaty`, `korytarze`, `skrzynie`, `ekstrakcje`, `kosze`, `spawny` |
| `bohater.gd`, `wrog.gd` | stan postaci (typy wrogów w `wrog.gd → TYPY`) |
| `korekta_chodu.gd` | modyfikator szkieletu: kolana Hadræna pod biodrami w ruchu |
| `przystan.gd`, `hub.gd` | Warownia-Przystań w 3D (NPC: Marga, Chojrak, chłop, przewoźnik) i jej menu |
| `ekran_menu.gd`, `ekran_tytulowy.gd`, `pauza.gd`, `okno_lupu.gd`, `hud.gd`, `ui.gd` | menu na szablonie NightBrand, HUD, motyw (`Ui.*`) |
| `sterowanie.gd` | **jedyne miejsce akcji sterowania** (klawiatura, mysz, pad, ukrywanie kursora przy padzie) |
| `dzwiek.gd` | próbki NightBrand (`PROBKI`) + syntezator zapasowy |
| `profil.gd`, `dane.gd` | zapis gracza, ustawienia (jakość grafiki 0–3), dane z JSON |
| `iso.gd` | rzut izometryczny 2D ↔ świat; **kąt kamery `KAT_KAMERY` = 40°** (`KAFEL_H` = 64·sin kąta) — kamera 3D i rzut 2D muszą mieć ten sam kąt |

## 8. Środowisko i polecenia

- **Godot 4.7.2.** Linux: instalacja w `SILNIK_GODOT.md` §8. Windows: `Godot_v4.7.2-stable_win64.exe` z github.com/godotengine/godot/releases.
- **Pierwszy import po klonie:** `godot --headless --path godot --import` (bez `SCRIPT ERROR` / `Parse Error`).
- **Test:**
  - Linux: `python3 narzedzia/testy.py godot` (wymaga `xvfb-run`; trwa ok. 3–5 min);
  - Windows (bez xvfb): `godot --path godot -- --test --zrzuty=C:\tmp\zrzuty --zapis=C:\tmp\zapis.json`.
  - Wynik: linia `WYNIK (godot): OK (n/n)`. **Dziś: 157/157 na gałęzi `poprawki-autora-1`.**
- **Eksport:** z katalogu `godot/`:
  - `godot --headless --path . --export-release "Windows" ../dist/godot/Warownia_Popiolow.exe`;
  - kontrola: preset „Linux (kontrola agenta)” + uruchomienie z `-- --test`.
  - Szablony eksportu 4.7.2 trzeba pobrać (`SILNIK_GODOT.md` §8).
- **Paczka dla autora:** zip (`Warownia_Popiolow.exe` + `TEST_<TEMAT>.bat`) do `NIGHTBRAND\WAROWNIA_POPIOLOW`.
  - Zip ma ok. 155 MB.
  - Jeśli przesyłasz przez narzędzie z limitem, dziel `narzedzia/paczka_czesci.py`.
  - Windows ostrzeże o „nieznanym wydawcy”; uprzedź autora.
- **Podglądy wyglądu dla agenta** (zrzuty bez grania):
  - `--podglad-krainy=katalog,kraina[,ziarno]` (kilka miejsc mapy);
  - `--podglad-walki=katalog[,kraina]` (seria klatek ciosu, parowania, śmierci);
  - `--podglad-ruchu=katalog`;
  - `--podglad-lasu` / `--podglad-osady` (mapy z góry, rysuje `narzedzia/podglad_*.py`);
  - `--pomiar=kraina` (klatki na sekundę).
  - Dodaj `--pelna`, by renderować w jakości Ultra.
  - Bez karty graficznej las w Ultra liczy się bardzo długo.
- **Ustawienia tekstur 3D:** nowe pliki w `zasoby/3d/**` mają mieć w `.import` `compress/mode=1` i `compress/lossy_quality=0.82` (inaczej paczka puchnie do ok. 400 MB).
- **Zapis gracza:** `%APPDATA%\Godot\app_userdata\Warownia Popiolow\warownia_zapis_v1.json`. Zmiana struktury zapisu wymaga migracji albo decyzji autora.

## 9. Stan projektu i raport z działań

### Stan na 26.11.2026, 23:30
- **`main` = `32087d1`** (opublikowane 26.11, 21:25): menu NightBrand, walka uczciwa, mapa z mgłą, Czarnobór, Spalona Osada, łup w modelach biblioteki, rozpad poległych w pył, szersze pole widzenia.
- **Gałąź `poprawki-autora-1` (`aaf2236`), NIEopublikowana**, czeka na ocenę autora (paczka `Warownia_Poprawki2.zip`):
  - chód bez rozkroku (`korekta_chodu.gd`);
  - zapowiedź ciosu jako lekki złotawy odcień i obrys, bez światła punktowego i bez migania;
  - drzewa przy ścieżce w pełnej siatce (jakość Wysoka/Ultra) z wygładzonymi liśćmi, szerszy przekrój drzew;
  - gładka mgła wojny bez kwadratów (`mgla_gladka.gdshaderinc`);
  - dźwięki NightBrand, ściszone −5 dB;
  - **kamera 40° (było 30°) i oddalona o 15%** (`Iso.KAT_KAMERY`, `rajd.ZOOM_3D = 1.23`).
  - Na „publikuj”: `git checkout main && git merge --ff-only poprawki-autora-1 && git push origin main`.
- Testy: 157/157 (także w spakowanej grze).

### Raport z sesji 25–26.11 (szczegóły w `DZIENNIK.md`)
| Kiedy | Co zrobiono | Ocena autora |
|---|---|---|
| 25.11 | Przejście z wersji JS na **Godota 4.7.2 w 3D (Forward+)**; Hadræn, 6 wrogów i NPC z Meshy + animacje Mixamo; Warownia-Przystań w 3D | „Postacie są super” |
| 26.11 rano | Oprawa walki (paski, hitstop, krew, kręgi), pauza, menu, HUD NightBrand, mocny cios, Kram Margi, namierzanie | „jest o wiele lepiej” |
| 26.11 11:00 | Decyzje: biotopy otwarte, ścieżki jak Dragon's Dogma, **mapy 128×128 m, rajd 20 min**, biotopy v1 = Osada + Czarnobór | decyzje autora |
| 26.11 12–14 | Magazyn grafik NightBrand, generator lasu, **Czarnobór grywalny** | „Akceptuję” |
| 26.11 15–17 | Walka i oznaczenia (zapowiedź ciosu, riposta, mniejszy HUD); **całe menu na szablonie NightBrand** (Warownia, pauza, łup, wynik, ekran tytułowy) | „jak na obecny etap świetne” |
| 26.11 18–19 | Mapa: płynna mgła, głębia poza mapą zamiast czerni, korytarze 3 pola, mniej przedmiotów, paczka 405 → 137 MB; walka uczciwa (fazy ciosu, nietykalność, stamina, max 2 wrogów w zamachu, obrys wroga) | „ocena pozytywna” |
| 26.11 19:45 | **Pilot Spalonej Osady** (generator wsi: plac ze studnią, zagrody, kuźnia, stodoła, sad, cmentarz, piwnica, spalony kościół, 30–34 spalone chaty z wejściem) | „pasuje” |
| 26.11 20:20 | **Osada w rajdzie**: palisady, chaty z bali z żarem, deski, płoty, groby, studnia, szubienica, wóz; w co trzeciej chacie lokator | „bardzo dobre” |
| 26.11 21:00 | Łup w malowanych modelach (kufer, sarkofag, krzyż z czaszkami) zamiast pikselowych brył; **poległy rozpada się w pył i zostawia skrzyneczkę lub krzyżyk**; pole widzenia 13/8 m, wróg w walce widoczny do 12 m | „bardzo dobre”, **opublikowane** |
| 26.11 22:25–23:00 | Poprawki autora (gałąź `poprawki-autora-1`, opisane wyżej) | czeka na ocenę |

### Otwarte sprawy (kolejność wg autora i dziennika)
0. **Ekonomia, przedmioty i łup (27.11):** `docs/KONCEPCJE_EKONOMIA.md`. Autor przyjął ją jako kierunek, a nie gotowy plan. Kolejność rund w §7: broń i pancerz → bossowie i moby → hałas → łup → wyjścia i Zmrok. Przed każdą rundą balansu zgoda autora.
1. **Ocena `Warownia_Poprawki2.zip`**:
   - czy mgła jest gładka;
   - czy zniknęły zacięcia przy podświetleniu wrogów (przyczyna to przypuszczenie: kompilacja osobnego shadera, już usuniętego);
   - jak autor ocenia kamerę 40°.
   - Potem „publikuj”.
2. **Boss Spalonej Osady** w spalonym kościele (arena gotowa: najgłębsza ślepa odnoga, promień ≥ 9 m). Potem boss Czarnoboru.
3. **Moby biotopów:** wilki, kłusownik-łucznik, elita lasu; moby osady. Dziś wrogowie to 6 starych typów (`scout`, `warden`, `archer`, `knight`, `brute`, `boss`).
4. **Decyzja autora:** ukryć stare lochy (Katakumby, Podgrodzie, Krypta) i użyć ich jako piwnic/krypty osady?
5. **Czekają na autora:**
   - ocena walki (jego punkt 8);
   - lista poprawek map „na później”;
   - obrazy do menu z `docs/PROMPTY_MENU.md`;
   - wibracja pada i pauza po odłączeniu pada;
   - podpis paska pancerza i rozrzut liczb obrażeń.
6. **Liczby do strojenia** (bez zgody nie zmieniaj):
   - wrogowie na mapę 60/56/56/78/89 (Katakumby / Czarnobór / Osada / Podgrodzie / Krypta);
   - nagrody kontraktów 40/60/150–400;
   - pole widzenia 13/8/12 m;
   - lokator w co trzeciej chacie;
   - siła korekty chodu 0,75;
   - głośności w `dzwiek.gd → PROBKI`.

### NIE sprawdzone (całość)
- Gra na prawdziwym padzie i z dźwiękiem na komputerze autora.
- Płynność na jego karcie przy drzewach LOD0.
- Wygląd na prawdziwej karcie (zrzuty agenta są z renderera programowego).
- Celowanie myszą i łukiem przy nowym kącie kamery.
- Inne rozdzielczości niż 1280×720.
- Czy 20 minut rajdu wystarcza.

## 10. Twoje role (osobne pliki do wklejenia jako instrukcje)
W `docs/chatgpt/`:
| Plik | Rola | Zmienia kod? |
|---|---|---|
| `ROLA_AGENT_GLOWNY_WAROWNIA.md` | prowadzenie projektu, start sesji, plan rund, dokumenty, publikacja | tylko dokumenty |
| `ROLA_GAMEDEV_WAROWNIA.md` | mechaniki, generator, interfejs, sterowanie, testy, eksport | tak |
| `ROLA_GRAFIK_WAROWNIA.md` | wygląd: materiały, światło, modele z biblioteki, shadery, UI, prompty | tak (zasoby i wygląd) |
| `ROLA_RECENZENT_WAROWNIA.md` | przegląd kodu i gry, spójność, ryzyka | nie |
| `ROLA_MENTOR_NIGHTBRAND.md` | ocena i podpowiedzi z doświadczenia NightBrand, zadania dla wykonawcy | nie |

W meldunku zawsze podawaj rolę. W jednej rundzie kod zmienia jedna rola.

## 11. Pułapki (najważniejsze; pełna lista `SILNIK_GODOT.md` §4 i `PRZEKAZANIE_2026-11-26.md` §8)
- Wartości ze słowników typuj jawnie (`var x: float = d["y"]`), bo inaczej pojawia się błąd parsowania i autoload pada. `floorf()` / `floori()` zamiast `floor()`. Zmienna `rajd.mapa` nie ma typu (loch, las albo osada).
- **Modele NightBrand mają teksturę w osobnym `.webp`.** Nakładaj materiał (`swiat3d._mat_las`). Tysiące modeli tylko przez MultiMesh w kwadratach 16×16 m z `custom_aabb` i uproszczeniami LOD (`_siatka_las(nazwa, lod)`).
- **Mgła wojny:**
  - podłoga, wierzch skał i korony stoją zawsze;
  - mrok rysuje shader z mapy jasności (`_jasn_tex`, `_zalezne`);
  - mury, drzewa i rekwizyty pojawiają się wg pola (skala 0 → pełna).
  - Nie wracaj do pokazywania podłogi kaflami: warstwa chmur mgły (shader z głębią) zaczyna wtedy rysować kwadraty.
- **Nowy shader = kompilacja przy pierwszym użyciu = możliwe zacięcie w walce.** Zmiany wyglądu w trakcie gry rób parametrami istniejących materiałów.
- Kamera 3D i rzut 2D (`iso.gd`) muszą mieć ten sam kąt. Zmieniając kąt, zmieniaj `Iso.KAT_KAMERY` i `KAFEL_H` razem.
- Test, który niczego nie sprawdził (0 elementów), też daje OK, więc sprawdzaj liczniki w opisie testu. W testach czekaj na warunek (`_czekaj_az`), a nie na sekundy.
- Cinzel nie ma strzałek, ✓, ★ ani emoji, więc pisz słowami.
- Modeli nie używać: `r7_*`, `r8_*`, `r9_*`, `p1_covered_corpses`, `p2_clan_banner`, `p2_fallen_pillar`, `p3_beggar_bodies`, `p3_street_lantern`, `p5_cage`.
