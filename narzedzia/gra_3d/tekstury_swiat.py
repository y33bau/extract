# Tekstury świata z paczki NightBrand (GRAFIKI_SWIAT/tekstury) -> PBR dla Godota.
# Dla każdej: albedo (JPEG), normal (z wysokości, wieloskalowo), mapa "rh" (R = szorstkość, G = wysokość).
# Użycie: python3 tekstury_swiat.py <katalog_paczki_tekstury> <godot/zasoby/3d/swiat>
# Paczka: folder autora Downloads\GRAFIKI_SWIAT\GRAFIKI_SWIAT\tekstury (nazwy plików = hash, jak w NightBrand).
import sys, os, numpy as np
from PIL import Image, ImageFilter

# nazwa -> (rozmiar, siła normalnej); plik źródłowy z paczki: tekstury_swiat.json
WYBOR = {
    # Zrujnowane Katakumby: chłodny, wilgotny kamień, mech w szczelinach
    "kat_plyty":   (2048, 5.0),   # nr 39: ciemne, wielkie płyty
    "kat_kostka":  (1024, 5.0),   # nr 17: szara kostka
    "kat_mech":    (2048, 5.0),   # nr 80: mszysty ciemny kamień
    "kat_mur":     (1024, 6.0),   # nr 129: mokry mur z mchem
    # Kamienne Podgrodzie: bruk dziedzińca, błoto, trawa w spoinach
    "pod_bruk":    (2048, 6.0),
    "pod_ziemia":  (2048, 3.0),
    "pod_trawa":   (2048, 3.5),
    "pod_mur":     (2048, 5.0),
    # Krypta Popielnego Króla: popiół z żarem, zwęglona skała
    "kry_plyty":   (1024, 5.0),
    "kry_popiol":  (2048, 4.0),
    "kry_lawa":    (1024, 4.0),
    "kry_mur":     (2048, 7.0),   # nr 130: ciemna, spękana skała
    # wspólne
    "drewno":      (1024, 4.0),
}


def bezszwowa(a, pas=48):
    """Łagodzi szew przy zawinięciu: brzegi przenikają się z przeciwną stroną."""
    a = a.astype(np.float32)
    h, w, _ = a.shape
    for i in range(pas):
        t = 0.5 * (1.0 - i / pas)
        l, r = a[:, i].copy(), a[:, w - 1 - i].copy()
        a[:, i] = l * (1 - t) + r * t
        a[:, w - 1 - i] = r * (1 - t) + l * t
        g, d = a[i].copy(), a[h - 1 - i].copy()
        a[i] = g * (1 - t) + d * t
        a[h - 1 - i] = d * (1 - t) + g * t
    return a


def zrob(src, nazwa, wyj, rozm, sila):
    im = Image.open(src).convert('RGB').resize((rozm, rozm), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    sx = np.abs(a[:, 0] - a[:, -1]).mean(); sy = np.abs(a[0] - a[-1]).mean()
    typ = np.abs(a[:, 1:] - a[:, :-1]).mean()
    if max(sx, sy) > typ * 1.25:
        a = bezszwowa(a, max(24, rozm // 40))
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    im.save(f'{wyj}/{nazwa}_albedo.jpg', quality=92)
    # wysokość: jasność + szersze kształty (kamienie wypukłe, spoiny wklęsłe)
    L = np.asarray(im.convert('L')).astype(np.float32) / 255.0
    def blur(x, r):
        return np.asarray(Image.fromarray((x * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))).astype(np.float32) / 255.0
    s = rozm / 1024.0
    hgt = 0.5 * blur(L, 1.0 * s) + 0.35 * blur(L, 4.0 * s) + 0.15 * blur(L, 12.0 * s)
    hgt = (hgt - hgt.min()) / max(1e-4, hgt.max() - hgt.min())
    gx = (np.roll(hgt, -1, 1) - np.roll(hgt, 1, 1)) * sila * s
    gy = (np.roll(hgt, -1, 0) - np.roll(hgt, 1, 0)) * sila * s
    n = np.dstack([-gx, gy, np.ones_like(hgt)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    # mapy normalnych i szorstkości max 1024 px (detal niesie albedo; mniejsza paczka gry)
    def zapisz(arr, plik):
        im2 = Image.fromarray(arr)
        if rozm > 1024:
            im2 = im2.resize((1024, 1024), Image.LANCZOS)
        im2.save(plik)
    zapisz(((n * 0.5 + 0.5) * 255).astype(np.uint8), f'{wyj}/{nazwa}_normal.png')
    rough = np.clip(0.97 - (hgt - 0.5) * 0.35 - (L - L.mean()) * 0.3, 0.6, 1.0)
    rh = np.dstack([rough, hgt, np.zeros_like(hgt)])
    zapisz((rh * 255).astype(np.uint8), f'{wyj}/{nazwa}_rh.png')
    print('TEKSTURA', nazwa, rozm, 'szew %.1f/%.1f typ %.1f' % (sx, sy, typ))


if __name__ == '__main__':
    import json
    src, wyj = sys.argv[1], sys.argv[2]
    mapa = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tekstury_swiat.json')))
    os.makedirs(wyj, exist_ok=True)
    for nazwa, (rozm, sila) in WYBOR.items():
        if nazwa in mapa:
            zrob(os.path.join(src, mapa[nazwa]), nazwa, wyj, rozm, sila)
