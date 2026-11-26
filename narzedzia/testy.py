#!/usr/bin/env python3
"""Wspólne testy automatyczne Warowni Popiołów (wersja JS).

Użycie:
  python3 narzedzia/testy.py szybki   # drobne zmiany: budowa, brak błędów, rajd startuje
  python3 narzedzia/testy.py pelny    # duże zmiany: + pełna pętla gry i testy mechanik
  python3 narzedzia/testy.py godot    # gra w Godocie (wymaga godot 4.7.x, xvfb-run, mesa)

Wymaga: pip install playwright && python -m playwright install chromium
Test buduje grę, robi kopię z haczykiem testowym (window.__R / __P) w katalogu tymczasowym
i gra nią w przeglądarce bez okna. Plik dist/ zostaje czysty.
"""
import asyncio, pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIST = ROOT / 'dist' / 'WAROWNIA_POPIOLOW.html'

wyniki = []


def ok(nazwa, warunek, szczegol=''):
    wyniki.append((nazwa, bool(warunek), szczegol))
    print(('  OK   ' if warunek else '  BŁĄD ') + nazwa + (f'  [{szczegol}]' if szczegol else ''))


def zbuduj_kopie_testowa():
    subprocess.run([sys.executable, str(ROOT / 'narzedzia' / 'zbuduj.py')], check=True)
    html = DIST.read_text(encoding='utf-8')
    hak = 'window.__R = () => raid;\nwindow.__P = () => profile;\nfunction raidLoop(now) {'
    if 'function raidLoop(now) {' not in html:
        raise SystemExit('Nie znaleziono raidLoop: zaktualizuj haczyk testowy w testy.py')
    html = html.replace('function raidLoop(now) {', hak, 1)
    tmp = pathlib.Path(tempfile.mkdtemp()) / 'test.html'
    tmp.write_text(html, encoding='utf-8')
    return tmp


async def nowa_strona(b, plik, bledy):
    ctx = await b.new_context(viewport={'width': 1366, 'height': 768})
    pg = await ctx.new_page()
    pg.on('pageerror', lambda e: bledy.append(str(e)))
    # Błędy ładowania zasobów liczymy po adresie (requestfailed). Czcionki Google są jedynym
    # dozwolonym zasobem z internetu: offline gra używa czcionek zastępczych.
    pg.on('console', lambda m: bledy.append('console: ' + m.text)
          if m.type == 'error' and not m.text.startswith('Failed to load resource') else None)
    pg.on('requestfailed', lambda r: None if ('fonts.googleapis.com' in r.url or 'fonts.gstatic.com' in r.url)
          else bledy.append('nie wczytano: ' + r.url[:80]))
    # tylko pliki lokalne: gra musi działać offline
    await pg.route('**/*', lambda r: r.abort() if not r.request.url.startswith(('file:', 'data:')) else r.continue_())
    await pg.goto(plik.as_uri())
    await pg.evaluate('localStorage.clear()')
    await pg.reload()
    await pg.wait_for_timeout(400)
    return pg


async def start_rajdu(pg):
    await pg.click('#btn-start-raid')
    await pg.wait_for_timeout(500)
    return await pg.evaluate('() => !!__R() && !document.getElementById("raid-screen").classList.contains("hidden")')


async def test_szybki(pg):
    print('-- szybki')
    ok('hub widoczny', await pg.is_visible('#hub-screen'))
    ok('rajd startuje', await start_rajdu(pg))
    await pg.mouse.move(800, 420)
    await pg.keyboard.down('KeyD'); await pg.wait_for_timeout(400); await pg.keyboard.up('KeyD')
    await pg.mouse.down(); await pg.wait_for_timeout(60); await pg.mouse.up()
    await pg.wait_for_timeout(300)
    ok('pętla gry działa (czas płynie)', await pg.evaluate('() => __R().elapsed > 0.5'))


async def ustaw_wroga_przed(pg, idx=0):
    await pg.evaluate(f"""() => {{ const r=__R(), p=r.player, e=r.enemies[{idx}];
        e.x=p.x+Math.cos(p.angle)*0.9; e.y=p.y+Math.sin(p.angle)*0.9; e.atkTimer=99; e.windupTimer=0; e.state='combat'; p.stamina=p.maxStamina; }}""")


async def test_mechaniki(pg):
    print('-- mechaniki (runda 1)')
    await pg.mouse.move(800, 420)
    # pochodnia w ręce blokuje parowanie
    await pg.mouse.down(button='right'); await pg.wait_for_timeout(60)
    r = await pg.evaluate('() => ({t: __R().player.torchInHand, pw: __R().player.parryWindow})')
    await pg.mouse.up(button='right')
    ok('pochodnia w ręce: brak parowania', r['t'] and r['pw'] == 0, str(r))
    await pg.keyboard.press('KeyF'); await pg.wait_for_timeout(100)
    await pg.mouse.down(button='right'); await pg.wait_for_timeout(60)
    r = await pg.evaluate('() => ({t: __R().player.torchInHand, pw: __R().player.parryWindow, g: !!__R().groundTorch})')
    await pg.mouse.up(button='right')
    ok('pochodnia rzucona: parowanie działa', (not r['t']) and r['pw'] > 0 and r['g'], str(r))
    # postura
    await pg.evaluate("() => { const e=__R().enemies[0]; e.hp=99999; e.maxHp=99999; }")
    pekla = False
    for _ in range(10):
        await ustaw_wroga_przed(pg)
        await pg.mouse.down(); await pg.wait_for_timeout(40); await pg.mouse.up(); await pg.wait_for_timeout(420)
        if await pg.evaluate('() => __R().enemies[0].staggerTimer > 0'):
            pekla = True; break
    ok('postura pęka od ciosów', pekla)
    # sakwa
    await pg.evaluate("() => { const l=__R().player.loadout; l.backpack.push({uid:'t1',id:'iron_ingot'}); l.backpack.push({uid:'t2',id:'silver_goblet'}); }")
    await pg.keyboard.press('KeyG'); await pg.wait_for_timeout(100)
    r = await pg.evaluate("() => ({bag: __R().corpses.filter(c=>c.isBag).map(c=>c.items.length), pas: __R().player.loadout.backpack.every(i=>['elixir','arrow'].includes(i.id==='iron_arrows'?'arrow':(i.id.includes('flask')||i.id.includes('tonic')||i.id.includes('salve')?'elixir':'x')))})")
    ok('zrzut sakwy (łup na ziemi, pas zostaje)', r['bag'] == [2] and r['pas'], str(r))


async def test_petla(pg):
    print('-- pełna pętla')
    # ekstrakcja z łupem
    await pg.evaluate("""() => { const r=__R(), p=r.player; p.loadout.backpack.push({uid:'lup1',id:'golden_idol'});
        r.enemies.forEach(e=>{e.x=2.5;e.y=2.5;e.state='patrol';});
        const ex=r.map.extracts[0]; p.x=ex.x; p.y=ex.y; p.hp=p.maxHp=9999; }""")
    await pg.wait_for_timeout(7000)
    tekst = await pg.inner_text('#res-badge') if await pg.is_visible('#result-modal') else ''
    ok('ekstrakcja kończy rajd', 'EKSTRAKCJA' in tekst, tekst)
    await pg.click('#btn-return-hub'); await pg.wait_for_timeout(300)
    r = await pg.evaluate("() => ({s: __P().stats.survived, lup: __P().stash.some(i=>i.uid==='lup1')})")
    ok('łup trafia do Skrytki', r['lup'], str(r))
    await pg.reload(); await pg.wait_for_timeout(400)
    r = await pg.evaluate("() => ({s: __P().stats.survived, raids: __P().stats.raids, lup: __P().stash.some(i=>i.uid==='lup1')})")
    ok('zapis przetrwał przeładowanie', r['s'] == 1 and r['raids'] == 1 and r['lup'], str(r))
    # śmierć
    ok('drugi rajd startuje', await start_rajdu(pg))
    await pg.evaluate("""() => { const r=__R(), p=r.player; p.loadout.reliquary=[{uid:'rel1',id:'runic_ring'}];
        p.hp=1; p.maxHp=100; r.enemies.forEach(e=>{e.x=p.x+0.8;e.y=p.y;e.state='combat';e.atkTimer=0;e.staggerTimer=0;e.windupTimer=0;}); }""")
    await pg.wait_for_timeout(4000)
    tekst = await pg.inner_text('#res-badge') if await pg.is_visible('#result-modal') else ''
    ok('śmierć kończy rajd', 'POLEG' in tekst, tekst)
    await pg.click('#btn-return-hub'); await pg.wait_for_timeout(300)
    r = await pg.evaluate("() => ({w: __P().loadout.weapon, rel: __P().loadout.reliquary.map(i=>i.uid), raids: __P().stats.raids})")
    ok('po śmierci: ekwipunek stracony, Relikwiarz ocalał', r['w'] is None and r['rel'] == ['rel1'] and r['raids'] == 2, str(r))
    ok('powrót do Warowni', await pg.is_visible('#hub-screen'))


async def main(tryb):
    from playwright.async_api import async_playwright
    plik = zbuduj_kopie_testowa()
    bledy = []
    async with async_playwright() as pw:
        b = await pw.chromium.launch()
        pg = await nowa_strona(b, plik, bledy)
        await test_szybki(pg)
        if tryb == 'pelny':
            await test_mechaniki(pg)
            pg2 = await nowa_strona(b, plik, bledy)
            ok('nowy rajd do pętli', await start_rajdu(pg2))
            await test_petla(pg2)
        await b.close()
    ok('brak błędów konsoli', not bledy, '; '.join(bledy[:3]))
    zle = [w for w in wyniki if not w[1]]
    print(f'\nWYNIK ({tryb}): ' + ('OK' if not zle else f'BŁĘDY: {len(zle)}') + f'  ({len(wyniki) - len(zle)}/{len(wyniki)})')
    return 0 if not zle else 1


def test_godot():
    """Gra w trybie testu: pełna pętla na symulowanym padzie, zrzuty ekranu do katalogu tymczasowego."""
    g = ROOT / 'godot'
    # Linter GDScriptu (gdtoolkit): na razie tylko ostrzega, nie blokuje
    try:
        lint = subprocess.run(['gdlint', *sorted(str(p) for p in (g / 'skrypty').glob('*.gd'))], capture_output=True, text=True)
        uwagi = [l for l in (lint.stdout + lint.stderr).splitlines() if ': Error:' in l]
        print(f'  gdlint: {len(uwagi)} uwag (styl; nie blokuje)')
    except FileNotFoundError:
        print('  gdlint: brak (pip install gdtoolkit)')
    subprocess.run(['godot', '--headless', '--path', str(g), '--import'], capture_output=True, timeout=300)
    tmp = pathlib.Path(tempfile.mkdtemp())
    r = subprocess.run(['xvfb-run', '-a', '-s', '-screen 0 1280x720x24', 'godot', '--path', str(g),
                        '--rendering-driver', 'opengl3', '--', '--test', f'--zrzuty={tmp / "zrzuty"}',
                        f'--zapis={tmp / "zapis_testowy.json"}'],
                       capture_output=True, text=True, timeout=600)  # 26.11: pełny test trwa ok. 5 min w środowisku agenta
    for linia in r.stdout.splitlines():
        if linia.startswith(('  OK', '  BŁĄD', 'WYNIK', '--')):
            print(linia)
    print(f'  zrzuty ekranu: {tmp / "zrzuty"}')
    bledy = [l for l in (r.stderr + r.stdout).splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l or 'ERROR: res://' in l]
    for b in bledy:
        print('  BŁĄD ' + b)
    return 0 if r.returncode == 0 and not bledy else 1


if __name__ == '__main__':
    tryb = sys.argv[1] if len(sys.argv) > 1 else 'szybki'
    if tryb == 'godot':
        sys.exit(test_godot())
    if tryb not in ('szybki', 'pelny'):
        raise SystemExit('Użycie: testy.py [szybki|pelny|godot]')
    sys.exit(asyncio.run(main(tryb)))
