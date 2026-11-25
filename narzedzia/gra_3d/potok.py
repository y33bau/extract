# Potok: model Meshy (szkielet mixamorig, poza A) + animacje Mixamo (poza T)
# -> przeniesienie ruchu -> broń w dłoni -> render izometryczny 8 kierunków.
import bpy, math, sys, json, os
from mathutils import Matrix, Vector, Quaternion

ARG = json.loads(sys.argv[sys.argv.index('--') + 1])

KOMORKA = ARG.get('komorka', 224)      # px klatki w grze
NADPROBKA = ARG.get('nadprobka', 2)    # render w x2, potem zmniejszenie
STOPY_Y = ARG.get('stopy_y', 176)      # wiersz stóp w klatce
PX_NA_M = ARG.get('px_na_m', 56.0)     # skala postaci


def czysc():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def importuj(sciezka):
    przed = set(bpy.data.objects)
    if sciezka.lower().endswith('.fbx'):
        bpy.ops.import_scene.fbx(filepath=sciezka)
    else:
        bpy.ops.import_scene.gltf(filepath=sciezka)
    return [o for o in bpy.data.objects if o not in przed]


def szkielet(obiekty):
    return [o for o in obiekty if o.type == 'ARMATURE'][0]


# ---------- przeniesienie animacji ----------
def _odniesienie(n, arm, mw):
    """Wektor poprzeczny kości w spoczynku (świat), niezależny od konwencji „roll”:
    ręce i palce -> linia knykci (wskazujący -> mały), uda i łydki -> kierunek stopy, stopy -> biodro L -> P."""
    k = arm.data.bones
    pre = 'mixamorig:'
    for strona in ('Left', 'Right'):
        if n.startswith(pre + strona + 'Arm') or n.startswith(pre + strona + 'ForeArm') or n.startswith(pre + strona + 'Hand'):
            a, b = pre + strona + 'HandIndex1', pre + strona + 'HandPinky1'
            if a in k and b in k:
                return mw @ k[a].head_local - mw @ k[b].head_local
        if n in (pre + strona + 'UpLeg', pre + strona + 'Leg'):
            a, b = pre + strona + 'ToeBase', pre + strona + 'Foot'
            if a in k and b in k:
                return mw @ k[a].head_local - mw @ k[b].head_local
        if n in (pre + strona + 'Foot', pre + strona + 'ToeBase'):
            a, b = pre + 'LeftUpLeg', pre + 'RightUpLeg'
            if a in k and b in k:
                return mw @ k[a].head_local - mw @ k[b].head_local
    return None


def _skret(n, cel, zrodlo, mwc, mws, ds, wyr):
    """Obrót wokół osi kości (ds), który po wyrównaniu kierunku dopasowuje też skręt (dłonie, kolana)."""
    vc, vs = _odniesienie(n, cel, mwc), _odniesienie(n, zrodlo, mws)
    if vc is None or vs is None:
        return Quaternion()
    vc = wyr @ vc
    vc = vc - ds * vc.dot(ds)
    vs = vs - ds * vs.dot(ds)
    if vc.length < 1e-4 or vs.length < 1e-4:
        return Quaternion()
    vc.normalize(); vs.normalize()
    kat = math.atan2(ds.dot(vc.cross(vs)), vc.dot(vs))
    return Quaternion(ds, kat)


def przenies(cel, zrodlo, klatki, w_miejscu=True, korekta_skretu=True):
    """Kopiuje ruch ze szkieletu zrodlo (T) na cel (A). Zwraca listę klatek celu."""
    sc = bpy.context.scene
    mwc, mws = cel.matrix_world, zrodlo.matrix_world
    wspolne = [b.name for b in cel.data.bones if b.name in zrodlo.data.bones]
    # spoczynek w świecie
    rest_c = {n: mwc @ cel.data.bones[n].matrix_local for n in wspolne}
    rest_s = {n: mws @ zrodlo.data.bones[n].matrix_local for n in wspolne}
    wyr = {}
    for n in wspolne:
        bc, bs = cel.data.bones[n], zrodlo.data.bones[n]
        dc = (mwc @ bc.tail_local - mwc @ bc.head_local).normalized()
        ds = (mws @ bs.tail_local - mws @ bs.head_local).normalized()
        wyr[n] = dc.rotation_difference(ds)
        if korekta_skretu:
            wyr[n] = _skret(n, cel, zrodlo, mwc, mws, ds, wyr[n]) @ wyr[n]
    biodra = 'mixamorig:Hips'
    h_c = (mwc @ cel.data.bones[biodra].head_local).z
    h_s = (mws @ zrodlo.data.bones[biodra].head_local).z
    skala = h_c / h_s if h_s else 1.0
    for pb in cel.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    kolejnosc = [b for b in cel.data.bones]  # bones są w kolejności rodzic->dziecko
    wynik = []
    for f in klatki:
        sc.frame_set(int(math.floor(f)), subframe=f - math.floor(f))
        swiat = {}
        for b in kolejnosc:
            n = b.name
            if n in wspolne:
                Ms = mws @ zrodlo.pose.bones[n].matrix
                rot = (Ms.to_quaternion() @ rest_s[n].to_quaternion().inverted()) @ wyr[n] @ rest_c[n].to_quaternion()
            else:
                rot = None
            if b.parent is None:
                if n == biodra and n in wspolne:
                    Hs = (mws @ zrodlo.pose.bones[n].matrix).translation
                    Hs0 = rest_s[n].translation
                    d = (Hs - Hs0) * skala
                    if w_miejscu:
                        d.x = 0.0
                        d.y = 0.0
                    glowa = rest_c[n].translation + d
                else:
                    glowa = (mwc @ b.matrix_local).translation
                if rot is None:
                    rot = (mwc @ b.matrix_local).to_quaternion()
            else:
                P = swiat[b.parent.name]
                off = (b.parent.matrix_local.inverted() @ b.matrix_local)
                glowa = (P @ off).translation
                if rot is None:
                    rot = (P @ off).to_quaternion()
            swiat[n] = Matrix.Translation(glowa) @ rot.to_matrix().to_4x4()
        wynik.append(swiat)
    return wynik


def ustaw_poze(cel, swiat):
    inv = cel.matrix_world.inverted()
    for b in cel.data.bones:
        pb = cel.pose.bones[b.name]
        arm = inv @ swiat[b.name]
        if b.parent is None:
            baza = b.matrix_local.inverted() @ arm
        else:
            parm = inv @ swiat[b.parent.name]
            baza = (b.matrix_local.inverted() @ b.parent.matrix_local) @ parm.inverted() @ arm
        loc, rot, _ = baza.decompose()
        pb.rotation_quaternion = rot
        pb.location = loc if b.parent is None else Vector()
        pb.scale = Vector((1, 1, 1))


# ---------- broń ----------
def material(nazwa, kolor, metal=0.8, szorstk=0.45, emisja=None):
    m = bpy.data.materials.new(nazwa)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*kolor, 1)
    bs.inputs['Metallic'].default_value = metal
    bs.inputs['Roughness'].default_value = szorstk
    if emisja:
        bs.inputs['Emission Color'].default_value = (*emisja, 1)
        bs.inputs['Emission Strength'].default_value = 3.0
    return m


def prostopadloscian(nazwa, rozmiar, srodek, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=srodek)
    o = bpy.context.active_object
    o.name = nazwa
    o.scale = rozmiar
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat)
    return o


def zbuduj_bron(rodzaj):
    """Broń w lokalnym układzie: rękojeść w (0,0,0), ostrze wzdłuż +Z."""
    stal = material('stal', (0.24, 0.24, 0.26), 0.85, 0.5)
    ciemna = material('ciemna_stal', (0.09, 0.09, 0.1), 0.8, 0.62)
    skora = material('skora', (0.18, 0.1, 0.06), 0.0, 0.8)
    drewno = material('drewno', (0.25, 0.15, 0.08), 0.0, 0.7)
    czesci = []
    if rodzaj == 'dwureczny':  # wielki, ciężki miecz jak płyta żelaza
        czesci += [prostopadloscian('rekojesc', (0.045, 0.045, 0.34), (0, 0, 0.0), skora),
                   prostopadloscian('jelec', (0.32, 0.06, 0.06), (0, 0, 0.2), ciemna),
                   prostopadloscian('ostrze', (0.2, 0.035, 1.35), (0, 0, 0.9), ciemna),
                   prostopadloscian('glowica', (0.08, 0.08, 0.08), (0, 0, -0.2), ciemna)]
    elif rodzaj == 'glewia':
        czesci += [prostopadloscian('drzewce', (0.04, 0.04, 1.9), (0, 0, 0.3), drewno),
                   prostopadloscian('grot', (0.13, 0.03, 0.55), (0.03, 0, 1.5), stal)]
    elif rodzaj == 'topor':
        czesci += [prostopadloscian('trzonek', (0.045, 0.045, 1.05), (0, 0, 0.25), drewno),
                   prostopadloscian('ostrze', (0.36, 0.035, 0.32), (0.16, 0, 0.68), ciemna),
                   prostopadloscian('obuch', (0.1, 0.07, 0.12), (-0.06, 0, 0.68), ciemna)]
    elif rodzaj == 'miecz':
        czesci += [prostopadloscian('rekojesc', (0.035, 0.035, 0.16), (0, 0, 0.0), skora),
                   prostopadloscian('jelec', (0.2, 0.04, 0.035), (0, 0, 0.1), ciemna),
                   prostopadloscian('ostrze', (0.07, 0.02, 0.8), (0, 0, 0.51), stal)]
    elif rodzaj == 'tarcza':
        czesci += [prostopadloscian('tarcza', (0.5, 0.05, 0.62), (0, 0, 0), material('drewno_t', (0.12, 0.07, 0.04), 0.0, 0.75)),
                   prostopadloscian('okucie', (0.54, 0.055, 0.06), (0, 0.005, 0.0), ciemna),
                   prostopadloscian('okucie2', (0.06, 0.055, 0.66), (0, 0.005, 0.0), ciemna)]
    if not czesci:
        return None
    bpy.ops.object.select_all(action='DESELECT')
    for c in czesci:
        c.select_set(True)
    bpy.context.view_layer.objects.active = czesci[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = 'bron_' + rodzaj
    return o


def przypnij(obiekt, cel, kosc, lok, rot_euler):
    obiekt.parent = cel
    obiekt.parent_type = 'BONE'
    obiekt.parent_bone = kosc
    # układ kości: pozycja względem ogona kości
    dl = cel.data.bones[kosc].length
    obiekt.matrix_parent_inverse = Matrix()
    obiekt.location = Vector(lok) - Vector((0, dl, 0))
    obiekt.rotation_euler = rot_euler


# ---------- scena i render ----------
def scena(rozmiar_px):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = ARG.get('probki', 6)
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 2
    sc.render.resolution_x = sc.render.resolution_y = rozmiar_px
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.view_settings.exposure = ARG.get('ekspozycja', 1.15)
    # kamera izometryczna 2:1 (elewacja 30°), patrzy wzdłuż (-1, 1)
    cam_d = bpy.data.cameras.new('kam')
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = KOMORKA / PX_NA_M
    cam_d.shift_y = (STOPY_Y - KOMORKA / 2) / KOMORKA
    cam = bpy.data.objects.new('kam', cam_d)
    sc.collection.objects.link(cam)
    r = 10.0
    el = math.radians(30)
    cam.location = Vector((r * math.cos(el) / math.sqrt(2), -r * math.cos(el) / math.sqrt(2), r * math.sin(el)))
    kier = (Vector((0, 0, 0)) - cam.location).normalized()
    cam.rotation_euler = kier.to_track_quat('-Z', 'Y').to_euler()
    sc.camera = cam
    # światło: klucz z góry-lewej, wypełnienie, kontra
    def slonce(nazwa, moc, rot, kolor):
        L = bpy.data.lights.new(nazwa, 'SUN')
        L.energy = moc
        L.color = kolor
        L.angle = math.radians(8)
        o = bpy.data.objects.new(nazwa, L)
        sc.collection.objects.link(o)
        o.rotation_euler = [math.radians(a) for a in rot]
    slonce('klucz', 4.2, (35, 0, -150), (1.0, 0.93, 0.85))
    slonce('wypel', 1.1, (60, 0, 60), (0.75, 0.8, 1.0))
    slonce('kontra', 3.4, (110, 0, 135), (1.0, 0.8, 0.65))
    w = bpy.data.worlds.new('swiat')
    w.use_nodes = True
    w.node_tree.nodes['Background'].inputs['Color'].default_value = (0.35, 0.33, 0.34, 1)
    w.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.6
    sc.world = w
    return sc
