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
