Stan na 2026-11-26, rola: gamedev

# Pilot Spalonej Osady: mapy z góry

Generator `godot/skrypty/mapgen_osada.gd`. **Pilot do akceptacji autora.** Generator nie jest jeszcze podpięty do rajdu, nie ma też grafiki 3D.

## Jak działa
Zasada ta sama co w Czarnoborze (decyzja autora: biotop otwarty, wyznaczone ścieżki jak w Dragon's Dogma). Zamiast polan są miejsca osady, zamiast lasu zabudowa.
1. Plac ze studnią blisko środka (promień 10–11,5 m). Do tego 14–17 miejsc z odstępem 11 m, żeby między nimi zmieściły się chaty.
2. Ulice: drzewo rozpinające i 3–5 pętli. Ulice prowadzące do placu (główne) mają 6–7,5 m, reszta 5–6,5 m. Wieś, więc ulice są mniej kręte niż leśne ścieżki.
3. Start: miejsce najbliżej losowej krawędzi. Głębokość to długość drogi od startu.
4. Spalony kościół: najgłębsza ślepa odnoga, promień co najmniej 9 m, osmalone mury z wyłomami przy ulicach. To przyszła arena bossa osady.
5. Wyjścia (3): w głębi (co najmniej 45% najdłuższej drogi) i przy skraju. Pozostałe ślepe odnogi to cmentarz (płot, groby, sarkofagi) albo zapadnięta piwnica. Mają lepszy łup.
6. Pozostałe miejsca to zagrody (płot z przerwami), jedna kuźnia, jedna stodoła i spalony sad (gęsto zwęglonych drzew).
7. Spalone chaty (30–34 na mapę) przy ulicach i miejscach. Mury 1 m, wnętrze 4–6 m, wejście 3 m od strony drogi. Co trzecia ma skrzynię, w co czwartej żarzą się zgliszcza (światło). Chata bez wejścia znika.
8. Osłony: wozy, beczki, belki, spalone drzewa. Każda stoi w wolnym pierścieniu, więc nie zamyka przejścia.
9. Łupy (`rng_lup`) i miejsca wrogów (`rng_wrogowie`): głębiej = więcej i lepiej. Rodzaje wrogów osady dojdą w rundzie „moby”.

## Podgląd
`godot --path godot -- --podglad-osady=/tmp/osada[,ZIARNO;ZIARNO]`, potem `python3 narzedzia/podglad_osady.py /tmp/osada/osada_ZIARNO.json`.

Test: `_test_osady()` w `gra.gd` sprawdza 6 ziaren:
- to samo ziarno daje tę samą mapę;
- wszystko jest osiągalne;
- do każdego miejsca prowadzi przejście co najmniej 3×3 m;
- są 3 wyjścia w głębi i ślepe odnogi;
- każda chata ma wejście;
- jest jeden kościół o promieniu co najmniej 9 m;
- szerokość ulic się zgadza.

## Do decyzji autora
- Układ, rodzaje miejsc i chaty z wejściem: akceptacja pilota.
- Liczby (miejsca, chaty, łupy, wrogowie) to liczby pilota, nie balans.
- Czasem dwa wyjścia wypadają bliżej niż 35 m (ziarno 3). Jeśli to przeszkadza, poprawię.
