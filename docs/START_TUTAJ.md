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
| `docs/PRZEKAZANIE_2026-11-26.md` | raport ostatniej sesji (4 rundy, decyzje, pułapki) | nowy agent po 26.11 |
| `docs/KONCEPCJE.md` | pomysły autora z ocenami (nie wszystko wchodzi do v1!) | koncepciarz, planowanie |
| `CLAUDE.md` | skrót zasad (ładuje się automatycznie w Claude Code) | automatycznie |

## 3. Stan na dziś (sprawdź komendą `git log --oneline -8 --all` i dziennikiem)
- **Silnik: Godot 4.7.2, renderer Forward+, prawdziwe 3D z kamerą izometryczną** (decyzje autora 25.11.2026). Gra w `godot/`; wygląd rajdu: `swiat3d.gd`; potok assetów: `narzedzia/gra_3d/`.
- Gra: Warownia-Przystań w 3D (swobodny ruch, NPC: Marga = kupiec, Chojrak = wyprawy i kontrakty, chłop = gawędziarz, przewoźnik z łodzią; obóz rosnący z poziomem), rajd na mapach 96×96 z ziarna (7 rodzajów komnat, 3–4 ekstrakcje, patrole, pościg), walka (combo, parowanie z pierścieniem rytmu, riposta, blok, przewrót, postura, pochodnia vs tarcza, zrzut sakwy), mgła wojny, minimapa, łup, śmierć (Relikwiarz, połowa doświadczenia), dźwięk, pad wszędzie, ustawienie jakości grafiki.
- Postacie: Hadræn (płynny ruch i walka przyjęte przez autora), 6 typów wrogów i NPC z Meshy w pozie T — **autor 26.11.2026: „Postacie są super”**.
- Testy: `testy.py godot` 88/88 (gałąź `hud-nightbrand`).
- Rundy nieopublikowane: `walka-oprawa` (oprawa walki, przyjęta: „o wiele lepiej”) → `menu-i-pauza` (menu, pauza Esc/Start, sterowanie jak NightBrand; „OK jak na betę”) → `mocny-cios-sklep` (mocny cios przez przytrzymanie, Kram Margi) → `hud-nightbrand` (HUD jak NightBrand, wskaźniki walki) → **`namierzanie`** (namierzanie, klik na wroga, płynny ruch, parowanie; W TOKU — ZACZYNAJ OD NIEJ, patrz dziennik 02:40). Raport sesji: `docs/PRZEKAZANIE_2026-11-26.md`. Następne: świat rajdu.
- Sterowanie: układ NightBrand (unik A, rozmowa Y, łuk B, pauza Start) — pełna lista w `godot/skrypty/sterowanie.gd` (`OPIS`).
- Prototyp JS (`zrodlo/`) = archiwum.
- **`main` = opublikowana wersja** (26.11.2026, stan gałęzi `mapy-runda-2`, przyjęty przez autora). Nowa runda: nowa gałąź od `main`.
- Liczby do strojenia czekające na decyzję autora: wrogowie 34/44/50 na mapę, czas rajdu 15 min, skrzynie 40–80, nagrody kontraktów 40/60/150–400.
- Otwarte tematy (z `FUNDAMENT.md`): ekonomia, lista broni v1, struktura mapy rajdu, liczby odblokowań biotopów i kary za śmierć; pilot grafiki Spalonej Osady.

## 4. Gdzie co jest
- Repo: `y33bau/extract`.
- Folder autora: `C:\Users\Admin\Desktop\NIGHTBRAND\` — gra do grania w `WAROWNIA_POPIOLOW\` (zip + `TEST_*.bat`).
- Grafika źródłowa NightBrand: `C:\Users\Admin\Desktop\NIGHTBRAND\bohaterowie_do_x2\` (arkusze z nazwami + `MAPA.json`), `NightBrand-itch-test\assets\wrogowie\` (nazwy to hasze; wybrane już są w `godot/zasoby/`).
- Projekt Claude: **„Warownia”** (instrukcje z `docs/INSTRUKCJE_PROJEKTU.md`).

## 5. Jak rozmawiać z autorem
Po polsku, krótko, wynik najpierw, jedna polecana opcja. Jest początkujący w IT, ale bardzo logiczny: tłumacz decyzje, nie żargon. Nie każ mu używać gita. Zawsze pisz, czego NIE sprawdziłeś. Szczegóły: `ZASADY.md` (F, G), wzory wiadomości: `PROCES.md` §5–6.

## 6. Na koniec sesji
Commit i push gałęzi, wpis na górze `docs/DZIENNIK.md` (wzór w `PROCES.md` §3), aktualizacja §3 tego pliku, meldunek. Bez tego następny agent startuje w ciemno.
