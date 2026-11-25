#!/usr/bin/env python3
"""Skleja zrodlo/ w jeden plik dist/WAROWNIA_POPIOLOW.html (działa offline, dwuklik).
Użycie: python3 narzedzia/zbuduj.py"""
import base64, json, re, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'zrodlo'
OUT = ROOT / 'dist' / 'WAROWNIA_POPIOLOW.html'

html = (SRC / 'index.html').read_text(encoding='utf-8')

# 1. Tailwind wszyty w plik
css = (SRC / 'tailwind.css').read_text(encoding='utf-8')
html = html.replace('<link rel="stylesheet" href="tailwind.css"> <!--BUILD:TAILWIND-->',
                    '<style>/* Tailwind (wbudowany) */\n' + css + '</style>')

# 2. Skrypty: kolejność z tagów <script src> w bloku BUILD, sklejone w jedną funkcję
m = re.search(r'<!--BUILD:SKRYPTY-->\n(.*?)<!--/BUILD:SKRYPTY-->\n', html, re.S)
pliki = re.findall(r'<script src="(js/[^"]+)"></script>', m.group(1))
kod = '\n'.join((SRC / p).read_text(encoding='utf-8') for p in pliki)

# 3. Sprite'y jako data URI
sprites = {}
for f in sorted((ROOT / 'zasoby' / 'sprite').glob('*.webp')):
    sprites[f.stem] = 'data:image/webp;base64,' + base64.b64encode(f.read_bytes()).decode()

blok = ('<script>window.__SPRITE_DATA__ = ' + json.dumps(sprites) + ';</script>\n'
        "<script>\n(() => {\n'use strict';\n" + kod + '\n})();\n</script>\n')
html = html[:m.start()] + blok + html[m.end():]

OUT.parent.mkdir(exist_ok=True)
OUT.write_text(html, encoding='utf-8')
print(f'OK: {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB, {len(pliki)} skryptów, {len(sprites)} sprite\'ów)')
