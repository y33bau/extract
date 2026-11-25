Stan na 2026-11-25, rola: gamedev

# Gra w 3D (Forward+): postacie, broń, rekwizyty

## Co jest gdzie
- `godot/skrypty/swiat3d.gd` — cały wygląd rajdu w 3D: loch z mapy (MultiMesh: podłoga, mury, filary), rekwizyty, światła, mgła wojny, przekrój murów przy graczu, kamera, postacie i animacje. Reguły nadal w `rajd.gd` (`GRAFIKA_3D := true`, `ZOOM_3D`).
- Kamera ortogonalna w rzucie `iso.gd` (64x32 px na pole, x zoom) — dlatego paski HP, napisy, efekty i HUD z 2D trafiają w postacie.
- `godot/zasoby/3d/postacie/` — `hadraen.glb` (37 animacji: `<styl>_<anim>`, style: dwureczny, topor, miecz, piesci; bronie i pochodnia przypięte do kości dłoni), `wrog_<typ>.glb` (postoj, chod, zamach, cios, trafienie, ogluszenie, smierc).
- `godot/zasoby/3d/rekwizyty/` — modele Meshy autora (folder `NIGHTBRAND\modele_meshy` i `meshy\partia8_z_malunkow`), tekstury zmniejszone do 1K.
- `godot/zasoby/3d/tekstury/` — kamień/deski/bale z Pobranych autora + mapy normal/rough (`tekstury.py`).

## Przebudowa postaci (Blender 5.0.1 jako bpy)
```bash
~/blendvenv/bin/python wypiekacz.py -- "$(cat cfg_hadraen.json)"   # albo cfg_<typ>.json dla wroga
```
`wypiekacz.py`: model Meshy (FBX, szkielet Mixamo, poza A) + klipy Mixamo z paczek autora (poza T) -> przeniesienie ruchu (`potok.py`), wypiekanie akcji, broń z `bronie.py`, podpięcie map PBR, eksport GLB (JPEG 92).
Ścieżki w cfg wskazują na rozpakowane modele (`/home/claude/postacie/<nazwa>`) i paczki (`/home/claude/anim/...`) — źródła są w folderze autora `WAROWNIA_POPIOLOW\3D modele warownia`.

## Testy
`testy.py godot` uruchamia grę z `--test` w trybie lekkim (bez cieni i efektów ekranowych, 3D w połowie rozdzielczości), bo w środowisku agenta render jest programowy (~2-5 FPS). Pełna jakość do zrzutów: `--rendering-driver vulkan -- --test --pelna` (lavapipe: `apt-get install mesa-vulkan-drivers`).

## Świat: tekstury NightBrand i oprawa map (25.11.2026)
- `tekstury_swiat.py` + `tekstury_swiat.json`: 13 tekstur z paczki autora `Downloads\GRAFIKI_SWIAT\GRAFIKI_SWIAT\tekstury` -> `godot/zasoby/3d/swiat/<nazwa>_albedo.jpg / _normal.png / _rh.png` (R szorstkość, G wysokość). Szwy wygładzane automatycznie.
- Wygląd krain: stała `WYGLAD` w `swiat3d.gd` (tekstury warstw, skale, kałuże, żar, kolory światła i mgły).
- Shadery: `godot/zasoby/3d/shadery/` (teren, mur, mgla, czastka).
- Podgląd bez grania: `godot --path godot --rendering-driver vulkan -- --pelna --podglad=catacombs,ZIARNO,/tmp/podglad` (5 zrzutów: start, kosze, ekstrakcja, wróg z zapowiedzią ciosu).

## Postacie: skręt kości i narzędzia kontrolne (25.11.2026)
- `potok.py` → `_skret`: przy przenoszeniu ruchu dopasowuje też skręt kości wokół osi (dłonie, przedramiona, kolana). Bez tego postacie Meshy w pozie A miały wykręcone ręce.
- `zblizenia.gd`: zbliżenia wszystkich postaci w Godocie (`godot --path godot --rendering-driver vulkan -s ../narzedzia/gra_3d/zblizenia.gd -- --wyj=/tmp/zb`).
- `plan_mapy.gd`: plan mapy z góry (`godot --headless --path godot -s ../narzedzia/gra_3d/plan_mapy.gd -- --kraina=crypt --ziarno=ABC --wyj=/tmp/plan.png`).
- `napraw_kufer.py`: UV + drewno dla kufra z Meshy (model źródłowy bez UV).
- Podgląd komnat: `--podglad=kraina,ziarno,katalog,komnaty` (po jednym ujęciu z każdego rodzaju komnaty).
