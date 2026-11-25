# Postać Meshy + animacje Mixamo -> GLB z wszystkimi akcjami, bronią przypiętą do dłoni i pełnym PBR.
import sys, os, math, json, glob
cfg = json.loads(sys.argv[-1])
sys.path.insert(0, '/home/claude/render')
import bpy
import potok as P
import bronie as BR

FPS = 30


def podlacz_pbr(katalog):
    """Meshy FBX: podłącz mapy normal/metallic/roughness do materiału."""
    for m in bpy.data.materials:
        if not m.use_nodes:
            continue
        nt = m.node_tree
        bs = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if bs is None:
            continue
        for przyr, wejscie, kolor in [('_normal', 'Normal', 'Non-Color'), ('_metallic', 'Metallic', 'Non-Color'), ('_roughness', 'Roughness', 'Non-Color')]:
            pl = glob.glob(f'{katalog}/*{przyr}.png')
            if not pl or bs.inputs[wejscie].is_linked and wejscie != 'Normal':
                continue
            img = bpy.data.images.load(pl[0], check_existing=True)
            img.colorspace_settings.name = kolor
            tn = nt.nodes.new('ShaderNodeTexImage')
            tn.image = img
            if wejscie == 'Normal':
                if bs.inputs['Normal'].is_linked:
                    continue
                nm = nt.nodes.new('ShaderNodeNormalMap')
                nt.links.new(tn.outputs['Color'], nm.inputs['Color'])
                nt.links.new(nm.outputs['Normal'], bs.inputs['Normal'])
            else:
                nt.links.new(tn.outputs['Color'], bs.inputs[wejscie])
        print('PBR', m.name, [i.name for i in bs.inputs if i.is_linked])


P.czysc()
model = glob.glob(cfg['katalog'] + '/*.fbx')[0]
obj = P.importuj(model)
cel = P.szkielet(obj)
if cel.animation_data:
    cel.animation_data_clear()
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
podlacz_pbr(cfg['katalog'])
cel.name = 'szkielet'
for o in obj:
    if o.type == 'MESH':
        o.name = 'cialo'

# broń i rekwizyty w dłoniach
for b in cfg.get('bronie', []):
    o = BR.zbuduj(b['rodzaj'])
    o.name = b['nazwa']
    P.przypnij(o, cel, b['kosc'], b.get('lok', (0, 0.06, 0)), [math.radians(x) for x in b.get('rot', (0, -90, 0))])

for pb in cel.pose.bones:
    pb.rotation_mode = 'QUATERNION'
cel.animation_data_create()
for nazwa, (klip, t0, t1) in cfg['akcje'].items():
    zo = P.importuj(klip)
    zr = P.szkielet(zo)
    akc_zr = zr.animation_data.action
    f0, f1 = akc_zr.frame_range
    a0, a1 = f0 + (f1 - f0) * t0, f0 + (f1 - f0) * t1
    n = max(2, int(round(a1 - a0)) + 1)
    klatki = [a0 + (a1 - a0) * i / (n - 1) for i in range(n)]
    pozy = P.przenies(cel, zr, klatki)
    akc = bpy.data.actions.new(nazwa)
    akc.use_fake_user = True
    cel.animation_data.action = akc
    for i, pz in enumerate(pozy):
        P.ustaw_poze(cel, pz)
        for pb in cel.pose.bones:
            pb.keyframe_insert('rotation_quaternion', frame=i + 1)
            if pb.parent is None:
                pb.keyframe_insert('location', frame=i + 1)
    print('AKCJA', nazwa, n, 'klatek', flush=True)
    for o in zo:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.actions.remove(akc_zr)
    for a in list(bpy.data.actions):
        if not a.use_fake_user:
            bpy.data.actions.remove(a)
cel.animation_data.action = None
for pb in cel.pose.bones:
    pb.rotation_quaternion = (1, 0, 0, 0)
    pb.location = (0, 0, 0)
bpy.context.scene.render.fps = FPS
os.makedirs(os.path.dirname(cfg['wyj']), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=cfg['wyj'], export_format='GLB', export_animation_mode='ACTIONS',
                          export_force_sampling=True, export_image_format='JPEG', export_image_quality=92,
                          export_apply=False, export_yup=True)
print('ZAPISANO', cfg['wyj'], os.path.getsize(cfg['wyj']) // 1024, 'KB')
