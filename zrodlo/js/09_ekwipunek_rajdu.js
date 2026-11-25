// ==================== 13. IN-RAID INVENTORY & LOOT MODAL ====================
function openRaidModal(box = null) {
    raid.modalOpen = true;
    raid.activeLoot = box;
    raid.searchProg = 0;
    mouse.lmb = false; mouse.rmb = false;
    raid.player.blocking = false;
    if (box) SFX.loot();
    document.getElementById('raid-modal').classList.remove('hidden');
    renderRaidModal();
}
function closeRaidModal() {
    if (!raid) return;
    raid.modalOpen = false;
    raid.activeLoot = null;
    hideTooltip();
    document.getElementById('raid-modal').classList.add('hidden');
}

function renderRaidModal() {
    if (!raid || !raid.modalOpen) return;
    const l = raid.player.loadout;
    const maxRel = getMaxReliquary();

    document.getElementById('rm-gear-1').textContent = `${l.weapon ? ITEMS_DB[l.weapon.id].name : 'Brak'} / ${l.shield ? ITEMS_DB[l.shield.id].name : 'Brak'}`;
    document.getElementById('rm-gear-2').textContent = `${l.bow ? ITEMS_DB[l.bow.id].name : 'Brak'} / ${l.armor ? ITEMS_DB[l.armor.id].name : 'Brak'}`;

    const relEl = document.getElementById('rm-reliquary-grid');
    relEl.innerHTML = '';
    for (let i = 0; i < maxRel; i++) {
        const it = l.reliquary[i] || null;
        relEl.appendChild(makeSlotEl(it, 'slot-reliquary', () => {
            if (l.backpack.length >= 12) return showToast('Sakwa jest pełna!', 'warn');
            l.backpack.push(l.reliquary.splice(i, 1)[0]);
            SFX.ui(); hideTooltip(); renderRaidModal(); updateRaidHUD();
        }));
    }

    document.getElementById('rm-bp-count').textContent = l.backpack.length;
    const bpEl = document.getElementById('rm-bp-grid');
    bpEl.innerHTML = '';
    for (let i = 0; i < 12; i++) {
        const it = l.backpack[i] || null;
        const slot = makeSlotEl(it, '', e => {
            const def = ITEMS_DB[it.id];
            if (e.shiftKey) {
                if (l.reliquary.length >= maxRel) return showToast('Relikwiarz jest pełny!', 'warn');
                l.reliquary.push(l.backpack.splice(i, 1)[0]);
                SFX.ui();
            } else if (def.type === 'elixir') {
                closeRaidModal(); useElixir(def.elixKind); return;
            } else if (['weapon', 'shield', 'bow', 'armor'].includes(def.type)) {
                const old = l[def.type];
                l[def.type] = l.backpack.splice(i, 1)[0];
                if (old) l.backpack.push(old);
                SFX.ui();
            }
            hideTooltip(); renderRaidModal(); updateRaidHUD();
        });
        if (it) {
            slot.oncontextmenu = e => {
                e.preventDefault();
                l.backpack.splice(i, 1);
                SFX.ui(); hideTooltip(); renderRaidModal(); updateRaidHUD();
            };
        }
        bpEl.appendChild(slot);
    }

    const titleEl = document.getElementById('rm-loot-title');
    const gridEl = document.getElementById('rm-loot-grid');
    const allBtn = document.getElementById('btn-loot-all');
    const searchBox = document.getElementById('rm-search-status');
    gridEl.innerHTML = '';

    if (!raid.activeLoot) {
        titleEl.textContent = 'BRAK POJEMNIKA';
        allBtn.classList.add('hidden');
        searchBox.classList.add('hidden');
        gridEl.innerHTML = '<div class="col-span-2 text-xs text-stone-500 py-8 text-center">Podejdź do skrzyni, sarkofagu lub pokonanego wroga i naciśnij [E].</div>';
        return;
    }

    const box = raid.activeLoot;
    titleEl.textContent = box.name.toUpperCase();
    const hasHidden = box.items.some(e => !e.revealed);
    searchBox.classList.toggle('hidden', !hasHidden);
    allBtn.classList.toggle('hidden', hasHidden || box.items.length === 0);

    if (box.items.length === 0) {
        gridEl.innerHTML = '<div class="col-span-2 text-xs text-stone-500 py-8 text-center">Pusto.</div>';
    } else {
        box.items.forEach((entry, idx) => {
            if (!entry.revealed) {
                const hs = document.createElement('div');
                hs.className = 'slot-cell rounded p-2 h-16 flex flex-col items-center justify-center text-stone-500 animate-pulse';
                hs.innerHTML = '<span class="text-base">❓</span><span class="text-[9px]">Przeszukiwanie...</span>';
                gridEl.appendChild(hs);
            } else {
                gridEl.appendChild(makeSlotEl(entry.item, '', e => takeLootItem(idx, e.shiftKey)));
            }
        });
    }
}

function takeLootItem(idx, toRel = false) {
    if (!raid || !raid.activeLoot) return;
    const entry = raid.activeLoot.items[idx];
    if (!entry || !entry.revealed) return;
    const l = raid.player.loadout;
    const it = entry.item;

    if (toRel) {
        if (l.reliquary.length >= getMaxReliquary()) return showToast('Relikwiarz jest pełny!', 'warn');
        l.reliquary.push(it);
    } else {
        if (it.id === 'iron_arrows') {
            const ex = l.backpack.find(b => b.id === 'iron_arrows' && b.qty < 32);
            if (ex) {
                ex.qty += it.qty;
                raid.activeLoot.items.splice(idx, 1);
                SFX.loot(); hideTooltip(); renderRaidModal(); updateRaidHUD();
                return;
            }
        }
        if (l.backpack.length >= 12) return showToast('Sakwa jest pełna (12/12)!', 'warn');
        l.backpack.push(it);
    }
    raid.activeLoot.items.splice(idx, 1);
    SFX.loot(); addSkillXp('scavenger', 10);
    hideTooltip(); renderRaidModal(); updateRaidHUD();
}

// ==================== 14. RAID END ====================
function endRaid(survived, reason) {
    if (raid.ended) return;
    raid.ended = true;
    closeRaidModal();
    raid.player.dead = !survived && raid.player.hp <= 0;
    raid.deathAnim = 0;
    const revealDelay = raid.player.dead ? 1700 : 0;
    raid.endAt = performance.now() + revealDelay;
    if (raid.player.dead) {
        SFX.hurt();
        document.getElementById('hit-overlay').style.opacity = '1';
    }

    profile.stats.raids++;
    profile.stats.kills += raid.kills;
    profile.stats.parries += raid.parries;

    const l = raid.player.loadout;
    let lootVal = 0;

    if (survived) {
        SFX.extractDone();
        profile.stats.survived++;
        const keepBp = [];
        for (const it of l.backpack) {
            const def = ITEMS_DB[it.id];
            lootVal += Math.floor(def.price * 0.65);
            if ((def.type === 'valuable' || def.type === 'material') && profile.stash.length < getMaxStash()) {
                profile.stash.push(it);
            } else {
                keepBp.push(it);
            }
        }
        l.backpack = keepBp;
        profile.loadout = l;
    } else {
        profile.loadout = { weapon: null, shield: null, bow: null, armor: null, backpack: [], reliquary: l.reliquary };
    }

    // Alchemist upgrade grants a free Ember Flask in stash after raid if space allows
    if (profile.stronghold.alchemist > 0 && profile.stash.length < getMaxStash()) {
        profile.stash.push(makeItem('ember_flask'));
    }
    saveProfile();

    const badge = document.getElementById('res-badge');
    badge.textContent = survived ? '✨ EKSTRAKCJA UDANA' : '💀 POLEGŁEŚ W RUINACH';
    badge.className = `font-fantasy font-extrabold text-xl sm:text-2xl tracking-wider ${survived ? 'text-emerald-400' : 'text-red-500'}`;
    document.getElementById('res-subtitle').textContent = reason;

    const m = Math.floor(raid.elapsed / 60);
    const s = Math.floor(raid.elapsed % 60).toString().padStart(2, '0');
    document.getElementById('res-stats').innerHTML = `
        <div class="flex justify-between"><span class="text-stone-400">Kraina:</span><span class="text-stone-100 font-bold">${raid.zone.name} (${raid.seed})</span></div>
        <div class="flex justify-between"><span class="text-stone-400">Czas wyprawy:</span><span class="text-stone-100">${m}:${s}</span></div>
        <div class="flex justify-between"><span class="text-stone-400">Pokonani wrogowie:</span><span class="text-red-400 font-bold">${raid.kills}</span></div>
        <div class="flex justify-between"><span class="text-stone-400">Udane parowania:</span><span class="text-[#e6ba63] font-bold">${raid.parries}</span></div>
        <div class="flex justify-between"><span class="text-stone-400">Rynsztunek:</span><span class="${survived ? 'text-emerald-400' : 'text-red-400'} font-bold">${survived ? 'Zabezpieczony w Warowni' : 'Utracono (Relikwiarz ocalał)'}</span></div>
        ${survived ? `<div class="flex justify-between"><span class="text-stone-400">Wartość łupu z sakwy:</span><span class="text-[#e6ba63] font-bold">🪙 ${lootVal} zł</span></div>` : ''}
    `;
    const endedRaid = raid;
    setTimeout(() => {
        if (raid !== endedRaid) return;
        document.getElementById('result-modal').classList.remove('hidden');
    }, revealDelay);
}
