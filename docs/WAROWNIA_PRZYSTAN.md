Stan na 2026-11-25, rola agent główny (grafik + gamedev)

# WAROWNIA-PRZYSTAŃ: projekt miejsca startowego

Decyzja autora (25.11.2026): Warownia to **przystań, po której Hadræn chodzi swobodnie**. Lokacja startowa przed każdą wyprawą i po niej. Są tu NPC (handlarze, zleceniodawcy, gawędziarze) oraz **obóz bohatera**, który rozbudowujemy o przydatne funkcje. To realizacja pomysłu „Warownia jako żywa makieta” z `KONCEPCJE.md` pkt 4, w 3D.

## 1. Rola w fundamencie
- **Dopamina:** widoczny postęp. Każdy poziom budynku zmienia jego wygląd (prowizorka → drewno i kamień → żelazo i runy), a łup z wyprawy ląduje fizycznie w obozie.
- **Strach i decyzja:** przed wyprawą wybierasz, co bierzesz, a resztę zostawiasz w Skrytce (Relikwiarz). Przystań to jedyne bezpieczne miejsce: ciepłe światło ognisk kontra czarna woda i mgła za palisadą.
- **Bez walki** w Przystani. Bez zadań fabularnych w v1. „Zleceniodawca” daje **kontrakty** (pomysł z KONCEPCJE, runda 5), a nie fabułę.

## 2. Układ (rzut izometryczny, ok. 30 × 30 m)
```
             (czarna woda, mgła)
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ~~  [ŁÓDŹ] = POMOST =  ~~~~~~~~      ← Przewoźnik: wyprawa (wybór krainy)
      ~~~~~~~~~~~ ||| ~~~~~~~~~~~~~~~
   PALISADA ======|||======= PALISADA
   |  [Kupiec Marga]  [Stół Wypraw/Tablica]   |   ← handel / kontrakty (Chojrak)
   |                                           |
   |  [Kuźnia]      ( OGNISKO )     [Zielarnia]|   ← obóz bohatera: serce Przystani
   |  kowadło,      gawędziarz       stół,     |
   |  miech         (Chłop)          zioła     |
   |                                           |
   |  [Ołtarz Żaru]   [Namiot Hadræna]  [Skrytka]|  ← umiejętności / ekwipunek
   |_____________ BRAMA (zamknięta) ___________|
```
- Wejście na wyprawę przez **pomost i łódź przewoźnika**: krainy leżą w górę i w dół rzeki.
- Ognisko w środku obozu to punkt orientacyjny i źródło światła.

## 3. Postacie (modele autora z `3D modele warownia`, wypiekane z animacjami Mixamo)
| NPC | Model | Funkcja w grze | Zakładka dziś |
|---|---|---|---|
| **Marga**, stara handlarka kośćmi | `npc_marga.glb` | Kupiec: kupno i sprzedaż | ⚖ Kupiec |
| **Chojrak**, stary upadły paladyn | `npc_chojrak.glb` | Stół Wypraw: wybór krainy, później kontrakty | ⚔ Wyprawa |
| **Chłop** przy ognisku | `npc_chlop.glb` | Gawędziarz: plotki, porady, lore świata (krótkie kwestie) | (dymek) |
| (później) **Heri**, weteran | do wypieczenia | Trener: umiejętności | 📜 Umiejętności |
| (później) **Przewoźnik** | do zrobienia (Meshy) | łódź = start wyprawy | ⚔ Wyprawa |

Do czasu przewoźnika wyprawę daje Chojrak przy pomoście.

## 4. Obóz bohatera: miejsca na rozbudowę (dzisiejsze budynki z `warownia.json`)
| Miejsce | Modele autora (modele_meshy) | Zakładka |
|---|---|---|
| Kuźnia | kowadło (15), miech (43), stojak (11/66), drewno (55) | 🏰 Warownia (budowa) |
| Zielarnia / Alchemik | stół (63), pulpit (62), regał (40) | 🏰 Warownia |
| Ołtarz Żaru | misa ofiarna (54), idol (59) | 🏰 Warownia + 📜 Umiejętności |
| Skrytka / Skarbiec | skarbiec (49), kufer | 🎒 Ekwipunek i Skrytka |
| Namiot Hadræna | namiot (47), skóry (56) | 🎒 Ekwipunek |

**Poziomy budynków (następna runda):** poziom 0 = puste miejsce (kopiec, szkic na ziemi), 1 = modele podstawowe, 2–3 = więcej modeli, światło, sztandary (12/14/17). Liczby i ceny bez zmian (balans autora).

## 5. Sterowanie (pad i klawiatura)
- Ruch: lewy drążek / WASD (jak w rajdzie). Bez ataku i uniku.
- **A / E przy postaci lub budynku** otwiera właściwą zakładkę Warowni (to samo menu co dziś). **B / Esc** wraca do chodzenia.
- **Back / Tab:** pełne menu Warowni (wszystkie zakładki), jak dotąd.
- Napis nad celem: „[A] Marga — handel”.

## 6. Etapy
1. **Runda 1 (teraz):** scena Przystani 3D z tekstur NightBrand i modeli autora, swobodny ruch, 3 NPC, obóz z pięcioma miejscami, interakcja otwiera zakładki, start wyprawy, powrót do Przystani po rajdzie. Testy na padzie.
2. Runda 2: wygląd budynków zależny od poziomu, dymki gawędziarza (pula kwestii), łódź i przewoźnik (Meshy).
3. Runda 3: kontrakty Chojraka (KONCEPCJE runda 5), ślady łupu w obozie po wyprawie.

## 7. Czego nie robimy
- Walki i wrogów w Przystani; zadań fabularnych (v1); nowych walut i cen bez zgody autora.
