Stan na 2026-11-26, rola: agent główny

# PRZEKAZANIE — sesja 25.11 (23:57) – 26.11 (14:10), konto 2

Dla agenta na nowym koncie, który nic nie wie o tej sesji. Kolejność czytania: `START_TUTAJ.md` → `ZASADY.md` → `FUNDAMENT.md` → ten plik → 3 najnowsze wpisy `DZIENNIK.md`. Szczegóły każdej rundy są w dzienniku (najnowsze na górze).

## 1. Stan w jednym akapicie
`main` = `97c0c22` (opublikowane 26.11 o 00:06). Od tego czasu powstało **9 nieopublikowanych rund w jednym łańcuchu gałęzi — każda zawiera wszystkie poprzednie**:
`walka-oprawa` → `menu-i-pauza` → `mocny-cios-sklep` → `hud-nightbrand` → `namierzanie` → `magazyn-nightbrand` → `pilot-czarnobor` → `mapy-128` → **`las-w-rajdzie` (`9b582ad` i nowsze — ZACZYNAJ OD NIEJ)**.
Testy `testy.py godot`: **100/100 OK**; kontrola spakowanej gry (Linux `--test`): 100/100 OK. Ostatnia paczka dla autora: `NIGHTBRAND\WAROWNIA_POPIOLOW\Warownia_Czarnobor.zip` (`TEST_CZARNOBOR.bat`). Autor nie powiedział „publikuj” dla żadnej z tych rund — na „publikuj”: `git checkout main && git merge --ff-only las-w-rajdzie && git push origin main`.

## 2. ODKRYCIE: biblioteka grafik NightBrand — pracuj na niej
NightBrand ma **setki gotowych, malowanych grafik**, ale trudno je znaleźć: pliki mają nazwy z kodów SHA-256, a **tekstura każdego modelu 3D leży w osobnym pliku** (`.glb` bez tekstury + `.webp`; para jest opisana tylko w kodzie NightBrand: `nazwa:{g:'…glb',k:'…webp'}` w `zrodlo/main/06_three_siatki_rozdzialow.js`). Bez tej wiedzy modele wyglądają na białe bryły.
- **Pełna biblioteka pod czytelnymi nazwami** (202 modele 3D z teksturami i miniaturami, 91 tekstur, 118 obrazków 2D, 15 teł, gotowe podłoże lasu): u autora w `C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_GRAFIKA\Biblioteka_grafik_NightBrand.zip` (225 MB, opis `CZYTAJ.md` w środku). Pobierz ją narzędziem do plików urządzenia (`device_stage_files`) albo odtwórz: `python3 narzedzia/magazyn_nightbrand.py <klon NightBrand-PC> <wyjście>`.
- **W repo** (`magazyn/nightbrand/`, poza `godot/`, gra tego nie importuje): wybór pod biotopy v1 (81 modeli: las 63 + osada 18, 29 tekstur, 58 obrazków 2D), `pelny_spis_nightbrand.json`, arkusze podglądu `arkusze/`, opis `README.md` i `BIBLIOTEKA_CZYTAJ.md`.
- **Polecenie autora: nowe poziomy, oprawę i wystrój budujesz na tych teksturach i modelach** (zanim poprosisz o nowe grafiki albo użyjesz czegokolwiek innego). Kolejność źródeł przy brakach: reszta biblioteki → shader w Godocie → prompt dla autora (ChatGPT/Gemini) → model z malunku autora (TripoSG darmowy / Meshy płatny — tylko za zgodą) → CC0 z sieci tylko za zgodą. Gotowych modeli z galerii nie bierzemy (zasada autora z NightBrand).
- Nie używać: `r7_*`, `r8_*`, `r9_*` (bryły z Blendera zdjęte przez autora), oraz `p1_covered_corpses`, `p2_clan_banner`, `p2_fallen_pillar`, `p3_beggar_bodies`, `p3_street_lantern`, `p5_cage` (słabe, „do przeróbki”).
- Modele mają ok. 12,8 tys. trójkątów — przy dziesiątkach/tysiącach sztuk używaj uproszczeń z importu (§6, `_siatka_las(nazwa, lod)`).

## 3. Co zrobiono (chronologicznie)
| Godz. | Gałąź | Co | Ocena / decyzja autora |
|---|---|---|---|
| 23:57–00:06 | `mapy-runda-2` | Start sesji; renderer to **Forward+** (dokumenty mówiły Compatibility) | „Postacie są super”; **publikacja** `97c0c22` |
| 00:08–00:50 | `walka-oprawa` | Oprawa walki: paski HP/postury, romb riposty, pasek bossa, napisy Cinzel, iskry i krew 3D, hitstop, wstrząs i przybliżenie kamery, wzdrygnięcie wroga, kręgi pod postaciami, `--podglad-walki` | „Jest o wiele lepiej” |
| 01:00 | `walka-oprawa` | Warownia: kamera dalej (ZOOM 1,85 → 1,35) | decyzja autora |
| 01:02–01:35 | `menu-i-pauza` | Pauza (Esc/P/Start), sterowanie jak NightBrand, menu w grafikach NightBrand + Cinzel, bez emoji | „OK jak na betę, dopracujemy” |
| 01:36–01:50 | `mocny-cios-sklep` | Mocny cios (przytrzymaj ≥ 0,35 s), Kram Margi, atak RB | brak oceny |
| 01:57–02:10 | `hud-nightbrand` | HUD jak NightBrand (kule, pasek akcji, zegar, minimapa w ramie), wskaźniki walki | brak oceny |
| 02:12–10:45 | `namierzanie` | Namierzanie (R / środkowy / R3), klik na wroga = cios, riposta w najbliższego ogłuszonego, kursor nie obraca postaci, płynny ruch i parowanie, mniejsze znaczniki | brak oceny |
| 10:48–11:00 | dokumenty | Burza mózgów: sekcje gry + pętla i ekonomia; **kolejność: biotopy, bohater, moby, balans**; biotopy otwarte; mapy z wyznaczonych ścieżek (Dragon's Dogma) | decyzje → `FUNDAMENT.md` |
| 11:40 | `magazyn-nightbrand` | Pełny spis NightBrand, miniatury 202 modeli, wyciąg do `magazyn/nightbrand/` | prośba autora |
| 12:10 | `pilot-czarnobor` | Generator lasu `mapgen_las.gd` + mapy z góry (`--podglad-lasu`, `narzedzia/podglad_lasu.py`) | „Akceptuję” |
| 12:55 | `mapy-128` | **Wszystkie mapy 128×128 m, rajd 20 min**; komnaty, wrogowie, polany ×1,78 (ta sama gęstość) | decyzja autora; liczba wrogów do potwierdzenia |
| 13:40 | `las-w-rajdzie` | **Czarnobór grywalny**: kraina leśna, `K.WODA`, las 3D z zasobów NightBrand, LOD + kwadraty 16 m | czeka na test autora |
| 14:10 | `las-w-rajdzie` | Biblioteka grafik (§2), to przekazanie | — |

## 4. Decyzje autora (obowiązują)
- **Brak limitu wysyłki plików do folderu autora** (26.11, 14:02). Paczki z grą mogą być duże.
- **Wszystkie mapy 128×128 m, rajd 20 minut** (26.11, 11:40).
- Biotopy otwarte (lasy, kaniony, knieje, doliny), mapa z **wyznaczonych ścieżek jak w Dragon's Dogma** — nie za wąskich, nie za szerokich. Biotopy v1: **Spalona Osada + Czarnobór**; Dolne Miasto później.
- Kolejność prac (z burzy mózgów): biotopy → bohater → moby → balans. **Nowy plan autora (14:02): z nowym agentem walka, oznaczenia, balans i oprawa graficzna („kuleją”).**
- Cinzel = czcionka całego UI i walki; grafiki UI z `NIGHTBRAND\NightBrand_test_911\assets`; sterowanie jak NightBrand; mocny cios przez przytrzymanie; Warownia z kamerą dalej.
- Repo NightBrand-PC: tylko czytamy i bierzemy grafiki; **nic tam nie zmieniamy**.

## 5. Liczby robocze (czekają na ocenę autora — bez zgody nie zmieniaj)
- Wrogowie na mapę: Katakumby 60, **Czarnobór 56**, Podgrodzie 78, Krypta 89 (było 34/44/50 przy 96 m; skala z polem mapy).
- Komnaty lochu 64/57/60; polany lasu ok. 18–21; czas rajdu 1200 s.
- Czarnobór: ŚREDNIA, nagroda kontraktu 250; wrogowie zwiadowca 35%, łucznik 30%, strażnik 20%, osiłek 15% (obecne typy — wilki i kłusownicy w rundzie „moby”).
- Hitstop: cios 0,055 s, ciężki 0,085, riposta 0,15, złamanie postury 0,12, parowanie 0,15, otrzymany cios 0,06. Mocny cios: próg 0,35 s.
- Ścieżki lasu 4,5–6 m, polany o promieniu 5,5–8 m (łąki 9–11), 3–5 pętli, ≥ 2 ślepe odnogi, wyjścia ≥ 45% najdłuższej drogi.

## 6. Gdzie co jest w kodzie (nowe w tej sesji)
- `mapgen_las.gd` — las: `teren` (typy `T.*`, wygląd) i `siatka` (typy `Mapgen.K`, logika jak w lochu); polany → `komnaty`, ścieżki → `korytarze`, ogniska → `kosze` (`_dla_rajdu()`). Rajd wybiera generator po `"typ": "las"` w `krainy.json`.
- `mapgen.gd` — `ROZMIAR` 128, `K.WODA` (blokuje ruch, nie wzrok).
- `rajd.gd` — `var mapa` bez typu (loch albo las), więc **zmienne z `mapa.*` typuj jawnie** (`var t: int = mapa.kafel(...)`), inaczej błąd parsowania. Nazwy obszarów lasu w `NAZWY_OBSZAROW`; wrogowie lasu w tabelach `tabela`/`ciezcy`.
- `swiat3d.gd` — tryb `las`: `_pole_lasu` (podłoże, woda/bród/dno, drzewa, skały, runo), `_wystroj_lasu` (polany wg rodzaju), `_siatka_las(nazwa, lod)` (uproszczenie z importu Godota + odchudzenie wierzchołków), `_kwadrat()` (MultiMesh na kwadrat 16×16 m z `custom_aabb`), `_kotwica` (widoczność drzewa = widoczność najbliższego przejścia), przekrój drzew przed bohaterem w `odswiez_widok`. `WYGLAD["czarnobor"]`.
- Zasoby lasu: `godot/zasoby/3d/las/` (modele + tekstury `.webp`), `las/runo/` (2D), podłoże `zasoby/3d/swiat/las_*`.
- `gra.gd` — testy `_test_lasu` (generator, 5 ziaren) i `_test_czarnoboru` (rajd w lesie); podglądy: `--podglad-lasu=katalog[,ziarna]`, `--podglad=czarnobor,ZIARNO,katalog,woda|komnaty`, **`--pomiar=kraina`** (+ `--lekki`): klatki na sekundę z całością i bez grup siatek — tak znaleziono wąskie gardło drzew.
- Wcześniejsze moduły sesji (pauza, HUD, motyw, mocny cios, namierzanie): `pauza.gd`, `hud.gd`, `ui.gd`, `efekty.gd`, `rajd.gd`, `hub.gd` — opis w `DZIENNIK.md` (wpisy 00:50–10:45) i `GRAFIKA.md`.

## 7. Sterowanie (źródło: `sterowanie.gd`, lista dla gracza `Sterowanie.OPIS`)
| Czynność | Klawiatura i mysz | Pad |
|---|---|---|
| Ruch | WASD, strzałki (kursor nie obraca postaci; LPM na wroga = cios w niego) | lewy drążek |
| Cios (combo); przytrzymaj = mocny | LPM, J | X, RT, RB |
| Blok i parowanie | PPM, L | LB |
| Unik | Spacja, Shift | A |
| Rozmowa i przeszukiwanie | E, Enter | Y |
| Łuk | Q | B |
| Mikstury / pochodnia | 1-2-3 / F | krzyżak |
| Zrzuć sakwę / sakwa | G / Tab, I | L3 / Widok |
| Namierzanie | R, środkowy przycisk | R3 |
| Pauza | Esc, P | Start |

## 8. Pułapki odkryte w tej sesji
- Modele NightBrand: tekstura w osobnym `.webp` — nakładaj `StandardMaterial3D` (alpha scissor, bez odrzucania tylnych ścian).
- Tysiące modeli w jednym MultiMesh na całą mapę = karta rysuje wszystko w każdej klatce (las 0,7 kl/s). Dziel na kwadraty i ustaw `custom_aabb`. Instancje ze skalą 0 (mgła wojny) nadal kosztują.
- W lesie w środowisku agenta hamuje rysowanie dużych koron (zakrywanie pikseli), nie liczba trójkątów — dalsze cięcie trójkątów nic nie dało.
- Mgła wojny w lesie: drzewa w głębi nigdy nie są „widziane” → bez `_kotwica` ściana lasu ma czarne dziury.
- Test, który niczego nie sprawdził (0 elementów), też daje OK — sprawdzaj liczniki w opisie testu.
- Cinzel nie ma strzałek, ✓, ★ ani emoji → pisz słowami. Wariant wagi czcionki: liczbowy tag `name_to_tag("wght")`.
- Tryb `--test` renderuje lekko (pikseloza) — wygląd oceniaj podglądami z `--rendering-driver vulkan` (wymaga `mesa-vulkan-drivers`).
- Zip gry ma ok. 380–400 MB (eksport bierze wszystkie zasoby). Limitu już nie ma, ale warto wyłączyć z eksportu nieużywane pliki.
- Dostarczanie: `SendUserFile` → `device_commit_files` z `fileUuid`.

## 9. NIE sprawdzone (całość sesji)
Płynność na komputerze autora (zwłaszcza las: ponad 2000 drzew z cieniami, i 89 wrogów w Krypcie), prawdziwy pad, dźwięk, inne rozdzielczości niż 1280×720, czy 20 min wystarcza, czy walka na otwartych polanach nie jest za łatwa/za trudna. Autor nie ocenił jeszcze: mocny cios, Kram, HUD, namierzanie, las w grze.

## 10. Co dalej (plan autora z 14:02: walka, oznaczenia, balans, oprawa graficzna)
1. Najpierw poproś autora o wynik testu `Warownia_Czarnobor.zip` (płynność!) i o „publikuj” — wtedy nowa praca idzie od świeżego `main`.
2. **Walka**: zbierz od autora, co konkretnie „kuleje” (czytelność ciosów wroga, trafienia, ruch w walce, namierzanie). Narzędzia: `--podglad-walki`, `--podglad-ruchu`.
3. **Oznaczenia** (wskaźniki nad wrogami, zapowiedzi ataków, kręgi, napisy): `wrog.gd::_rysuj_nakladke`, `swiat3d.gd::_zapowiedz`, `efekty.gd`, `hud.gd`. Pokazuj warianty jako obrazy przed wdrożeniem.
4. **Balans**: liczby z §5 — tylko z decyzją autora, każdą zapisz w dzienniku.
5. **Oprawa graficzna**: buduj na bibliotece z §2 (np. Spalona Osada z grupy `r1_spalona_osada` + tekstur `br_*`; wystrój lochów z `partia8_malowane`).
6. Czeka też: runda „moby” (wilki, kłusownik-łucznik, elita lasu), aktywne umiejętności jak NightBrand (niezdecydowane).
