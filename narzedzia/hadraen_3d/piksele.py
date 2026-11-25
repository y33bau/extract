# Surowe rendery (x2) -> arkusze pixel-art: wiersze = 8 kierunków, kolumny = klatki.
import sys, os, glob, json
import numpy as np
from PIL import Image, ImageEnhance

SUROWE, WYJ = sys.argv[1], sys.argv[2]
KOM = 224
KOLORY = int(os.environ.get('KOLORY', 48))
KONTUR = (16, 11, 12, 255)
# dopasowanie do sprite'ów wrogów (średnia jasność ~62, nasycenie ~30), bo światło 2D mocno rozjaśnia
KOLOR = float(os.environ.get('KOLOR', 2.6))
KONTRAST = float(os.environ.get('KONTRAST', 1.3))
JASNOSC = float(os.environ.get('JASNOSC', 0.72))
os.makedirs(WYJ, exist_ok=True)


def zmniejsz(im):
    a = np.asarray(im).astype(np.float32) / 255.0
    rgb, al = a[..., :3] * a[..., 3:4], a[..., 3:4]
    pre = np.concatenate([rgb, al], -1)
    h, w = pre.shape[:2]
    pre = pre.reshape(h // 2, 2, w // 2, 2, 4).mean((1, 3))
    al = pre[..., 3:4]
    rgb = np.where(al > 1e-4, pre[..., :3] / np.maximum(al, 1e-4), 0)
    out = np.concatenate([rgb, (al > 0.42).astype(np.float32)], -1)
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), 'RGBA')


def kontur(im):
    a = np.asarray(im).copy()
    op = a[..., 3] > 0
    sas = np.zeros_like(op)
    sas[1:] |= op[:-1]; sas[:-1] |= op[1:]; sas[:, 1:] |= op[:, :-1]; sas[:, :-1] |= op[:, 1:]
    brzeg = sas & ~op
    a[brzeg] = KONTUR
    return Image.fromarray(a, 'RGBA')


manifest = {}
for zestaw in sorted(os.listdir(SUROWE)):
    animy = sorted(os.listdir(f'{SUROWE}/{zestaw}'))
    klatki_zestawu = {}
    for an in animy:
        pliki = sorted(glob.glob(f'{SUROWE}/{zestaw}/{an}/d*_*.png'))
        if not pliki:
            continue
        n = 1 + max(int(os.path.basename(p)[3:5]) for p in pliki)
        kl = {}
        for p in pliki:
            b = os.path.basename(p)
            d, i = int(b[1]), int(b[3:5])
            im = zmniejsz(Image.open(p).convert('RGBA'))
            rgb = ImageEnhance.Color(im.convert('RGB')).enhance(KOLOR)
            rgb = ImageEnhance.Contrast(rgb).enhance(KONTRAST)
            rgb = ImageEnhance.Brightness(rgb).enhance(JASNOSC)
            im = Image.merge('RGBA', (*rgb.split(), im.split()[3]))
            kl[(d, i)] = im
        klatki_zestawu[an] = (n, kl)
    # wspólna paleta zestawu
    probka = Image.new('RGB', (KOM * 8, KOM * 2))
    xs = 0
    wszystkie = [im for n, kl in klatki_zestawu.values() for im in kl.values()]
    krok = max(1, len(wszystkie) // 16)
    for j, im in enumerate(wszystkie[::krok][:16]):
        probka.paste(im.convert('RGB'), ((j % 8) * KOM, (j // 8) * KOM), im.split()[3])
    pal = probka.quantize(KOLORY, method=Image.Quantize.MEDIANCUT)
    for an, (n, kl) in klatki_zestawu.items():
        ark = Image.new('RGBA', (KOM * n, KOM * 8), (0, 0, 0, 0))
        for (d, i), im in kl.items():
            q = im.convert('RGB').quantize(palette=pal, dither=Image.Dither.NONE).convert('RGB')
            q = Image.merge('RGBA', (*q.split(), im.split()[3]))
            ark.alpha_composite(kontur(q), (i * KOM, d * KOM))
        ark.save(f'{WYJ}/{zestaw}_{an}.png', optimize=True)
        dl = f'{SUROWE}/{zestaw}/{an}/dlon.json'
        if os.path.exists(dl):
            manifest.setdefault('_dlon', {}).setdefault(zestaw, {})[an] = json.load(open(dl))
        manifest.setdefault(zestaw, {})[an] = n
    print('ZESTAW', zestaw, {a: v[0] for a, v in klatki_zestawu.items()})
json.dump(manifest, open(f'{WYJ}/_manifest.json', 'w'), indent=1)
