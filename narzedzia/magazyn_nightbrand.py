#!/usr/bin/env python3
"""Warownia: pełna biblioteka grafik NightBrand pod czytelnymi nazwami. Stan na 2026-11-26, rola grafik.
Użycie: python3 magazyn_nightbrand.py ŚCIEŻKA_NightBrand-PC KATALOG_WYJŚCIOWY [--miniatury KATALOG_PNG]
Czyta: gra/assets/* (pliki o nazwach SHA-256), docs/INDEKS_ASSETOW.json (nazwy tekstur, rekwizytów 2D, teł)
i zrodlo/main/*.js (nazwy modeli 3D `nazwa:{g:'...glb',k:'...webp'}` — tekstura modelu leży w osobnym pliku).
NightBrand jest tylko źródłem: niczego tam nie zmienia."""
import sys, os, re, glob, json, shutil

nb, wyj = sys.argv[1].rstrip('/'), sys.argv[2].rstrip('/')
mini = sys.argv[sys.argv.index('--miniatury') + 1] if '--miniatury' in sys.argv else None
A = nb + '/gra/assets/'
src = ''.join(open(f, encoding='utf8').read() for f in sorted(glob.glob(nb + '/zrodlo/main/*.js')))
idx = json.load(open(nb + '/docs/INDEKS_ASSETOW.json', encoding='utf8'))['pliki']
spis = {'modele_3d': [], 'tekstury': [], 'rekwizyty_2d': [], 'tla': []}

# modele 3D: nazwa -> (glb, tekstura)
nazwy, tekst = {}, {}
for m in re.finditer(r"([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\{\s*g\s*:\s*'assets/rekwizyty/([0-9a-f]{64})\.glb'(?:\s*,\s*k\s*:\s*'assets/rekwizyty/([0-9a-f]{64})\.webp')?", src):
    nazwy.setdefault(m.group(2), m.group(1))
    if m.group(3):
        tekst[m.group(2)] = m.group(3)
for m in re.finditer(r"([A-Za-z_][A-Za-z0-9_]*)\s*:\s*'assets/rekwizyty/([0-9a-f]{64})\.glb'", src):
    nazwy.setdefault(m.group(2), m.group(1))


def grupa(n):
    if n.startswith('p8_'): return 'partia8_malowane'
    for p, g in [('p1_', 'r1_spalona_osada'), ('p2_', 'r2_dolne_miasto'), ('p3_', 'r3_zlotogrod'), ('p4_', 'r4_czarnobor'), ('p5_', 'r5_cytadela')]:
        if n.startswith(p): return g
    if re.match(r'r[789]_', n): return 'odrzucone_bryly_blendera'
    return 'inne_stare'


for p in sorted(glob.glob(A + 'rekwizyty/*.glb')):
    h = os.path.basename(p)[:-4]
    n = nazwy.get(h, 'bez_nazwy_' + h[:8])
    g = grupa(n)
    os.makedirs(f'{wyj}/modele_3d/{g}', exist_ok=True)
    shutil.copy(p, f'{wyj}/modele_3d/{g}/{n}.glb')
    t = tekst.get(h)
    if t and os.path.exists(A + f'rekwizyty/{t}.webp'):
        shutil.copy(A + f'rekwizyty/{t}.webp', f'{wyj}/modele_3d/{g}/{n}.webp')
    if mini and os.path.exists(f'{mini}/{n}.png'):
        os.makedirs(f'{wyj}/modele_3d/_miniatury', exist_ok=True)
        shutil.copy(f'{mini}/{n}.png', f'{wyj}/modele_3d/_miniatury/{n}.png')
    spis['modele_3d'].append({'nazwa': n, 'grupa': g, 'glb': h, 'tekstura': t})

# tekstury, rekwizyty 2D, tła (z indeksu NightBrand; ten sam klucz w kilku rozmiarach -> sufiks _px)
for kat, folder in [('tekstury', 'tekstury'), ('rekwizyty', 'rekwizyty_2d'), ('tla', 'tla')]:
    for w in idx:
        if w['kategoria'] != kat or w['typ'] == 'glb' or not os.path.exists(nb + '/gra/' + w['plik']):
            continue
        k = (w.get('klucze') or ['bez_nazwy_' + w['hash'][:8]])[0]
        roz = w.get('wymiary')
        nazwa = f"{k}_{roz[0]}" if (kat == 'tekstury' and roz) else k
        os.makedirs(f'{wyj}/{folder}', exist_ok=True)
        shutil.copy(nb + '/gra/' + w['plik'], f"{wyj}/{folder}/{nazwa}.{w['typ']}")
        spis['rekwizyty_2d' if kat == 'rekwizyty' else kat].append({'nazwa': nazwa, 'plik': os.path.basename(w['plik']), 'px': roz})

json.dump(spis, open(f'{wyj}/spis.json', 'w', encoding='utf8'), ensure_ascii=False, indent=1)
print({k: len(v) for k, v in spis.items()})
