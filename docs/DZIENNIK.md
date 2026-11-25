Stan na 2026-11-25, rola: agent główny

# DZIENNIK PROJEKTU

Jedno miejsce, w którym każdy agent (z każdego konta) zostawia ślad pracy. **Najnowszy wpis na górze.** Czytaj przed pracą, dopisuj przed końcem sesji.

## Wzór wpisu
```
## RRRR-MM-DD GG:MM — [konto / agent], rola: [agent główny / gamedev / grafik / koncepciarz / recenzent]
- Gałąź i commit:
- Zrobione:
- Testy (szybki/pelny) i wynik:
- NIE sprawdzone:
- Decyzje autora:
- Następny krok:
```

---

## 2026-11-25 10:40 — konto 1 (Claude, sesja Warownia), rola: gamedev
- Gałąź i commit: `godot-pilot` (od `fundament-i-dziennik`).
- Zrobione:
  - Krok 2: Godot **4.7.2** (najnowszy stabilny) działa w środowisku agenta: bez okna (`--headless`) oraz z renderem przez `xvfb-run` + Mesa (llvmpipe, OpenGL 4.5, renderer Compatibility). Symulowane wejście (`Input.parse_input_event`) i zrzuty ekranu działają.
  - Krok 3: pilot w `godot/`: jedna komnata izometryczna, Hadræn (arkusze z `zasoby/sprite`), Upadły Gwardzista (pościg, zamach ze złotym błyskiem, cios), parowanie → ogłuszenie → riposta, blok, unik, światło pochodni z silnika (PointLight2D + CanvasModulate), sterowanie mysz/klawiatura + pad (`skrypty/sterowanie.gd`).
  - Test automatyczny symuluje **pad** (lewy drążek, L1, X): `python3 narzedzia/testy.py godot`.
  - Eksport do Windows: jeden plik `Warownia_Pilot.exe` (110 MB, 39 MB w zip), dostarczony autorowi do `NIGHTBRAND\WAROWNIA_POPIOLOW\Warownia_Godot_Pilot.zip`. Plik exe nie jest w repo (`dist/godot/` w .gitignore).
- Testy: `testy.py godot` OK 6/6.
- NIE sprawdzone: uruchomienie .exe na Windows autora, prawdziwy pad (test symuluje zdarzenia pada), dźwięk (pilot bez dźwięku), wydajność na PC autora.
- Jak postawić Godota w środowisku agenta (Linux):
  - `curl -L -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip && unzip g.zip` → binarka jako `godot` w PATH.
  - Szablony eksportu (1,3 GB, ok. 1 min): `.../4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz`; wypakuj `templates/version.txt` i `templates/windows_*_x86_64*.exe` do `~/.local/share/godot/export_templates/4.7.2.stable/`.
  - Eksport: `godot --headless --path godot --export-release "Windows" ../dist/godot/Warownia_Pilot.exe`.
- Decyzje autora: czeka na decyzję po zagraniu w pilota (Godot vs JS).
- Następny krok: autor uruchamia `TEST_GODOT_PILOT.bat` (najlepiej z padem) i decyduje. Jeśli Godot: plan przenosin całości (3–5 sesji), nowe mechaniki dopiero po przeniesieniu.

## 2026-11-25 10:30 — konto 1 (Claude, sesja Warownia), rola: agent główny
- Gałąź i commit: `fundament-i-dziennik` (od `runda-1-walka`).
- Zrobione: `docs/FUNDAMENT.md` (z burzy mózgów z autorem), ten dziennik, `docs/START_TUTAJ.md`, `docs/INSTRUKCJE_PROJEKTU.md` (tekst do ustawień projektu Claude), zasady testów i dziennika w `CLAUDE.md`, wspólny skrypt `narzedzia/testy.py`.
- Testy: `testy.py pelny` OK 16/16, `szybki` OK 4/4 (Chromium, offline).
- NIE sprawdzone: granie ręczne, pad, dźwięk, itch.io.
- Decyzje autora (rozmowa głosowa, 25.11):
  - Fundament gry (jedno zdanie, trzy uczucia, pętla, śmierć, rajd 10–15 min, jeden bohater, broń = klasa, drabina biotopów, zakres v1): wszystko w `docs/FUNDAMENT.md`.
  - Pad obowiązkowy od pierwszej wersji (też menu i Warownia). Bez kooperacji i bez zadań fabularnych w v1.
  - Pierwsza wersja: 2 biotopy, Spalona Osada i Dolne Miasto, każdy z bossem.
  - Najpierw fundament, potem funkcje (lekcja z NightBrand).
  - Jeden dziennik dla wszystkich agentów; testy po każdej zmianie (szybki / pełny) + test autora z padem przed publikacją.
  - Silnik: wstępnie **Godot**, pod warunkiem że agent da radę go uruchomić i testować automatycznie. Kolejność: (1) fundament i dziennik w repo, (2) sprawdzenie Godota w środowisku agenta, (3) mała wersja testowa w Godocie (Hadræn chodzi, jeden wróg, pad, jeden test automatyczny), (4) decyzja: przenosimy całość albo zostajemy przy JS z uzasadnieniem. Do decyzji nie dodajemy nowych mechanik do wersji JS.
- Następny krok: krok (2), sprawdzenie Godota.

## 2026-11-25 09:30 — konto 1, rola: gamedev
- Gałąź i commit: `runda-1-walka` @ `afe1f5c`.
- Zrobione: postura wrogów, dylemat pochodni (F), ciężar i zrzut sakwy (G). Szczegóły: `docs/LOG_2026-11-25_runda1.md`.
- Testy: automatyczne w Chromium, bez błędów (parowanie z/bez pochodni, pęknięcie postury, sakwa, śmierć → plansza).
- NIE sprawdzone: granie ręczne i balans, pad, dźwięk, itch.io.
- Decyzje autora: 5 biotopów z pakietu 4; bez ubezpieczenia.

## 2026-11-25 09:15 — konto 1, rola: agent główny
- Gałąź i commit: `start-projektu` @ `d678a11`.
- Zrobione: założenie repo, prototyp podzielony na 12 skryptów + `narzedzia/zbuduj.py`, `CLAUDE.md`, `docs/KONCEPCJE.md`.
- Decyzje autora: Warownia to osobny projekt (repo `y33bau/extract`); wspólne lore z NightBrand, nowe wątki fabularne.
