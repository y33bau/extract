import sys, glob, os, json
sys.path.insert(0,'/home/claude/render')
import bpy, potok as P
for f in sorted(glob.glob('/home/claude/extract/godot/zasoby/3d/rekwizyty/*.glb')):
    P.czysc()
    P.importuj(f)
    for img in bpy.data.images:
        if img.size[0] > 1024:
            img.scale(1024, 1024)
    bpy.ops.export_scene.gltf(filepath=f, export_format='GLB', export_image_format='JPEG', export_image_quality=90)
    print('ODCHUDZONO', os.path.basename(f), os.path.getsize(f)//1024, 'KB')
