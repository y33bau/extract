Stan na 2026-11-25, rola: agent główny

# NARZĘDZIA, SKILLE I MCP

## 0. Najważniejsze
**Skille i MCP należą do konta, nie do projektu.** Agent na innym koncie może ich nie mieć. Dlatego:
- gra, zasady i procedury są w repo i działają bez nich;
- skille tylko przyspieszają start i pilnują porządku — ich treść jest też w `docs/ROLE.md`;
- jeśli na koncie brakuje skilli, agent mówi o tym autorowi na starcie i pracuje z plików.

## 1. Narzędzia w użyciu (sprawdzone, działają)

| Narzędzie | Do czego | Uwagi |
|---|---|---|
| Godot 4.7.2 (Linux, wiersz poleceń) | import, uruchamianie gry, testy, eksport | instalacja: `SILNIK_GODOT.md` §8 |
| `xvfb-run` + Mesa (llvmpipe) | wirtualny ekran: render, zrzuty ekranu, symulacja pada | wolne FPS → testy czekają na warunek |
| Szablony eksportu Godot 4.7.2 | `.exe` dla Windows, kontrolna paczka Linux | 1,3 GB, pobierane na sesję |
| `narzedzia/testy.py godot` | wspólny test pełnej pętli | obowiązkowy po każdej zmianie |
| gdtoolkit (`gdlint`, `gdformat`) | linter i formatowanie GDScript | na razie tylko ostrzega |
| GUT 9.6.1 | testy jednostkowe GDScript | pobrany i sprawdzony, **jeszcze niewpięty**; wepnij, gdy przybędzie logiki do testowania bez uruchamiania gry |
| git + GitHub (repo `y33bau/extract`) | kod, historia, przekazanie | push tylko gałęzi; `main` na „publikuj” |
| Python 3 | skrypty narzędziowe | `narzedzia/` |
| Playwright + Chromium | testy **archiwum JS** (`testy.py szybki/pelny`) i eksport danych z JS (`eksport_z_js.py`) | tylko archiwum |

## 2. Narzędzia Claude w sesji

| Narzędzie | Do czego | Zasada |
|---|---|---|
| Podpięcie repo GitHub | dostęp do `y33bau/extract` (zapis) | pierwszy krok sesji |
| Most do komputera autora (`remote-devices`) | folder `C:\Users\Admin\Desktop\NIGHTBRAND`; podgląd plików, dostarczanie zipów | gra dla autora zawsze do `...\WAROWNIA_POPIOLOW\` jako zip + `TEST_*.bat` |
| Wysyłanie plików na czat | żeby autor widział plik także na telefonie | dodatkowo do folderu, nie zamiast |
| Projekt Claude „Warownia” | instrukcje projektu (tekst z `INSTRUKCJE_PROJEKTU.md`) i kopie kluczowych dokumentów | źródłem prawdy jest repo; dokumenty projektu to kopie |
| Wyszukiwanie w sieci | dokumentacja Godota 4.7, sprawdzanie narzędzi | nie wymyślaj API z pamięci |
| Skille ról Warowni | start sesji i praca w roli | patrz §3 |

## 3. Skille projektu

| Skill | Kiedy | Co zawiera |
|---|---|---|
| `warownia-start` | **na początku każdej sesji** | podpięcie repo, folderu, skilli; kolejność czytania; test bazowy; pierwsza wiadomość; rola agenta głównego, koncepciarza i recenzenta |
| `warownia-gamedev` | zmiany w kodzie gry | architektura, pułapki, test, eksport, dostarczenie |
| `warownia-grafik` | grafika, oprawa, prompty obrazowe | formaty sprite'ów i kafli, styl, proces produkcji |

Treść ról jest też w `docs/ROLE.md` (gdy skilli brak na koncie). Skille zapisuje autor z karty propozycji w Claude; zmiany skilli zawsze idą w parze ze zmianą `ROLE.md`.

## 4. Ocenione i odłożone

| Narzędzie | Co to | Decyzja | Kiedy wracamy |
|---|---|---|---|
| tomyud Godot MCP (MIT) | most do **edytora Godota na komputerze autora**: sceny, błędy, uruchamianie, input, zrzuty | nie teraz — agent ma własnego Godota i robi to samo | gdy autor zacznie pracować w edytorze u siebie i chce, by agent widział to na żywo (wtedy ten, jako najpełniejszy darmowy) |
| GDAI MCP, Godot AI (dlight) | jak wyżej | nie teraz | jak wyżej |
| Godot MCP Pro (15 $) | jak wyżej, płatny | nie | darmowe robią to samo |
| Godot MCP / AI Game Developer (Apache-2.0) | addon C# | **nie**: wymaga Godota .NET, my piszemy w GDScript | — |
| Ziva | panel AI w edytorze + agent testujący | nie teraz | jak przy MCP edytora |
| claude-godot-tools | wtyczki Claude Code: LSP, gdscript-toolkit, gdunit4 | nie teraz — linter i testy mamy bez wtyczek | gdy potrzebny będzie LSP |
| godot-claude-skills, gg-godot | cudze paczki skilli/procesu | nie — nieprzetestowane, mamy własny proces | — |
| GdUnit4 | testy jednostkowe | wybrany GUT (czysty GDScript, prostszy w CLI) | — |
| PixelLab, Retro Diffusion | AI do pixel-artu i arkuszy animacji | **płatne — decyzja autora** | pilot grafiki Spalonej Osady (alternatywa: prompty GPT/Gemini jak w NightBrand) |
| Sprite Fusion | ręczne układanie map z kafli | nie — mapy generuje kod | — |
| UnlockSFX, SFXMint | generatory dźwięków w edytorze | później | runda dźwięku (najpierw dźwięki z NightBrand) |

## 5. Zasady dodawania narzędzi
1. Najpierw test w środowisku agenta (czy działa z Godotem 4.7.2 i bez edytora).
2. Wpis w tej tabeli: co to, decyzja, powód.
3. **Nic płatnego bez zgody autora.**
4. **Żadna wtyczka/addon w repo bez zgody autora** (każda to kod, który trzeba utrzymywać).
5. Narzędzie nie może być warunkiem działania gry ani testów, jeśli nie da się go zainstalować jedną komendą na nowym koncie.
