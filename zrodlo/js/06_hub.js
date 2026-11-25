// ==================== 8. TOASTS & TOOLTIPS ====================
function showToast(msg, type = 'info') {
    const container = document.getElementById('toast-container');
    const el = document.createElement('div');
    const styles = {
        info: 'border-[#c79c4c] text-[#f0e6d8] bg-[#1a161c]/95',
        warn: 'border-amber-500 text-amber-200 bg-[#241a10]/95',
        danger: 'border-red-500 text-red-200 bg-[#261114]/95',
        success: 'border-emerald-500 text-emerald-200 bg-[#10241c]/95'
    };
    el.className = `border rounded px-3 py-2 text-xs font-semibold shadow-xl text-center transition-all duration-300 ${styles[type] || styles.info}`;
    el.textContent = msg;
    container.appendChild(el);
    setTimeout(() => {
        el.style.opacity = '0'; el.style.transform = 'translateY(-8px)';
        setTimeout(() => el.remove(), 300);
    }, 2500);
}

const ttEl = document.getElementById('item-tooltip');
function showTooltip(e, inst) {
    const def = ITEMS_DB[inst.id];
    if (!def) return;
    const typePL = { weapon: 'Broń Biała', shield: 'Tarcza', bow: 'Łuk', arrow: 'Strzały', armor: 'Pancerz', elixir: 'Mikstura', material: 'Surowiec Warowni', valuable: 'Kosztowność' };
    document.getElementById('tt-name').textContent = def.name;
    document.getElementById('tt-type').textContent = typePL[def.type] || def.type;
    document.getElementById('tt-desc').textContent = def.desc;
    let s = `<div class="flex justify-between"><span class="text-stone-400">Wartość skupu:</span><span class="text-[#e6ba63] font-bold">${Math.floor(def.price * 0.65)} zł</span></div>`;
    if (def.type === 'weapon') {
        s += `<div class="flex justify-between"><span class="text-stone-400">Obrażenia:</span><span class="text-red-300">${def.dmg}</span></div>`;
        s += `<div class="flex justify-between"><span class="text-stone-400">Koszt Staminy:</span><span class="text-emerald-300">${def.stamina}</span></div>`;
    } else if (def.type === 'shield') {
        s += `<div class="flex justify-between"><span class="text-stone-400">Blok obrażeń:</span><span class="text-sky-300">${Math.round(def.blockRed * 100)}%</span></div>`;
        s += `<div class="flex justify-between"><span class="text-stone-400">Bonus Parowania:</span><span class="text-[#e6ba63]">+${Math.round(def.parryBonus * 1000)} ms</span></div>`;
    } else if (def.type === 'bow') {
        s += `<div class="flex justify-between"><span class="text-stone-400">Obrażenia:</span><span class="text-red-300">${def.dmg}</span></div>`;
    } else if (def.type === 'armor') {
        s += `<div class="flex justify-between"><span class="text-stone-400">Wytrzymałość:</span><span class="text-sky-300">${Math.ceil(inst.durability)} / ${def.maxDurability}</span></div>`;
        s += `<div class="flex justify-between"><span class="text-stone-400">Redukcja:</span><span class="text-sky-300">${Math.round(def.reduction * 100)}% (Kl. ${def.tier})</span></div>`;
    } else if (def.type === 'arrow') {
        s += `<div class="flex justify-between"><span class="text-stone-400">Ilość:</span><span class="text-[#e6ba63]">${inst.qty} szt.</span></div>`;
    }
    document.getElementById('tt-stats').innerHTML = s;
    ttEl.classList.remove('hidden');
    moveTooltip(e);
}
function moveTooltip(e) {
    ttEl.style.left = Math.min(window.innerWidth - 270, e.clientX + 14) + 'px';
    ttEl.style.top = Math.min(window.innerHeight - 190, e.clientY + 14) + 'px';
}
function hideTooltip() { ttEl.classList.add('hidden'); }

// ==================== 9. HUB UI RENDERING ====================
function makeSlotEl(inst, extraCls = '', onClick = null) {
    const el = document.createElement('div');
    if (!inst) {
        el.className = `slot-cell rounded p-1.5 h-16 flex items-center justify-center text-[10px] text-stone-600 ${extraCls}`;
        el.textContent = 'Puste';
        return el;
    }
    const def = ITEMS_DB[inst.id];
    el.className = `slot-cell rarity-${def.rarity} rounded p-1.5 h-16 flex flex-col justify-between cursor-pointer ${extraCls}`;
    let badge = '';
    if (def.type === 'arrow') badge = `x${inst.qty}`;
    else if (def.type === 'armor') badge = `${Math.ceil(inst.durability)}/${def.maxDurability}`;
    else if (def.type === 'weapon') badge = `⚔${def.dmg}`;
    else if (def.type === 'shield') badge = `${Math.round(def.blockRed * 100)}%`;
    else badge = `${Math.floor(def.price * 0.65)}zł`;

    el.innerHTML = `
        <div class="flex items-start justify-between gap-1">
            ${iconHtml(def, 24)}
            <span class="text-[9px] text-stone-400 font-bold">${badge}</span>
        </div>
        <div class="text-[10px] font-semibold text-stone-200 leading-tight truncate">${def.name}</div>
    `;
    el.onmouseenter = e => showTooltip(e, inst);
    el.onmousemove = moveTooltip;
    el.onmouseleave = hideTooltip;
    if (onClick) el.onclick = onClick;
    return el;
}

function updateHeader() {
    document.getElementById('hdr-gold').textContent = profile.gold.toLocaleString('pl-PL');
    document.getElementById('hdr-iron').textContent = countMaterial('iron');
    document.getElementById('hdr-ash').textContent = countMaterial('ash');
    document.getElementById('hdr-relics').textContent = countMaterial('relic');
    document.getElementById('hdr-raids').textContent = profile.stats.raids;
    document.getElementById('hdr-survived').textContent = profile.stats.survived;
}

function renderZones() {
    const el = document.getElementById('zone-cards');
    el.innerHTML = '';
    for (const z of ZONES) {
        const act = z.id === selectedZoneId;
        const c = document.createElement('div');
        c.className = `rounded-lg p-3 cursor-pointer transition-all border ${act ? 'bg-[#241b1a] border-[#e07a38] shadow-lg' : 'bg-[#120f14] border-[#302935] hover:border-stone-500'}`;
        c.innerHTML = `
            <div class="flex items-center justify-between mb-1">
                <span class="font-fantasy font-bold text-xs ${act ? 'text-[#f0b96e]' : 'text-stone-200'}">${z.name}</span>
            </div>
            <div class="text-[10px] text-stone-400 mb-2">${z.subtitle}</div>
            <div class="flex justify-between text-[10px] border-t border-stone-800 pt-2 mb-1.5">
                <span>Poziom: <b class="${z.diffColor}">${z.diff}</b></span>
                <span>Łup: <b class="text-[#e6ba63]">${z.lootStars}</b></span>
            </div>
            <p class="text-[10px] text-stone-400 leading-snug">${z.desc}</p>
        `;
        c.onclick = () => { SFX.ui(); selectedZoneId = z.id; renderZones(); };
        el.appendChild(c);
    }
    document.getElementById('seed-input').value = currentSeed;
}

function renderPreRaid() {
    const l = profile.loadout;
    const w = l.weapon ? ITEMS_DB[l.weapon.id] : null;
    const sh = l.shield ? ITEMS_DB[l.shield.id] : null;
    const bw = l.bow ? ITEMS_DB[l.bow.id] : null;
    const ar = l.armor ? ITEMS_DB[l.armor.id] : null;
    const flasks = [...l.backpack, ...l.reliquary].filter(i => i && ITEMS_DB[i.id].elixKind === 'heal').length;
    const arrows = [...l.backpack, ...l.reliquary].reduce((s, i) => s + (i && i.id === 'iron_arrows' ? i.qty : 0), 0);

    document.getElementById('pre-raid-summary').innerHTML = `
        <div class="flex justify-between bg-[#100d12] p-2 rounded border border-stone-800">
            <span class="text-stone-400">Broń Biała:</span>
            <span class="font-bold ${w ? 'text-[#e6ba63]' : 'text-red-400'}">${w ? w.name : 'BRAK BRONI!'}</span>
        </div>
        <div class="flex justify-between bg-[#100d12] p-2 rounded border border-stone-800">
            <span class="text-stone-400">Tarcza / Łuk:</span>
            <span class="font-bold text-stone-200">${sh ? sh.name : 'Brak'} / ${bw ? arrows + ' strzał' : 'Brak'}</span>
        </div>
        <div class="flex justify-between bg-[#100d12] p-2 rounded border border-stone-800">
            <span class="text-stone-400">Pancerz:</span>
            <span class="font-bold ${ar ? 'text-sky-300' : 'text-stone-500'}">${ar ? ar.name : 'Brak'}</span>
        </div>
        <div class="flex justify-between bg-[#100d12] p-2 rounded border border-stone-800">
            <span class="text-stone-400">Flaszki Żaru:</span>
            <span class="font-bold ${flasks > 0 ? 'text-emerald-400' : 'text-amber-400'}">${flasks} szt.</span>
        </div>
        <div class="flex justify-between bg-[#100d12] p-2 rounded border border-stone-800">
            <span class="text-stone-400">Sakwa / Relikwiarz:</span>
            <span class="font-bold text-stone-200">${l.backpack.length}/12 • 🔒 ${l.reliquary.length}/${getMaxReliquary()}</span>
        </div>
    `;
    const warns = [];
    if (!w) warns.push('⚠ Brak broni białej! Odbierz darmowy Zestaw Wygnańca u Kupca lub załóż broń ze Skrytki.');
    if (flasks === 0) warns.push('⚠ Nie masz Flaszek Żaru do leczenia w trakcie wyprawy.');
    document.getElementById('pre-raid-warnings').innerHTML = warns.map(t => `<div class="bg-red-950/50 border border-red-800/70 rounded px-2.5 py-1.5 text-[11px] text-red-200">${t}</div>`).join('');
}

function renderInventoryTab() {
    const l = profile.loadout;
    const maxStash = getMaxStash();
    const maxRel = getMaxReliquary();

    const bindEquip = (elId, key, emptyLabel) => {
        const box = document.getElementById(elId);
        const it = l[key];
        box.innerHTML = '';
        box.className = 'slot-cell rounded p-2 h-16 cursor-pointer flex flex-col justify-between ' + (it ? `rarity-${ITEMS_DB[it.id].rarity}` : '');
        if (it) {
            const def = ITEMS_DB[it.id];
            box.innerHTML = `<div class="flex justify-between items-center">${iconHtml(def, 24)}<span class="text-[10px] text-[#e6ba63] font-bold">${def.dmg ? '⚔' + def.dmg : (def.blockRed ? Math.round(def.blockRed * 100) + '%' : (def.tier ? 'Kl.' + def.tier : ''))}</span></div><div class="text-[11px] font-bold text-stone-100 truncate">${def.name}</div>`;
            box.onmouseenter = e => showTooltip(e, it);
            box.onmousemove = moveTooltip;
            box.onmouseleave = hideTooltip;
            box.onclick = () => {
                if (profile.stash.length >= maxStash) return showToast('Skrytka jest pełna!', 'warn');
                profile.stash.push(l[key]);
                l[key] = null;
                SFX.ui(); hideTooltip(); saveProfile(); refreshHub();
            };
        } else {
            box.innerHTML = `<span class="text-[11px] text-stone-600 m-auto">${emptyLabel}</span>`;
            box.onmouseenter = null; box.onclick = null;
        }
    };

    bindEquip('eq-weapon', 'weapon', 'Brak broni');
    bindEquip('eq-shield', 'shield', 'Brak tarczy');
    bindEquip('eq-bow', 'bow', 'Brak łuku');
    bindEquip('eq-armor', 'armor', 'Brak pancerza');

    // Reliquary
    document.getElementById('rel-count').textContent = l.reliquary.length;
    document.getElementById('rel-max').textContent = maxRel;
    const relEl = document.getElementById('eq-reliquary');
    relEl.innerHTML = '';
    for (let i = 0; i < maxRel; i++) {
        const it = l.reliquary[i] || null;
        relEl.appendChild(makeSlotEl(it, 'slot-reliquary', () => {
            if (profile.stash.length >= maxStash) return showToast('Skrytka jest pełna!', 'warn');
            profile.stash.push(l.reliquary.splice(i, 1)[0]);
            SFX.ui(); hideTooltip(); saveProfile(); refreshHub();
        }));
    }

    // Backpack
    document.getElementById('bp-count').textContent = l.backpack.length;
    const bpEl = document.getElementById('eq-backpack');
    bpEl.innerHTML = '';
    for (let i = 0; i < 12; i++) {
        const it = l.backpack[i] || null;
        bpEl.appendChild(makeSlotEl(it, '', e => {
            if (e.shiftKey) {
                if (l.reliquary.length >= maxRel) return showToast('Relikwiarz jest pełny!', 'warn');
                l.reliquary.push(l.backpack.splice(i, 1)[0]);
            } else {
                if (profile.stash.length >= maxStash) return showToast('Skrytka jest pełna!', 'warn');
                profile.stash.push(l.backpack.splice(i, 1)[0]);
            }
            SFX.ui(); hideTooltip(); saveProfile(); refreshHub();
        }));
    }

    // Stash
    document.getElementById('stash-count').textContent = profile.stash.length;
    document.getElementById('stash-max').textContent = maxStash;
    const stEl = document.getElementById('stash-grid');
    stEl.innerHTML = '';
    for (let i = 0; i < maxStash; i++) {
        const it = profile.stash[i] || null;
        stEl.appendChild(makeSlotEl(it, '', e => {
            const def = ITEMS_DB[it.id];
            if (e.shiftKey) {
                if (l.reliquary.length >= maxRel) return showToast('Relikwiarz jest pełny!', 'warn');
                l.reliquary.push(profile.stash.splice(i, 1)[0]);
            } else if (def.type === 'weapon' && !l.weapon) l.weapon = profile.stash.splice(i, 1)[0];
            else if (def.type === 'shield' && !l.shield) l.shield = profile.stash.splice(i, 1)[0];
            else if (def.type === 'bow' && !l.bow) l.bow = profile.stash.splice(i, 1)[0];
            else if (def.type === 'armor' && !l.armor) l.armor = profile.stash.splice(i, 1)[0];
            else {
                if (l.backpack.length >= 12) return showToast('Sakwa jest pełna (12/12)!', 'warn');
                l.backpack.push(profile.stash.splice(i, 1)[0]);
            }
            SFX.ui(); hideTooltip(); saveProfile(); refreshHub();
        }));
    }
}

function renderMerchant() {
    const hasWeapon = profile.loadout.weapon || profile.stash.some(i => ITEMS_DB[i.id].type === 'weapon') || profile.loadout.backpack.some(i => ITEMS_DB[i.id].type === 'weapon');
    document.getElementById('btn-starter-kit').classList.toggle('hidden', !(!hasWeapon && profile.gold < 200));

    const stockEl = document.getElementById('merchant-stock');
    stockEl.innerHTML = '';
    const forgeLv = profile.stronghold.forge;
    const list = Object.values(ITEMS_DB).filter(d => {
        if (d.type === 'material' || d.type === 'valuable') return false;
        if (merchantCat === 'all') return true;
        if (merchantCat === 'bow') return d.type === 'bow' || d.type === 'arrow';
        return d.type === merchantCat;
    });

    for (const def of list) {
        const locked = (def.forgeReq || 0) > forgeLv;
        const card = document.createElement('div');
        card.className = `bg-[#120f15] border border-stone-800 rarity-${def.rarity} rounded p-2.5 flex flex-col justify-between gap-2 ${locked ? 'opacity-60' : ''}`;
        card.innerHTML = `
            <div class="flex items-start gap-2">
                <div class="bg-[#0b090d] border border-stone-800 rounded p-1 shrink-0">${iconHtml(def, 28)}</div>
                <div>
                    <div class="text-xs font-bold text-stone-100">${def.name}</div>
                    <div class="text-[10px] text-stone-400 mt-0.5 leading-snug">${def.desc}</div>
                </div>
            </div>
            <div class="flex items-center justify-between pt-1.5 border-t border-stone-800/80">
                <span class="text-xs font-bold text-[#e6ba63]">🪙 ${def.price} zł</span>
                ${locked
                    ? `<span class="text-[10px] text-orange-400 font-bold">Wymaga Kuźni poz. ${def.forgeReq}</span>`
                    : `<button class="buy-btn ember-btn rounded px-2.5 py-1 text-[11px] font-bold" ${profile.gold < def.price ? 'disabled' : ''}>Kup</button>`}
            </div>
        `;
        const btn = card.querySelector('.buy-btn');
        if (btn) {
            btn.onclick = () => {
                if (profile.gold < def.price) return showToast('Za mało Złota!', 'danger');
                if (profile.stash.length >= getMaxStash() && profile.loadout.backpack.length >= 12) return showToast('Brak miejsca w Skrytce i Sakwie!', 'warn');
                profile.gold -= def.price;
                const inst = makeItem(def.id);
                if (def.type === 'weapon' && !profile.loadout.weapon) profile.loadout.weapon = inst;
                else if (def.type === 'shield' && !profile.loadout.shield) profile.loadout.shield = inst;
                else if (def.type === 'bow' && !profile.loadout.bow) profile.loadout.bow = inst;
                else if (def.type === 'armor' && !profile.loadout.armor) profile.loadout.armor = inst;
                else if (profile.stash.length < getMaxStash()) profile.stash.push(inst);
                else profile.loadout.backpack.push(inst);
                SFX.loot(); showToast(`Kupiono: ${def.name}`, 'success'); saveProfile(); refreshHub();
            };
        }
        stockEl.appendChild(card);
    }

    const sellEl = document.getElementById('merchant-sell-list');
    sellEl.innerHTML = '';
    const sellables = [
        ...profile.stash.map((it, idx) => ({ it, src: 'stash', idx })),
        ...profile.loadout.backpack.map((it, idx) => ({ it, src: 'backpack', idx }))
    ];
    if (!sellables.length) {
        sellEl.innerHTML = '<div class="text-xs text-stone-500 text-center py-6">Brak przedmiotów na sprzedaż.</div>';
    } else {
        for (const entry of sellables) {
            const def = ITEMS_DB[entry.it.id];
            const val = Math.floor(def.price * 0.65);
            const row = document.createElement('div');
            row.className = `flex items-center justify-between bg-[#120f15] border border-stone-800 rarity-${def.rarity} rounded px-2.5 py-1.5 text-xs`;
            row.innerHTML = `
                <div class="flex items-center gap-1.5 truncate pr-2">
                    ${iconHtml(def, 18)}
                    <span class="font-semibold text-stone-200 truncate">${def.name}</span>
                    <span class="text-[10px] text-stone-500 shrink-0">(${entry.src === 'stash' ? 'Skrytka' : 'Sakwa'})</span>
                </div>
                <button class="sell-btn iron-btn rounded px-2 py-1 text-[11px] text-[#e6ba63] font-bold shrink-0">+${val} zł</button>
            `;
            row.querySelector('.sell-btn').onclick = () => {
                if (entry.src === 'stash') profile.stash.splice(entry.idx, 1);
                else profile.loadout.backpack.splice(entry.idx, 1);
                profile.gold += val;
                SFX.loot(); saveProfile(); refreshHub();
            };
            sellEl.appendChild(row);
        }
    }
}

function renderStronghold() {
    const grid = document.getElementById('stronghold-grid');
    grid.innerHTML = '';
    for (const up of Object.values(STRONGHOLD_UPGRADES)) {
        const lv = profile.stronghold[up.id];
        const maxed = lv >= up.maxLv;
        const cost = maxed ? null : up.costs[lv];
        const canAfford = !maxed &&
            profile.gold >= cost.gold &&
            countMaterial('iron') >= cost.iron &&
            countMaterial('ash') >= cost.ash &&
            countMaterial('relic') >= cost.relic;

        const card = document.createElement('div');
        card.className = 'dark-panel rounded-lg p-4 flex flex-col justify-between gap-3';
        card.innerHTML = `
            <div>
                <div class="flex items-center justify-between mb-1.5">
                    <h3 class="font-fantasy font-bold text-sm text-[#e6ba63]">${up.icon} ${up.name}</h3>
                    <span class="text-xs font-bold px-2 py-0.5 rounded bg-[#231d26] border border-stone-700 text-stone-200">Poziom ${lv} / ${up.maxLv}</span>
                </div>
                <p class="text-xs text-stone-300 leading-relaxed">${up.desc}</p>
            </div>
            ${maxed
                ? '<div class="text-xs text-emerald-400 font-bold text-center py-2 bg-emerald-950/30 border border-emerald-800/50 rounded">✓ MAKSYMALNY POZIOM</div>'
                : `<div class="space-y-2 border-t border-stone-800 pt-2.5">
                    <div class="flex flex-wrap gap-2 text-[11px]">
                        <span class="${profile.gold >= cost.gold ? 'text-[#e6ba63]' : 'text-red-400'}">🪙 ${cost.gold} zł</span>
                        ${cost.iron > 0 ? `<span class="${countMaterial('iron') >= cost.iron ? 'text-stone-200' : 'text-red-400'}">⚒️ ${cost.iron} Żelaza</span>` : ''}
                        ${cost.ash > 0 ? `<span class="${countMaterial('ash') >= cost.ash ? 'text-orange-300' : 'text-red-400'}">🔥 ${cost.ash} Popiołu</span>` : ''}
                        ${cost.relic > 0 ? `<span class="${countMaterial('relic') >= cost.relic ? 'text-emerald-300' : 'text-red-400'}">🏺 ${cost.relic} Reliktów</span>` : ''}
                    </div>
                    <button class="upg-btn w-full ember-btn rounded py-2 text-xs font-bold" ${canAfford ? '' : 'disabled'}>Rozbuduj do poziomu ${lv + 1}</button>
                </div>`
            }
        `;
        const btn = card.querySelector('.upg-btn');
        if (btn) {
            btn.onclick = () => {
                if (!canAfford) return;
                profile.gold -= cost.gold;
                consumeMaterial('iron', cost.iron);
                consumeMaterial('ash', cost.ash);
                consumeMaterial('relic', cost.relic);
                profile.stronghold[up.id]++;
                SFX.extractDone();
                showToast(`🏰 Ulepszono: ${up.name} (Poz. ${profile.stronghold[up.id]})!`, 'success');
                saveProfile(); refreshHub();
            };
        }
        grid.appendChild(card);
    }
}

function renderSkills() {
    const grid = document.getElementById('skills-grid');
    grid.innerHTML = '';
    for (const def of Object.values(SKILLS_DEF)) {
        const sk = profile.skills[def.id];
        const req = sk.lv * 100;
        const pct = Math.min(100, Math.round((sk.xp / req) * 100));
        const card = document.createElement('div');
        card.className = 'dark-panel rounded-lg p-3.5 space-y-2';
        card.innerHTML = `
            <div class="flex items-center justify-between">
                <span class="font-fantasy font-bold text-sm text-[#e6ba63]">${def.icon} ${def.name}</span>
                <span class="text-xs font-bold text-stone-200">Poziom ${sk.lv}</span>
            </div>
            <div class="text-[11px] text-stone-300">${def.bonusDesc}</div>
            <div>
                <div class="flex justify-between text-[10px] text-stone-400 mb-1">
                    <span>Doświadczenie</span>
                    <span>${Math.floor(sk.xp)} / ${req} PD</span>
                </div>
                <div class="w-full h-2 bg-[#0d0b0f] rounded overflow-hidden border border-stone-800">
                    <div class="h-full bg-gradient-to-r from-[#a84520] to-[#e6ba63]" style="width:${pct}%"></div>
                </div>
            </div>
        `;
        grid.appendChild(card);
    }
}

function refreshHub() {
    updateHeader();
    renderZones();
    renderPreRaid();
    renderInventoryTab();
    renderMerchant();
    renderStronghold();
    renderSkills();
}
