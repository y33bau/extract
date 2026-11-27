Stan na 2026-11-27, rola grafik.

# Wyposażenie widoczne na Hadranie

**Aktualizacja decyzji autora 27.11:** wymienne nakładki pancerzy zostały odrzucone i wycofane w rundzie `ulepszenia-interakcje-i-pad`. Hadræn zachowuje oryginalny strój; trzy dodatki z łupu zmieniają statystyki. Poniższy opis pancerzy jest historią produkcji assetów. Bieżący system i migrację opisuje `DODATKI_INTERAKCJE_PAD_2026-11-27.md`. Bronie, tarcze, łuki i poprawki chwytów pozostają w grze.

## Korekta chwytów po ocenie autora

Gałąź `grafika-poprawne-chwyty`, od `fb91b01`. Ostrza wychodzą od strony kciuka, a pivot znajduje się w zamkniętej dłoni. Poprawiono przód wszystkich tarcz, ich odłożenie na plecach i tylne uchwyty. Z puklerza usunięto wygenerowaną bryłę przypominającą dodatkową pięść. Drzewce glewii zwężono w części chwytowej; głownia pozostaje szeroka i skierowana ku górze lub ku celowi.

Skorygowano prowadzenie ramion w klipach miecza, tak aby ostrze omijało tarczę. Dla 2H rozwiązano kontakt obu dłoni, ciągły kierunek zgięcia łokci i wspólny obszar dosięgania. Glewia i topór używają stabilnej bazy ciała Hadrana; glewia zachowuje osobne trajektorie pchnięcia oraz dwóch cięć. Długości klipów pozostają takie same. Eksport i import animacji: 60 Hz, bez optymalizacji usuwającej klucze chwytu.

Kontrola rzeczywistego GLB w Godocie: **105/105**. Obejmuje orientację dwóch mieczy i mocowanie do dłoni, 13 klipów miecza przeciw trzem tarczom, osiem przejść między animacjami oraz 65 próbek na każdy z 33 klipów 2H (dopuszczalne odchylenie drugiej dłoni poniżej 2,5 cm). Przewrót i śmierć celowo zwalniają drugą dłoń. Kontrola Przystani i rajdu: **20/20**. Dodatkowo Blender sprawdza siatki broni i tarcz z marginesem kolizji. Kontrole są próbkowane i nie stanowią gwarancji wszystkich możliwych mieszanek animacji podczas gry.

Odtworzenie po wcześniejszych skryptach: `popraw_chwyty_hadrana.py -- FOLDER_STARYCH_ASSETOW REPO FOLDER_WYNIKOW`, następnie `stabilizuj_chwyty_2h.py -- FOLDER_WYNIKOW REPO` w Blenderze 5.3. `podglad_poprawnych_chwytow.py -- GOTOWY_BLEND FOLDER_PODGLADOW` renderuje zbliżenia. Gotowy plik: `POPRAWNE_CHWYTY_2026-11-27/hadran_chwyty_stabilne.blend`.

Nowa paczka: `Warownia_Chwyty_Test/TEST_POPRAWNE_CHWYTY.bat`, osobny profil pokazowy. Rzeczywisty eksport Windows uruchomiony i sprawdzony testem ekonomii: **30/30**. Dodatkowy koszt Meshy: **0**, łącznie nadal **465/800**. Pełnego testu gry nie powtarzano w tej korekcie wizualnej; wcześniejsze błędy opisane niżej pozostają poza zakresem. Nie sprawdzono fizycznego pada ani długiej sesji gracza.

Gałąź: `grafika-rynsztunek-hadrana`, baza `ekonomia-bron-i-pancerz` (`828cacb`). Autor zlecił wszystkie brakujące elementy i zatwierdził do 800 kredytów Meshy. Zmiana dotyczy wyglądu; parametry przedmiotów i moment wystrzelenia pocisku pozostają w istniejących regułach gry.

## Zestaw

| Element | Identyfikatory |
|---|---|
| Pięć broni białych | `rusty_sword`, `steel_falchion`, `warden_glaive`, `ash_greatsword`, `executioner_axe` |
| Trzy tarcze | `wood_buckler`, `iron_kite`, `ash_aegis` |
| Trzy łuki | `hunter_bow`, `yew_longbow`, `shadow_bow` |
| Trzy pancerze | `leather_jerkin`, `chainmail_hauberk`, `ash_plate` |
| Dodatki | kołczan, strzała z lotkami, pochwy miecza, kordelasa i miecza dwuręcznego |
| Ruch | `glewia_atak1` (pchnięcie), `glewia_atak2` (cięcie), `glewia_atak3` (mocne cięcie), osobna postawa, chód i obrona glewii; `luk_celowanie`, `luk_strzal` |

Modele Meshy powstały z obecnych ikon autora. W Blenderze dopasowano skalę w metrach, rękojeści, proporcje drzewca i głowni, wagi pancerzy oraz mocowania do oryginalnego szkieletu Hadrana. Twarz i podstawowe animacje pozostają z dotychczasowego modelu. Pancerze wymieniają korpus i rękawy, zachowując oryginalne elementy kończyn, rękawice, naramienniki i buty.

Pancerze mają wspólny szkielet i ciągłe wagi kręgosłupa. Kolczugę zastąpiono drugim wariantem o siatce przygotowanej do gry; pierwszą siatkę z odrzuconej próby zachowano wyłącznie w folderze autora. Tekstury koloru mają najwyżej 1K, mapy pomocnicze przeważnie 512 px. Nowe GLB używają importu Basis Universal w Godocie; ustawienia `.glb.import` są zachowane w repo. PNG wydobywane przez wcześniejszy import są plikami odtwarzalnymi i nie należą do źródeł.

Tarcza założona przy broni 2H jest widoczna na plecach. Przy łuku broń biała trafia do pochwy lub na plecy. Odłożony łuk i kołczan są widoczne przy wyposażonym łuku. Strzała i morf cięciwy pokazują naciągnięcie i wypuszczenie. Istniejący strzał nadal następuje natychmiast po naciśnięciu przycisku; animacja pokazuje krótki ruch towarzyszący, bez dodawania nowego czasu ładowania.

## Koszt Meshy

| Operacje | Kredyty |
|---|---:|
| 14 modeli z ikon, w tym odrzucona pierwsza kolczuga | 420 |
| 3 animacje glewii | 30 |
| Poprawiona kolczuga z siatką do gry | 15 |
| **Razem / zatwierdzony limit** | **465 / 800** |

Saldo przed: 1081, po: 616. Nie ma zleceń oczekujących ani automatycznych ponowień. Identyfikatory zadań i koszty są w `ASSETY_HADRAN_2026-11-27/RAPORT_ASSETOW.json` u autora. Narzędzie nie zapisuje kluczy ani tokenów w repo. Pochwy, kołczan, strzała, korekty chwytów i pozy łuku powstały lokalnie.

## Kontrola assetów

- Import Godota: bez błędów parsowania nowych skryptów i modeli.
- `narzedzia/gra_3d/kontrola_rynsztunku.gd`: **38/38**, warianty siatek, widoczność, skóra pancerzy, odkładanie, morfy i wysokość bioder w klipach glewii.
- Pomiar Blendera: kontakt ręki z drzewcem w trzech klipach glewii oraz osiągnięcie pozy łuku w granicach błędu numerycznego. Jest to kontrola mocowania, nie ocena fizycznego pada ani wyczucia walki.
- Podglądy: każdy wariant obejrzany w Godocie, dodatkowo kordelas, łuk i glewia z właściwej kamery w Czarnoborze.

## Kontrola w grze

- `narzedzia/gra_3d/kontrola_rynsztunku_w_grze.gd`: **20/20**, rzeczywista Przystań i rajd z aktualizacją wyposażenia przez postać.
- Test ekonomii: **30/30** ze źródeł oraz w paczce Windows.
- Pełny test przed i po zmianie: te same 10 niezaliczonych kontroli menu, pada, końca rajdu i kontrolowanego przewrotu, bez nowych niezaliczonych kontroli. Oba przebiegi zatrzymują się na wcześniejszym dostępie do `przystan.poziomy` po nieudanym powrocie z rajdu. Test nie jest przedstawiany jako zaliczony. Porównanie: `porownanie_testu_pelnego.json` w folderze autora.
- Nie sprawdzono fizycznego pada, odsłuchu ani długiej sesji gracza. Nie wykonano kontroli eksportu Linux na tym komputerze; kontrola dotyczy Windows Forward+ na RTX 4070 SUPER.

## Pliki i odtworzenie

Zasoby gry: `godot/zasoby/3d/rynsztunek/`. `hadraen_rynsztunek.glb` zawiera bohatera, warianty, mocowania oraz animacje; pozostałe GLB są samodzielnymi modelami wyposażenia lub pancerzami na jego szkielecie. Wybór modeli obsługuje `godot/skrypty/wyglad_rynsztunku.gd` w rajdzie i Przystani.

Źródła Meshy, FBX, referencje i pliki `.blend` pozostają w folderze autora `C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_POPIOLOW\ASSETY_HADRAN_2026-11-27`.

Odtworzenie w Blenderze 5.3: uruchom kolejno `rynsztunek_hadrana.py`, potem `chwyty_hadrana.py`, przekazując po `--` pełną ścieżkę folderu assetów autora i repo. Opcja `--force` pierwszego skryptu ponownie przygotowuje również osobne modele broni. `podglad_rynsztunku.py` renderuje porównania z gotowego pliku `.blend`.

Paczka autora: `Warownia_Rynsztunek_Test/TEST_RYNSZTUNEK.bat`, z osobnym profilem pokazowym i kompletem wyposażenia w Skrytce. Nowa gałąź oczekuje na ocenę autora; `main` nie był zmieniany.
