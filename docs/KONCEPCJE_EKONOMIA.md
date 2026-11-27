Stan na 2026-11-27, rola agent główny

# Koncepcja ekonomii i wyposażenia

Status dokumentu — propozycja do decyzji autora. Uwagi Claude’a sprawdzono w kodzie gałęzi oprawa-parowania-i-lupu. Ten dokument porządkuje zakres kolejnych rund. Publikacja dokumentu nie zatwierdza nowych wartości balansu.

## Stan potwierdzony w kodzie

| Obszar | Obecne działanie | Miejsce w kodzie |
|---|---|---|
| Skup | Wszystkie typy mają stawkę 65% ceny, wynik obcinany do liczby całkowitej. | godot/skrypty/dane.gd, cena_skupu |
| Postura | Zwykły cios zadaje dmg broni × mnożnik Kuźni × 0,85 obrażeń postury, ciężki × 1,9. | godot/skrypty/rajd.gd, obsługa trafienia |
| Kuźnia | +12% na poziom w mnożniku obrażeń. | godot/skrypty/rajd.gd |
| Ołtarz | +0,04 s na poziom do okna parowania. Bazowe okno, tarcza i biegłość także wpływają na wynik. | godot/skrypty/rajd.gd, dlugosc_okna_parowania |
| Pancerz | Wytrzymałość spada po trafieniu. Ochrona pozostaje nominalna przy dodatniej wytrzymałości. Przy zerowej wytrzymałości kolejne trafienia pomijają redukcję pancerza. | godot/skrypty/rajd.gd, trafienie_gracza |
| Wentyl bankructwa | Dar Margi oferuje darmowy miecz, puklerz i flaszkę. Obecny warunek sprawdza brak broni założonej, w magazynie i sakwie oraz złoto poniżej 200. Flaszka trafia do sakwy, jeśli jest miejsce. | godot/skrypty/hub.gd, Dar Margi |
| Pochodnia | Można ją rzucić. Trzymana w ręce uniemożliwia parowanie. | istniejąca mechanika |
| Sakwa | Ma 12 miejsc i można ją zrzucić przed walką. | istniejąca mechanika |
| Przeszukiwanie | Przedmioty odkrywają się kolejno. Tempo wymaga oceny podczas gry. | godot/skrypty/okno_lupu.gd |
| Hałas | Zaplanowany jako runda 2. | docs/KONCEPCJE.md |
| Wyjścia | Dzwon, Studnia i Szczelina zapisane jako kierunek rundy 3. | docs/KONCEPCJE.md |

## Proponowane rundy

Każda runda wymaga określenia zakresu przez autora i oddzielnej gałęzi.

1. **Tożsamość broni.** Jawny chwyt jednoręczny lub dwuręczny oraz osobne postureDmg dla broni. Wykorzystać istniejące zestawy animacji. Przygotować tabelę wartości do akceptacji, uwzględniając zwykły i mocny cios, tarczę, pochodnię, ripostę i starsze zapisy. Wprowadzenie chwytu wymaga sprawdzenia, jak obecny kod dobiera animacje i wyposażenie.
2. **Pancerz i naprawa.** Ustalić koszt uniku zależny od pancerza, przebieg utraty ochrony oraz koszt naprawy u Margi. Sprawdzić opłacalność naprawy względem kupna nowego pancerza i sposób obsługi uszkodzonych przedmiotów w zapisie.
3. **Skup.** Przygotować stawki dla typów przedmiotów dopiero po przeliczeniu obecnej bazy 65%. Pokazać autorowi ceny kupna, sprzedaży i naprawy oraz wynik przykładowego rajdu. Dar Margi poddać przeglądowi pod kątem rzeczywistego bankructwa i możliwości wielokrotnego sprzedawania darmowego wyposażenia.

## Zależności i późniejsze etapy

- Hałas poprzedza słyszalne kufry, wpływ pancerza na słuch wrogów oraz kadzidło zmieniające ten słuch.
- Trzy rodzaje pojemników mogą otrzymać różne czasy otwierania przed systemem hałasu. Ich słyszalność i zwabianie wrogów wymagają tego systemu.
- Zmrok może wykorzystywać zegar i nagrody niezależnie od hałasu. Przed wdrożeniem trzeba określić zagrożenie, nagrodę i sposób ich zakomunikowania.
- Bossowie i nowe moby pozostają odłożone decyzją autora. Można przygotować ekonomię zwykłego rajdu. Nagrody bossów i końcową ekonomię należy zweryfikować po ich dodaniu.
- Dwie szable, buzdygan i noże do rzucania wymagają oceny modeli, animacji i obsługi walki.
- Klucze, oleje, kadzidła, okazje, Żar Piętna i zmiana Relikwiarza pozostają pomysłami do oddzielnej decyzji.

## Wartości oczekujące na decyzję

| Propozycja z opinii | Stan |
|---|---|
| Kuźnia +12% → +8% na poziom | Do zatwierdzenia przez autora |
| Ołtarz +0,04 s → +0,02 s na poziom | Do zatwierdzenia przez autora |
| postureDmg dla każdej broni | Tabela do przygotowania i zatwierdzenia |
| Koszt uniku, utrata ochrony i naprawa | Wartości do przygotowania i zatwierdzenia |
| Osobne stawki skupu | Wartości do przygotowania i zatwierdzenia |

## Kryteria sprawdzenia przy wdrożeniu

- Stare zapisy zachowują poprawne wyposażenie, wytrzymałość i dostęp do sklepu.
- Zakup, sprzedaż i naprawa poprawnie aktualizują złoto oraz przedmiot.
- Gracz może wrócić do wyprawy po utracie wyposażenia.
- Chwyt broni zgadza się z animacją i wyposażeniem w obu dłoniach.
- Każda zmiana mechaniki otrzymuje test zgodnie z zasadami projektu. Wyniki testów i ograniczenia trafiają do dziennika.
- Znane błędy pada pozostają odłożone zgodnie z decyzją autora.

## Zalecany następny krok

Najpierw przygotować tabelę chwytu i obrażeń postury dla pięciu istniejących broni białych. Autor zatwierdza liczby przed wdrożeniem.
