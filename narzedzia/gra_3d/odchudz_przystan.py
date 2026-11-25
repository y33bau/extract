import sys, glob, os
import bpy
for f in sorted(glob.glob('/home/claude/extract/godot/zasoby/3d/przystan/*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    for img in bpy.data.images:
        if img.size[0] > 1024:
            img.scale(1024, 1024)
    bpy.ops.export_scene.gltf(filepath=f, export_format='GLB', export_image_format='JPEG', export_image_quality=88)
    print('ODCHUDZONO', os.path.basename(f), os.path.getsize(f)//1024, 'KB')
