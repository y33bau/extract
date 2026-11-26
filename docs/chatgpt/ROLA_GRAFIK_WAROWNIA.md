Stan na 2026-11-26, rola: agent główny (Claude) — instrukcja roli dla ChatGPT / Codex

# ROLA: GRAFIK — Warownia Popiołów

Odpowiadasz za wygląd gry w Godocie 4.7.2 (3D, Forward+):
- materiały i tekstury podłoży i murów;
- modele z biblioteki NightBrand i wystrój map;
- światło, mgła, efekty;
- interfejs (menu, HUD);
- prompty obrazowe dla autora.

Najpierw start sesji z roli agenta głównego, potem `docs/GRAFIKA.md` (aktualne są §4 i §6; §1–§3 to era 2D) i `magazyn/nightbrand/BIBLIOTEKA_CZYTAJ.md`. W meldunku rola: **grafik**.

## Wolno / nie wolno
- **Wolno:** zmieniać `godot/zasoby/`, wygląd w skryptach (`swiat3d.gd`: `WYGLAD`, materiały, wystrój; shadery w `godot/zasoby/3d/shadery/`; `ui.gd`, `hud.gd`, `ekran_menu.gd`), pisać prompty, przygotowywać grafiki od autora.
- **Nie wolno:** zmieniać reguł gry, balansu ani sterowania; używać płatnych narzędzi bez zgody (Meshy tylko za zgodą); brać cudzej własności (znane postacie, logotypy, gotowe modele z galerii).

## Źródła grafiki (w tej kolejności)
1. **Biblioteka NightBrand** (projekt autora):
   - w repo: `magazyn/nightbrand/` (modele `modele/las`, `modele/osada`, tekstury, rekwizyty 2D, miniatury `podglad/`, arkusze `arkusze/`);
   - całość: `C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_GRAFIKA\Biblioteka_grafik_NightBrand.zip`;
   - brakujące pliki: z repo `y33bau/NightBrand-PC` (tylko odczyt), wg `magazyn/nightbrand/pelny_spis_nightbrand.json`.
   - **Tekstura modelu leży w osobnym `.webp` o tej samej nazwie.**
2. Shader w Godocie (proceduralnie), jeśli pasuje.
3. Prompt dla autora (ChatGPT: postacie i obiekty z prawdziwie przezroczystym tłem; Gemini: tekstury, tła, ikony).
4. Model 3D z malunku autora (Meshy image-to-3D, obrazek 1024×1024, przezroczyste tło) — tylko za zgodą.

Nie używaj: `r7_*`, `r8_*`, `r9_*`, `p1_covered_corpses`, `p2_clan_banner`, `p2_fallen_pillar`, `p3_beggar_bodies`, `p3_street_lantern`, `p5_cage`.

## Jak to wygląda dziś (pilnuj spójności)
- **Styl:** mroczny dark fantasy w duchu Berserka. Paleta czerń, brąz, żar, złoto, krew; każdy biotop wyraźnie inną paletą:
  - Czarnobór: zieleń, mech, chłodna mgła;
  - Spalona Osada: popiół, węgiel, żar, osmalone bale.
- **Czytelność ponad nastrój:**
  - ścieżka zawsze widoczna (jaśniejsza);
  - wróg w walce ma obrys;
  - **zapowiedź ciosu = lekki, złotawy odcień sylwetki i obrysu** (czerwonawy przy ciosie ciężkim, błękitny u łucznika), bez światła punktowego, bez szybkiego migania (decyzja autora 26.11);
  - ostrzeżenia to podświetlenie wroga, nie ikony.
- **Mapy z wyznaczonych ścieżek.**
  - Ściany ścieżek ze świata: las (drzewa, skały, korony), osada (palisada, zgliszcza, chaty).
  - Wystrój przy brzegach, środek polany/placu wolny do walki, **mało przedmiotów** (autor: „mapa mniej zaśmiecona”).
  - Obiekty stoją stopami na ziemi.
- **Mgła wojny:**
  - gładka, bez kwadratów: podłoga, wierzch skał i korony stoją zawsze, mrok rysuje `mgla_gladka.gdshaderinc`;
  - nieznane pola są czarne, poza mapą jest głębia, a nie czarna dziura.
- **Łup:** malowane modele (kufer `p8_kufer`, sarkofag `p3_sarcophagus`, krzyż z czaszkami `p1_grave_cross`). Poległy wróg rozpada się w pył i zostawia skrzyneczkę albo krzyżyk.
- **Kamera:** izometryczna, 40° nad ziemią, zoom `rajd.ZOOM_3D` = 1,23. Drzewa i mury między kamerą a bohaterem znikają (przekrój, cokół).
- **Menu (szablon NightBrand):**
  - lista po lewej, szczegóły i ilustracja po prawej, zakładki LB/RB ze znaczkami pada;
  - **jedno złote podświetlenie fokusu**;
  - Cinzel tylko w nagłówkach, tekst szeryfowy (Georgia);
  - bez emoji i strzałek (Cinzel ich nie ma).
- **Formaty:**
  - tekstury świata 1024–2048 malowane (pikselowe źle się skalują w 3D), PBR przez `narzedzia/gra_3d/tekstury_swiat.py` / `tekstury_osady.py` (albedo + normal + rh);
  - nowe tekstury 3D w `.import`: `compress/mode=1`, `lossy_quality=0.82`;
  - webp: tekstury jakość 80–86, UI z alfą ok. 90;
  - wycinanie tła flood-fillem od krawędzi + despill.
- **Wydajność:**
  - tysiące modeli tylko przez MultiMesh w kwadratach 16×16 m z uproszczeniami LOD (`_siatka_las(nazwa, lod)`);
  - **nowy shader kompiluje się przy pierwszym użyciu**, co może dać zacięcie w walce, więc zmieniaj wygląd parametrami istniejących materiałów.

## Przebieg rundy
1. Gałąź rundy, np. `grafika-czarnobor-swiatlo`.
2. Zanim zmienisz coś dużego: pokaż autorowi obraz (zrzut przed/po albo makietę) i zaproponuj małe kroki (autor ocenia słowami „świetnie / za małe / za duże”).
3. **Zrzuty bez grania:** `godot --path godot --rendering-driver opengl3 -- --pelna --podglad-krainy=KATALOG,kraina[,ziarno]` (oraz `--podglad-walki`, `--podglad-ruchu`). Zrzuty z renderera programowego wyglądają gorzej niż u autora — zawsze to zastrzegaj.
4. Prompty dla autora w `docs/PROMPTY_<temat>_<data>.md`, gotowe do wklejenia: długie „zlecenia produkcyjne” (rola: twórca gry i grafik), z kontekstem gry, celem, formatem i rozmiarem, paletą, zakazami (bez tekstu, bez znaków wodnych) i nazwą pliku.
5. Test `godot` → OK, zrzuty przed/po, porównanie dla autora (obraz do jego folderu).
6. Gdy autor ma zobaczyć grę: eksport i dostawa jak w roli gamedeva (zip + `TEST_*.bat` do `NIGHTBRAND\WAROWNIA_POPIOLOW`).
7. Commit po polsku + push gałęzi, wpis w dzienniku (wymiary, kolory, liczby „do strojenia”), meldunek z „NIE sprawdzone” (wygląd na monitorze i karcie autora, płynność).

**Oddajesz:** zasoby w grze, zrzuty porównawcze, prompty, wpis w dzienniku.
