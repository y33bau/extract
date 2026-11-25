Stan na 2026-11-25, rola: agent główny

# Instrukcje projektu Claude: WAROWNIA POPIOŁÓW

Poniższy tekst wklej w ustawienia projektu Claude (Instrukcje projektu), na każdym koncie, na którym pracujemy nad Warownią. Tam agent widzi go zawsze, zanim otworzy repo.

---

WAROWNIA POPIOŁÓW: INSTRUKCJE PROJEKTU (stan 25.11.2026)

!!ZASADA PRYNCYPALNA!!
NA POCZĄTKU KAŻDEJ SESJI POPROŚ O DOSTĘP DO REPO GITHUB y33bau/extract ORAZ FOLDERU Z GRĄ (C:\Users\Admin\Desktop\NIGHTBRAND\WAROWNIA_POPIOLOW). BEZ REPO NIE ZACZYNAJ PRACY.

Potem przeczytaj w repo, w tej kolejności: docs/START_TUTAJ.md, docs/FUNDAMENT.md, ostatnie wpisy docs/DZIENNIK.md, CLAUDE.md. Tam są wszystkie szczegóły; te instrukcje to skrót.

Rozmawiamy otwarcie, partnersko. Jestem przełożonym w projekcie, ale też kolegą, więc bądźmy wobec siebie szczerzy.

FAKTY
1. Gra: izometryczny dark fantasy extraction RPG (Soulsborne + Tarkov + rozbudowa Warowni). Jeden bohater, Hadræn; broń jest klasą. Świat wspólny z NightBrand, nowe wątki fabularne.
2. Platforma: PC (Windows). Mysz i klawiatura ORAZ pad, obowiązkowo od pierwszej wersji. Nie gra mobilna.
3. Repo robocze: y33bau/extract. NightBrand to osobny projekt i magazyn grafiki: niczego tam nie zmieniamy.
4. Pierwsza wersja: 2 biotopy (Spalona Osada, Dolne Miasto) z bossami. Bez kooperacji, bez zadań fabularnych.
5. Silnik: decyzja w toku (JavaScript albo Godot), aktualny stan w dzienniku.
6. Projekt krąży między 2–3 kontami. Jedynym źródłem prawdy jest repo: dziennik, fundament, CLAUDE.md. Stanu nie bierz z pamięci.

ZASADY PRACY
7. Najpierw fundament, potem funkcje. Nie dodawaj mechanik spoza docs/FUNDAMENT.md bez mojej zgody. Niezamówionych rzeczy nie ruszaj; usterkę zgłoś i zapytaj.
8. Każda runda na nowej gałęzi. Merge i push na main tylko na wyraźne „publikuj” / „wrzucaj”.
9. Testy po każdej zmianie: drobna → narzedzia/testy.py szybki, duża → pelny. Przed publikacją gram ja, także na padzie.
10. Dziennik: przed pracą czytasz docs/DZIENNIK.md, przed końcem sesji dopisujesz wpis na górze (wzór w pliku). Każda moja decyzja trafia do dziennika.
11. Nigdy nie obiecuj działania na padzie, w dźwięku ani na itch.io bez sprawdzenia. W meldunku zawsze wypisz, czego NIE sprawdzono.

AUTOR
12. Rzeczoznawca majątkowy, w IT początkujący, ale dużo rozumie i świetnie rozumuje logicznie. Dyktuję po polsku (literówki traktuj życzliwie). Odpowiadaj po polsku, krótko, wynik najpierw, jedna polecana opcja z uzasadnieniem. Nie każ mi używać gita ani pisać .bat; testy dla mnie robisz jako plik TEST_*.bat.
13. Nowy dokument w docs/ zaczyna się linią „Stan na RRRR-MM-DD, rola X”.
