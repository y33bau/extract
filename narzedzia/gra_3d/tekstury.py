# Albedo -> albedo + normal + roughness (PBR) dla Godota.
import sys, numpy as np
from PIL import Image, ImageFilter
def zrob(zrodlo, nazwa, wyj, sila=4.0, rozm=1024):
    im = Image.open(zrodlo).convert('RGB').resize((rozm, rozm), Image.LANCZOS)
    im.save(f'{wyj}/{nazwa}_albedo.jpg', quality=93)
    l = np.asarray(im.convert('L').filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255.0
    gx = (np.roll(l, -1, 1) - np.roll(l, 1, 1)) * sila   # zawija się: tekstura bezszwowa
    gy = (np.roll(l, -1, 0) - np.roll(l, 1, 0)) * sila
    n = np.dstack([-gx, gy, np.ones_like(l)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save(f'{wyj}/{nazwa}_normal.png')
    r = np.clip(0.95 - (l - l.mean()) * 0.8, 0.55, 1.0)  # jasne wypukłości gładsze, szczeliny matowe
    Image.fromarray((r * 255).astype(np.uint8)).save(f'{wyj}/{nazwa}_rough.png')
    print('TEKSTURA', nazwa)
D = '/mnt/user-data/uploads/Downloads/'
W = sys.argv[1]
zrob(D + 'Bezszwowa ściana z osmalonego kamienia.png', 'kamien', W, 5.0)
zrob(D + 'Spalone deski z popiołem i żarem.png', 'deski', W, 3.0)
zrob(D + 'Zwęglone poziome bale z żarem.png', 'bale', W, 4.0)
