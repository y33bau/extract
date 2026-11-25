// ==================== 10. RAID ENGINE (SOULSBORNE ISOMETRIC 2.5D) ====================
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
const miniCanvas = document.getElementById('minimapCanvas');
const miniCtx = miniCanvas.getContext('2d');
const lightCanvas = document.createElement('canvas');
const lightCtx = lightCanvas.getContext('2d');

let raid = null;
const keys = {};
const mouse = { x: 0, y: 0, lmb: false, rmb: false };

function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    ctx.imageSmoothingEnabled = false;
    lightCanvas.width = Math.max(1, Math.ceil(canvas.width / 2));
    lightCanvas.height = Math.max(1, Math.ceil(canvas.height / 2));
}
window.addEventListener('resize', resizeCanvas);

function worldToScreen(wx, wy, camX, camY) {
    return {
        x: (wx - wy) * (TILE_W / 2) - camX + canvas.width / 2,
        y: (wx + wy) * (TILE_H / 2) - camY + canvas.height / 2
    };
}
function screenToWorld(sx, sy, camX, camY) {
    const ix = sx - canvas.width / 2 + camX;
    const iy = sy - canvas.height / 2 + camY;
    return {
        x: (ix / (TILE_W / 2) + iy / (TILE_H / 2)) / 2,
        y: (iy / (TILE_H / 2) - ix / (TILE_W / 2)) / 2
    };
}

function startRaid() {
    SFX.init();
    const zone = ZONES.find(z => z.id === selectedZoneId) || ZONES[0];
    const seedVal = (document.getElementById('seed-input').value.trim().toUpperCase()) || randomSeedStr();
    currentSeed = seedVal;

    ATLAS.buildForZone(zone);
    const map = generateDungeon(zone, seedVal);
    const raidLoadout = JSON.parse(JSON.stringify(profile.loadout));

    const maxHp = 100 + profile.stronghold.altar * 18;
    const maxStam = 100 + profile.stronghold.altar * 15;

    // Postura (równowaga) wrogów: po wyzerowaniu wróg jest ogłuszony i otwarty na ripostę
    const POISE_MAX = { scout: 40, warden: 75, archer: 30, knight: 95, brute: 120, boss: 230 };

    const player = {
        x: map.spawn.x, y: map.spawn.y, radius: 0.28, angle: 0,
        hp: maxHp, maxHp,
        stamina: maxStam, maxStamina: maxStam,
        stamRegenBoost: 0,
        burning: false, burnTick: 0,
        walkFrame: 0, stepTimer: 0,
        // Soulsborne combat states
        attackTimer: 0, attackDur: 0, attackCd: 0, attackAngle: 0, comboStep: 0, comboReset: 0,
        blocking: false, parryWindow: 0, parryCd: 0,
        dodgeTimer: 0, dodgeDx: 0, dodgeDy: 0, dodgeCd: 0,
        bowCd: 0,
        swingAnim: 0, swingAnimMax: 0.3, moving: false, dead: false,
        // Runda 1: pochodnia w ręce tarczy, nietykalność riposty
        torchInHand: true, riposteIframe: 0,
        loadout: raidLoadout
    };

    // Spawn Dark Fantasy Enemies
    const enemies = [];
    const rng = map.rng;
    for (let i = 0; i < zone.enemyCount; i++) {
        let ex = 0, ey = 0, tries = 0;
        while (tries < 60) {
            ex = 3 + Math.floor(rng() * (MAP_SIZE - 6)) + 0.5;
            ey = 3 + Math.floor(rng() * (MAP_SIZE - 6)) + 0.5;
            if (Math.hypot(ex - player.x, ey - player.y) > 9 && !isBlockingMove(map.grid[Math.floor(ey) * MAP_SIZE + Math.floor(ex)])) break;
            tries++;
        }
        const r = rng();
        let kind = 'scout';
        const table = {
            catacombs: [['scout', 0.5], ['warden', 0.3], ['archer', 0.2]],
            outskirts: [['scout', 0.25], ['warden', 0.25], ['archer', 0.2], ['knight', 0.2], ['brute', 0.1]],
            crypt:     [['scout', 0.15], ['warden', 0.2], ['archer', 0.15], ['knight', 0.25], ['brute', 0.25]]
        }[zone.id];
        let acc = 0;
        for (const [k, w] of table) { acc += w; if (r < acc) { kind = k; break; } }

        const cfg = {
            scout:  { name: 'Popielny Zwiadowca', hp: 65,  spd: 2.6, dmg: 18, range: 1.45, windup: 0.42, cd: 1.0,  armor: 0 },
            warden: { name: 'Upadły Gwardzista',  hp: 115, spd: 1.9, dmg: 30, range: 1.75, windup: 0.62, cd: 1.45, armor: 0.22 },
            archer: { name: 'Kusznik Cienia',     hp: 55,  spd: 2.1, dmg: 19, range: 9.5,  windup: 0.68, cd: 1.8,  armor: 0 },
            knight: { name: 'Zakonny Rycerz',     hp: 150, spd: 1.8, dmg: 34, range: 1.85, windup: 0.55, cd: 1.3,  armor: 0.30 },
            brute:  { name: 'Kat Ruin',           hp: 190, spd: 1.6, dmg: 46, range: 1.95, windup: 0.85, cd: 1.9,  armor: 0.12, heavy: true }
        }[kind];

        enemies.push({
            id: 'en_' + i, kind, name: cfg.name, isBoss: false, heavy: !!cfg.heavy,
            x: ex, y: ey, radius: kind === 'brute' ? 0.36 : (kind === 'warden' || kind === 'knight' ? 0.32 : 0.27),
            angle: rng() * Math.PI * 2,
            hp: cfg.hp, maxHp: cfg.hp, armorRed: cfg.armor,
            spd: cfg.spd, dmg: cfg.dmg, atkRange: cfg.range,
            windupDur: cfg.windup, atkCdMax: cfg.cd,
            state: 'patrol', patrolTarget: { x: ex, y: ey },
            atkTimer: 0, windupTimer: 0, staggerTimer: 0, atkSwingVisual: 0,
            walkFrame: 0, hitFlash: 0,
            poise: POISE_MAX[kind], maxPoise: POISE_MAX[kind], poiseRegenDelay: 0
        });
    }

    // Sector Boss in Crypt of the Ash King
    if (zone.hasBoss) {
        let bx = MAP_SIZE / 2 + 0.5, by = MAP_SIZE / 2 + 0.5;
        for (let t = 0; t < 50; t++) {
            const tx = 14 + Math.floor(rng() * (MAP_SIZE - 24));
            const ty = 14 + Math.floor(rng() * (MAP_SIZE - 24));
            if (!isBlockingMove(map.grid[ty * MAP_SIZE + tx])) { bx = tx + 0.5; by = ty + 0.5; break; }
        }
        enemies.push({
            id: 'boss_ash', kind: 'boss', name: 'BOSS: POPIELNY STRAŻNIK', isBoss: true,
            x: bx, y: by, radius: 0.38, angle: 0,
            hp: 340, maxHp: 340, armorRed: 0.30,
            spd: 2.25, dmg: 44, atkRange: 2.15,
            windupDur: 0.72, atkCdMax: 1.35,
            state: 'patrol', patrolTarget: { x: bx, y: by },
            atkTimer: 0, windupTimer: 0, staggerTimer: 0, atkSwingVisual: 0,
            walkFrame: 0, hitFlash: 0,
            poise: POISE_MAX.boss, maxPoise: POISE_MAX.boss, poiseRegenDelay: 0
        });
    }

    raid = {
        zone, seed: seedVal, map, player, enemies,
        corpses: [], arrows: [], particles: [], ghosts: [], floatTexts: [], flashes: [],
        ashFlakes: Array.from({ length: 65 }, () => ({
            x: Math.random() * window.innerWidth,
            y: Math.random() * window.innerHeight,
            spd: 0.6 + Math.random() * 0.8,
            phase: Math.random() * Math.PI * 2,
            size: 1 + Math.floor(Math.random() * 2)
        })),
        visMap: new Uint8Array(MAP_SIZE * MAP_SIZE),
        camX: (player.x - player.y) * (TILE_W / 2),
        camY: (player.x + player.y) * (TILE_H / 2),
        shake: 0, hitstop: 0, hitFlash: 0, parryFlash: 0,
        timeLeft: 480, elapsed: 0, kills: 0, parries: 0,
        extracting: false, extractTimer: 6.0, extractLastSec: 6,
        modalOpen: false, activeLoot: null, searchProg: 0,
        ended: false, lastTime: performance.now(), visTimer: 0,
        groundTorch: null
    };

    document.getElementById('hub-screen').classList.add('hidden');
    document.getElementById('raid-screen').classList.remove('hidden');
    document.getElementById('result-modal').classList.add('hidden');
    document.getElementById('raid-modal').classList.add('hidden');
    document.getElementById('hud-zone').textContent = zone.name.toUpperCase();
    document.getElementById('hud-seed').textContent = seedVal;

    resizeCanvas();
    computeVisibility();
    updateRaidHUD();
    requestAnimationFrame(raidLoop);
    setTimeout(() => showToast('🔥 Pochodnia zajmuje rękę tarczy: nie parujesz. [F] rzuć ją przed walką.', 'info'), 400);
}

// ==================== 11. COLLISION & VISIBILITY ====================
function isSolidAt(x, y) {
    const tx = Math.floor(x), ty = Math.floor(y);
    if (tx < 0 || ty < 0 || tx >= MAP_SIZE || ty >= MAP_SIZE) return true;
    return isBlockingMove(raid.map.grid[ty * MAP_SIZE + tx]);
}

function moveEntity(ent, dx, dy) {
    const r = ent.radius;
    const nx = ent.x + dx;
    if (!isSolidAt(nx - r, ent.y - r) && !isSolidAt(nx + r, ent.y - r) &&
        !isSolidAt(nx - r, ent.y + r) && !isSolidAt(nx + r, ent.y + r)) ent.x = nx;
    const ny = ent.y + dy;
    if (!isSolidAt(ent.x - r, ny - r) && !isSolidAt(ent.x + r, ny - r) &&
        !isSolidAt(ent.x - r, ny + r) && !isSolidAt(ent.x + r, ny + r)) ent.y = ny;
}

function hasLOS(x1, y1, x2, y2) {
    const dist = Math.hypot(x2 - x1, y2 - y1);
    const steps = Math.ceil(dist * 3.5);
    for (let i = 1; i < steps; i++) {
        const t = i / steps;
        const tx = Math.floor(x1 + (x2 - x1) * t);
        const ty = Math.floor(y1 + (y2 - y1) * t);
        if (tx < 0 || ty < 0 || tx >= MAP_SIZE || ty >= MAP_SIZE) return false;
        if (isBlockingSight(raid.map.grid[ty * MAP_SIZE + tx])) return false;
    }
    return true;
}

// Jak daleko widzi gracz: pełny wzrok z pochodnią w ręce lub w kręgu innego światła, inaczej połowa
function nearLightSource(x, y) {
    const gt = raid.groundTorch;
    if (gt && Math.hypot(gt.x - x, gt.y - y) < 4.6) return true;
    for (const br of raid.map.braziers) if (Math.hypot(br.x - x, br.y - y) < 3.4) return true;
    for (const ex of raid.map.extracts) if (Math.hypot(ex.x - x, ex.y - y) < 3.4) return true;
    return false;
}
function playerSightFactor() {
    const p = raid.player;
    return (p.torchInHand || nearLightSource(p.x, p.y)) ? 1 : 0.5;
}

function computeVisibility() {
    const vis = raid.visMap;
    for (let i = 0; i < vis.length; i++) if (vis[i] === 2) vis[i] = 1;
    const px = raid.player.x, py = raid.player.y, aim = raid.player.angle;
    const sight = playerSightFactor();
    const rays = 128;
    for (let r = 0; r < rays; r++) {
        const ang = (r / rays) * Math.PI * 2;
        let diff = ang - aim;
        while (diff > Math.PI) diff -= Math.PI * 2;
        while (diff < -Math.PI) diff += Math.PI * 2;
        const maxD = (Math.abs(diff) < 1.1 ? 11.5 : 4.8) * sight;
        const c = Math.cos(ang), s = Math.sin(ang);
        for (let d = 0.25; d <= maxD; d += 0.38) {
            const tx = Math.floor(px + c * d), ty = Math.floor(py + s * d);
            if (tx < 0 || ty < 0 || tx >= MAP_SIZE || ty >= MAP_SIZE) break;
            const i = ty * MAP_SIZE + tx;
            vis[i] = 2;
            if (isBlockingSight(raid.map.grid[i])) break;
        }
    }
}
