Stan na 2026-11-26, rola: gamedev

# Pilot Czarnoboru: mapy lasu z góry

Generator `godot/skrypty/mapgen_las.gd`. **Jeszcze nie jest podpięty do rajdu**: gra działa jak dotąd, a to jest tylko podgląd układu do oceny przez autora.

## Jak działa
1. Plamy skał w gąszczu (szum), strumień od krawędzi do krawędzi.
2. 9–12 polan z odstępem; promień 5,5–8 m, czasem łąka 9–11 m; brzeg nieregularny.
3. Sieć: drzewo rozpinające i 2–3 pętle. Pętle omijają liście drzewa, więc ślepe odnogi zostają ślepe.
4. Ścieżki: krzywe z wychyleniem na boki, szerokość nominalna 4–6 m, nigdy węższe niż 4,5 m (po skosie też). Co czwarta dłuższa to wąwóz ze skalnymi ścianami. Na przecięciu ze strumieniem powstaje bród.
5. Start: polana najbliżej losowej krawędzi. Głębokość to długość drogi od startu.
6. Wyjścia (3): głęboko (co najmniej 45% najdłuższej drogi) i przy skraju lasu, 26 m od siebie. Co najmniej 2 ślepe odnogi zostają jako legowisko albo kurhan, z lepszym łupem i większą liczbą wrogów.
7. Na polanach pojedyncze drzewa i głazy jako osłony; każde ma wolny pierścień, więc nigdy nie zamyka przejścia.
8. Łupy (strumień `rng_lup`) i miejsca wrogów (strumień `rng_wrogowie`): głębiej = więcej i lepiej. Rodzaje wrogów lasu dojdą w rundzie „moby”.

## Podgląd
`godot --path godot -- --podglad-lasu=/tmp/las[,ZIARNO;ZIARNO]`, potem `python3 narzedzia/podglad_lasu.py /tmp/las/las_ZIARNO.json`.

Test: `_test_lasu()` w `gra.gd` sprawdza 5 ziaren: ziarno, osiągalność, przejście co najmniej 3×3 m do każdej polany, 3 wyjścia w głębi, ślepe odnogi, szerokość ścieżek.

## Do decyzji autora
- Wielkość mapy: **128×128 m** (decyzja autora 26.11, 11:40: wszystkie mapy 128×128, rajd 20 min). Polan ok. 18–21.
- Liczba polan, gęstość wrogów i łupów to liczby pilota, nie balans. Ustalimy je w rundzie balansu.
