Stan na 2026-11-26, rola: grafik (przebudowa menu wg NightBrand, etapy 3–5)

# Prompty na brakujące grafiki menu Warowni

Menu jest już przebudowane na wzór NightBrand, ale część ilustracji to **zastępstwa z NightBrand**: tła `rozdzial_*` i `tlo_menu_1`. Poniżej są gotowe zlecenia dla ChatGPT / Gemini (autor wkleja, pobiera obraz, wrzuca do `NIGHTBRAND\WAROWNIA_GRAFIKA\`). Agent potem skaluje je skryptem (`narzedzia/menu_zasoby.py`) do `godot/zasoby/ui/menu/` i podmienia nazwy w kodzie.

| Gdzie w grze | Teraz (zastępstwo) | Docelowo | Plik docelowy |
|---|---|---|---|
| Wyprawa: Zrujnowane Katakumby, pauza i wynik w tej krainie | `rozdzial_5` | prompt 1A | `kraina_katakumby.webp` |
| Wyprawa: Kamienne Podgrodzie | `rozdzial_1` | prompt 1B | `kraina_podgrodzie.webp` |
| Wyprawa: Krypta Popielnego Króla | `rozdzial_2` | prompt 1C | `kraina_krypta.webp` |
| Czarnobór | `rozdzial_4` (pasuje: las nocą) | może zostać | — |
| Kram Margi (szczegóły) | `tlo_menu_1` | prompt 2A | `stanowisko_kram.webp` |
| Stół Chojraka (Wyprawa, bez wybranej krainy) | `tlo_menu_1` | prompt 2B | `stanowisko_chojrak.webp` |
| Warownia: Kuźnia | `tlo_menu_1` | prompt 2C | `stanowisko_kuznia.webp` |
| Warownia: Ołtarz Relikwiarza | `kaplica` | prompt 2D | `stanowisko_oltarz.webp` |
| Ekran tytułowy: logo | napis Cinzel + Piętno | prompt 3 | `logo_warownia.webp` (przezroczyste) |
| Ikony przedmiotów | piksele 16–24 px | prompt 4 (osobna runda) | `ikony_128/<id>.webp` |

---

## Wspólny początek każdego promptu (wklej przed treścią)
> Jesteś głównym grafikiem koncepcyjnym gry wideo „Warownia Popiołów” — izometrycznego RPG dark fantasy o wyprawach w mrok po łup (walka jak w Dark Souls, ryzyko utraty ekwipunku jak w Escape from Tarkov). Świat jest ten sam co w grze NightBrand: spalone wsie, popiół, żar, stare kaplice, ludzie wyniszczeni wojną i klątwą. Styl: **malowana ilustracja cyfrowa, ręcznie malowany dark fantasy, nocne światło, ciepły żar ognia kontra zimny księżyc**, faktura pędzla widoczna, bogate detale, filmowa głębia, lekka mgła. Paleta: czerń, głęboki brąz, rdza, popiół, żar pomarańczowy, akcenty czerwieni, zimny błękit nocy. Nastrój: groza i samotność, ale z odrobiną ciepła ognia. **Bez tekstu, bez liter, bez napisów, bez znaków wodnych, bez ramek, bez interfejsu, bez logo.** Bez postaci na pierwszym planie, chyba że prompt mówi inaczej. Obraz ma być tłem menu: główny motyw w górnych 2/3, dolna 1/3 spokojniejsza i ciemniejsza (na niej będzie tekst).

## 1. Ilustracje krain (1672 × 941 px, poziomo)
**1A — Zrujnowane Katakumby.** Wejście do podziemnych katakumb pod ruinami kamiennego klasztoru, nocą. Schody w dół między zapadniętymi kolumnami, w głębi słaby żar zniczy i kości ułożone w niszach ścian. Na górze krzywe nagrobki, uschnięte drzewo, księżyc za chmurami. Zimne kamienie, ciepłe światło zniczy w głębi.

**1B — Kamienne Podgrodzie.** Zrujnowane przedmieście pod murami twierdzy: kamienne domy bez dachów, wąskie uliczki, barykady z wozów, tlące się zgliszcza, szubienica przy bramie. W tle ciemna sylweta murów i wieży z jednym oknem w ogniu. Deszcz popiołu w świetle pożaru.

**1C — Krypta Popielnego Króla.** Ogromna podziemna sala grobowa: kamienny sarkofag króla na podwyższeniu, posągi rycerzy z mieczami wzdłuż ścian, żar w kamiennych misach, popiół wirujący w smugach światła z pęknięcia w sklepieniu. Czuć obecność czegoś, co zaraz się obudzi (bossa), ale **bez postaci**.

## 2. Stanowiska Przystani (1200 × 900 px)
**2A — Kram Margi.** Drewniany kram handlarki w obozie Przystani nocą: lada z bronią (miecze, topór, łuk, tarcze na stojaku), flaszki z czerwonym i zielonym płynem, worki i skrzynie, dwie latarnie po bokach, płachta nad kramem. Za kramem ciemny plac i ognisko. Ciepłe, zapraszające światło latarni.

**2B — Stół Chojraka.** Stół najemnika pod daszkiem: rozłożona stara mapa okolicy z naszkicowanymi krainami, sztylet wbity w mapę, świeca, kufel, sakwa z monetami, kilka zwojów z pieczęciami (kontrakty). Obok stojak z włócznią. Światło świecy z dołu.

**2C — Kuźnia Warowni.** Polowa kuźnia w obozie: kowadło, palenisko w żarze, miech, młoty na ścianie, świeżo kute ostrza w wodzie (para). Iskry. Kamień i drewno, ciężki, rzemieślniczy klimat.

**2D — Ołtarz Relikwiarza.** Mała kapliczka z kamienia i drewna: ołtarz z relikwiarzem (metalowa szkatuła z wizerunkiem Piętna — sztylet w półksiężycu), świece, suche kwiaty, wota zawieszone na sznurkach. Spokojne, święte światło świec w mroku.

## 3. Logo „Warownia Popiołów” (ChatGPT, przezroczyste tło, 1600 × 700 px)
> Zaprojektuj logo gry „WAROWNIA POPIOŁÓW” w stylu logo gry NightBrand: napis wielkimi literami w kroju szeryfowym inspirowanym rzymskimi kapitałami (jak Cinzel), litery z kutego, porysowanego metalu z ciepłym żarem w szczelinach. Nad napisem znak Piętna: sztylet wbity w półksiężyc, żarzący się na pomarańczowo. Słowo „WAROWNIA” większe, „POPIOŁÓW” pod nim mniejsze. **Przezroczyste tło (PNG z kanałem alfa)**, bez dodatkowych tekstów, bez ramki. Polskie znaki muszą być poprawne: Ó, Ł, Ó.

## 4. Ikony przedmiotów 128 × 128 (osobna runda)
> Ikona przedmiotu do gry dark fantasy w stylu ikon menu NightBrand: malowany przedmiot w ujęciu 3/4 na przezroczystym tle, ciepłe światło z lewej góry, lekka ciemna obwódka, bez tła, bez tekstu, bez ramki. Przedmiot: [NAZWA i opis z `godot/dane/przedmioty.json`].
Lista przedmiotów: `godot/dane/przedmioty.json` (pola `id`, `name`, `desc`). Najpierw broń i tarcze (najczęściej widoczne w Kramie i Ekwipunku).
