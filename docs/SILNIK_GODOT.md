Stan na 2026-11-25, rola: gamedev

# SILNIK GODOT — przewodnik techniczny

Wszystko, co agent musi wiedzieć, żeby bezpiecznie zmieniać kod gry. Zasady nienaruszalne są w `ZASADY.md` (sekcja C, D); tu jest „jak”.

---

## 1. Parametry projektu

| Rzecz | Wartość |
|---|---|
| Silnik | **Godot 4.7.2** stable (`4.7.2.stable.official.ed1daf0bf`) |
| Język | GDScript z typami (bez C#/.NET) |
| Renderer | Compatibility (OpenGL) — działa na słabych kartach i pod Mesa w środowisku agenta |
| Rozdzielczość bazowa | 1280×720, `stretch/mode = canvas_items`, `aspect = expand` |
| Filtr tekstur | najbliższy sąsiad (piksele ostre) |
| Folder projektu | `godot/` (w edytorze otwórz ten folder) |
| Scena główna | `godot/gra.tscn` → skrypt `skrypty/gra.gd` |
| Zapis gracza | `user://warownia_zapis_v1.json` (Windows: `%APPDATA%\Godot\app_userdata\Warownia Popiolow\`) |

Sceny budujemy **w kodzie** (węzły tworzone w `_ready`), a nie w edytorze. Dzięki temu cała gra jest czytelna jako tekst, agent może ją zmieniać i testować bez edytora, a w repo nie ma trudnych do scalenia plików `.tscn`.

## 2. Architektura

### Autoloady (globalne, zawsze dostępne)
| Nazwa | Plik | Rola |
|---|---|---|
| `Sterowanie` | `sterowanie.gd` | **Jedyne** miejsce definicji akcji: klawiatura + mysz + pad. Dopisuje też pad do `ui_accept`/`ui_cancel`. |
| `Dane` | `dane.gd` | Wczytuje `dane/*.json`: przedmioty, krainy, Warownia, umiejętności. Ikony, opisy, ceny skupu. |
| `Profil` | `profil.gd` | Trwały stan gracza (złoto, Warownia, umiejętności, rynsztunek, skrytka), zapis/odczyt, doświadczenie, surowce. Argument `--zapis=ścieżka` podmienia plik zapisu (testy). |
| `Swiatla` | `swiatla.gd` | Wspólna tekstura i fabryka świateł 2D (`nowe(kolor, energia, promień_px)`). |
| `Dzwiek` | `dzwiek.gd` | Syntezator efektów (bez plików audio): `zamach`, `trafienie`, `blok`, `parowanie`, `riposta`, `cieciwa`, `unik`, `krok`, `bol`, `picie`, `lup`, `ui`, `tik`, `ekstrakcja`. |

### Skrypty gry
| Plik | Co robi |
|---|---|
| `gra.gd` | Korzeń: Warownia ⇄ rajd ⇄ ekran wyniku. **Test automatyczny** (`_test`) przy `--test`. |
| `hub.gd` | Warownia: 5 zakładek (Wyprawa, Ekwipunek i Skrytka, Kupiec, Warownia, Umiejętności). Fokus pada, LB/RB zakładki. |
| `rajd.gd` | **Wszystkie reguły rajdu**: świat, kolizje, widoczność, walka gracza, AI wrogów, strzały, łup, ekstrakcja, śmierć, rozliczenie z profilem. |
| `mapgen.gd` | Generator lochu z ziarna. Trzy strumienie losowania: `rng_uklad`, `rng_lup`, `rng_wrogowie`. Typy kafli `K.*`. |
| `bohater.gd` | Stan Hadræna (HP, stamina, timery walki, rynsztunek rajdu) + animacja z arkuszy, pochodnia, płomień. |
| `wrog.gd` | Typy wrogów (`TYPY`), stan, animacja, nakładka bez cieniowania (paski HP/postury, błysk ataku, napisy). |
| `hud.gd` | HUD rajdu: paski, mikstury, broń, minimapa, ekstrakcja, podpowiedzi, toasty, winiety. |
| `okno_lupu.gd` | Okno „Sakwa i łupy” (mysz i pad). |
| `efekty.gd` | Cząsteczki i unoszące się napisy (współrzędne świata). |
| `iso.gd` | Rzut izometryczny: `ekran(w)`, `swiat(e)`, kierunki arkuszy. |
| `ui.gd` | Wspólny motyw interfejsu i fabryki kontrolek (`motyw()`, `panel()`, `etykieta()`, `pasek()`, `przycisk_akcji()`). |

### Przepływ danych
`dane/*.json` → `Dane` → `Profil.d` (zapis) → `rajd.start()` kopiuje `loadout` do `gracz.rynsztunek` → w rajdzie zmienia się tylko kopia → `rajd.zakoncz()` rozlicza: przeżycie = rynsztunek wraca, kosztowności i surowce do skrytki; śmierć = zostaje tylko Relikwiarz. Doświadczenie zbierane w `rajd.xp_rajdu`, na końcu ×1,0 (przeżycie) albo ×0,5 (śmierć) — **zasada fundamentu**.

### Świat i rysowanie
- Współrzędne świata w polach (`Vector2`), ekran przez `Iso.ekran(w)` (kafel 64×32 px).
- Podłoga: jeden węzeł rysujący wszystkie kafle (`_rysuj_podloge`), alfa wg widoczności.
- Mury, filary, kosze, gruz, skrzynie, postacie, zwłoki: węzły w `swiat` z `y_sort_enabled` (głębia = y ekranu).
- Ciemność: `CanvasModulate`; światło: `PointLight2D` (pochodnia, kosze, kręgi ekstrakcji, pochodnia na ziemi).
- Rzeczy, które mają być widoczne w mroku (paski, błyski, napisy), mają materiał `LIGHT_MODE_UNSHADED`.
- Mgła wojny: `widok` (0 nieznane, 1 widziane, 2 widoczne), przeliczana co 0,08 s promieniami od gracza.

## 3. Konwencje kodu

- Nazwy i komentarze **po polsku** (bez polskich znaków w nazwach identyfikatorów: `obrazenia`, nie `obrażenia`).
- **Typy jawne** przy wartościach ze słowników i tablic: `var t: float = d["x"]`, `var lista: Array = l["backpack"]`. `:=` tylko gdy prawa strona ma znany typ.
- Liczby z JSON przychodzą jako `float` — rzutuj `int(...)` tam, gdzie liczysz sztuki/złoto.
- Stałe gry (balans) w `dane/*.json` albo w stałych na górze pliku z komentarzem. Nie „magiczne liczby” w środku funkcji, jeśli dotyczą balansu.
- Każda funkcja reguł w `rajd.gd` krótka i nazwana czynnością: `atak_wrecz`, `postura`, `trafienie_gracza`, `zabij`.
- Linter: `gdlint godot/skrypty/*.gd` (gdtoolkit) — na razie ostrzega; nowe pliki pisz tak, żeby nie dokładać uwag.

## 4. Pułapki, na które już trafiliśmy (przeczytaj!)

| Pułapka | Objaw | Rozwiązanie |
|---|---|---|
| Wnioskowanie typu z wartości słownika | `Parse Error: Cannot infer the type of "x"` — skrypt się nie ładuje, autoload pada | `var x: Typ = ...` zamiast `:=` |
| `floor()` zwraca Variant | to samo | `floorf()` / `floori()` |
| Pad nie działa w menu | Godot 4.7 domyślnie: `ui_accept` = tylko Enter/Spacja, `ui_cancel` = tylko Escape | Dopisane w `Sterowanie` (A/B). Nie usuwaj. |
| Kontrolka przypięta do prawej/dolnej krawędzi wychodzi poza ekran | ustawianie `position` po `set_anchors_preset` | `set_anchors_and_offsets_preset(..., PRESET_MODE_MINSIZE, margines)` + `grow_horizontal/vertical = BEGIN` |
| Pusty widok zakładek | Control na `CanvasLayer` ma wysokość 0 | `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` **po** `add_child` |
| Test zależny od czasu się sypie | wirtualny ekran rysuje wolno, gra ogranicza `dt` do 0,05 s → czas gry płynie wolniej niż rzeczywisty | W testach czekaj na warunek (`_czekaj_az`), nie na sekundy |
| Naciśnięcie przepada w „zamrożeniu” po trafieniu | `hitstop` pomija wejście | Bufor wejścia (`bufor_ataku`, `bufor_uniku`) w `rajd.gd` |
| Ten sam przycisk zamyka okno i robi unik (B) | po zamknięciu okna postać robi unik | `blokada_wejscia` w `rajd.gd` i `_blokada` w `okno_lupu.gd` |
| JSON nie trafia do eksportu | gra po eksporcie nie ma danych | `include_filter="dane/*.json"` w obu presetach; kontrola Linux z `--test` |
| Brak znaków w czcionce | kwadraciki zamiast emoji (np. 🛡) | Sprawdzaj zrzuty; używaj znaków, które się wyświetlają, albo tekstu |
| Ostrzeżenia ALSA/audio w środowisku agenta | błąd sterownika audio | Normalne pod `xvfb`; Godot przechodzi na sterownik zastępczy |

## 5. Jak dodać…

### …przedmiot
1. Dopisz wpis w `godot/dane/przedmioty.json` (pola jak w istniejących: `id`, `name`, `type`, `rarity`, `price`, `desc` + pola typu, np. `dmg`, `range`, `arc`, `stamina`, `cooldown` dla broni).
2. Ikona 24×24 px PNG w `godot/zasoby/ikony/<id>.png` (zasady w `GRAFIKA.md`).
3. Jeśli ma wypadać: dopisz do puli w `mapgen.gd` (`PULE_LUPU`) albo do łupu wroga w `rajd.gd` (`zabij`).
4. Test: sprawdź w Kupcu / w łupie na zrzucie ekranu.

### …wroga
1. Dopisz typ w `wrog.gd` → `TYPY` (hp, spd, dmg, zasieg, zamach, cd, pancerz, postura, promien, skala; opcjonalnie `ciezki`, `boss`).
2. Arkusz `godot/zasoby/en_<rodzaj>.webp` w formacie wrogów (`GRAFIKA.md`).
3. Dodaj do tabeli losowania krain w `rajd.gd` → `_postaw_wrogow`.
4. Łup w `rajd.gd` → `zabij`.
5. Test: krok w `_test`, który stawia tego wroga przed graczem i sprawdza jego zachowanie.

### …akcję sterowania
1. Tylko w `sterowanie.gd`: `_akcja("nazwa", [_klaw(KEY_..), _pr(JOY_BUTTON_..)])`.
2. Zawsze klawiatura/mysz **i** pad. Sprawdź kolizje z istniejącym układem (tabela w nagłówku pliku).
3. Dopisz do instrukcji sterowania w `hub.gd` (`_wyprawa`) i w HUD, jeśli gracz ma o niej wiedzieć.

### …mechanikę
1. Upewnij się, że jest w `FUNDAMENT.md` albo zamówiona przez autora.
2. Reguły w `rajd.gd` (albo w `profil.gd`, jeśli dotyczy Warowni/zapisu), stan w `bohater.gd`/`wrog.gd`, wygląd tamże.
3. Test w `gra.gd` → `_test` (symulowany pad: `_pad(JOY_BUTTON_..)`, `_os(JOY_AXIS_.., v)`).
4. `python3 narzedzia/testy.py godot` → OK; obejrzyj zrzuty.
5. Opis w dzienniku (z liczbami „do strojenia”).

## 6. Test automatyczny

- Uruchomienie: `python3 narzedzia/testy.py godot` (import projektu → gra pod `xvfb-run` z `--test --zrzuty=… --zapis=…`).
- Ręcznie: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot --rendering-driver opengl3 --log-file /tmp/log.txt -- --test --zrzuty=/tmp/zrzuty --zapis=/tmp/zapis.json`
- Co sprawdza dziś (21 kroków): Warownia, RB zakładki, start rajdu, ruch drążkiem, pochodnia blokuje parowanie, krzyżak ↓ rzuca pochodnię, LB paruje, X riposta, postura, A otwiera skrzynię, łup do sakwy, B zamyka okno, R3 zrzut sakwy, podniesienie sakwy, ekstrakcja, A wraca do Warowni, zapis, łup w skrytce, śmierć, Relikwiarz, połowa doświadczenia.
- Pomocnicze funkcje w `gra.gd`: `_pad(przycisk, czas)`, `_os(oś, wartość)`, `_czekaj(s)`, `_czekaj_az(warunek, limit)`, `_klatka()`, `_zrzut(nazwa)`, `_ok(nazwa, warunek, szczegół)`.
- Wróg „uśpiony” (`en.uspiony = true`) jest pomijany przez AI — do ustawiania scen w teście.
- Wynik: linia `WYNIK (godot): OK  (n/n)`; kod wyjścia 0 = OK.

## 7. Eksport

| Preset | Po co | Komenda (z katalogu `godot/`) |
|---|---|---|
| `Windows` | gra dla autora: jeden `.exe` z wszytym pck | `godot --headless --path . --export-release "Windows" ../dist/godot/Warownia_Popiolow.exe` |
| `Linux (kontrola agenta)` | sprawdzenie spakowanej gry w środowisku agenta | `godot --headless --path . --export-release "Linux (kontrola agenta)" /tmp/linux_kontrola/warownia.x86_64`, potem uruchom z `-- --test` pod `xvfb-run` |

Paczka dla autora: zip z `Warownia_Popiolow.exe` + `TEST_WAROWNIA_GODOT.bat` → folder autora `NIGHTBRAND\WAROWNIA_POPIOLOW`. Pliki `.exe`/`.zip` nie trafiają do repo. Windows może ostrzec o „nieznanym wydawcy” (brak podpisu) — uprzedź autora.

## 8. Środowisko agenta (Linux, jednorazowo na sesję)

```bash
# Godot 4.7.2
curl -L -o /tmp/g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -o -q /tmp/g.zip -d /opt/godot && ln -sf /opt/godot/Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot
godot --version   # 4.7.2.stable.official.ed1daf0bf

# Szablony eksportu (1,3 GB, ok. 1 min) — tylko gdy robisz .exe
curl -L -o /tmp/t.tpz https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
D=~/.local/share/godot/export_templates/4.7.2.stable && mkdir -p $D
unzip -o -q -j /tmp/t.tpz templates/version.txt templates/windows_release_x86_64.exe templates/linux_release.x86_64 -d $D

# Linter (opcjonalnie)
pip install --break-system-packages gdtoolkit
```
Wymagane systemowo: `xvfb-run` i Mesa (OpenGL) — w środowisku Claude zwykle są; sprawdź `which xvfb-run`.
Pierwsze uruchomienie po klonie: `godot --headless --path godot --import` (tworzy `godot/.godot/`, którego nie commitujemy).
