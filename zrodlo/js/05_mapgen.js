// ==================== 7. PROCEDURAL DUNGEON GENERATOR ====================
const MAP_SIZE = 42;
const TILE = { FLOOR: 0, PATH: 1, WALL: 2, PILLAR: 3, BRAZIER: 4, RUBBLE: 5, EXTRACT: 6 };

function isBlockingMove(t) {
    return t === TILE.WALL || t === TILE.PILLAR || t === TILE.BRAZIER || t === TILE.RUBBLE;
}
function isBlockingSight(t) {
    return t === TILE.WALL || t === TILE.PILLAR;
}

function generateDungeon(zone, seedStr) {
    const rng = mulberry32(hashSeed(seedStr + '_' + zone.id));
    const grid = new Uint8Array(MAP_SIZE * MAP_SIZE);
    const variant = new Uint8Array(MAP_SIZE * MAP_SIZE);
    const lootBoxes = [];
    const extracts = [];
    const braziers = [];

    const idx = (x, y) => y * MAP_SIZE + x;
    const inB = (x, y) => x >= 1 && y >= 1 && x < MAP_SIZE - 1 && y < MAP_SIZE - 1;

    for (let i = 0; i < grid.length; i++) variant[i] = Math.floor(rng() * 3);

    // Border stone walls
    for (let i = 0; i < MAP_SIZE; i++) {
        grid[idx(i, 0)] = TILE.WALL;
        grid[idx(i, MAP_SIZE - 1)] = TILE.WALL;
        grid[idx(0, i)] = TILE.WALL;
        grid[idx(MAP_SIZE - 1, i)] = TILE.WALL;
    }

    // Main ancient stone avenues
    const midX = Math.floor(MAP_SIZE / 2) + Math.floor((rng() - 0.5) * 6);
    const midY = Math.floor(MAP_SIZE / 2) + Math.floor((rng() - 0.5) * 6);
    for (let x = 2; x < MAP_SIZE - 2; x++) {
        grid[idx(x, midY)] = TILE.PATH;
        grid[idx(x, midY + 1)] = TILE.PATH;
    }
    for (let y = 2; y < MAP_SIZE - 2; y++) {
        grid[idx(midX, y)] = TILE.PATH;
        grid[idx(midX + 1, y)] = TILE.PATH;
    }

    // Chambers / Ruined Crypts
    const rooms = [];
    const roomTarget = zone.id === 'catacombs' ? 8 : (zone.id === 'outskirts' ? 6 : 7);
    for (let tries = 0; tries < roomTarget * 4 && rooms.length < roomTarget; tries++) {
        const rw = 5 + Math.floor(rng() * 5);
        const rh = 5 + Math.floor(rng() * 5);
        const rx = 3 + Math.floor(rng() * (MAP_SIZE - rw - 6));
        const ry = 3 + Math.floor(rng() * (MAP_SIZE - rh - 6));
        let ok = true;
        for (let y = ry - 1; y <= ry + rh; y++) {
            for (let x = rx - 1; x <= rx + rw; x++) {
                const t = grid[idx(x, y)];
                if (t === TILE.PATH || t === TILE.WALL) { ok = false; break; }
            }
            if (!ok) break;
        }
        if (!ok) continue;

        for (let y = ry; y < ry + rh; y++) {
            for (let x = rx; x < rx + rw; x++) {
                if (x === rx || x === rx + rw - 1 || y === ry || y === ry + rh - 1) {
                    grid[idx(x, y)] = TILE.WALL;
                } else {
                    grid[idx(x, y)] = TILE.FLOOR;
                }
            }
        }
        // Carve 2-4 archways
        const doors = [
            [rx + Math.floor(rw / 2), ry],
            [rx + Math.floor(rw / 2), ry + rh - 1],
            [rx, ry + Math.floor(rh / 2)],
            [rx + rw - 1, ry + Math.floor(rh / 2)]
        ];
        let opened = 0;
        for (const [dx, dy] of doors) {
            if (rng() < 0.72 || opened < 2) {
                grid[idx(dx, dy)] = TILE.PATH;
                opened++;
            }
        }
        rooms.push({ x: rx, y: ry, w: rw, h: rh });
    }

    // Pillars, Rubble & Iron Braziers
    for (let y = 3; y < MAP_SIZE - 3; y++) {
        for (let x = 3; x < MAP_SIZE - 3; x++) {
            if (grid[idx(x, y)] === TILE.FLOOR) {
                const r = rng();
                if (r < 0.024) grid[idx(x, y)] = TILE.PILLAR;
                else if (r < 0.044) grid[idx(x, y)] = TILE.RUBBLE;
                else if (r < 0.056) {
                    grid[idx(x, y)] = TILE.BRAZIER;
                    braziers.push({ x: x + 0.5, y: y + 0.5 });
                }
            }
        }
    }

    // Spawn & 2 Runic Extraction Circles on far side
    const spawnTop = rng() < 0.5;
    const spawn = spawnTop ? { x: 4.5, y: 4.5 } : { x: 4.5, y: MAP_SIZE - 5.5 };
    const extCoords = spawnTop
        ? [{ x: MAP_SIZE - 5, y: MAP_SIZE - 6, name: 'Krąg Południowy' }, { x: MAP_SIZE - 6, y: 5, name: 'Brama Wschodnia' }]
        : [{ x: MAP_SIZE - 5, y: 5, name: 'Krąg Północny' }, { x: MAP_SIZE - 6, y: MAP_SIZE - 6, name: 'Ołtarz Powrotu' }];

    // Clear spawn area + place welcome brazier
    for (let dy = -2; dy <= 2; dy++) {
        for (let dx = -2; dx <= 2; dx++) {
            const tx = Math.floor(spawn.x) + dx, ty = Math.floor(spawn.y) + dy;
            if (inB(tx, ty)) grid[idx(tx, ty)] = TILE.PATH;
        }
    }
    grid[idx(Math.floor(spawn.x) + 2, Math.floor(spawn.y) - 1)] = TILE.BRAZIER;
    braziers.push({ x: Math.floor(spawn.x) + 2.5, y: Math.floor(spawn.y) - 0.5 });

    for (const ex of extCoords) {
        for (let dy = -1; dy <= 1; dy++) {
            for (let dx = -1; dx <= 1; dx++) {
                if (inB(ex.x + dx, ex.y + dy)) grid[idx(ex.x + dx, ex.y + dy)] = TILE.PATH;
            }
        }
        grid[idx(ex.x, ex.y)] = TILE.EXTRACT;
        extracts.push({ x: ex.x + 0.5, y: ex.y + 0.5, name: ex.name, radius: 1.85 });
    }

    // Loot generation
    const luckBonus = (profile.skills.scavenger.lv - 1) * 0.04 + (zone.id === 'crypt' ? 0.22 : (zone.id === 'outskirts' ? 0.1 : 0));
    const rollLoot = (kind) => {
        const items = [];
        const cnt = 2 + Math.floor(rng() * 3);
        const pools = {
            loot_chest: ['iron_ingot', 'iron_arrows', 'ember_flask', 'stamina_tonic', 'ash_salve', 'silver_goblet', 'steel_falchion', 'iron_kite', 'yew_longbow'],
            loot_sarcophagus: ['ash_essence', 'ancient_relic', 'runic_ring', 'golden_idol', 'ash_greatsword', 'ash_plate', 'ember_flask'],
            loot_knight: ['iron_ingot', 'iron_arrows', 'chainmail_hauberk', 'warden_glaive', 'iron_kite', 'ash_salve', 'silver_goblet']
        };
        const pool = pools[kind] || pools.loot_chest;
        for (let i = 0; i < cnt; i++) {
            let pick = pool[Math.floor(rng() * pool.length)];
            if (['ancient_relic', 'golden_idol', 'ash_greatsword', 'ash_plate'].includes(pick) && rng() > 0.35 + luckBonus) {
                pick = rng() < 0.5 ? 'ash_essence' : 'runic_ring';
            }
            const it = makeItem(pick);
            if (it) items.push({ item: it, revealed: false });
        }
        return items;
    };

    const names = {
        loot_chest: 'Okuta Skrzynia',
        loot_sarcophagus: 'Kamienny Sarkofag',
        loot_knight: 'Szczątki Rycerza'
    };

    for (const r of rooms) {
        const c = 1 + Math.floor(rng() * 2);
        for (let i = 0; i < c; i++) {
            const lx = r.x + 1 + Math.floor(rng() * (r.w - 2));
            const ly = r.y + 1 + Math.floor(rng() * (r.h - 2));
            if (isBlockingMove(grid[idx(lx, ly)]) || lootBoxes.some(b => b.tx === lx && b.ty === ly)) continue;
            const rr = rng();
            const kind = rr < 0.42 ? 'loot_sarcophagus' : (rr < 0.78 ? 'loot_chest' : 'loot_knight');
            lootBoxes.push({ id: 'lb_' + lootBoxes.length, tx: lx, ty: ly, x: lx + 0.5, y: ly + 0.5, kind, name: names[kind], items: rollLoot(kind) });
        }
    }
    // Outdoor piles & chests
    for (let k = 0; k < 10; k++) {
        const lx = 4 + Math.floor(rng() * (MAP_SIZE - 8));
        const ly = 4 + Math.floor(rng() * (MAP_SIZE - 8));
        if (grid[idx(lx, ly)] !== TILE.FLOOR || lootBoxes.some(b => b.tx === lx && b.ty === ly)) continue;
        const kind = rng() < 0.5 ? 'loot_chest' : 'loot_knight';
        lootBoxes.push({ id: 'lb_' + lootBoxes.length, tx: lx, ty: ly, x: lx + 0.5, y: ly + 0.5, kind, name: names[kind], items: rollLoot(kind) });
    }

    return { grid, variant, lootBoxes, extracts, braziers, spawn, rooms, rng };
}
