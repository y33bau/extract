Stan na 2026-11-25, rola: gamedev

# Hadræn z modelu 3D → arkusze pixel-art

Potok, który zrobił obecny wygląd Hadræna (8 kierunków, broń w dłoni). Powtarzalny: podmień model albo animację i przebuduj.

## Źródła (poza repo — w folderze autora)
- **Model:** Meshy (konto autora), obraz referencyjny `NIGHTBRAND\WAROWNIA_POPIOLOW\PILOT_3D\`, model z obrazu → remesh 30k → rig humanoidalny (1,85 m) → pobranie FBX, szablon szkieletu **Mixamo**. Kości `mixamorig:*`, poza spoczynkowa **A**.
- **Animacje:** paczki Mixamo autora (`Downloads\Great Sword Pack.zip`, `Sword and Shield Pack.zip`, `Pro Melee Axe Pack.zip`, `Pro Longbow Pack.zip`), poza spoczynkowa **T**.

## Kroki (środowisko agenta, Linux)
```bash
python3.11 -m venv ~/blendvenv && ~/blendvenv/bin/pip install bpy==5.0.1 numpy pillow
# 1) render surowy (x2) jednego zestawu broni, wszystkie animacje, 8 kierunków:
~/blendvenv/bin/python produkcja.py -- '{"model":"/sciezka/hadraen.fbx","zestaw":"dwureczny","wyj":"/tmp/surowe"}'
#    zestawy: dwureczny, glewia, topor, miecz, miecz_tarcza, piesci  (ok. 8–15 min każdy na 2 rdzeniach)
# 2) pixel-art: zmniejszenie x2, twarda alfa, paleta 48 kolorów na zestaw, ciemny kontur 1 px
python3 piksele.py /tmp/surowe /tmp/arkusze
# 3) do gry: arkusze -> godot/zasoby/hadraen/, dane -> godot/dane/wyglad_bohatera.json
python3 skladaj.py /tmp/arkusze /sciezka/do/repo
```

## Jak to działa
- `potok.py` — przeniesienie ruchu T→A: dla każdej kości obrót świata ze źródła względem jego spoczynku, nałożony na kość celu wyrównaną kierunkiem do spoczynku źródła; biodra w miejscu (gra sama przesuwa postać). Broń: prosta bryła przypięta do `mixamorig:RightHand` (obrót 0,-90,0), tarcza do `LeftForeArm`. Kamera ortho 2:1 (elewacja 30°) — ten sam rzut co `iso.gd`.
- `produkcja.py` — lista animacji każdego zestawu (klip, przycięcie t0–t1, liczba klatek). Ciosy są przycięte tak, że zaczynają się od uniesionej broni, bo gra zadaje obrażenia od razu po naciśnięciu. Zapisuje też pozycję **lewej dłoni** w każdej klatce (płomień pochodni idzie za ręką).
- Wiersz arkusza `d` = postać zwrócona pod kątem świata `d·45°` (bez odbijania). Klatka 224×224, stopy w wierszu 176.

## Animacje w grze (`bohater.gd`)
`postoj`, `chod`, `atak1`, `atak2`, `atak3` (ciężki, 3. cios combo), `blok`, `parowanie` (pierwsze 0,35 s bloku z otwartym oknem), `przewrot` (unik), `smierc`.
