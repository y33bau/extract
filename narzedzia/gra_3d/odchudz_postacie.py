# Zmniejsza tekstury postaci, żeby paczka gry zmieściła się w limicie: NPC wszystko do 1K,
# wrogowie normal/metallic do 1K (kolor zostaje 2K — ostrość sylwetki). Bohater bez zmian.
import sys, glob, os
import bpy
D = '/home/claude/extract/godot/zasoby/3d/postacie/'
for f in sorted(glob.glob(D + 'npc_*.glb') + glob.glob(D + 'wrog_*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    npc = os.path.basename(f).startswith('npc_')
    for img in bpy.data.images:
        if img.size[0] > 1024 and (npc or 'baseColor' not in img.name):
            img.scale(1024, 1024)
    bpy.ops.export_scene.gltf(filepath=f, export_format='GLB', export_image_format='JPEG', export_image_quality=90, export_animations=True)
    print('ODCHUDZONO', os.path.basename(f), os.path.getsize(f) // 1024, 'KB')
