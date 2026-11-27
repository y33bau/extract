Stan na 2026-11-27, rola gamedev.

# Stały strój, dodatki, interakcje i pad

Gałąź `ulepszenia-interakcje-i-pad`, od `3e4dae7`. Autor odrzucił wymienne zbroje, następnie zlecił podpowiedzi nad obiektami, klikanie obiektów, naprawę pada i porzucenie rajdu z pauzy.

## Stały strój i trzy dodatki

Widoczny jest oryginalny, kompletny strój Hadrana (`cialo`). Nieudane nakładki są ukryte w Przystani i rajdzie. Wycofano zbroje ze sklepu, pojemników i łupów przeciwników oraz ich naprawę u Margi. Stałego stroju nie kupujemy ani nie tracimy po śmierci. Zachowano początkowe 24% ochrony.

Przed rajdem można założyć trzy dodatki różnych rodzajów. Znalezione dodatki można przechować, sprzedać i schować w Relikwiarzu. W rajdzie można je podnieść, ale montaż odbywa się w Warowni. Zdejmowanie nie niszczy przedmiotu. Założone dodatki podlegają utracie przy śmierci.

Pierwsze wartości **do strojenia przez autora**, w `godot/dane/ulepszenia_zbroi.json`:

| Rodzaj | Zwykły | Magiczny | Epicki | Legendarny |
|---|---:|---:|---:|---:|
| Klamra Wędrowca: ruch | +3% | +5% | +7% | +10% |
| Okucie Strażnika: ochrona | +3 pkt proc. | +5 pkt proc. | +7 pkt proc. | +10 pkt proc. |
| Pieczęć Wytchnienia: odnowa staminy | +5% | +8% | +12% | +16% |
| Rzemień Zwinności: niższy koszt uniku | 4% | 7% | 10% | 14% |

16 definicji powstaje z danych, cztery ikony SVG rozróżniają rodzaje. Jakość jest także nazwana tekstem. Wagi jakości: 55/30/12/3. Wartość bazowa: 160/400/900/1800 zł, skup 40%; dodatków nie można kupić. Szanse dodatkowego przedmiotu w pojemniku i u zwykłego wroga wynoszą po 20%; boss zostawia jeden dodatek. To nowe wartości do strojenia.

Losowanie jakości odbywa się ze strumienia łupu po rozmieszczeniu obiektów mapy. Techniczne znaczniki w dawnych miejscach pancerzy są rozwiązywane przed oddaniem mapy grze. Nowe definicje nie przesuwają skrzyń, układu ani punktów wrogów. Porównanie `OSADA01` z `3e4dae7`: identyczna siatka, komnaty, spawny i stan RNG wrogów.

## Zapis v3

Domyślny plik to `user://warownia_zapis_v3.json`. Przy braku v3 odczytywany jest v2, potem v1; stary plik pozostaje na dysku. `--zapis` nadal wskazuje konkretny plik.

Dawne zbroje stają się okuciami: skóra → zwykłe, kolczuga → magiczne, płyta → epickie. UID i pojemnik pozostają zachowane. Założona zbroja trafia do miejsca na dodatek. Nadmiar i powtarzające się rodzaje trafiają do Skrytki, nawet jeśli migracja przekracza pojemność — nic nie jest kasowane. Ponowne wczytanie nie duplikuje przedmiotów. Stare definicje i funkcje pancerza zachowano dla zgodności; nie są bieżącą ofertą wyposażenia.

## Interakcje przy obiektach

Mała etykieta podąża za rozmówcą, skrzynią albo zwłokami. Pokazuje E lub Y według urządzenia. Kliknięcie obiektu albo etykiety wykonuje tę samą akcję. Usunięto dawną podpowiedź przeszukiwania z góry HUD. Odłożona pochodnia ma lokalną podpowiedź F / krzyżak dół.

Zasięg NPC: 2 m, łupu: 1,7 m. Rajd sprawdza widoczność i linię wzroku. Nie ma otwierania przez ścianę ani poza zasięgiem. Klik łupu zeruje oczekujące wejście ataku. Żywy przeciwnik pod kursorem ma pierwszeństwo walki; etykieta jednoznacznie wskazuje łup. Nie dodano automatycznego podchodzenia do odległego obiektu.

## Pad i sklep

Skróty sekcji są obsługiwane przed GUI: LT/RT przełącza Kup/Sprzedaj, LB/RB sekcje, B wraca. Fokus pomija przyciski `FOCUS_NONE`. Po zakupie wraca do towaru, po sprzedaży do istniejącej pozycji. Krzyżak i lewy drążek mają jawne przypisania nawigacji. Prawo z towaru prowadzi do akcji, lewo wraca na listę.

Usunięto globalne wyłączanie wejścia viewportu na 0,4 s. Pomocniczy węzeł przechwytuje tylko puszczenie trzymanego zatwierdzenia z poprzedniego ekranu. Inne przyciski reagują od razu. Potwierdzenia obsługują B we własnym viewporcie. Destrukcyjne operacje zaczynają od anulowania.

## Porzucenie rajdu

Pauza w rajdzie ma opcję **„Porzuć rajd i wróć do Przystani”**. W Przystani jest ukryta. Potwierdzenie opisuje utratę sprzętu, dodatków i łupu. Domyślny wybór to pozostanie w wyprawie; B anuluje.

Zatwierdzenie wraca bezpośrednio do Przystani i zapisuje utratę wyprawy. Nie przyznaje doświadczenia, złota, postępu kontraktów ani flaszki od Alchemika. Relikwiarz i wcześniejszy postęp Warowni pozostają bezpieczne. Zwykła śmierć nadal zachowuje połowę doświadczenia — to inny przypadek niż porzucenie.

## Kontrola

- `--test-ulepszen`: 52/52 — migracja v1/v2, trzy miejsca, cztery jakości, generatory, faktyczne premie w rajdzie, ekstrakcja i śmierć.
- `--test-interakcji`: 18/18 — rozmowa, skrzynia, zwłoki, klik obiektu i etykiety, Y, zasięg, widoczność, brak przypadkowego ataku.
- `--test-pada`: 34/34 — transakcje, fokus, pięć sekcji, pauza, anulowanie i porzucenie rajdu oraz zapis utraty.
- Wyeksportowana paczka Windows: te same **52/52 + 18/18 + 34/34**, uruchomione na właściwym pliku EXE i PCK.
- Regresja wyposażenia: **105/105** kontroli GLB, w tym chwyty i tarcze, oraz **20/20** sprawdzeń wyposażenia w Przystani i rajdzie. Dawne kontrole widoczności nakładek zastąpiono kontrolą stałego stroju zgodnie z decyzją autora; kontrole broni i kolizji pozostały.
- Pełny test gry w Windows: **168/168**. W bazie występowały błędy menu/pada i zatrzymanie na `przystan.poziomy`; ten przebieg dochodzi do końca. Kontrola pozy przewrotu mierzy teraz cały ruch zamiast sześciu klatek, zachowując dotychczasowy próg — wynik nie zależy od przypadkowego fragmentu animacji przy wysokim FPS.

Paczka autora: `Warownia_Dodatki_i_Pad_Test/TEST_DODATKI_I_PAD.bat`. Ma osobny profil pokazowy, wszystkie cztery jakości dodatków w Skrytce i trzy założone dodatki początkowe. To stan demonstracyjny; zwykły nowy profil zaczyna bez dodatków. Wersja spakowana: `Warownia_Dodatki_i_Pad_Test.zip`.

Testy mają osobne profile. `--ustawienia` kieruje plik preferencji do katalogu kontroli; domyślny plik gracza pozostaje w `user://ustawienia.cfg`. Koszt Meshy tej rundy: **0 kredytów**.

Nie sprawdzono fizycznego pada, odsłuchu ani długiej sesji. WSL nie jest zainstalowany, więc nie można uruchomić eksportu Linux na tym komputerze. Weryfikacja paczki dotyczy Windows Forward+ na RTX 4070 SUPER. `main` nie był zmieniany.
