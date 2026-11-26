Stan na 2026-11-26, rola: agent główny (Claude)

# Instrukcje ról dla ChatGPT / Codex

Główny dokument: `../PRZEKAZANIE_CHATGPT_2026-11-26.md` (przeczytaj najpierw).

| Plik | Rola | Zmienia kod? |
|---|---|---|
| `ROLA_AGENT_GLOWNY_WAROWNIA.md` | prowadzenie projektu, start sesji, plan rund, dokumenty, publikacja | tylko dokumenty |
| `ROLA_GAMEDEV_WAROWNIA.md` | mechaniki, generator, interfejs, sterowanie, testy, eksport | tak |
| `ROLA_GRAFIK_WAROWNIA.md` | wygląd: materiały, światło, modele z biblioteki, shadery, UI, prompty | tak (zasoby i wygląd) |
| `ROLA_RECENZENT_WAROWNIA.md` | przegląd kodu i gry, spójność, ryzyka | nie |
| `ROLA_MENTOR_NIGHTBRAND.md` | ocena i podpowiedzi z doświadczenia NightBrand, zadania dla wykonawcy | nie |

Jak użyć:
- **ChatGPT:** wklej treść roli jako instrukcję projektu albo własnego GPT, albo dodaj plik do wiedzy projektu.
- **Codex:** wskaż plik roli w poleceniu („pracuj według `docs/chatgpt/ROLA_GAMEDEV_WAROWNIA.md`”).

Jedna rola naraz. W meldunku zawsze podaj rolę.

Odpowiedniki w Claude (skille na koncie autora):
- `warownia-start` (agent główny);
- `warownia-gamedev`;
- `warownia-grafik`;
- `mentor-nightbrand`;
- recenzent: tylko `docs/ROLE.md` i ten plik.
