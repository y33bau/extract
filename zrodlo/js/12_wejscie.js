// ==================== 17. INPUT & EVENT LISTENERS ====================
window.addEventListener('keydown', e => {
    keys[e.code] = true;
    if (!raid || raid.ended) return;

    if (e.code === 'Tab' || e.code === 'KeyI') {
        e.preventDefault();
        raid.modalOpen ? closeRaidModal() : openRaidModal(null);
    } else if (e.code === 'Escape' && raid.modalOpen) {
        closeRaidModal();
    } else if (!raid.modalOpen) {
        if (e.code === 'Space') { e.preventDefault(); performDodge(); }
        else if (e.code === 'KeyQ') performBowShot();
        else if (e.code === 'KeyE') {
            const near = findNearestInteractable();
            if (near) openRaidModal(near);
        }
        else if (e.code === 'Digit1') useElixir('heal');
        else if (e.code === 'Digit2') useElixir('stamina');
        else if (e.code === 'Digit3') useElixir('salve');
    }
});
window.addEventListener('keyup', e => { keys[e.code] = false; });

canvas.addEventListener('mousemove', e => {
    const r = canvas.getBoundingClientRect();
    mouse.x = e.clientX - r.left;
    mouse.y = e.clientY - r.top;
});
canvas.addEventListener('mousedown', e => {
    if (!raid || raid.ended || raid.modalOpen) return;
    SFX.init();
    if (e.button === 0) { mouse.lmb = true; performMeleeAttack(); }
    else if (e.button === 2) { mouse.rmb = true; triggerParryStart(); }
});
window.addEventListener('mouseup', e => {
    if (e.button === 0) mouse.lmb = false;
    if (e.button === 2) { mouse.rmb = false; if (raid) raid.player.blocking = false; }
});
canvas.addEventListener('contextmenu', e => e.preventDefault());

// Hub Navigation Tabs
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.onclick = () => {
        SFX.ui();
        const target = btn.dataset.tab;
        document.querySelectorAll('.tab-btn').forEach(b => {
            b.className = `tab-btn ${b.dataset.tab === target ? 'ember-btn' : 'iron-btn'} rounded px-4 py-2 text-xs sm:text-sm font-bold tracking-wide whitespace-nowrap`;
        });
        ['expedition', 'inventory', 'merchant', 'stronghold', 'skills'].forEach(id => {
            document.getElementById('tab-' + id).classList.toggle('hidden', id !== target);
        });
        refreshHub();
    };
});

// Merchant Category Filter
document.querySelectorAll('.merch-cat-btn').forEach(btn => {
    btn.onclick = () => {
        SFX.ui();
        merchantCat = btn.dataset.cat;
        document.querySelectorAll('.merch-cat-btn').forEach(b => {
            b.className = `merch-cat-btn ${b.dataset.cat === merchantCat ? 'ember-btn' : 'iron-btn'} rounded px-2.5 py-1 text-xs`;
        });
        renderMerchant();
    };
});

// Hub Buttons
document.getElementById('btn-random-seed').onclick = () => {
    SFX.ui();
    currentSeed = randomSeedStr();
    document.getElementById('seed-input').value = currentSeed;
};
document.getElementById('btn-start-raid').onclick = startRaid;
document.getElementById('btn-mute-hub').onclick = () => SFX.toggleMute();
document.getElementById('btn-mute-raid').onclick = () => SFX.toggleMute();
document.getElementById('btn-raid-inv').onclick = () => raid && (raid.modalOpen ? closeRaidModal() : openRaidModal(null));
document.getElementById('btn-close-raid-modal').onclick = closeRaidModal;
document.getElementById('btn-elix-1').onclick = () => useElixir('heal');
document.getElementById('btn-elix-2').onclick = () => useElixir('stamina');
document.getElementById('btn-elix-3').onclick = () => useElixir('salve');

document.getElementById('btn-loot-all').onclick = () => {
    if (!raid || !raid.activeLoot) return;
    while (raid.activeLoot.items.length > 0 && raid.player.loadout.backpack.length < 12) {
        takeLootItem(0, false);
    }
};

document.getElementById('btn-sort-stash').onclick = () => {
    const order = { weapon: 1, shield: 2, bow: 3, armor: 4, arrow: 5, elixir: 6, material: 7, valuable: 8 };
    profile.stash.sort((a, b) => (order[ITEMS_DB[a.id].type] || 9) - (order[ITEMS_DB[b.id].type] || 9));
    SFX.ui(); saveProfile(); refreshHub();
};

document.getElementById('btn-sell-valuables').onclick = () => {
    let gained = 0, sold = 0;
    for (const arr of [profile.stash, profile.loadout.backpack]) {
        for (let i = arr.length - 1; i >= 0; i--) {
            const def = ITEMS_DB[arr[i].id];
            if (def.type === 'valuable') {
                gained += Math.floor(def.price * 0.65);
                arr.splice(i, 1);
                sold++;
            }
        }
    }
    if (sold === 0) return showToast('Brak kosztowności na sprzedaż.', 'info');
    profile.gold += gained;
    SFX.loot(); showToast(`Sprzedano ${sold} kosztowności za ${gained} zł!`, 'success');
    saveProfile(); refreshHub();
};

document.getElementById('btn-starter-kit').onclick = () => {
    profile.loadout.weapon = makeItem('rusty_sword');
    profile.loadout.shield = makeItem('wood_buckler');
    if (profile.loadout.backpack.length < 12) profile.loadout.backpack.push(makeItem('ember_flask'));
    SFX.loot(); showToast('Otrzymano darmowy Zestaw Wygnańca!', 'success');
    saveProfile(); refreshHub();
};

document.getElementById('btn-return-hub').onclick = () => {
    raid = null;
    document.getElementById('raid-screen').classList.add('hidden');
    document.getElementById('hub-screen').classList.remove('hidden');
    refreshHub();
};

// Reset modal
document.getElementById('btn-reset-hub').onclick = () => document.getElementById('reset-modal').classList.remove('hidden');
document.getElementById('btn-cancel-reset').onclick = () => document.getElementById('reset-modal').classList.add('hidden');
document.getElementById('btn-confirm-reset').onclick = () => {
    localStorage.removeItem(SAVE_KEY);
    profile = defaultProfile();
    document.getElementById('reset-modal').classList.add('hidden');
    showToast('Kronika Warowni została zresetowana.', 'warn');
    refreshHub();
};

// Boot directly into Stronghold Hub
window.onload = () => {
    resizeCanvas();
    refreshHub();
};
