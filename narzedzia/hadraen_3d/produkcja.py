# Produkcja arkuszy Hadræna: jeden zestaw (broń) = arkusze wszystkich animacji, 8 kierunków.
# Wynik surowy: <wyj>/<zestaw>/<anim>/d<kierunek>_<klatka>.png (render x2)
import sys, os, math, json, time
cfg = json.loads(sys.argv[-1])
sys.path.insert(0, '/home/claude/render')
import bpy
import potok as P
from bpy_extras.object_utils import world_to_camera_view

G = '/home/claude/anim/Great Sword Pack/'
S = '/home/claude/anim/Sword and Shield Pack/'
A = '/home/claude/anim/Pro Melee Axe Pack/'
L = '/home/claude/anim/Pro Longbow Pack/'

# animacja: (klip, t0, t1, klatki, petla)
ANIM_DWURECZNY = {
    'postoj': (G + 'great sword idle.fbx', 0.0, 1.0, 6, True),
    'chod': (G + 'great sword walk.fbx', 0.0, 1.0, 8, True),
    'atak1': (G + 'great sword slash.fbx', 0.2, 0.8, 6, False),
    'atak2': (G + 'great sword slash (3).fbx', 0.18, 0.75, 6, False),
    'atak3': (G + 'great sword slash (5).fbx', 0.15, 0.75, 7, False),
    'blok': (G + 'great sword blocking (2).fbx', 0.2, 0.8, 4, True),
    'parowanie': (G + 'great sword blocking (3).fbx', 0.0, 0.7, 4, False),
    'przewrot': (L + 'standing dive forward.fbx', 0.0, 0.62, 7, False),
    'smierc': (G + 'two handed sword death.fbx', 0.0, 1.0, 8, False),
}
ANIM_TOPOR = {
    'postoj': (A + 'standing idle.fbx', 0.0, 1.0, 6, True),
    'chod': (A + 'standing walk forward.fbx', 0.0, 1.0, 8, True),
    'atak1': (A + 'standing melee attack horizontal.fbx', 0.05, 0.75, 6, False),
    'atak2': (A + 'standing melee attack backhand.fbx', 0.05, 0.75, 6, False),
    'atak3': (A + 'standing melee attack downward.fbx', 0.0, 0.75, 7, False),
    'blok': (A + 'standing block idle.fbx', 0.0, 1.0, 4, True),
    'parowanie': (A + 'standing block react large.fbx', 0.0, 0.6, 4, False),
    'przewrot': (L + 'standing dive forward.fbx', 0.0, 0.62, 7, False),
    'smierc': (G + 'two handed sword death.fbx', 0.0, 1.0, 8, False),
}
ANIM_MIECZ = {
    'postoj': (S + 'sword and shield idle.fbx', 0.0, 1.0, 6, True),
    'chod': (S + 'sword and shield walk.fbx', 0.0, 1.0, 8, True),
    'atak1': (S + 'sword and shield slash.fbx', 0.05, 0.75, 6, False),
    'atak2': (S + 'sword and shield slash (2).fbx', 0.05, 0.75, 6, False),
    'atak3': (S + 'sword and shield attack.fbx', 0.0, 0.75, 7, False),
    'blok': (S + 'sword and shield block idle.fbx', 0.0, 1.0, 4, True),
    'parowanie': (S + 'sword and shield block.fbx', 0.0, 0.6, 4, False),
    'przewrot': (L + 'standing dive forward.fbx', 0.0, 0.62, 7, False),
    'smierc': (S + 'sword and shield death.fbx', 0.0, 1.0, 8, False),
}
ANIM_PIESCI = {
    'postoj': (A + 'unarmed idle.fbx', 0.0, 1.0, 6, True),
    'chod': (A + 'unarmed walk forward.fbx', 0.0, 1.0, 8, True),
    'atak1': (L + 'standing melee punch.fbx', 0.0, 0.8, 6, False),
    'atak2': (L + 'standing melee punch.fbx', 0.0, 0.8, 6, False),
    'atak3': (A + 'standing melee attack kick ver. 1.fbx', 0.0, 0.8, 7, False),
    'blok': (A + 'standing block idle.fbx', 0.0, 1.0, 4, True),
    'parowanie': (A + 'standing block react large.fbx', 0.0, 0.6, 4, False),
    'przewrot': (L + 'standing dive forward.fbx', 0.0, 0.62, 7, False),
    'smierc': (L + 'standing death forward 01.fbx', 0.0, 1.0, 8, False),
}
ZESTAWY = {
    'dwureczny': (ANIM_DWURECZNY, [('dwureczny', 'mixamorig:RightHand', (0, 0.06, 0), (0, -90, 0))]),
    'glewia': (ANIM_DWURECZNY, [('glewia', 'mixamorig:RightHand', (0, 0.06, 0), (0, -90, 0))]),
    'topor': (ANIM_TOPOR, [('topor', 'mixamorig:RightHand', (0, 0.06, 0), tuple(cfg.get('rot_topor', (0, -90, 0))))]),
    'miecz': (ANIM_MIECZ, [('miecz', 'mixamorig:RightHand', (0, 0.06, 0), tuple(cfg.get('rot_miecz', (0, -90, 0))))]),
    'miecz_tarcza': (ANIM_MIECZ, [('miecz', 'mixamorig:RightHand', (0, 0.06, 0), tuple(cfg.get('rot_miecz', (0, -90, 0)))),
                                  ('tarcza', 'mixamorig:LeftForeArm', tuple(cfg.get('lok_tarcza', (0.0, -0.08, 0.07))), tuple(cfg.get('rot_tarcza', (0, 0, 90))))]),
    'piesci': (ANIM_PIESCI, []),
}

zestaw = cfg['zestaw']
anim, bronie = ZESTAWY[zestaw]
tylko = cfg.get('anim')  # opcjonalnie lista animacji
kierunki = cfg.get('kier', list(range(8)))

P.czysc()
cel = P.szkielet(P.importuj(cfg['model']))
if cel.animation_data:
    cel.animation_data_clear()
piv = bpy.data.objects.new('piwot', None)
bpy.context.scene.collection.objects.link(piv)
cel.parent = piv
for rodzaj, kosc, lok, rot in bronie:
    b = P.zbuduj_bron(rodzaj)
    P.przypnij(b, cel, kosc, lok, [math.radians(a) for a in rot])
sc = P.scena(P.KOMORKA * P.NADPROBKA)
start = time.time()
for nazwa, (klip, t0, t1, n, petla) in anim.items():
    if tylko and nazwa not in tylko:
        continue
    zo = P.importuj(klip)
    zr = P.szkielet(zo)
    zr.hide_render = True
    f0, f1 = zr.animation_data.action.frame_range
    if petla:
        ts = [t0 + (t1 - t0) * i / n for i in range(n)]
    else:
        ts = [t0 + (t1 - t0) * i / (n - 1) for i in range(n)]
    pozy = P.przenies(cel, zr, [f0 + (f1 - f0) * t for t in ts])
    kat = f"{cfg['wyj']}/{zestaw}/{nazwa}"
    os.makedirs(kat, exist_ok=True)
    dlonie = {}
    for i, pz in enumerate(pozy):
        P.ustaw_poze(cel, pz)
        for d in kierunki:
            piv.rotation_euler = (0, 0, math.radians(90 - 45 * d))
            bpy.context.view_layer.update()
            pw = cel.matrix_world @ cel.pose.bones['mixamorig:LeftHand'].head
            v = world_to_camera_view(sc, sc.camera, pw)
            dlonie.setdefault(str(d), []).append([round(v.x * P.KOMORKA, 1), round((1 - v.y) * P.KOMORKA, 1)])
            sc.render.filepath = f"{kat}/d{d}_{i:02d}.png"
            bpy.ops.render.render(write_still=True)
    json.dump(dlonie, open(f"{kat}/dlon.json", 'w'))
    print('ANIM', zestaw, nazwa, n, 'klatek', round(time.time() - start), 's', flush=True)
    for o in zo:
        bpy.data.objects.remove(o, do_unlink=True)
print('KONIEC', zestaw)
