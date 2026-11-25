// ==================== 15. MAIN UPDATE LOOP ====================
function updateRaid(dt) {
    if (raid.hitstop > 0) {
        raid.hitstop -= dt;
        return;
    }
    const p = raid.player;
    raid.elapsed += dt;
    raid.timeLeft = Math.max(0, raid.timeLeft - dt);
    if (raid.timeLeft <= 0) return endRaid(false, 'Ciemność pochłonęła ruiny — czas wyprawy minął.');

    // Progressive container search
    if (raid.modalOpen && raid.activeLoot) {
        const nextIdx = raid.activeLoot.items.findIndex(e => !e.revealed);
        if (nextIdx !== -1) {
            const searchSpeed = 0.52 / (1 + (profile.skills.scavenger.lv - 1) * 0.15);
            raid.searchProg += dt / searchSpeed;
            document.getElementById('rm-search-bar').style.width = Math.min(100, raid.searchProg * 100) + '%';
            if (raid.searchProg >= 1) {
                raid.activeLoot.items[nextIdx].revealed = true;
                raid.searchProg = 0;
                SFX.loot();
                renderRaidModal();
            }
        }
    }

    // Cooldowns
    p.attackTimer = Math.max(0, p.attackTimer - dt);
    p.attackCd = Math.max(0, p.attackCd - dt);
    p.comboReset = Math.max(0, p.comboReset - dt);
    p.parryWindow = Math.max(0, p.parryWindow - dt);
    p.parryCd = Math.max(0, p.parryCd - dt);
    p.dodgeCd = Math.max(0, p.dodgeCd - dt);
    p.bowCd = Math.max(0, p.bowCd - dt);
    p.stamRegenBoost = Math.max(0, p.stamRegenBoost - dt);
    p.swingAnim = Math.max(0, p.swingAnim - dt);
    p.moving = false;

    // Stamina regeneration
    const stamBase = 24 * (1 + (profile.skills.endurance.lv - 1) * 0.08) * (p.stamRegenBoost > 0 ? 1.65 : 1.0);
    const stamMult = p.blocking ? 0.35 : (p.attackTimer > 0 ? 0.2 : 1.0);
    p.stamina = Math.min(p.maxStamina, p.stamina + stamBase * stamMult * dt);

    // Player Movement & Dodge Roll
    if (!raid.modalOpen) {
        if (p.dodgeTimer > 0) {
            p.dodgeTimer -= dt;
            moveEntity(p, p.dodgeDx * 7.6 * dt, p.dodgeDy * 7.6 * dt);
            p.moving = true;
            p.walkFrame += dt * 14;
            if (Math.random() < 0.7) {
                const f = screenFacing(Math.atan2(p.dodgeDy, p.dodgeDx));
                raid.ghosts.push({ x: p.x, y: p.y, life: 0.22, row: 3 + f.dir, col: Math.floor(p.walkFrame) % 4, flip: f.dir === 1 && f.sdx < 0 });
            }
        } else {
            let sx = 0, sy = 0;
            if (keys['KeyW'] || keys['ArrowUp']) sy -= 1;
            if (keys['KeyS'] || keys['ArrowDown']) sy += 1;
            if (keys['KeyA'] || keys['ArrowLeft']) sx -= 1;
            if (keys['KeyD'] || keys['ArrowRight']) sx += 1;

            let wx = sx + sy, wy = sy - sx;
            const len = Math.hypot(wx, wy);
            if (len > 0) {
                wx /= len; wy /= len;
                const spd = p.blocking ? 1.9 : (p.attackTimer > 0 ? 1.6 : 3.4);
                moveEntity(p, wx * spd * dt, wy * spd * dt);
                p.moving = true;
                p.walkFrame += dt * (p.blocking ? 5 : 8);
                p.stepTimer -= dt;
                if (p.stepTimer <= 0) { SFX.step(); p.stepTimer = 0.38; }
            }
        }
        const mw = screenToWorld(mouse.x, mouse.y, raid.camX, raid.camY);
        p.angle = Math.atan2(mw.y - p.y, mw.x - p.x);
        if (mouse.lmb && p.attackCd <= 0) performMeleeAttack();
    }

    // Burning status
    if (p.burning) {
        p.burnTick += dt;
        if (p.burnTick >= 1.1) {
            p.burnTick = 0;
            p.hp = Math.max(0, p.hp - 3);
            spawnParticles(p.x, p.y, 3, '#f97316', 1.2, 0.35);
            if (p.hp <= 0) return endRaid(false, 'Spopielił Cię żar strażnika.');
        }
    }

    // Extraction Circle check
    let inExt = false;
    for (const ex of raid.map.extracts) {
        if (Math.random() < 0.35) {
            raid.particles.push({
                x: ex.x + (Math.random() - 0.5) * 0.9, y: ex.y + (Math.random() - 0.5) * 0.9, z: 0.1,
                vx: 0, vy: 0, vz: 1.5, color: Math.random() < 0.5 ? '#34d399' : '#a7f3d0',
                life: 1.1, maxLife: 1.1, size: 3
            });
        }
        if (Math.hypot(p.x - ex.x, p.y - ex.y) < ex.radius) inExt = true;
    }
    if (inExt) {
        raid.extracting = true;
        raid.extractTimer -= dt;
        const sec = Math.ceil(raid.extractTimer);
        if (sec < raid.extractLastSec && sec > 0) { raid.extractLastSec = sec; SFX.extractTick(); }
        if (raid.extractTimer <= 0) return endRaid(true, 'Bezpiecznie powróciłeś do Warowni ze zdobytym łupem!');
    } else {
        raid.extracting = false; raid.extractTimer = 6.0; raid.extractLastSec = 6;
    }

    // Enemy AI (Soulsborne Telegraphed Strikes)
    for (let i = raid.enemies.length - 1; i >= 0; i--) {
        const en = raid.enemies[i];
        en.hitFlash = Math.max(0, en.hitFlash - dt);
        en.atkSwingVisual = Math.max(0, en.atkSwingVisual - dt);

        if (en.staggerTimer > 0) {
            en.staggerTimer -= dt;
            continue;
        }

        const distP = Math.hypot(p.x - en.x, p.y - en.y);
        const canSee = distP < (en.isBoss ? 12 : 9.5) && hasLOS(en.x, en.y, p.x, p.y);
        if (canSee) en.state = 'combat';

        // Active attack windup (Golden Glint Telegraph!)
        if (en.windupTimer > 0) {
            en.windupTimer -= dt;
            if (en.windupTimer <= 0) {
                if (en.kind === 'archer') {
                    SFX.bowRelease();
                    raid.arrows.push({
                        x: en.x + Math.cos(en.angle) * 0.4, y: en.y + Math.sin(en.angle) * 0.4,
                        vx: Math.cos(en.angle) * 18, vy: Math.sin(en.angle) * 18,
                        dmg: en.dmg, rangeLeft: 12, fromPlayer: false
                    });
                } else {
                    SFX.swing(en.isBoss || en.kind === 'warden');
                    en.atkSwingVisual = 0.22;
                    moveEntity(en, Math.cos(en.angle) * 0.28, Math.sin(en.angle) * 0.28);
                    if (Math.hypot(p.x - en.x, p.y - en.y) <= en.atkRange + p.radius + 0.25) {
                        applyEnemyHitToPlayer(en, en.dmg, false);
                    }
                }
                en.atkTimer = en.atkCdMax * (en.isBoss && en.hp < en.maxHp * 0.5 ? 0.72 : 1.0);
            }
            continue;
        }

        en.atkTimer = Math.max(0, en.atkTimer - dt);

        if (en.state === 'combat') {
            en.angle = Math.atan2(p.y - en.y, p.x - en.x);
            if (en.kind === 'archer') {
                if (distP > 7.5) {
                    moveEntity(en, Math.cos(en.angle) * en.spd * dt, Math.sin(en.angle) * en.spd * dt);
                    en.walkFrame += dt * 6;
                } else if (distP < 4.2) {
                    moveEntity(en, -Math.cos(en.angle) * en.spd * 0.8 * dt, -Math.sin(en.angle) * en.spd * 0.8 * dt);
                    en.walkFrame += dt * 5;
                }
                if (canSee && distP <= en.atkRange && en.atkTimer <= 0) {
                    en.windupTimer = en.windupDur;
                }
            } else {
                if (distP > en.atkRange - 0.15) {
                    const spd = en.isBoss && en.hp < en.maxHp * 0.5 ? en.spd * 1.25 : en.spd;
                    moveEntity(en, Math.cos(en.angle) * spd * dt, Math.sin(en.angle) * spd * dt);
                    en.walkFrame += dt * 7;
                } else if (en.atkTimer <= 0) {
                    en.windupTimer = en.windupDur;
                }
            }
            if (distP > 15) en.state = 'patrol';
        } else {
            const dx = en.patrolTarget.x - en.x, dy = en.patrolTarget.y - en.y;
            const d = Math.hypot(dx, dy);
            if (d < 0.5 || Math.random() < 0.008) {
                en.patrolTarget = {
                    x: Math.max(3, Math.min(MAP_SIZE - 4, en.x + (Math.random() - 0.5) * 6)),
                    y: Math.max(3, Math.min(MAP_SIZE - 4, en.y + (Math.random() - 0.5) * 6))
                };
            } else {
                en.angle = Math.atan2(dy, dx);
                moveEntity(en, (dx / d) * 1.1 * dt, (dy / d) * 1.1 * dt);
                en.walkFrame += dt * 4;
            }
        }
    }

    // Update Arrows
    for (let i = raid.arrows.length - 1; i >= 0; i--) {
        const a = raid.arrows[i];
        const sx = a.vx * dt, sy = a.vy * dt;
        a.x += sx; a.y += sy;
        a.rangeLeft -= Math.hypot(sx, sy);
        if (a.rangeLeft <= 0 || isSolidAt(a.x, a.y)) {
            if (isSolidAt(a.x, a.y)) spawnParticles(a.x, a.y, 4, '#d4c3a3', 2.0, 0.25);
            raid.arrows.splice(i, 1);
            continue;
        }
        if (a.fromPlayer) {
            let hit = false;
            for (let j = raid.enemies.length - 1; j >= 0; j--) {
                const en = raid.enemies[j];
                if (Math.hypot(en.x - a.x, en.y - a.y) < en.radius + 0.2) {
                    const dmg = a.dmg * (1 - en.armorRed * 0.7);
                    en.hp -= dmg;
                    en.hitFlash = 0.14;
                    en.state = 'combat';
                    SFX.hitFlesh();
                    spawnParticles(a.x, a.y, 6, '#b51d29', 2.4, 0.35);
                    spawnText(en.x, en.y - 0.6, `-${Math.round(dmg)}`, '#fbbf24', 12);
                    addSkillXp('archery', 16);
                    if (en.hp <= 0) killEnemy(en, j);
                    hit = true; break;
                }
            }
            if (hit) raid.arrows.splice(i, 1);
        } else {
            if (Math.hypot(p.x - a.x, p.y - a.y) < p.radius + 0.16) {
                applyEnemyHitToPlayer(null, a.dmg, true);
                raid.arrows.splice(i, 1);
            }
        }
    }

    // Brazier Embers
    for (const br of raid.map.braziers) {
        if (Math.random() < 0.25) {
            raid.particles.push({
                x: br.x + (Math.random() - 0.5) * 0.2, y: br.y + (Math.random() - 0.5) * 0.2, z: 0.75,
                vx: (Math.random() - 0.5) * 0.3, vy: (Math.random() - 0.5) * 0.3, vz: 1.4 + Math.random(),
                color: Math.random() < 0.5 ? '#e06324' : '#ffd166', life: 0.7, maxLife: 0.7, size: 2
            });
        }
    }

    // Particles, Ghosts, Flashes, Float Texts
    for (let i = raid.particles.length - 1; i >= 0; i--) {
        const pt = raid.particles[i];
        pt.life -= dt;
        if (pt.life <= 0) { raid.particles.splice(i, 1); continue; }
        pt.x += pt.vx * dt; pt.y += pt.vy * dt; pt.z += pt.vz * dt;
        pt.vz -= 4.5 * dt;
        if (pt.z < 0) pt.z = 0;
    }
    for (let i = raid.ghosts.length - 1; i >= 0; i--) {
        raid.ghosts[i].life -= dt;
        if (raid.ghosts[i].life <= 0) raid.ghosts.splice(i, 1);
    }
    for (let i = raid.flashes.length - 1; i >= 0; i--) {
        raid.flashes[i].life -= dt;
        if (raid.flashes[i].life <= 0) raid.flashes.splice(i, 1);
    }
    for (let i = raid.floatTexts.length - 1; i >= 0; i--) {
        raid.floatTexts[i].life -= dt;
        raid.floatTexts[i].y -= 0.45 * dt;
        if (raid.floatTexts[i].life <= 0) raid.floatTexts.splice(i, 1);
    }

    // Falling Ash Flakes
    for (const af of raid.ashFlakes) {
        af.phase += dt * 1.6;
        af.x += (Math.sin(af.phase) * 18 - 10) * af.spd * dt;
        af.y += 28 * af.spd * dt;
        if (af.y > canvas.height + 6) { af.y = -6; af.x = Math.random() * canvas.width; }
        if (af.x < -6) af.x = canvas.width + 6;
    }

    // Overlays decay
    raid.hitFlash = Math.max(0, raid.hitFlash - dt * 2.8);
    raid.parryFlash = Math.max(0, raid.parryFlash - dt * 3.0);
    document.getElementById('hit-overlay').style.opacity = raid.hitFlash.toFixed(2);
    document.getElementById('parry-flash-overlay').style.opacity = raid.parryFlash.toFixed(2);

    // Smooth camera follow
    const tx = (p.x - p.y) * (TILE_W / 2) + Math.cos(p.angle) * 28;
    const ty = (p.x + p.y) * (TILE_H / 2) + Math.sin(p.angle) * 18;
    raid.camX += (tx - raid.camX) * Math.min(1, dt * 8);
    raid.camY += (ty - raid.camY) * Math.min(1, dt * 8);
    raid.shake = Math.max(0, raid.shake - dt * 24);

    raid.visTimer -= dt;
    if (raid.visTimer <= 0) { computeVisibility(); raid.visTimer = 0.08; }
}
