# Łódź przewoźnika z Meshy (894k ścian) -> 24k ścian, tekstury 1K -> zasoby/3d/przystan/lodz.glb
# Użycie: blendvenv/bin/python odchudz_lodz.py  (wejście: /home/claude/lodz_in/lodz_raw.glb)
import bpy, os
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='/home/claude/lodz_in/lodz_raw.glb')
for o in bpy.data.objects:
    if o.type=='MESH':
        n=len(o.data.polygons); m=o.modifiers.new('d','DECIMATE'); m.ratio=min(1.0,24000/n)
        bpy.context.view_layer.objects.active=o; o.select_set(True)
        bpy.ops.object.modifier_apply(modifier='d'); print('scian',n,'->',len(o.data.polygons))
        print('wym',tuple(round(v,2) for v in o.dimensions))
for img in bpy.data.images:
    if img.size[0]>1024: img.scale(1024,1024)
out='/home/claude/extract/godot/zasoby/3d/przystan/lodz.glb'
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_image_format='JPEG', export_image_quality=88)
print('ZAPISANO', os.path.getsize(out)//1024,'KB')
