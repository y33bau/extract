extends RefCounted
## Generator lochu z ziarna. Trzy osobne strumienie losowania (układ / łupy / wrogowie),
## żeby zmiana w jednym nie przetasowała pozostałych.

const ROZMIAR := 42
enum K { PODLOGA, SCIEZKA, MUR, FILAR, KOSZ, GRUZ, EKSTRAKCJA }

const PULE_LUPU := {
	"loot_chest": ["iron_ingot", "iron_arrows", "ember_flask", "stamina_tonic", "ash_salve", "silver_goblet", "steel_falchion", "iron_kite", "yew_longbow"],
	"loot_sarcophagus": ["ash_essence", "ancient_relic", "runic_ring", "golden_idol", "ash_greatsword", "ash_plate", "ember_flask"],
	"loot_knight": ["iron_ingot", "iron_arrows", "chainmail_hauberk", "warden_glaive", "iron_kite", "ash_salve", "silver_goblet"],
}
const NAZWY := {"loot_chest": "Okuta Skrzynia", "loot_sarcophagus": "Kamienny Sarkofag", "loot_knight": "Szczątki Rycerza"}
const RZADKIE := ["ancient_relic", "golden_idol", "ash_greatsword", "ash_plate"]

var siatka := PackedByteArray()
var wariant := PackedByteArray()
var skrzynie: Array = []      # {tx, ty, w: Vector2, rodzaj, nazwa, przedmioty: [{przedmiot, odkryty}]}
var ekstrakcje: Array = []    # {w: Vector2, nazwa, promien}
var kosze: Array = []         # Vector2
var start := Vector2.ZERO
var rng_uklad := RandomNumberGenerator.new()
var rng_lup := RandomNumberGenerator.new()
var rng_wrogowie := RandomNumberGenerator.new()


static func blokuje_ruch(t: int) -> bool:
	return t == K.MUR or t == K.FILAR or t == K.KOSZ or t == K.GRUZ


static func blokuje_wzrok(t: int) -> bool:
	return t == K.MUR or t == K.FILAR


func idx(x: int, y: int) -> int:
	return y * ROZMIAR + x


func kafel(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= ROZMIAR or y >= ROZMIAR:
		return K.MUR
	return siatka[idx(x, y)]


func generuj(kraina: Dictionary, ziarno: String, poziom_poszukiwacza: int) -> void:
	var baza := (ziarno + "_" + str(kraina["id"])).hash()
	rng_uklad.seed = baza
	rng_lup.seed = baza ^ 0x5bd1e995
	rng_wrogowie.seed = baza ^ 0x2545f491
	var r := rng_uklad
	siatka.resize(ROZMIAR * ROZMIAR)
	siatka.fill(K.PODLOGA)
	wariant.resize(ROZMIAR * ROZMIAR)
	for i in wariant.size():
		wariant[i] = r.randi_range(0, 2)
	for i in ROZMIAR:
		siatka[idx(i, 0)] = K.MUR
		siatka[idx(i, ROZMIAR - 1)] = K.MUR
		siatka[idx(0, i)] = K.MUR
		siatka[idx(ROZMIAR - 1, i)] = K.MUR

	# Główne aleje
	var sx := ROZMIAR / 2 + int((r.randf() - 0.5) * 6)
	var sy := ROZMIAR / 2 + int((r.randf() - 0.5) * 6)
	for x in range(2, ROZMIAR - 2):
		siatka[idx(x, sy)] = K.SCIEZKA
		siatka[idx(x, sy + 1)] = K.SCIEZKA
	for y in range(2, ROZMIAR - 2):
		siatka[idx(sx, y)] = K.SCIEZKA
		siatka[idx(sx + 1, y)] = K.SCIEZKA

	# Komnaty
	var komnaty: Array = []
	var cel := 8 if kraina["id"] == "catacombs" else (6 if kraina["id"] == "outskirts" else 7)
	var proby := 0
	while proby < cel * 4 and komnaty.size() < cel:
		proby += 1
		var rw := 5 + r.randi_range(0, 4)
		var rh := 5 + r.randi_range(0, 4)
		var rx := 3 + r.randi_range(0, ROZMIAR - rw - 7)
		var ry := 3 + r.randi_range(0, ROZMIAR - rh - 7)
		var ok := true
		for y in range(ry - 1, ry + rh + 1):
			for x in range(rx - 1, rx + rw + 1):
				var t := siatka[idx(x, y)]
				if t == K.SCIEZKA or t == K.MUR:
					ok = false
					break
			if not ok:
				break
		if not ok:
			continue
		for y in range(ry, ry + rh):
			for x in range(rx, rx + rw):
				var brzeg := x == rx or x == rx + rw - 1 or y == ry or y == ry + rh - 1
				siatka[idx(x, y)] = K.MUR if brzeg else K.PODLOGA
		var drzwi := [Vector2i(rx + rw / 2, ry), Vector2i(rx + rw / 2, ry + rh - 1), Vector2i(rx, ry + rh / 2), Vector2i(rx + rw - 1, ry + rh / 2)]
		var otwarte := 0
		for dz in drzwi:
			if r.randf() < 0.72 or otwarte < 2:
				siatka[idx(dz.x, dz.y)] = K.SCIEZKA
				otwarte += 1
		komnaty.append(Rect2i(rx, ry, rw, rh))

	# Filary, gruz, kosze ogniowe
	for y in range(3, ROZMIAR - 3):
		for x in range(3, ROZMIAR - 3):
			if siatka[idx(x, y)] == K.PODLOGA:
				var q := r.randf()
				if q < 0.024:
					siatka[idx(x, y)] = K.FILAR
				elif q < 0.044:
					siatka[idx(x, y)] = K.GRUZ
				elif q < 0.056:
					siatka[idx(x, y)] = K.KOSZ
					kosze.append(Vector2(x + 0.5, y + 0.5))

	# Start i dwa kręgi ekstrakcji po drugiej stronie
	var gora := r.randf() < 0.5
	start = Vector2(4.5, 4.5) if gora else Vector2(4.5, ROZMIAR - 5.5)
	var ex: Array = [[Vector2i(ROZMIAR - 5, ROZMIAR - 6), "Krąg Południowy"], [Vector2i(ROZMIAR - 6, 5), "Brama Wschodnia"]] if gora \
		else [[Vector2i(ROZMIAR - 5, 5), "Krąg Północny"], [Vector2i(ROZMIAR - 6, ROZMIAR - 6), "Ołtarz Powrotu"]]
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			_ustaw_wew(int(start.x) + dx, int(start.y) + dy, K.SCIEZKA)
	var kx := int(start.x) + 2
	var ky := int(start.y) - 1
	siatka[idx(kx, ky)] = K.KOSZ
	kosze.append(Vector2(kx + 0.5, ky + 0.5))
	for e in ex:
		var p: Vector2i = e[0]
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				_ustaw_wew(p.x + dx, p.y + dy, K.SCIEZKA)
		siatka[idx(p.x, p.y)] = K.EKSTRAKCJA
		ekstrakcje.append({"w": Vector2(p.x + 0.5, p.y + 0.5), "nazwa": e[1], "promien": 1.85})

	# Łupy (osobny strumień)
	var szczescie := (poziom_poszukiwacza - 1) * 0.04 + (0.22 if kraina["id"] == "crypt" else (0.1 if kraina["id"] == "outskirts" else 0.0))
	for kom in komnaty:
		var ile := 1 + rng_lup.randi_range(0, 1)
		for i in ile:
			var lx: int = kom.position.x + 1 + rng_lup.randi_range(0, kom.size.x - 3)
			var ly: int = kom.position.y + 1 + rng_lup.randi_range(0, kom.size.y - 3)
			if blokuje_ruch(siatka[idx(lx, ly)]) or _zajete(lx, ly):
				continue
			var q := rng_lup.randf()
			var rodzaj := "loot_sarcophagus" if q < 0.42 else ("loot_chest" if q < 0.78 else "loot_knight")
			_dodaj_skrzynie(lx, ly, rodzaj, szczescie)
	for k in 10:
		var lx := 4 + rng_lup.randi_range(0, ROZMIAR - 9)
		var ly := 4 + rng_lup.randi_range(0, ROZMIAR - 9)
		if siatka[idx(lx, ly)] != K.PODLOGA or _zajete(lx, ly):
			continue
		_dodaj_skrzynie(lx, ly, "loot_chest" if rng_lup.randf() < 0.5 else "loot_knight", szczescie)


func _ustaw_wew(x: int, y: int, t: int) -> void:
	if x >= 1 and y >= 1 and x < ROZMIAR - 1 and y < ROZMIAR - 1:
		siatka[idx(x, y)] = t


func _zajete(x: int, y: int) -> bool:
	for s in skrzynie:
		if s["tx"] == x and s["ty"] == y:
			return true
	return false


func _dodaj_skrzynie(x: int, y: int, rodzaj: String, szczescie: float) -> void:
	var lista: Array = []
	var pula: Array = PULE_LUPU[rodzaj]
	for i in 2 + rng_lup.randi_range(0, 2):
		var id: String = pula[rng_lup.randi_range(0, pula.size() - 1)]
		if id in RZADKIE and rng_lup.randf() > 0.35 + szczescie:
			id = "ash_essence" if rng_lup.randf() < 0.5 else "runic_ring"
		lista.append({"przedmiot": Profil.nowy_przedmiot(id), "odkryty": false})
	skrzynie.append({"tx": x, "ty": y, "w": Vector2(x + 0.5, y + 0.5), "rodzaj": rodzaj, "nazwa": NAZWY[rodzaj], "przedmioty": lista})
