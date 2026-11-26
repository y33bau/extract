extends RefCounted
## Generator lochu z ziarna (wersja 2, „duże mapy”). Trzy osobne strumienie losowania (układ / łupy / wrogowie),
## żeby zmiana w jednym nie przetasowała pozostałych.
## Loch wykuty w litej skale: komnaty różnych rodzajów (krypty, sale filarów, dziedzińce, skarbce, kaplice,
## legowiska) połączone krętymi korytarzami z pętlami. Wszystko osiągalne od startu (sprawdzane BFS).

const ROZMIAR := 128   # decyzja autora 26.11.2026: wszystkie mapy 128×128 m, rajd 20 min
enum K { PODLOGA, SCIEZKA, MUR, FILAR, KOSZ, GRUZ, EKSTRAKCJA, WODA }   # WODA: las (strumień) — blokuje ruch, nie wzrok

const PULE_LUPU := {
	"loot_chest": ["iron_ingot", "iron_arrows", "ember_flask", "stamina_tonic", "ash_salve", "silver_goblet", "steel_falchion", "iron_kite", "yew_longbow"],
	"loot_sarcophagus": ["ash_essence", "ancient_relic", "runic_ring", "golden_idol", "ash_greatsword", "ash_plate", "ember_flask"],
	"loot_knight": ["iron_ingot", "iron_arrows", "chainmail_hauberk", "warden_glaive", "iron_kite", "ash_salve", "silver_goblet"],
}
const NAZWY := {"loot_chest": "Okuta Skrzynia", "loot_sarcophagus": "Kamienny Sarkofag", "loot_knight": "Szczątki Rycerza"}
const RZADKIE := ["ancient_relic", "golden_idol", "ash_greatsword", "ash_plate"]

## Rodzaje komnat: [min szer, max szer, min wys, max wys, waga losowania].
const RODZAJE := {
	"komnata": [7, 11, 7, 11, 30],
	"krypta": [8, 12, 7, 10, 16],
	"sala_filarow": [13, 19, 10, 14, 14],
	"dziedziniec": [15, 21, 14, 19, 8],
	"kaplica": [9, 11, 9, 11, 8],
	"legowisko": [10, 14, 10, 13, 9],
	"skarbiec": [7, 8, 6, 7, 7],
}
## Nazwy kręgów ekstrakcji (pierwszy zawsze najdalej od startu).
const NAZWY_EKSTRAKCJI := ["Ołtarz Powrotu", "Brama Wschodnia", "Krąg Północny", "Studnia Popiołu", "Krąg Południowy"]

var siatka := PackedByteArray()
var wariant := PackedByteArray()
var skrzynie: Array = []      # {tx, ty, w: Vector2, rodzaj, nazwa, przedmioty: [{przedmiot, odkryty}]}
var ekstrakcje: Array = []    # {w: Vector2, nazwa, promien}
var kosze: Array = []         # Vector2
var komnaty: Array = []       # {r: Rect2i (z murem obwodowym), typ: String, srodek: Vector2}
var korytarze: Array = []     # Vector2i — pola korytarzy (dla patroli)
var start := Vector2.ZERO
var komnata_startu := -1
var rng_uklad := RandomNumberGenerator.new()
var rng_lup := RandomNumberGenerator.new()
var rng_wrogowie := RandomNumberGenerator.new()


static func blokuje_ruch(t: int) -> bool:
	return t == K.MUR or t == K.FILAR or t == K.KOSZ or t == K.GRUZ or t == K.WODA


static func blokuje_wzrok(t: int) -> bool:
	return t == K.MUR or t == K.FILAR


func idx(x: int, y: int) -> int:
	return y * ROZMIAR + x


func kafel(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= ROZMIAR or y >= ROZMIAR:
		return K.MUR
	return siatka[idx(x, y)]


## Ile komnat na mapę (zależnie od krainy). Liczby do strojenia.
static func liczba_komnat(id_krainy: String) -> int:
	return {"catacombs": 64, "outskirts": 57, "crypt": 60}.get(id_krainy, 57)   # ×1,78 (pole mapy 128² / 96²), ta sama gęstość


func generuj(kraina: Dictionary, ziarno: String, poziom_poszukiwacza: int) -> void:
	var baza := (ziarno + "_" + str(kraina["id"])).hash()
	rng_uklad.seed = baza
	rng_lup.seed = baza ^ 0x5bd1e995
	rng_wrogowie.seed = baza ^ 0x2545f491
	var r := rng_uklad
	var id_k: String = kraina["id"]
	siatka.resize(ROZMIAR * ROZMIAR)
	siatka.fill(K.MUR)
	wariant.resize(ROZMIAR * ROZMIAR)
	for i in wariant.size():
		wariant[i] = r.randi_range(0, 2)

	# 1. Komnaty: losowe rodzaje, rozstawione bez nakładania (odstęp 2 pola skały).
	var cel := liczba_komnat(id_k)
	var wagi := _wagi_rodzajow(id_k)
	var proby := 0
	while proby < cel * 30 and komnaty.size() < cel:
		proby += 1
		var typ := _losuj_rodzaj(r, wagi, komnaty)
		var d: Array = RODZAJE[typ]
		var rw: int = r.randi_range(d[0], d[1])
		var rh: int = r.randi_range(d[2], d[3])
		var rx := r.randi_range(2, ROZMIAR - rw - 3)
		var ry := r.randi_range(2, ROZMIAR - rh - 3)
		var rect := Rect2i(rx, ry, rw, rh)
		var wolne := true
		for k in komnaty:
			if (k["r"] as Rect2i).grow(2).intersects(rect):
				wolne = false
				break
		if not wolne:
			continue
		komnaty.append({"r": rect, "typ": typ, "srodek": Vector2(rx + rw * 0.5, ry + rh * 0.5)})
	for k in komnaty:
		var rr: Rect2i = k["r"]
		for y in range(rr.position.y + 1, rr.end.y - 1):
			for x in range(rr.position.x + 1, rr.end.x - 1):
				siatka[idx(x, y)] = K.PODLOGA

	# 2. Korytarze: drzewo rozpinające (najbliższe komnaty) + dodatkowe pętle, żeby dało się obejść wroga.
	var polaczenia := _drzewo(komnaty)
	var dodatkowe := int(komnaty.size() * 0.35)
	for i in dodatkowe:
		var a := r.randi_range(0, komnaty.size() - 1)
		var najb := -1
		var nd := 1e9
		for j in komnaty.size():
			if j == a or [a, j] in polaczenia or [j, a] in polaczenia:
				continue
			var dd: float = (komnaty[a]["srodek"] as Vector2).distance_to(komnaty[j]["srodek"])
			if dd < nd and dd < 40.0:
				nd = dd
				najb = j
		if najb >= 0:
			polaczenia.append([a, najb])
	for p in polaczenia:
		_korytarz(komnaty[p[0]], komnaty[p[1]], r)

	# 3. Start: komnata najbliżej losowego narożnika; ekstrakcje: komnaty najdalej od startu (różne strony).
	var narozniki := [Vector2(6, 6), Vector2(ROZMIAR - 6, 6), Vector2(6, ROZMIAR - 6), Vector2(ROZMIAR - 6, ROZMIAR - 6)]
	var nar: Vector2 = narozniki[r.randi_range(0, 3)]
	var najl := 1e9
	for i in komnaty.size():
		if komnaty[i]["typ"] in ["skarbiec", "legowisko"]:
			continue
		var dd: float = (komnaty[i]["srodek"] as Vector2).distance_to(nar)
		if dd < najl:
			najl = dd
			komnata_startu = i
	komnaty[komnata_startu]["typ"] = "start"
	var ks: Rect2i = komnaty[komnata_startu]["r"]
	start = Vector2(ks.position.x + ks.size.x / 2 + 0.5, ks.position.y + ks.size.y / 2 + 0.5)

	# 4. Wystrój komnat według rodzaju (filary, gruz, kosze, sarkofagi).
	for i in komnaty.size():
		_urzadz(i, r)

	# 5. Spójność: wszystko, czego nie da się dojść od startu, zamienia się w skałę.
	_tylko_osiagalne()

	# 6. Ekstrakcje: 3–4 komnaty, najdalsza + rozrzucone (każda co najmniej 22 pola od innych).
	var odl := _odleglosci(Vector2i(int(start.x), int(start.y)))
	var kandydaci: Array = []
	for i in komnaty.size():
		var t: String = komnaty[i]["typ"]
		if t in ["start", "skarbiec", "legowisko"]:
			continue
		var c: Vector2i = _wolne_pole_w(i)
		if c.x < 0:
			continue
		kandydaci.append([odl[idx(c.x, c.y)], c, i])
	kandydaci.sort_custom(func(a, b): return a[0] > b[0])
	var ile_ekstrakcji := 4 if id_k == "crypt" else 3
	for prog in [[40, 29.0], [24, 19.0], [0, 8.0]]:
		for kd in kandydaci:
			if ekstrakcje.size() >= ile_ekstrakcji:
				break
			var c: Vector2i = kd[1]
			if kd[0] < prog[0] or komnaty[kd[2]]["typ"] == "ekstrakcja":
				continue
			var blisko := false
			for e in ekstrakcje:
				if (e["w"] as Vector2).distance_to(Vector2(c) + Vector2(0.5, 0.5)) < prog[1]:
					blisko = true
			if blisko:
				continue
			_postaw_ekstrakcje(c, kd[2])
		if ekstrakcje.size() >= ile_ekstrakcji:
			break
	# kosz przy starcie (światło na pierwsze kroki)
	var kx := int(start.x) + 2
	var ky := int(start.y) - 1
	var przy_przejsciu := false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if kafel(kx + dx, ky + dy) != K.PODLOGA:
				przy_przejsciu = true
	if not przy_przejsciu:
		siatka[idx(kx, ky)] = K.KOSZ
	_zbierz_kosze()

	# 7. Łupy (osobny strumień): ilość i jakość zależna od rodzaju komnaty.
	var szczescie := (poziom_poszukiwacza - 1) * 0.04 + (0.22 if id_k == "crypt" else (0.1 if id_k == "outskirts" else 0.0))
	for i in komnaty.size():
		_lupy_komnaty(i, szczescie)
	# pojedyncze szczątki w korytarzach (rzadko)
	for k in 14:
		if korytarze.is_empty():
			break
		var c: Vector2i = korytarze[rng_lup.randi_range(0, korytarze.size() - 1)]
		if siatka[idx(c.x, c.y)] == K.SCIEZKA and not _zajete(c.x, c.y):
			_dodaj_skrzynie(c.x, c.y, "loot_knight", szczescie)


func _postaw_ekstrakcje(c: Vector2i, komnata: int) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t := kafel(c.x + dx, c.y + dy)
			if t == K.PODLOGA or t == K.GRUZ or t == K.KOSZ:
				_ustaw_wew(c.x + dx, c.y + dy, K.SCIEZKA)
	siatka[idx(c.x, c.y)] = K.EKSTRAKCJA
	komnaty[komnata]["typ"] = "ekstrakcja"
	ekstrakcje.append({"w": Vector2(c.x + 0.5, c.y + 0.5), "nazwa": NAZWY_EKSTRAKCJI[ekstrakcje.size()], "promien": 1.85})


# ---------------------------------------------------------------- KOMNATY
func _wagi_rodzajow(id_k: String) -> Dictionary:
	var w := {}
	for t in RODZAJE:
		w[t] = float(RODZAJE[t][4])
	match id_k:
		"catacombs":
			w["krypta"] *= 1.8
			w["dziedziniec"] *= 0.4
		"outskirts":
			w["dziedziniec"] *= 2.2
			w["sala_filarow"] *= 1.3
			w["krypta"] *= 0.5
		"crypt":
			w["sala_filarow"] *= 1.5
			w["legowisko"] *= 1.4
			w["kaplica"] *= 1.3
	return w


func _losuj_rodzaj(r: RandomNumberGenerator, wagi: Dictionary, juz: Array) -> String:
	# limity: najwyżej 3 skarbce i 4 legowiska na mapę
	var ile := {}
	for k in juz:
		ile[k["typ"]] = ile.get(k["typ"], 0) + 1
	var suma := 0.0
	for t in wagi:
		if (t == "skarbiec" and ile.get(t, 0) >= 3) or (t == "legowisko" and ile.get(t, 0) >= 4):
			continue
		suma += wagi[t]
	var q := r.randf() * suma
	for t in wagi:
		if (t == "skarbiec" and ile.get(t, 0) >= 3) or (t == "legowisko" and ile.get(t, 0) >= 4):
			continue
		q -= wagi[t]
		if q <= 0.0:
			return t
	return "komnata"


## Drzewo rozpinające (Prim) po środkach komnat.
func _drzewo(lista: Array) -> Array:
	var wynik: Array = []
	if lista.size() < 2:
		return wynik
	var w_drzewie := {0: true}
	while w_drzewie.size() < lista.size():
		var best := [-1, -1]
		var bd := 1e9
		for a in w_drzewie:
			for b in lista.size():
				if w_drzewie.has(b):
					continue
				var dd: float = (lista[a]["srodek"] as Vector2).distance_squared_to(lista[b]["srodek"])
				if dd < bd:
					bd = dd
					best = [a, b]
		wynik.append(best)
		w_drzewie[best[1]] = true
	return wynik


## Korytarz w kształcie L (z losowym zagięciem w połowie), szerokość 2; drzwi w murze komnaty.
func _korytarz(a: Dictionary, b: Dictionary, r: RandomNumberGenerator) -> void:
	var pa := _punkt_w(a, r)
	var pb := _punkt_w(b, r)
	var poziomo_najpierw := r.randf() < 0.5
	var zagiecie := Vector2i(pb.x, pa.y) if poziomo_najpierw else Vector2i(pa.x, pb.y)
	# czasem schodkowo (dwa zagięcia) — kręte przejścia
	if r.randf() < 0.45 and absi(pa.x - pb.x) > 6 and absi(pa.y - pb.y) > 6:
		var sx := (pa.x + pb.x) / 2 + r.randi_range(-3, 3)
		_odcinek(pa, Vector2i(sx, pa.y))
		_odcinek(Vector2i(sx, pa.y), Vector2i(sx, pb.y))
		_odcinek(Vector2i(sx, pb.y), pb)
		return
	_odcinek(pa, zagiecie)
	_odcinek(zagiecie, pb)


func _punkt_w(k: Dictionary, r: RandomNumberGenerator) -> Vector2i:
	var rr: Rect2i = k["r"]
	return Vector2i(r.randi_range(rr.position.x + 2, rr.end.x - 3), r.randi_range(rr.position.y + 2, rr.end.y - 3))


func _odcinek(a: Vector2i, b: Vector2i) -> void:
	var p := a
	var krok := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	while true:
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var q: Vector2i = p + d
			if q.x >= 1 and q.y >= 1 and q.x < ROZMIAR - 1 and q.y < ROZMIAR - 1:
				var t := siatka[idx(q.x, q.y)]
				if t == K.MUR:
					siatka[idx(q.x, q.y)] = K.SCIEZKA
					korytarze.append(q)
		if p == b:
			break
		p += krok


## Wnętrze komnaty bez pasa przy ścianach (pas 1 pola zostaje wolny — gwarancja przejścia).
func _wnetrze(i: int) -> Rect2i:
	var rr: Rect2i = komnaty[i]["r"]
	return Rect2i(rr.position.x + 2, rr.position.y + 2, rr.size.x - 4, rr.size.y - 4)


func _urzadz(i: int, r: RandomNumberGenerator) -> void:
	var typ: String = komnaty[i]["typ"]
	var w := _wnetrze(i)
	if w.size.x < 1 or w.size.y < 1:
		return
	match typ:
		"sala_filarow":
			# rzędy filarów co 3 pola
			for y in range(w.position.y, w.end.y, 3):
				for x in range(w.position.x, w.end.x, 3):
					if (x - w.position.x) % 3 == 0 and siatka[idx(x, y)] == K.PODLOGA:
						siatka[idx(x, y)] = K.FILAR
			_kosz_w(w.position.x + w.size.x / 2, w.position.y + w.size.y / 2)
		"dziedziniec":
			# ruiny: gruz i pojedyncze kolumny, kosze w narożach wnętrza
			for y in range(w.position.y, w.end.y):
				for x in range(w.position.x, w.end.x):
					var q := r.randf()
					if q < 0.05:
						siatka[idx(x, y)] = K.GRUZ
					elif q < 0.075:
						siatka[idx(x, y)] = K.FILAR
			_kosz_w(w.position.x, w.position.y)
			_kosz_w(w.end.x - 1, w.end.y - 1)
		"kaplica":
			# krąg koszy wokół środka — oaza światła
			var c := Vector2i(w.position.x + w.size.x / 2, w.position.y + w.size.y / 2)
			for d in [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2)]:
				_kosz_w(c.x + d.x, c.y + d.y)
			siatka[idx(c.x, c.y)] = K.FILAR
		"legowisko":
			for y in range(w.position.y, w.end.y):
				for x in range(w.position.x, w.end.x):
					if r.randf() < 0.06:
						siatka[idx(x, y)] = K.GRUZ
			_kosz_w(w.position.x + w.size.x / 2, w.position.y + w.size.y / 2)
		"skarbiec":
			pass
		"start":
			pass
		_:
			# komnata / krypta: kilka filarów i gruzu, czasem kosz
			for y in range(w.position.y, w.end.y):
				for x in range(w.position.x, w.end.x):
					var q := r.randf()
					if q < 0.035:
						siatka[idx(x, y)] = K.FILAR
					elif q < 0.07:
						siatka[idx(x, y)] = K.GRUZ
			if r.randf() < 0.55:
				_kosz_w(w.position.x + r.randi_range(0, w.size.x - 1), w.position.y + r.randi_range(0, w.size.y - 1))


func _kosz_w(x: int, y: int) -> void:
	if kafel(x, y) == K.PODLOGA:
		siatka[idx(x, y)] = K.KOSZ


func _zbierz_kosze() -> void:
	kosze.clear()
	for y in ROZMIAR:
		for x in ROZMIAR:
			if siatka[idx(x, y)] == K.KOSZ:
				kosze.append(Vector2(x + 0.5, y + 0.5))


## Pierwsze wolne pole blisko środka komnaty (spirala).
func _wolne_pole_w(i: int) -> Vector2i:
	var rr: Rect2i = komnaty[i]["r"]
	var c := Vector2i(rr.position.x + rr.size.x / 2, rr.position.y + rr.size.y / 2)
	for rad in 4:
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				var t := kafel(c.x + dx, c.y + dy)
				if t == K.PODLOGA or t == K.SCIEZKA:
					return Vector2i(c.x + dx, c.y + dy)
	return Vector2i(-1, -1)


## BFS po polach przechodnich od pola startu: odległość w krokach (-1 = nieosiągalne).
func _odleglosci(od: Vector2i) -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(ROZMIAR * ROZMIAR)
	d.fill(-1)
	var kolejka: Array[Vector2i] = [od]
	d[idx(od.x, od.y)] = 0
	var g := 0
	while g < kolejka.size():
		var p: Vector2i = kolejka[g]
		g += 1
		for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + s
			if q.x < 0 or q.y < 0 or q.x >= ROZMIAR or q.y >= ROZMIAR:
				continue
			var i := idx(q.x, q.y)
			if d[i] >= 0 or blokuje_ruch(siatka[i]):
				continue
			d[i] = d[idx(p.x, p.y)] + 1
			kolejka.append(q)
	return d


func _tylko_osiagalne() -> void:
	var d := _odleglosci(Vector2i(int(start.x), int(start.y)))
	for i in siatka.size():
		var t := siatka[i]
		if (t == K.PODLOGA or t == K.SCIEZKA) and d[i] < 0:
			siatka[i] = K.MUR
	# rekwizyty odcięte od przejść (np. filar w zamurowanym kącie) też w skałę
	for y in range(1, ROZMIAR - 1):
		for x in range(1, ROZMIAR - 1):
			var t := siatka[idx(x, y)]
			if t == K.FILAR or t == K.GRUZ or t == K.KOSZ:
				var obok := false
				for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if d[idx(x + s.x, y + s.y)] >= 0:
						obok = true
				if not obok:
					siatka[idx(x, y)] = K.MUR
	var zostaja: Array = []
	for k in korytarze:
		if d[idx(k.x, k.y)] >= 0:
			zostaja.append(k)
	korytarze = zostaja


# ---------------------------------------------------------------- ŁUPY
func _lupy_komnaty(i: int, szczescie: float) -> void:
	var typ: String = komnaty[i]["typ"]
	var ile := 0
	var rodzaje: Array = ["loot_chest", "loot_knight", "loot_sarcophagus"]
	var bonus := 0.0
	match typ:
		"start", "ekstrakcja":
			ile = 0
		"skarbiec":
			ile = 3 + rng_lup.randi_range(0, 1)
			rodzaje = ["loot_chest", "loot_sarcophagus"]
			bonus = 0.25
		"krypta":
			ile = 2 + rng_lup.randi_range(0, 1)
			rodzaje = ["loot_sarcophagus", "loot_sarcophagus", "loot_knight"]
		"legowisko":
			ile = 2 + rng_lup.randi_range(0, 1)
			rodzaje = ["loot_knight", "loot_chest", "loot_sarcophagus"]
			bonus = 0.15
		"kaplica":
			ile = 1
			rodzaje = ["loot_sarcophagus"]
		"sala_filarow", "dziedziniec":
			ile = 1 + rng_lup.randi_range(0, 2)
		_:
			ile = rng_lup.randi_range(0, 2)
	var rr: Rect2i = komnaty[i]["r"]
	for n in ile:
		for proba in 12:
			var lx := rng_lup.randi_range(rr.position.x + 1, rr.end.x - 2)
			var ly := rng_lup.randi_range(rr.position.y + 1, rr.end.y - 2)
			if siatka[idx(lx, ly)] != K.PODLOGA or _zajete(lx, ly):
				continue
			_dodaj_skrzynie(lx, ly, rodzaje[rng_lup.randi_range(0, rodzaje.size() - 1)], szczescie + bonus)
			break


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
