#!/usr/bin/env python3
"""Warownia: obraz mapy lasu z góry (pilot Czarnoboru). Stan na 2026-11-26, rola gamedev.
Użycie: python3 podglad_lasu.py las_ZIARNO.json [wyjscie.png]
Dane z gry: godot --path godot -- --podglad-lasu=/tmp/las[,ziarno;ziarno]"""
import sys, json, random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PX = 7  # pikseli na metr
POLANA, SCIEZKA, LAS, SKALA, WODA, BROD, DRZEWO, GLAZ, EKSTRAKCJA = range(9)
KOL = {
    POLANA: (74, 92, 46), SCIEZKA: (112, 92, 64), LAS: (20, 34, 22), SKALA: (78, 76, 72),
    WODA: (26, 52, 70), BROD: (70, 108, 112), DRZEWO: (74, 92, 46), GLAZ: (74, 92, 46), EKSTRAKCJA: (74, 92, 46),
}
TYPY = {"start": "START", "ekstrakcja": "WYJŚCIE", "polana": "polana", "laka": "łąka", "oboz": "obóz kłusowników",
        "kapliczka": "kapliczka", "kurhan": "kurhan (odnoga)", "legowisko": "legowisko (odnoga)"}


def czcionka(r):
    for p in ["/home/claude/extract/godot/zasoby/czcionki/cinzel.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, r)
        except Exception:
            pass
    return ImageFont.load_default()


def rysuj(d, wyj, tytul=""):
    N = d["rozmiar"]
    S = [[int(c) for c in w] for w in d["siatka"]]
    rnd = random.Random(1)
    W = N * PX
    img = Image.new("RGB", (W, W), (0, 0, 0))
    px = img.load()
    for y in range(W):
        for x in range(W):
            t = S[y // PX][x // PX]
            c = KOL[t]
            j = rnd.randint(-6, 6)
            px[x, y] = (c[0] + j, c[1] + j, c[2] + j)
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    dr = ImageDraw.Draw(img, "RGBA")
    # ścieżki: jaśniejszy ubity środek
    for s in d["sciezki"]:
        pts = [(p[0] * PX, p[1] * PX) for p in s["punkty"]]
        dr.line(pts, fill=(140, 116, 80, 120), width=int(PX * 1.6), joint="curve")
    # korony drzew w gąszczu (tylko przy krawędzi, żeby las miał fakturę), skały z cieniem
    for y in range(N):
        for x in range(N):
            t = S[y][x]
            cx, cy = (x + 0.5) * PX, (y + 0.5) * PX
            if t == LAS and rnd.random() < 0.55:
                r = rnd.uniform(0.7, 1.25) * PX
                g = rnd.randint(28, 52)
                dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(14, g, 20, 210))
                dr.ellipse([cx - r * 0.5, cy - r * 0.6, cx + r * 0.2, cy], fill=(40, g + 22, 34, 120))
            elif t == SKALA and rnd.random() < 0.35:
                r = rnd.uniform(0.6, 1.1) * PX
                dr.polygon([(cx - r, cy + r * 0.4), (cx - r * 0.3, cy - r), (cx + r, cy - r * 0.2), (cx + r * 0.6, cy + r)], fill=(104, 100, 94, 200))
            elif t == DRZEWO:
                r = 1.25 * PX
                dr.ellipse([cx - r + 3, cy - r + 4, cx + r + 3, cy + r + 4], fill=(0, 0, 0, 90))
                dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(24, 60, 28, 255))
                dr.ellipse([cx - r * 0.6, cy - r * 0.7, cx + r * 0.1, cy], fill=(60, 96, 50, 160))
            elif t == GLAZ:
                r = 0.75 * PX
                dr.ellipse([cx - r + 2, cy - r + 3, cx + r + 2, cy + r + 3], fill=(0, 0, 0, 90))
                dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(130, 126, 118, 255))
    # znaczniki
    f_m = czcionka(13)
    f_d = czcionka(18)
    for o in d["ogniska"]:
        x, y = o[0] * PX, o[1] * PX
        dr.ellipse([x - 22, y - 22, x + 22, y + 22], fill=(255, 150, 40, 40))
        dr.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(255, 170, 60, 255))
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
    for p in d["polany"]:
        x, y = p["x"] * PX, (p["y"] - p["r"] * 0.55) * PX
        t = TYPY.get(p["typ"], p["typ"])
        f = f_d if p["typ"] in ("start", "ekstrakcja") else f_m
        b = dr.textbbox((0, 0), t, font=f)
        dr.text((x - (b[2] - b[0]) / 2 + 1, y + 1), t, font=f, fill=(0, 0, 0, 230))
        dr.text((x - (b[2] - b[0]) / 2, y), t, font=f, fill=(245, 230, 190, 255))
    # skala 10 m
    dr.rectangle([16, W - 24, 16 + 10 * PX, W - 18], fill=(240, 230, 200, 230))
    dr.text((16, W - 44), "10 m", font=f_m, fill=(240, 230, 200, 255))
    # legenda z boku
    L = 290
    out = Image.new("RGB", (W + L, W), (16, 14, 12))
    out.paste(img, (0, 0))
    od = ImageDraw.Draw(out, "RGBA")
    od.text((W + 18, 18), tytul, font=czcionka(22), fill=(240, 214, 150))
    rzedy = [
        ("pas", (140, 116, 80), "ścieżka 4,5–6 m"), ("pas", KOL[POLANA], "polana (walka, łup)"),
        ("pas", (20, 40, 22), "gęsty las (ściana)"), ("pas", (104, 100, 94), "skały, wąwozy"),
        ("pas", KOL[WODA], "głęboka woda"), ("pas", KOL[BROD], "bród, płytka woda"),
        ("kolo", (24, 60, 28), "pojedyncze drzewo (osłona)"), ("kolo", (130, 126, 118), "głaz (osłona)"),
        ("gw", (240, 200, 90), "start"), ("ring", (120, 220, 240), "wyjście (ekstrakcja)"),
        ("kw", (232, 196, 80), "łup"), ("kolo", (200, 40, 34), "wróg (miejsce)"), ("kolo", (255, 170, 60), "ognisko"),
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
        y += 30
    y += 14
    staty = [f"mapa {N}×{N} m", f"polan: {len(d['polany'])}", f"ścieżek: {len(d['sciezki'])}",
             f"wąwozów: {sum(1 for s in d['sciezki'] if s['wawoz'])}", f"łupów: {len(d['skrzynie'])}",
             f"wrogów: {len(d['wrogowie'])}", "głębiej = więcej wrogów", "i lepszy łup"]
    for s in staty:
        od.text((W + 22, y), s, font=fl, fill=(170, 160, 140))
        y += 24
    out.save(wyj)


if __name__ == "__main__":
    src = sys.argv[1]
    d = json.load(open(src, encoding="utf8"))
    wyj = sys.argv[2] if len(sys.argv) > 2 else src.rsplit(".", 1)[0] + ".png"
    z = src.rsplit("las_", 1)[-1].rsplit(".", 1)[0]
    rysuj(d, wyj, "Czarnobór · ziarno " + z.replace("CZARNOBOR", ""))
    print(wyj)
