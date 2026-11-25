// ==================== 3. SEEDED PRNG ====================
function hashSeed(str) {
    let h = 2166136261 >>> 0;
    for (let i = 0; i < str.length; i++) {
        h ^= str.charCodeAt(i);
        h = Math.imul(h, 16777619);
    }
    return h >>> 0;
}
function mulberry32(a) {
    return function() {
        let t = a += 0x6D2B79F5;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}
function randomSeedStr() {
    const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let s = '';
    for (let i = 0; i < 6; i++) s += c[Math.floor(Math.random() * c.length)];
    return s;
}

// ==================== 4. PERSISTENT PROFILE & HELPERS ====================
const SAVE_KEY = 'warownia_popiolow_save_v1';

function makeItem(id, qty = null) {
    const def = ITEMS_DB[id];
    if (!def) return null;
    const inst = { uid: Math.random().toString(36).slice(2, 10), id };
    if (def.type === 'arrow') inst.qty = qty !== null ? qty : def.stackSize;
    if (def.type === 'armor') inst.durability = def.maxDurability;
    return inst;
}

function defaultProfile() {
    return {
        gold: 650,
        stats: { raids: 0, survived: 0, kills: 0, parries: 0 },
        stronghold: { forge: 0, alchemist: 0, altar: 0, vault: 0 },
        skills: {
            melee: { lv: 1, xp: 0 },
            parry: { lv: 1, xp: 0 },
            endurance: { lv: 1, xp: 0 },
            archery: { lv: 1, xp: 0 },
            scavenger: { lv: 1, xp: 0 }
        },
        loadout: {
            weapon: makeItem('rusty_sword'),
            shield: makeItem('wood_buckler'),
            bow: makeItem('hunter_bow'),
            armor: makeItem('leather_jerkin'),
            backpack: [
                makeItem('iron_arrows', 16),
                makeItem('ember_flask'),
                makeItem('ember_flask'),
                makeItem('stamina_tonic'),
                makeItem('ash_salve')
            ],
            reliquary: [
                makeItem('ember_flask')
            ]
        },
        stash: [
            makeItem('steel_falchion'),
            makeItem('iron_arrows', 16),
            makeItem('ember_flask'),
            makeItem('iron_ingot'),
            makeItem('ash_essence'),
            makeItem('silver_goblet')
        ]
    };
}

let profile = loadProfile();
let selectedZoneId = 'catacombs';
let currentSeed = randomSeedStr();
let merchantCat = 'all';

function loadProfile() {
    try {
        const raw = localStorage.getItem(SAVE_KEY);
        if (!raw) return defaultProfile();
        const p = JSON.parse(raw);
        if (!p || !p.loadout || !p.stronghold || !p.skills) return defaultProfile();
        return p;
    } catch (e) {
        return defaultProfile();
    }
}
function saveProfile() {
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(profile)); } catch (e) {}
}

function getMaxStash() { return 24 + profile.stronghold.vault * 8; }
function getMaxReliquary() { return 2 + profile.stronghold.vault; }

function countMaterial(matKind) {
    const all = [...profile.stash, ...profile.loadout.backpack, ...profile.loadout.reliquary];
    return all.filter(it => it && ITEMS_DB[it.id].matKind === matKind).length;
}
function consumeMaterial(matKind, count) {
    let left = count;
    const pools = [profile.stash, profile.loadout.backpack, profile.loadout.reliquary];
    for (const arr of pools) {
        for (let i = arr.length - 1; i >= 0 && left > 0; i--) {
            if (ITEMS_DB[arr[i].id].matKind === matKind) {
                arr.splice(i, 1);
                left--;
            }
        }
    }
}

function addSkillXp(skillId, amount) {
    const sk = profile.skills[skillId];
    if (!sk) return;
    sk.xp += amount;
    const req = sk.lv * 100;
    if (sk.xp >= req) {
        sk.xp -= req;
        sk.lv++;
        showToast(`📜 Awans: ${SKILLS_DEF[skillId].name} (Poziom ${sk.lv})!`, 'success');
    }
}
