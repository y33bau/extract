extends Node2D
## Rajd: świat lochu i wszystkie reguły walki, łupu, ekstrakcji i śmierci (port z wersji JS).

signal koniec(przezyl: bool, powod: String, podsumowanie: Dictionary)
signal otworz_okno(pojemnik)  # pojemnik może być null (sama sakwa)
signal zmiana_ekwipunku
signal toast(tekst: String, rodzaj: String)

const Iso = preload("res://skrypty/iso.gd")
const Mapgen = preload("res://skrypty/mapgen.gd")
const Bohater = preload("res://skrypty/bohater.gd")
const Wrog = preload("res://skrypty/wrog.gd")
const Efekty = preload("res://skrypty/efekty.gd")
const K = Mapgen.K
const N := Mapgen.ROZMIAR
const CZAS_RAJDU := 480.0
const CZAS_EKSTRAKCJI := 6.0

var kraina: Dictionary
var ziarno := ""
var mapa: Mapgen
var gracz: Bohater
var wrogowie: Array = []
var zwloki: Array = []     # {w, rodzaj, kat, nazwa, boss, sakwa, przedmioty, wezel}
var strzaly: Array = []    # {w, v, dmg, zasieg, od_gracza}
var widok := PackedByteArray()  # 0 nieznane, 1 widziane, 2 widoczne
var czas := 0.0
var czas_pozostaly := CZAS_RAJDU
var zabici := 0
var parowania := 0
var ekstrakcja_czas := CZAS_EKSTRAKCJI
var ekstrakcja_sek := 6
var w_ekstrakcji := false
var okno_otwarte := false
var aktywny_pojemnik = null
var postep_szukania := 0.0
var zakonczony := false
var koniec_za := -1.0
var hitstop := 0.0
var wstrzas := 0.0
var blysk_trafienia := 0.0
var blysk_parowania := 0.0
var pochodnia_na_ziemi = null  # Vector2 albo null
var xp_rajdu := {}             # doświadczenie zbierane w rajdzie, rozliczane na końcu
var timer_widoku := 0.0
var mysz_aktywna := false
var blokada_wejscia := 0.0
# Bufor wejścia (jak w Soulsborne): naciśnięcie w trakcie zamrożenia lub odnowienia nie przepada
var bufor_ataku := 0.0
var bufor_uniku := 0.0

var podloga: Node2D
var swiat: Node2D
var efekty: Efekty
var strzaly_wezel: Node2D
var kamera: Camera2D
var mrok: CanvasModulate
var sprite_kafli := {}   # idx -> Sprite2D (mury, filary, kosze, gruz)
var swiatlo_pochodni_ziemia: PointLight2D
var wezel_pochodni: Node2D
var tekstury := {}


func start(id_krainy: String, ziarno_mapy: String) -> void:
	kraina = Dane.kraina(id_krainy)
	ziarno = ziarno_mapy
	mapa = Mapgen.new()
	mapa.generuj(kraina, ziarno, Profil.poziom("scavenger"))
	widok.resize(N * N)
	widok.fill(0)
	for t in ["floor_0", "floor_1", "floor_2", "path", "extract", "wall", "pillar", "brazier", "rubble", "loot_chest", "loot_sarcophagus", "loot_knight"]:
		tekstury[t] = load("res://zasoby/kafle/%s/%s.png" % [kraina["id"], t])
	_buduj_swiat()
	_postaw_gracza()
	_postaw_wrogow()
	_licz_widok()


# ---------------------------------------------------------------- BUDOWA ŚWIATA
func _buduj_swiat() -> void:
	mrok = CanvasModulate.new()
	mrok.color = Color8(20, 16, 22) if kraina["id"] == "crypt" else Color8(30, 27, 34)
	add_child(mrok)
	podloga = Node2D.new()
	podloga.z_index = -10
	podloga.draw.connect(_rysuj_podloge)
	add_child(podloga)
	swiat = Node2D.new()
	swiat.y_sort_enabled = true
	add_child(swiat)
	for y in N:
		for x in N:
			var t := mapa.kafel(x, y)
			var nazwa := ""
			var off := Vector2.ZERO
			match t:
				K.MUR: nazwa = "wall"; off = Vector2(-16, -28)
				K.FILAR: nazwa = "pillar"; off = Vector2(-16, -28)
				K.KOSZ: nazwa = "brazier"; off = Vector2(-16, -20)
				K.GRUZ: nazwa = "rubble"; off = Vector2(-16, -16)
			if nazwa != "":
				var s := _sprite_kafla(nazwa, off, Vector2(x + 0.5, y + 0.5))
				s.visible = false
				swiat.add_child(s)
				sprite_kafli[mapa.idx(x, y)] = s
	for sk in mapa.skrzynie:
		var s := _sprite_kafla(sk["rodzaj"], Vector2(-16, -16), sk["w"])
		s.visible = false
		swiat.add_child(s)
		sk["wezel"] = s
	for k in mapa.kosze:
		var l := Swiatla.nowe(Color(1.0, 0.63, 0.27), 1.2, 195.0)
		l.position = Iso.ekran(k) + Vector2(0, -16)
		add_child(l)
	for e in mapa.ekstrakcje:
		var l := Swiatla.nowe(Color(0.27, 0.92, 0.69), 1.3, 210.0)
		l.position = Iso.ekran(e["w"])
		add_child(l)
		e["swiatlo"] = l
	strzaly_wezel = Node2D.new()
	strzaly_wezel.z_index = 20
	strzaly_wezel.draw.connect(_rysuj_strzaly)
	add_child(strzaly_wezel)
	efekty = Efekty.new()
	add_child(efekty)
	kamera = Camera2D.new()
	add_child(kamera)
	swiatlo_pochodni_ziemia = Swiatla.nowe(Color(1.0, 0.78, 0.5), 1.6, 300.0)
	swiatlo_pochodni_ziemia.visible = false
	add_child(swiatlo_pochodni_ziemia)
	wezel_pochodni = Node2D.new()
	wezel_pochodni.draw.connect(_rysuj_pochodnie_ziemia)
	swiat.add_child(wezel_pochodni)


func _sprite_kafla(nazwa: String, off: Vector2, w: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tekstury[nazwa]
	s.centered = false
	s.offset = off
	s.scale = Vector2(2, 2)
	s.position = Iso.ekran(w)
	return s


func _postaw_gracza() -> void:
	gracz = Bohater.new()
	gracz.w = mapa.start
	var oltarz := Profil.budynek("altar")
	gracz.hp_max = 100.0 + oltarz * 18
	gracz.hp = gracz.hp_max
	gracz.stamina_max = 100.0 + oltarz * 15
	gracz.stamina = gracz.stamina_max
	gracz.rynsztunek = Profil.d["loadout"].duplicate(true)
	swiat.add_child(gracz)
	kamera.position = Iso.ekran(gracz.w)


func _postaw_wrogow() -> void:
	var r := mapa.rng_wrogowie
	var tabela: Array = {
		"catacombs": [["scout", 0.5], ["warden", 0.3], ["archer", 0.2]],
		"outskirts": [["scout", 0.25], ["warden", 0.25], ["archer", 0.2], ["knight", 0.2], ["brute", 0.1]],
		"crypt": [["scout", 0.15], ["warden", 0.2], ["archer", 0.15], ["knight", 0.25], ["brute", 0.25]],
	}[kraina["id"]]
	for i in int(kraina["enemyCount"]):
		var p := Vector2.ZERO
		for proba in 60:
			p = Vector2(3 + r.randi_range(0, N - 7) + 0.5, 3 + r.randi_range(0, N - 7) + 0.5)
			if p.distance_to(gracz.w) > 9.0 and not Mapgen.blokuje_ruch(mapa.kafel(int(p.x), int(p.y))):
				break
		var q := r.randf()
		var acc := 0.0
		var rodzaj := "scout"
		for wpis in tabela:
			acc += wpis[1]
			if q < acc:
				rodzaj = wpis[0]
				break
		_dodaj_wroga(rodzaj, p, r.randf() * TAU)
	if kraina["hasBoss"]:
		var b := Vector2(N / 2 + 0.5, N / 2 + 0.5)
		for t in 50:
			var tx := 14 + r.randi_range(0, N - 25)
			var ty := 14 + r.randi_range(0, N - 25)
			if not Mapgen.blokuje_ruch(mapa.kafel(tx, ty)):
				b = Vector2(tx + 0.5, ty + 0.5)
				break
		_dodaj_wroga("boss", b, 0.0)


func _dodaj_wroga(rodzaj: String, p: Vector2, kat: float) -> Wrog:
	var w := Wrog.new()
	w.ustaw(rodzaj, p, kat)
	swiat.add_child(w)
	wrogowie.append(w)
	return w


# ---------------------------------------------------------------- RYSOWANIE
func _rysuj_podloge() -> void:
	for y in N:
		for x in N:
			var v := widok[y * N + x]
			if v == 0:
				continue
			var t := mapa.kafel(x, y)
			var tex: Texture2D = tekstury["floor_%d" % mapa.wariant[y * N + x]]
			if t == K.SCIEZKA:
				tex = tekstury["path"]
			elif t == K.EKSTRAKCJA:
				tex = tekstury["extract"]
			var p := Iso.ekran(Vector2(x, y))
			podloga.draw_texture_rect(tex, Rect2(p.x - 32, p.y, 64, 32), false, Color(1, 1, 1, 1.0 if v == 2 else 0.34))


func _rysuj_strzaly() -> void:
	for a in strzaly:
		var p := Iso.ekran(a["w"]) + Vector2(0, -14)
		var v: Vector2 = a["v"]
		var kier := Iso.ekran(v).normalized() * 7.0
		strzaly_wezel.draw_line(p - kier, p + kier, Color("e6ba63") if a["od_gracza"] else Color("f87171"), 2.0)


func _rysuj_pochodnie_ziemia() -> void:
	if pochodnia_na_ziemi == null:
		return
	var t := czas
	wezel_pochodni.draw_line(Vector2(-7, 2), Vector2(5, -8), Color("4a3222"), 3.0)
	var h := 9.0 + sin(t * 17.0) * 2.0
	wezel_pochodni.draw_set_transform(Vector2(5, -14), 0, Vector2(1.0, h / 6.0))
	wezel_pochodni.draw_circle(Vector2.ZERO, 6.0, Color(0.88, 0.33, 0.1, 0.9))
	wezel_pochodni.draw_circle(Vector2(0, 1), 3.3, Color(1.0, 0.82, 0.4, 0.95))
	wezel_pochodni.draw_set_transform(Vector2.ZERO)


# ---------------------------------------------------------------- KOLIZJE I WIDOCZNOŚĆ
func pelne(x: float, y: float) -> bool:
	return Mapgen.blokuje_ruch(mapa.kafel(int(floor(x)), int(floor(y))))


func przesun(cialo, d: Vector2) -> void:
	var r: float = cialo.promien
	var w: Vector2 = cialo.w
	var nx := w.x + d.x
	if not pelne(nx - r, w.y - r) and not pelne(nx + r, w.y - r) and not pelne(nx - r, w.y + r) and not pelne(nx + r, w.y + r):
		w.x = nx
	var ny := w.y + d.y
	if not pelne(w.x - r, ny - r) and not pelne(w.x + r, ny - r) and not pelne(w.x - r, ny + r) and not pelne(w.x + r, ny + r):
		w.y = ny
	cialo.w = w


func linia_wzroku(a: Vector2, b: Vector2) -> bool:
	var kroki := int(ceil(a.distance_to(b) * 3.5))
	for i in range(1, kroki):
		var p := a.lerp(b, float(i) / kroki)
		if Mapgen.blokuje_wzrok(mapa.kafel(int(floor(p.x)), int(floor(p.y)))):
			return false
	return true


func przy_swietle(p: Vector2) -> bool:
	if pochodnia_na_ziemi != null and p.distance_to(pochodnia_na_ziemi) < 4.6:
		return true
	for k in mapa.kosze:
		if p.distance_to(k) < 3.4:
			return true
	for e in mapa.ekstrakcje:
		if p.distance_to(e["w"]) < 3.4:
			return true
	return false


func _licz_widok() -> void:
	for i in widok.size():
		if widok[i] == 2:
			widok[i] = 1
	var wzrok := 1.0 if (gracz.pochodnia_w_rece or przy_swietle(gracz.w)) else 0.5
	for r in 128:
		var a := r / 128.0 * TAU
		var dk := absf(angle_difference(a, gracz.kat))
		var max_d := (11.5 if dk < 1.1 else 4.8) * wzrok
		var c := cos(a)
		var s := sin(a)
		var d := 0.25
		while d <= max_d:
			var tx := int(floor(gracz.w.x + c * d))
			var ty := int(floor(gracz.w.y + s * d))
			if tx < 0 or ty < 0 or tx >= N or ty >= N:
				break
			widok[ty * N + tx] = 2
			if Mapgen.blokuje_wzrok(mapa.siatka[ty * N + tx]):
				break
			d += 0.38
	# widoczność obiektów i przezroczystość murów zasłaniających gracza
	for i in sprite_kafli:
		var s: Sprite2D = sprite_kafli[i]
		var v := widok[i]
		s.visible = v > 0
		if v > 0:
			var tx: int = i % N
			var ty: int = i / N
			var alfa := 1.0 if v == 2 else 0.34
			var t := mapa.siatka[i]
			if (t == K.MUR or t == K.FILAR) and tx + ty > gracz.w.x + gracz.w.y \
					and absf(tx - gracz.w.x) < 2.1 and absf(ty - gracz.w.y) < 2.1:
				alfa = minf(alfa, 0.35)
			s.modulate.a = alfa
	for sk in mapa.skrzynie:
		var v2 := widok[mapa.idx(sk["tx"], sk["ty"])]
		sk["wezel"].visible = v2 > 0
		sk["wezel"].modulate.a = 1.0 if v2 == 2 else 0.4
	podloga.queue_redraw()


func widoczne(p: Vector2) -> int:
	var x := int(floor(p.x))
	var y := int(floor(p.y))
	if x < 0 or y < 0 or x >= N or y >= N:
		return 0
	return widok[y * N + x]


# ---------------------------------------------------------------- POMOCNICZE
func xp(umiejetnosc: String, ile: float) -> void:
	xp_rajdu[umiejetnosc] = float(xp_rajdu.get(umiejetnosc, 0.0)) + ile


func napis(w: Vector2, t: String, kolor := Color.WHITE, rozmiar := 12) -> void:
	efekty.napis(w, t, kolor, rozmiar)


func sakwa_obciazenie() -> int:
	var n := 0
	for it in gracz.rynsztunek["backpack"]:
		if not _na_pasie(it):
			n += 1
	return n


func _na_pasie(it: Dictionary) -> bool:
	var t := Dane.typ(it["id"])
	return t == "elixir" or t == "arrow"


func liczba_strzal() -> int:
	var n := 0
	for lista in [gracz.rynsztunek["backpack"], gracz.rynsztunek["reliquary"]]:
		for it in lista:
			if it["id"] == "iron_arrows":
				n += int(it["qty"])
	return n


func liczba_mikstur(rodzaj: String) -> int:
	var n := 0
	for lista in [gracz.rynsztunek["backpack"], gracz.rynsztunek["reliquary"]]:
		for it in lista:
			if Dane.p(it["id"]).get("elixKind") == rodzaj:
				n += 1
	return n


# ---------------------------------------------------------------- WALKA GRACZA
func atak_wrecz() -> void:
	var p := gracz
	if okno_otwarte or p.atak_cd > 0.0 or p.unik_czas > 0.0 or p.martwy:
		return
	var bron: Dictionary = Dane.p(p.rynsztunek["weapon"]["id"]) if p.rynsztunek["weapon"] else {"dmg": 10, "range": 1.3, "arc": 1.2, "stamina": 10, "cooldown": 0.35}
	if p.stamina < float(bron["stamina"]) * 0.6:
		napis(p.w - Vector2(0.6, 0.6), "BRAK STAMINY!", Color("a8a29e"), 10)
		return
	p.stamina = maxf(0.0, p.stamina - float(bron["stamina"]))
	p.blok = false
	p.combo = (p.combo + 1) % 3 if p.combo_reset > 0.0 else 0
	p.combo_reset = 0.95
	var ciezki := p.combo == 2
	p.atak_dlugosc = 0.24 if ciezki else 0.18
	p.atak_czas = p.atak_dlugosc
	p.atak_cd = float(bron["cooldown"]) * (1.22 if ciezki else 1.0)
	p.atak_kat = p.kat
	p.zamach_anim_max = 0.42 if ciezki else 0.3
	p.zamach_anim = p.zamach_anim_max
	przesun(p, Vector2(cos(p.kat), sin(p.kat)) * (0.32 if ciezki else 0.18))
	Dzwiek.zamach(ciezki)
	var kuznia := 1.0 + Profil.budynek("forge") * 0.12
	var bieglosc := 1.0 + (Profil.poziom("melee") - 1) * 0.06
	var trafil := false
	for i in range(wrogowie.size() - 1, -1, -1):
		var en: Wrog = wrogowie[i]
		var d := en.w - p.w
		if d.length() > float(bron["range"]) + en.promien:
			continue
		var kat_do := atan2(d.y, d.x)
		if absf(angle_difference(p.atak_kat, kat_do)) > float(bron["arc"]) * 0.58:
			continue
		var riposta := en.ogluszenie > 0.0
		var obr := float(bron["dmg"]) * kuznia * bieglosc * (1.35 if ciezki else 1.0)
		if riposta:
			obr *= 2.6 + (Profil.poziom("parry") - 1) * 0.15
			en.ogluszenie = 0.0
			Dzwiek.riposta()
			hitstop = 0.11
			wstrzas = minf(14.0, wstrzas + 10.0)
			efekty.czastki_dodaj(en.w, 18, Color("ffd166"), 4.2, 0.6)
			napis(en.w - Vector2(0.9, 0.9), "RIPOSTA -%d!" % roundi(obr), Color("ffd166"), 14)
			xp("parry", 35)
			p.riposta_niet = 0.5
		else:
			obr *= 1.0 - en.pancerz
			Dzwiek.trafienie()
			hitstop = 0.05 if ciezki else 0.025
			wstrzas = minf(9.0, wstrzas + (5.0 if ciezki else 2.5))
			efekty.czastki_dodaj(en.w, 7, Color("b51d29"), 2.8, 0.4)
			napis(en.w - Vector2(0.6, 0.6), "-%d" % roundi(obr), Color("f59e0b") if ciezki else Color("f5f0e6"), 12)
			xp("melee", 12)
			postura(en, float(bron["dmg"]) * kuznia * (1.9 if ciezki else 0.85))
		en.hp -= obr
		en.trafiony = 0.15
		en.stan = "walka"
		var odrzut := 0.45 if riposta else (0.25 if ciezki else 0.12)
		przesun(en, Vector2(cos(kat_do), sin(kat_do)) * odrzut)
		trafil = true
		if en.hp <= 0.0:
			zabij(en)
	if trafil and ciezki:
		xp("melee", 6)


func postura(en: Wrog, ile: float) -> void:
	if en.ogluszenie > 0.0 or en.hp <= 0.0:
		return
	en.postura -= ile
	en.postura_przerwa = 2.5
	if en.postura <= 0.0:
		en.postura = en.postura_max
		en.ogluszenie = 1.8 if en.boss else 2.2
		en.zamach = 0.0
		en.atak_timer = en.ogluszenie
		hitstop = maxf(hitstop, 0.09)
		wstrzas = minf(12.0, wstrzas + 6.0)
		Dzwiek.parowanie()
		efekty.czastki_dodaj(en.w, 16, Color("ffd166"), 3.6, 0.5)
		napis(en.w - Vector2(1.05, 1.05), "POSTURA ZŁAMANA!", Color("ffd166"), 13)


func strzal_z_luku() -> void:
	var p := gracz
	if okno_otwarte or p.luk_cd > 0.0 or p.unik_czas > 0.0 or p.martwy:
		return
	if not p.rynsztunek["bow"]:
		toast.emit("Nie masz wyposażonego łuku!", "warn")
		return
	if liczba_strzal() <= 0:
		toast.emit("Brak strzał w sakwie!", "warn")
		return
	var luk := Dane.p(p.rynsztunek["bow"]["id"])
	if p.stamina < float(luk["stamina"]):
		return
	for lista in [p.rynsztunek["backpack"], p.rynsztunek["reliquary"]]:
		var znaleziono := false
		for i in lista.size():
			if lista[i]["id"] == "iron_arrows" and int(lista[i]["qty"]) > 0:
				lista[i]["qty"] = int(lista[i]["qty"]) - 1
				if lista[i]["qty"] <= 0:
					lista.remove_at(i)
				znaleziono = true
				break
		if znaleziono:
			break
	p.stamina -= float(luk["stamina"])
	p.luk_cd = 0.58
	Dzwiek.cieciwa()
	var lucznictwo := Profil.poziom("archery") - 1
	var kier := Vector2(cos(p.kat), sin(p.kat))
	strzaly.append({"w": p.w + kier * 0.4, "v": kier * float(luk["speed"]) * (1.0 + lucznictwo * 0.04),
		"dmg": float(luk["dmg"]) * (1.0 + lucznictwo * 0.08), "zasieg": float(luk["range"]), "od_gracza": true})
	zmiana_ekwipunku.emit()


func unik(kierunek_ruchu: Vector2) -> void:
	var p := gracz
	if okno_otwarte or p.unik_cd > 0.0 or p.unik_czas > 0.0 or p.martwy:
		return
	var koszt := maxf(12.0, 22.0 - (Profil.poziom("endurance") - 1) * 1.2)
	if p.stamina < koszt:
		return
	p.stamina -= koszt
	p.unik_kier = kierunek_ruchu if kierunek_ruchu != Vector2.ZERO else Vector2(cos(p.kat), sin(p.kat))
	p.unik_czas = p.UNIK_DLUGOSC
	p.unik_cd = 0.62
	p.blok = false
	Dzwiek.unik()
	xp("endurance", 8)


func parowanie_start() -> void:
	var p := gracz
	if okno_otwarte or p.unik_czas > 0.0 or p.martwy:
		return
	p.blok = true
	if p.pochodnia_w_rece:
		napis(p.w - Vector2(0.9, 0.9), "POCHODNIA W RĘCE — [F]", Color("f59e0b"), 10)
		return
	if p.parowanie_cd <= 0.0:
		var tarcza: float = float(Dane.p(p.rynsztunek["shield"]["id"])["parryBonus"]) if p.rynsztunek["shield"] else 0.0
		p.okno_parowania = 0.28 + tarcza + Profil.budynek("altar") * 0.04 + (Profil.poziom("parry") - 1) * 0.015
		p.parowanie_cd = 0.65


func pochodnia() -> void:
	var p := gracz
	if okno_otwarte or p.martwy:
		return
	if p.pochodnia_w_rece:
		p.pochodnia_w_rece = false
		p.blok = false
		var gdzie := p.w + Vector2(cos(p.kat), sin(p.kat)) * 0.6
		pochodnia_na_ziemi = p.w if pelne(gdzie.x, gdzie.y) else gdzie
		swiatlo_pochodni_ziemia.position = Iso.ekran(pochodnia_na_ziemi) + Vector2(0, -12)
		swiatlo_pochodni_ziemia.visible = true
		wezel_pochodni.position = Iso.ekran(pochodnia_na_ziemi)
		Dzwiek.unik()
		efekty.czastki_dodaj(pochodnia_na_ziemi, 10, Color("ffb347"), 2.2, 0.5)
		napis(p.w - Vector2(0.9, 0.9), "POCHODNIA NA ZIEMI — TARCZA GOTOWA", Color("fbbf24"), 11)
	elif pochodnia_na_ziemi != null and p.w.distance_to(pochodnia_na_ziemi) < 1.6:
		p.pochodnia_w_rece = true
		p.blok = false
		p.okno_parowania = 0.0
		pochodnia_na_ziemi = null
		swiatlo_pochodni_ziemia.visible = false
		Dzwiek.lup()
		napis(p.w - Vector2(0.9, 0.9), "POCHODNIA W DŁONI", Color("fbbf24"), 11)
	else:
		napis(p.w - Vector2(0.9, 0.9), "Pochodnia za daleko!" if pochodnia_na_ziemi != null else "Brak pochodni", Color("a8a29e"), 10)
	wezel_pochodni.queue_redraw()
	_licz_widok()


func zrzuc_sakwe() -> void:
	var p := gracz
	if okno_otwarte or p.martwy:
		return
	var zrzut: Array = []
	var zostaje: Array = []
	for it in p.rynsztunek["backpack"]:
		(zostaje if _na_pasie(it) else zrzut).append(it)
	if zrzut.is_empty():
		napis(p.w - Vector2(0.9, 0.9), "Sakwa pusta", Color("a8a29e"), 10)
		return
	p.rynsztunek["backpack"] = zostaje
	var lista: Array = []
	for it in zrzut:
		lista.append({"przedmiot": it, "odkryty": true})
	var gdzie := p.w - Vector2(cos(p.kat), sin(p.kat)) * 0.4
	_dodaj_zwloki({"w": gdzie, "rodzaj": "bag", "kat": 0.0, "nazwa": "Twoja porzucona sakwa", "boss": false, "sakwa": true, "przedmioty": lista})
	Dzwiek.blok()
	napis(p.w - Vector2(0.9, 0.9), "SAKWA ZRZUCONA (%d)" % zrzut.size(), Color("e6ba63"), 11)
	zmiana_ekwipunku.emit()


func uzyj_mikstury(rodzaj: String) -> void:
	var p := gracz
	if zakonczony or p.martwy:
		return
	for zrodlo in ["backpack", "reliquary"]:
		var lista: Array = p.rynsztunek[zrodlo]
		for i in lista.size():
			var def := Dane.p(lista[i]["id"])
			if def.get("elixKind") == rodzaj:
				lista.remove_at(i)
				Dzwiek.picie()
				match rodzaj:
					"heal":
						var lecz := roundi(float(def["healAmount"]) * (1.0 + Profil.budynek("alchemist") * 0.22))
						p.hp = minf(p.hp_max, p.hp + lecz)
						efekty.czastki_dodaj(p.w, 10, Color("f97316"), 2.0, 0.5)
						napis(p.w - Vector2(0.7, 0.7), "+%d HP" % lecz, Color("4ade80"), 12)
					"stamina":
						p.stamina = p.stamina_max
						p.dopalacz_staminy = 12.0
						efekty.czastki_dodaj(p.w, 10, Color("34d399"), 2.0, 0.5)
						napis(p.w - Vector2(0.7, 0.7), "PRZYPŁYW SIŁ!", Color("6ee7b7"), 12)
					"salve":
						p.plonie = false
						p.hp = minf(p.hp_max, p.hp + 18)
						efekty.czastki_dodaj(p.w, 8, Color("e6ba63"), 1.8, 0.45)
						napis(p.w - Vector2(0.7, 0.7), "UGASZONO +18 HP", Color("fbbf24"), 11)
				zmiana_ekwipunku.emit()
				return
	toast.emit("Brak tej mikstury!", "warn")


## Cios wroga w gracza. en == null dla strzał.
func trafienie_gracza(en, surowe: float, dystansowe := false) -> void:
	var p := gracz
	if p.martwy or p.riposta_niet > 0.0:
		return
	if p.unik_czas > 0.0:
		napis(p.w - Vector2(0.7, 0.7), "UNIK!", Color("6ee7b7"), 11)
		xp("endurance", 14)
		return
	if not dystansowe and p.okno_parowania > 0.0 and en != null:
		if en.ciezki:
			napis(p.w - Vector2(0.95, 0.95), "NIE DO SPAROWANIA!", Color("f87171"), 11)
		else:
			p.okno_parowania = 0.0
			en.ogluszenie = 2.8
			en.zamach = 0.0
			en.atak_timer = 2.8
			parowania += 1
			hitstop = 0.13
			blysk_parowania = 0.85
			wstrzas = minf(12.0, wstrzas + 8.0)
			Dzwiek.parowanie()
			efekty.czastki_dodaj((p.w + en.w) / 2.0, 22, Color("ffd166"), 4.5, 0.55)
			napis(en.w - Vector2(0.95, 0.95), "PAROWANIE! [ATAK = RIPOSTA]", Color("ffd166"), 13)
			xp("parry", 30)
			return
	var obr := surowe
	if p.blok and p.stamina > 6.0:
		var redukcja: float = 0.3 if p.pochodnia_w_rece else (float(Dane.p(p.rynsztunek["shield"]["id"])["blockRed"]) if p.rynsztunek["shield"] else 0.45)
		p.stamina = maxf(0.0, p.stamina - surowe * 0.65 * (1.8 if (en != null and en.ciezki) else 1.0))
		obr *= 1.0 - redukcja
		Dzwiek.blok()
		efekty.czastki_dodaj(p.w, 7, Color("d4c3a3"), 2.4, 0.25)
		napis(p.w - Vector2(0.65, 0.65), "BLOK -%d" % roundi(obr), Color("7dd3fc"), 11)
		if p.stamina <= 0.0:
			napis(p.w - Vector2(0.95, 0.95), "PRZEŁAMANIE BLOKU!", Color("f87171"), 11)
	else:
		var zbroja = p.rynsztunek["armor"]
		if zbroja and float(zbroja["durability"]) > 0.0:
			var red := float(Dane.p(zbroja["id"])["reduction"])
			var poch := obr * red
			zbroja["durability"] = maxf(0.0, float(zbroja["durability"]) - poch * 0.75)
			obr = maxf(2.0, obr - poch)
		Dzwiek.bol()
		blysk_trafienia = 0.85
		wstrzas = minf(12.0, wstrzas + 6.0)
		efekty.czastki_dodaj(p.w, 10, Color("a31820"), 2.6, 0.45)
		napis(p.w - Vector2(0.6, 0.6), "-%d" % roundi(obr), Color("ff4d4d"), 12)
		if en != null and en.boss and mapa.rng_wrogowie.randf() < 0.35 and not p.plonie:
			p.plonie = true
			napis(p.w - Vector2(0.9, 0.9), "POPARZENIE ŻAREM!", Color("f97316"), 11)
			toast.emit("Płoniesz! Użyj Maści z Popiołu [3]!", "danger")
	p.hp = maxf(0.0, p.hp - obr)
	if p.hp <= 0.0:
		zakoncz(false, "Poległeś w mroku ruin.")


func zabij(en: Wrog) -> void:
	wrogowie.erase(en)
	zabici += 1
	efekty.czastki_dodaj(en.w, 16, Color("8f151d"), 3.2, 0.65)
	var r := mapa.rng_lup
	var lup: Array = []
	if en.boss:
		for id in ["ash_crown", "ancient_relic", "ash_essence", "ash_greatsword"]:
			lup.append(Profil.nowy_przedmiot(id))
		toast.emit("🏆 POKONANO POPIELNEGO STRAŻNIKA! Przeszukaj jego szczątki!", "success")
	else:
		if r.randf() < 0.65:
			lup.append(Profil.nowy_przedmiot("iron_ingot" if r.randf() < 0.5 else "ash_essence"))
		if en.rodzaj == "archer":
			lup.append(Profil.nowy_przedmiot("iron_arrows", 8))
		if en.rodzaj == "warden" and r.randf() < 0.55:
			lup.append(Profil.nowy_przedmiot("iron_kite" if r.randf() < 0.5 else "runic_ring"))
		if en.rodzaj == "knight" and r.randf() < 0.5:
			lup.append(Profil.nowy_przedmiot("chainmail_hauberk" if r.randf() < 0.6 else "ancient_relic"))
		if en.rodzaj == "brute":
			lup.append(Profil.nowy_przedmiot("iron_ingot"))
			if r.randf() < 0.08:
				lup.append(Profil.nowy_przedmiot("executioner_axe"))
			elif r.randf() < 0.35:
				lup.append(Profil.nowy_przedmiot("golden_idol"))
		if r.randf() < 0.45:
			lup.append(Profil.nowy_przedmiot("ember_flask"))
		if lup.is_empty():
			lup.append(Profil.nowy_przedmiot("silver_goblet"))
	var lista: Array = []
	for it in lup:
		lista.append({"przedmiot": it, "odkryty": false})
	en.queue_free()
	_dodaj_zwloki({"w": en.w, "rodzaj": en.rodzaj, "kat": en.kat, "nazwa": "Szczątki: " + en.nazwa, "boss": en.boss, "sakwa": false, "przedmioty": lista})


func _dodaj_zwloki(z: Dictionary) -> void:
	var wezel: Node2D
	if z["sakwa"]:
		wezel = Node2D.new()
		wezel.draw.connect(func():
			wezel.draw_rect(Rect2(-9, -14, 18, 15), Color("5a3d24"))
			wezel.draw_rect(Rect2(-7, -18, 14, 6), Color("7a5532"))
			wezel.draw_rect(Rect2(-9, -9, 18, 2), Color("c79c4c")))
	else:
		var s := Sprite2D.new()
		s.texture = load("res://zasoby/en_%s.webp" % z["rodzaj"])
		s.hframes = 4
		s.vframes = 2
		s.frame = 7
		var sk := 0.9 if z["boss"] else 0.78
		s.scale = Vector2(sk, sk)
		var fh := 192.0 if z["boss"] else 128.0
		s.offset = Vector2(0, -(fh * 0.93 - fh * 0.5))
		s.flip_h = Iso.kierunek_arkusza(z["kat"])["sdx"] < 0.0
		s.modulate = Color(0.85, 0.85, 0.85)
		wezel = s
	wezel.position = Iso.ekran(z["w"]) + Vector2(0, 2)
	swiat.add_child(wezel)
	z["wezel"] = wezel
	zwloki.append(z)


func najblizszy_pojemnik():
	var najlepszy = null
	var nd := 1.7
	for s in mapa.skrzynie:
		var d: float = s["w"].distance_to(gracz.w)
		if d < nd:
			nd = d
			najlepszy = s
	for z in zwloki:
		var d2: float = z["w"].distance_to(gracz.w)
		if d2 < nd:
			nd = d2
			najlepszy = z
	return najlepszy


func interakcja() -> void:
	if okno_otwarte or gracz.martwy:
		return
	var p = najblizszy_pojemnik()
	if p != null:
		otworz(p)


func otworz(pojemnik) -> void:
	okno_otwarte = true
	aktywny_pojemnik = pojemnik
	postep_szukania = 0.0
	gracz.blok = false
	if pojemnik != null:
		Dzwiek.lup()
	otworz_okno.emit(pojemnik)


func zamknij_okno() -> void:
	blokada_wejscia = 0.2
	okno_otwarte = false
	aktywny_pojemnik = null


# ---------------------------------------------------------------- PĘTLA
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		mysz_aktywna = true
	elif e is InputEventJoypadMotion and absf(e.axis_value) > 0.4:
		mysz_aktywna = false


func _process(dt_surowe: float) -> void:
	var dt := minf(0.05, dt_surowe)
	if zakonczony:
		if gracz.martwy:
			gracz.smierc_anim += dt
			gracz.animuj(czas)
		czas += dt
		efekty.aktualizuj(dt)
		return
	if not okno_otwarte:
		if Input.is_action_just_pressed("atak"):
			bufor_ataku = 0.25
		if Input.is_action_just_pressed("unik"):
			bufor_uniku = 0.2
	if hitstop > 0.0:
		hitstop -= dt
		return
	_wejscie()
	_aktualizuj(dt)
	_kamera(dt)


func _wejscie() -> void:
	if okno_otwarte:
		return
	if blokada_wejscia > 0.0:
		blokada_wejscia -= get_process_delta_time()
		return
	var p := gracz
	var ruch := Input.get_vector("ruch_lewo", "ruch_prawo", "ruch_gora", "ruch_dol")
	var cel := Input.get_vector("celuj_lewo", "celuj_prawo", "celuj_gora", "celuj_dol")
	if cel.length() > 0.3:
		var c := Iso.ekran_na_swiat_kierunek(cel)
		p.kat = atan2(c.y, c.x)
	elif mysz_aktywna:
		var m := Iso.swiat(get_global_mouse_position())
		p.kat = atan2(m.y - p.w.y, m.x - p.w.x)
	elif ruch.length() > 0.3 and p.atak_czas <= 0.0:
		var c2 := Iso.ekran_na_swiat_kierunek(ruch)
		p.kat = atan2(c2.y, c2.x)
	if Input.is_action_just_pressed("parowanie"):
		parowanie_start()
	if not Input.is_action_pressed("parowanie"):
		p.blok = false
	var dt := get_process_delta_time()
	bufor_ataku = maxf(0.0, bufor_ataku - dt)
	bufor_uniku = maxf(0.0, bufor_uniku - dt)
	if bufor_uniku > 0.0 and p.unik_cd <= 0.0 and p.unik_czas <= 0.0:
		bufor_uniku = 0.0
		unik(Iso.ekran_na_swiat_kierunek(ruch))
	if (Input.is_action_pressed("atak") or bufor_ataku > 0.0) and p.atak_cd <= 0.0 and p.unik_czas <= 0.0:
		bufor_ataku = 0.0
		atak_wrecz()
	if Input.is_action_just_pressed("luk"):
		strzal_z_luku()
	if Input.is_action_just_pressed("interakcja"):
		interakcja()
	if Input.is_action_just_pressed("pochodnia"):
		pochodnia()
	if Input.is_action_just_pressed("zrzut_sakwy"):
		zrzuc_sakwe()
	for i in 3:
		if Input.is_action_just_pressed("mikstura_%d" % (i + 1)):
			uzyj_mikstury(["heal", "stamina", "salve"][i])
	if Input.is_action_just_pressed("sakwa"):
		otworz(null)


func _aktualizuj(dt: float) -> void:
	var p := gracz
	czas += dt
	czas_pozostaly = maxf(0.0, czas_pozostaly - dt)
	if czas_pozostaly <= 0.0:
		zakoncz(false, "Ciemność pochłonęła ruiny — czas wyprawy minął.")
		return

	# przeszukiwanie pojemnika
	if okno_otwarte and aktywny_pojemnik != null:
		for wpis in aktywny_pojemnik["przedmioty"]:
			if not wpis["odkryty"]:
				var tempo := 0.52 / (1.0 + (Profil.poziom("scavenger") - 1) * 0.15)
				postep_szukania += dt / tempo
				if postep_szukania >= 1.0:
					wpis["odkryty"] = true
					postep_szukania = 0.0
					Dzwiek.lup()
					zmiana_ekwipunku.emit()
				break

	for pole in ["atak_czas", "atak_cd", "combo_reset", "okno_parowania", "parowanie_cd", "unik_cd", "luk_cd", "dopalacz_staminy", "zamach_anim", "riposta_niet"]:
		p.set(pole, maxf(0.0, p.get(pole) - dt))
	var odnowa := 24.0 * (1.0 + (Profil.poziom("endurance") - 1) * 0.08) * (1.65 if p.dopalacz_staminy > 0.0 else 1.0)
	var mnoznik := 0.35 if p.blok else (0.2 if p.atak_czas > 0.0 else 1.0)
	var ciezar := maxf(0.55, 1.0 - sakwa_obciazenie() * 0.035)
	p.stamina = minf(p.stamina_max, p.stamina + odnowa * mnoznik * ciezar * dt)

	p.w_ruchu = false
	if not okno_otwarte:
		if p.unik_czas > 0.0:
			p.unik_czas -= dt
			przesun(p, p.unik_kier * 7.6 * dt)
			p.w_ruchu = true
			p.krok_anim += dt * 14.0
		else:
			var ruch := Iso.ekran_na_swiat_kierunek(Input.get_vector("ruch_lewo", "ruch_prawo", "ruch_gora", "ruch_dol"))
			if ruch != Vector2.ZERO:
				var v := 1.9 if p.blok else (1.6 if p.atak_czas > 0.0 else 3.4)
				przesun(p, ruch * v * dt)
				p.w_ruchu = true
				p.krok_anim += dt * (5.0 if p.blok else 8.0)
				p.krok_dzwiek -= dt
				if p.krok_dzwiek <= 0.0:
					Dzwiek.krok()
					p.krok_dzwiek = 0.38

	if p.plonie:
		p.plon_tik += dt
		if p.plon_tik >= 1.1:
			p.plon_tik = 0.0
			p.hp = maxf(0.0, p.hp - 3.0)
			efekty.czastki_dodaj(p.w, 3, Color("f97316"), 1.2, 0.35)
			if p.hp <= 0.0:
				zakoncz(false, "Spopielił Cię żar strażnika.")
				return

	# ekstrakcja
	var w_kregu := false
	for e in mapa.ekstrakcje:
		if randf() < 0.35:
			efekty.czastka(e["w"] + Vector2(randf() - 0.5, randf() - 0.5) * 0.9, 0.1, Vector3(0, 0, 1.5), Color("34d399") if randf() < 0.5 else Color("a7f3d0"), 1.1, 3)
		if p.w.distance_to(e["w"]) < float(e["promien"]):
			w_kregu = true
	if w_kregu:
		w_ekstrakcji = true
		ekstrakcja_czas -= dt
		var sek := int(ceil(ekstrakcja_czas))
		if sek < ekstrakcja_sek and sek > 0:
			ekstrakcja_sek = sek
			Dzwiek.tik()
		if ekstrakcja_czas <= 0.0:
			zakoncz(true, "Bezpiecznie powróciłeś do Warowni ze zdobytym łupem!")
			return
	else:
		w_ekstrakcji = false
		ekstrakcja_czas = CZAS_EKSTRAKCJI
		ekstrakcja_sek = 6

	_wrogowie(dt)
	if zakonczony:
		return
	_strzaly(dt)
	for k in mapa.kosze:
		if randf() < 0.25:
			efekty.czastka(k + Vector2(randf() - 0.5, randf() - 0.5) * 0.2, 0.75, Vector3((randf() - 0.5) * 0.3, (randf() - 0.5) * 0.3, 1.4 + randf()),
				Color("e06324") if randf() < 0.5 else Color("ffd166"), 0.7, 2)
	if p.pochodnia_w_rece and randf() < 0.3:
		efekty.czastki_dodaj(p.w - Vector2(0.05, 0.05), 1, Color("ffb347"), 0.6, 0.4)
	efekty.aktualizuj(dt)
	blysk_trafienia = maxf(0.0, blysk_trafienia - dt * 2.8)
	blysk_parowania = maxf(0.0, blysk_parowania - dt * 3.0)
	wstrzas = maxf(0.0, wstrzas - dt * 24.0)
	timer_widoku -= dt
	if timer_widoku <= 0.0:
		_licz_widok()
		timer_widoku = 0.08
	p.animuj(czas)
	for en in wrogowie:
		var v := widoczne(en.w)
		en.visible = v == 2
		en.widoczny_dla_gracza = v == 2
		en.animuj(czas)
	for z in zwloki:
		z["wezel"].visible = widoczne(z["w"]) > 0
	if pochodnia_na_ziemi != null:
		wezel_pochodni.queue_redraw()
	strzaly_wezel.queue_redraw()


func _wrogowie(dt: float) -> void:
	var p := gracz
	for en in wrogowie.duplicate():
		if en.uspiony:
			continue
		en.trafiony = maxf(0.0, en.trafiony - dt)
		en.cios_anim = maxf(0.0, en.cios_anim - dt)
		if en.postura_przerwa > 0.0:
			en.postura_przerwa -= dt
		elif en.postura < en.postura_max:
			en.postura = minf(en.postura_max, en.postura + en.postura_max * 0.25 * dt)
		if en.ogluszenie > 0.0:
			en.ogluszenie -= dt
			continue
		var d: Vector2 = p.w - en.w
		var dist: float = d.length()
		var widzi: bool = dist < (12.0 if en.boss else 9.5) and linia_wzroku(en.w, p.w)
		if widzi:
			en.stan = "walka"
		if en.zamach > 0.0:
			en.zamach -= dt
			if en.zamach <= 0.0:
				if en.rodzaj == "archer":
					Dzwiek.cieciwa()
					var kier := Vector2(cos(en.kat), sin(en.kat))
					strzaly.append({"w": en.w + kier * 0.4, "v": kier * 18.0, "dmg": en.dmg, "zasieg": 12.0, "od_gracza": false})
				else:
					Dzwiek.zamach(en.boss or en.rodzaj == "warden")
					en.cios_anim = 0.22
					przesun(en, Vector2(cos(en.kat), sin(en.kat)) * 0.28)
					if p.w.distance_to(en.w) <= en.zasieg + p.promien + 0.25:
						trafienie_gracza(en, en.dmg)
						if zakonczony:
							return
				en.atak_timer = en.cd_max * (0.72 if (en.boss and en.hp < en.hp_max * 0.5) else 1.0)
			continue
		en.atak_timer = maxf(0.0, en.atak_timer - dt)
		if en.stan == "walka":
			en.kat = atan2(d.y, d.x)
			var kier2 := Vector2(cos(en.kat), sin(en.kat))
			if en.rodzaj == "archer":
				if dist > 7.5:
					przesun(en, kier2 * en.spd * dt)
					en.krok_anim += dt * 6.0
				elif dist < 4.2:
					przesun(en, -kier2 * en.spd * 0.8 * dt)
					en.krok_anim += dt * 5.0
				if widzi and dist <= en.zasieg and en.atak_timer <= 0.0:
					en.zamach = en.zamach_dl
			else:
				if dist > en.zasieg - 0.15:
					var v: float = en.spd * (1.25 if (en.boss and en.hp < en.hp_max * 0.5) else 1.0)
					przesun(en, kier2 * v * dt)
					en.krok_anim += dt * 7.0
				elif en.atak_timer <= 0.0:
					en.zamach = en.zamach_dl
			if dist > 15.0:
				en.stan = "patrol"
		else:
			var dp: Vector2 = en.cel_patrolu - en.w
			if dp.length() < 0.5 or randf() < 0.008:
				en.cel_patrolu = Vector2(clampf(en.w.x + (randf() - 0.5) * 6.0, 3, N - 4), clampf(en.w.y + (randf() - 0.5) * 6.0, 3, N - 4))
			else:
				en.kat = atan2(dp.y, dp.x)
				przesun(en, dp.normalized() * 1.1 * dt)
				en.krok_anim += dt * 4.0


func _strzaly(dt: float) -> void:
	for i in range(strzaly.size() - 1, -1, -1):
		var a: Dictionary = strzaly[i]
		var krok: Vector2 = a["v"] * dt
		a["w"] += krok
		a["zasieg"] -= krok.length()
		if a["zasieg"] <= 0.0 or pelne(a["w"].x, a["w"].y):
			if pelne(a["w"].x, a["w"].y):
				efekty.czastki_dodaj(a["w"], 4, Color("d4c3a3"), 2.0, 0.25)
			strzaly.remove_at(i)
			continue
		if a["od_gracza"]:
			for en in wrogowie:
				if en.w.distance_to(a["w"]) < en.promien + 0.2:
					var obr: float = a["dmg"] * (1.0 - en.pancerz * 0.7)
					en.hp -= obr
					en.trafiony = 0.14
					en.stan = "walka"
					postura(en, a["dmg"] * 0.4)
					Dzwiek.trafienie()
					efekty.czastki_dodaj(a["w"], 6, Color("b51d29"), 2.4, 0.35)
					napis(en.w - Vector2(0.6, 0.6), "-%d" % roundi(obr), Color("fbbf24"), 12)
					xp("archery", 16)
					if en.hp <= 0.0:
						zabij(en)
					strzaly.remove_at(i)
					break
		elif gracz.w.distance_to(a["w"]) < gracz.promien + 0.16:
			trafienie_gracza(null, a["dmg"], true)
			strzaly.remove_at(i)
			if zakonczony:
				return


func _kamera(dt: float) -> void:
	var p := gracz
	var cel := Iso.ekran(p.w) + Vector2(cos(p.kat) * 28.0, sin(p.kat) * 18.0) + Vector2(0, -30)
	kamera.position = kamera.position.lerp(cel, minf(1.0, dt * 8.0))
	kamera.offset = Vector2(randf() - 0.5, randf() - 0.5) * wstrzas if wstrzas > 0.0 else Vector2.ZERO


# ---------------------------------------------------------------- KONIEC RAJDU
func zakoncz(przezyl: bool, powod: String) -> void:
	if zakonczony:
		return
	zakonczony = true
	okno_otwarte = false
	var p := gracz
	p.martwy = not przezyl and p.hp <= 0.0
	if p.martwy:
		Dzwiek.bol()
		blysk_trafienia = 1.0
	var prof := Profil.d
	prof["stats"]["raids"] += 1
	prof["stats"]["kills"] += zabici
	prof["stats"]["parries"] += parowania
	var wartosc := 0
	var l: Dictionary = p.rynsztunek
	if przezyl:
		Dzwiek.ekstrakcja()
		prof["stats"]["survived"] += 1
		var zostaje: Array = []
		for it in l["backpack"]:
			var t := Dane.typ(it["id"])
			wartosc += Dane.cena_skupu(it["id"])
			if (t == "valuable" or t == "material") and prof["stash"].size() < Profil.max_skrytka():
				prof["stash"].append(it)
			else:
				zostaje.append(it)
		l["backpack"] = zostaje
		prof["loadout"] = l
	else:
		prof["loadout"] = {"weapon": null, "shield": null, "bow": null, "armor": null, "backpack": [], "reliquary": l["reliquary"]}
	# Fundament: po śmierci postęp zostaje, ale mniejszy (połowa doświadczenia)
	var mnoznik_xp := 1.0 if przezyl else 0.5
	var awanse: Array = []
	var polacz := func(u, lv): awanse.append([u, lv])
	Profil.awans.connect(polacz)
	for u in xp_rajdu:
		Profil.dodaj_xp(u, xp_rajdu[u] * mnoznik_xp)
	Profil.awans.disconnect(polacz)
	if Profil.budynek("alchemist") > 0 and prof["stash"].size() < Profil.max_skrytka():
		prof["stash"].append(Profil.nowy_przedmiot("ember_flask"))
	Profil.zapisz()
	var podsumowanie := {"kraina": kraina["name"], "ziarno": ziarno, "czas": czas, "zabici": zabici, "parowania": parowania,
		"wartosc": wartosc, "mnoznik_xp": mnoznik_xp, "awanse": awanse}
	var opoznienie := 1.7 if p.martwy else 0.0
	if opoznienie > 0.0:
		await get_tree().create_timer(opoznienie).timeout
	koniec.emit(przezyl, powod, podsumowanie)
