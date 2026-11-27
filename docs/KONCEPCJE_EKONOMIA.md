Stan na 2026-11-27, rola: koncepciarz (propozycja zewnętrzna), sprostowania: agent główny (Claude)

# KONCEPCJE: EKONOMIA, PRZEDMIOTY, ŁUP I MECHANIKI RAJDU

Propozycja koncepciarza z 27.11.2026, napisana bez dostępu do kodu. Agent główny sprawdził ją z kodem i dopisał **sprostowania** (oznaczone ▶). Autor przyjął dokument **jako kierunek**, nie jako gotowy plan (27.11, 01:26).

**Zasady wdrożenia:**
- Każda liczba poniżej jest „do strojenia” (`ZASADY.md` B4).
- Zmiany w `przedmioty.json` i `warownia.json` to balans, więc każdą rundę potwierdzasz z autorem.
- Logika: `rajd.gd` (rajd), `hub.gd` (Warownia, Kram Margi). Dane: `godot/dane/*.json`.
- Losowanie łupu i wrogów tylko ze strumieni `rng_lup` / `rng_wrogowie`.
- Każdy nowy ekran i każda akcja działają na padzie i mają test w `gra.gd`.

---

## 0. Stan gry względem propozycji (sprawdzone w kodzie 27.11, commit `bb4ff3e`)

| Temat | Stan w grze | Skutek dla propozycji |
|---|---|---|
| Skup u Margi | **65% ceny dla wszystkich typów** (`dane.gd → cena_skupu`) | Ceny kosztowności z §1D liczono przy 100% skupu; przelicz przed wdrożeniem |
| Hałas (wrogowie słyszą) | **nie ma** (planowana „runda 2 — hałas” w `KONCEPCJE.md`) | `noiseMult`, głośne kufry, kadzidło (słuch) dopiero **po** rundzie hałasu |
| Pochodnia w ręce blokuje parowanie, rzut F | **jest** (runda 1) | §6.2 zrobione; ewentualnie tylko dopracowanie (czas palenia na ziemi, zapasowa pochodnia) |
| Zrzut sakwy (G / L3) | **jest**; sakwa ma **12 miejsc** (`profil.SAKWA_MAX`) | §6.6 zrobione; „plecak 10 slotów” z §3 to zmiana balansu |
| Odkrywanie przedmiotów po kolei | **jest** (flaga `odkryty`, `okno_lupu.gd`, `rajd.gd`) | §6.3: sprawdzić tylko tempo (0,45 s) i czy świat się nie pauzuje |
| Zużycie pancerza | **jest** (`rajd.gd`: `durability` spada przy trafieniu) | brak: wpływ zużycia na ochronę i naprawa |
| Postura | liczona z obrażeń broni (`dmg × 0,85 / 1,9`) | `postureDmg` daje broniom charakter |
| Zestawy animacji broni | dwuręczny, glewia, topór, miecz, miecz z tarczą, pięści (`wyglad_bohatera.json`) | dwie szable, buzdygan i noże do rzucania wymagają nowych animacji/modeli |
| Bossowie i moby biotopów v1 | **jeszcze nie ma** | trofea bossów (§2, §5B) czekają na rundę bossów |

---

## 1. Zmiany w istniejących przedmiotach (`przedmioty.json`)

### A. Broń biała: nowe pola `twoHanded` (bool) i `postureDmg` (int)
Broń dwuręczna wyklucza tarczę. W zamian łamie posturę mocniej i paruje oraz blokuje samą bronią (mniejsza redukcja bloku, np. 0,50, bazowe okno parowania).

| ID | Zmiana (do strojenia) | Rola |
|---|---|---|
| `rusty_sword` | `twoHanded: false`, `postureDmg: 16` | start, rycerz |
| `steel_falchion` | `twoHanded: false`, `postureDmg: 20` | szybka 1H + tarcza |
| `warden_glaive` | `twoHanded: true`, `dmg 40 → 45`, `stamina 21 → 23`, `postureDmg: 34` | kontrola dystansu |
| `ash_greatsword` | `twoHanded: true`, `dmg 54 → 58`, `stamina 24 → 28`, `postureDmg: 46` | łamacz gardy |
| `executioner_axe` | `twoHanded: true`, `dmg 70 → 74`, `stamina 28 → 35`, `postureDmg: 58` | Kat: potężny cios, pudło boli |

▶ Wizualnie gra już rozróżnia broń: tarczę ma tylko zestaw „miecz” (`z_tarcza`). Sprawdź, czy reguły w `rajd.gd` pozwalają dziś na tarczę przy broni dwuręcznej.

### B. Tarcze: osobny styl blokowania i parowania
- `wood_buckler`: `parryBonus 0.05 → 0.06` (tarcza do parowania).
- `iron_kite`: `parryBonus 0.04 → 0.03` (środek).
- `ash_aegis`: `parryBonus 0.07 → 0.00`, nowe `blockStaminaMult: 0.70` (twierdza do blokowania).

### C. Pancerze: ciężar i zużycie
- `leather_jerkin` (kl. 1): `dodgeStaminaMult 1.00`, `noiseMult 0.80`.
- `chainmail_hauberk` (kl. 2): `dodgeStaminaMult 1.15`, `noiseMult 1.15`.
- `ash_plate` (kl. 3): `dodgeStaminaMult 1.35`, `noiseMult 1.45`.
- Zużycie: poniżej 50% wytrzymałości pancerz traci redukcję liniowo, aż do połowy bazowej `reduction` przy 0.

▶ `noiseMult` dopiero po rundzie hałasu. `dodgeStaminaMult` i wpływ zużycia można zrobić od razu.

### D. Kosztowności: kalibracja cen
Propozycja zakłada skup 100%:
- `silver_goblet` 220 → 130;
- `runic_ring` 540 → 300;
- `golden_idol` 1180 → 650;
- `ash_crown` 2800 → 1450 (trofeum bossa Czarnoboru).

▶ **Dziś skup wynosi 65%.** Przy skupie 100% te ceny dają mniej więcej tę samą wypłatę co dzisiejsze przy 65%: kielich 143 zł → 130, pierścień 351 → 300, bożek 767 → 650, korona 1820 → 1450. Jeśli autor przyjmie stawki z §4, przelicz ceny od nowa. W interfejsie zawsze pokazuj faktyczną kwotę wypłaty.

---

## 2. Nowe przedmioty (propozycja)

| ID | Nazwa | Typ / rzadkość | Cena / Kuźnia | Parametry i rola (do strojenia) |
|---|---|---|---|---|
| `exile_dagger` | Stary Sztylet | weapon / common | 0 / — | 1H, dmg 15, cd 0,28, stam 10, postureDmg 8; tylko z jałmużny |
| `war_mace` | Żelazny Buzdygan | weapon / uncommon | 560 / K1 | 1H, dmg 33, cd 0,40, stam 19, postureDmg 36 |
| `twin_sabers` | Dwie Szable Najemnika | weapon / rare | 920 / K1 | 2H (bez tarczy), dmg 24, cd 0,22, zasięg 1,35, stam 11, postureDmg 14; 3. cios combo = krwawienie |
| `steel_buckler` | Stalowy Puklerz Mistrza | shield / epic | 1250 / K2 | blockRed 0,68, parryBonus 0,09 |
| `ember_oil` | Olej Żaru | elixir (oil) / rare | 130 / K1 | +25% obrażeń wręcz i podpalenie na 25 s |
| `ash_incense` | Kadzidło Popiołu | elixir (stealth) / uncommon | 110 / K0 | −40% zasięgu wykrycia (wzrok i słuch) na 20 s |
| `torch_bundle` | Zapasowa Pochodnia | elixir (torch) / common | 35 / K0 | druga pochodnia po rzuceniu pierwszej |
| `throwing_knife` | Noże do Rzucania | arrow / common | 70 / K0 | stos 5, dmg 20, zasięg 7 m, bez łuku |
| `amber_shard` | Czarnoborski Bursztyn | valuable / common | 95 | częsty drobny łup w Czarnoborze |
| `bone_charm` | Kościany Talizman | valuable / uncommon | 190 | łup ze Spalonej Osady |
| `gilded_censer` | Pozłacana Kadzielnica | valuable / rare | 420 | kapliczki, obozowiska |
| `osada_seal` | Spalona Pieczęć Wójta | valuable / epic | 950 | trofeum bossa Osady |
| `rusty_key` | Klucz Piwniczny | key / rare | 120 | otwiera zamkniętą skrytkę w Osadzie (jednorazowy) |
| `forest_key` | Klucz Gajowego | key / epic | 240 | otwiera zamkniętą kapliczkę w Czarnoborze (jednorazowy) |

▶ **Koszt wykonania:**
- **Animacje i modele:** dwie szable (nowy zestaw animacji Hadræna), buzdygan (może użyć zestawu „miecz”, potrzebny model), noże (pocisk i animacja rzutu).
- **Mechaniki, których dziś nie ma:** krwawienie i podpalenie (status na wrogu), kadzidło (zasięg wykrycia; słuch po rundzie hałasu), klucze (nowy typ `key`, zamknięte skrytki w generatorach).
- **Same wpisy w JSON** (najtańsze): nowe kosztowności (bez trofeów bossów), `exile_dagger`, `steel_buckler`, `torch_bundle` (pochodnia już działa).

---

## 3. Warownia (`warownia.json`) i miejsca w ekwipunku
- **Łączny koszt Warowni** (15 550 zł, 40 żelaza, 35 popiołu, 11 reliktów) koncepciarz uznaje za dobry: ok. 20–25 udanych rajdów.
- **Kuźnia:** +12% → **+8%** obrażeń wręcz na poziom (maks. +24%).
- **Ołtarz Żaru:** +18 HP / +15 staminy / +0,04 s parowania → **+15 / +12 / +0,02 s** na poziom (maks. +0,06 s).
- **Alchemik:** bez zmian (+22% leczenia). Darmowa flaszka po wyprawie **tylko wtedy, gdy gracz ma 0 flaszek** na pasku.
- **Skarbiec:** bez zmian.
- **Miejsca:**
  - sakwa rajdowa 10 miejsc (▶ dziś 12; zmniejszenie to balans);
  - Relikwiarz 2 → maks. 5 ze Skarbcem, tylko typy `material`, `valuable`, `key`.
- **Stosy:**
  - strzały 16, noże 5;
  - eliksiry, oleje, pochodnie 2–3;
  - żelazo i popiół 3;
  - relikt, kosztowności, klucze i sprzęt zawsze po 1 sztuce.

---

## 4. Kram Margi (`hub.gd`)
- **Jawne stawki skupu:**
  - `valuable` 100%;
  - broń, tarcza, łuk, pancerz 50% (pancerz poniżej 50% wytrzymałości: 25%);
  - `material` 35% (żeby opłacało się rozbudowywać Warownię);
  - `elixir`, `arrow`, `key` 30%.
  - ▶ Dziś wszystko 65% (`dane.gd → cena_skupu`).
- **Naprawa pancerza** (jeden przycisk, także na padzie): pełna naprawa od 0% = 30% ceny pancerza, proporcjonalnie do zużycia (pancerz płytowy ok. 585 zł).
- **„Okazja po wyprawie”:** po każdym rajdzie jeden losowy towar w osobnej ramce, broń z poziomu Kuźni −20%.
- **Wentyl bankructwa („Jałmużna Wygnańca”):** gracz nie ma żadnej broni białej (w ręce ani w skrytce) i ma mniej niż 180 zł → darmowo `exile_dagger` + `ash_salve` + `torch_bundle`.

---

## 5. Łup na mapie i z wrogów (`mapgen_osada.gd`, `mapgen_las.gd`, `rajd.gd`)
Trzy strefy odległości od startu. Losowanie wyłącznie z `rng_lup` / `rng_wrogowie`.

### A. Pojemniki
| Obiekt | Otwarcie / hałas | Gdzie | Zawartość (do strojenia) |
|---|---|---|---|
| Zwłoki / szkielet / wóz | 1,5 s, cicho | cała mapa (gł. strefa 1) | 15–40 zł + 1 losowanie: strzały 30%, maść/pochodnia 30%, noże 20%, drobna kosztowność 15%, klucz 5% |
| Zwykła skrzynia | 3 s, hałas 4 m | strefy 1–2 | 2–3 przedmioty: kosztowność common/uncommon + surowiec (żelazo 45% w Osadzie / popiół 45% w lesie) + 30% na tonik/flaszkę |
| Zdobiony kufer / sarkofag | 5 s, hałas 11 m (ściąga patrol) | strefy 2–3 | 3–4 przedmioty: kosztowność rare/epic + 1–2 surowce + 20% na broń/pancerz T1–T2; w Czarnoborze 15% na relikt |
| Zamknięta skrytka (klucz) | 2 s + klucz | 1–2 na mapę (strefy 2–3) | broń lub pancerz T1 (Osada) / T2 (Czarnobór) + złoty bożek + 2 surowce (Czarnobór 35% na relikt) |

Zasada: w kufrach i skrytkach może wypaść sprzęt o 1 poziom wyższy niż obecna Kuźnia gracza.

▶ Czas otwierania i hałas dopiero po rundzie hałasu. Strefy i tabele zawartości można zrobić wcześniej.

### B. Wrogowie i bossowie
| Wróg | Szansa | Łup (do strojenia) |
|---|---|---|
| Zwykły | 35% | 15–35 zł lub zużywalne; 10% żelazo (Osada) / bursztyn (las) |
| Elitarny | 100% | 60–110 zł + przedmiot: surowiec 50%, flaszka/olej 25%, kosztowność 15%, klucz 10%; osobno 8% na sprzęt T1 |
| Boss Spalonej Osady | 100% | `osada_seal` + relikt + 2 żelaza + popiół + 25% na sprzęt K1 |
| Boss Czarnoboru | 100% | `ash_crown` + 1–2 relikty + 2 popiół + 2 żelaza + 35% na sprzęt K2 |

### C. Biotopy
- **Spalona Osada:** dużo żelaza, mało popiołu, relikt tylko od bossa. Zysk netto z udanego rajdu 450–850 zł.
- **Czarnobór:** dużo popiołu, relikty także w głębi, częstsze kadzielnice i bożki. Zysk 900–1500 zł.

---

## 6. Mechaniki rajdu (propozycje)
1. **Trzy różne wyjścia:**
   - Brama: darmowa, blisko, zamyka się w 10. minucie.
   - Ołtarz Powrotu: zawsze otwarty, 18 s rytuału ściąga wrogów.
   - Krąg Przewoźnika: cichy, 5 s, opłata 150 zł albo jedna kosztowność.
   - ▶ Zgodne z decyzją autora (Dzwon / Studnia / Szczelina, `KONCEPCJE.md` runda 3). Przy opłacie sprawdź, czy gracz w ogóle nosi złoto w rajdzie.
2. **Dylemat pochodni.** ▶ Zrobione w rundzie 1. Zostaje ewentualnie czas palenia na ziemi (45 s) i zapasowa pochodnia.
3. **Przeszukiwanie bez pauzy, odkrywanie po kolei co 0,45 s, B zamyka.** ▶ Odkrywanie już jest; sprawdzić tempo i pauzę.
4. **Nadejście Zmroku** (ostatnie 3 min):
   - gęstsza mgła, światło −20%, wrogowie +15% szybkości;
   - nagroda: +30% złota i lepsze szanse na rzadki łup.
5. **Żar Piętna:** riposta lub złamanie postury daje 12 s stanu: +25% regeneracji staminy, podwójna szansa na łup z zabitych. ▶ Nowa mechanika z mnożnikiem łupu; po bossach.
6. **Zrzut sakwy przed bossem.** ▶ Zrzut już jest; progi ciężaru sakwy (np. powyżej 7/10 droższy unik) to nowy balans.

---

## 7. Polecana kolejność (sprostowana przez agenta głównego, przyjęta przez autora jako kierunek 27.11)

| Runda | Co | Dlaczego tak |
|---|---|---|
| **1. Broń i pancerz** (tania, bez nowych systemów) | broń 1H/2H + `postureDmg`; ciężar pancerza (`dodgeStaminaMult`); zużyty pancerz chroni słabiej + naprawa u Margi; jawne stawki skupu (zamiast 65% dla wszystkiego) + przeliczenie cen kosztowności; wentyl bankructwa | dane + `rajd.gd` + `hub.gd`; od razu czuć „broń = klasa” i wybór pancerza |
| **2. Bossowie i moby v1** | boss Osady (spalony kościół), boss Czarnoboru, moby biotopów; trofea bossów (`osada_seal`, `ash_crown`) | brakujący filar pierwszej wersji; ekonomia bez bossów stroi się na pusto |
| **3. Hałas** | system hałasu (kroki, walka, pancerz `noiseMult`) | warunek dla głośnych kufrów, kadzidła i Ołtarza Powrotu |
| **4. Łup i pojemniki** | strefy łupu, tabele pojemników i dropu, klucze i skrytki, nowe kosztowności | na gotowym hałasie i bossach |
| **5. Klimat rajdu** | trzy różne wyjścia, Nadejście Zmroku | adrenalina i ryzyko na końcu rajdu |
| Później | dwie szable, buzdygan, noże (animacje/modele), olej, kadzidło, Żar Piętna, okazja po wyprawie, progi ciężaru sakwy | dużo nowej pracy albo nowych mechanik |

Każda runda: liczby „do strojenia”, zgoda autora na balans, test w `gra.gd`, zip z `TEST_*.bat` do folderu autora.

## Czego nie sprawdzono
- Czy reguły walki dziś pozwalają na tarczę przy broni dwuręcznej (zestaw wizualny tego nie pokazuje).
- Czy gracz nosi złoto w rajdzie (warunek opłaty w Kręgu Przewoźnika).
- Czy działa krwawienie lub poparzenie: opis maści o nich wspomina, ale nie znalazłem tego w regułach.
- Liczby nie były grane, wymagają sprawdzenia „w ręku”.
