# Arkusze z piksele.py -> godot/zasoby/hadraen/ + godot/dane/wyglad_bohatera.json
import sys, os, json, shutil
import numpy as np
from PIL import Image

ARK, REPO = sys.argv[1], sys.argv[2]
KOM, STOPY = 224, 176
WZROST_EKRAN = 86.0  # docelowa wysokość postaci na ekranie (px), stary sprite ~82

man = json.load(open(f'{ARK}/_manifest.json'))
dlon = man.pop('_dlon', {})
cel = f'{REPO}/godot/zasoby/hadraen'
os.makedirs(cel, exist_ok=True)
for z, animy in man.items():
    for a in animy:
        shutil.copy(f'{ARK}/{z}_{a}.png', f'{cel}/{z}_{a}.png')

# skala z wysokości postaci bez broni (postój, wszystkie kierunki)
wys = []
im = np.asarray(Image.open(f'{ARK}/piesci_postoj.png'))[..., 3]
n = man['piesci']['postoj']
for d in range(8):
    for i in range(n):
        k = im[d * KOM:(d + 1) * KOM, i * KOM:(i + 1) * KOM]
        rows = np.where(k.max(1) > 0)[0]
        if len(rows):
            wys.append(rows[-1] - rows[0])
skala = round(WZROST_EKRAN / float(np.median(wys)), 3)

wyglad = {
    "_opis": "Wygląd Hadræna z modelu 3D (Meshy) renderowanego w Blenderze. Generator: narzedzia/hadraen_3d/. Wiersz arkusza d = kąt świata d*45°.",
    "komorka": KOM,
    "stopy_y": STOPY,
    "skala": skala,
    "bron_zestaw": {
        "ash_greatsword": "dwureczny",
        "warden_glaive": "glewia",
        "executioner_axe": "topor",
        "rusty_sword": "miecz",
        "steel_falchion": "miecz",
    },
    "domyslny": "dwureczny",
    "bez_broni": "piesci",
    "z_tarcza": {"miecz": "miecz_tarcza"},
    "klatki": man,
    "dlon": dlon,
}
json.dump(wyglad, open(f'{REPO}/godot/dane/wyglad_bohatera.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print('skala', skala, 'mediana wysokości', float(np.median(wys)), 'zestawy', list(man))
