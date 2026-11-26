Stan na 2026-11-26, rola: agent główny

# START TUTAJ — 5 minut dla nowego agenta

Jesteś nowym agentem (inne konto, nowa sesja). Przeczytaj ten plik w całości, zanim cokolwiek zmienisz. Start sesji krok po kroku: `PROCES.md` §1.

## 1. Czym jest projekt
**Warownia Popiołów** — izometryczny dark fantasy extraction RPG. Walka wręcz w stylu Soulsborne, łup i ryzyko w stylu Tarkova, rozbudowa Warowni między rajdami. Jeden bohater: Hadræn (broń jest klasą). Świat wspólny z grą NightBrand tego samego autora, ale z nowymi wątkami.
Jedno zdanie gry: *„Wchodzę w mrok, walczę o każdy krok, biorę więcej, niż powinienem, i ledwo wracam do domu.”*

## 2. Mapa dokumentów

| Plik | Co w nim jest | Kiedy czytać |
|---|---|---|
| `docs/INSTRUKCJE_PROJEKTU.md` | tekst instrukcji projektu Claude (start sesji w skrócie) | wklejony w ustawieniach projektu |
| `docs/START_TUTAJ.md` | ten plik: orientacja i stan na dziś | zawsze, najpierw |
| `docs/ZASADY.md` | **kodeks — zasady nienaruszalne** | zawsze |
| `docs/FUNDAMENT.md` | czym jest gra; zakres pierwszej wersji (kompas) | zawsze |
| `docs/DZIENNIK.md` | dziennik wszystkich agentów (najnowszy na górze) | zawsze: 3 ostatnie wpisy |
| `docs/PROCES.md` | przebieg sesji i rundy, wzory wiadomości, publikacja | zawsze |
| `docs/ROLE.md` | role agentów (zastępuje skille, gdy ich brak) | wybierając rolę |
| `docs/SILNIK_GODOT.md` | architektura, konwencje, pułapki, „jak dodać”, testy, eksport, środowisko | gamedev, grafik |
| `docs/GRAFIKA.md` | styl, formaty sprite'ów i kafli, kolory, proces produkcji | grafik |
| `docs/NARZEDZIA.md` | narzędzia, skille i MCP: co używamy, co odłożone i dlaczego | przy pytaniu o narzędzia |
| `docs/PRZEKAZANIE_2026-11-26.md` | raport sesji 25.11–26.11 (9 rund, decyzje, biblioteka grafik NightBrand, pułapki) | nowy agent po 26.11 |
| `magazyn/nightbrand/` | grafiki NightBrand pod czytelnymi nazwami (wybór v1) + spis całości; pełna biblioteka u autora: `NIGHTBRAND\WAROWNIA_GRAFIKA\Biblioteka_grafik_NightBrand.zip` | grafik, każdy buduje świat |
| `docs/KONCEPCJE.md` | pomysły autora z ocenami (nie wszystko wchodzi do v1!) | koncepciarz, planowanie |
| `CLAUDE.md` | skrót zasad (ładuje się automatycznie w Claude Code) | automatycznie |

## 3. Stan na dziś (sprawdź komendą `git log --oneline -8 --all` i dziennikiem)
- **Silnik: Godot 4.7.2, renderer Forward+, prawdziwe 3D z kamerą izometryczną** (decyzje autora 25.11.2026). Gra w `godot/`; wygląd rajdu: `swiat3d.gd`; potok assetów: `narzedzia/gra_3d/`.
- Gra: Warownia-Przystań w 3D (swobodny ruch, NPC: Marga = kupiec, Chojrak = wyprawy i kontrakty, chłop = gawędziarz, przewoźnik z łodzią; obóz rosnący z poziomem), rajd 20 min na mapach 128×128 z ziarna (lochy, las Czarnobór i wieś Spalona Osada od 26.11) (7 rodzajów komnat, 3–4 ekstrakcje, patrole, pościg), walka (combo, parowanie z pierścieniem rytmu, riposta, blok, przewrót, postura, pochodnia vs tarcza, zrzut sakwy), mgła wojny, minimapa, łup, śmierć (Relikwiarz, połowa doświadczenia), dźwięk, pad wszędzie, ustawienie jakości grafiki.
- Postacie: Hadræn (płynny ruch i walka przyjęte przez autora), 6 typów wrogów i NPC z Meshy w pozie T — **autor 26.11.2026: „Postacie są super”**.
- Testy: `testy.py godot` 154/154 (main po publikacji 26.11, 21:25).
- **Opublikowane 26.11 (21:25)**: `pilot-spalona-osada` → `osada-w-rajdzie` → **`grafika-osada-lup`** (Spalona Osada grywalna: generator `mapgen_osada.gd`, oprawa 3D z biblioteki NightBrand; łup w malowanych modelach; poległy rozpada się w pył i zostawia skrzyneczkę lub krzyżyk; pole widzenia 13/8 m, wróg w walce widoczny do 12 m). Autor: „bardzo dobre”; następnie jego poprawki, potem boss osady w kościele.
- **Opublikowane na `main` 26.11 (14:50)**: cały łańcuch rund `walka-oprawa` → … → `las-w-rajdzie` (Czarnobór grywalny). Opublikowane 26.11 (19:20): `mapa-mgla-i-wczytywanie` → **`walka-i-czytelnosc`** (cios w fazach, nietykalność, obrys wroga zamiast „!”, miękki brzeg mgły, cokół w przekroju, pasek bossa u dołu, minimapa); wcześniej: **`mapa-mgla-i-wczytywanie`** (płynna mgła, głębia zamiast czerni, korytarze 3 pola, mniej przedmiotów, paczka 137 MB). Nowa praca: nowa gałąź od `main`. Opublikowane 26.11 (17:15, `e93aa0e`): `walka-i-oznaczenia` → `szlif-menu-ui` → **`menu-etap2`** (całe menu na szablonie NightBrand: Warownia, pauza, okno łupu, wynik, ekran tytułowy; `ekran_menu.gd`, `ekran_tytulowy.gd`) (zapowiedź ciosu, waga trafień, riposta, odskok, mniejszy HUD i kręgi; porządek menu wg oceny NightBrand; testy 119/119). Narzędzia autora (ziarno) tylko z parametrem `--autor`. Raport sesji: `docs/PRZEKAZANIE_2026-11-26.md`. **Grafiki świata bierz z biblioteki NightBrand** (§2 przekazania). Następne wg autora: walka, oznaczenia, balans, oprawa graficzna.
- Sterowanie: układ NightBrand (unik A, rozmowa Y, łuk B, pauza Start) — pełna lista w `godot/skrypty/sterowanie.gd` (`OPIS`).
- Prototyp JS (`zrodlo/`) = archiwum.
- **`main` = opublikowana wersja** (26.11.2026, 21:25, stan gałęzi `grafika-osada-lup`, „publikuj” autora). Nowa runda: nowa gałąź od `main`.
- Liczby do strojenia czekające na decyzję autora: wrogowie 60/56/56/78/89 na mapę (Katakumby/Czarnobór/Osada/Podgrodzie/Krypta), pole widzenia 13/8/12 m, czas rajdu 20 min (decyzja autora), nagrody kontraktów 40/60/150–400. Brak limitu wysyłki plików do autora (decyzja 26.11).
- Otwarte tematy (z `FUNDAMENT.md`): ekonomia, lista broni v1, struktura mapy rajdu, liczby odblokowań biotopów i kary za śmierć; boss Spalonej Osady (arena: spalony kościół).

## 4. Gdzie co jest
- Repo: `y33bau/extract`.
- Folder autora: `C:\Users\Admin\Desktop\NIGHTBRAND\` — gra do grania w `WAROWNIA_POPIOLOW\` (zip + `TEST_*.bat`).
- Grafika źródłowa NightBrand: `C:\Users\Admin\Desktop\NIGHTBRAND\bohaterowie_do_x2\` (arkusze z nazwami + `MAPA.json`), `NightBrand-itch-test\assets\wrogowie\` (nazwy to hasze; wybrane już są w `godot/zasoby/`).
- Projekt Claude: **„Warownia”** (instrukcje z `docs/INSTRUKCJE_PROJEKTU.md`).

## 5. Jak rozmawiać z autorem
Po polsku, krótko, wynik najpierw, jedna polecana opcja. Jest początkujący w IT, ale bardzo logiczny: tłumacz decyzje, nie żargon. Nie każ mu używać gita. Zawsze pisz, czego NIE sprawdziłeś. Szczegóły: `ZASADY.md` (F, G), wzory wiadomości: `PROCES.md` §5–6.

## 6. Na koniec sesji
Commit i push gałęzi, wpis na górze `docs/DZIENNIK.md` (wzór w `PROCES.md` §3), aktualizacja §3 tego pliku, meldunek. Bez tego następny agent startuje w ciemno.
