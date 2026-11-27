Stan na 2026-11-27, rola grafik.

# Audyt menu i UI — Cinzel i czytelność

Gałąź `grafika-cinzel-i-audyt-ui`, baza `b01626e`. Zlecenie autora: delikatniejsze podpowiedzi interakcji, sam tekst bez ramki, zachowanie jednej czcionki oraz pełny audyt z propozycjami zmian.

Największą poprawę dadzą: **osobny układ Ekwipunku, uporządkowany Kupiec i czytelniejsze karty szczegółów**. Obecny wspólny szablon wymusza podobny układ na ekranach o różnych zadaniach. Duże ilustracje, wielopoziomowe ramy i nagłówki zabierają miejsce, którego brakuje nazwom, statystykom i przyciskom.

## Zakres i metoda

- Obejrzano **33 stany**: ekran tytułowy, wyjście, podpowiedzi NPC na klawiaturze/padzie, pięć zakładek Warowni, wybór krainy i potwierdzenie, kupno/sprzedaż/zablokowany towar, budynki, biegłości, pełną Skrytkę i dodatki, wszystkie zakładki pauzy, obie instrukcje sterowania, reset zapisu, HUD, podpowiedź łupu, przeszukiwanie/odkryty/pusty łup, samą sakwę, porzucenie rajdu oraz oba wyniki wyprawy.
- **99 zrzutów:** 33 przed zmianami w 1280×720, 33 po w 1280×720 i 33 po w 1920×1080. Profile testowe zawierają również długie nazwy, pięciomiejscowy Relikwiarz i przykładowe nagrody/kontrakty, aby odsłonić problemy z układem.
- Automatycznie zmierzono rodzinę i wielkość fontu, szerokości tekstów, zawijanie, ucinanie i położenie widocznych kontrolek; wyniki obejrzano na zrzutach. Powtarzające się próbki kontrolek w kolejnych stanach nie są liczone jako unikalne elementy gry.
- Galeria porównawcza i pomiary: `WAROWNIA_POPIOLOW/AUDYT_UI_2026-11-27/`. Odtwarzanie: `narzedzia/gra_3d/audyt_ui.gd`, wyłącznie z osobnym `--zapis`, `--wyniki` i `--podglad-audyt`.
- Przy 1920×1080 gra skaluje logiczny układ 1280×720. Sama zmiana rozdzielczości nie zwiększa miejsca na nazwy; potrzebna jest zmiana podziału przestrzeni.

## Wdrożone w tej rundzie

1. **Podpowiedzi:** sam tekst Cinzel 600, 14 px, bez tła i ramki we wszystkich stanach przycisku. Krycie zwykłe 78%, po najechaniu 96%. Delikatny obrys dotyczy liter, aby pozostały czytelne na jasnym i ciemnym tle. Klikanie i E/Y pozostają aktywne.
2. **Jedna rodzina fontu:** Cinzel. Wcześniej pomiar dawał 555 wystąpień Georgii, 379 Cinzel i 3 Open Sans. Po zmianie wszystkie **930 widocznych próbek tekstu w każdym zestawie po zmianie** używają Cinzel. Dotyczy to też dialogów potwierdzenia, tekstu świata i zastępczej czcionki projektu. Grubość 400 do treści, 600–700 do oznaczeń i nagłówków; brak zależności od systemowej Georgii.
3. **Nazwy dodatków:** wiersz pokazuje nazwę rodzaju i osobną, tekstową jakość zamiast powtarzanego „Dodatek do zbroi”. Pełna nazwa pozostaje w szczegółach. Usunięto zaobserwowane ucinanie nazw: wcześniej tekst o szerokości do 326 px miał około 195 px miejsca po ujednoliceniu fontu.
4. **Okno łupu:** otrzymało stały obrys mieszczący się w ekranie i przewijane panele z podążaniem za fokusem. Dłuższy tekst i większy Relikwiarz nie wypychają już nagłówka ani stopki poza ekran. Przed zabezpieczeniem nagłówek zaczynał się na y = −18, a stopka przekraczała dolną krawędź 720 px.

Po tych korektach pomiary obu rozmiarów okna nie wykazują wychodzenia widocznych etykiet poza ekran ani przepełnienia niełamanych etykiet. Nie oznacza to pełnej czytelności: mały tekst, tło ilustracji, skróty i gęstość treści nadal wymagają oceny wizualnej i zmian opisanych niżej.

## Zalecane zmiany — kolejność

### 1. Ekwipunek i Skrytka — wysoki priorytet

**Obserwacja:** broń, tarcza, łuk, trzy dodatki, Relikwiarz, Sakwa i Skrytka są jedną długą listą. Przy 720p początek ekranu mieści tylko część dodatków. Założone przedmioty znikają podczas szukania rzeczy w Skrytce. Powtarzane nagłówki i opisy zajmują dużą część panelu.

**Propozycja:** stały obszar rynsztunku i trzech dodatków na górze. Pod nim oddzielny widok Skrytka / Sakwa / Relikwiarz, przełączany także LT/RT. Więcej szerokości dla zawartości: około 60% ekranu na wyposażenie i zasoby, 40% na czytelne szczegóły. Wiersze lub kafelki mają ikonę, nazwę i małe oznaczenie jakości. Porównanie i jednoznaczne „Załóż” / „Zdejmij” / „Przenieś” pozostają w stałym miejscu.

**Warunek odbioru:** trzy dodatki są widoczne równocześnie; ich wymiana nie wymaga przechodzenia przez zawartość Sakwy. Pełna nazwa i jakość każdego dodatku pozostają czytelne przy 1280×720. Pad zachowuje fokus po przeniesieniu.

**Dowody:** `12_ekwipunek_dodatki`, `13_skrytka_pelna`, `14_ekwipunek_pad`.

### 2. Karty szczegółów i ilustracje — wysoki priorytet

**Obserwacja:** tekst leży na twarzy bohatera, architekturze i jasnych ogniskach. Duża ikona konkuruje z nazwą. Przy wielu statystykach przycisk transakcji schodzi poniżej widocznego fragmentu. Przewijanie szczegółów łatwo przeoczyć.

**Propozycja:** ilustracja w wyznaczonym górnym polu; poniżej spokojne, mocno przyciemnione tło treści. Nazwa i jakość, krótki opis, 3–5 najważniejszych statystyk, porównanie. Przycisk głównej akcji przy dolnej krawędzi panelu, poza przewijaną treścią. Cinzel 16 px dla opisów i wartości, 22–26 px dla nazw.

**Warunek odbioru:** czytelność pozostaje podobna przy portrecie, nocnej warowni i jasnym ogniu. Nazwa, duża ikona i przycisk nie konkurują o ten sam obszar.

**Dowody:** `05_menu_1`, `05_menu_2`, `08_kupiec_zablokowany`, `13_skrytka_pelna`.

### 3. Kupiec — wysoki priorytet

**Obserwacja:** Kup/Sprzedaj to małe przyciski pomiędzy rozbudowaną nawigacją a długą listą. Kategorie towaru są belkami w jednej liście. Powtarzane opisy rodzaju i blokad zwiększają szum. Kontrolka zablokowanej broni wygląda podobnie do dostępnej.

**Propozycja:** wyraźny przełącznik Kup / Sprzedaj z LT/RT. Krótkie filtry Broń / Tarcze / Łuki / Mikstury. Cena w jednej kolumnie, a przy zaznaczeniu stały blok „Masz / Koszt / Pozostanie”. Przy braku Kuźni krótka, stale widoczna przyczyna blokady. Po sprzedaży utrzymać obecne poprawne zachowanie fokusu.

**Warunek odbioru:** od razu wiadomo, czy gracz kupuje, czy sprzedaje, ile zapłaci i dlaczego akcja jest niedostępna. Przycisk transakcji jest widoczny bez przewijania.

**Dowody:** `05_menu_2`, `08_kupiec_zablokowany`, `09_kupiec_sprzedaz`.

### 4. Sakwa i łupy — wysoki priorytet

**Obserwacja:** po zabezpieczeniu okno mieści się na ekranie, ale nazwy w małych slotach nadal łamią się niezgrabnie, np. „Tonik Wytrzymałości”. Puste, silnie obramowane sloty przyciągają tyle samo uwagi co przedmioty. Nagłówek panelu może przewinąć się razem z zawartością. „Przeszukiwanie…” powtarza się na każdym ukrytym przedmiocie.

**Propozycja:** większa ikona i licznik w slocie; pełna nazwa, jakość i premia w stałej karcie zaznaczenia. Spokojniejsze puste sloty. Stałe nagłówki Sakwa / Relikwiarz / Pojemnik, przewija się tylko ich zawartość. Jeden czytelny postęp przeszukiwania i liczba pozostałych nieodkrytych przedmiotów. „Zabierz wszystko” w stałym miejscu.

**Warunek odbioru:** pełna nazwa wybranego przedmiotu jest dostępna bez urwanych wyrazów, a pasek opisu nie przesuwa stopki. Akcje A/Y/X/B pozostają czytelne i nie zmieniają znaczenia.

**Dowody:** `20_lup_szukanie`, `21_lup_odkryty`, `22_lup_pusty`, `23_sakwa_bez_pojemnika`.

### 5. Pauza i sterowanie — średni priorytet

**Obserwacja:** tytuł, ornament, kontekst, główne zakładki i dwie zakładki urządzeń zajmują ponad jedną trzecią wysokości. Początkowo widać około siedmiu wierszy instrukcji, a interakcje i pozostałe akcje są dalej. Widok pada powtarza frazę o klikaniu wroga. Jasne tło ogniska i architektury prześwituje przez tabelę.

**Propozycja:** mniejsza wysokość nagłówka, jednolita karta o wysokim kontraście i grupy Ruch / Walka / Interakcje. Krótkie nazwy akcji właściwe dla urządzenia. Opcjonalnie dwie kolumny grup zamiast jednej długiej tabeli. W pauzie Biegłości stosować ten sam widok postępu co w Warowni.

**Warunek odbioru:** podstawowe akcje ruchu, walki i interakcji są widoczne bez długiego przewijania; opis pada nie wymaga czytania instrukcji myszy.

**Dowody:** `15_pauza_klawiatura`, `16_pauza_0`, `16_pauza_1`, `24_pauza_rajd`.

### 6. Warownia i biegłości — średni priorytet

**Obserwacja:** koszt budynku to jedna gęsta linia, a posiadane surowce znajdują się daleko w dole drugiego panelu. Dla biegłości informacje są rozdzielone między listę, opis i cienki pasek. Nazewnictwo „Umiejętności” / „Biegłości” nie jest jednolite.

**Propozycja:** przy budynku pokazać „Teraz → Po rozbudowie” oraz koszty z ikonami i ilościami „masz / potrzeba”. Dla biegłości: aktualna korzyść, korzyść następnego poziomu i postęp PD w jednym bloku. Wspólna nazwa działu w całym UI.

**Warunek odbioru:** decyzja o rozbudowie nie wymaga szukania surowców w drugim rogu. Gracz rozumie, że biegłości rosną przez grę, a nie przez zakup.

**Dowody:** `05_menu_3`, `10_warownia_koszt`, `05_menu_4`, `11_bieglosc_parowanie`.

### 7. Wyprawa i potwierdzenia — średni priorytet

**Obserwacja:** oglądana kraina może różnić się od aktualnie wybranej, a odróżnia je mała etykieta i treść przycisku. Dialogi potwierdzenia mają szare belki okna odstające od oprawy gry. Potwierdzenie porzucenia jest szerokim zdaniem o wielu konsekwencjach.

**Propozycja:** wyraźna belka „Wyruszasz do: …”, a zmianę wyboru pokazywać spójnie na liście i w szczegółach. Wszystkie potwierdzenia w jednym stylu i szerokości około 560–680 px. Konsekwencje porzucenia jako krótkie punkty. Zachować obecny bezpieczny fokus i B = anuluj.

**Warunek odbioru:** kraina widoczna przed zatwierdzeniem jest tą samą, do której gracz wyruszy; wszystkie operacje destrukcyjne mają jeden wzór i czytelne anulowanie.

**Dowody:** `05_menu_0`, `06_wyprawa_osada`, `07_wyprawa_potwierdzenie`, `17_usuniecie_zapisu`, `25_porzucony_rajd`.

### 8. HUD i wyniki — średni / niski priorytet

**Obserwacja:** małe podpisy HUD mają miejscami 8–12 px. Górna instrukcja pochodni nadal zajmuje środek obrazu, choć lokalne podpowiedzi interakcji już go nie zasłaniają. Wynik sukcesu łączy ikony, złoto, kontrakty i awanse w jednej karcie; długie wpisy mają mało odstępu.

**Propozycja:** większe najważniejsze liczby i krótsze podpisy HUD. Podpowiedzi nauki gry blisko związanej kontrolki, pokazywane kontekstowo. Na wyniku oddzielić Łup / Doświadczenie / Kontrakty, zawijać długie wpisy i podawać faktyczną nagrodę liczbowo. Ekran tytułowy zachować; wystarczy mocniej wyróżnić „Kontynuuj”.

**Warunek odbioru:** HUD daje się odczytać w ruchu przy 720p, a wynik pokazuje, co konkretnie zostało zdobyte lub utracone.

**Dowody:** `01_tytul`, `18_hud`, `19_podpowiedz_lup`, `26_wynik_sukces`, `27_wynik_smierc`.

## Rekomendowana następna runda

Najpierw **Ekwipunek + Kupiec + wspólna karta szczegółów**, potem **Sakwa i łupy**, następnie **pauza i pozostałe zakładki**. Zachować Cinzel, malowane ilustracje i złoto/brąz; uprościć wnętrza paneli do jednej głównej ramy, spokojnej powierzchni tekstu i jednej wyróżnionej akcji. To propozycje kolejnej rundy — w tej nie przebudowano całego menu.

Odbiór kolejnej rundy: brak uciętych nazw i jakości, stałe przyciski główne, czytelne trzy dodatki, przewijanie podążające za padem, brak wychodzenia poza ekran, kontrola 1280×720 i 1920×1080. Czytelność fizycznego telewizora i prawdziwego kontrolera wymaga osobnej oceny autora.

## Weryfikacja i ograniczenia

Test bazowy przed zmianami: **168/168**. Pełny test po ujednoliceniu fontu i zabezpieczeniu okna łupu: **168/168**; interakcje **18/18**, pad i powrót **34/34**. Krótsze etykiety dodatków dodatkowo sprawdza audyt obu rozmiarów okna.

Ostateczna wyeksportowana paczka Windows: interakcje **18/18**, pad i powrót **34/34**. Uruchomienie: `WAROWNIA_POPIOLOW/Warownia_Cinzel_UI_Test/TEST_CINZEL_UI.bat`; osobny profil pokazowy. Galeria offline: `AUDYT_UI_2026-11-27/AUDYT_UI.html`, porównuje wszystkie 33 stany przed/po. Całość dostępna również jako `Audyt_Menu_UI_2026-11-27.zip`.

Nie testowano fizycznego pada, odsłuchu, Linux ani ultrapanoramicznych proporcji. Ocena kontrastu i gęstości jest oceną projektu interfejsu, a nie certyfikatem dostępności. Zrzuty wyników z długimi kontraktami są stanami testowymi. Koszt Meshy: 0. `main` pozostaje bez zmian.
