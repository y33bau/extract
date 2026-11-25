Stan na 2026-11-25, rola: agent główny

# WAROWNIA POPIOŁÓW: koncepcje, decyzje, plan

Zbiór pomysłów autora z 25.11.2026 (cztery pakiety) z uwagami agenta. Decyzje autora są w punkcie 6. Reszta to notatki do wdrożenia lub decyzji.

## 0. Stan gry
- Repo `y33bau/extract`. Gra: `dist/WAROWNIA_POPIOLOW.html` (ok. 1 MB, działa offline). Źródła w `zrodlo/` (12 skryptów), budowa: `narzedzia/zbuduj.py`.
- Silnik: canvas 2D, rzut izometryczny, kafle proceduralne, dynamiczne światło. NIE Three.js.
- Postacie z NightBrand: Hadræn (rycerz) + 6 wrogów (Zwiadowca, Gwardzista, Kusznik, Zakonny Rycerz, Kat Ruin z czerwonym błyskiem, boss Popielny Strażnik).
- Mechanika: combo 3 ciosów, parowanie złotego błysku + riposta, blok, unik, łuk, ekstrakcja 6 s, Relikwiarz, Warownia (Kuźnia, Alchemik, Ołtarz Żaru, Skarbiec), 5 umiejętności, ziarna map, 3 krainy.
- Sprawdzone: przeglądarka testowa (Chromium), brak błędów konsoli. NIE sprawdzone: ręczne granie i balans, dźwięk na PC autora, pad (brak obsługi), itch.io.

## 1. Walka i mechaniki rajdu (pakiet 1)
| Pomysł | Ocena agenta | Kiedy |
|---|---|---|
| Dylemat pochodni (pochodnia zajmuje rękę tarczy, F = rzut na ziemię) | Biorę: najlepszy pomysł, silnik światła już jest | Runda 1 |
| Postura / pasek równowagi wrogów | Biorę: ciężkie combo też otwiera ripostę | Runda 1 |
| Zrzucanie plecaka przed walką | Biorę: tanie, czysty Tarkov | Runda 1 |
| Hałas (krąg dźwięku, wrogowie słyszą) | Fundament pod wagę, dzwon, osełkę | Runda 2 |
| Waga pancerza = ciężki unik + hałas | Biorę, po systemie hałasu | Runda 2 |
| Typy ekstrakcji: Dzwon / Studnia / Szczelina | Biorę | Runda 3 |
| Przypływ Popiołu + Popielny Kat | Biorę, ale Kat „bardzo trudny”, nie nieśmiertelny | Runda 3 |
| Urazy: krwawienie, złamanie (+ zgnilizna później) | Biorę uproszczone, leczenie 2–4 s z wolnym chodem | Runda 4 |
| Przeklęte Relikty | Biorę | Runda 5 |
| Kontrakty NPC | Na koniec (potrzebują gotowej treści) | Runda 5 |
| Tępienie ostrza + osełka | Zmienić: tylko przy wrogach w pancerzach, inaczej nudny obowiązek | Później |
| Ubezpieczenie (Pakt Przewoźnika) | ODRZUCONE (decyzja 25.11) | — |

## 2. Architektura
- ZROBIONE 25.11: podział na 12 plików w `zrodlo/js/` + skrypt sklejający `narzedzia/zbuduj.py` (moduły ES nie działają z file://, więc zwykłe skrypty).
- Docelowo wyodrębnić: maszynę stanów walki (idle, windup, active, recovery, parry_window, riposte, staggered), system wagi i stanów zdrowia, metę (Warownia, kontrakty, ekonomia).

## 3. Grafika, seedy, generator (pakiet 2)
- Problem nr 1: postacie malowane (NightBrand) vs kafle w grubym pikselu. Rozwiązanie: malowane zestawy kafli i rekwizytów na biotop + jedna gęstość pikseli dla całej sceny (render na mniejszym płótnie, powiększenie bez wygładzania).
- Zestaw na biotop: 4–6 podłóg, blok ściany, ściana z przejściem, ściana z pochodnią, 10–15 rekwizytów. Prompty pisze rola grafika.
- Do przejrzenia: tekstury (99), rekwizyty (133) i posadzki z NightBrand.
- Seedy: osobne strumienie losowania (układ / łupy / wrogowie); ziarno wybiera też biotop (np. `OSAD-7Q2M`); opcjonalnie „Loch dnia”.
- Generator: graf pomieszczeń z POI (arena bossa, kapliczka, skarbiec, dzwon, studnia, szczelina), gwarantowana droga do każdej ekstrakcji, boczne odnogi z lepszym łupem.

## 4. Warownia jako żywa makieta (pakiet 3)
Hub nie jako menu, tylko mapa, po której chodzi Hadræn; budynki zmieniają wygląd z poziomem.
- 5–6 stref, każda 3 etapy wizualne (prowizorka → drewno i kamień → żelazo i runy):
  - Kuźnia i Zbrojownia (Goran) = obecna Kuźnia
  - Krąg Ognia / Ołtarz Przysiąg (serce, błogosławieństwa i klątwy przed wyprawą) = obecny Ołtarz Żaru
  - Zielarnia i Lazaret (Mira / Milena) = obecny Alchemik
  - Strażnica i Stół Wypraw (Iwo): wybór krainy, zwiad = NOWE
  - Palisada i Brama: startowe bonusy = NOWE
  - (Skarbiec zostaje jako skrytka i Relikwiarz)
- Stos żelaza pod kuźnią po powrocie, wizualne ślady moralności/Paktu, zero timerów (ulepszenie natychmiast, z efektem).

Uwagi agenta:
- Robić w TYM SAMYM silniku 2D izometrycznym co rajdy, NIE w Three.js. Jeden silnik = połowa pracy.
- Koszt grafiki: 5 budynków × 3 etapy = ok. 15 obrazów + postacie NPC.
- Pad (LB/RB): gra dziś nie obsługuje pada. Osobna runda.

## 5. Pięć biotopów (pakiet 4)
| Biotop | Charakter walki | Zagrożenie | Surowce | Układ |
|---|---|---|---|---|
| Spalona Osada i Pogorzeliska | Średni dystans, zniszczalne przeszkody | Dym (widoczność, podpalenie), tlące węgle (można wpychać wrogów) | żelazo, węgiel, osmolone drewno | ścieżki + zagrody |
| Dolne Miasto i Gnijące Podgrodzie | Krótki dystans, ciasno | Błoto (wolniej, krótszy unik), trujące wyziewy | księgi, narzędzia, zardzewiała stal | pokoje + korytarze (BSP) |
| Solne Nabrzeże i Szuwary | Otwarte, łuki ważne | Wiatr spycha i zmienia tor strzał, ostre wykwity soli | sól, drewno okrętowe, bursztyn | otwarte (cellular automata) + groble |
| Czarnobór i Głuche Ostoje | Osłony blokują wzrok, mrok | Poza światłem rośnie Strach/Zepsucie, korzenie i sidła | krwawa żywica, zioła, buk, kości | organiczne polany (cellular automata) |
| Cytadela Wierzycieli | Endgame, precyzja | Wahadła, zapadnie, ołtarze wysysające zasoby | relikty, obsydian, pieczęcie Paktu | symetryczne sale + mosty |

Uwagi agenta:
- Przyjąć te 5. Katakumby i krypty zostają jako typ pomieszczenia (podziemia) w Dolnym Mieście i Cytadeli. Krypta Popielnego Króla → arena bossa.
- Czarnobór najmocniej wykorzystuje dylemat pochodni, a Solne Nabrzeże łuk.
- „Mgła FogExp2” z propozycji = u nas kolor mroku w warstwie światła; cząsteczki już są w silniku.
- „Wiele poziomów” w Dolnym Mieście: na start udawana wysokość (kładki jako osobne kafle), bez prawdziwych pięter.
- Surowce biotopów wymagają przebudowy ekonomii Warowni (dziś: żelazo, esencja popiołu, relikty).
- Pilot grafiki: Spalona Osada (rozdział I NightBrand, najwięcej wzorców).

## 6. Decyzje autora
- 25.11: Warownia to osobny projekt, repo `y33bau/extract`.
- 25.11: wspólne lore z NightBrand, ale nowe wątki fabularne.

- 25.11: przyjęte 5 biotopów z pakietu 4 (Spalona Osada, Dolne Miasto, Solne Nabrzeże, Czarnobór, Cytadela Wierzycieli).
- 25.11: rezygnujemy z ubezpieczenia (Pakt Przewoźnika).

## 7. Kolejność prac
1. Runda 1 walki: postura, pochodnia vs tarcza, zrzut plecaka.
2. Równolegle pilot grafiki: Spalona Osada (zestaw kafli, jedna gęstość pikseli, nowy generator z POI).
3. Dalej rundy 2–5 z tabeli w punkcie 1, potem Warownia-makieta i kolejne biotopy.
