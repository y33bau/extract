// ==================== 5. PROCEDURAL PIXEL-ART ITEM ICONS ====================
const ITEM_ICONS = {};
function buildItemIcons() {
    const make = (id, fn) => {
        const c = document.createElement('canvas');
        c.width = 24; c.height = 24;
        const g = c.getContext('2d');
        g.imageSmoothingEnabled = false;
        fn(g);
        ITEM_ICONS[id] = c.toDataURL();
    };

    // Melee Weapons
    const drawSword = (g, blade, edge, hilt, pommel) => {
        for (let i = 0; i < 12; i++) {
            g.fillStyle = blade; g.fillRect(18 - i, 4 + i, 2, 2);
            g.fillStyle = edge; g.fillRect(19 - i, 4 + i, 1, 1);
        }
        g.fillStyle = hilt; g.fillRect(5, 13, 6, 2); g.fillRect(8, 13, 2, 6);
        g.fillStyle = '#4a3222'; g.fillRect(5, 17, 3, 3);
        g.fillStyle = pommel; g.fillRect(4, 19, 2, 2);
    };
    make('rusty_sword', g => drawSword(g, '#7a685b', '#9c8676', '#5c4b3c', '#8c6e46'));
    make('steel_falchion', g => drawSword(g, '#96a0ab', '#cfd8e3', '#9e7c3e', '#d4aa55'));
    make('warden_glaive', g => {
        for (let i = 0; i < 14; i++) { g.fillStyle = '#5c4028'; g.fillRect(4 + i, 19 - i, 2, 2); }
        g.fillStyle = '#adb8c4'; g.fillRect(15, 3, 5, 6);
        g.fillStyle = '#dce6f0'; g.fillRect(18, 3, 2, 5);
        g.fillStyle = '#c79c4c'; g.fillRect(14, 8, 3, 2);
    });
    make('ash_greatsword', g => {
        for (let i = 0; i < 13; i++) {
            g.fillStyle = '#332e36'; g.fillRect(17 - i, 3 + i, 3, 3);
            g.fillStyle = '#e06324'; g.fillRect(18 - i, 4 + i, 1, 1);
        }
        g.fillStyle = '#c79c4c'; g.fillRect(4, 13, 8, 2); g.fillRect(9, 13, 2, 7);
        g.fillStyle = '#291e1a'; g.fillRect(5, 17, 3, 3);
    });
    make('executioner_axe', g => {
        for (let i = 0; i < 14; i++) { g.fillStyle = '#4a3222'; g.fillRect(5 + i, 19 - i, 2, 2); }
        g.fillStyle = '#5e5a63'; g.fillRect(12, 4, 8, 8);
        g.fillStyle = '#d43f49'; g.fillRect(18, 5, 2, 6);
        g.fillStyle = '#c79c4c'; g.fillRect(13, 7, 3, 2);
    });

    // Shields
    const drawShield = (g, main, rim, emblem) => {
        g.fillStyle = rim; g.fillRect(5, 4, 14, 13); g.fillRect(7, 17, 10, 3); g.fillRect(10, 20, 4, 2);
        g.fillStyle = main; g.fillRect(7, 6, 10, 10); g.fillRect(9, 16, 6, 3);
        g.fillStyle = emblem; g.fillRect(11, 8, 2, 7); g.fillRect(9, 10, 6, 2);
    };
    make('wood_buckler', g => drawShield(g, '#6e4a2e', '#8c694a', '#b59a5b'));
    make('iron_kite', g => drawShield(g, '#4f565e', '#8b95a0', '#c79c4c'));
    make('ash_aegis', g => drawShield(g, '#2d2630', '#c79c4c', '#e06324'));

    // Bows & Arrows
    const drawBow = (g, wood, string) => {
        g.fillStyle = wood;
        g.fillRect(8, 4, 5, 2); g.fillRect(12, 6, 3, 3); g.fillRect(14, 9, 2, 6); g.fillRect(12, 15, 3, 3); g.fillRect(8, 18, 5, 2);
        g.fillStyle = string;
        g.fillRect(8, 6, 1, 12);
    };
    make('hunter_bow', g => drawBow(g, '#7d522d', '#c7bfb5'));
    make('yew_longbow', g => drawBow(g, '#9e622d', '#e6ba63'));
    make('shadow_bow', g => drawBow(g, '#393040', '#34d399'));
    make('iron_arrows', g => {
        for (let k = 0; k < 3; k++) {
            const ox = k * 4;
            g.fillStyle = '#7d5938'; g.fillRect(5 + ox, 8, 2, 11);
            g.fillStyle = '#b5bec7'; g.fillRect(5 + ox, 4, 2, 4);
            g.fillStyle = '#c43b3b'; g.fillRect(4 + ox, 17, 4, 3);
        }
    });

    // Armor
    const drawArmor = (g, body, plate, trim) => {
        g.fillStyle = '#18141b'; g.fillRect(5, 4, 14, 16);
        g.fillStyle = body; g.fillRect(6, 5, 12, 14);
        g.fillStyle = '#100d12'; g.fillRect(9, 4, 6, 4);
        g.fillStyle = plate; g.fillRect(8, 9, 8, 8);
        g.fillStyle = trim; g.fillRect(6, 12, 12, 2);
    };
    make('leather_jerkin', g => drawArmor(g, '#664830', '#4f3623', '#8c694a'));
    make('chainmail_hauberk', g => drawArmor(g, '#6b727a', '#4f555c', '#c79c4c'));
    make('ash_plate', g => drawArmor(g, '#332d36', '#4a414f', '#e06324'));

    // Elixirs
    const drawFlask = (g, liquid, glow) => {
        g.fillStyle = '#8c7d6b'; g.fillRect(10, 4, 4, 3);
        g.fillStyle = '#3d3742'; g.fillRect(9, 7, 6, 2);
        g.fillStyle = liquid; g.fillRect(6, 9, 12, 11); g.fillRect(8, 20, 8, 1);
        g.fillStyle = glow; g.fillRect(8, 11, 3, 5);
    };
    make('ember_flask', g => drawFlask(g, '#b8252f', '#ff7b47'));
    make('stamina_tonic', g => drawFlask(g, '#28854f', '#6ee7b7'));
    make('ash_salve', g => {
        g.fillStyle = '#5c4e43'; g.fillRect(6, 9, 12, 10);
        g.fillStyle = '#9e8b76'; g.fillRect(7, 7, 10, 3);
        g.fillStyle = '#e07a38'; g.fillRect(9, 12, 6, 4);
    });

    // Materials & Valuables
    make('iron_ingot', g => {
        g.fillStyle = '#4f5761'; g.fillRect(4, 11, 16, 7);
        g.fillStyle = '#8d97a3'; g.fillRect(6, 8, 12, 4);
        g.fillStyle = '#c4cdd6'; g.fillRect(7, 9, 8, 2);
    });
    make('ash_essence', g => {
        g.fillStyle = '#5c2214'; g.fillRect(7, 7, 10, 12);
        g.fillStyle = '#e06324'; g.fillRect(9, 5, 6, 12);
        g.fillStyle = '#ffd166'; g.fillRect(11, 8, 2, 6);
    });
    make('ancient_relic', g => {
        g.fillStyle = '#755823'; g.fillRect(8, 4, 8, 16);
        g.fillStyle = '#e6ba63'; g.fillRect(6, 8, 12, 8);
        g.fillStyle = '#34d399'; g.fillRect(10, 10, 4, 4);
    });
    make('silver_goblet', g => {
        g.fillStyle = '#9aa3ad'; g.fillRect(7, 5, 10, 8); g.fillRect(11, 13, 2, 5); g.fillRect(8, 18, 8, 2);
        g.fillStyle = '#dce3eb'; g.fillRect(8, 6, 3, 6);
    });
    make('runic_ring', g => {
        g.fillStyle = '#c79c4c'; g.fillRect(7, 8, 10, 10);
        g.fillStyle = '#110f13'; g.fillRect(9, 10, 6, 6);
        g.fillStyle = '#4d88c7'; g.fillRect(10, 6, 4, 3);
    });
    make('golden_idol', g => {
        g.fillStyle = '#9e7526'; g.fillRect(8, 5, 8, 15);
        g.fillStyle = '#e6ba63'; g.fillRect(9, 6, 6, 6); g.fillRect(7, 13, 10, 6);
        g.fillStyle = '#d43f49'; g.fillRect(10, 8, 1, 1); g.fillRect(13, 8, 1, 1);
    });
    make('ash_crown', g => {
        g.fillStyle = '#c79c4c'; g.fillRect(4, 12, 16, 6);
        g.fillRect(4, 7, 3, 5); g.fillRect(10, 5, 4, 7); g.fillRect(17, 7, 3, 5);
        g.fillStyle = '#e06324'; g.fillRect(11, 13, 2, 3);
        g.fillStyle = '#d43f49'; g.fillRect(6, 14, 2, 2); g.fillRect(16, 14, 2, 2);
    });
}
buildItemIcons();

function iconHtml(def, size = 24) {
    return `<img src="${ITEM_ICONS[def.id] || ''}" width="${size}" height="${size}" class="pixel-icon" alt="${def.name}">`;
}

// ==================== 6. PIXEL-ART ISOMETRIC TILE ATLAS ====================
const TILE_W = 64;
const TILE_H = 32;

class PixelAtlas {
    constructor() { this.sprites = {}; }
    mk(w, h) {
        const c = document.createElement('canvas');
        c.width = w; c.height = h;
        return c;
    }
    drawDiamond(ctx, w, h, base, noises, seed, border = 'rgba(0,0,0,0.22)') {
        const rng = mulberry32(9001 + seed);
        const hw = w / 2, hh = h / 2;
        for (let y = 0; y < h; y++) {
            const dy = Math.abs(y - hh + 0.5) / hh;
            const span = Math.floor(hw * (1 - dy));
            for (let x = hw - span; x < hw + span; x++) {
                let col = base;
                const r = rng();
                if (noises && (r < 0.25 || ((x + y) % 2 === 0 && r < 0.36))) {
                    col = noises[Math.floor(rng() * noises.length)];
                }
                if (border && (x === hw - span || x === hw + span - 1)) col = border;
                ctx.fillStyle = col;
                ctx.fillRect(x, y, 1, 1);
            }
        }
    }
    drawIsoBlock(ctx, w, h, wallH, topCol, leftCol, rightCol, detailFn) {
        const hw = w / 2, hh = 8;
        // Ground AO shadow
        ctx.fillStyle = 'rgba(0,0,0,0.48)';
        for (let x = 0; x < hw; x++) {
            const yb = hh + Math.floor((x / hw) * hh) + wallH;
            ctx.fillRect(x, yb - 1, 1, 3);
        }
        for (let x = hw; x < w; x++) {
            const yb = 2 * hh - Math.floor(((x - hw) / hw) * hh) - 1 + wallH;
            ctx.fillRect(x, yb - 1, 1, 3);
        }
        // Left face
        for (let x = 0; x < hw; x++) {
            const yt = hh + Math.floor((x / hw) * hh);
            ctx.fillStyle = leftCol; ctx.fillRect(x, yt, 1, wallH);
            ctx.fillStyle = 'rgba(0,0,0,0.32)'; ctx.fillRect(x, yt + wallH - 3, 1, 3);
        }
        // Right face
        for (let x = hw; x < w; x++) {
            const yt = 2 * hh - Math.floor(((x - hw) / hw) * hh) - 1;
            ctx.fillStyle = rightCol; ctx.fillRect(x, yt, 1, wallH);
            ctx.fillStyle = 'rgba(0,0,0,0.38)'; ctx.fillRect(x, yt + wallH - 3, 1, 3);
        }
        // Top diamond
        for (let y = 0; y < hh * 2; y++) {
            const dy = Math.abs(y - hh + 0.5) / hh;
            const span = Math.floor(hw * (1 - dy));
            ctx.fillStyle = topCol; ctx.fillRect(hw - span, y, span * 2, 1);
            if (y < hh) {
                ctx.fillStyle = 'rgba(255,240,220,0.09)';
                ctx.fillRect(hw - span, y, 2, 1);
            }
        }
        ctx.fillStyle = 'rgba(0,0,0,0.28)';
        ctx.fillRect(hw - 1, hh * 2 - 1, 2, wallH);
        if (detailFn) detailFn(ctx, w, h, wallH, hw, hh);
    }

    buildForZone(zone) {
        const p = zone.palette;
        this.sprites = {};

        const mkTile = (key, base, noises, seed, fn) => {
            const c = this.mk(32, 16);
            const g = c.getContext('2d');
            this.drawDiamond(g, 32, 16, base, noises, seed);
            if (fn) fn(g);
            this.sprites[key] = c;
        };

        mkTile('floor_0', p.floor1, [p.floor2, '#1f1c21', '#3b353e'], 11, g => {
            g.fillStyle = 'rgba(0,0,0,0.35)';
            g.fillRect(10, 7, 5, 1); g.fillRect(15, 8, 3, 1);
        });
        mkTile('floor_1', p.floor2, [p.floor1, '#221f24', '#403942'], 22, g => {
            // Stone slab seam
            g.fillStyle = 'rgba(0,0,0,0.28)';
            g.fillRect(8, 8, 16, 1);
            g.fillStyle = 'rgba(255,240,220,0.06)';
            g.fillRect(9, 7, 14, 1);
        });
        mkTile('floor_2', p.floor1, [p.moss, p.floor2, '#21261e'], 33, g => {
            // Mossy cracks
            g.fillStyle = p.moss;
            g.fillRect(11, 6, 6, 3); g.fillRect(16, 8, 4, 2);
        });
        mkTile('path', '#262328', ['#1d1a1f', '#302c33'], 44, g => {
            g.fillStyle = 'rgba(199,156,76,0.12)';
            g.fillRect(13, 7, 6, 2);
        });
        mkTile('extract', '#132924', ['#193b33', '#235448', '#34d399'], 88, g => {
            // Glowing runic circle on stone
            g.fillStyle = '#34d399';
            g.fillRect(11, 5, 10, 1); g.fillRect(11, 10, 10, 1);
            g.fillRect(9, 6, 2, 4); g.fillRect(21, 6, 2, 4);
            g.fillStyle = '#a7f3d0';
            g.fillRect(15, 7, 2, 2);
        });

        // Crumbling Stone Wall (32x36)
        {
            const c = this.mk(32, 36);
            const g = c.getContext('2d');
            this.drawIsoBlock(g, 32, 36, 20, p.wallTop, p.wallL, p.wallR, (ctx, w, h, wh, hw, hh) => {
                const rng = mulberry32(404);
                for (let y = hh + 2; y < hh + wh - 2; y += 4) {
                    for (let x = 2; x < w - 2; x += 5) {
                        if (rng() < 0.5) {
                            ctx.fillStyle = 'rgba(0,0,0,0.32)';
                            ctx.fillRect(x, y, 4, 1);
                        }
                    }
                }
                // Cracks & moss streaks
                ctx.fillStyle = 'rgba(10,8,12,0.45)';
                ctx.fillRect(8, 15, 1, 8); ctx.fillRect(21, 17, 1, 7);
                ctx.fillStyle = p.moss;
                ctx.fillRect(4, 24, 3, 4); ctx.fillRect(24, 23, 3, 3);
            });
            this.sprites['wall'] = c;
        }

        // Ancient Stone Pillar (32x36)
        {
            const c = this.mk(32, 36);
            const g = c.getContext('2d');
            g.fillStyle = 'rgba(0,0,0,0.48)'; g.fillRect(9, 28, 14, 4);
            g.fillStyle = p.wallL; g.fillRect(10, 8, 6, 22);
            g.fillStyle = p.wallR; g.fillRect(16, 8, 6, 22);
            g.fillStyle = p.wallTop; g.fillRect(9, 6, 14, 3); g.fillRect(9, 27, 14, 3);
            g.fillStyle = 'rgba(199,156,76,0.35)'; g.fillRect(11, 10, 10, 1);
            this.sprites['pillar'] = c;
        }

        // Iron Brazier with Fire (32x28)
        {
            const c = this.mk(32, 28);
            const g = c.getContext('2d');
            g.fillStyle = 'rgba(0,0,0,0.48)'; g.fillRect(10, 22, 12, 3);
            g.fillStyle = '#242026'; g.fillRect(14, 15, 4, 8); g.fillRect(11, 21, 10, 2);
            g.fillStyle = '#38323b'; g.fillRect(10, 11, 12, 5);
            g.fillStyle = '#5c5261'; g.fillRect(11, 11, 10, 1);
            g.fillStyle = '#e0531a'; g.fillRect(12, 8, 8, 4);
            g.fillStyle = '#ffd166'; g.fillRect(14, 7, 4, 4);
            this.sprites['brazier'] = c;
        }

        // Broken Rubble / Barricade (32x24)
        {
            const c = this.mk(32, 24);
            const g = c.getContext('2d');
            g.fillStyle = 'rgba(0,0,0,0.42)'; g.fillRect(7, 16, 18, 4);
            g.fillStyle = p.wallL; g.fillRect(8, 12, 8, 6); g.fillRect(15, 13, 8, 5);
            g.fillStyle = p.wallTop; g.fillRect(11, 9, 9, 4);
            g.fillStyle = p.wallR; g.fillRect(17, 14, 6, 4);
            this.sprites['rubble'] = c;
        }

        // Loot Containers: Wooden Chest, Stone Sarcophagus, Fallen Knight Pile
        {
            // Chest
            const c = this.mk(32, 24);
            const g = c.getContext('2d');
            g.fillStyle = 'rgba(0,0,0,0.5)'; g.fillRect(8, 18, 16, 3);
            g.fillStyle = '#593b22'; g.fillRect(9, 10, 14, 9);
            g.fillStyle = '#7a5230'; g.fillRect(10, 8, 12, 4);
            g.fillStyle = '#c79c4c'; g.fillRect(9, 12, 14, 1); g.fillRect(15, 11, 2, 4);
            this.sprites['loot_chest'] = c;
        }
        {
            // Sarcophagus
            const c = this.mk(32, 26);
            const g = c.getContext('2d');
            g.fillStyle = 'rgba(0,0,0,0.5)'; g.fillRect(6, 19, 20, 4);
            g.fillStyle = '#47424a'; g.fillRect(7, 12, 18, 8);
            g.fillStyle = '#68616e'; g.fillRect(8, 9, 16, 4);
            g.fillStyle = '#c79c4c'; g.fillRect(12, 10, 8, 2);
            this.sprites['loot_sarcophagus'] = c;
        }
        {
            // Fallen Knight Gear Pile
            const c = this.mk(32, 24);
            const g = c.getContext('2d');
            g.fillStyle = 'rgba(0,0,0,0.5)'; g.fillRect(8, 17, 16, 4);
            g.fillStyle = '#4f555e'; g.fillRect(10, 12, 10, 6);
            g.fillStyle = '#7a838f'; g.fillRect(12, 10, 5, 4);
            g.fillStyle = '#9e2a2b'; g.fillRect(16, 14, 6, 3); // tattered cloak
            g.fillStyle = '#c79c4c'; g.fillRect(11, 14, 3, 2);
            this.sprites['loot_knight'] = c;
        }
    }
}
const ATLAS = new PixelAtlas();

// ==================== 6b. NIGHTBRAND SPRITE SHEETS (Hadræn + wrogowie) ====================
// Arkusze z NightBrand: bohater 4x6 klatek (rzędy: przód/bok/tył), wrogowie 4x2 (chód / atak+śmierć).
const SPRITE_NAMES = ['knight_d', 'knight_def', 'knight_dc', 'knight_death',
    'en_scout', 'en_warden', 'en_archer', 'en_knight', 'en_brute', 'en_boss'];
// W wersji zbudowanej obrazy są wszyte w plik (window.__SPRITE_DATA__), w wersji roboczej ładowane z zasoby/sprite/
const SPRITE_DATA = window.__SPRITE_DATA__ ||
    Object.fromEntries(SPRITE_NAMES.map(k => [k, '../zasoby/sprite/' + k + '.webp']));
const SPR = {};
for (const [k, src] of Object.entries(SPRITE_DATA)) {
    const img = new Image();
    img.src = src;
    const big = k === 'en_boss';
    SPR[k] = { img, fw: big ? 192 : 128, fh: big ? 192 : 128, white: null };
}
function sprReady(s) { return s && s.img.complete && s.img.naturalWidth > 0; }
function whiteSheet(s) {
    if (!s.white && sprReady(s)) {
        const c = document.createElement('canvas');
        c.width = s.img.naturalWidth; c.height = s.img.naturalHeight;
        const g = c.getContext('2d');
        g.drawImage(s.img, 0, 0);
        g.globalCompositeOperation = 'source-atop';
        g.fillStyle = '#fff6e0';
        g.fillRect(0, 0, c.width, c.height);
        s.white = c;
    }
    return s.white;
}
// Rysuje klatkę tak, by stopy postaci stały w punkcie (sx, sy)
function drawSpriteFrame(key, col, row, sx, sy, scale, flip, alpha = 1, white = false) {
    const s = SPR[key];
    if (!sprReady(s)) return false;
    const src = white ? whiteSheet(s) : s.img;
    if (!src) return false;
    const dw = s.fw * scale, dh = s.fh * scale;
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.imageSmoothingEnabled = false;
    ctx.translate(Math.round(sx), Math.round(sy));
    if (flip) ctx.scale(-1, 1);
    ctx.drawImage(src, col * s.fw, row * s.fh, s.fw, s.fh, -dw / 2, -dh * 0.93, dw, dh);
    ctx.restore();
    return true;
}
// Kierunek ekranowy z kąta w świecie izometrycznym
function screenFacing(angle) {
    const c = Math.cos(angle), s = Math.sin(angle);
    const sdx = c - s, sdy = (c + s) * 0.5;
    if (Math.abs(sdx) > Math.abs(sdy) * 1.6) return { dir: 1, sdx };
    return { dir: sdy >= 0 ? 0 : 2, sdx };
}
