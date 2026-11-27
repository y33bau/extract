extends RefCounted
## Generator Spalonej Osady (pilot, 26.11.2026). Ta sama zasada co Czarnobór (decyzja autora): biotop otwarty,
## mapa z wyznaczonych ścieżek jak w Dragon's Dogma. Zamiast polan: miejsca osady (plac ze studnią, zagrody,
## kuźnia, stodoła, sad, cmentarz, piwnica, spalony kościół) połączone ulicami. Ściany to zabudowa: zgliszcza,
## zwęglone zarośla, gruz. Wzdłuż ulic stoją spalone chaty z wejściem — małe ślepe izby z łupem.
## Te same trzy strumienie losowania (układ / łupy / wrogowie): to samo ziarno = ta sama osada.
## PILOT: generator jeszcze NIE jest podpięty do rajdu (podgląd: --podglad-osady=katalog[,ziarno;ziarno]).

const Mapgen = preload("res://skrypty/mapgen.gd")

const ROZMIAR := 128   # decyzja autora 26.11.2026: wszystkie mapy 128×128 m
enum T { PLAC, ULICA, ZABUDOWA, ZGLISZCZA, CHATA, PLOT, DRZEWO, WOZ, STUDNIA, GROB, EKSTRAKCJA }

const NAZWY_MIEJSC := {
	"start": "Rozstaje", "plac": "Plac ze Studnią", "zagroda": "Zagroda", "kuznia": "Kuźnia", "stodola": "Spalona Stodoła",
	"sad": "Spalony Sad", "cmentarz": "Cmentarz", "piwnica": "Zapadnięta Piwnica", "kosciol": "Spalony Kościół",
	"ekstrakcja": "Wyjście",
}
const NAZWY_EKSTRAKCJI := ["Brama Osady", "Wyłom w Palisadzie", "Polna Droga", "Most Młynarza"]

var teren := PackedByteArray()    # typy T (wygląd i generowanie)
var siatka := PackedByteArray()   # typy Mapgen.K (logika rajdu) — zgodne z lochem i lasem
var wariant := PackedByteArray()
var kosze: Array = []             # żarzące się zgliszcza jako K.KOSZ (światło)
var komnaty: Array = []           # miejsca jako {r: Rect2i, typ, srodek}
var korytarze: Array = []         # pola ulic (patrole)
var komnata_startu := -1
var polany: Array = []      # miejsca osady: {c: Vector2, r: float, typ: String, gleb: int, stopien: int} (nazwa jak w lesie)
var sciezki: Array = []     # ulice: {a, b, szer, glowna: bool, punkty}
var domy: Array = []        # spalone chaty: {r: Rect2i (z murami), drzwi: Vector2i, przod: Vector2i}
var skrzynie: Array = []
var ekstrakcje: Array = []
var ogniska: Array = []     # Vector2 — światło (kuźnia, żar w chatach, start)
var spawny: Array = []
var start := Vector2.ZERO
var odl := PackedInt32Array()
var rng_uklad := RandomNumberGenerator.new()
var rng_lup := RandomNumberGenerator.new()
var rng_wrogowie := RandomNumberGenerator.new()
var _szum := FastNoiseLite.new()
var _plac := -1


static func blok_t(t: int) -> bool:
	return t == T.ZABUDOWA or t == T.ZGLISZCZA or t == T.PLOT or t == T.DRZEWO or t == T.WOZ or t == T.STUDNIA or t == T.GROB


static func wzrok_t(t: int) -> bool:
	return t == T.ZABUDOWA or t == T.ZGLISZCZA or t == T.DRZEWO


static func wolne_t(t: int) -> bool:
	return t == T.PLAC or t == T.ULICA or t == T.CHATA or t == T.EKSTRAKCJA


func idx(x: int, y: int) -> int:
	return y * ROZMIAR + x


func kt(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= ROZMIAR or y >= ROZMIAR:
		return T.ZABUDOWA
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
	teren.fill(T.ZABUDOWA)
	# 1. Miejsca: plac ze studnią blisko środka, reszta z odstępem (między nimi zabudowa i chaty).
	_rozstaw_miejsca(r)
	# 2. Ulice: drzewo rozpinające + pętle bez przecięć (jak w lesie, mniej kręte).
	var krawedzie := _drzewo()
	_petle(krawedzie, r)
	for k in krawedzie:
		_ulica(k[0], k[1], r)
	for i in polany.size():
		_wytnij_miejsce(i)
	# 3. Start przy krawędzi; głębokość = droga od startu.
	_wybierz_start(r)
	odl = _odl_t(Vector2i(int(start.x), int(start.y)))
	for p in polany:
		var c: Vector2 = p["c"]
		p["gleb"] = odl[idx(int(c.x), int(c.y))]
	# 4. Rodzaje miejsc (wyjścia w głębi, ślepe odnogi: cmentarz/piwnica, najgłębsza odnoga: kościół).
	_rodzaje_miejsc(r)
	# 5. Wyposażenie miejsc (studnia, płoty, groby, drzewa sadu, wozy), potem chaty wzdłuż ulic.
	_wyposaz(r)
	_chaty(r)
	_tylko_osiagalne()
	odl = _odl_t(Vector2i(int(start.x), int(start.y)))
	# 6. Ekstrakcje, światła, łupy (strumień łupów), miejsca wrogów (strumień wrogów).
	for i in polany.size():
		var p: Dictionary = polany[i]
		var c := Vector2i(int(p["c"].x), int(p["c"].y))
		match String(p["typ"]):
			"ekstrakcja":
				teren[idx(c.x, c.y)] = T.EKSTRAKCJA
				ekstrakcje.append({"w": Vector2(c) + Vector2(0.5, 0.5), "nazwa": NAZWY_EKSTRAKCJI[ekstrakcje.size() % NAZWY_EKSTRAKCJI.size()], "promien": 1.85})
			"start", "kuznia", "stodola":
				ogniska.append(Vector2(c) + Vector2(2.5, -1.5))
	for i in domy.size():
		if i % 4 == 0:   # żar w co czwartej chacie: światło i drogowskaz w ciemności
			ogniska.append(Vector2((domy[i]["r"] as Rect2i).get_center()) + Vector2(0.5, 0.5))
	var szczescie := (poziom_poszukiwacza - 1) * 0.04 + 0.1
	_lupy(szczescie)
	_wrogowie()
	_dla_rajdu()
	Mapgen.uzupelnij_dodatki(skrzynie, rng_lup)


const K = Mapgen.K
const NA_K := {T.PLAC: K.PODLOGA, T.ULICA: K.SCIEZKA, T.ZABUDOWA: K.MUR, T.ZGLISZCZA: K.MUR, T.CHATA: K.PODLOGA,
	T.PLOT: K.GRUZ, T.DRZEWO: K.FILAR, T.WOZ: K.GRUZ, T.STUDNIA: K.FILAR, T.GROB: K.GRUZ, T.EKSTRAKCJA: K.EKSTRAKCJA}
const KOMNATA_MIEJSCA := {"start": "start", "ekstrakcja": "ekstrakcja", "plac": "plac", "zagroda": "zagroda",
	"kuznia": "kuznia", "stodola": "stodola", "sad": "sad", "cmentarz": "cmentarz", "piwnica": "piwnica", "kosciol": "kosciol"}


func _dla_rajdu() -> void:
	siatka.resize(ROZMIAR * ROZMIAR)
	wariant.resize(ROZMIAR * ROZMIAR)
	for i in teren.size():
		siatka[i] = NA_K[teren[i]]
		wariant[i] = rng_uklad.randi_range(0, 2)
		if teren[i] == T.ULICA:
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
		komnaty.append({"r": Rect2i(int(c.x) - rad, int(c.y) - rad, rad * 2 + 1, rad * 2 + 1), "typ": KOMNATA_MIEJSCA[p["typ"]], "srodek": c})
		if p["typ"] == "start":
			komnata_startu = i


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


# ---------------------------------------------------------------- UKŁAD
func _rozstaw_miejsca(r: RandomNumberGenerator) -> void:
	# plac: zawsze, blisko środka, największy
	var rp := r.randf_range(10.0, 11.5)
	var cp := Vector2(ROZMIAR * 0.5 + r.randf_range(-12, 12), ROZMIAR * 0.5 + r.randf_range(-12, 12))
	polany.append({"c": cp, "r": rp, "typ": "plac", "gleb": 0, "stopien": 0})
	_plac = 0
	var cel := 18
	var proby := 0
	while proby < 1600 and polany.size() < cel:
		proby += 1
		var duza := r.randf() < 0.15
		var rad := r.randf_range(8.5, 10.0) if duza else r.randf_range(5.5, 7.5)
		var c := Vector2(r.randf_range(rad + 4, ROZMIAR - rad - 4), r.randf_range(rad + 4, ROZMIAR - rad - 4))
		var wolne := true
		for q in polany:
			# odstęp 11 m: między miejscami mieszczą się chaty (głębokość 6–8 m) i pas zabudowy
			if c.distance_to(q["c"]) < rad + float(q["r"]) + 11.0:
				wolne = false
				break
		if wolne:
			polany.append({"c": c, "r": rad, "typ": "sad" if duza else "zagroda", "gleb": 0, "stopien": 0})


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


func _petle(krawedzie: Array, r: RandomNumberGenerator) -> void:
	var kandydaci: Array = []
	for a in polany.size():
		for b in range(a + 1, polany.size()):
			if [a, b] in krawedzie or [b, a] in krawedzie:
				continue
			var d: float = (polany[a]["c"] as Vector2).distance_to(polany[b]["c"])
			if d < 44.0:
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


## Ulica: łagodny łuk (wieś, nie las). Do placu prowadzą ulice główne 6–7,5 m, reszta 5–6,5 m.
func _ulica(a: int, b: int, r: RandomNumberGenerator) -> void:
	var pa: Vector2 = polany[a]["c"]
	var pb: Vector2 = polany[b]["c"]
	var dl := pa.distance_to(pb)
	var bok := (pb - pa).orthogonal().normalized()
	var k1 := pa.lerp(pb, 0.33) + bok * r.randf_range(-0.12, 0.12) * dl
	var k2 := pa.lerp(pb, 0.66) + bok * r.randf_range(-0.12, 0.12) * dl
	var glowna := a == _plac or b == _plac
	var szer := r.randf_range(6.0, 7.5) if glowna else r.randf_range(5.0, 6.5)
	var punkty := PackedVector2Array()
	var n := int(dl * 2.0) + 2
	for i in n + 1:
		var t := float(i) / n
		var p := pa.bezier_interpolate(k1, k2, pb, t)
		p.x = clampf(p.x, 3.0, ROZMIAR - 4.0)
		p.y = clampf(p.y, 3.0, ROZMIAR - 4.0)
		punkty.append(p)
		var s := maxf(szer * 0.5 + 0.35 * _szum.get_noise_2d(p.x * 3.0, p.y * 3.0), 2.5)
		_maluj_kolo(p, s, T.ULICA, [T.ZABUDOWA])
	sciezki.append({"a": a, "b": b, "szer": szer, "glowna": glowna, "punkty": punkty})
	polany[a]["stopien"] += 1
	polany[b]["stopien"] += 1


## Miejsce o nieregularnym brzegu (mniej postrzępione niż polana: to podwórze, nie łąka).
func _wytnij_miejsce(i: int) -> void:
	var c: Vector2 = polany[i]["c"]
	var rad: float = polany[i]["r"]
	for y in range(int(c.y - rad - 3), int(c.y + rad + 4)):
		for x in range(int(c.x - rad - 3), int(c.x + rad + 4)):
			if x < 2 or y < 2 or x >= ROZMIAR - 2 or y >= ROZMIAR - 2:
				continue
			var d := Vector2(x + 0.5, y + 0.5) - c
			var kat := d.angle()
			var brzeg := rad * (1.0 + 0.14 * _szum.get_noise_2d(cos(kat) * 40.0 + c.x * 7.0, sin(kat) * 40.0 + c.y * 7.0))
			if d.length() <= brzeg:
				teren[idx(x, y)] = T.PLAC


func _maluj_kolo(c: Vector2, rad: float, typ: int, na: Array) -> void:
	for y in range(floori(c.y - rad), ceili(c.y + rad) + 1):
		for x in range(floori(c.x - rad), ceili(c.x + rad) + 1):
			if x < 2 or y < 2 or x >= ROZMIAR - 2 or y >= ROZMIAR - 2:
				continue
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= rad and teren[idx(x, y)] in na:
				teren[idx(x, y)] = typ


func _wybierz_start(r: RandomNumberGenerator) -> void:
	var strony := [Vector2(ROZMIAR * 0.5, 0), Vector2(ROZMIAR * 0.5, ROZMIAR), Vector2(0, ROZMIAR * 0.5), Vector2(ROZMIAR, ROZMIAR * 0.5)]
	var brzeg: Vector2 = strony[r.randi_range(0, 3)]
	var naj := 1
	var nd := 1e9
	for i in polany.size():
		if i == _plac:
			continue
		var dd: float = (polany[i]["c"] as Vector2).distance_to(brzeg) - float(polany[i]["r"])
		if dd < nd:
			nd = dd
			naj = i
	polany[naj]["typ"] = "start"
	var c: Vector2 = polany[naj]["c"]
	start = Vector2(int(c.x) + 0.5, int(c.y) + 0.5)


func _rodzaje_miejsc(r: RandomNumberGenerator) -> void:
	var kol: Array = []
	for i in polany.size():
		if polany[i]["typ"] != "start" and i != _plac:
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
	# kościół: najgłębsza ślepa odnoga (miejsce na bossa w rundzie „bossowie”), zanim wybierzemy wyjścia
	var kosciol := -1
	for i in polany.size():
		if polany[i]["stopien"] == 1 and polany[i]["typ"] != "start" and i != _plac:
			if kosciol < 0 or int(polany[i]["gleb"]) > int(polany[kosciol]["gleb"]):
				kosciol = i
	if kosciol >= 0:
		polany[kosciol]["typ"] = "kosciol"
		# kościół to przyszła arena bossa: co najmniej 9 m promienia (odstęp między miejscami to 11 m, więc się mieści)
		polany[kosciol]["r"] = maxf(float(polany[kosciol]["r"]), 9.0)
		_wytnij_miejsce(kosciol)
		kol.erase(kosciol)
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
	for i in polany.size():
		var p: Dictionary = polany[i]
		if p["typ"] in ["start", "ekstrakcja", "plac", "kosciol"]:
			continue
		if p["stopien"] == 1:
			p["typ"] = "cmentarz" if _ile_typu("cmentarz") < 1 or r.randf() < 0.3 else "piwnica"
		elif p["typ"] == "sad":
			pass
		else:
			var q := r.randf()
			var t := "kuznia" if q < 0.25 else ("stodola" if q < 0.45 else "zagroda")
			if t == "kuznia" and _ile_typu("kuznia") >= 1:
				t = "zagroda"
			if t == "stodola" and _ile_typu("stodola") >= 1:
				t = "zagroda"
			p["typ"] = t


func _ile_typu(t: String) -> int:
	var n := 0
	for p in polany:
		if p["typ"] == t:
			n += 1
	return n


## Pole wolne do postawienia przeszkody: wokół (3×3) tylko plac — przeszkoda nigdy nie zamyka przejścia.
func _wolny_pierscien(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if kt(x + dx, y + dy) != T.PLAC:
				return false
	return true


## Wyposażenie miejsc: studnia na placu, płot z przerwami w zagrodzie i na cmentarzu, groby, spalone drzewa
## (gęsto w sadzie), wozy i beczki (osłony). Wejścia ulic zawsze zostają wolne.
func _wyposaz(r: RandomNumberGenerator) -> void:
	for i in polany.size():
		var p: Dictionary = polany[i]
		var typ := String(p["typ"])
		var c: Vector2 = p["c"]
		var rad: float = p["r"]
		var ci := Vector2i(int(c.x), int(c.y))
		if typ == "plac":
			for dy in 2:
				for dx in 2:
					teren[idx(ci.x + dx, ci.y + dy)] = T.STUDNIA
		if typ in ["zagroda", "cmentarz"]:
			_plot(c, rad, r, T.PLOT)
		if typ == "kosciol":
			_plot(c, rad, r, T.ZGLISZCZA)   # osmalone mury nawy z wyłomami przy ulicach
		if typ == "cmentarz" or typ == "kosciol":
			for y in range(int(c.y - rad * 0.6), int(c.y + rad * 0.6) + 1, 2):
				for x in range(int(c.x - rad * 0.6), int(c.x + rad * 0.6) + 1, 3):
					if Vector2(x + 0.5, y + 0.5).distance_to(c) < 3.0 or r.randf() < (0.35 if typ == "cmentarz" else 0.75):
						continue
					if _wolny_pierscien(x, y):
						teren[idx(x, y)] = T.GROB
		if typ in ["start", "ekstrakcja"]:
			continue
		var gestosc := 0.09 if typ == "sad" else 0.035
		for y in range(int(c.y - rad), int(c.y + rad) + 1):
			for x in range(int(c.x - rad), int(c.x + rad) + 1):
				if Vector2(x + 0.5, y + 0.5).distance_to(c) < 3.0 or r.randf() > gestosc:
					continue
				if _wolny_pierscien(x, y):
					var drzewo := r.randf() < (0.85 if typ == "sad" else 0.35)
					teren[idx(x, y)] = T.DRZEWO if drzewo else T.WOZ


## Płot (albo mur kościoła) po obwodzie miejsca z przerwami tam, gdzie wchodzą ulice (i jedną-dwiema losowymi wyrwami).
func _plot(c: Vector2, rad: float, r: RandomNumberGenerator, typ: int) -> void:
	var wyrwa := r.randf() * TAU
	for y in range(int(c.y - rad - 1), int(c.y + rad) + 2):
		for x in range(int(c.x - rad - 1), int(c.x + rad) + 2):
			var d := Vector2(x + 0.5, y + 0.5) - c
			if d.length() < rad - 1.6 or d.length() > rad - 0.6 or kt(x, y) != T.PLAC:
				continue
			if absf(angle_difference(d.angle(), wyrwa)) < 0.45:
				continue
			var przy_ulicy := false
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if kt(x + dx, y + dy) == T.ULICA:
						przy_ulicy = true
			if not przy_ulicy:
				teren[idx(x, y)] = typ


## Spalone chaty przy ulicach i miejscach: prostokąt zgliszcz (mury 1 m), wnętrze, wejście 3 m od strony drogi.
## Chata stoi w zabudowie z odstępem 1 m od innych; gdy wejście nie dochodzi do drogi, chata znika.
func _chaty(r: RandomNumberGenerator) -> void:
	var kotwice: Array = []   # [punkt, kierunek na zewnątrz drogi]
	for s in sciezki:
		var pts: PackedVector2Array = s["punkty"]
		var polsz: float = float(s["szer"]) * 0.5
		for i in range(2, pts.size() - 2, 3):
			var styczna := (pts[i + 1] - pts[i - 1]).normalized()
			var bok := styczna.orthogonal()
			kotwice.append([pts[i] + bok * polsz, bok])
			kotwice.append([pts[i] - bok * polsz, -bok])
	for p in polany:
		if p["typ"] in ["start", "ekstrakcja"]:
			continue
		var c: Vector2 = p["c"]
		for k in 10:
			var kier := Vector2.RIGHT.rotated(k * TAU / 10.0)
			kotwice.append([c + kier * float(p["r"]), kier])
	# kolejność zależy od ziarna
	for i in range(kotwice.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = kotwice[i]
		kotwice[i] = kotwice[j]
		kotwice[j] = t
	var cel := 34
	for k in kotwice:
		if domy.size() >= cel:
			break
		_postaw_chate(k[0], k[1], r)


func _postaw_chate(punkt: Vector2, kier: Vector2, r: RandomNumberGenerator) -> void:
	# chata ustawiona do osi: przód (wejście) w stronę drogi
	var przod := Vector2i(signi(roundi(kier.x)), 0) if absf(kier.x) >= absf(kier.y) else Vector2i(0, signi(roundi(kier.y)))
	if przod == Vector2i.ZERO:
		return
	var szer := r.randi_range(6, 8)    # wzdłuż drogi (z murami)
	var gleb := r.randi_range(6, 8)    # w głąb zabudowy (z murami)
	var wym := Vector2i(szer, gleb) if przod.y != 0 else Vector2i(gleb, szer)
	# pierwsze pole zabudowy za brzegiem drogi
	var p := Vector2i(int(punkt.x), int(punkt.y))
	for krok in 4:
		if kt(p.x, p.y) == T.ZABUDOWA:
			break
		p += przod
	var lewy_gorny: Vector2i
	if przod == Vector2i(1, 0):
		lewy_gorny = Vector2i(p.x + 1, p.y - wym.y / 2)
	elif przod == Vector2i(-1, 0):
		lewy_gorny = Vector2i(p.x - wym.x, p.y - wym.y / 2)
	elif przod == Vector2i(0, 1):
		lewy_gorny = Vector2i(p.x - wym.x / 2, p.y + 1)
	else:
		lewy_gorny = Vector2i(p.x - wym.x / 2, p.y - wym.y)
	var rect := Rect2i(lewy_gorny, wym)
	if rect.position.x < 3 or rect.position.y < 3 or rect.end.x > ROZMIAR - 3 or rect.end.y > ROZMIAR - 3:
		return
	# cała chata z marginesem 1 m w zabudowie (margines od strony drogi może być drogą)
	for y in range(rect.position.y - 1, rect.end.y + 1):
		for x in range(rect.position.x - 1, rect.end.x + 1):
			var t := kt(x, y)
			var w_rect := rect.has_point(Vector2i(x, y))
			if w_rect and t != T.ZABUDOWA:
				return
			if not w_rect and t != T.ZABUDOWA:
				var od_przodu := (przod.x > 0 and x < rect.position.x) or (przod.x < 0 and x >= rect.end.x) \
					or (przod.y > 0 and y < rect.position.y) or (przod.y < 0 and y >= rect.end.y)
				if not od_przodu or not wolne_t(t):
					return
	# mury i wnętrze
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var brzeg := x == rect.position.x or y == rect.position.y or x == rect.end.x - 1 or y == rect.end.y - 1
			teren[idx(x, y)] = T.ZGLISZCZA if brzeg else T.CHATA
	# wejście 3 m w ścianie od drogi + przejście do drogi (najwyżej 2 pola)
	var srodek := rect.get_center()
	var drzwi: Vector2i
	if przod.x > 0:
		drzwi = Vector2i(rect.position.x, srodek.y)
	elif przod.x < 0:
		drzwi = Vector2i(rect.end.x - 1, srodek.y)
	elif przod.y > 0:
		drzwi = Vector2i(srodek.x, rect.position.y)
	else:
		drzwi = Vector2i(srodek.x, rect.end.y - 1)
	var wzdluz := Vector2i(przod.y, przod.x).abs()
	var doszla := false
	var wyciete: Array[Vector2i] = []
	for o in [-1, 0, 1]:
		var q: Vector2i = drzwi + wzdluz * o
		teren[idx(q.x, q.y)] = T.CHATA
		for krok in range(1, 4):
			var z: Vector2i = q - przod * krok
			var t := kt(z.x, z.y)
			if wolne_t(t) or t in [T.PLOT, T.DRZEWO, T.WOZ, T.GROB]:
				if wolne_t(t):
					doszla = true
				break
			teren[idx(z.x, z.y)] = T.ULICA
			wyciete.append(z)
	if not doszla:
		_zburz(rect)
		for z in wyciete:
			teren[idx(z.x, z.y)] = T.ZABUDOWA
		return
	# w środku czasem belka albo przewrócony sprzęt (osłona przy ścianie, nie na środku)
	if r.randf() < 0.5:
		var bx := rect.position.x + 1 if r.randf() < 0.5 else rect.end.x - 2
		var by := rect.position.y + 1 if r.randf() < 0.5 else rect.end.y - 2
		var bq := Vector2i(bx, by)
		if bq.distance_to(drzwi) > 2.5:
			teren[idx(bx, by)] = T.WOZ
	domy.append({"r": rect, "drzwi": drzwi, "przod": przod})


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
		if wolne_t(teren[i]) and d[i] < 0:
			teren[i] = T.ZABUDOWA
	var zostaja: Array = []
	for dom in domy:
		var dr: Vector2i = dom["drzwi"]
		if d[idx(dr.x, dr.y)] >= 0:
			zostaja.append(dom)
		else:
			_zburz(dom["r"])
	domy = zostaja


## Chata, do której nie da się wejść, znika całkiem (nie zostawia pustych murów).
func _zburz(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			teren[idx(x, y)] = T.ZABUDOWA


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
			"kosciol":
				ile = 3 + rng_lup.randi_range(0, 1)
				rodzaje = ["loot_sarcophagus", "loot_chest", "loot_sarcophagus"]
				bonus += 0.25
			"piwnica":
				ile = 3
				rodzaje = ["loot_chest", "loot_chest", "loot_knight"]
				bonus += 0.15
			"cmentarz":
				ile = 2 + rng_lup.randi_range(0, 1)
				rodzaje = ["loot_sarcophagus", "loot_sarcophagus", "loot_knight"]
				bonus += 0.15
			"kuznia":
				ile = 2
				rodzaje = ["loot_knight", "loot_chest"]
			"stodola":
				ile = 2
			_:
				ile = rng_lup.randi_range(0, 1) + (1 if g > 0.5 else 0)
		var c: Vector2 = p["c"]
		var rad: float = p["r"]
		for n in ile:
			for proba in 16:
				var lx := int(c.x + rng_lup.randf_range(-rad * 0.7, rad * 0.7))
				var ly := int(c.y + rng_lup.randf_range(-rad * 0.7, rad * 0.7))
				if kt(lx, ly) != T.PLAC or odl[idx(lx, ly)] < 0 or _zajete(lx, ly):
					continue
				_dodaj_skrzynie(lx, ly, rodzaje[rng_lup.randi_range(0, rodzaje.size() - 1)], szczescie + bonus)
				break
	# chaty: co trzecia ma coś w środku (zachęta do zaglądania, ryzyko ślepej izby)
	for dom in domy:
		if rng_lup.randf() > 0.35:
			continue
		var rect: Rect2i = dom["r"]
		for proba in 10:
			var lx := rng_lup.randi_range(rect.position.x + 1, rect.end.x - 2)
			var ly := rng_lup.randi_range(rect.position.y + 1, rect.end.y - 2)
			if kt(lx, ly) == T.CHATA and odl[idx(lx, ly)] >= 0 and not _zajete(lx, ly):
				_dodaj_skrzynie(lx, ly, "loot_chest", szczescie)
				break


## Pilot: tylko miejsca i liczebność grup (rodzaje wrogów osady dojdą w rundzie „moby”).
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
			"kosciol":
				ile = 3 + int(g * 2.0)
			"plac":
				ile = 3
			"ekstrakcja":
				ile = 2
			"cmentarz", "piwnica", "sad":
				ile = 2 + int(g * 1.5)
			_:
				ile = 1 + int(g * 2.0)
		if g < 0.2:
			ile = mini(ile, 1)
		var c: Vector2 = p["c"]
		for n in ile:
			for proba in 12:
				var w := c + Vector2(rng_wrogowie.randf_range(-3.5, 3.5), rng_wrogowie.randf_range(-3.5, 3.5))
				if blok_t(kt(int(w.x), int(w.y))) or odl[idx(int(w.x), int(w.y))] < 0 or _zajete(int(w.x), int(w.y)):
					continue
				spawny.append({"w": w, "grupa": grupa, "gleb": p["gleb"]})
				break
		grupa += 1
	for s in sciezki:
		var ga: float = float(polany[s["a"]]["gleb"]) / max_gleb
		if ga > 0.35 and rng_wrogowie.randf() < 0.5:
			var pts: PackedVector2Array = s["punkty"]
			var w: Vector2 = pts[pts.size() / 2]
			if not blok_t(kt(int(w.x), int(w.y))) and odl[idx(int(w.x), int(w.y))] >= 0 and not _zajete(int(w.x), int(w.y)):
				spawny.append({"w": w, "grupa": grupa, "gleb": int(ga * max_gleb)})
				grupa += 1


func _zajete(x: int, y: int) -> bool:
	for o in ogniska:   # żar stanie się w rajdzie przeszkodą (K.KOSZ)
		if int(o.x) == x and int(o.y) == y:
			return true
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


## Zapis do podglądu (JSON).
func do_slownika() -> Dictionary:
	var wiersze: Array = []
	for y in ROZMIAR:
		var s := ""
		for x in ROZMIAR:
			s += "%x" % teren[idx(x, y)]
		wiersze.append(s)
	var pol: Array = []
	for p in polany:
		pol.append({"x": p["c"].x, "y": p["c"].y, "r": p["r"], "typ": p["typ"], "gleb": p["gleb"], "nazwa": NAZWY_MIEJSC.get(p["typ"], "")})
	var sc: Array = []
	for s in sciezki:
		var pts: Array = []
		for p in s["punkty"]:
			pts.append([p.x, p.y])
		sc.append({"szer": s["szer"], "glowna": s["glowna"], "punkty": pts})
	var dm: Array = []
	for d in domy:
		var rc: Rect2i = d["r"]
		dm.append([rc.position.x, rc.position.y, rc.size.x, rc.size.y])
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
	return {"rozmiar": ROZMIAR, "teren": wiersze, "miejsca": pol, "ulice": sc, "domy": dm, "skrzynie": sk,
		"ekstrakcje": ek, "wrogowie": wr, "ogniska": og, "start": [start.x, start.y]}
