Stan na 2026-11-27, rola grafik.

# Wyposażenie widoczne na Hadranie

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
