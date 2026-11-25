#!/usr/bin/env python3
"""Jednorazowy eksport z prototypu JS do projektu Godot:
dane (przedmioty, krainy, Warownia, umiejętności) jako JSON oraz ikony przedmiotów i kafle krain jako PNG.
Użycie: python3 narzedzia/eksport_z_js.py"""
import asyncio, base64, json, pathlib, subprocess, sys, tempfile
ROOT = pathlib.Path(__file__).resolve().parent.parent
G = ROOT / 'godot'

async def main():
    from playwright.async_api import async_playwright
    subprocess.run([sys.executable, str(ROOT / 'narzedzia' / 'zbuduj.py')], check=True)
    html = (ROOT / 'dist' / 'WAROWNIA_POPIOLOW.html').read_text(encoding='utf-8')
    html = html.replace('function raidLoop(now) {', 'window.__X = {ITEMS_DB, ZONES, STRONGHOLD_UPGRADES, SKILLS_DEF, ITEM_ICONS, ATLAS};\nfunction raidLoop(now) {', 1)
    tmp = pathlib.Path(tempfile.mkdtemp()) / 't.html'; tmp.write_text(html, encoding='utf-8')
    async with async_playwright() as pw:
        b = await pw.chromium.launch(); pg = await b.new_page()
        await pg.route('**/*', lambda r: r.abort() if not r.request.url.startswith(('file:', 'data:')) else r.continue_())
        await pg.goto(tmp.as_uri()); await pg.wait_for_timeout(300)
        dane = await pg.evaluate('() => ({przedmioty: __X.ITEMS_DB, krainy: __X.ZONES, warownia: __X.STRONGHOLD_UPGRADES, umiejetnosci: __X.SKILLS_DEF})')
        (G / 'dane').mkdir(exist_ok=True)
        for k, v in dane.items():
            (G / 'dane' / f'{k}.json').write_text(json.dumps(v, ensure_ascii=False, indent=1), encoding='utf-8')
        ikony = await pg.evaluate('() => __X.ITEM_ICONS')
        (G / 'zasoby' / 'ikony').mkdir(parents=True, exist_ok=True)
        for k, url in ikony.items():
            (G / 'zasoby' / 'ikony' / f'{k}.png').write_bytes(base64.b64decode(url.split(',', 1)[1]))
        for z in dane['krainy']:
            kafle = await pg.evaluate("""(id) => { const z = __X.ZONES.find(q => q.id === id); __X.ATLAS.buildForZone(z);
                const o = {}; for (const [k, c] of Object.entries(__X.ATLAS.sprites)) o[k] = c.toDataURL(); return o; }""", z['id'])
            d = G / 'zasoby' / 'kafle' / z['id']; d.mkdir(parents=True, exist_ok=True)
            for k, url in kafle.items():
                (d / f'{k}.png').write_bytes(base64.b64decode(url.split(',', 1)[1]))
        await b.close()
    print('OK: dane, ikony i kafle wyeksportowane do godot/')

asyncio.run(main())
