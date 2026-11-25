# Bronie i rekwizyty (Blender). Układ: rękojeść w (0,0,0), broń wzdłuż +Z, płaszczyzna ostrza XZ.
import bpy, math
from mathutils import Vector


def mat(nazwa, kolor, metal, szorstk, emisja=None, sila=0.0):
    m = bpy.data.materials.get(nazwa)
    if m:
        return m
    m = bpy.data.materials.new(nazwa)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*kolor, 1)
    bs.inputs['Metallic'].default_value = metal
    bs.inputs['Roughness'].default_value = szorstk
    if emisja:
        bs.inputs['Emission Color'].default_value = (*emisja, 1)
        bs.inputs['Emission Strength'].default_value = sila
    return m


def M():
    return {
        'stal_ciemna': mat('stal_ciemna', (0.16, 0.16, 0.17), 1.0, 0.38),
        'stal': mat('stal', (0.55, 0.55, 0.57), 1.0, 0.28),
        'zelazo': mat('zelazo', (0.09, 0.085, 0.08), 0.9, 0.55),
        'skora': mat('skora', (0.12, 0.06, 0.035), 0.0, 0.7),
        'drewno': mat('drewno', (0.2, 0.11, 0.05), 0.0, 0.65),
        'drewno_ciemne': mat('drewno_ciemne', (0.09, 0.05, 0.025), 0.0, 0.7),
        'mosiadz': mat('mosiadz', (0.55, 0.38, 0.16), 1.0, 0.35),
        'szmata': mat('szmata', (0.08, 0.06, 0.04), 0.0, 0.9),
        'cieciwa': mat('cieciwa', (0.6, 0.55, 0.45), 0.0, 0.8),
    }


def obiekt(nazwa, verts, faces, material):
    me = bpy.data.meshes.new(nazwa)
    me.from_pydata([Vector(v) for v in verts], [], faces)
    me.update()
    o = bpy.data.objects.new(nazwa, me)
    bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(material)
    for p in o.data.polygons:
        p.use_smooth = False
    return o


def ostrze(nazwa, w, t, L, czub, material, z0=0.0, zbrocze=True):
    """Ostrze obosieczne: przekrój romb, zwęża się do czubka."""
    v = []
    for z, sz in [(z0, 1.0), (z0 + (L - czub), 0.92)]:
        v += [(-w / 2 * sz, 0, z), (0, -t / 2, z), (w / 2 * sz, 0, z), (0, t / 2, z)]
    v.append((0, 0, z0 + L))
    f = [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 8), (5, 6, 8), (6, 7, 8), (7, 4, 8), (3, 2, 1, 0)]
    return obiekt(nazwa, v, f, material)


def wyciagnij(nazwa, punkty, grubosc, material, faza=0.6):
    """Kontur 2D (x,z) wyciągnięty wzdłuż Y; krawędzie zwężone (faza) jak szlif ostrza."""
    n = len(punkty)
    v = []
    for y in (-grubosc / 2, grubosc / 2):
        v += [(x, y, z) for x, z in punkty]
    sr = Vector((sum(p[0] for p in punkty) / n, 0, sum(p[1] for p in punkty) / n))
    f = [tuple(range(n))[::-1], tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        f.append((i, j, n + j, n + i))
    return obiekt(nazwa, v, f, material)


def walec(nazwa, r, z0, z1, material, seg=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=r, depth=z1 - z0, location=(0, 0, (z0 + z1) / 2))
    o = bpy.context.active_object
    o.name = nazwa
    o.data.materials.append(material)
    return o


def kula(nazwa, r, z, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=r, location=(0, 0, z))
    o = bpy.context.active_object
    o.name = nazwa
    o.data.materials.append(material)
    return o


def skrzynka(nazwa, sx, sy, sz, srodek, material, faza=0.01):
    bpy.ops.mesh.primitive_cube_add(size=1, location=srodek)
    o = bpy.context.active_object
    o.name = nazwa
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    mod = o.modifiers.new('faza', 'BEVEL')
    mod.width = faza
    mod.segments = 2
    o.data.materials.append(material)
    return o


def rura(nazwa, punkty, r, material, seg=8):
    """Tuba wzdłuż łamanej (łuk, cięciwa)."""
    v, f = [], []
    for i, p in enumerate(punkty):
        p = Vector(p)
        a = Vector(punkty[min(i + 1, len(punkty) - 1)]) - Vector(punkty[max(i - 1, 0)])
        a.normalize()
        u = a.cross(Vector((0, 1, 0))).normalized()
        w = a.cross(u).normalized()
        for k in range(seg):
            t = k / seg * math.tau
            v.append(tuple(p + (u * math.cos(t) + w * math.sin(t)) * r))
    for i in range(len(punkty) - 1):
        for k in range(seg):
            a0, a1 = i * seg + k, i * seg + (k + 1) % seg
            f.append((a0, a1, a1 + seg, a0 + seg))
    return obiekt(nazwa, v, f, material)


def polacz(czesci, nazwa):
    for c in czesci:
        for mod in list(c.modifiers):
            bpy.context.view_layer.objects.active = c
            bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.select_all(action='DESELECT')
    for c in czesci:
        c.select_set(True)
    bpy.context.view_layer.objects.active = czesci[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = nazwa
    return o


def zbuduj(rodzaj):
    m = M()
    c = []
    if rodzaj == 'dwureczny':  # Czarny Miecz Popiołów: płyta żelaza
        c += [ostrze('o', 0.25, 0.05, 1.5, 0.16, m['zelazo'], z0=0.2),
              skrzynka('jelec', 0.38, 0.08, 0.07, (0, 0, 0.19), m['stal_ciemna']),
              walec('rek', 0.028, -0.24, 0.16, m['skora']),
              kula('glowica', 0.05, -0.27, m['stal_ciemna'])]
    elif rodzaj == 'miecz':
        c += [ostrze('o', 0.07, 0.018, 0.84, 0.14, m['stal'], z0=0.1),
              skrzynka('jelec', 0.22, 0.04, 0.035, (0, 0, 0.09), m['mosiadz']),
              walec('rek', 0.02, -0.1, 0.08, m['skora']),
              kula('glowica', 0.03, -0.12, m['mosiadz'])]
    elif rodzaj in ('topor', 'topor_wielki'):
        s = 1.45 if rodzaj == 'topor_wielki' else 1.0
        kontur = [(0.02, 0.6), (0.12, 0.52), (0.27, 0.46), (0.33, 0.62), (0.34, 0.8), (0.28, 0.95), (0.13, 0.88), (0.02, 0.8)]
        c += [walec('trzon', 0.024 * s, -0.28 * s, 0.98 * s, m['drewno_ciemne']),
              wyciagnij('ostrze', [(x * s, z * s) for x, z in kontur], 0.03 * s, m['zelazo']),
              skrzynka('obuch', 0.09 * s, 0.07 * s, 0.16 * s, (-0.04 * s, 0, 0.72 * s), m['stal_ciemna'])]
    elif rodzaj == 'glewia':
        kontur = [(-0.03, 1.32), (0.07, 1.36), (0.1, 1.6), (0.06, 1.88), (0.0, 1.98), (-0.02, 1.7)]
        c += [walec('drzewce', 0.02, -0.7, 1.36, m['drewno']),
              wyciagnij('grot', kontur, 0.022, m['stal']),
              skrzynka('tuleja', 0.06, 0.06, 0.1, (0, 0, 1.32), m['stal_ciemna'])]
    elif rodzaj == 'tarcza':  # tarcza herbowa
        kontur = [(-0.27, 0.32), (0.27, 0.32), (0.27, 0.0), (0.18, -0.24), (0.0, -0.38), (-0.18, -0.24), (-0.27, 0.0)]
        rama = [(x * 1.07, z * 1.07) for x, z in kontur]
        t1 = wyciagnij('deski', kontur, 0.04, m['drewno'])
        t2 = wyciagnij('okucie', rama, 0.03, m['zelazo'])
        t2.location.y = 0.012
        c += [t1, t2, kula('umbo', 0.07, 0.0, m['stal_ciemna'])]
        c[-1].location.y = -0.03
    elif rodzaj == 'luk':
        pkt = [(0.11 * math.sin(math.pi * i / 16) - 0.0, 0, -0.7 + 1.4 * i / 16) for i in range(17)]
        pkt = [(-0.12 * math.sin(math.pi * i / 16), 0, -0.7 + 1.4 * i / 16) for i in range(17)]
        c += [rura('lek', pkt, 0.016, m['drewno_ciemne']),
              rura('cieciwa', [(0.0, 0, -0.69), (0.0, 0, 0.69)], 0.004, m['cieciwa'], 4),
              walec('uchwyt', 0.024, -0.08, 0.08, m['skora'])]
        c[-1].location.x = -0.12
    elif rodzaj == 'pochodnia':
        c += [walec('drzewce', 0.022, -0.18, 0.32, m['drewno_ciemne']),
              walec('glowa', 0.038, 0.3, 0.42, m['szmata'])]
    else:
        return None
    o = polacz(c, 'bron_' + rodzaj)
    if rodzaj == 'pochodnia':
        e = bpy.data.objects.new('plomien_punkt', None)
        bpy.context.scene.collection.objects.link(e)
        e.parent = o
        e.location = (0, 0, 0.5)
    return o
