// ==================== 16. ISOMETRIC RENDERING & DYNAMIC LIGHTING ====================
function drawCharacter(x, y, angle, walkFrame, opts) {
    const sc = worldToScreen(x, y, raid.camX, raid.camY);
    const sx = Math.round(sc.x), sy = Math.round(sc.y);
    const bob = Math.sin(walkFrame * 2) * 1.8;
    const breathe = Math.sin(raid.elapsed * 3.2) * 0.8;
    const scale = opts.isBoss ? 1.38 : 1.0;

    ctx.save();
    ctx.translate(sx, sy);
    ctx.scale(scale, scale);

    // Ground shadow
    ctx.fillStyle = 'rgba(0,0,0,0.52)';
    ctx.beginPath();
    ctx.ellipse(0, 2, 11, 5.5, 0, 0, Math.PI * 2);
    ctx.fill();

    // Legs
    const legOff = Math.sin(walkFrame * 2) * 3;
    ctx.fillStyle = '#1b181f';
    ctx.fillRect(-5, -8 + legOff * 0.5, 4, 9);
    ctx.fillRect(1, -8 - legOff * 0.5, 4, 9);

    // Cloak / Cape
    ctx.fillStyle = opts.cloak || '#47181f';
    ctx.fillRect(-7, -21 + bob, 14, 13);

    // Armor Torso
    ctx.fillStyle = opts.hitFlash ? '#ffffff' : opts.body;
    ctx.fillRect(-6, -22 + bob + breathe, 12, 13);
    ctx.fillStyle = opts.trim || '#c79c4c';
    ctx.fillRect(-6, -13 + bob + breathe, 12, 2);

    // Helmet / Head
    ctx.fillStyle = opts.hitFlash ? '#ffffff' : (opts.helm || '#5c626b');
    ctx.fillRect(-5, -31 + bob + breathe, 10, 9);
    // Visor slit
    const faceDir = Math.cos(angle) >= 0 ? 1 : -1;
    ctx.fillStyle = opts.eyeGlow || '#120f15';
    ctx.fillRect(faceDir > 0 ? -1 : -4, -27 + bob + breathe, 5, 2);

    // Shield (if equipped / blocking)
    if (opts.hasShield) {
        const shX = opts.blocking ? (faceDir * 7) : (-faceDir * 7);
        ctx.fillStyle = opts.parryWindow ? '#ffd166' : (opts.shieldCol || '#6e4a2e');
        ctx.fillRect(shX - 3, -21 + bob, 6, 11);
        ctx.fillStyle = '#c79c4c';
        ctx.fillRect(shX - 2, -17 + bob, 4, 2);
    }

    // Weapon
    const wDirX = Math.cos(angle) * 13;
    const wDirY = Math.sin(angle) * 7;
    ctx.strokeStyle = opts.weaponCol || '#cfd8e3';
    ctx.lineWidth = opts.isBoss ? 3.5 : 2.5;
    ctx.beginPath();
    ctx.moveTo(faceDir * 4, -17 + bob);
    ctx.lineTo(faceDir * 4 + wDirX, -17 + bob + wDirY);
    ctx.stroke();

    // Player Sword Swing Arc
    if (opts.swingProgress > 0) {
        ctx.save();
        ctx.translate(0, -14);
        ctx.scale(1, 0.55);
        const startA = angle - 1.1;
        const endA = angle + 1.1;
        ctx.strokeStyle = opts.isHeavy ? 'rgba(230, 122, 56, 0.85)' : 'rgba(235, 228, 215, 0.72)';
        ctx.lineWidth = opts.isHeavy ? 6 : 4;
        ctx.beginPath();
        ctx.arc(0, 0, 26, startA, endA);
        ctx.stroke();
        ctx.restore();
    }

    // Enemy Telegraph GOLDEN GLINT (Parry Cue!)
    if (opts.telegraph > 0) {
        const pulse = 0.55 + Math.sin(raid.elapsed * 30) * 0.45;
        ctx.fillStyle = `rgba(255, 215, 80, ${pulse})`;
        ctx.beginPath();
        ctx.arc(faceDir * 6 + wDirX * 0.6, -24 + bob, 7 + pulse * 4, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#fff9db';
        ctx.fillRect(faceDir * 6 + wDirX * 0.6 - 7, -25 + bob, 14, 2);
        ctx.fillRect(faceDir * 6 + wDirX * 0.6 - 1, -31 + bob, 2, 14);
    }

    // Staggered (Parried) Indicator!
    if (opts.staggered) {
        ctx.fillStyle = '#ffd166';
        ctx.font = 'bold 10px JetBrains Mono';
        ctx.textAlign = 'center';
        ctx.fillText('★ RIPOSTA! ★', 0, -40);
    }

    ctx.restore();

    // Enemy HP bar
    if (opts.hpPct !== undefined && opts.hpPct < 1) {
        const bw = opts.isBoss ? 52 : 28;
        ctx.fillStyle = 'rgba(10,8,12,0.85)';
        ctx.fillRect(sx - bw / 2, sy - (opts.isBoss ? 54 : 38), bw, 4);
        ctx.fillStyle = opts.isBoss ? '#e06324' : '#c92a35';
        ctx.fillRect(sx - bw / 2, sy - (opts.isBoss ? 54 : 38), Math.round(bw * opts.hpPct), 4);
    }
}

const POST_GLINTS = [];
function drawPostGlints() {
    const pulse = 0.55 + Math.sin(raid.elapsed * 30) * 0.45;
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    for (const g of POST_GLINTS) {
        // złoty = paruj [PPM], czerwony = ciężki cios, tylko unik [Spacja]
        ctx.fillStyle = g.heavy ? `rgba(255, 60, 40, ${pulse})` : `rgba(255, 215, 80, ${pulse})`;
        ctx.beginPath(); ctx.arc(g.x, g.y, 7 + pulse * 5, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = g.heavy ? '#ffd0c8' : '#fff9db';
        ctx.fillRect(g.x - 10, g.y - 1, 20, 2);
        ctx.fillRect(g.x - 1, g.y - 10, 2, 20);
    }
    ctx.restore();
    POST_GLINTS.length = 0;
}

// Płomień pochodni (rysowany przed warstwą światła, więc oświetla go własny blask)
function drawFlame(x, y, s = 1) {
    const t = raid.elapsed;
    const h = (9 + Math.sin(t * 17) * 2 + Math.cos(t * 29)) * s;
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = 'rgba(224, 83, 26, 0.9)';
    ctx.beginPath(); ctx.ellipse(Math.round(x), Math.round(y), 4 * s, h * 0.6, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = 'rgba(255, 209, 102, 0.95)';
    ctx.beginPath(); ctx.ellipse(Math.round(x), Math.round(y + 1), 2.2 * s, h * 0.35, 0, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
}

function drawShadow(sx, sy, rx, ry) {
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.beginPath();
    ctx.ellipse(Math.round(sx), Math.round(sy), rx, ry, 0, 0, Math.PI * 2);
    ctx.fill();
}

function drawPlayerSprite(p, camX, camY) {
    // Powidoki uniku
    for (const gh of raid.ghosts) {
        const gs = worldToScreen(gh.x, gh.y, camX, camY);
        if (!drawSpriteFrame('knight_d', gh.col, gh.row, gs.x, gs.y, 0.82, gh.flip, gh.life * 1.6, true)) {
            ctx.fillStyle = `rgba(210, 200, 225, ${gh.life * 1.4})`;
            ctx.fillRect(Math.round(gs.x - 6), Math.round(gs.y - 24), 12, 22);
        }
    }
    const sc = worldToScreen(p.x, p.y, camX, camY);
    drawShadow(sc.x, sc.y + 1, 15, 7);

    let key = 'knight_d', col = 0, row = 0, flip = false;
    if (p.dead) {
        const f = Math.min(7, Math.floor(raid.deathAnim * 6));
        key = 'knight_death'; col = f % 4; row = Math.floor(f / 4);
        flip = screenFacing(p.angle).sdx < 0;
    } else if (p.swingAnim > 0) {
        const f = screenFacing(p.attackAngle);
        const t = 1 - p.swingAnim / p.swingAnimMax;
        key = 'knight_dc'; col = Math.min(3, Math.floor(t * 4));
        const heavy = p.comboStep === 2;
        if (f.dir === 0) row = heavy ? 4 : 3;
        else if (f.dir === 2) row = heavy ? 2 : (p.comboStep === 1 ? 1 : 0);
        else { row = 5; flip = f.sdx < 0; }
    } else if (p.blocking) {
        const f = screenFacing(p.angle);
        key = 'knight_def'; row = f.dir; col = p.parryWindow > 0 ? 1 : 0;
        flip = f.dir === 1 && f.sdx < 0;
    } else {
        const f = screenFacing(p.angle);
        flip = f.dir === 1 && f.sdx < 0;
        if (p.moving) { row = 3 + f.dir; col = Math.floor(p.walkFrame) % 4; }
        else { row = f.dir; col = Math.floor(raid.elapsed * 4) % 4; }
    }
    const drawn = drawSpriteFrame(key, col, row, sc.x, sc.y + 2, 0.82, flip);
    if (!drawn) {
        drawCharacter(p.x, p.y, p.angle, p.walkFrame, {
            body: '#4d3d35', helm: '#574e47', cloak: '#6b1d24',
            hasShield: !!p.loadout.shield, blocking: p.blocking, parryWindow: p.parryWindow > 0,
            swingProgress: p.attackDur > 0 ? p.attackTimer / p.attackDur : 0, isHeavy: p.comboStep === 2
        });
    }
    // Pochodnia w ręce tarczy
    if (p.torchInHand && !p.dead) {
        const hand = flip ? 13 : -13;
        ctx.strokeStyle = '#3a2618'; ctx.lineWidth = 3;
        ctx.beginPath(); ctx.moveTo(Math.round(sc.x + hand), Math.round(sc.y - 30)); ctx.lineTo(Math.round(sc.x + hand * 1.2), Math.round(sc.y - 50)); ctx.stroke();
        drawFlame(sc.x + hand * 1.2, sc.y - 58, 1.5);
        if (Math.random() < 0.3) spawnParticles(p.x - 0.05, p.y - 0.05, 1, '#ffb347', 0.6, 0.4);
    }
    // Złota aura okna parowania
    if (p.parryWindow > 0 && !p.dead) {
        ctx.save();
        ctx.globalCompositeOperation = 'lighter';
        ctx.strokeStyle = `rgba(255, 210, 110, ${0.35 + p.parryWindow})`;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.ellipse(Math.round(sc.x), Math.round(sc.y), 22, 11, 0, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
    }
    // Łuk cięcia (czytelność ciosu)
    if (p.attackTimer > 0 && !p.dead) {
        ctx.save();
        ctx.translate(Math.round(sc.x), Math.round(sc.y - 30));
        ctx.scale(1, 0.55);
        const sa = Math.atan2((Math.cos(p.attackAngle) + Math.sin(p.attackAngle)) * 0.5 * 2, Math.cos(p.attackAngle) - Math.sin(p.attackAngle));
        ctx.strokeStyle = p.comboStep === 2 ? 'rgba(230, 122, 56, 0.8)' : 'rgba(235, 228, 215, 0.55)';
        ctx.lineWidth = p.comboStep === 2 ? 5 : 3;
        ctx.beginPath();
        ctx.arc(0, 0, 44, sa - 1.0, sa + 1.0);
        ctx.stroke();
        ctx.restore();
    }
}

function drawEnemySprite(en, camX, camY) {
    const sc = worldToScreen(en.x, en.y, camX, camY);
    const key = 'en_' + en.kind;
    const scale = en.isBoss ? 0.95 : (en.kind === 'brute' ? 0.9 : 0.8);
    drawShadow(sc.x, sc.y + 1, en.isBoss ? 30 : 15, en.isBoss ? 13 : 7);

    const nowMs = performance.now();
    if (en.walkFrame !== en._lw) { en._lw = en.walkFrame; en._mvT = nowMs; }
    const moving = nowMs - (en._mvT || 0) < 150;

    let col = 0, row = 0;
    if (en.windupTimer > 0) { row = 1; col = 0; }
    else if (en.atkSwingVisual > 0) { row = 1; col = en.atkSwingVisual > 0.11 ? 1 : 2; }
    else if (moving) { row = 0; col = Math.floor(en.walkFrame) % 4; }
    const f = screenFacing(en.angle);
    const wob = en.staggerTimer > 0 ? Math.sin(raid.elapsed * 40) * 2 : 0;
    const drawn = drawSpriteFrame(key, col, row, sc.x + wob, sc.y + 2, scale, f.sdx < 0, 1, en.hitFlash > 0);

    const topY = sc.y - (en.isBoss ? 152 : 92);
    if (!drawn) {
        drawCharacter(en.x, en.y, en.angle, en.walkFrame, {
            body: '#4a433d', helm: '#383330', cloak: '#2c292b', isBoss: en.isBoss,
            hitFlash: en.hitFlash > 0, telegraph: 0, staggered: false, swingProgress: 0, hpPct: 1
        });
    }
    // Błysk zapowiedzi ataku (rysowany po oświetleniu, żeby był widoczny w mroku)
    if (en.windupTimer > 0) {
        POST_GLINTS.push({
            x: sc.x + (f.sdx < 0 ? -14 : 14) * (en.isBoss ? 1.6 : 1),
            y: sc.y - (en.isBoss ? 110 : 62),
            heavy: en.heavy
        });
    }
    if (en.staggerTimer > 0) {
        ctx.fillStyle = '#ffd166';
        ctx.font = 'bold 10px JetBrains Mono';
        ctx.textAlign = 'center';
        ctx.fillText('★ RIPOSTA! ★', Math.round(sc.x), Math.round(topY - 6));
    }
    if (en.hp < en.maxHp) {
        const bw = en.isBoss ? 70 : 30;
        ctx.fillStyle = 'rgba(10,8,12,0.85)';
        ctx.fillRect(Math.round(sc.x - bw / 2), Math.round(topY), bw, 4);
        ctx.fillStyle = en.isBoss ? '#e06324' : '#c92a35';
        ctx.fillRect(Math.round(sc.x - bw / 2), Math.round(topY), Math.round(bw * Math.max(0, en.hp / en.maxHp)), 4);
    }
    // Pasek postury (żółty): po wyzerowaniu wróg traci równowagę
    if (en.poise < en.maxPoise && en.staggerTimer <= 0) {
        const bw = en.isBoss ? 70 : 30;
        ctx.fillStyle = 'rgba(10,8,12,0.85)';
        ctx.fillRect(Math.round(sc.x - bw / 2), Math.round(topY + 5), bw, 2);
        ctx.fillStyle = '#f2c14e';
        ctx.fillRect(Math.round(sc.x - bw / 2), Math.round(topY + 5), Math.round(bw * Math.max(0, en.poise / en.maxPoise)), 2);
    }
    if (en.isBoss) {
        ctx.fillStyle = '#f0b96e';
        ctx.font = 'bold 11px Cinzel, serif';
        ctx.textAlign = 'center';
        ctx.fillText('POPIELNY STRAŻNIK', Math.round(sc.x), Math.round(topY - 8));
    }
}

function renderLighting() {
    const lw = lightCanvas.width, lh = lightCanvas.height;
    const p = raid.player;
    lightCtx.save();
    lightCtx.globalCompositeOperation = 'source-over';
    // Grim dark-fantasy darkness veil
    lightCtx.fillStyle = raid.zone.id === 'crypt' ? 'rgb(20, 16, 22)' : 'rgb(28, 25, 32)';
    lightCtx.fillRect(0, 0, lw, lh);

    lightCtx.globalCompositeOperation = 'lighter';

    const addGlow = (wx, wy, rad, colInner, colMid) => {
        const sc = worldToScreen(wx, wy, raid.camX, raid.camY);
        const lx = sc.x / 2, ly = sc.y / 2;
        const r = rad / 2;
        if (lx < -r || ly < -r || lx > lw + r || ly > lh + r) return;
        const grad = lightCtx.createRadialGradient(lx, ly, r * 0.08, lx, ly, r);
        grad.addColorStop(0, colInner);
        grad.addColorStop(0.55, colMid);
        grad.addColorStop(1, 'rgba(0,0,0,0)');
        lightCtx.fillStyle = grad;
        lightCtx.fillRect(lx - r, ly - r, r * 2, r * 2);
    };

    // Player warm flickering torch
    const flick = Math.sin(raid.elapsed * 14) * 8 + Math.cos(raid.elapsed * 23) * 4;
    if (p.torchInHand) {
        addGlow(p.x, p.y - 0.2, 270 + flick, 'rgba(255, 205, 138, 0.96)', 'rgba(220, 130, 62, 0.45)');
        // Directional torch beam toward cursor
        addGlow(p.x + Math.cos(p.angle) * 2.2, p.y + Math.sin(p.angle) * 2.2, 185 + flick * 0.5, 'rgba(255, 215, 155, 0.55)', 'rgba(190, 115, 55, 0.18)');
    } else {
        // Bez pochodni: tylko słaba poświata wokół rycerza
        addGlow(p.x, p.y - 0.2, 105, 'rgba(150, 140, 175, 0.55)', 'rgba(70, 60, 90, 0.2)');
    }
    // Pochodnia rzucona na ziemię oświetla krąg areny
    if (raid.groundTorch) {
        const gt = raid.groundTorch;
        addGlow(gt.x, gt.y, 300 + flick, 'rgba(255, 200, 130, 0.95)', 'rgba(215, 125, 55, 0.42)');
    }

    // Iron Braziers
    for (const br of raid.map.braziers) {
        const bf = Math.sin(raid.elapsed * 11 + br.x * 3) * 10;
        addGlow(br.x, br.y, 195 + bf, 'rgba(255, 160, 70, 0.85)', 'rgba(185, 75, 25, 0.30)');
    }

    // Runic Extraction Circles
    for (const ex of raid.map.extracts) {
        const ef = Math.sin(raid.elapsed * 4) * 14;
        addGlow(ex.x, ex.y, 210 + ef, 'rgba(70, 235, 175, 0.82)', 'rgba(30, 140, 110, 0.28)');
    }

    // Combat Flashes (Parry / Riposte)
    for (const fl of raid.flashes) {
        const a = fl.life / fl.maxLife;
        addGlow(fl.x, fl.y, fl.radius * a, fl.color, 'rgba(220, 160, 50, 0.25)');
    }

    lightCtx.restore();

    ctx.save();
    ctx.globalCompositeOperation = 'multiply';
    ctx.drawImage(lightCanvas, 0, 0, canvas.width, canvas.height);
    ctx.restore();
}

function renderRaid() {
    const shakeX = raid.shake > 0 ? (Math.random() - 0.5) * raid.shake : 0;
    const shakeY = raid.shake > 0 ? (Math.random() - 0.5) * raid.shake : 0;
    const camX = raid.camX + shakeX, camY = raid.camY + shakeY;

    ctx.fillStyle = '#070609';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    const p = raid.player;
    const grid = raid.map.grid;
    const vis = raid.visMap;

    // 1. Ground Floor Pass
    for (let ty = 0; ty < MAP_SIZE; ty++) {
        for (let tx = 0; tx < MAP_SIZE; tx++) {
            const i = ty * MAP_SIZE + tx;
            const v = vis[i];
            if (v === 0) continue;
            const sc = worldToScreen(tx, ty, camX, camY);
            if (sc.x < -TILE_W || sc.x > canvas.width + TILE_W || sc.y < -TILE_H * 2 || sc.y > canvas.height + TILE_H * 2) continue;

            const t = grid[i];
            let spr = ATLAS.sprites['floor_' + raid.map.variant[i]];
            if (t === TILE.PATH) spr = ATLAS.sprites['path'];
            else if (t === TILE.EXTRACT) spr = ATLAS.sprites['extract'];

            ctx.globalAlpha = v === 2 ? 1.0 : 0.34;
            ctx.drawImage(spr, Math.round(sc.x - TILE_W / 2), Math.round(sc.y), TILE_W, TILE_H);
        }
    }
    ctx.globalAlpha = 1;

    // 2. Depth-Sorted Render Queue (Walls, Props, Loot, Corpses, Characters)
    const drawList = [];

    for (let ty = 0; ty < MAP_SIZE; ty++) {
        for (let tx = 0; tx < MAP_SIZE; tx++) {
            const i = ty * MAP_SIZE + tx;
            const v = vis[i];
            if (v === 0) continue;
            const t = grid[i];
            if (t === TILE.WALL || t === TILE.PILLAR || t === TILE.BRAZIER || t === TILE.RUBBLE) {
                const sc = worldToScreen(tx, ty, camX, camY);
                if (sc.x < -TILE_W || sc.x > canvas.width + TILE_W || sc.y < -90 || sc.y > canvas.height + 90) continue;
                drawList.push({ depth: tx + ty + 0.5, type: 'tile', tx, ty, t, v });
            }
        }
    }

    for (const lb of raid.map.lootBoxes) {
        const v = vis[lb.ty * MAP_SIZE + lb.tx];
        if (v > 0) drawList.push({ depth: lb.x + lb.y, type: 'loot', obj: lb, v });
    }
    for (const cp of raid.corpses) {
        const v = vis[Math.floor(cp.y) * MAP_SIZE + Math.floor(cp.x)];
        if (v > 0) drawList.push({ depth: cp.x + cp.y, type: 'corpse', obj: cp, v });
    }
    for (const en of raid.enemies) {
        const v = vis[Math.floor(en.y) * MAP_SIZE + Math.floor(en.x)];
        if (v === 2) drawList.push({ depth: en.x + en.y, type: 'enemy', obj: en });
    }
    if (raid.groundTorch) drawList.push({ depth: raid.groundTorch.x + raid.groundTorch.y, type: 'torch' });
    drawList.push({ depth: p.x + p.y, type: 'player' });

    drawList.sort((a, b) => a.depth - b.depth);

    for (const item of drawList) {
        if (item.type === 'tile') {
            const sc = worldToScreen(item.tx, item.ty, camX, camY);
            let alpha = item.v === 2 ? 1.0 : 0.34;
            // Auto-transparency when player walks behind tall wall/pillar
            if ((item.t === TILE.WALL || item.t === TILE.PILLAR) &&
                item.tx + item.ty > p.x + p.y &&
                Math.abs(item.tx - p.x) < 2.1 && Math.abs(item.ty - p.y) < 2.1) {
                alpha = Math.min(alpha, 0.35);
            }
            ctx.globalAlpha = alpha;
            if (item.t === TILE.WALL) ctx.drawImage(ATLAS.sprites['wall'], Math.round(sc.x - 32), Math.round(sc.y - 40), 64, 72);
            else if (item.t === TILE.PILLAR) ctx.drawImage(ATLAS.sprites['pillar'], Math.round(sc.x - 32), Math.round(sc.y - 40), 64, 72);
            else if (item.t === TILE.BRAZIER) ctx.drawImage(ATLAS.sprites['brazier'], Math.round(sc.x - 32), Math.round(sc.y - 24), 64, 56);
            else if (item.t === TILE.RUBBLE) ctx.drawImage(ATLAS.sprites['rubble'], Math.round(sc.x - 32), Math.round(sc.y - 16), 64, 48);
            ctx.globalAlpha = 1;
        } else if (item.type === 'loot') {
            const sc = worldToScreen(item.obj.x - 0.5, item.obj.y - 0.5, camX, camY);
            ctx.globalAlpha = item.v === 2 ? 1.0 : 0.4;
            ctx.drawImage(ATLAS.sprites[item.obj.kind], Math.round(sc.x - 32), Math.round(sc.y - 16), 64, 48);
            if (item.obj.items.length > 0 && item.v === 2) {
                ctx.fillStyle = '#e6ba63';
                ctx.fillRect(Math.round(sc.x - 2), Math.round(sc.y - 10 + Math.sin(raid.elapsed * 5) * 2), 4, 4);
            }
            ctx.globalAlpha = 1;
        } else if (item.type === 'torch') {
            const gt = raid.groundTorch;
            const sc = worldToScreen(gt.x, gt.y, camX, camY);
            drawFlame(sc.x + 5, sc.y - 12, 1.1);
            ctx.strokeStyle = '#4a3222'; ctx.lineWidth = 3;
            ctx.beginPath(); ctx.moveTo(Math.round(sc.x - 7), Math.round(sc.y + 2)); ctx.lineTo(Math.round(sc.x + 5), Math.round(sc.y - 8)); ctx.stroke();
        } else if (item.type === 'corpse' && item.obj.isBag) {
            const cp = item.obj;
            const sc = worldToScreen(cp.x, cp.y, camX, camY);
            ctx.globalAlpha = item.v === 2 ? 1 : 0.45;
            drawShadow(sc.x, sc.y + 2, 11, 5);
            ctx.fillStyle = '#5a3d24'; ctx.fillRect(Math.round(sc.x - 9), Math.round(sc.y - 14), 18, 15);
            ctx.fillStyle = '#7a5532'; ctx.fillRect(Math.round(sc.x - 7), Math.round(sc.y - 18), 14, 6);
            ctx.fillStyle = '#c79c4c'; ctx.fillRect(Math.round(sc.x - 9), Math.round(sc.y - 9), 18, 2);
            ctx.globalAlpha = 1;
            if (cp.items.length > 0 && item.v === 2) {
                ctx.fillStyle = '#e6ba63';
                ctx.fillRect(Math.round(sc.x - 2), Math.round(sc.y - 28 + Math.sin(raid.elapsed * 5) * 2), 4, 4);
            }
        } else if (item.type === 'corpse') {
            const cp = item.obj;
            const sc = worldToScreen(cp.x, cp.y, camX, camY);
            const key = 'en_' + cp.kind;
            const ok = SPR[key] && drawSpriteFrame(key, 3, 1, sc.x, sc.y + 4, cp.isBoss ? 0.9 : 0.78,
                screenFacing(cp.angle || 0).sdx < 0, item.v === 2 ? 0.92 : 0.4);
            if (!ok) {
                ctx.globalAlpha = item.v === 2 ? 1.0 : 0.4;
                ctx.drawImage(ATLAS.sprites['loot_knight'], Math.round(sc.x - 32), Math.round(sc.y - 24), 64, 48);
                ctx.globalAlpha = 1;
            }
            if (cp.items.length > 0 && item.v === 2) {
                ctx.fillStyle = '#e6ba63';
                ctx.fillRect(Math.round(sc.x - 2), Math.round(sc.y - 30 + Math.sin(raid.elapsed * 5) * 2), 4, 4);
            }
        } else if (item.type === 'player') {
            drawPlayerSprite(p, camX, camY);
        } else if (item.type === 'enemy') {
            drawEnemySprite(item.obj, camX, camY);
        }
    }

    // 3. Flying Arrows
    for (const a of raid.arrows) {
        const sc = worldToScreen(a.x, a.y, camX, camY);
        const ang = Math.atan2((a.vx + a.vy) * 0.5, a.vx - a.vy);
        ctx.save();
        ctx.translate(sc.x, sc.y - 14);
        ctx.rotate(ang);
        ctx.strokeStyle = a.fromPlayer ? '#e6ba63' : '#f87171';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(-7, 0); ctx.lineTo(7, 0); ctx.stroke();
        ctx.restore();
    }

    // 4. Particles
    for (const pt of raid.particles) {
        const sc = worldToScreen(pt.x, pt.y, camX, camY);
        ctx.globalAlpha = Math.max(0, pt.life / pt.maxLife);
        ctx.fillStyle = pt.color;
        ctx.fillRect(Math.round(sc.x), Math.round(sc.y - pt.z * 26), pt.size, pt.size);
    }
    ctx.globalAlpha = 1;

    // 5. Dynamic Lighting Pass
    renderLighting();
    drawPostGlints();

    // 6. Floating Damage / Parry Texts (drawn bright over lighting)
    ctx.textAlign = 'center';
    for (const ft of raid.floatTexts) {
        const sc = worldToScreen(ft.x, ft.y, camX, camY);
        ctx.globalAlpha = Math.min(1, ft.life * 1.4);
        ctx.font = `bold ${ft.size}px JetBrains Mono`;
        ctx.fillStyle = '#000';
        ctx.fillText(ft.text, Math.round(sc.x) + 1, Math.round(sc.y - 26) + 1);
        ctx.fillStyle = ft.color;
        ctx.fillText(ft.text, Math.round(sc.x), Math.round(sc.y - 26));
    }
    ctx.globalAlpha = 1;

    // 7. Gentle Falling Ash
    ctx.fillStyle = 'rgba(220, 208, 195, 0.35)';
    for (const af of raid.ashFlakes) {
        ctx.fillRect(Math.round(af.x), Math.round(af.y), af.size, af.size);
    }

    // 8. Minimap
    renderMinimap();
}

function renderMinimap() {
    const s = miniCanvas.width / MAP_SIZE;
    miniCtx.fillStyle = '#08070a';
    miniCtx.fillRect(0, 0, miniCanvas.width, miniCanvas.height);

    const grid = raid.map.grid;
    const vis = raid.visMap;
    for (let y = 0; y < MAP_SIZE; y++) {
        for (let x = 0; x < MAP_SIZE; x++) {
            const v = vis[y * MAP_SIZE + x];
            if (v === 0) continue;
            const t = grid[y * MAP_SIZE + x];
            if (t === TILE.WALL || t === TILE.PILLAR) miniCtx.fillStyle = v === 2 ? '#594e5c' : '#2c262e';
            else if (t === TILE.EXTRACT) miniCtx.fillStyle = '#34d399';
            else miniCtx.fillStyle = v === 2 ? '#29242c' : '#161318';
            miniCtx.fillRect(x * s, y * s, Math.ceil(s), Math.ceil(s));
        }
    }
    // Extraction markers always visible on minimap
    for (const ex of raid.map.extracts) {
        miniCtx.fillStyle = '#34d399';
        miniCtx.fillRect(ex.x * s - 2, ex.y * s - 2, 5, 5);
    }
    // Visible enemies
    for (const en of raid.enemies) {
        if (vis[Math.floor(en.y) * MAP_SIZE + Math.floor(en.x)] === 2) {
            miniCtx.fillStyle = en.isBoss ? '#f97316' : '#ef4444';
            miniCtx.fillRect(en.x * s - 1.5, en.y * s - 1.5, en.isBoss ? 4 : 3, en.isBoss ? 4 : 3);
        }
    }
    // Player dot
    miniCtx.fillStyle = '#e6ba63';
    miniCtx.fillRect(raid.player.x * s - 2, raid.player.y * s - 2, 4, 4);
}

function updateRaidHUD() {
    if (!raid) return;
    const p = raid.player;
    const mins = Math.floor(raid.timeLeft / 60);
    const secs = Math.floor(raid.timeLeft % 60).toString().padStart(2, '0');
    document.getElementById('hud-timer').textContent = `${mins}:${secs}`;
    document.getElementById('hud-kills').textContent = raid.kills;
    document.getElementById('hud-parries').textContent = raid.parries;

    document.getElementById('hud-hp-text').textContent = `${Math.ceil(p.hp)} / ${p.maxHp}`;
    document.getElementById('hud-hp-bar').style.width = `${(p.hp / p.maxHp) * 100}%`;
    document.getElementById('hud-stam-text').textContent = `${Math.ceil(p.stamina)} / ${p.maxStamina}`;
    document.getElementById('hud-stam-bar').style.width = `${(p.stamina / p.maxStamina) * 100}%`;

    document.getElementById('hud-burn-badge').classList.toggle('hidden', !p.burning);
    document.getElementById('burn-overlay').classList.toggle('hidden', !p.burning);

    if (p.loadout.armor) {
        const ad = ITEMS_DB[p.loadout.armor.id];
        document.getElementById('hud-armor-cls').textContent = `(Kl.${ad.tier})`;
        document.getElementById('hud-armor-text').textContent = `${Math.ceil(p.loadout.armor.durability)} / ${ad.maxDurability}`;
        document.getElementById('hud-armor-bar').style.width = `${(p.loadout.armor.durability / ad.maxDurability) * 100}%`;
    } else {
        document.getElementById('hud-armor-cls').textContent = '';
        document.getElementById('hud-armor-text').textContent = '0 / 0';
        document.getElementById('hud-armor-bar').style.width = '0%';
    }

    const allInv = [...p.loadout.backpack, ...p.loadout.reliquary];
    document.getElementById('hud-elix-1').textContent = allInv.filter(i => ITEMS_DB[i.id].elixKind === 'heal').length;
    document.getElementById('hud-elix-2').textContent = allInv.filter(i => ITEMS_DB[i.id].elixKind === 'stamina').length;
    document.getElementById('hud-elix-3').textContent = allInv.filter(i => ITEMS_DB[i.id].elixKind === 'salve').length;

    document.getElementById('hud-weapon-name').textContent = p.loadout.weapon ? ITEMS_DB[p.loadout.weapon.id].name : 'Gołe Pięści';
    document.getElementById('hud-shield-name').textContent = p.torchInHand ? '🔥 Pochodnia [F]' : (p.loadout.shield ? ITEMS_DB[p.loadout.shield.id].name : 'Brak');
    document.getElementById('hud-arrows').textContent = countRaidArrows();
    const load = backpackLoad();
    document.getElementById('hud-bp-slots').textContent = `${p.loadout.backpack.length}/12` + (load > 0 ? ` (−${Math.round(Math.min(45, load * 3.5))}% st.)` : '');

    const stance = p.parryWindow > 0 ? 'PAROWANIE!' : (p.blocking ? 'BLOK' : (p.dodgeTimer > 0 ? 'UNIK' : 'GOTOWY'));
    const sb = document.getElementById('hud-stance-badge');
    sb.textContent = stance;
    sb.className = `text-[10px] px-1.5 py-0.5 rounded font-bold ${p.parryWindow > 0 ? 'bg-amber-600 text-white' : (p.blocking ? 'bg-sky-800 text-sky-200' : 'bg-stone-800 text-stone-300')}`;

    // Extraction Banner
    const eb = document.getElementById('hud-extract-banner');
    eb.classList.toggle('hidden', !raid.extracting);
    if (raid.extracting) {
        document.getElementById('hud-extract-timer').textContent = raid.extractTimer.toFixed(1) + ' s';
        document.getElementById('hud-extract-bar').style.width = `${((6.0 - raid.extractTimer) / 6.0) * 100}%`;
    }

    // Compass directions to Extraction Circles
    const dirsHtml = raid.map.extracts.map(ex => {
        const d = Math.round(Math.hypot(ex.x - p.x, ex.y - p.y));
        return `<div class="truncate">✦ ${ex.name}: <b>${d}m</b></div>`;
    }).join('');
    document.getElementById('hud-extract-dirs').innerHTML = dirsHtml;

    // Interact prompt
    const near = !raid.modalOpen ? findNearestInteractable() : null;
    const pr = document.getElementById('hud-interact-prompt');
    const gt = raid.groundTorch;
    if (near) {
        pr.textContent = `[E] Przeszukaj: ${near.name}`;
        pr.classList.remove('hidden');
    } else if (!raid.modalOpen && gt && !p.torchInHand && Math.hypot(gt.x - p.x, gt.y - p.y) < 1.6) {
        pr.textContent = '[F] Podnieś pochodnię';
        pr.classList.remove('hidden');
    } else {
        pr.classList.add('hidden');
    }
}

function raidLoop(now) {
    if (!raid) return;
    const dt = Math.min(0.05, (now - raid.lastTime) / 1000);
    raid.lastTime = now;
    if (raid.ended) {
        // Krótka animacja śmierci przed planszą wyniku
        if (now < raid.endAt) {
            raid.deathAnim += dt;
            raid.elapsed += dt;
            renderRaid();
            requestAnimationFrame(raidLoop);
        }
        return;
    }
    updateRaid(dt);
    renderRaid();
    updateRaidHUD();
    requestAnimationFrame(raidLoop);
}
