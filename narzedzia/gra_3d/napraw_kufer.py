# Kufer z Meshy (c05) nie ma UV ani tekstury: rozkład UV (Smart UV Project) + drewno z tekstur świata,
# okucia przyciemnione wg wysokości (dół i wieko ciemniejsze). Wynik -> godot/zasoby/3d/rekwizyty/kufer.glb
import bpy, os
Z = '/home/claude/rek2/c05_kufer.glb'
T = '/home/claude/extract/godot/zasoby/3d/swiat/'
WYJ = '/home/claude/extract/godot/zasoby/3d/rekwizyty/kufer.glb'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=Z)
o = [x for x in bpy.data.objects if x.type == 'MESH'][0]
bpy.context.view_layer.objects.active = o
o.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.01)
bpy.ops.object.mode_set(mode='OBJECT')
m = bpy.data.materials.new('kufer')
m.use_nodes = True
nt = m.node_tree
bs = nt.nodes['Principled BSDF']
def tex(nazwa, kolor):
    n = nt.nodes.new('ShaderNodeTexImage')
    n.image = bpy.data.images.load(T + nazwa)
    n.image.colorspace_settings.name = kolor
    return n
alb = tex('drewno_albedo.jpg', 'sRGB')
nor = tex('drewno_normal.png', 'Non-Color')
mul = nt.nodes.new('ShaderNodeMix')
mul.data_type = 'RGBA'
mul.blend_type = 'MULTIPLY'
mul.inputs['Factor'].default_value = 1.0
mul.inputs['B'].default_value = (0.55, 0.42, 0.32, 1.0)
nt.links.new(alb.outputs['Color'], mul.inputs['A'])
nt.links.new(mul.outputs['Result'], bs.inputs['Base Color'])
nm = nt.nodes.new('ShaderNodeNormalMap')
nt.links.new(nor.outputs['Color'], nm.inputs['Color'])
nt.links.new(nm.outputs['Normal'], bs.inputs['Normal'])
bs.inputs['Roughness'].default_value = 0.8
bs.inputs['Metallic'].default_value = 0.15
o.data.materials.clear()
o.data.materials.append(m)
# wypiek do jednej tekstury koloru (glTF nie zna węzła Mix): render Cycles bake
bpy.context.scene.render.engine = 'CYCLES'
bpy.context.scene.cycles.samples = 4
img = bpy.data.images.new('kufer_kolor', 1024, 1024)
bn = nt.nodes.new('ShaderNodeTexImage')
bn.image = img
nt.nodes.active = bn
bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=4)
img.filepath_raw = '/tmp/kufer_kolor.png'
img.file_format = 'PNG'
img.save()
nt.nodes.remove(mul)
nt.links.new(bn.outputs['Color'], bs.inputs['Base Color'])
nt.nodes.remove(alb)
if os.path.exists(WYJ):
    os.chmod(WYJ, 0o644)
bpy.ops.export_scene.gltf(filepath=WYJ, export_format='GLB', export_image_format='JPEG', export_image_quality=88)
print('ZAPISANO', WYJ, os.path.getsize(WYJ) // 1024, 'KB')
