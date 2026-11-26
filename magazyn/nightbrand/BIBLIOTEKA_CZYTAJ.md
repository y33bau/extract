Stan na 2026-11-26, rola: grafik

# Biblioteka grafik NightBrand dla Warowni Popiołów

Wszystkie grafiki świata z gry NightBrand (wersja 911) pod czytelnymi nazwami. W NightBrand pliki mają nazwy z kodów SHA-256, a tekstury modeli 3D leżą w osobnych plikach, dlatego trudno je było znaleźć. Tutaj każdy model ma obok siebie swoją teksturę o tej samej nazwie.

## Co jest w środku
| Folder | Ile | Co |
|---|---|---|
| `modele_3d/` | 202 | modele `.glb`; obok każdego plik `.webp` o tej samej nazwie = jego malowana tekstura (170 modeli ma teksturę) |
| `modele_3d/_miniatury/` | 202 | podgląd każdego modelu z teksturą |
| `tekstury/` | 91 | podłoża, ściany, dachy, woda, atlasy; sufiks = rozmiar w pikselach (np. `cc0_forestmoss_2048`) |
| `rekwizyty_2d/` | 118 | obrazki 2D: trawy, paprocie, trzciny, grzyby, kwiaty, ogniska, płonące domy |
| `tla/` | 15 | ilustracje (intro, rozdziały) |
| `podloze_warowni_las/` | 18 | gotowe podłoże lasu Warowni (albedo + normal + rh) zrobione z tekstur NightBrand |
| `arkusze_podgladu/` | 6 | wszystko na kilku obrazach |
| `spis.json` | | nazwa → plik źródłowy w NightBrand (`gra/assets/...`) |

## Grupy modeli
- `r1_spalona_osada` (p1): studnia, szubienice, nagrobki, koła, martwy koń, wóz Margi, chorągiew zakonu
- `r2_dolne_miasto` (p2): kowadło, miechy, posąg króla, wózek górniczy, latarnia runiczna
- `r3_zlotogrod` (p3): fontanna królowej, szubienica z klatką, wozy, sarkofag, latarnia
- `r4_czarnobor` (p4): **drzewa** (świerk, sosna, brzoza, martwe dęby i świerki, święty dąb, drzewo wisielców), omszały głaz, kurhan, obóz (namiot, skóry, drewno, wóz), bożek
- `r5_cytadela` (p5): biurka, regały, tron, skarbiec, posągi, klatka
- `partia8_malowane` (p8): 66 nowszych modeli z malunków autora — grzyby, kłody, korzenie, kapliczki, menhiry, ogniska, płoty, bramy, kufry, księgi
- `odrzucone_bryly_blendera` (r7–r9): **nie używać** — autor zdjął je z NightBrand
- `inne_stare`: stare bryły zastępcze bez tekstur

## Zasady
- Modele i tekstury pochodzą z gry autora: wolno ich używać w Warowni. W NightBrand niczego nie zmieniamy.
- Skala: model ma wysokość ok. 1 jednostki, w grze skalujemy do realnej wysokości w metrach.
- Modele zdjęte w NightBrand „do przeróbki” (słabe): `p1_covered_corpses`, `p2_clan_banner`, `p2_fallen_pillar`, `p3_beggar_bodies`, `p3_street_lantern`, `p5_cage`.
- Odtworzenie biblioteki z repo NightBrand-PC: `python3 narzedzia/magazyn_nightbrand.py NightBrand-PC WYJŚCIE` (repo Warowni).
