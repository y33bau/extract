# NPC prosto z Meshy (model w pozie T + rig Meshy + animacje z biblioteki Meshy, jeden plik GLB):
# animacje są na tym samym szkielecie — bez przenoszenia ruchu, więc bez wykrzywień.
# Skrypt: nazwy animacji -> nazwy gry (postoj, postoj2, rozglad, chod), lekkie ożywienie koloru,
# normal / metal-szorstkość do 1K, kolor 2K.
# Użycie: blendvenv/bin/python npc_z_meshy.py -- <wej.glb> <wyj.glb> '<json mapy nazw>' [nasycenie]
import sys, os, json
import numpy as np
import bpy

arg = sys.argv[sys.argv.index('--') + 1:]
WEJ, WYJ, MAPA = arg[0], arg[1], json.loads(arg[2])
NAS = float(arg[3]) if len(arg) > 3 else 1.25

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=WEJ)
for a in list(bpy.data.actions):
    if a.name in MAPA:
        a.name = MAPA[a.name]
        a.use_fake_user = True
    else:
        bpy.data.actions.remove(a)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
if arm.animation_data:
    arm.animation_data.action = None
    for t in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(t)
for img in bpy.data.images:
    n = img.name.lower()
    if 'normal' in n or 'metallic' in n or 'rough' in n:
        if img.size[0] > 1024:
            img.scale(1024, 1024)
        continue
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = a[..., :3]
    lum = (rgb * np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)).sum(-1, keepdims=True)
    a[..., :3] = np.clip(lum + (rgb - lum) * NAS, 0.0, 1.0) ** 0.94
    img.pixels[:] = a.ravel()
bpy.ops.export_scene.gltf(filepath=WYJ, export_format='GLB', export_image_format='JPEG', export_image_quality=92,
                          export_animations=True, export_animation_mode='ACTIONS')
print('NPC', os.path.basename(WYJ), os.path.getsize(WYJ) // 1024, 'KB', sorted(MAPA.values()))
