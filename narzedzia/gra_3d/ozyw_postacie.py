# Ożywienie kolorów postaci z Meshy (tekstury wychodzą prawie bez koloru: nasycenie 2–10%).
# Dla każdego GLB z wypiekacza: tekstura koloru -> więcej nasycenia, cieplejsze półcienie (skóra, skóra wyprawiona,
# drewno), łagodna krzywa S i rozjaśnienie ciemnych tonów; normal/metal-szorstkość do 1K (rozmiar paczki).
# Użycie: blendvenv/bin/python ozyw_postacie.py -- <katalog_wej> <katalog_wyj> [nazwa.glb ...]
import sys, os, glob, json
import numpy as np
import bpy

arg = sys.argv[sys.argv.index('--') + 1:]
WEJ, WYJ = arg[0], arg[1]
TYLKO = arg[2:]

# siła korekty na postać: [nasycenie x, ciepło, rozjaśnienie cieni (gamma < 1 jaśniej)]
USTAWIENIA = {
    'npc_marga': [1.9, 0.05, 0.86], 'npc_chojrak': [1.7, 0.04, 0.86], 'npc_chlop': [1.9, 0.05, 0.85],
    'npc_przewoznik': [1.8, 0.04, 0.86],
    'wrog_scout': [1.5, 0.02, 0.9], 'wrog_warden': [1.6, 0.03, 0.9], 'wrog_knight': [1.5, 0.03, 0.88],
    'wrog_brute': [1.7, 0.04, 0.9], 'wrog_archer': [1.5, 0.02, 0.9], 'wrog_boss': [1.6, 0.03, 0.9],
}


def koryguj(img, nas, cieplo, gamma):
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = a[..., :3]
    # tekstury w glTF są sRGB; pracujemy na wartościach wyświetlanych
    lum = (rgb * np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)).sum(-1, keepdims=True)
    rgb = lum + (rgb - lum) * nas                      # nasycenie
    rgb = np.clip(rgb, 0.0, 1.0) ** gamma              # rozjaśnienie cieni
    pol = 4.0 * lum * (1.0 - lum)                      # waga półcieni (0 w czerni i bieli)
    rgb[..., 0] += cieplo * pol[..., 0]
    rgb[..., 1] += cieplo * 0.35 * pol[..., 0]
    rgb[..., 2] -= cieplo * 0.6 * pol[..., 0]
    rgb = np.clip(rgb, 0.0, 1.0)
    rgb = rgb + (rgb - 0.5) * 0.08 * (1.0 - np.abs(rgb - 0.5) * 2.0)  # łagodna krzywa S
    a[..., :3] = np.clip(rgb, 0.0, 1.0)
    img.pixels[:] = a.ravel()


pliki = sorted(glob.glob(os.path.join(WEJ, '*.glb')))
if TYLKO:
    pliki = [p for p in pliki if os.path.basename(p) in TYLKO]
for f in pliki:
    nazwa = os.path.splitext(os.path.basename(f))[0]
    if nazwa not in USTAWIENIA:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    nas, ciep, gam = USTAWIENIA[nazwa]
    for img in bpy.data.images:
        kolor = 'baseColor' in img.name or img.colorspace_settings.name == 'sRGB'
        if 'normal' in img.name.lower() or 'metallic' in img.name.lower() or 'roughness' in img.name.lower():
            kolor = False
        if kolor:
            koryguj(img, nas, ciep, gam)
            if img.size[0] > 2048:
                img.scale(2048, 2048)
        elif img.size[0] > 1024:
            img.scale(1024, 1024)
    wyj = os.path.join(WYJ, nazwa + '.glb')
    bpy.ops.export_scene.gltf(filepath=wyj, export_format='GLB', export_image_format='JPEG', export_image_quality=92,
                              export_animations=True, export_animation_mode='ACTIONS')
    print('OZYWIONO', nazwa, os.path.getsize(wyj) // 1024, 'KB', flush=True)
