// ==================== 12. COMBAT, PARRY, BOW, ELIXIRS ====================
function spawnText(x, y, text, color = '#fff', size = 12) {
    raid.floatTexts.push({ x, y, text, color, size, life: 1.05 });
}
function spawnParticles(x, y, count, color, spd = 2.6, life = 0.45) {
    for (let i = 0; i < count; i++) {
        const a = Math.random() * Math.PI * 2;
        const s = (0.35 + Math.random() * 0.75) * spd;
        raid.particles.push({
            x, y, z: 0.45,
            vx: Math.cos(a) * s, vy: Math.sin(a) * s, vz: 1.2 + Math.random() * 1.4,
            color, life: life * (0.65 + Math.random() * 0.45), maxLife: life, size: 2 + Math.floor(Math.random() * 2)
        });
    }
}

function angleDiff(a, b) {
    let d = a - b;
    while (d > Math.PI) d -= Math.PI * 2;
    while (d < -Math.PI) d += Math.PI * 2;
    return d;
}

function performMeleeAttack() {
    const p = raid.player;
    if (raid.modalOpen || p.attackCd > 0 || p.dodgeTimer > 0) return;
    const wDef = p.loadout.weapon ? ITEMS_DB[p.loadout.weapon.id] : { dmg: 10, range: 1.3, arc: 1.2, stamina: 10, cooldown: 0.35 };
    if (p.stamina < wDef.stamina * 0.6) {
        spawnText(p.x, p.y - 0.6, 'BRAK STAMINY!', '#a8a29e', 10);
        return;
    }
    p.stamina = Math.max(0, p.stamina - wDef.stamina);
    p.blocking = false;
    p.comboStep = p.comboReset > 0 ? (p.comboStep + 1) % 3 : 0;
    p.comboReset = 0.95;
    const isHeavy = p.comboStep === 2;
    p.attackDur = isHeavy ? 0.24 : 0.18;
    p.attackTimer = p.attackDur;
    p.attackCd = wDef.cooldown * (isHeavy ? 1.22 : 1.0);
    p.attackAngle = p.angle;
    p.swingAnimMax = isHeavy ? 0.42 : 0.3;
    p.swingAnim = p.swingAnimMax;

    // Slight forward lunge
    moveEntity(p, Math.cos(p.angle) * (isHeavy ? 0.32 : 0.18), Math.sin(p.angle) * (isHeavy ? 0.32 : 0.18));
    SFX.swing(isHeavy);

    const forgeMult = 1 + profile.stronghold.forge * 0.12;
    const skillMult = 1 + (profile.skills.melee.lv - 1) * 0.06;
    const comboMult = isHeavy ? 1.35 : 1.0;

    let hitAny = false;
    for (let i = raid.enemies.length - 1; i >= 0; i--) {
        const en = raid.enemies[i];
        const dist = Math.hypot(en.x - p.x, en.y - p.y);
        if (dist > wDef.range + en.radius) continue;
        const angTo = Math.atan2(en.y - p.y, en.x - p.x);
        if (Math.abs(angleDiff(angTo, p.attackAngle)) > wDef.arc * 0.58) continue;

        // Check for Critical Riposte on staggered enemy!
        const isRiposte = en.staggerTimer > 0;
        let dmg = wDef.dmg * forgeMult * skillMult * comboMult;
        if (isRiposte) {
            const ripMult = 2.6 + (profile.skills.parry.lv - 1) * 0.15;
            dmg *= ripMult;
            en.staggerTimer = 0;
            SFX.riposte();
            raid.hitstop = 0.11;
            raid.shake = Math.min(14, raid.shake + 10);
            spawnParticles(en.x, en.y, 18, '#ffd166', 4.2, 0.6);
            raid.flashes.push({ x: en.x, y: en.y, radius: 130, life: 0.16, maxLife: 0.16, color: 'rgba(255, 209, 102, 0.9)' });
            spawnText(en.x, en.y - 0.9, `RIPOSTA -${Math.round(dmg)}!`, '#ffd166', 14);
            addSkillXp('parry', 35);
        } else {
            dmg *= (1 - en.armorRed);
            SFX.hitFlesh();
            raid.hitstop = isHeavy ? 0.05 : 0.025;
            raid.shake = Math.min(9, raid.shake + (isHeavy ? 5 : 2.5));
            spawnParticles(en.x, en.y, 7, '#b51d29', 2.8, 0.4);
            spawnText(en.x, en.y - 0.6, `-${Math.round(dmg)}`, isHeavy ? '#f59e0b' : '#f5f0e6', 12);
            addSkillXp('melee', 12);
        }

        en.hp -= dmg;
        en.hitFlash = 0.15;
        en.state = 'combat';
        if (isRiposte) {
            p.riposteIframe = 0.5; // krótka nietykalność w trakcie egzekucji
        } else {
            damagePoise(en, wDef.dmg * forgeMult * (isHeavy ? 1.9 : 0.85));
        }
        // Knockback
        const kb = isRiposte ? 0.45 : (isHeavy ? 0.25 : 0.12);
        moveEntity(en, Math.cos(angTo) * kb, Math.sin(angTo) * kb);
        hitAny = true;

        if (en.hp <= 0) killEnemy(en, i);
    }
    if (hitAny && p.comboStep === 2) addSkillXp('melee', 6);
}

// ---------- POSTURA ----------
function damagePoise(en, amount) {
    if (en.staggerTimer > 0 || en.hp <= 0) return;
    en.poise -= amount;
    en.poiseRegenDelay = 2.5;
    if (en.poise <= 0) {
        en.poise = en.maxPoise;
        en.staggerTimer = en.isBoss ? 1.8 : 2.2;
        en.windupTimer = 0;
        en.atkTimer = en.staggerTimer;
        raid.hitstop = Math.max(raid.hitstop, 0.09);
        raid.shake = Math.min(12, raid.shake + 6);
        SFX.parryClang();
        spawnParticles(en.x, en.y, 16, '#ffd166', 3.6, 0.5);
        spawnText(en.x, en.y - 1.05, 'POSTURA ZŁAMANA! [LPM]', '#ffd166', 13);
    }
}

// ---------- POCHODNIA (klawisz F) ----------
function toggleTorch() {
    const p = raid.player;
    if (raid.modalOpen || p.dead) return;
    if (p.torchInHand) {
        p.torchInHand = false;
        p.blocking = false;
        raid.groundTorch = { x: p.x + Math.cos(p.angle) * 0.6, y: p.y + Math.sin(p.angle) * 0.6 };
        if (isSolidAt(raid.groundTorch.x, raid.groundTorch.y)) raid.groundTorch = { x: p.x, y: p.y };
        SFX.dodge();
        spawnParticles(raid.groundTorch.x, raid.groundTorch.y, 10, '#ffb347', 2.2, 0.5);
        spawnText(p.x, p.y - 0.9, 'POCHODNIA NA ZIEMI — TARCZA GOTOWA', '#fbbf24', 11);
    } else if (raid.groundTorch && Math.hypot(raid.groundTorch.x - p.x, raid.groundTorch.y - p.y) < 1.6) {
        p.torchInHand = true;
        p.blocking = false;
        p.parryWindow = 0;
        raid.groundTorch = null;
        SFX.loot();
        spawnText(p.x, p.y - 0.9, 'POCHODNIA W DŁONI', '#fbbf24', 11);
    } else {
        spawnText(p.x, p.y - 0.9, raid.groundTorch ? 'Pochodnia za daleko!' : 'Brak pochodni', '#a8a29e', 10);
    }
    computeVisibility();
    updateRaidHUD();
}

// ---------- PLECAK (klawisz G) ----------
// Mikstury i strzały są na pasie: zostają przy tobie. Reszta sakwy ląduje na ziemi.
function isBeltItem(it) {
    const t = ITEMS_DB[it.id].type;
    return t === 'elixir' || t === 'arrow';
}
function backpackLoad() {
    return raid.player.loadout.backpack.filter(it => !isBeltItem(it)).length;
}
function dropBackpack() {
    const p = raid.player;
    if (raid.modalOpen || p.dead) return;
    const l = p.loadout;
    const dropped = l.backpack.filter(it => !isBeltItem(it));
    if (dropped.length === 0) return spawnText(p.x, p.y - 0.9, 'Sakwa pusta', '#a8a29e', 10);
    l.backpack = l.backpack.filter(isBeltItem);
    raid.corpses.push({
        id: 'bag_' + Date.now(), kind: 'bag', isBag: true,
        x: p.x - Math.cos(p.angle) * 0.4, y: p.y - Math.sin(p.angle) * 0.4,
        name: 'Twoja porzucona sakwa',
        items: dropped.map(item => ({ item, revealed: true }))
    });
    SFX.block();
    spawnText(p.x, p.y - 0.9, `SAKWA ZRZUCONA (${dropped.length})`, '#e6ba63', 11);
    updateRaidHUD();
}

function performBowShot() {
    const p = raid.player;
    if (raid.modalOpen || p.bowCd > 0 || p.dodgeTimer > 0) return;
    if (!p.loadout.bow) return showToast('Nie masz wyposażonego łuku!', 'warn');
    const arrows = countRaidArrows();
    if (arrows <= 0) return showToast('Brak strzał w sakwie!', 'warn');
    const bDef = ITEMS_DB[p.loadout.bow.id];
    if (p.stamina < bDef.stamina) return;

    consumeRaidArrow();
    p.stamina -= bDef.stamina;
    p.bowCd = 0.58;
    SFX.bowRelease();

    const archMult = 1 + (profile.skills.archery.lv - 1) * 0.08;
    raid.arrows.push({
        x: p.x + Math.cos(p.angle) * 0.4,
        y: p.y + Math.sin(p.angle) * 0.4,
        vx: Math.cos(p.angle) * bDef.speed * (1 + (profile.skills.archery.lv - 1) * 0.04),
        vy: Math.sin(p.angle) * bDef.speed * (1 + (profile.skills.archery.lv - 1) * 0.04),
        dmg: bDef.dmg * archMult,
        rangeLeft: bDef.range,
        fromPlayer: true
    });
    updateRaidHUD();
}

function performDodge() {
    const p = raid.player;
    if (raid.modalOpen || p.dodgeCd > 0 || p.dodgeTimer > 0) return;
    const cost = Math.max(12, 22 - (profile.skills.endurance.lv - 1) * 1.2);
    if (p.stamina < cost) return;
    p.stamina -= cost;

    let sx = 0, sy = 0;
    if (keys['KeyW'] || keys['ArrowUp']) sy -= 1;
    if (keys['KeyS'] || keys['ArrowDown']) sy += 1;
    if (keys['KeyA'] || keys['ArrowLeft']) sx -= 1;
    if (keys['KeyD'] || keys['ArrowRight']) sx += 1;

    let wx = sx + sy, wy = sy - sx;
    const len = Math.hypot(wx, wy);
    if (len > 0) { wx /= len; wy /= len; }
    else { wx = Math.cos(p.angle); wy = Math.sin(p.angle); }

    p.dodgeDx = wx; p.dodgeDy = wy;
    p.dodgeTimer = 0.30; // i-frames!
    p.dodgeCd = 0.62;
    p.blocking = false;
    SFX.dodge();
    addSkillXp('endurance', 8);
}

function triggerParryStart() {
    const p = raid.player;
    if (raid.modalOpen || p.dodgeTimer > 0) return;
    if (p.torchInHand) {
        // Ręka zajęta pochodnią: tylko słaby blok, bez parowania
        p.blocking = true;
        spawnText(p.x, p.y - 0.9, 'POCHODNIA W RĘCE — [F]', '#f59e0b', 10);
        return;
    }
    p.blocking = true;
    if (p.parryCd <= 0) {
        const shBonus = p.loadout.shield ? ITEMS_DB[p.loadout.shield.id].parryBonus : 0;
        const altarBonus = profile.stronghold.altar * 0.04;
        const skillBonus = (profile.skills.parry.lv - 1) * 0.015;
        p.parryWindow = 0.28 + shBonus + altarBonus + skillBonus;
        p.parryCd = 0.65;
    }
}

function applyEnemyHitToPlayer(en, rawDmg, isRanged = false) {
    const p = raid.player;
    if (p.riposteIframe > 0) return;
    if (p.dodgeTimer > 0) {
        spawnText(p.x, p.y - 0.7, 'UNIK!', '#6ee7b7', 11);
        addSkillXp('endurance', 14);
        return;
    }

    // Check PARRY (melee only, during parryWindow!)
    if (!isRanged && p.parryWindow > 0 && en && en.heavy) {
        spawnText(p.x, p.y - 0.95, 'NIE DO SPAROWANIA!', '#f87171', 11);
    }
    if (!isRanged && p.parryWindow > 0 && en && !en.heavy) {
        p.parryWindow = 0;
        en.staggerTimer = 2.8;
        en.windupTimer = 0;
        en.atkTimer = 2.8;
        raid.parries++;
        raid.hitstop = 0.13;
        raid.parryFlash = 0.85;
        raid.shake = Math.min(12, raid.shake + 8);
        SFX.parryClang();
        spawnParticles((p.x + en.x) / 2, (p.y + en.y) / 2, 22, '#ffd166', 4.5, 0.55);
        raid.flashes.push({ x: (p.x + en.x) / 2, y: (p.y + en.y) / 2, radius: 160, life: 0.2, maxLife: 0.2, color: 'rgba(255, 220, 110, 0.95)' });
        spawnText(en.x, en.y - 0.95, 'PAROWANIE! [LPM RIPOSTA]', '#ffd166', 13);
        addSkillXp('parry', 30);
        return;
    }

    let dmg = rawDmg;
    // Shield Block
    if (p.blocking && p.stamina > 6) {
        // Pochodnią da się tylko odbić cios (słabo); pełny blok wymaga tarczy w wolnej ręce
        const blockRed = p.torchInHand ? 0.3 : (p.loadout.shield ? ITEMS_DB[p.loadout.shield.id].blockRed : 0.45);
        const stamCost = rawDmg * 0.65 * (en && en.heavy ? 1.8 : 1);
        p.stamina = Math.max(0, p.stamina - stamCost);
        dmg *= (1 - blockRed);
        SFX.block();
        spawnParticles(p.x, p.y, 7, '#d4c3a3', 2.4, 0.25);
        spawnText(p.x, p.y - 0.65, `BLOK -${Math.round(dmg)}`, '#7dd3fc', 11);
        if (p.stamina <= 0) spawnText(p.x, p.y - 0.95, 'PRZEŁAMANIE BLOKU!', '#f87171', 11);
    } else {
        // Armor reduction
        if (p.loadout.armor && p.loadout.armor.durability > 0) {
            const aDef = ITEMS_DB[p.loadout.armor.id];
            const abs = dmg * aDef.reduction;
            p.loadout.armor.durability = Math.max(0, p.loadout.armor.durability - abs * 0.75);
            dmg = Math.max(2, dmg - abs);
        }
        SFX.hurt();
        raid.hitFlash = 0.85;
        raid.shake = Math.min(12, raid.shake + 6);
        spawnParticles(p.x, p.y, 10, '#a31820', 2.6, 0.45);
        spawnText(p.x, p.y - 0.6, `-${Math.round(dmg)}`, '#ff4d4d', 12);

        if (en && en.isBoss && Math.random() < 0.35 && !p.burning) {
            p.burning = true;
            spawnText(p.x, p.y - 0.9, 'POPARZENIE ŻAREM!', '#f97316', 11);
            showToast('Płoniesz! Użyj Maści z Popiołu [3]!', 'danger');
        }
    }

    p.hp = Math.max(0, p.hp - dmg);
    if (p.hp <= 0) endRaid(false, 'Poległeś w mroku ruin.');
}

function countRaidArrows() {
    return [...raid.player.loadout.backpack, ...raid.player.loadout.reliquary]
        .reduce((s, it) => s + (it && it.id === 'iron_arrows' ? it.qty : 0), 0);
}
function consumeRaidArrow() {
    for (const arr of [raid.player.loadout.backpack, raid.player.loadout.reliquary]) {
        const idx = arr.findIndex(i => i.id === 'iron_arrows' && i.qty > 0);
        if (idx !== -1) {
            arr[idx].qty--;
            if (arr[idx].qty <= 0) arr.splice(idx, 1);
            return;
        }
    }
}

function useElixir(kind) {
    const p = raid.player;
    if (!raid || raid.ended) return;
    let found = null;
    for (const src of ['backpack', 'reliquary']) {
        const idx = p.loadout[src].findIndex(i => ITEMS_DB[i.id].elixKind === kind);
        if (idx !== -1) { found = { src, idx, def: ITEMS_DB[p.loadout[src][idx].id] }; break; }
    }
    if (!found) return showToast('Brak tej mikstury w sakwie!', 'warn');

    p.loadout[found.src].splice(found.idx, 1);
    SFX.drink();
    if (kind === 'heal') {
        const heal = Math.round(found.def.healAmount * (1 + profile.stronghold.alchemist * 0.22));
        p.hp = Math.min(p.maxHp, p.hp + heal);
        spawnParticles(p.x, p.y, 10, '#f97316', 2.0, 0.5);
        spawnText(p.x, p.y - 0.7, `+${heal} HP`, '#4ade80', 12);
    } else if (kind === 'stamina') {
        p.stamina = p.maxStamina;
        p.stamRegenBoost = 12.0;
        spawnParticles(p.x, p.y, 10, '#34d399', 2.0, 0.5);
        spawnText(p.x, p.y - 0.7, 'PRZYPŁYW SIŁ!', '#6ee7b7', 12);
    } else if (kind === 'salve') {
        p.burning = false;
        p.hp = Math.min(p.maxHp, p.hp + 18);
        spawnParticles(p.x, p.y, 8, '#e6ba63', 1.8, 0.45);
        spawnText(p.x, p.y - 0.7, 'UGASZONO +18 HP', '#fbbf24', 11);
    }
    updateRaidHUD();
}

function killEnemy(en, idx) {
    raid.enemies.splice(idx, 1);
    raid.kills++;
    spawnParticles(en.x, en.y, 16, '#8f151d', 3.2, 0.65);

    const loot = [];
    if (en.isBoss) {
        loot.push({ item: makeItem('ash_crown'), revealed: false });
        loot.push({ item: makeItem('ancient_relic'), revealed: false });
        loot.push({ item: makeItem('ash_essence'), revealed: false });
        loot.push({ item: makeItem('ash_greatsword'), revealed: false });
        showToast('🏆 POKONANO POPIELNEGO STRAŻNIKA! Przeszukaj jego szczątki!', 'success');
    } else {
        if (Math.random() < 0.65) loot.push({ item: makeItem(Math.random() < 0.5 ? 'iron_ingot' : 'ash_essence'), revealed: false });
        if (en.kind === 'archer') loot.push({ item: makeItem('iron_arrows', 8), revealed: false });
        if (en.kind === 'warden' && Math.random() < 0.55) loot.push({ item: makeItem(Math.random() < 0.5 ? 'iron_kite' : 'runic_ring'), revealed: false });
        if (en.kind === 'knight' && Math.random() < 0.5) loot.push({ item: makeItem(Math.random() < 0.6 ? 'chainmail_hauberk' : 'ancient_relic'), revealed: false });
        if (en.kind === 'brute') {
            loot.push({ item: makeItem('iron_ingot'), revealed: false });
            if (Math.random() < 0.08) loot.push({ item: makeItem('executioner_axe'), revealed: false });
            else if (Math.random() < 0.35) loot.push({ item: makeItem('golden_idol'), revealed: false });
        }
        if (Math.random() < 0.45) loot.push({ item: makeItem('ember_flask'), revealed: false });
        if (loot.length === 0) loot.push({ item: makeItem('silver_goblet'), revealed: false });
    }

    raid.corpses.push({
        id: 'corp_' + Date.now() + '_' + idx,
        x: en.x, y: en.y, kind: en.kind, angle: en.angle,
        name: 'Szczątki: ' + en.name,
        isBoss: en.isBoss,
        items: loot
    });
}

function findNearestInteractable() {
    const p = raid.player;
    let best = null, bd = 1.7;
    for (const b of raid.map.lootBoxes) {
        const d = Math.hypot(b.x - p.x, b.y - p.y);
        if (d < bd) { bd = d; best = b; }
    }
    for (const c of raid.corpses) {
        const d = Math.hypot(c.x - p.x, c.y - p.y);
        if (d < bd) { bd = d; best = c; }
    }
    return best;
}
