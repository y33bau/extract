Stan na 2026-11-25, rola: grafik

# GRAFIKA — styl, formaty i proces

## 1. Kierunek
**Mroczne dark fantasy w izometrii 2.5D**, malowany pixel-art w stylu postaci NightBrand. Ciemność jest domyślna, światło buduje klimat i czytelność walki. Gracz ma w każdej chwili wyraźnie widzieć: siebie, wroga, **zapowiedź ataku** (złoty / czerwony błysk), łup i drogę do wyjścia.

**Problem nr 1 do rozwiązania (pilot Spalonej Osady):** postacie są malowane i szczegółowe, a kafle otoczenia to gruby proceduralny piksel z prototypu JS. Dwa style obok siebie. Cel: kafle i rekwizyty malowane w tym samym stylu co postacie + **jedna gęstość pikseli** dla całej sceny.

## 2. Zasady nienaruszalne grafiki
1. Czytelność walki ważniejsza od ozdób: błysk ataku, pasek HP/postury i sylwetka wroga nie mogą ginąć w tle.
2. Postacie i rekwizyty z **przezroczystym tłem** (PNG/WebP z kanałem alfa), bez cieni wpalonych w tło (cień rysuje gra).
3. Kierunek światła w grafice: miękkie, z góry; mocne światło daje silnik (`PointLight2D`), nie malunek.
4. Bez cudzej własności: żadnych znanych postaci, logotypów, cudzych grafik. Źródła: zasoby NightBrand (projekt autora) albo grafiki generowane na zlecenie autora.
5. Każda nowa grafika jest sprawdzana na **zrzucie ekranu z gry** (test `godot`), nie tylko jako plik.
6. Nazwy plików: małe litery, ASCII, `snake_case` (`knight_d.webp`, `floor_0.png`).

## 3. Formaty

### Postacie (arkusze animacji)
| Arkusz | Siatka | Klatka w grze | Zawartość |
|---|---|---|---|
| Bohater `knight_d` | 4×6 | 128×128 | rzędy 0–2: postój przód/bok/tył; 3–5: chód przód/bok/tył |
| Bohater `knight_dc` | 4×6 | 128×128 | ciosy: 3 przód lekki, 4 przód ciężki, 5 bok, 0–2 tył |
| Bohater `knight_def` | 4×6 | 128×128 | rzędy 0–2 przód/bok/tył; klatka 0 = blok, 1 = parowanie |
| Bohater `knight_death` | 4×2 | 128×128 | 8 klatek upadku |
| Wróg `en_<rodzaj>` | 4×2 | 128×128 (boss 192×192) | rząd 0: chód 4 klatki; rząd 1: atak 3 klatki + klatka śmierci |

- Widok z boku **patrzy w prawo** (gra odbija w lewo).
- **Stopy na 93% wysokości klatki**, postać wyśrodkowana w poziomie.
- Skala w grze: bohater 0,82, wrogowie 0,8 (Kat Ruin 0,9, boss 0,95).
- Źródła NightBrand: arkusze 256 px w `C:\Users\Admin\Desktop\NIGHTBRAND\bohaterowie_do_x2\` (nazwy + `MAPA.json`), wrogowie w `NightBrand-itch-test\assets\wrogowie\` (nazwy plików to hasze). Do gry: zmniejszenie 2× (Lanczos), WebP jakość 88.
- Pozostali bohaterowie NightBrand (Kat, Zabójczyni, Dzwonnik, Woskownica) mają arkusze — przydadzą się jako wzór animacji broni (fundament: **broń jest klasą**).

### Otoczenie (kafle izometryczne)
| Element | Rozmiar pliku | Na ekranie | Punkt zaczepienia |
|---|---|---|---|
| Podłoga (romb) | 32×16 | 64×32 | góra rombu w punkcie kafla |
| Mur / filar | 32×36 | 64×72 | środek kafla, przesunięcie (-16, -28) |
| Kosz ogniowy | 32×28 | 64×56 | (-16, -20) |
| Gruz, skrzynie, sarkofag, szczątki | 32×24–26 | 64×48–52 | (-16, -16) |

To są wymiary **obecnego prototypu**. Pilot grafiki ustali nowe (najpewniej kafle malowane w 2× większej rozdzielczości, żeby gęstość pikseli zgadzała się z postaciami) — decyzja trafi tu i do dziennika.

Zestaw na biotop (minimum): 4–6 wariantów podłogi, ścieżka, krąg ekstrakcji, blok muru, mur z przejściem, mur z uchwytem pochodni, filar, 10–15 rekwizytów (w tym 3 pojemniki na łup), 1 kafel zagrożenia biotopu.

### Ikony przedmiotów
- 24×24 px PNG, przezroczyste tło, czytelna sylwetka, w `godot/zasoby/ikony/<id_przedmiotu>.png`.
- Rzadkość pokazuje ramka w interfejsie (kolor), nie sama ikona.

## 4. Kolory

### Biotopy pierwszej wersji
| Biotop | Paleta | Światło / atmosfera |
|---|---|---|
| Spalona Osada i Pogorzeliska | czerń, głęboka szarość, żarzący się pomarańcz w szczelinach | dym, iskry, popiół w powietrzu |
| Dolne Miasto i Gnijące Podgrodzie | zgniła zieleń, rdzawy brąz, zimny kamień | przyziemna mgła, wilgoć, trujące wyziewy |

### Światła w grze (obecne wartości)
| Źródło | Kolor | Promień |
|---|---|---|
| Pochodnia w ręce | (1.0, 0.78, 0.52) ciepłe | 270 px |
| Pochodnia na ziemi | (1.0, 0.78, 0.50) | 300 px |
| Kosz ogniowy | (1.0, 0.63, 0.27) | 195 px |
| Krąg ekstrakcji | (0.27, 0.92, 0.69) zielony runiczny | 210 px |
| Poświata bez pochodni | (0.6, 0.55, 0.75) chłodna | 105 px |
| Błysk ataku do parowania | złoty `#ffd666` | — |
| Błysk ciężkiego ciosu (tylko unik) | czerwony `#ff3d29` | — |

### Interfejs (`ui.gd`)
złoto `#e6ba63`, żar `#e07a38`, popiół (tekst) `#dcd6ce`, tło paneli `#1a171c`, rama `#352f38`.
Rzadkość: zwykły `#78736d`, niepospolity `#4ca676`, rzadki `#4d88c7`, epicki `#c79c4c`, legendarny `#d43f49`.

### Menu, pauza, przyciski (runda `menu-i-pauza`, 26.11.2026)
- **Czcionka całego interfejsu: Cinzel** (decyzja autora: „Cinzel”; ociekające napisy-obrazki z NightBrand odrzucone).
- **Zasoby z NightBrand wybrane przez autora** (`NIGHTBRAND\NightBrand_test_911\assets\ui`) → `godot/zasoby/ui/` (czytelne nazwy: `przycisk_drewno`, `przycisk_gotycki(_wybrany)`, `kula_*`, `rama_minimapy`, `slot`, `pasek_akcji`, `pad_*` (ikony przycisków pada), `zebatka`, `kursor`). Gotowe do rozciągania (9-slice) w `godot/zasoby/ui/9/`: `btn` / `btn_fokus` (gotycki: ciemna tablica, bordo przy fokusie), `akcja` / `akcja_fokus` (drewno z okuciami, fokus = żar), `tab` / `tab_wybrana` (zakładki), `slot` (ramka przedmiotu).
- Motyw: `Ui.motyw()` (jeden, wspólny): zwykłe przyciski = gotyckie, główne przyciski (`Ui.przycisk_akcji`) = drewniane z żarem, zakładki = drewniane (wybrana żarzy się), panele = ciemne płótno z cienką mosiężną ramą (tekstura panelu rozciągała się w smugi), sloty przedmiotów = nitowana ramka + nazwa w kolorze rzadkości.
- **Bez emoji i strzałek w napisach** — Cinzel ich nie ma (sprawdzone: brak →←↑↓✓✦), wyglądały archaicznie. Zamiast „↓” piszemy „krzyżak dół”.
- HUD rajdu (runda `hud-nightbrand`): kula życia, kula wytrzymałości (niebieska kula many z NightBrand), pasek akcji, zegar w drewnianym kole, minimapa w ramie; ikony HUD z `NightBrand_test_911\assets\ikony` → `godot/zasoby/ui/hud/`.

### Oprawa walki (runda `walka-oprawa`, 26.11.2026)
- **Czcionka walki: Cinzel** (SIL OFL, `godot/zasoby/czcionki/cinzel.ttf` + licencja, która jedzie w paczce). `Ui.czcionka(waga)` — grubość 400–900; klucz wariantu musi być liczbowym tagiem OpenType (tekstowy „wght” nie działa — sprawdzone testem).
- **Pasek wroga** (`Ui.rysuj_pasek`, `wrog.gd`): ciemne tło, brązowa rama, czerwone życie `#c4252f` z jaśniejszą górą, jasny „ślad” utraconego życia (dogania po 0,45 s). Postura jak w Sekiro: rośnie od środka, złoto → żar, pulsuje >75%. Pojawia się płynnie tylko w walce.
- **Riposta możliwa:** pulsujący złoty romb nad głową (zamiast napisu „★ RIPOSTA ★”). W 3D brak starego krążka z krzyżykiem — zamach pokazują klin, pierścień rytmu i błysk broni.
- **Boss:** pasek na dole ekranu (HUD, `hud.gd`), imię Cinzel, bez paska nad głową.
- **Napisy** (`efekty.gd`): liczby duże i „wyskakują”, komunikaty mniejsze; układanie piętrami wg położenia na ekranie; ten sam komunikat się nie dubluje, liczby zawsze osobno.
- **Cząsteczki:** wybuchy ≥6 cząstek idą do 3D (`swiat3d.czastki`): jasne = iskry z poświatą, ciemne = krople krwi z grawitacją; drobne 2D to miękkie kropki, nie kwadraty.
- **Mięso trafień** (`swiat3d.gd`, `rajd.gd` — tylko wygląd): zatrzymanie klatki zamraża też animacje, kierunkowe „kopnięcie” obrazu w stronę ciosu, płynny wstrząs zamiast losowego, krótkie przybliżenie przy ripoście/parowaniu/złamaniu postury, błysk ciała i wzdrygnięcie wroga (0,42 s, klip „trafienie”) z odchyleniem na sprężynie, czerwony/złoty błysk bohatera.
- **Czytelność:** krąg pod wrogiem w walce (ciemnoczerwony), ciepły krąg pod bohaterem, mocniejsze światło postaci bohatera (1,35).
- Podgląd dla agenta: `godot --path godot --rendering-driver vulkan -- --podglad-walki=/tmp/katalog[,kraina]` (seria zrzutów: cios, ciężki cios, zamach, parowanie, riposta, ból, śmierć).

### Las: Czarnobór (runda `las-w-rajdzie`, 26.11.2026)
- Źródło: magazyn NightBrand (`magazyn/nightbrand/`) → `godot/zasoby/3d/las/` (modele `.glb` + tekstura `.webp` o tej samej nazwie, runo 2D w `las/runo/`). Podłoże `zasoby/3d/swiat/las_*` (mech, ziemia, liście, skała = urwisko, mchy, błoto); mapy `normal` i `rh` wyliczone z jasności tekstury.
- Wysokości (m): świerk 4,6, sosna 5,0, brzoza 4,0, martwy dąb 3,6, martwy świerk 4,2; drzewa na polanach ×0,75; głaz 0,9. Bohater ok. 1,8.
- Ściana lasu: drzewo w każdym polu przy przejściu, co 2. pole dalej, co 3. w głębi (do 4 pól); runo paproci na skraju. Skały: moduły murów z teksturą urwiska.
- Wydajność: drzewo ma ok. 12,8 tys. trójkątów — w lesie stoją uproszczenia z importu Godota (LOD 1 ok. 3,2 tys. w dwóch pierwszych rzędach, LOD 2 ok. 1,3 tys. dalej, bez cieni); MultiMesh dzielony na kwadraty 16×16 m (karta pomija kwadraty poza kadrem).
- Mgła wojny: drzewo i podłoże pod nim są widoczne, gdy widać najbliższe pole przejścia (`_kotwica`). Drzewo między kamerą a bohaterem znika (jak mur obniżany do cokołu).
- Woda: płaskie pola z shaderem `woda.gdshader` (toń 0,035/0,08/0,085; bród jaśniejszy), dno obniżone.

## 5. Proces produkcji grafiki
1. **Grafik pisze prompty** (dla ChatGPT / Gemini — jak w NightBrand; narzędzia płatne typu PixelLab tylko za zgodą autora). Prompt zawsze zawiera: styl („dark fantasy painted pixel art, isometric 2:1”), widok, rozmiar siatki, przezroczyste tło, paletę biotopu, brak tekstu i podpisów.
2. **Autor generuje** i wrzuca pliki do swojego folderu (agent wskazuje ścieżkę, np. `NIGHTBRAND\WAROWNIA_GRAFIKA\spalona_osada\`).
3. **Grafik przygotowuje zasoby** w środowisku agenta: wycięcie z tła, siatka, skalowanie do formatu z §3, kontrola punktu stóp/zaczepienia, zapis do `godot/zasoby/...`.
4. **Podgląd w grze:** test `godot`, zrzuty ekranu, porównanie przed/po (obraz dla autora).
5. Decyzja autora → commit na gałęzi grafiki → dziennik.
6. Zasoby źródłowe w pełnej rozdzielczości zostają w folderze autora; do repo trafiają tylko wersje do gry.

## 6. Menu na wzór NightBrand (od 26.11.2026, etap 2 przebudowy menu)
- Instrukcja: `NIGHTBRAND\WAROWNIA_POPIOLOW\INSTRUKCJA_PRZEBUDOWY_MENU_WAROWNIA_2026-11-26.md` (mentor NightBrand); wzór: Kaplica NightBrand (`3_kaplica_lista_i_szczegoly.png` w `PAKIET_MENU_NIGHTBRAND.zip`).
- Zasoby: `godot/zasoby/ui/menu/` — z pakietu NightBrand (autor gry), przeskalowane skryptem `narzedzia/menu_zasoby.py` (ramki 9-slice: róg ok. 17–20 px przy 720p; tła 1280×720).
- Szablon ekranu: `godot/skrypty/ekran_menu.gd` (tło, nagłówek z separatorem, zakładki z LB/RB lub Q/E, panel listy 44% + szczegóły 56%, stopka). Klocki w `ui.gd`: `wiersz_listy`, `belka_sekcji`, `para`, `klawisz`, `zakladka_menu`, `przycisk_menu`, `styl_panelu_menu`, `styl_fokusu_wiersza`, paleta `M_*`.
- Czcionki: Cinzel tylko w tytułach, zakładkach, przyciskach, belkach i nazwie w szczegółach; tekst czytany szeryfem (`Ui.czcionka_tekstu()`: Georgia u autora, Liberation/DejaVu Serif w chmurze). Domyślna czcionka motywu = szeryf; `Ui.etykieta` z tekstem WIELKIMI literami = Cinzel.
- Jedno podświetlenie fokusu: bursztynowy gradient + złota ramka 1 px (wiersze) / jaśniejszy żar (zakładki, przyciski). „Wybrane” = ◆ i jaśniejszy tekst, nigdy biała ramka.
- Na szablonie: **Kram Margi**. Reszta ekranów Warowni — etap 3 (po ocenie autora).
