Stan na 2026-11-26, rola: grafik

# Magazyn NightBrand dla Warowni

Zasoby wyciągnięte z gry NightBrand (repo `y33bau/NightBrand-PC`, wersja 911) pod czytelnymi nazwami. NightBrand jest tylko źródłem: tam niczego nie zmieniamy.

Folder leży poza `godot/`, więc gra go nie importuje i nie powiększa eksportu. Zasób, którego używamy w grze, kopiujemy do `godot/zasoby/...` w rundzie, która go wdraża.

## Co jest w NightBrand (cały spis: `pelny_spis_nightbrand.json`)
| Rodzaj | Ile | Uwagi |
|---|---|---|
| Modele 3D (.glb) | 202 | 170 z malowaną teksturą (osobny plik .webp), 32 bez tekstury (stare bryły zastępcze) |
| Tekstury (podłoże, ściany, dachy, woda, atlasy) | 91 plików, 74 rodzaje | `cc0_` = darmowe CC0, `wl_` / `cz_` / `br_` / `zl_` / `dm_` / `cy_` = malowane do NightBrand |
| Rekwizyty 2D (sprite'y) | 188 w spisie, 118 plików na dysku | trawy, paprocie, trzciny, grzyby, ogniska, płonące domy |
| Tła (intro, rozdziały) | 25 | ilustracje, nie do terenu |

Podglądy całości: `arkusze/` (tekstury, modele_1–3, rekwizyty2d_1–2).

## Co wyciągnięto (spis: `katalog.json`)
- `modele/las/` (63) i `modele/osada/` (18): bryła `.glb` + tekstura `.webp` o tej samej nazwie. Tekstury zmniejszone do 1024 px, drzewa zostają 2048 (zasada NightBrand).
- `tekstury/` (29): mech, mech leśny, liście, błoto, ziemia, ciemna i czarna skała, woda głęboka i płytka, bród, popiół, węgiel, spękania, urwisko, palisada, chata, deski, atlasy Czarnoboru (`cz_ground`, `cz_walls`, `cz_trees`) i Spalonej Osady (`br_ground`, `br_walls`).
- `rekwizyty_2d/` (58): runo leśne i drobiazgi do gęstego zasiewania (`p0_np_*`, `p4_sp*`, `p4_wd*`, paprocie, trzciny, jeżyny, grzyby, kłoda, menhiry, ogniska i płonące domy).
- `podglad/`: miniatura każdego wyciągniętego modelu.

## Czego świadomie nie wzięto
- `r7_*`, `r8_*`, `r9_*`: bryły z Blendera, autor zdjął je z NightBrand (893).
- Modele zdjęte w NightBrand 22.11 „do przeróbki”: `p1_covered_corpses`, `p2_clan_banner`, `p2_fallen_pillar`, `p3_beggar_bodies`, `p3_street_lantern`, `p5_cage`.
- Wnętrza, cytadela, miasto (p2, p5, reszta p3): nie służą biotopom v1. Są w spisie, można dobrać później.

## Jak dobrać coś jeszcze
Nazwa z `pelny_spis_nightbrand.json` → plik o tej nazwie (skrót SHA-256) w `NightBrand-PC/gra/assets/<rodzaj>/` → kopia tutaj pod nazwą z spisu.
