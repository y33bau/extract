// ==================== 1. DATABASE: ITEMS, ZONES, UPGRADES, SKILLS ====================
const ITEMS_DB = {
    // Melee Weapons
    rusty_sword: {
        id: 'rusty_sword', name: 'Zardzewiały Miecz', type: 'weapon', rarity: 'common', price: 180, forgeReq: 0,
        dmg: 22, range: 1.55, arc: 1.35, stamina: 14, cooldown: 0.34, desc: 'Wysłużone ostrze wygnańca. Szybkie i niezawodne.'
    },
    steel_falchion: {
        id: 'steel_falchion', name: 'Stalowy Kordelas', type: 'weapon', rarity: 'uncommon', price: 480, forgeReq: 0,
        dmg: 30, range: 1.65, arc: 1.5, stamina: 16, cooldown: 0.32, desc: 'Zakrzywiona stal dobrze wyważona do szybkich kombinacji.'
    },
    warden_glaive: {
        id: 'warden_glaive', name: 'Glewia Strażnika', type: 'weapon', rarity: 'rare', price: 980, forgeReq: 1,
        dmg: 40, range: 2.05, arc: 1.45, stamina: 21, cooldown: 0.44, desc: 'Długa broń drzewcowa o szerokim zasięgu cięcia.'
    },
    ash_greatsword: {
        id: 'ash_greatsword', name: 'Czarny Miecz Popiołów', type: 'weapon', rarity: 'epic', price: 1850, forgeReq: 2,
        dmg: 54, range: 1.95, arc: 1.75, stamina: 24, cooldown: 0.48, desc: 'Wykuty w żarze miecz o potężnej sile przełamującej.'
    },
    executioner_axe: {
        id: 'executioner_axe', name: 'Topór Popielnego Kata', type: 'weapon', rarity: 'legendary', price: 3200, forgeReq: 3,
        dmg: 70, range: 1.85, arc: 1.8, stamina: 28, cooldown: 0.54, desc: 'Legendarny topór bojowy zadający druzgocące ciosy.'
    },

    // Shields
    wood_buckler: {
        id: 'wood_buckler', name: 'Drewniany Puklerz', type: 'shield', rarity: 'common', price: 160, forgeReq: 0,
        blockRed: 0.62, parryBonus: 0.05, desc: 'Lekka tarcza ułatwiająca parowanie ciosów.'
    },
    iron_kite: {
        id: 'iron_kite', name: 'Żelazna Tarcza', type: 'shield', rarity: 'rare', price: 620, forgeReq: 1,
        blockRed: 0.80, parryBonus: 0.04, desc: 'Solidna tarcza rycerska pochłaniająca 80% obrażeń.'
    },
    ash_aegis: {
        id: 'ash_aegis', name: 'Pawęż Popielnej Gwardii', type: 'shield', rarity: 'epic', price: 1450, forgeReq: 2,
        blockRed: 0.92, parryBonus: 0.07, desc: 'Mistrzowska tarcza wykuta z ciemnej stali. Niemal pełna ochrona.'
    },

    // Bows & Arrows
    hunter_bow: {
        id: 'hunter_bow', name: 'Łuk Myśliwski', type: 'bow', rarity: 'common', price: 240, forgeReq: 0,
        dmg: 24, speed: 24, range: 13, stamina: 15, desc: 'Prosty łuk pomocniczy do eliminowania łuczników i wabienia wrogów.'
    },
    yew_longbow: {
        id: 'yew_longbow', name: 'Długi Łuk Cisowy', type: 'bow', rarity: 'rare', price: 780, forgeReq: 1,
        dmg: 38, speed: 28, range: 16, stamina: 18, desc: 'Potężny łuk wojenny przebijający lekkie pancerze.'
    },
    shadow_bow: {
        id: 'shadow_bow', name: 'Łuk Cienia', type: 'bow', rarity: 'epic', price: 1650, forgeReq: 2,
        dmg: 52, speed: 32, range: 18, stamina: 16, desc: 'Szybki łuk z czarnego drewna o śmiertelnej celności.'
    },
    iron_arrows: {
        id: 'iron_arrows', name: 'Strzały Żelazne', type: 'arrow', rarity: 'common', price: 85, stackSize: 16, forgeReq: 0,
        desc: 'Kołczan 16 ostrych strzał. Wystrzeliwane klawiszem [Q].'
    },

    // Armor (Tiers 1-3)
    leather_jerkin: {
        id: 'leather_jerkin', name: 'Skórzany Kaftan (Kl. 1)', type: 'armor', rarity: 'common', price: 280, forgeReq: 0,
        tier: 1, maxDurability: 50, reduction: 0.24, desc: 'Lekka zbroja zapewniająca podstawową ochronę (24% redukcji).'
    },
    chainmail_hauberk: {
        id: 'chainmail_hauberk', name: 'Kolczuga Strażnika (Kl. 2)', type: 'armor', rarity: 'rare', price: 860, forgeReq: 1,
        tier: 2, maxDurability: 90, reduction: 0.42, desc: 'Gęsto pleciona kolczuga (42% redukcji obrażeń).'
    },
    ash_plate: {
        id: 'ash_plate', name: 'Pancerz Popielnego Rycerza (Kl. 3)', type: 'armor', rarity: 'epic', price: 1950, forgeReq: 2,
        tier: 3, maxDurability: 140, reduction: 0.58, desc: 'Ciężki pancerz płytowy wykuty w popiele (58% redukcji).'
    },

    // Elixirs
    ember_flask: {
        id: 'ember_flask', name: 'Flaszka Żaru', type: 'elixir', elixKind: 'heal', rarity: 'uncommon', price: 140, forgeReq: 0,
        healAmount: 55, desc: 'Przywraca 55 pkt. Żywotności (wzmacniane przez Alchemika). Klawisz [1].'
    },
    stamina_tonic: {
        id: 'stamina_tonic', name: 'Tonik Wytrzymałości', type: 'elixir', elixKind: 'stamina', rarity: 'common', price: 95, forgeReq: 0,
        desc: 'Natychmiast odnawia Wytrzymałość i przyspiesza jej regenerację na 12 sek. Klawisz [2].'
    },
    ash_salve: {
        id: 'ash_salve', name: 'Maść z Popiołu', type: 'elixir', elixKind: 'salve', rarity: 'common', price: 80, forgeReq: 0,
        desc: 'Gasi poparzenie/krwawienie i leczy 18 pkt. Żywotności. Klawisz [3].'
    },

    // Stronghold Materials
    iron_ingot: {
        id: 'iron_ingot', name: 'Sztaba Żelaza', type: 'material', matKind: 'iron', rarity: 'uncommon', price: 190,
        desc: 'Ciężka sztaba kowalska używana do rozbudowy Warowni.'
    },
    ash_essence: {
        id: 'ash_essence', name: 'Esencja Popiołu', type: 'material', matKind: 'ash', rarity: 'rare', price: 320,
        desc: 'Żarząca się esencja dusz potrzebna do ulepszania Ołtarza i Alchemika.'
    },
    ancient_relic: {
        id: 'ancient_relic', name: 'Starożytny Relikt', type: 'material', matKind: 'relic', rarity: 'epic', price: 750,
        desc: 'Rzadki artefakt z głębin krypt. Kluczowy dla zaawansowanych ulepszeń Warowni.'
    },

    // Pure Valuables
    silver_goblet: {
        id: 'silver_goblet', name: 'Srebrny Kielich', type: 'valuable', rarity: 'common', price: 220,
        desc: 'Zaśniedziały kielich ze starej uczty. Cenny u Kupca.'
    },
    runic_ring: {
        id: 'runic_ring', name: 'Runiczny Pierścień', type: 'valuable', rarity: 'rare', price: 540,
        desc: 'Złoty sygnet wyryty zapomnianymi runami.'
    },
    golden_idol: {
        id: 'golden_idol', name: 'Złoty Bożek Katakumb', type: 'valuable', rarity: 'epic', price: 1180,
        desc: 'Ciężka figurka z pradawnego sarkofagu.'
    },
    ash_crown: {
        id: 'ash_crown', name: 'Korona Popielnego Króla', type: 'valuable', rarity: 'legendary', price: 2800,
        desc: 'Mityczne trofeum zdobyte na Popielnym Strażniku. Warte fortunę!'
    }
};

const ZONES = [
    {
        id: 'catacombs',
        name: 'Zrujnowane Katakumby',
        subtitle: 'Mroczne korytarze i stare krypty',
        diff: 'POCZĄTKUJĄCA',
        diffColor: 'text-emerald-400',
        lootStars: '★★☆',
        enemyCount: 9,
        hasBoss: false,
        palette: { floor1: '#2e2b30', floor2: '#373339', moss: '#2c362c', wallTop: '#524b54', wallL: '#3d3740', wallR: '#29242b' },
        desc: 'Zniszczone katakumby pełne zwiadowców i pierwszych skrzyń. Idealne do nauki parowania.'
    },
    {
        id: 'outskirts',
        name: 'Kamienne Podgrodzie',
        subtitle: 'Zawalony dziedziniec i mury strażnicze',
        diff: 'ŚREDNIA',
        diffColor: 'text-[#e6ba63]',
        lootStars: '★★★',
        enemyCount: 12,
        hasBoss: false,
        palette: { floor1: '#33302c', floor2: '#3d3934', moss: '#363d2d', wallTop: '#5c554c', wallL: '#453f38', wallR: '#2e2a25' },
        desc: 'Ruiny podgrodzia: Upadli Gwardziści, Kusznicy Cienia, Zakonni Rycerze i pierwsi Katowie Ruin.'
    },
    {
        id: 'crypt',
        name: 'Krypta Popielnego Króla',
        subtitle: 'Sanktuarium żaru i legowisko Bossa',
        diff: 'TRUDNA (BOSS)',
        diffColor: 'text-red-400',
        lootStars: '★★★★',
        enemyCount: 14,
        hasBoss: true,
        palette: { floor1: '#2b2426', floor2: '#362c2f', moss: '#3d2824', wallTop: '#544346', wallL: '#3d2f32', wallR: '#261d1f' },
        desc: 'Najgłębsze kręgi ruin. Strzeżone przez potężnego Popielnego Strażnika. Najcenniejsze relikty.'
    }
];

const STRONGHOLD_UPGRADES = {
    forge: {
        id: 'forge', name: 'Kuźnia', icon: '⚒️', maxLv: 3,
        desc: 'Zwiększa obrażenia broni białej (+12% na poziom) i odblokowuje wyższe klasy oręża u Kupca.',
        costs: [
            { gold: 450, iron: 2, ash: 0, relic: 0 },
            { gold: 1100, iron: 4, ash: 2, relic: 0 },
            { gold: 2200, iron: 6, ash: 4, relic: 2 }
        ]
    },
    alchemist: {
        id: 'alchemist', name: 'Alchemik', icon: '⚗️', maxLv: 3,
        desc: 'Zwiększa moc leczenia Flaszek Żaru (+22% na poziom) i daje darmowe uzupełnienie 1 flaszki po każdej wyprawie.',
        costs: [
            { gold: 400, iron: 1, ash: 2, relic: 0 },
            { gold: 950, iron: 2, ash: 4, relic: 1 },
            { gold: 1900, iron: 3, ash: 6, relic: 2 }
        ]
    },
    altar: {
        id: 'altar', name: 'Ołtarz Żaru', icon: '🔥', maxLv: 3,
        desc: 'Zwiększa maks. Żywotność (+18), Wytrzymałość (+15) oraz wydłuża okno Parowania (+0.04s na poziom).',
        costs: [
            { gold: 500, iron: 1, ash: 2, relic: 0 },
            { gold: 1200, iron: 2, ash: 4, relic: 1 },
            { gold: 2400, iron: 4, ash: 6, relic: 2 }
        ]
    },
    vault: {
        id: 'vault', name: 'Skarbiec', icon: '🏰', maxLv: 3,
        desc: 'Rozszerza Skrytkę Warowni (+8 miejsc na poziom) i dodaje +1 chronione miejsce w Relikwiarzu.',
        costs: [
            { gold: 550, iron: 3, ash: 0, relic: 0 },
            { gold: 1300, iron: 5, ash: 2, relic: 1 },
            { gold: 2600, iron: 7, ash: 3, relic: 2 }
        ]
    }
};

const SKILLS_DEF = {
    melee:     { id: 'melee',     name: 'Fechtunek',             icon: '⚔️', bonusDesc: '+6% obrażeń bronią białą / poz.' },
    parry:     { id: 'parry',     name: 'Mistrzostwo Parowania', icon: '✨', bonusDesc: '+15% obrażeń Riposty i szersze okno parowania / poz.' },
    endurance: { id: 'endurance', name: 'Wytrzymałość',          icon: '⚡', bonusDesc: '+8% regeneracji staminy i tańsze uniki / poz.' },
    archery:   { id: 'archery',   name: 'Łucznictwo',            icon: '🏹', bonusDesc: '+8% obrażeń łuku i szybsze strzały / poz.' },
    scavenger: { id: 'scavenger', name: 'Poszukiwacz Reliktów',  icon: '🗝️', bonusDesc: '+15% szybsze przeszukiwanie i lepsze łupy / poz.' }
};
