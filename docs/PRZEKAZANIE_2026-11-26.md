Stan na 2026-11-26, rola: agent główny

# PRZEKAZANIE — sesja 26.11.2026 (konto 2), od startu do namierzania

Dla agenta na innym koncie, który nic nie wie o tej sesji. Przeczytaj najpierw `START_TUTAJ.md`, `ZASADY.md`, `FUNDAMENT.md`, potem ten plik. Szczegóły każdej rundy są w `DZIENNIK.md` (najnowsze na górze).

## 1. Stan w jednym akapicie

`main` = `97c0c22` (opublikowano 26.11 o 00:06 całą linię do `mapy-runda-2`). Od tego czasu powstały **5 nieopublikowanych rund na gałęziach, każda zawiera poprzednią**:
`walka-oprawa` → `menu-i-pauza` → `mocny-cios-sklep` → `hud-nightbrand` → **`namierzanie` (najnowsza — od niej zaczynaj)**. Testy: **94/94 OK**, kontrola spakowanej gry Linux 94/94 OK. Ostatnia paczka dla autora: `NIGHTBRAND\WAROWNIA_POPIOLOW\Warownia_Namierzanie.zip` (`TEST_NAMIERZANIE.bat`). Autor nie powiedział jeszcze „publikuj” dla żadnej z tych rund — na „publikuj” scal `namierzanie` do main (`--ff-only`; zawiera wszystkie poprzednie).

## 2. Co zrobiono (chronologicznie)

| Godz. | Gałąź | Co | Ocena / decyzja autora |
|---|---|---|---|
| 23:57–00:06 | `mapy-runda-2` | Start sesji (krok 0), poprawka dokumentów: renderer to **Forward+** (instrukcje i `SILNIK_GODOT.md` mówiły Compatibility), `START_TUTAJ.md` §3 | „Postacie są super” → cel „żywe postacie” zamknięty |
| 00:06 | `main` | **Publikacja** `2945bea → 97c0c22` | „publikuj” |
| 00:08–00:50 | `walka-oprawa` | **Oprawa walki**: paski HP/postury nad wrogami (rama, jasny ślad utraty, postura od środka jak Sekiro), złoty romb riposty, pasek bossa, napisy Cinzel bez nakładania, iskry i krople krwi w 3D, zatrzymanie klatki zamraża animacje, kierunkowe kopnięcie i płynny wstrząs kamery, przybliżenie przy ripoście/parowaniu, wzdrygnięcie i błysk trafionego wroga, kręgi pod postaciami, mocniejsze światło bohatera, narzędzie `--podglad-walki` | „Jest o wiele lepiej” |
| 01:00 | `walka-oprawa` | Kamera Warowni (Przystań) dalej: `przystan.gd` ZOOM 1,85 → 1,35 | decyzja autora: w Warowni dalej, w misjach bez zmian |
| 01:02–01:35 | `menu-i-pauza` | **Pauza** (`pauza.gd`, Esc / P / pad Start), **sterowanie jak NightBrand**, **menu w grafikach NightBrand** + Cinzel, bez emoji | „jak na betę jest OK, później dopracujemy”; czcionka: **Cinzel** |
| 01:36–01:50 | `mocny-cios-sklep` | **Mocny cios** (przytrzymaj cios ≥ 0,35 s, puść), **Kram Margi** (kup/sprzedaj, karty, szczegóły z porównaniem), RB na liście sterowania | zlecenie autora; oceny jeszcze brak |
| 02:12–02:40 | `namierzanie` | **Namierzanie** (R / środkowy / R3), klik na wroga = cios w niego, riposta w najbliższego ogłuszonego, kursor nie obraca postaci, doskok tylko do celu, płynny ruch i parowanie, Warownia szybciej, mniejsze znaczniki | zamknięta 10:45 (naprawiony błąd składni z nocy), paczka dostarczona; oceny brak |
| 01:57–02:10 | `hud-nightbrand` | **HUD jak NightBrand** (kule życia i wytrzymałości, pasek akcji, zegar, minimapa w ramie) + **dopracowane wskaźniki walki** | zlecenie autora; oceny jeszcze brak |

## 3. Decyzje autora z tej sesji (obowiązują)
- Cinzel to czcionka całego interfejsu i walki. Ociekające napisy-obrazki z NightBrand — odrzucone.
- Grafiki UI bierzemy z **`C:\Users\Admin\Desktop\NIGHTBRAND\NightBrand_test_911\assets`** (autor wskazał; w `ui\` jest jego wybór 24 plików). Nazwy plików to skróty SHA — te same pliki są w repo `y33bau/NightBrand-PC` w `gra/assets/` (ten sam skrót = ten sam plik).
- Sterowanie ma być jak w NightBrand (tabela w §5). Pauza: Esc / P / Start. Atak także na RB.
- Mocny cios jak w NightBrand: przytrzymanie ciosu.
- Warownia: kamera dalej (postacie mniejsze); rajd bez zmian.
- Repo NightBrand-PC: wolno czytać i brać inspiracje/grafiki; **nic tam nie zmieniamy** (osobny projekt).

## 4. Liczby „do strojenia” (pierwsze przymiarki, czekają na ocenę autora)
- Zatrzymanie klatki (hitstop, `rajd.gd`): zwykły cios 0,055 s (było 0,025), ciężki 0,085 (0,05), riposta 0,15 (0,11), złamanie postury 0,12 (0,09), parowanie 0,15 (0,13), nowe 0,06 s przy otrzymanym ciosie. Autor przyjął oprawę walki bez zastrzeżeń.
- Próg mocnego ciosu `rajd.PROG_MOCNEGO` = 0,35 s. Mocny cios używa liczb ciężkiego ciosu combo (bez nowych liczb). Podczas ładowania krok jak przy bloku (1,9).
- Starsze, nadal czekające: wrogowie 34/44/50 na mapę, czas rajdu 15 min, skrzynie 40–80, nagrody kontraktów 40/60/150–400.

## 5. Sterowanie (stan na `namierzanie`, źródło: `godot/skrypty/sterowanie.gd`, lista dla gracza: `Sterowanie.OPIS`)
| Czynność | Klawiatura i mysz | Pad |
|---|---|---|
| Ruch / kierunek postaci | WASD, strzałki (kursor NIE obraca postaci; LPM na wroga = cios w niego) | lewy / prawy drążek |
| Cios (combo); przytrzymaj = mocny | LPM, J | X, RT, RB |
| Blok i parowanie | PPM, L | LB |
| Unik | Spacja, Shift | **A** (było B) |
| Rozmowa i przeszukiwanie | E, Enter | **Y** (było A) |
| Łuk | Q | **B** (było Y) |
| Mikstury / pochodnia | 1-2-3 / F | krzyżak góra-lewo-prawo / dół |
| Zrzuć sakwę / sakwa | G / Tab, I | **L3** / Widok |
| Namierzanie (wł./wył.) | R, środkowy przycisk myszy | **R3** |
| Pauza | Esc, P | Start |
W menu: A zatwierdza, B wraca, LB/RB zakładki.

## 6. Gdzie co jest w kodzie (nowe w tej sesji)
- `godot/skrypty/pauza.gd` — pauza (CanvasLayer, `PROCESS_MODE_ALWAYS`, `get_tree().paused`). Otwiera `gra.gd` (`moze_pauzowac()`, `otworz_pauze()`): w rajdzie bez otwartego okna łupów, w Przystani bez menu Warowni. „Wyjdź z gry” tylko w Przystani (w rajdzie nie — byłaby ucieczka przed śmiercią).
- `godot/skrypty/ui.gd` — `Ui.motyw()` (jeden wspólny motyw: StyleBoxTexture 9-slice z `zasoby/ui/9/`), `Ui.czcionka(waga)` (Cinzel; **klucz wariantu musi być liczbowym tagiem** `TextServer.name_to_tag("wght")` — tekstowy nie działa, sprawdzone), `Ui.rysuj_pasek`, `Ui.przycisk_akcji` (drewno z żarem), `Ui.styl_slotu`.
- `godot/skrypty/hud.gd` — HUD NightBrand: `_rysuj_kule`, `_rysuj_pasek_akcji` (sloty wg `SLOTY_X` zmierzonych na grafice `pasek_akcji.webp` 724×241), `stan_postawy()`, `_rysuj_zegar`, minimapa z okrągłą maską w `rama_minimapy.webp`, pasek bossa pod zegarem. Podpowiedzi klawiszy zmieniają się na ikony pada, gdy `rajd.mysz_aktywna == false`.
- `godot/skrypty/efekty.gd` — napisy walki (liczby duże z „wyskokiem”, komunikaty mniejsze, piętra wg ekranu, bez dublowania komunikatów), cząsteczki: duże wybuchy idą do `swiat3d.czastki` (3D).
- `godot/skrypty/swiat3d.gd` — mięso trafień: `_reakcja_wroga` (licznik `wrog.licznik_trafien`, odchylenie na sprężynie, błysk), `zamroz()`, `_krag()`, `czastki()`, ładowanie mocnego ciosu (`_plan_animacji` → klucz „ladowanie”), klin łucznika kończy się za graczem (`dlugosc`).
- `godot/skrypty/rajd.gd` — mocny cios (`PROG_MOCNEGO`, `bufor_mocnego`, `atak_wrecz(mocny)`), kopnięcie kamery `_kopnij`, `przyblizenie`. Reguły walki bez zmian poza hitstopem (§4).
- `godot/skrypty/hub.gd` — Kram Margi (`_kupiec`, `_karta`, `_panel_szczegolow`, `_pokaz_szczegoly`, `tryb_kupca`), sloty w ramkach, bez emoji.
- Zasoby: `godot/zasoby/ui/` (z NightBrand, czytelne nazwy), `ui/9/` (9-slice), `ui/hud/` (ikony HUD), `zasoby/czcionki/cinzel.ttf` + licencja OFL (jedzie w paczce i w zipie).
- Narzędzie: `godot --path godot --rendering-driver vulkan -- --podglad-walki=/tmp/katalog` (pełna jakość, seria zrzutów walki z HUD-em; wymaga `apt-get install mesa-vulkan-drivers`).

## 7. Pułapki odkryte w tej sesji
- **Cinzel nie ma** strzałek ←↑→↓, ✓, ✦, ★ ani emoji → pisz słowami („krzyżak dół”). Emoji w napisach wyglądały „archaicznie”.
- StyleBoxTexture rysuje marginesy w pikselach tekstury → grafiki do 9-slice są wcześniej przeskalowane i przycięte (`zasoby/ui/9/`). Duże panele rozciągnięte z tekstury robiły smugi → panele są płaskie z mosiężną ramą.
- Test zależny od FPS: reakcja wroga musi iść z licznika trafień, nie z porównywania `trafiony` między klatkami (w spakowanej grze z wyższym FPS test padał).
- Zbuforowany zwykły cios z poprzedniego kroku testu potrafi odpalić się na starcie kolejnego — w testach czyść `rajd.bufor_ataku`.
- Tryb `--test` renderuje w trybie lekkim (pikseloza) — do oceny wyglądu używaj podglądów `--podglad-*` z Vulkanem.
- Esc to jednocześnie `pauza` i `ui_cancel`: okna (łupy, menu Warowni) obsługują Esc pierwsze, pauza otwiera się tylko, gdy nic nie jest otwarte.
- Commit „w toku” bez zakończonych testów nie jest sprawdzony: w nocy taki commit miał błąd składni w `rajd.gd` (rajd by nie ruszył).
- Dostarczanie plików do folderu autora: `SendUserFile` → `device_commit_files` z `fileUuid` (ścieżka `stagedPath` nie działa dla dużych plików).

## 8. NIE sprawdzone (całość sesji)
Prawdziwy pad (Start, RT jako oś przy przytrzymaniu, ikony pada w HUD), dźwięk, wygląd i płynność na komputerze autora (iskry 3D, wiele wrogów), inne rozdzielczości ekranu niż 1280×720.

## 9. Otwarte sprawy / następne kroki (do decyzji autora)
1. Ocena i „publikuj” dla `namierzanie` (zawiera wszystkie rundy od 26.11).
2. Aktywne umiejętności jak w NightBrand (sloty Q/E/F/R/G, mana) — NIE wdrożone (nowa mechanika; założenie: tylko wygląd zakładki). Czeka na decyzję.
3. Menu „do dopracowania później” (autor: OK jak na betę).
4. Liczby do strojenia (§4).
5. Świat rajdu (mgła wojny bez schodków, wystrój) — zaplanowane wcześniej.
6. HUD: autor jeszcze nie ocenił; możliwe dalsze kroki: ikony mikstur z NightBrand zamiast pikselowych 24 px z Warowni.
