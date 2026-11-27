extends RefCounted
## Generator lasu (pilot Czarnoboru, 26.11.2026). Decyzja autora: biotop otwarty, mapa z wyznaczonych ścieżek
## jak w Dragon's Dogma — gracz widzi przyrodę, ale chodzi siecią ścieżek; nie za wąskich, nie za szerokich.
## Układ: polany (kotwice) połączone krętymi ścieżkami 4–6 m; drzewo rozpinające + 2–3 pętle; ślepe odnogi;
## ściany z natury (gęsty las, skały, wąwozy), strumień z brodami. Głębiej = groźniej i bogaciej.
## Te same trzy strumienie losowania co w lochu (układ / łupy / wrogowie): to samo ziarno = ten sam las.
## PILOT: generator jeszcze NIE jest podpięty do rajdu (podgląd: --podglad-lasu=katalog[,ziarno;ziarno]).

const Mapgen = preload("res://skrypty/mapgen.gd")

const ROZMIAR := 128   # 1 pole = 1 m; decyzja autora 26.11.2026: wszystkie mapy 128×128 m
enum T { POLANA, SCIEZKA, LAS, SKALA, WODA, BROD, DRZEWO, GLAZ, EKSTRAKCJA }

## Rodzaje polan: [min promień, max promień]. Promień w metrach (polana ma ok. 2× tyle średnicy).
const POLANY := {
	"start": [6, 7], "ekstrakcja": [5, 6], "polana": [6, 9], "laka": [9, 11],
	"oboz": [6, 8], "kapliczka": [5, 6], "kurhan": [5, 7], "legowisko": [6, 8],
}
const NAZWY_POLAN := {
	"start": "Skraj Czarnoboru", "polana": "Polana", "laka": "Wilcza Łąka", "oboz": "Obóz Kłusowników",
	"kapliczka": "Leśna Kapliczka", "kurhan": "Kurhan", "legowisko": "Legowisko", "ekstrakcja": "Wyjście",
}
const NAZWY_EKSTRAKCJI := ["Stary Trakt", "Bród Przewoźnika", "Ścieżka Smolarzy", "Krąg Menhirów"]

var teren := PackedByteArray()    # typy T (wygląd i generowanie)
var siatka := PackedByteArray()   # typy Mapgen.K (logika rajdu: ruch, wzrok, mgła) — zgodne z lochem
var wariant := PackedByteArray()
var kosze: Array = []             # ogniska jako K.KOSZ (światło)
var komnaty: Array = []           # polany jako {r: Rect2i, typ, srodek} — rajd: wrogowie, nazwy obszarów
var korytarze: Array = []         # pola ścieżek (patrole)
var komnata_startu := -1
var polany: Array = []      # {c: Vector2, r: float, typ: String, gleb: int, stopien: int}
var sciezki: Array = []     # {a: int, b: int, szer: float, wawoz: bool, punkty: PackedVector2Array}
var skrzynie: Array = []    # jak w Mapgen
var ekstrakcje: Array = []  # {w: Vector2, nazwa, promien}
var ogniska: Array = []     # Vector2 — światło (obóz, start, kapliczka)
var spawny: Array = []      # {w: Vector2, grupa: int, gleb: int} — miejsca wrogów (pilot: tylko znaczniki)
var start := Vector2.ZERO
var odl := PackedInt32Array()
var rng_uklad := RandomNumberGenerator.new()
var rng_lup := RandomNumberGenerator.new()
var rng_wrogowie := RandomNumberGenerator.new()
var _szum := FastNoiseLite.new()


static func blok_t(t: int) -> bool:
	return t == T.LAS or t == T.SKALA or t == T.WODA or t == T.DRZEWO or t == T.GLAZ


static func wzrok_t(t: int) -> bool:
	return t == T.LAS or t == T.SKALA or t == T.DRZEWO


func idx(x: int, y: int) -> int:
	return y * ROZMIAR + x


func kt(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= ROZMIAR or y >= ROZMIAR:
		return T.LAS
	return teren[idx(x, y)]


func generuj(kraina: Dictionary, ziarno: String, poziom_poszukiwacza: int) -> void:
	var baza := (ziarno + "_" + str(kraina["id"])).hash()
	rng_uklad.seed = baza
	rng_lup.seed = baza ^ 0x5bd1e995
	rng_wrogowie.seed = baza ^ 0x2545f491
	var r := rng_uklad
	_szum.seed = r.randi()
	_szum.frequency = 0.045
	_szum.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	teren.resize(ROZMIAR * ROZMIAR)
	teren.fill(T.LAS)
	# 0. Skały w gąszczu (plamy z szumu): ściany natury są różne, nie tylko drzewa.
	for y in ROZMIAR:
		for x in ROZMIAR:
			if _szum.get_noise_2d(x * 1.3 + 500.0, y * 1.3) > 0.32:
				teren[idx(x, y)] = T.SKALA
	# 1. Strumień (zawsze w Czarnoborze): od krawędzi do krawędzi, kręty.
	_strumien(r)
	# 2. Polany: rozstawione z odstępem (między nimi zawsze pas lasu).
	_rozstaw_polany(r)
	# 3. Sieć: drzewo rozpinające + pętle bez przecięć.
	var krawedzie := _drzewo()
	_petle(krawedzie, r)
	for k in krawedzie:
		_sciezka(k[0], k[1], r)
	for i in polany.size():
		_wytnij_polane(i)
	# 4. Start: polana najbliżej losowej krawędzi; głębokość = odległość ścieżką od startu.
	_wybierz_start(r)
	odl = _odl_t(Vector2i(int(start.x), int(start.y)))
	for p in polany:
		var c: Vector2 = p["c"]
		p["gleb"] = odl[idx(int(c.x), int(c.y))]
	# 5. Rodzaje polan (ślepe odnogi i głębia: legowiska i kurhany; wyjścia najdalej).
	_rodzaje_polan(r)
	# 6. Pojedyncze drzewa i głazy na polanach (osłony w walce, nigdy nie zamykają przejścia).
	_oslony(r)
	_tylko_osiagalne()
	odl = _odl_t(Vector2i(int(start.x), int(start.y)))
	# 7. Ekstrakcje, ogniska, łupy (strumień łupów), miejsca wrogów (strumień wrogów).
	for i in polany.size():
		var p: Dictionary = polany[i]
		var c := Vector2i(int(p["c"].x), int(p["c"].y))
		match String(p["typ"]):
			"ekstrakcja":
				teren[idx(c.x, c.y)] = T.EKSTRAKCJA
				ekstrakcje.append({"w": Vector2(c) + Vector2(0.5, 0.5), "nazwa": NAZWY_EKSTRAKCJI[ekstrakcje.size() % NAZWY_EKSTRAKCJI.size()], "promien": 1.85})
			"start", "oboz", "kapliczka":
				ogniska.append(Vector2(c) + Vector2(2.5, -1.5))
	var szczescie := (poziom_poszukiwacza - 1) * 0.04 + 0.1
	_lupy(szczescie)
	_wrogowie()
	_dla_rajdu()
	Mapgen.uzupelnij_dodatki(skrzynie, rng_lup)


const K = Mapgen.K
const NA_K := {T.POLANA: K.PODLOGA, T.SCIEZKA: K.SCIEZKA, T.LAS: K.MUR, T.SKALA: K.MUR, T.WODA: K.WODA,
	T.BROD: K.SCIEZKA, T.DRZEWO: K.FILAR, T.GLAZ: K.GRUZ, T.EKSTRAKCJA: K.EKSTRAKCJA}
## Typy komnat rajdu dla polan (rozstawianie wrogów i tytuły obszarów).
const KOMNATA_POLANY := {"start": "start", "ekstrakcja": "ekstrakcja", "polana": "polana", "laka": "laka",
	"oboz": "oboz", "kapliczka": "kapliczka_lesna", "kurhan": "kurhan", "legowisko": "legowisko"}


## Przekład na format lochu: siatka K, polany jako komnaty, ścieżki jako korytarze, ogniska jako kosze.
func _dla_rajdu() -> void:
	siatka.resize(ROZMIAR * ROZMIAR)
	wariant.resize(ROZMIAR * ROZMIAR)
	for i in teren.size():
		siatka[i] = NA_K[teren[i]]
		wariant[i] = rng_uklad.randi_range(0, 2)
		if teren[i] == T.SCIEZKA or teren[i] == T.BROD:
			korytarze.append(Vector2i(i % ROZMIAR, i / ROZMIAR))
	for o in ogniska:
		var c := Vector2i(int(o.x), int(o.y))
		var wolne := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if kafel(c.x + dx, c.y + dy) != K.PODLOGA:
					wolne = false
		if wolne:
			siatka[idx(c.x, c.y)] = K.KOSZ
			kosze.append(Vector2(c) + Vector2(0.5, 0.5))
	for i in polany.size():
		var p: Dictionary = polany[i]
		var c: Vector2 = p["c"]
		var rad := int(float(p["r"]) * 0.8)
		komnaty.append({"r": Rect2i(int(c.x) - rad, int(c.y) - rad, rad * 2 + 1, rad * 2 + 1), "typ": KOMNATA_POLANY[p["typ"]], "srodek": c})
		if p["typ"] == "start":
			komnata_startu = i


## Logika rajdu (typy K), jak w Mapgen.
func kafel(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= ROZMIAR or y >= ROZMIAR:
		return K.MUR
	return siatka[idx(x, y)]


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
			if d[i] >= 0 or Mapgen.blokuje_ruch(siatka[i]):
				continue
			d[i] = d[idx(p.x, p.y)] + 1
			kolejka.append(q)
	return d


# ---------------------------------------------------------------- TEREN
func _strumien(r: RandomNumberGenerator) -> void:
	var pion := r.randf() < 0.5
	var p := Vector2(r.randf_range(32, ROZMIAR - 32), -2.0) if pion else Vector2(-2.0, r.randf_range(32, ROZMIAR - 32))
	var kier := Vector2(0, 1) if pion else Vector2(1, 0)
	var kat := 0.0
	var szer := r.randf_range(1.4, 1.9)
	var krok := 0
	while p.x > -4 and p.y > -4 and p.x < ROZMIAR + 4 and p.y < ROZMIAR + 4 and krok < 600:
		krok += 1
		kat = clampf(kat + r.randf_range(-0.22, 0.22), -0.9, 0.9)
		p += kier.rotated(kat) * 0.6
		var s := szer + 0.35 * _szum.get_noise_2d(p.x * 2.0, p.y * 2.0)
		_maluj_kolo(p, s, T.WODA, [T.LAS, T.SKALA])


func _rozstaw_polany(r: RandomNumberGenerator) -> void:
	var cel := 21   # ×1,78 względem pilota 96 m (ta sama gęstość polan)
	var proby := 0
	while proby < 1600 and polany.size() < cel:
		proby += 1
		var duza := r.randf() < 0.18
		var rad := r.randf_range(9.0, 11.0) if duza else r.randf_range(5.5, 8.0)
		var c := Vector2(r.randf_range(rad + 4, ROZMIAR - rad - 4), r.randf_range(rad + 4, ROZMIAR - rad - 4))
		var wolne := true
		for q in polany:
			if c.distance_to(q["c"]) < rad + float(q["r"]) + 9.0:
				wolne = false
				break
		if wolne:
			polany.append({"c": c, "r": rad, "typ": "laka" if duza else "polana", "gleb": 0, "stopien": 0})


## Drzewo rozpinające (Prim) po środkach polan.
func _drzewo() -> Array:
	var wynik: Array = []
	var w := {0: true}
	while w.size() < polany.size():
		var best := [-1, -1]
		var bd := 1e9
		for a in w:
			for b in polany.size():
				if w.has(b):
					continue
				var dd: float = (polany[a]["c"] as Vector2).distance_squared_to(polany[b]["c"])
				if dd < bd:
					bd = dd
					best = [a, b]
		wynik.append(best)
		w[best[1]] = true
	return wynik


## 2–3 pętle: krótkie połączenia, które nie przecinają innych ścieżek i nie zahaczają o obce polany.
func _petle(krawedzie: Array, r: RandomNumberGenerator) -> void:
	var kandydaci: Array = []
	for a in polany.size():
		for b in range(a + 1, polany.size()):
			if [a, b] in krawedzie or [b, a] in krawedzie:
				continue
			var d: float = (polany[a]["c"] as Vector2).distance_to(polany[b]["c"])
			if d < 42.0:
				kandydaci.append([d + r.randf() * 8.0, a, b])
	kandydaci.sort_custom(func(x, y): return x[0] < y[0])
	var stopien := {}
	for e in krawedzie:
		stopien[e[0]] = stopien.get(e[0], 0) + 1
		stopien[e[1]] = stopien.get(e[1], 0) + 1
	var ile := r.randi_range(3, 5)
	for k in kandydaci:
		if ile <= 0:
			break
		# liście drzewa zostają ślepymi odnogami (nagroda za zboczenie z drogi)
		if stopien.get(k[1], 0) <= 1 or stopien.get(k[2], 0) <= 1:
			continue
		if _koliduje(k[1], k[2], krawedzie):
			continue
		krawedzie.append([k[1], k[2]])
		ile -= 1


func _koliduje(a: int, b: int, krawedzie: Array) -> bool:
	var pa: Vector2 = polany[a]["c"]
	var pb: Vector2 = polany[b]["c"]
	for e in krawedzie:
		if e[0] == a or e[0] == b or e[1] == a or e[1] == b:
			continue
		if Geometry2D.segment_intersects_segment(pa, pb, polany[e[0]]["c"], polany[e[1]]["c"]) != null:
			return true
	for i in polany.size():
		if i == a or i == b:
			continue
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(polany[i]["c"], pa, pb)
		if q.distance_to(polany[i]["c"]) < float(polany[i]["r"]) + 4.0:
			return true
	return false


## Kręta ścieżka (krzywa Béziera z wychyleniem na boki), szerokość 5–6,5 m (autor 26.11: szersze; było 4–6); czasem wąwóz.
func _sciezka(a: int, b: int, r: RandomNumberGenerator) -> void:
	var pa: Vector2 = polany[a]["c"]
	var pb: Vector2 = polany[b]["c"]
	var dl := pa.distance_to(pb)
	var bok := (pb - pa).orthogonal().normalized()
	var k1 := pa.lerp(pb, 0.33) + bok * r.randf_range(-0.22, 0.22) * dl
	var k2 := pa.lerp(pb, 0.66) + bok * r.randf_range(-0.22, 0.22) * dl
	var szer := r.randf_range(5.0, 6.5)
	var wawoz := r.randf() < 0.25 and dl > 20.0
	var punkty := PackedVector2Array()
	var n := int(dl * 2.0) + 2
	for i in n + 1:
		var t := float(i) / n
		var p := pa.bezier_interpolate(k1, k2, pb, t)
		p.x = clampf(p.x, 3.0, ROZMIAR - 4.0)
		p.y = clampf(p.y, 3.0, ROZMIAR - 4.0)
		punkty.append(p)
		var s := maxf(szer * 0.5 + 0.45 * _szum.get_noise_2d(p.x * 3.0, p.y * 3.0), 2.5)   # min. 5 m (także po skosie)
		if wawoz:
			_maluj_kolo(p, s + 2.2, T.SKALA, [T.LAS])
		_maluj_kolo(p, s, T.SCIEZKA, [T.LAS, T.SKALA])
		_maluj_kolo(p, s, T.BROD, [T.WODA])
	sciezki.append({"a": a, "b": b, "szer": szer, "wawoz": wawoz, "punkty": punkty})
	polany[a]["stopien"] += 1
	polany[b]["stopien"] += 1


## Polana o nieregularnym brzegu (szum po kącie). Strumień na polanie staje się płytką wodą.
func _wytnij_polane(i: int) -> void:
	var c: Vector2 = polany[i]["c"]
	var rad: float = polany[i]["r"]
	for y in range(int(c.y - rad - 3), int(c.y + rad + 4)):
		for x in range(int(c.x - rad - 3), int(c.x + rad + 4)):
			if x < 2 or y < 2 or x >= ROZMIAR - 2 or y >= ROZMIAR - 2:
				continue
			var d := Vector2(x + 0.5, y + 0.5) - c
			var kat := d.angle()
			var brzeg := rad * (1.0 + 0.22 * _szum.get_noise_2d(cos(kat) * 40.0 + c.x * 7.0, sin(kat) * 40.0 + c.y * 7.0))
			if d.length() <= brzeg:
				var t := teren[idx(x, y)]
				if t == T.WODA or t == T.BROD:
					teren[idx(x, y)] = T.BROD
				else:
					teren[idx(x, y)] = T.POLANA


func _maluj_kolo(c: Vector2, rad: float, typ: int, na: Array) -> void:
	for y in range(int(floor(c.y - rad)), int(ceil(c.y + rad)) + 1):
		for x in range(int(floor(c.x - rad)), int(ceil(c.x + rad)) + 1):
			if x < 2 or y < 2 or x >= ROZMIAR - 2 or y >= ROZMIAR - 2:
				continue
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= rad and teren[idx(x, y)] in na:
				teren[idx(x, y)] = typ


func _wybierz_start(r: RandomNumberGenerator) -> void:
	var strony := [Vector2(ROZMIAR * 0.5, 0), Vector2(ROZMIAR * 0.5, ROZMIAR), Vector2(0, ROZMIAR * 0.5), Vector2(ROZMIAR, ROZMIAR * 0.5)]
	var brzeg: Vector2 = strony[r.randi_range(0, 3)]
	var naj := 0
	var nd := 1e9
	for i in polany.size():
		var dd: float = (polany[i]["c"] as Vector2).distance_to(brzeg) - float(polany[i]["r"])
		if dd < nd:
			nd = dd
			naj = i
	polany[naj]["typ"] = "start"
	var c: Vector2 = polany[naj]["c"]
	start = Vector2(int(c.x) + 0.5, int(c.y) + 0.5)


func _rodzaje_polan(r: RandomNumberGenerator) -> void:
	# wyjścia: 3 najgłębsze polany, co najmniej 26 m od siebie
	var kol: Array = []
	for i in polany.size():
		if polany[i]["typ"] != "start":
			kol.append(i)
	var max_g := 1
	for p in polany:
		max_g = maxi(max_g, int(p["gleb"]))
	var ocena := {}
	for i in kol:
		var c: Vector2 = polany[i]["c"]
		var brzeg := minf(minf(c.x, c.y), minf(ROZMIAR - c.x, ROZMIAR - c.y))
		ocena[i] = 0.6 * float(polany[i]["gleb"]) / max_g + 0.4 * (1.0 - clampf(brzeg / (ROZMIAR * 0.5), 0.0, 1.0))
	kol.sort_custom(func(a, b): return ocena[a] > ocena[b])
	var wyjscia: Array = []
	var lisci := 0
	for i in kol:
		if polany[i]["stopien"] == 1:
			lisci += 1
	var lisci_na_wyjscia := maxi(0, lisci - 2)   # co najmniej 2 ślepe odnogi zostają z łupem
	for prog in [35.0, 22.0, 0.0]:
		for i in kol:
			if wyjscia.size() >= 3:
				break
			if i in wyjscia:
				continue
			if polany[i]["stopien"] == 1 and lisci_na_wyjscia <= 0 and prog > 0.0:
				continue
			# wyjście nie przy starcie: co najmniej 45% najdłuższej drogi (ryzyko powrotu)
			if float(polany[i]["gleb"]) < 0.45 * max_g and prog > 0.0:
				continue
			var blisko := false
			for j in wyjscia:
				if (polany[i]["c"] as Vector2).distance_to(polany[j]["c"]) < prog:
					blisko = true
			if not blisko:
				wyjscia.append(i)
				if polany[i]["stopien"] == 1:
					lisci_na_wyjscia -= 1
	for i in wyjscia:
		polany[i]["typ"] = "ekstrakcja"
	var max_gleb := 1
	for p in polany:
		max_gleb = maxi(max_gleb, int(p["gleb"]))
	for i in polany.size():
		var p: Dictionary = polany[i]
		if p["typ"] in ["start", "ekstrakcja"]:
			continue
		var g := float(p["gleb"]) / max_gleb
		if p["stopien"] == 1:
			# ślepa odnoga: nagroda za zboczenie z drogi
			p["typ"] = "legowisko" if g > 0.55 or r.randf() < 0.4 else "kurhan"
		elif p["typ"] == "laka":
			pass
		else:
			var q := r.randf()
			var t := "oboz" if q < 0.3 else ("kapliczka" if q < 0.45 else "polana")
			if t == "oboz" and _ile_typu("oboz") >= 2:
				t = "polana"
			if t == "kapliczka" and _ile_typu("kapliczka") >= 1:
				t = "polana"
			p["typ"] = t


func _ile_typu(t: String) -> int:
	var n := 0
	for p in polany:
		if p["typ"] == t:
			n += 1
	return n


## Pojedyncze drzewa i głazy: każdy otoczony wolnym pierścieniem, więc nigdy nie zamyka przejścia.
func _oslony(r: RandomNumberGenerator) -> void:
	for p in polany:
		if p["typ"] == "ekstrakcja" or p["typ"] == "start":
			continue
		var c: Vector2 = p["c"]
		var rad: float = p["r"]
		var gestosc := 0.05 if p["typ"] in ["laka", "polana"] else 0.03
		for y in range(int(c.y - rad), int(c.y + rad) + 1):
			for x in range(int(c.x - rad), int(c.x + rad) + 1):
				if Vector2(x + 0.5, y + 0.5).distance_to(c) < 2.5 or r.randf() > gestosc:
					continue
				var wolno := true
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if kt(x + dx, y + dy) != T.POLANA:
							wolno = false
				if wolno:
					teren[idx(x, y)] = T.DRZEWO if r.randf() < 0.6 else T.GLAZ


## BFS po polach przechodnich od startu: odległość w krokach (-1 = nieosiągalne).
func _odl_t(od: Vector2i) -> PackedInt32Array:
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
			if d[i] >= 0 or blok_t(teren[i]):
				continue
			d[i] = d[idx(p.x, p.y)] + 1
			kolejka.append(q)
	return d


func _tylko_osiagalne() -> void:
	var d := _odl_t(Vector2i(int(start.x), int(start.y)))
	for i in teren.size():
		var t := teren[i]
		if (t == T.POLANA or t == T.SCIEZKA or t == T.BROD) and d[i] < 0:
			teren[i] = T.LAS


# ---------------------------------------------------------------- ŁUPY I WROGOWIE
func _lupy(szczescie: float) -> void:
	var max_gleb := 1
	for p in polany:
		max_gleb = maxi(max_gleb, int(p["gleb"]))
	for p in polany:
		var g := float(p["gleb"]) / max_gleb
		var ile := 0
		var rodzaje: Array = ["loot_chest", "loot_knight"]
		var bonus := g * 0.15
		match String(p["typ"]):
			"start", "ekstrakcja":
				ile = 0
			"legowisko":
				ile = 3 + rng_lup.randi_range(0, 1)
				rodzaje = ["loot_knight", "loot_chest", "loot_sarcophagus"]
				bonus += 0.2
			"kurhan":
				ile = 2 + rng_lup.randi_range(0, 1)
				rodzaje = ["loot_sarcophagus", "loot_sarcophagus", "loot_knight"]
				bonus += 0.15
			"oboz":
				ile = 2 + rng_lup.randi_range(0, 1)
			"kapliczka":
				ile = 1
				rodzaje = ["loot_sarcophagus"]
			_:
				ile = rng_lup.randi_range(0, 1) + (1 if g > 0.5 else 0)
		var c: Vector2 = p["c"]
		var rad: float = p["r"]
		for n in ile:
			for proba in 16:
				var lx := int(c.x + rng_lup.randf_range(-rad * 0.7, rad * 0.7))
				var ly := int(c.y + rng_lup.randf_range(-rad * 0.7, rad * 0.7))
				if kt(lx, ly) != T.POLANA or odl[idx(lx, ly)] < 0 or _zajete(lx, ly):
					continue
				_dodaj_skrzynie(lx, ly, rodzaje[rng_lup.randi_range(0, rodzaje.size() - 1)], szczescie + bonus)
				break
	# szczątki przy ścieżkach (rzadko)
	for k in 8:
		var s: Dictionary = sciezki[rng_lup.randi_range(0, sciezki.size() - 1)]
		var pts: PackedVector2Array = s["punkty"]
		var p: Vector2 = pts[rng_lup.randi_range(pts.size() / 4, pts.size() * 3 / 4)]
		var cx := int(p.x)
		var cy := int(p.y)
		if kt(cx, cy) == T.SCIEZKA and not _zajete(cx, cy):
			_dodaj_skrzynie(cx, cy, "loot_knight", szczescie)


## Pilot: tylko miejsca i liczebność grup (rodzaje wrogów lasu dojdą w rundzie „moby”).
func _wrogowie() -> void:
	var max_gleb := 1
	for p in polany:
		max_gleb = maxi(max_gleb, int(p["gleb"]))
	var grupa := 0
	for p in polany:
		if p["typ"] == "start":
			continue
		var g := float(p["gleb"]) / max_gleb
		var ile := 0
		match String(p["typ"]):
			"legowisko":
				ile = 3 + int(g * 2.0)
			"oboz":
				ile = 3
			"ekstrakcja":
				ile = 2
			"kurhan", "laka":
				ile = 2 + int(g * 1.5)
			_:
				ile = 1 + int(g * 2.0)
		if g < 0.2:
			ile = mini(ile, 1)
		var c: Vector2 = p["c"]
		for n in ile:
			for proba in 12:
				var w := c + Vector2(rng_wrogowie.randf_range(-3.5, 3.5), rng_wrogowie.randf_range(-3.5, 3.5))
				if blok_t(kt(int(w.x), int(w.y))):
					continue
				spawny.append({"w": w, "grupa": grupa, "gleb": p["gleb"]})
				break
		grupa += 1
	# patrole na ścieżkach w głębi
	for s in sciezki:
		var ga: float = float(polany[s["a"]]["gleb"]) / max_gleb
		if ga > 0.35 and rng_wrogowie.randf() < 0.5:
			var pts: PackedVector2Array = s["punkty"]
			spawny.append({"w": pts[pts.size() / 2], "grupa": grupa, "gleb": int(ga * max_gleb)})
			grupa += 1


func _zajete(x: int, y: int) -> bool:
	for s in skrzynie:
		if s["tx"] == x and s["ty"] == y:
			return true
	return false


func _dodaj_skrzynie(x: int, y: int, rodzaj: String, szczescie: float) -> void:
	var lista: Array = []
	var pula: Array = Mapgen.PULE_LUPU[rodzaj]
	for i in 2 + rng_lup.randi_range(0, 2):
		var id: String = pula[rng_lup.randi_range(0, pula.size() - 1)]
		if id in Mapgen.RZADKIE and rng_lup.randf() > 0.35 + szczescie:
			id = "ash_essence" if rng_lup.randf() < 0.5 else "runic_ring"
		lista.append({"przedmiot": Profil.nowy_przedmiot(id), "odkryty": false})
	skrzynie.append({"tx": x, "ty": y, "w": Vector2(x + 0.5, y + 0.5), "rodzaj": rodzaj, "nazwa": Mapgen.NAZWY[rodzaj], "przedmioty": lista})


## Zapis do podglądu (JSON): teren jako tekst cyfr, polany, ścieżki, łupy, wrogowie.
func do_slownika() -> Dictionary:
	var wiersze: Array = []
	for y in ROZMIAR:
		var s := ""
		for x in ROZMIAR:
			s += str(teren[idx(x, y)])
		wiersze.append(s)
	var pol: Array = []
	for p in polany:
		pol.append({"x": p["c"].x, "y": p["c"].y, "r": p["r"], "typ": p["typ"], "gleb": p["gleb"], "nazwa": NAZWY_POLAN.get(p["typ"], "")})
	var sc: Array = []
	for s in sciezki:
		var pts: Array = []
		for p in s["punkty"]:
			pts.append([p.x, p.y])
		sc.append({"szer": s["szer"], "wawoz": s["wawoz"], "punkty": pts})
	var sk: Array = []
	for s in skrzynie:
		sk.append({"x": s["w"].x, "y": s["w"].y, "rodzaj": s["rodzaj"]})
	var ek: Array = []
	for e in ekstrakcje:
		ek.append({"x": e["w"].x, "y": e["w"].y, "nazwa": e["nazwa"]})
	var wr: Array = []
	for s in spawny:
		wr.append({"x": s["w"].x, "y": s["w"].y, "gleb": s["gleb"]})
	var og: Array = []
	for o in ogniska:
		og.append([o.x, o.y])
	return {"rozmiar": ROZMIAR, "teren": wiersze, "polany": pol, "sciezki": sc, "skrzynie": sk, "ekstrakcje": ek,
		"wrogowie": wr, "ogniska": og, "start": [start.x, start.y]}
