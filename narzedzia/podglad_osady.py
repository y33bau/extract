#!/usr/bin/env python3
"""Warownia: obraz Spalonej Osady z góry (pilot). Stan na 2026-11-26, rola gamedev.
Użycie: python3 podglad_osady.py osada_ZIARNO.json [wyjscie.png]
Dane z gry: godot --path godot -- --podglad-osady=/tmp/osada[,ziarno;ziarno]"""
import sys, json, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PX = 7  # pikseli na metr
PLAC, ULICA, ZABUDOWA, ZGLISZCZA, CHATA, PLOT, DRZEWO, WOZ, STUDNIA, GROB, EKSTRAKCJA = range(11)
KOL = {
    PLAC: (86, 74, 60), ULICA: (116, 96, 72), ZABUDOWA: (24, 20, 19), ZGLISZCZA: (24, 20, 19), CHATA: (70, 52, 40),
    PLOT: (86, 74, 60), DRZEWO: (86, 74, 60), WOZ: (86, 74, 60), STUDNIA: (86, 74, 60), GROB: (86, 74, 60),
    EKSTRAKCJA: (86, 74, 60),
}
TYPY = {"start": "START", "ekstrakcja": "WYJŚCIE", "plac": "plac ze studnią", "zagroda": "zagroda",
        "kuznia": "kuźnia", "stodola": "stodoła", "sad": "spalony sad", "cmentarz": "cmentarz (odnoga)",
        "piwnica": "piwnica (odnoga)", "kosciol": "SPALONY KOŚCIÓŁ"}


def czcionka(r):
    for p in ["/home/claude/extract/godot/zasoby/czcionki/cinzel.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, r)
        except Exception:
            pass
    return ImageFont.load_default()


def rysuj(d, wyj, tytul=""):
    N = d["rozmiar"]
    S = [[int(c, 16) for c in w] for w in d["teren"]]
    rnd = random.Random(1)
    W = N * PX
    img = Image.new("RGB", (W, W), (0, 0, 0))
    px = img.load()
    for y in range(W):
        for x in range(W):
            c = KOL[S[y // PX][x // PX]]
            j = rnd.randint(-6, 6)
            px[x, y] = (c[0] + j, c[1] + j, c[2] + j)
    img = img.filter(ImageFilter.GaussianBlur(1.0))
    dr = ImageDraw.Draw(img, "RGBA")
    for s in d["ulice"]:
        pts = [(p[0] * PX, p[1] * PX) for p in s["punkty"]]
        dr.line(pts, fill=(150, 124, 88, 110), width=int(PX * (2.2 if s["glowna"] else 1.5)), joint="curve")
    # zabudowa: gruz i zwęglone zarośla (faktura), chaty: mury zgliszcz z żarem
    for y in range(N):
        for x in range(N):
            t = S[y][x]
            cx, cy = (x + 0.5) * PX, (y + 0.5) * PX
            if t == ZABUDOWA and rnd.random() < 0.4:
                r = rnd.uniform(0.5, 1.1) * PX
                g = rnd.randint(30, 46)
                dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(g, g - 6, g - 8, 200))
            elif t == ZGLISZCZA:
                dr.rectangle([x * PX, y * PX, (x + 1) * PX - 1, (y + 1) * PX - 1], fill=(52, 40, 34, 255))
                if rnd.random() < 0.18:
                    dr.rectangle([x * PX + 2, y * PX + 2, x * PX + 4, y * PX + 4], fill=(230, 110, 40, 200))
            elif t == PLOT:
                dr.rectangle([cx - PX * 0.45, cy - PX * 0.15, cx + PX * 0.45, cy + PX * 0.15], fill=(120, 88, 56, 255))
                dr.rectangle([cx - PX * 0.15, cy - PX * 0.45, cx + PX * 0.15, cy + PX * 0.45], fill=(100, 72, 46, 255))
            elif t == DRZEWO:
                r = 1.1 * PX
                dr.ellipse([cx - r + 3, cy - r + 4, cx + r + 3, cy + r + 4], fill=(0, 0, 0, 90))
                dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(30, 24, 20, 255))
                dr.line([cx - r, cy, cx + r * 0.6, cy - r * 0.4], fill=(70, 56, 44, 255), width=2)
            elif t == WOZ:
                dr.rectangle([cx - PX * 0.5 + 2, cy - PX * 0.4 + 3, cx + PX * 0.5 + 2, cy + PX * 0.4 + 3], fill=(0, 0, 0, 90))
                dr.rectangle([cx - PX * 0.5, cy - PX * 0.4, cx + PX * 0.5, cy + PX * 0.4], fill=(96, 68, 44, 255))
            elif t == STUDNIA:
                dr.ellipse([x * PX - 1, y * PX - 1, (x + 1) * PX + 1, (y + 1) * PX + 1], fill=(120, 116, 108, 255))
            elif t == GROB:
                dr.rectangle([cx - PX * 0.3, cy - PX * 0.45, cx + PX * 0.3, cy + PX * 0.45], fill=(140, 136, 128, 255))
    # znaczniki
    f_m = czcionka(13)
    f_d = czcionka(18)
    for o in d["ogniska"]:
        x, y = o[0] * PX, o[1] * PX
        dr.ellipse([x - 20, y - 20, x + 20, y + 20], fill=(255, 120, 30, 40))
        dr.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(255, 150, 50, 255))
    for s in d["skrzynie"]:
        x, y = s["x"] * PX, s["y"] * PX
        dr.rectangle([x - 4, y - 3, x + 4, y + 3], fill=(232, 196, 80, 255), outline=(60, 40, 10, 255))
    for w in d["wrogowie"]:
        x, y = w["x"] * PX, w["y"] * PX
        dr.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(200, 40, 34, 255), outline=(40, 0, 0, 255))
    for e in d["ekstrakcje"]:
        x, y = e["x"] * PX, e["y"] * PX
        for rr, a in [(26, 50), (16, 255)]:
            dr.ellipse([x - rr, y - rr, x + rr, y + rr], outline=(120, 220, 240, a), width=3)
    sx, sy = d["start"][0] * PX, d["start"][1] * PX
    dr.regular_polygon((sx, sy, 15), 5, rotation=0, fill=(240, 200, 90, 255), outline=(60, 40, 10, 255))
    for p in d["miejsca"]:
        x, y = p["x"] * PX, (p["y"] - p["r"] * 0.6) * PX
        t = TYPY.get(p["typ"], p["typ"])
        f = f_d if p["typ"] in ("start", "ekstrakcja", "kosciol") else f_m
        b = dr.textbbox((0, 0), t, font=f)
        dr.text((x - (b[2] - b[0]) / 2 + 1, y + 1), t, font=f, fill=(0, 0, 0, 230))
        dr.text((x - (b[2] - b[0]) / 2, y), t, font=f, fill=(245, 230, 190, 255))
    dr.rectangle([16, W - 24, 16 + 10 * PX, W - 18], fill=(240, 230, 200, 230))
    dr.text((16, W - 44), "10 m", font=f_m, fill=(240, 230, 200, 255))
    L = 300
    out = Image.new("RGB", (W + L, W), (16, 14, 12))
    out.paste(img, (0, 0))
    od = ImageDraw.Draw(out, "RGBA")
    od.text((W + 18, 18), tytul, font=czcionka(22), fill=(240, 214, 150))
    rzedy = [
        ("pas", (150, 124, 88), "ulica główna 6–7,5 m"), ("pas", (116, 96, 72), "ulica 5–6,5 m"),
        ("pas", KOL[PLAC], "plac, podwórze (walka, łup)"), ("pas", (34, 28, 26), "zabudowa: gruz, zarośla (ściana)"),
        ("pas", (52, 40, 34), "mury spalonej chaty"), ("pas", KOL[CHATA], "wnętrze chaty (wejście 3 m)"),
        ("pas", (120, 88, 56), "płot (widać przez niego)"), ("kolo", (30, 24, 20), "spalone drzewo (osłona)"),
        ("pas", (96, 68, 44), "wóz, beczki, belka (osłona)"), ("pas", (140, 136, 128), "grób"),
        ("kolo", (120, 116, 108), "studnia"),
        ("gw", (240, 200, 90), "start"), ("ring", (120, 220, 240), "wyjście (ekstrakcja)"),
        ("kw", (232, 196, 80), "łup"), ("kolo", (200, 40, 34), "wróg (miejsce)"), ("kolo", (255, 150, 50), "żar (światło)"),
    ]
    y = 70
    fl = czcionka(15)
    for kind, c, opis in rzedy:
        x = W + 22
        if kind == "pas":
            od.rectangle([x, y, x + 26, y + 16], fill=c)
        elif kind == "kolo":
            od.ellipse([x + 6, y, x + 22, y + 16], fill=c)
        elif kind == "kw":
            od.rectangle([x + 8, y + 3, x + 20, y + 13], fill=c)
        elif kind == "ring":
            od.ellipse([x + 5, y - 1, x + 23, y + 17], outline=c, width=3)
        elif kind == "gw":
            od.regular_polygon((x + 13, y + 8, 10), 5, fill=c)
        od.text((x + 36, y), opis, font=fl, fill=(225, 215, 190))
        y += 28
    y += 14
    staty = [f"mapa {N}×{N} m", f"miejsc: {len(d['miejsca'])}", f"ulic: {len(d['ulice'])}",
             f"spalonych chat: {len(d['domy'])}", f"łupów: {len(d['skrzynie'])}",
             f"wrogów: {len(d['wrogowie'])}", "głębiej = więcej wrogów", "i lepszy łup"]
    for s in staty:
        od.text((W + 22, y), s, font=fl, fill=(170, 160, 140))
        y += 24
    out.save(wyj)


if __name__ == "__main__":
    src = sys.argv[1]
    d = json.load(open(src, encoding="utf8"))
    wyj = sys.argv[2] if len(sys.argv) > 2 else src.rsplit(".", 1)[0] + ".png"
    z = src.rsplit("osada_", 1)[-1].rsplit(".", 1)[0]
    rysuj(d, wyj, "Spalona Osada · ziarno " + z.replace("OSADA", ""))
    print(wyj)
