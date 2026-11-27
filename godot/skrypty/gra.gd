extends Node
## Korzeń gry: Warownia ⇄ rajd ⇄ ekran wyniku. Tryb testu: godot --path godot -- --test [--zrzuty=/katalog] [--zapis=/plik.json]

const Mapgen = preload("res://skrypty/mapgen.gd")
const MapgenLas = preload("res://skrypty/mapgen_las.gd")
const MapgenOsada = preload("res://skrypty/mapgen_osada.gd")
const Ui = preload("res://skrypty/ui.gd")
const Hub = preload("res://skrypty/hub.gd")
const Rajd = preload("res://skrypty/rajd.gd")
const Hud = preload("res://skrypty/hud.gd")
const Okno = preload("res://skrypty/okno_lupu.gd")
const Przystan = preload("res://skrypty/przystan.gd")
const Pauza = preload("res://skrypty/pauza.gd")
const EkranTytulowy = preload("res://skrypty/ekran_tytulowy.gd")

var hub_warstwa: CanvasLayer
var hub: Hub
var przystan: Przystan
var rajd: Rajd
var hud: Hud
var okno: Okno
var pauza: Pauza
var wynik: CanvasLayer
var wynik_przycisk: Button
var ostatni_wynik := {}
var tytul: EkranTytulowy
var _w_tytule := false


func _ready() -> void:
	randomize()
	hub_warstwa = CanvasLayer.new()
	add_child(hub_warstwa)
	hub = Hub.new()
	hub.start_rajdu.connect(rozpocznij_rajd)
	hub.zamknij.connect(zamknij_menu)
	hub_warstwa.add_child(hub)
	pauza = Pauza.new()
	add_child(pauza)
	pauza.porzucono_rajd.connect(_porzuc_rajd)
	# HUD chowa się pod pauzą (nie przebija licznikiem, minimapą ani podpowiedziami)
	pauza.otwarto.connect(func(): if hud != null and is_instance_valid(hud): hud.visible = false)
	pauza.wznowiono.connect(func(): if hud != null and is_instance_valid(hud) and rajd != null: hud.visible = true)
	pauza.zresetowano.connect(func():
		hub.odswiez()
		if przystan != null:
			przystan.odswiez_budynki())
	_przystan()
	tytul = EkranTytulowy.new()
	tytul.visible = false
	add_child(tytul)
	tytul.kontynuuj.connect(zamknij_tytul)
	tytul.opcje.connect(func():
		tytul.visible = false
		pauza.otworz("Warownia Popiołów", false)
		pauza.zakladki.current_tab = 2)
	pauza.wznowiono.connect(func(): if _w_tytule: tytul.visible = true; tytul.przycisk_opcje.grab_focus())
	var narzedzia_agenta := false
	for a in OS.get_cmdline_user_args():
		if a in ["--test", "--test-ekonomii", "--test-ulepszen", "--test-interakcji", "--test-pada"] or a.begins_with("--podglad") or a.begins_with("--pomiar"):
			narzedzia_agenta = true
	if not narzedzia_agenta:
		pokaz_tytul.call_deferred()
	if "--test-ekonomii" in OS.get_cmdline_user_args() or "--test-ulepszen" in OS.get_cmdline_user_args():
		_test_ekonomii.call_deferred()
	if "--test-pada" in OS.get_cmdline_user_args():
		_test_pada_i_powrotu.call_deferred()
	if "--test-interakcji" in OS.get_cmdline_user_args():
		_test_interakcji.call_deferred()
	if "--test" in OS.get_cmdline_user_args():
		_test.call_deferred()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--podglad="):
			_podglad.call_deferred(a.substr(10))
		if a.begins_with("--podglad-przystan="):
			_podglad_przystani.call_deferred(a.substr(19))
		if a.begins_with("--podglad-oprawy="):
			_podglad_oprawy.call_deferred(a.trim_prefix("--podglad-oprawy="))
		if a.begins_with("--podglad-walki="):
			_podglad_walki.call_deferred(a.substr(16))
		if a.begins_with("--podglad-ruchu="):
			_podglad_ruchu.call_deferred(a.substr(16))
		if a.begins_with("--pomiar="):
			_pomiar.call_deferred(a.substr(9))
		if a.begins_with("--podglad-lasu="):
			_podglad_lasu.call_deferred(a.substr(15))
		if a.begins_with("--podglad-osady="):
			_podglad_osady.call_deferred(a.substr(16))
		if a.begins_with("--podglad-krainy="):
			_podglad_krainy.call_deferred(a.substr(17))


## Podgląd oprawy walki dla agenta: --podglad-walki=katalog[,kraina]. Seria zrzutów klatka po klatce
## (cios, ciężki cios, zamach wroga, parowanie, riposta, trafienie gracza, śmierć wroga, boss). Bez asercji.
func _podglad_walki(arg: String) -> void:
	var cz := arg.split(",")
	_zrzuty = cz[0]
	DirAccess.make_dir_recursive_absolute(_zrzuty)
	Profil.resetuj()
	rozpocznij_rajd(cz[1] if cz.size() > 1 else "catacombs", "WALKA1")
	await _czekaj(0.3)
	var p = rajd.gracz
	p.pochodnia_w_rece = false
	for en in rajd.wrogowie:
		en.uspiony = true
	# dwóch wrogów przed graczem w otwartym miejscu startu
	var a = rajd.wrogowie[0]
	var b = rajd.wrogowie[1] if rajd.wrogowie.size() > 1 else null
	p.kat = 0.6
	var seria := func(nazwa: String, ile: int) -> void:
		for i in ile:
			await _zrzut("%s_%02d" % [nazwa, i])
	for en in [a, b]:
		if en != null:
			en.uspiony = true
			en.stan = "walka"
			en.atak_timer = 99.0
			en.hp_max = 400.0
			en.hp = 400.0
	_ustaw_wroga_przed(a, 1.35)
	if b != null:
		b.w = p.w + Vector2(cos(p.kat - 1.3), sin(p.kat - 1.3)) * 2.4
	await _czekaj(0.4)
	await _zrzut("w0_stoja")
	# zwykłe ciosy (combo 1, 2)
	rajd.atak_wrecz()
	await seria.call("w1_cios", 8)
	p.atak_cd = 0.0
	await _czekaj(0.1)
	rajd.atak_wrecz()
	p.atak_cd = 0.0
	rajd.atak_wrecz()
	await seria.call("w2_ciezki", 8)
	# zamach wroga z zapowiedzią
	_ustaw_wroga_przed(a, 1.3)
	a.kat = atan2(p.w.y - a.w.y, p.w.x - a.w.x)
	a.uspiony = false
	a.zamach = a.zamach_dl
	a.atak_timer = 0.0
	await seria.call("w3_zamach", 6)
	# parowanie w oknie
	p.riposta_niet = 0.0
	p.unik_czas = 0.0
	p.okno_parowania = 0.3
	rajd.trafienie_gracza(a, 12.0)
	a.uspiony = true
	await seria.call("w4_parowanie", 6)
	p.atak_cd = 0.0
	p.combo_reset = 0.0
	rajd.atak_wrecz()
	await seria.call("w5_riposta", 8)
	# trafienie gracza
	if b != null:
		b.uspiony = true
		p.riposta_niet = 0.0
		p.okno_parowania = 0.0
		p.blok = false
		rajd.trafienie_gracza(b, 14.0)
		await seria.call("w6_bol", 5)
	# śmierć wroga
	if is_instance_valid(a) and a.hp > 0.0:
		a.hp = 1.0
		p.atak_cd = 0.0
		rajd.atak_wrecz()
		await seria.call("w7_smierc", 10)
	print("PODGLAD WALKI gotowy")
	get_tree().quit(0)



## Próbka oprawy: jeden przeciwnik, ta sama pozycja i kamera dla czterech zdarzeń.
func _podglad_oprawy(katalog: String) -> void:
	_zrzuty = katalog
	DirAccess.make_dir_recursive_absolute(katalog)
	Profil.resetuj()
	rozpocznij_rajd("catacombs", "WALKA1")
	await _czekaj(0.3)
	var p = rajd.gracz
	var cel = null
	for en in rajd.wrogowie:
		en.uspiony = true
		if cel == null and not en.boss and en.rodzaj != "archer":
			cel = en
	if cel == null:
		get_tree().quit(1)
		return
	p.pochodnia_w_rece = false
	var poprawne := true
	var katalog_przedmiotow: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dane/przedmioty.json"))
	for id in katalog_przedmiotow:
		var ikona := Dane.ikona(str(id))
		if ikona == null or ikona.get_size() != Vector2(92, 92):
			push_error("Brak ikony: " + str(id))
			poprawne = false
	print("Sprawdzono ikony: ", katalog_przedmiotow.size())
	for nazwa in ["ciecie", "parowanie", "blok_iskry", "krew_bryzg"]:
		await _czekaj(0.9)
		_ustaw_wroga_przed(cel, 1.2)
		cel.kat = cel.w.angle_to_point(p.w)
		cel.ciezki = false
		cel.ogluszenie = 0.0
		p.niet = 0.0
		p.unik_czas = 0.0
		p.riposta_niet = 0.0
		p.okno_parowania = 0.2 if nazwa == "parowanie" else 0.0
		p.blok = nazwa == "blok_iskry"
		p.stamina = p.stamina_max
		if nazwa == "ciecie":
			cel.uspiony = false
			cel.zamach = 0.001
			p.niet = 0.1
			rajd._licz_widok()
			rajd._wrogowie(0.01)
			cel.uspiony = true
		else:
			rajd.trafienie_gracza(cel, 10.0)
		var znaleziono := false
		for efekt in rajd.swiat3d._efekty3d:
			var sprite: Sprite3D = efekt[0]
			if sprite.texture != null and sprite.texture.resource_path.get_file() == str(nazwa) + ".png" and sprite.texture.get_size() == Vector2(1024, 256) and sprite.hframes == 4:
				znaleziono = true
		poprawne = poprawne and znaleziono
		print("Kontakt ", nazwa, ": ", znaleziono)
		rajd.swiat3d._aktualizuj_efekty(0.06)
		await _zrzut("kontakt_" + str(nazwa))
	print("WYNIK OPRAWY: ", "OK" if poprawne else "BŁĄD")
	get_tree().quit(0 if poprawne else 1)

## Pomiar dla agenta: --pomiar=kraina — klatki na sekundę z całością i bez grup siatek (drzewa, runo, podłoże).
func _pomiar(kraina: String) -> void:
	Profil.resetuj()
	rozpocznij_rajd(kraina, "LAS01")
	for en in rajd.wrogowie:
		en.uspiony = true
	await _czekaj(3.0)
	var s3 = rajd.swiat3d
	for grupa in ["", "drz", "runo_", "podloga"]:
		for k in s3._mm:
			s3._mm[k].visible = grupa == "" or not String(k).begins_with(grupa)
		await _czekaj(0.5)
		var t0 := Time.get_ticks_msec()
		var f0 := Engine.get_frames_drawn()
		await _czekaj(3.0)
		print("POMIAR bez [%s]: %.1f kl/s" % [grupa, (Engine.get_frames_drawn() - f0) * 1000.0 / (Time.get_ticks_msec() - t0)])
	var ile := 0
	for k in s3._mm:
		ile += s3._mm[k].multimesh.instance_count
	print("POMIAR instancji: ", ile, " siatek MM: ", s3._mm.size(), " węzłów: ", s3.get_child_count())
	get_tree().quit(0)


## Pilot Czarnoboru dla agenta: --podglad-lasu=katalog[,ziarno;ziarno]. Zapisuje las_<ziarno>.json (rysuje
## narzedzia/podglad_lasu.py). Generator lasu nie jest jeszcze podpięty do rajdu.
func _podglad_lasu(arg: String) -> void:
	var cz := arg.split(",")
	var katalog: String = cz[0]
	DirAccess.make_dir_recursive_absolute(katalog)
	var ziarna: PackedStringArray = cz[1].split(";") if cz.size() > 1 else PackedStringArray(["CZARNOBOR1", "CZARNOBOR2", "CZARNOBOR3", "CZARNOBOR4"])
	for z in ziarna:
		var m = MapgenLas.new()
		m.generuj({"id": "czarnobor"}, z, 1)
		var f := FileAccess.open(katalog.path_join("las_%s.json" % z), FileAccess.WRITE)
		f.store_string(JSON.stringify(m.do_slownika()))
		f.close()
		print("LAS ", z, ": polan ", m.polany.size(), ", ścieżek ", m.sciezki.size(), ", skrzyń ", m.skrzynie.size(), ", wrogów ", m.spawny.size())
	get_tree().quit(0)


## Podgląd krainy dla agenta: --podglad-krainy=katalog,kraina[,ziarno]. Zrzuty z bohaterem w kilku miejscach
## mapy (start, każdy rodzaj miejsca, wnętrze chaty w osadzie). Wrogowie uśpieni. Bez asercji.
func _podglad_krainy(arg: String) -> void:
	var cz := arg.split(",")
	_zrzuty = cz[0]
	DirAccess.make_dir_recursive_absolute(_zrzuty)
	Profil.resetuj()
	rozpocznij_rajd(cz[1], cz[2] if cz.size() > 2 else "OSADA01")
	for en in rajd.wrogowie:
		en.uspiony = true
	await _czekaj(1.5)
	var m = rajd.mapa
	var miejsca: Array = [["start", m.start]]
	var byly := {}
	for p in m.polany:
		var typ := String(p["typ"])
		if not byly.has(typ):
			byly[typ] = true
			miejsca.append([typ, (p["c"] as Vector2) + Vector2(-2.5, -2.5)])
	if "domy" in m and not m.domy.is_empty():
		var rc: Rect2i = m.domy[0]["r"]
		miejsca.append(["chata", Vector2(rc.get_center()) + Vector2(0.5, 0.5)])
	for n in miejsca.size():
		var w: Vector2 = miejsca[n][1]
		if Mapgen.blokuje_ruch(m.kafel(int(w.x), int(w.y))):
			w = Vector2(int(w.x) + 2.5, int(w.y) + 2.5)
		rajd.gracz.w = w
		rajd._licz_widok()
		rajd.swiat3d.odswiez_widok()
		await _czekaj(1.6)
		await _zrzut("%02d_%s" % [n, miejsca[n][0]])
	get_tree().quit(0)


## Pilot Spalonej Osady dla agenta: --podglad-osady=katalog[,ziarno;ziarno]. Zapisuje osada_<ziarno>.json
## (rysuje narzedzia/podglad_osady.py). Generator osady nie jest jeszcze podpięty do rajdu.
func _podglad_osady(arg: String) -> void:
	var cz := arg.split(",")
	var katalog: String = cz[0]
	DirAccess.make_dir_recursive_absolute(katalog)
	var ziarna: PackedStringArray = cz[1].split(";") if cz.size() > 1 else PackedStringArray(["OSADA1", "OSADA2", "OSADA3", "OSADA4"])
	for z in ziarna:
		var m = MapgenOsada.new()
		m.generuj({"id": "spalona_osada"}, z, 1)
		var f := FileAccess.open(katalog.path_join("osada_%s.json" % z), FileAccess.WRITE)
		f.store_string(JSON.stringify(m.do_slownika()))
		f.close()
		print("OSADA ", z, ": miejsc ", m.polany.size(), ", ulic ", m.sciezki.size(), ", chat ", m.domy.size(), ", skrzyń ", m.skrzynie.size(), ", wrogów ", m.spawny.size())
	get_tree().quit(0)


## Podgląd ruchu Hadræna dla agenta (zbliżenie): bieg z zakrętem i nawrotem, zatrzymanie, blok/parowanie. Co 2 klatki zrzut.
func _podglad_ruchu(katalog: String) -> void:
	_zrzuty = katalog
	DirAccess.make_dir_recursive_absolute(katalog)
	Profil.resetuj()
	rozpocznij_rajd("catacombs", "WALKA1")
	await _czekaj(0.3)
	for en in rajd.wrogowie:
		en.uspiony = true
		en.w = Vector2(2.5, 2.5)
	rajd.gracz.pochodnia_w_rece = false
	hud.visible = false
	rajd.kamera.zoom = Vector2(3.0, 3.0)
	var kroki := [[Vector2(1, 0), 14, "bieg"], [Vector2(0, 1), 14, "zakret"], [Vector2(-1, 0), 14, "nawrot"], [Vector2.ZERO, 8, "stop"]]
	for k in kroki:
		_os(JOY_AXIS_LEFT_X, k[0].x)
		_os(JOY_AXIS_LEFT_Y, k[0].y)
		for i in k[1]:
			await _klatka()
			if i % 2 == 0:
				await _zrzut("r_%s_%02d" % [k[2], i])
	_przycisk(JOY_BUTTON_LEFT_SHOULDER, true)
	for i in 16:
		await _klatka()
		await _zrzut("r_parowanie_%02d" % i)
	_przycisk(JOY_BUTTON_LEFT_SHOULDER, false)
	print("PODGLAD RUCHU gotowy")
	get_tree().quit(0)


func _podglad_przystani(katalog: String) -> void:
	_zrzuty = katalog
	DirAccess.make_dir_recursive_absolute(katalog)
	await _czekaj(0.5)
	for i in 5:
		przystan.poz = [Vector2(18.0, 22.0), Vector2(13.0, 14.5), Vector2(14.0, 9.5), Vector2(24.0, 24.0), Vector2(10.6, 3.0)][i]
		await _czekaj(0.8)
		await _zrzut("przystan_%d" % i)
		print("PODGLAD przystan ", i)
	get_tree().quit(0)


## Podgląd oprawy dla agenta: --podglad=kraina,ziarno,katalog -> zrzuty kilku miejsc mapy (bez sterowania).
func _podglad(arg: String) -> void:
	var cz := arg.split(",")
	Profil.resetuj()
	rozpocznij_rajd(cz[0], cz[1])
	await _czekaj(0.3)
	var p = rajd.gracz
	for en in rajd.wrogowie:
		en.uspiony = true
	hud.visible = false
	var miejsca: Array = [p.w]
	for k in rajd.mapa.kosze:
		miejsca.append(k + Vector2(1.2, 0.8))
		if miejsca.size() >= 3:
			break
	if rajd.mapa.ekstrakcje.size() > 0:
		miejsca.append(rajd.mapa.ekstrakcje[0]["w"])
	if rajd.wrogowie.size() > 0:
		var en = rajd.wrogowie[0]
		miejsca.append(en.w + Vector2(1.2, 0.0))
	# --podglad=czarnobor,ziarno,katalog,woda -> ujęcia przy brodach strumienia (las)
	if cz.size() > 3 and cz[3] == "woda" and "teren" in rajd.mapa:
		miejsca = []
		var m = rajd.mapa
		for i in m.teren.size():
			if m.teren[i] == MapgenLas.T.BROD and i % 7 == 0 and miejsca.size() < 4:
				var w := Vector2(i % m.ROZMIAR + 0.5, i / m.ROZMIAR + 0.5)
				var daleko := true
				for q in miejsca:
					if (q as Vector2).distance_to(w) < 15.0:
						daleko = false
				if daleko:
					miejsca.append(w)
	# --podglad=kraina,ziarno,katalog,komnaty -> po jednym ujęciu z każdego rodzaju komnaty
	if cz.size() > 3 and cz[3] == "komnaty":
		miejsca = []
		var byly := {}
		for k in rajd.mapa.komnaty:
			if byly.has(k["typ"]):
				continue
			byly[k["typ"]] = true
			var rr: Rect2i = k["r"]
			for dy in range(1, rr.size.y - 1):
				var w := Vector2(rr.position.x + 1.5, rr.position.y + dy + 0.5)
				if not Mapgen.blokuje_ruch(rajd.mapa.kafel(int(w.x), int(w.y))):
					miejsca.append(w)
					print("KOMNATA ", miejsca.size() - 1, " ", k["typ"])
					break
	for i in miejsca.size():
		p.w = miejsca[i]
		p.kat = 2.4
		if i == miejsca.size() - 1 and rajd.wrogowie.size() > 0 and cz.size() <= 3:
			var en = rajd.wrogowie[0]
			en.uspiony = false
			en.stan = "walka"
			en.zamach = en.zamach_dl * 0.75
		await _czekaj(0.6)
		if i == miejsca.size() - 1 and rajd.wrogowie.size() > 0 and rajd.swiat3d and cz.size() <= 3:
			var en = rajd.wrogowie[0]
			p.pochodnia_w_rece = false
			en.kat = atan2(p.w.y - en.w.y, p.w.x - en.w.x)
			en.zamach = rajd.dlugosc_okna_parowania() * 0.6
			var d3: Dictionary = rajd.swiat3d._wrogowie[en.get_instance_id()]
			rajd.swiat3d._zapowiedz(en, d3, 1.0 - en.zamach / en.zamach_dl, true)
		_zrzuty = cz[2]
		DirAccess.make_dir_recursive_absolute(_zrzuty)
		await _zrzut("%s_%d" % [cz[0], i])
		print("PODGLAD ", cz[0], " ", i)
	get_tree().quit(0)


## Warownia-Przystań: miejsce startowe; menu Warowni (hub) otwiera się nad nią przy NPC i budynkach.
func _przystan() -> void:
	if przystan != null:
		return
	przystan = Przystan.new()
	add_child(przystan)
	move_child(przystan, 0)
	przystan.otworz.connect(otworz_menu)
	hub_warstwa.visible = false
	hub.visible = false


## Ekran tytułowy (etap 5 przebudowy menu): na starcie gry, przed Przystanią.
func pokaz_tytul() -> void:
	_w_tytule = true
	if przystan:
		przystan.aktywna = false
	tytul.pokaz()


func zamknij_tytul() -> void:
	_w_tytule = false
	tytul.visible = false
	Dzwiek.ui()
	if przystan and not hub.is_visible_in_tree():
		przystan.aktywna = true


func moze_pauzowac() -> bool:
	if _w_tytule:
		return false
	if rajd != null:
		return not rajd.zakonczony and not rajd.okno_otwarte
	return przystan != null and przystan.aktywna and not hub.is_visible_in_tree()


func otworz_pauze() -> void:
	if rajd != null:
		pauza.otworz(str(rajd.kraina["name"]), true, "Pokonani %d   ·   Parowania %d" % [rajd.zabici, rajd.parowania], str(rajd.kraina["id"]))
	else:
		pauza.otworz("Przystań · Warownia Popiołów", false)


func otworz_menu(zakladka: int) -> void:
	hub_warstwa.visible = true
	hub.visible = true
	if zakladka >= 0:
		hub.zakladki.current_tab = zakladka
	hub.odswiez()
	if przystan:
		przystan.aktywna = false


func zamknij_menu() -> void:
	if rajd != null or przystan == null:
		return
	hub_warstwa.visible = false
	hub.visible = false
	przystan.aktywna = true
	przystan.odswiez_budynki()


func _unhandled_input(e: InputEvent) -> void:
	# pauza: Esc / P / Start — w trwającym rajdzie (bez otwartego okna) i w Przystani (bez menu Warowni)
	if e.is_action_pressed("pauza") and not get_tree().paused and moze_pauzowac():
		otworz_pauze()
		get_viewport().set_input_as_handled()
		return
	# Back / Tab w Przystani: całe menu Warowni
	if przystan != null and przystan.aktywna and rajd == null and e.is_action_pressed("sakwa"):
		otworz_menu(-1)
		get_viewport().set_input_as_handled()


func rozpocznij_rajd(kraina: String, ziarno: String) -> void:
	Dzwiek.ui()
	if przystan:
		przystan.queue_free()
		przystan = null
	hub_warstwa.visible = false
	hub.visible = false
	rajd = Rajd.new()
	add_child(rajd)
	rajd.start(kraina, ziarno)
	hud = Hud.new()
	hud.rajd = rajd
	add_child(hud)
	okno = Okno.new()
	okno.rajd = rajd
	add_child(okno)
	rajd.otworz_okno.connect(okno.otworz)
	rajd.zmiana_ekwipunku.connect(okno.odswiez)
	rajd.toast.connect(hud.pokaz_toast)
	rajd.obszar.connect(hud.pokaz_obszar)
	rajd.koniec.connect(_koniec_rajdu)
	hud.pokaz_toast.call_deferred("Pochodnia zajmuje rękę tarczy: nie parujesz. F / krzyżak dół: rzuć ją przed walką.", "info")


func _koniec_rajdu(przezyl: bool, powod: String, s: Dictionary) -> void:
	ostatni_wynik = {"przezyl": przezyl, "powod": powod, "s": s}
	if okno:
		okno.visible = false
	if hud:
		hud.visible = false
	# Wynik wyprawy jak menu NightBrand (instrukcja przebudowy menu, etap 4): ilustracja biotopu w tle,
	# lewy panel = przebieg w tabeli par, prawy = łup jako ikony + suma złota, awanse z paskiem.
	wynik = CanvasLayer.new()
	wynik.layer = 30
	add_child(wynik)
	var tlo := Control.new()
	tlo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlo.theme = Ui.motyw()
	wynik.add_child(tlo)
	var czern := ColorRect.new()
	czern.color = Color.BLACK
	czern.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlo.add_child(czern)
	var obraz := TextureRect.new()
	obraz.texture = load("res://zasoby/ui/menu/%s.webp" % Pauza.TLA.get(str(s.get("kraina_id", "")), "tlo_menu_1"))
	obraz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	obraz.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	obraz.modulate = Color(0.5, 0.42, 0.4) if przezyl else Color(0.42, 0.3, 0.3)
	obraz.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlo.add_child(obraz)
	tlo.add_child(Ui.gradient_pionowy())
	tlo.add_child(Ui.winieta())
	var marg := MarginContainer.new()
	marg.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right"]:
		marg.add_theme_constant_override("margin_" + k, 110)
	marg.add_theme_constant_override("margin_top", 26)
	marg.add_theme_constant_override("margin_bottom", 24)
	tlo.add_child(marg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	marg.add_child(v)
	var t := Ui.naglowek_menu("EKSTRAKCJA UDANA" if przezyl else "POLEGŁEŚ", 44, Color("a7e8c4") if przezyl else Color("e87a6a"), 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 6)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	v.add_child(t)
	var sep := TextureRect.new()
	sep.texture = load("res://zasoby/ui/menu/separator_z_pietnem.webp")
	sep.custom_minimum_size = Vector2(300, 40)
	sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(sep)
	var pw := Ui.tekst_menu(powod, 15, Ui.M_DRUGI)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pw)
	var odst := Control.new()
	odst.custom_minimum_size = Vector2(0, 8)
	v.add_child(odst)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var pl := PanelContainer.new()
	pl.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(pl)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	pl.add_child(lv)
	lv.add_child(Ui.belka_sekcji("Przebieg wyprawy"))
	var m := int(s["czas"] / 60.0)
	var sek := int(s["czas"]) % 60
	lv.add_child(Ui.para("Kraina", str(s["kraina"]) + ("  (%s)" % s["ziarno"] if Ui.tryb_autora() else "")))
	lv.add_child(Ui.para("Czas wyprawy", "%d:%02d" % [m, sek]))
	lv.add_child(Ui.para("Pokonani wrogowie", str(s["zabici"])))
	lv.add_child(Ui.para("Udane parowania", str(s["parowania"])))
	lv.add_child(Ui.para("Rynsztunek", "zabezpieczony w Warowni" if przezyl else "utracony (Relikwiarz ocalał)", Ui.M_ZIELONY if przezyl else Ui.M_OSTRZ))
	lv.add_child(Ui.para("Doświadczenie", "zaliczone w całości" if przezyl else "zaliczona połowa", Ui.M_ZLOTO2 if przezyl else Ui.M_OSTRZ))
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(pp)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	pp.add_child(rv)
	rv.add_child(Ui.belka_sekcji("Łup"))
	var siatka := GridContainer.new()
	siatka.columns = 8
	siatka.add_theme_constant_override("h_separation", 6)
	siatka.add_theme_constant_override("v_separation", 6)
	for id in s.get("lup", []):
		var ik := TextureRect.new()
		ik.texture = Dane.ikona(str(id))
		ik.custom_minimum_size = Vector2(40, 40)
		ik.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ik.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ik.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ik.tooltip_text = str(Dane.p(str(id)).get("name", ""))
		siatka.add_child(ik)
	rv.add_child(siatka)
	if s.get("lup", []).is_empty():
		rv.add_child(Ui.tekst_menu("Sakwa wróciła pusta." if przezyl else "Łup przepadł w mroku.", 14, Ui.M_DRUGI))
	var zl := Ui.naglowek_menu("%d zł" % int(s["wartosc"]) if przezyl else "0 zł", 34, Ui.M_ZLOTO2)
	zl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(zl)
	var pz := Ui.tekst_menu("wartość łupu z sakwy", 12, Ui.M_DRUGI)
	pz.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(pz)
	for kt in s.get("kontrakty", []):
		rv.add_child(Ui.para("Kontrakt Chojraka", str(kt), Ui.M_ZIELONY))
	for a in s["awanse"]:
		rv.add_child(Ui.para("Awans: %s" % Dane.umiejetnosci[a[0]]["name"], "poziom %d" % a[1], Ui.M_ZLOTO2))
	var dol := HBoxContainer.new()
	dol.alignment = BoxContainer.ALIGNMENT_CENTER
	dol.custom_minimum_size = Vector2(0, 80)
	v.add_child(dol)
	wynik_przycisk = Ui.przycisk_menu("Powrót do Warowni", true)
	wynik_przycisk.custom_minimum_size = Vector2(340, 68)
	wynik_przycisk.pressed.connect(powrot_do_warowni)
	dol.add_child(wynik_przycisk)
	wynik_przycisk.grab_focus.call_deferred()
	Ui.blokada_po_otwarciu(self)


func powrot_do_warowni() -> void:
	for n in [rajd, hud, okno, wynik]:
		if n:
			n.queue_free()
	rajd = null
	hud = null
	okno = null
	wynik = null
	hub.zakladki.current_tab = 0
	hub.odswiez()
	_przystan()


func _porzuc_rajd() -> void:
	if rajd == null or rajd.zakonczony:return
	pauza.zamknij()
	rajd.koniec.disconnect(_koniec_rajdu)
	rajd.zakoncz(false, "Porzucono wyprawę.", true)
	powrot_do_warowni()


# ====================================================================== TEST AUTOMATYCZNY
var _wyniki: Array = []
var _zrzuty := ""


func _ok(nazwa: String, warunek: bool, szczegol := "") -> void:
	_wyniki.append(warunek)
	print(("  OK   " if warunek else "  BŁĄD ") + nazwa + ("  [" + szczegol + "]" if szczegol != "" else ""))


func _czekaj(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _czekaj_az(warunek: Callable, limit: float) -> void:
	var t := 0.0
	while not warunek.call() and t < limit:
		await _czekaj(0.1)
		t += 0.1


func _klatka() -> void:
	await get_tree().process_frame


func _pad(b: JoyButton, czas := 0.1) -> void:
	var z := InputEventJoypadButton.new()
	z.device = 0
	z.button_index = b
	z.pressed = true
	Input.parse_input_event(z)
	await _czekaj(czas)
	var z2 := InputEventJoypadButton.new()
	z2.device = 0
	z2.button_index = b
	z2.pressed = false
	Input.parse_input_event(z2)
	await _klatka()


func _os(os: JoyAxis, v: float) -> void:
	var z := InputEventJoypadMotion.new()
	z.device = 0
	z.axis = os
	z.axis_value = v
	Input.parse_input_event(z)


func _zrzut(nazwa: String) -> void:
	if _zrzuty == "":
		return
	await _klatka()
	get_viewport().get_texture().get_image().save_png(_zrzuty.path_join(nazwa + ".png"))


## Kram Margi: karty, szczegóły przy fokusie, porównanie z założonym, zablokowane nie do kupienia, zakup, tryb sprzedaży.
func _test_kramu() -> void:
	var kopia_profilu: Dictionary = Profil.d.duplicate(true)
	hub.tryb_kupca = "kup"
	hub.kategoria = "weapon"
	hub.zakladki.current_tab = 2
	hub.odswiez()
	await _klatka()
	var karty: Array = hub.t_kupiec.find_children("*", "Button", true, false).filter(func(b): return str(b.get_meta("klucz", "")).begins_with("kup_"))
	_ok("kram: karty broni", karty.size() >= 3, "%d kart" % karty.size())
	var stal = karty.filter(func(b): return b.get_meta("klucz") == "kup_steel_kordelas")
	var cel: Button = stal[0] if stal.size() > 0 else karty[1]
	cel.grab_focus()
	await _klatka()
	_ok("kram: fokus pokazuje szczegóły i porównanie z założonym", hub._sz_nazwa.text != "Wybierz przedmiot" and hub._sz_porown.text.begins_with("Założone"),
		"%s / %s" % [hub._sz_nazwa.text, hub._sz_porown.text])
	await _zrzut("1d_kram")
	var zablok: Array = karty.filter(func(b): return int(Dane.p(str(b.get_meta("klucz")).substr(4)).get("forgeReq", 0)) > Profil.budynek("forge"))
	if zablok.size() > 0:
		var z0 := int(Profil.d["gold"])
		Profil.d["gold"] = 99999
		(zablok[0] as Button).pressed.emit()
		_ok("kram: zablokowanego oręża nie kupisz (Kuźnia)", int(Profil.d["gold"]) == 99999)
		Profil.d["gold"] = z0
	var przed := int(Profil.d["gold"])
	hub._kup("ember_flask")
	_ok("kram: zakup zabiera złoto", int(Profil.d["gold"]) == przed - int(Dane.p("ember_flask")["price"]))
	Profil.d["gold"] = przed
	hub.tryb_kupca = "sprzedaj"
	hub.odswiez()
	await _klatka()
	var sp: Array = hub.t_kupiec.find_children("*", "Button", true, false).filter(func(b): return str(b.get_meta("klucz", "")).begins_with("sp_"))
	_ok("kram: tryb sprzedaży pokazuje łup", sp.size() > 0, "%d kart" % sp.size())
	hub.tryb_kupca = "kup"
	hub.kategoria = "all"
	Profil.d = kopia_profilu  # test nie zmienia profilu (zakup był tylko sprawdzeniem)


## Ekran tytułowy (etap 5): fokus na „Kontynuuj”, A po blokadzie 0,4 s prowadzi do Przystani; Opcje otwierają pauzę → Opcje.
func _test_tytulu() -> void:
	pokaz_tytul()
	await _klatka()
	await _klatka()
	_ok("ekran tytułowy: Warownia Popiołów, fokus na Kontynuuj", tytul.visible and get_viewport().gui_get_focus_owner() == tytul.przycisk_kontynuuj and not przystan.aktywna)
	await _zrzut("0_ekran_tytulowy")
	tytul.przycisk_opcje.pressed.emit()
	await _klatka()
	_ok("ekran tytułowy: Opcje otwierają pauzę na zakładce Opcje", pauza.visible and pauza.zakladki.current_tab == 2 and not tytul.visible)
	pauza.zamknij()
	await _klatka()
	_ok("ekran tytułowy: po Opcjach wraca", tytul.visible)
	await _czekaj(0.5)
	tytul.przycisk_kontynuuj.grab_focus()
	await _pad(JOY_BUTTON_A)
	await _czekaj_az(func(): return not tytul.visible, 2.0)
	_ok("ekran tytułowy: A na Kontynuuj → Przystań", not tytul.visible and przystan.aktywna)


## Szlif menu i UI (zlecenie autora 26.11, ocena NightBrand): jeden panel opisu w Kupcu, bez narzędzi autora
## na widoku gracza, Reset poza górnym paskiem, spokojne „wybrane”, znaczki LB/RB przy zakładkach.
func _test_szlifu_menu() -> void:
	hub.zakladki.current_tab = 0
	hub.odswiez()
	await _klatka()
	await _klatka()
	var kraina: Dictionary = Dane.krainy[0]
	var tekst_szczegolow := func() -> String:
		var t := ""
		for l in hub.ekran.szczegoly.find_children("*", "Label", true, false):
			t += (l as Label).text + "\n"
		return t
	var w_wyprawie: bool = tekst_szczegolow.call().contains(str(kraina["desc"])) or hub.wybrana_kraina != kraina["id"]
	hub.zakladki.current_tab = 2
	await _klatka()
	await _klatka()
	_ok("Wyprawa → Kupiec: szczegóły bez tekstu krainy (jeden panel opisu)", w_wyprawie and not tekst_szczegolow.call().contains(str(kraina["desc"])))
	var przed := int(Profil.d["gold"])
	Profil.d["gold"] = 0
	hub._kup("ember_flask")
	await _klatka()
	_ok("Kupiec: komunikat w prawym panelu", hub._sz_kom != null and hub._sz_kom.text == "Za mało złota!", hub._sz_kom.text if hub._sz_kom else "brak")
	Profil.d["gold"] = przed
	var gora := hub.find_children("*", "Button", true, false).filter(func(b): return b.text in ["Reset", "Dźwięk: wł.", "Dźwięk: wył."] or b.text.begins_with("Grafika:"))
	_ok("Warownia: Reset, Dźwięk i Grafika nie w menu Warowni (są w Opcjach pauzy)", gora.is_empty())
	hub.zakladki.current_tab = 0
	await _klatka()
	await _klatka()
	var pole_ziarna := hub.ekran.find_children("*", "LineEdit", true, false)
	_ok("Wyprawa: ziarno mapy i Losuj ukryte (tylko tryb autora)", pole_ziarna.size() > 0 and not (pole_ziarna[0] as LineEdit).is_visible_in_tree())
	var wybrany: Array = hub.ekran.lista.find_children("*", "Button", true, false).filter(func(b): return b.get_meta("klucz", "") == "kraina_" + hub.wybrana_kraina)
	var nazwa_wybranej: Label = wybrany[0].get_meta("etykieta_nazwy") if wybrany.size() == 1 else null
	_ok("wybrana kraina: znak ◆, nie biała ramka", nazwa_wybranej != null and nazwa_wybranej.text.begins_with("◆") and not (wybrany[0] as Button).get_theme_stylebox("normal") is StyleBoxFlat)
	var znaki_ok := true
	var krain := 0
	for b in hub.ekran.lista.find_children("*", "Button", true, false):
		if str(b.get_meta("klucz", "")).begins_with("kraina_"):
			krain += 1
			var t := ""
			for l in b.find_children("*", "Label", true, false):
				t += (l as Label).text
			var n := 0
			for ch in t:
				if ch == "◆" or ch == "◇":
					n += 1
			znaki_ok = znaki_ok and (n == 4 or n == 5)  # 4 znaki trudności (+ ◆ przy wybranej)
	_ok("trudność: jedna skala znaków (◆◆◇◇)", krain >= 3 and znaki_ok, "%d krain" % krain)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	_ok("pad: menu wie, że gra się padem (znaczki LB/RB)", Sterowanie.pad_aktywny)
	await _zrzut("2b_wyprawa_pad")
	# każda sekcja na szablonie: tytuł, lista z wierszami, szczegóły
	var sekcje_ok := true
	for i in 5:
		hub.zakladki.current_tab = i
		await _klatka()
		var wiersze := hub.ekran.lista.find_children("*", "Button", true, false).size()
		var szczeg := hub.ekran.szczegoly.get_child_count()
		sekcje_ok = sekcje_ok and wiersze > 0 and szczeg > 0 and hub.ekran.tytul.text == hub.TYTULY[i] and hub.ekran.aktywna == i
		await _zrzut("menu_%d_%s" % [i, hub.SEKCJE[i].to_lower()])
	_ok("menu Warowni: 5 sekcji na szablonie (lista + szczegóły)", sekcje_ok)
	# odbiór instrukcji §6: (b) RB i LB zmieniają sekcję na każdym ekranie, (c) B wraca z każdego ekranu do Przystani
	var nawig_ok := true
	var nawig_info := []
	for i in 5:
		otworz_menu(i)
		await _czekaj(0.45)  # blokada 0,4 s po otwarciu ekranu
		await _pad(JOY_BUTTON_RIGHT_SHOULDER)
		var po_rb: int = hub.zakladki.current_tab
		await _pad(JOY_BUTTON_LEFT_SHOULDER)
		var po_lb: int = hub.zakladki.current_tab
		await _pad(JOY_BUTTON_B)
		await _czekaj_az(func(): return not hub.is_visible_in_tree(), 2.0)
		var wrocil: bool = not hub.is_visible_in_tree() and przystan != null and przystan.aktywna
		if po_rb != (i + 1) % 5 or po_lb != i or not wrocil:
			nawig_ok = false
			nawig_info.append("%s: RB→%d LB→%d B %s" % [hub.SEKCJE[i], po_rb, po_lb, wrocil])
	_ok("menu: LB/RB zmieniają sekcję i B wraca do Przystani z każdego ekranu", nawig_ok, ", ".join(nawig_info))
	otworz_menu(0)
	await _czekaj(0.45)
	# Warownia: rozbudowa z wiersza działa jak dawniej (te same koszty)
	hub.zakladki.current_tab = 3
	await _klatka()
	var kopia: Dictionary = Profil.d.duplicate(true)
	Profil.d["gold"] = 99999
	for s in ["iron", "ash", "relic"]:
		for j in 6:
			Profil.d["stash"].append(Profil.nowy_przedmiot({"iron": "iron_ingot", "ash": "ash_essence", "relic": "ancient_relic"}[s]))
	var lv0 := Profil.budynek("forge")
	hub._rozbuduj("forge")
	_ok("Warownia: rozbudowa Kuźni z menu", Profil.budynek("forge") == lv0 + 1, "poziom %d → %d" % [lv0, Profil.budynek("forge")])
	Profil.d = kopia
	hub.zakladki.current_tab = 2
	await _klatka()
	await _zrzut("1e_kram_szlif")


## Namierzanie i celowanie (decyzja autora 26.11.2026): kursor nie obraca postaci, klik na wroga = cios w niego,
## riposta w najbliższego ogłuszonego, brak doskoku bez celu, namierzanie R / R3.
func _test_namierzania(p, en) -> void:
	var drugi = null
	for w in rajd.wrogowie:
		if w != en and not w.boss:
			drugi = w
			break
	en.uspiony = true
	en.atak_timer = 99.0
	en.ogluszenie = 0.0
	# kursor nie obraca postaci
	var w0: Vector2 = en.w
	en.w = Vector2(2.5, 2.5)
	if drugi:
		drugi.uspiony = true
		drugi.w = Vector2(2.5, 2.5)
	rajd.mysz_aktywna = true
	p.kat = 0.3
	await _czekaj(0.3)
	_ok("kursor nie obraca postaci", absf(angle_difference(p.kat, 0.3)) < 0.01, "kąt %.2f" % p.kat)
	# bez celu: brak doskoku (nie wjeżdża w ścianę)
	p.atak_cd = 0.0
	p.stamina = p.stamina_max
	rajd.bufor_ataku = 0.0
	var w_przed: Vector2 = p.w
	rajd.atak_wrecz()
	_ok("cios bez wroga: brak doskoku", p.w.distance_to(w_przed) < 0.001)
	await _czekaj_az(func(): return p.zamach_anim <= 0.0, 3.0)
	# klik na wroga z boku: cios celuje w niego
	var bok := Vector2(cos(p.kat + 1.6), sin(p.kat + 1.6))
	en.w = p.w + bok * 1.4
	if rajd.pelne(en.w.x, en.w.y):
		en.w = p.w - bok * 1.4
	en.widoczny_dla_gracza = true
	rajd._klik_cel = en
	rajd._klik_czas = 0.5
	p.atak_cd = 0.0
	p.stamina = p.stamina_max
	rajd.atak_wrecz()
	var do_en: Vector2 = en.w - p.w
	_ok("klik na wroga: cios w jego stronę", absf(angle_difference(p.kat, atan2(do_en.y, do_en.x))) < 0.05)
	await _czekaj_az(func(): return p.zamach_anim <= 0.0, 3.0)
	# riposta w najbliższego ogłuszonego (nawet gdy inny stoi na wprost)
	if drugi:
		drugi.w = p.w + Vector2(cos(p.kat + PI), sin(p.kat + PI)) * 1.0
		if rajd.pelne(drugi.w.x, drugi.w.y):
			drugi.w = p.w + Vector2(cos(p.kat), sin(p.kat)) * 1.0
		drugi.widoczny_dla_gracza = true
		drugi.ogluszenie = 2.0
		var hp_d: float = drugi.hp
		p.atak_cd = 0.0
		p.stamina = p.stamina_max
		rajd.atak_wrecz()
		await _po_cieciu()
		_ok("riposta trafia najbliższego ogłuszonego wroga", drugi.ogluszenie <= 0.0 and drugi.hp < hp_d, "HP %.0f → %.0f" % [hp_d, drugi.hp])
		drugi.w = Vector2(2.5, 2.5)
		drugi.hp = drugi.hp_max
		await _czekaj_az(func(): return p.zamach_anim <= 0.0, 3.0)
	# namierzanie: R3 włącza, postać zwraca się do celu, drugie naciśnięcie wyłącza
	p.kat = atan2(-do_en.y, -do_en.x)
	await _pad(JOY_BUTTON_RIGHT_STICK)
	await _czekaj_az(func(): return rajd.cel_namierzony != null, 2.0)
	await _czekaj(0.2)
	var do_cel: Vector2 = en.w - p.w
	_ok("R3: namierzanie wroga, postać zwrócona do celu", rajd.cel_namierzony == en and absf(angle_difference(p.kat, atan2(do_cel.y, do_cel.x))) < 0.1)
	await _zrzut("7c_namierzanie")
	await _pad(JOY_BUTTON_RIGHT_STICK)
	await _czekaj_az(func(): return rajd.cel_namierzony == null, 2.0)
	_ok("R3 ponownie: koniec namierzania", rajd.cel_namierzony == null)
	rajd.mysz_aktywna = false
	en.w = w0


## Mocny cios (jak w NightBrand): przytrzymanie X ładuje (poza zamachu, wolniejszy krok), puszczenie = ciężki cios combo.
func _test_mocnego_ciosu(p, en) -> void:
	en.ogluszenie = 0.0
	en.zamach = 0.0
	en.atak_timer = 99.0
	_ustaw_wroga_przed(en, 0.9)
	p.stamina = p.stamina_max
	p.atak_cd = 0.0
	p.combo_reset = 0.0
	p.combo = 0
	rajd.bufor_ataku = 0.0
	rajd.bufor_mocnego = 0.0
	await _czekaj_az(func(): return p.zamach_anim <= 0.0, 3.0)
	var post0: float = en.postura
	_przycisk(JOY_BUTTON_X, true)
	await _czekaj_az(func(): return p.ladowanie >= rajd.PROG_MOCNEGO + 0.15, 6.0)
	await _klatka()
	_ok("mocny cios: przytrzymanie ładuje (poza zamachu ciężkiego ciosu)", p.ladowanie >= rajd.PROG_MOCNEGO and p.biezaca_anim == "atak3" and p.zamach_anim <= 0.0,
		"ładowanie %.2f s, animacja %s" % [p.ladowanie, p.biezaca_anim])
	await _zrzut("7b_ladowanie_mocnego")
	var licznik: int = p.atak_licznik
	_przycisk(JOY_BUTTON_X, false)
	await _czekaj_az(func(): return p.atak_licznik > licznik, 3.0)
	await _po_cieciu()
	_ok("mocny cios: puszczenie = ciężki cios (combo 3, łamie posturę mocniej)", p.atak_licznik > licznik and p.combo == 2 and (en.postura < post0 or en.ogluszenie > 0.0),
		"combo %d, postura %.0f → %.0f" % [p.combo, post0, en.postura])
	await _czekaj(0.5)
	en.postura = en.postura_max
	en.ogluszenie = 0.0


## Oprawa walki (runda walka-oprawa): mięso trafień, paski, napisy, pasek bossa. Tylko wygląd — reguły bez zmian.
func _test_oprawy_walki(p, en) -> void:
	var s3 = rajd.swiat3d
	var d3: Dictionary = s3._wrog3d(en)
	# cios: wróg wzdryga się dłużej niż okno logiki, błyska i odchyla; obraz „kopie” w stronę ciosu
	en.ogluszenie = 0.0
	en.zamach = 0.0
	en.hp = en.hp_max
	en.hp_cien = en.hp_max
	_ustaw_wroga_przed(en, 0.9)
	en.atak_timer = 99.0
	p.atak_cd = 0.0
	p.stamina = p.stamina_max
	var dzieci_przed := s3.get_child_count()
	var licznik_przed: int = d3["traf_licznik"]
	rajd.ostatnie_trafienie = {}
	rajd.atak_wrecz()
	await _po_cieciu()
	var ot: Dictionary = rajd.ostatnie_trafienie
	_ok("trafienie: zatrzymanie klatki i kopnięcie obrazu", float(ot.get("hitstop", 0.0)) >= 0.05 and float(ot.get("kop", 0.0)) > 1.0,
		"hitstop %.3f s, kop %.1f px" % [float(ot.get("hitstop", 0.0)), float(ot.get("kop", 0.0))])
	_ok("trafienie: iskry/krople krwi w 3D (nie piksele 2D)", s3.get_child_count() > dzieci_przed)
	await _klatka()
	_ok("pasek HP: jasny ślad utraconego życia zostaje chwilę za paskiem", en.hp_cien > en.hp, "hp %d, ślad %d" % [en.hp, en.hp_cien])
	await _czekaj_az(func(): return int(d3["traf_licznik"]) > licznik_przed, 2.0)
	_ok("trafiony wróg: błysk, odchylenie i wzdrygnięcie (wygląd)", int(d3["traf_licznik"]) > licznik_przed and float(d3["odchyl_v"]) != 0.0,
		"wykryte trafienia %d → %d" % [licznik_przed, d3["traf_licznik"]])
	# napisy: liczby się nie zlewają, komunikaty nie nachodzą na siebie
	rajd.efekty.napisy.clear()
	rajd.napis(en.w, "-10", Color.WHITE, 12)
	rajd.napis(en.w, "-10", Color.WHITE, 12)
	rajd.napis(en.w + Vector2(0.2, 0.0), "POSTURA ZŁAMANA!", Color.WHITE, 13)
	var sloty := {}
	for n in rajd.efekty.napisy:
		sloty[int(n["slot"])] = true
	_ok("napisy: osobne liczby i osobne piętra (bez nakładania)", rajd.efekty.napisy.size() == 3 and sloty.size() == 3)
	await _zrzut("8_oprawa_trafienia")
	# pasek bossa w HUD, gdy boss walczy
	var boss = null
	for w in rajd.wrogowie:
		if w.boss:
			boss = w
	var nowy_boss: bool = boss == null
	if nowy_boss:
		boss = rajd._dodaj_wroga("boss", p.w + Vector2(3.0, 0.0), 0.0)
	var boss_w: Vector2 = boss.w
	boss.uspiony = true
	boss.w = p.w + Vector2(2.5, 0.0)
	boss.stan = "walka"
	boss.widoczny_dla_gracza = true
	await _czekaj_az(func(): return hud.pasek_bossa.visible, 1.5)
	_ok("pasek bossa na dole ekranu, gdy boss walczy", hud.pasek_bossa.visible)
	_ok("pasek bossa u dołu nad paskiem akcji, gruby (16 px), jasna nazwa", is_equal_approx(hud.pasek_bossa.anchor_top, 1.0) and hud.pasek_bossa.size.y >= 50.0,
		"wys. %.0f px" % hud.pasek_bossa.size.y)
	await _zrzut("8b_pasek_bossa")
	boss.stan = "patrol"
	boss.w = boss_w
	if nowy_boss:
		rajd.wrogowie.erase(boss)
		boss.queue_free()
	en.hp = en.hp_max


## Runda „walka i oznaczenia” (autor 26.11): znak zamachu i barwa sylwetki, pewna riposta z doskokiem,
## odskok w tył bez kierunku, unik przerywa cios, szybszy krok po ciosie, mniejszy HUD i kręgi.
func _test_walki_i_oznaczen(p, en) -> void:
	var s3 = rajd.swiat3d
	var d3: Dictionary = s3._wrog3d(en)
	var start_w: Vector2 = p.w
	var start_kat: float = p.kat
	en.ogluszenie = 0.0
	en.hp = en.hp_max
	en.atak_timer = 99.0
	_ustaw_wroga_przed(en, 1.3)
	en.kat = atan2(p.w.y - en.w.y, p.w.x - en.w.x)
	en.widoczny_dla_gracza = true
	# zapowiedź: sylwetka wroga nabiera barwy w trakcie zamachu
	en.uspiony = true
	en.zamach = en.zamach_dl * 0.3
	var tint := 0.0
	for i in 6:
		await _klatka()
		tint = maxf(tint, float(d3.get("tint_zamachu", 0.0)))
	_ok("zapowiedź: sylwetka wroga świeci w zamachu", tint > 0.06, "barwa %.2f (główny sygnał niesie obrys; autor 26.11: lekko i złotawo)" % tint)
	var cialo_w: MeshInstance3D = (d3["wezel"] as Node3D).find_child("cialo*", true, false)
	_ok("błysk, barwa zamachu i obrys naprawdę na ciele wroga (siatka cialo_001)", cialo_w != null and cialo_w.material_overlay == d3["blysk"],
		"brak siatki ciała" if cialo_w == null else str(cialo_w.name))
	var ob: StandardMaterial3D = d3["obrys"]
	_ok("obrys wroga w walce, w zamachu jaśnieje barwą ciosu (bez ikony „!”)", (d3["blysk"] as StandardMaterial3D).next_pass == ob and ob.albedo_color.r > 0.8,
		str(ob.albedo_color))
	await _zrzut("9d_znak_zamachu")
	en.zamach = 0.0
	# riposta: ogłuszony wróg 2,3 m z boku — doskok domyka dystans, cios trafia
	var bok := Vector2(cos(p.kat + 0.9), sin(p.kat + 0.9))
	en.w = p.w + bok * 2.3
	if rajd.pelne(en.w.x, en.w.y) or not rajd.linia_wzroku(p.w, en.w):
		en.w = p.w - bok * 2.3
	en.ogluszenie = 2.0
	var hp0: float = en.hp
	var w0: Vector2 = p.w
	p.atak_cd = 0.0
	p.stamina = p.stamina_max
	rajd.atak_wrecz()
	await _po_cieciu()
	_ok("riposta: doskok do ogłuszonego 2,3 m obok i pewne trafienie", en.hp < hp0 and en.ogluszenie <= 0.0 and p.w.distance_to(w0) > 0.4,
		"HP %.0f → %.0f, doskok %.2f m" % [hp0, en.hp, p.w.distance_to(w0)])
	en.hp = en.hp_max
	await _czekaj_az(func(): return rajd.hitstop <= 0.0, 2.0)
	# unik bez kierunku = odskok w tył i przerwanie wybrzmienia ciosu
	_ustaw_wroga_przed(en, 1.2)
	p.atak_cd = 0.0
	p.unik_cd = 0.0
	p.stamina = p.stamina_max
	rajd.atak_wrecz()
	var przod := Vector2(cos(p.kat), sin(p.kat))
	rajd.unik(Vector2.ZERO)
	_ok("cios zobowiązuje: w zamachu unik nie działa", p.unik_czas <= 0.0 and p.faza_ciosu == "zamach", p.faza_ciosu)
	await _czekaj_az(func(): return p.faza_ciosu == "powrot", 2.0)
	await _czekaj_az(func(): return rajd.hitstop <= 0.0, 2.0)
	rajd.unik(Vector2.ZERO)
	_ok("unik bez kierunku: odskok w tył, przerywa cios", p.unik_kier.dot(przod) < -0.9 and p.zamach_anim <= 0.0, "kierunek·przód %.2f" % p.unik_kier.dot(przod))
	await _czekaj_az(func(): return p.unik_czas <= 0.0, 2.0)
	_ok("ruch po ciosie szybszy niż dawniej (do strojenia)", rajd.V_PO_CIOSIE > 1.6 and rajd.V_W_CIOSIE > 0.5)
	await _test_walki_uczciwej(p, en)
	_ok("trafienie: mocniejsze zatrzymanie klatki", rajd.HITSTOP_CIOS > 0.055 and rajd.HITSTOP_CIEZKI > 0.085)
	# oznaczenia: mniejszy HUD i kręgi
	_ok("HUD mniejszy: kule, minimapa, pasek akcji", hud.kula_hp.size.x <= 130.0 and hud.pasek.size.x <= 724.0 * 0.65,
		"kula %.0f px, pasek %.0f px" % [hud.kula_hp.size.x, hud.pasek.size.x])
	var kr: MeshInstance3D = d3["krag"]
	var kb: MeshInstance3D = s3._krag_bohatera
	_ok("kręgi pod postaciami mniejsze", (kr.mesh as PlaneMesh).size.x < 1.0 and (kb.mesh as PlaneMesh).size.x < 1.0,
		"wróg %.2f m, bohater %.2f m" % [(kr.mesh as PlaneMesh).size.x, (kb.mesh as PlaneMesh).size.x])
	en.ogluszenie = 0.0
	en.hp = en.hp_max
	p.w = start_w  # kolejne testy zakładają miejsce startu (otwarta przestrzeń)
	p.kat = start_kat
	p.predkosc = Vector2.ZERO


## Walka „trudna, ale uczciwa” (autor 26.11: „rób”): cios w fazach, nietykalność, przerwa staminy,
## najwyżej 2 wrogów w zamachu naraz, wspólna przerwa strzelców.
func _test_walki_uczciwej(p, en) -> void:
	# cios w fazach: w zamachu jeszcze bez trafienia, po zamachu cios trafia
	en.ogluszenie = 0.0
	en.hp = en.hp_max
	en.uspiony = true
	_ustaw_wroga_przed(en, 1.0)
	p.atak_cd = 0.0
	p.combo_reset = 0.0
	p.stamina = p.stamina_max
	var hp0: float = en.hp
	rajd.atak_wrecz()
	var w_zamachu: bool = p.faza_ciosu == "zamach" and is_equal_approx(en.hp, hp0)
	await _po_cieciu()
	_ok("cios w fazach: zamach bez trafienia, trafia w chwili cięcia", w_zamachu and en.hp < hp0, "HP %.0f → %.0f" % [hp0, en.hp])
	await _czekaj_az(func(): return p.faza_ciosu == "" and rajd.hitstop <= 0.0, 3.0)
	en.hp = en.hp_max
	# nietykalność po otrzymanym ciosie: drugi cios w tym czasie nie zadaje obrażeń; postać miga
	p.niet = 0.0
	p.unik_czas = 0.0
	p.okno_parowania = 0.0
	p.blok = false
	p.riposta_niet = 0.0
	var hp_g: float = p.hp
	rajd.trafienie_gracza(en, 10.0)
	var po1: float = p.hp
	rajd.trafienie_gracza(en, 10.0)
	_ok("nietykalność 0,45 s po otrzymanym ciosie (miganie)", po1 < hp_g and is_equal_approx(p.hp, po1) and p.niet > 0.3 and p.niet_miganie,
		"HP %.0f → %.0f → %.0f" % [hp_g, po1, p.hp])
	p.hp = p.hp_max
	p.niet = 0.0
	await _czekaj_az(func(): return rajd.hitstop <= 0.0, 2.0)
	# stamina stoi chwilę po akcji
	p.stamina = 40.0
	p.stamina_przerwa = rajd.PRZERWA_STAMINY
	await _czekaj(0.15)
	var st1: float = p.stamina
	await _czekaj_az(func(): return p.stamina_przerwa <= 0.0, 3.0)
	await _czekaj(0.3)
	_ok("stamina nie odnawia się ok. 0,55 s po akcji", is_equal_approx(st1, 40.0) and p.stamina > 40.5, "%.1f → %.1f" % [st1, p.stamina])
	p.stamina = p.stamina_max
	# najwyżej 2 wrogów wręcz w zamachu naraz
	var wrecz: Array = []
	for w in rajd.wrogowie:
		if w.rodzaj != "archer" and not w.boss and wrecz.size() < 3:
			wrecz.append(w)
	if wrecz.size() == 3:
		var pozycje: Array = []
		for j in 3:
			var w = wrecz[j]
			pozycje.append(w.w)
			w.w = p.w + Vector2(cos(p.kat + j * 2.1), sin(p.kat + j * 2.1)) * 1.0
			w.uspiony = false
			w.stan = "walka"
			w.ogluszenie = 0.0
		wrecz[0].zamach = 5.0
		wrecz[1].zamach = 5.0
		wrecz[2].zamach = 0.0
		wrecz[2].atak_timer = 0.0
		rajd._wrogowie(0.016)
		_ok("najwyżej 2 wrogów naraz w zamachu", wrecz[2].zamach <= 0.0 and wrecz[2].atak_timer > 0.0, "w zamachu: %d" % rajd._zamachy_wrecz())
		for j in 3:
			wrecz[j].zamach = 0.0
			wrecz[j].atak_timer = 99.0
			wrecz[j].uspiony = true
			wrecz[j].w = pozycje[j]
	# Łucznik musi mieć widok gracza. Stały punkt pięć metrów od postaci mógł wypaść za murem.
	var miejsce_lucznika: Vector2 = p.w
	var ma_widok := false
	for odleglosc in [5.0, 2.5, 1.5]:
		for kierunek in range(8):
			var punkt: Vector2 = p.w + Vector2.from_angle(kierunek * PI / 4.0) * odleglosc
			if not rajd.pelne(punkt.x, punkt.y) and rajd.linia_wzroku(punkt, p.w):
				miejsce_lucznika = punkt
				ma_widok = true
				break
		if ma_widok:
			break
	var luk = rajd._dodaj_wroga("archer", miejsce_lucznika, 0.0)
	luk.stan = "walka"
	luk.atak_timer = 0.0
	rajd.przerwa_lucznikow = 0.8
	rajd._wrogowie(0.016)
	_ok("wspólna przerwa strzelców: łucznik czeka, gdy inny właśnie strzelał", ma_widok and luk.zamach <= 0.0 and luk.atak_timer > 0.5, "widok %s, zamach %.2f, przerwa %.2f" % [ma_widok, luk.zamach, luk.atak_timer])
	rajd.wrogowie.erase(luk)
	luk.queue_free()
	rajd.przerwa_lucznikow = 0.0


## Pauza: Start na padzie otwiera i zatrzymuje grę, lista sterowania z mapy akcji, LB/RB zakładki, B wraca; Esc też otwiera.
func _test_pauzy(gdzie: String, zrzut: String) -> void:
	await _pad(JOY_BUTTON_START)
	await _czekaj_az(func(): return pauza.visible, 2.0)
	_ok("%s: Start otwiera pauzę i zatrzymuje grę" % gdzie, pauza.visible and get_tree().paused)
	await _klatka()
	var fokus := get_viewport().gui_get_focus_owner()
	_ok("%s: pauza — fokus na „Wróć do gry” (pad)" % gdzie, fokus == pauza.wroc, str(fokus))
	var wiersze := pauza.zakladki.get_child(0).find_children("*", "Label", true, false).size()
	_ok("%s: pauza — sterowanie klawiatura + pad dla każdej czynności" % gdzie, wiersze >= Sterowanie.OPIS.size() * 2, "%d etykiet" % wiersze)
	if rajd != null:
		_ok("rajd: pod pauzą HUD schowany, wynik walki w podtytule", not hud.visible and pauza.podtytul.text.to_lower().contains("pokonani"), pauza.podtytul.text)
		_ok("rajd: w pauzie nie ma usuwania zapisu", not pauza.dane_zapisu.visible)
	else:
		_ok("Przystań: Opcje → usuń zapis (z potwierdzeniem)", pauza.dane_zapisu.visible and pauza.zakladki.get_child(2).name == "Opcje")
		pauza.dane_zapisu.pressed.emit()
		await _klatka()
		var okno_ok: bool = pauza.dialog_reset.visible
		pauza.dialog_reset.hide()
		_ok("Przystań: usunięcie zapisu pyta o potwierdzenie", okno_ok)
	await _zrzut(zrzut)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("%s: RB przełącza zakładkę pauzy" % gdzie, pauza.zakladki.current_tab == 1)
	await _zrzut(zrzut + "_umiejetnosci")
	pauza.zakladki.current_tab = 0
	await _pad(JOY_BUTTON_B)
	await _czekaj_az(func(): return not pauza.visible, 2.0)
	_ok("%s: B wraca do gry" % gdzie, not pauza.visible and not get_tree().paused)
	if rajd != null:
		_ok("rajd: po pauzie HUD wraca", hud.visible)
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _czekaj_az(func(): return pauza.visible, 2.0)
	var esc2 := InputEventKey.new()
	esc2.physical_keycode = KEY_ESCAPE
	esc2.pressed = false
	Input.parse_input_event(esc2)
	_ok("%s: Esc otwiera pauzę" % gdzie, pauza.visible)
	pauza.zamknij()
	await _klatka()


## Cios w fazach: trafienie następuje po zamachu (w chwili cięcia).
func _po_cieciu() -> void:
	await _czekaj_az(func(): return rajd.gracz.faza_ciosu != "zamach", 2.0)


func _ustaw_wroga_przed(en, odl := 1.0) -> void:
	var p = rajd.gracz
	en.w = p.w + Vector2(cos(p.kat), sin(p.kat)) * odl
	en.stan = "walka"


func _przycisk(b: JoyButton, wcisniety: bool) -> void:
	var z := InputEventJoypadButton.new()
	z.device = 0
	z.button_index = b
	z.pressed = wcisniety
	Input.parse_input_event(z)


## Wysokość bioder modelu 3D Hadræna (prawdziwa poza na ekranie, nie tylko nazwa animacji).
func _biodra3d() -> float:
	if rajd == null or rajd.swiat3d == null:
		return 0.0
	var sk: Skeleton3D = rajd.swiat3d.bohater.find_child("Skeleton3D", true, false)
	return (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_Hips"))).origin.y


func _dlon3d() -> Vector3:
	var sk: Skeleton3D = rajd.swiat3d.bohater.find_child("Skeleton3D", true, false)
	return (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_RightHand"))).origin - rajd.swiat3d.bohater.global_position


func _anim3d() -> String:
	if rajd == null or rajd.swiat3d == null:
		return ""
	return rajd.swiat3d._ap_bohatera.current_animation


## Rajd w Czarnoborze: generator lasu w rajdzie, wrogowie, wyjścia osiągalne, las w 3D (drzewa, woda, runo),
## drzewo między kamerą a graczem znika, strumień blokuje ruch, ale nie wzrok.
func _test_czarnoboru() -> void:
	rozpocznij_rajd("czarnobor", "LAS01")
	await _czekaj(0.5)
	var m = rajd.mapa
	_ok("Czarnobór: rajd w lesie (generator lasu 128×128)", "teren" in m and m.siatka.size() == 128 * 128 and m.komnaty.size() >= 14, "%d polan" % m.komnaty.size())
	var d: PackedInt32Array = m._odleglosci(Vector2i(int(m.start.x), int(m.start.y)))
	var eks := 0
	for e in m.ekstrakcje:
		if d[m.idx(int(e["w"].x), int(e["w"].y))] >= 0:
			eks += 1
	var limit := int(rajd.kraina["enemyCount"])
	_ok("Czarnobór: 3 wyjścia osiągalne, wrogowie wg krainy", eks == 3 and rajd.wrogowie.size() >= int(limit * 0.8) and rajd.wrogowie.size() <= limit + 8, "%d wyjść, %d/%d wrogów" % [eks, rajd.wrogowie.size(), limit])
	_ok("Czarnobór: woda blokuje ruch, nie wzrok", Mapgen.blokuje_ruch(Mapgen.K.WODA) and not Mapgen.blokuje_wzrok(Mapgen.K.WODA) and m.siatka.has(Mapgen.K.WODA))
	var s3 = rajd.swiat3d
	var drzew := 0
	var runa := 0
	for k in s3._mm:
		if String(k).begins_with("drz"):
			drzew += s3._mm[k].multimesh.instance_count
		if String(k).begins_with("runo_"):
			runa += s3._mm[k].multimesh.instance_count
	await _czekaj(1.5)
	_ok("Czarnobór: ściana lasu z drzew, strumień, runo", s3.las and drzew > 800 and runa > 300 and s3._mm.has("woda"), "%d drzew, %d runa, %d FPS" % [drzew, runa, Engine.get_frames_per_second()])
	# przekrój: stawiamy bohatera 3 pola za drzewem (patrząc od kamery) — to drzewo musi zniknąć
	var cel := []
	for i in s3._indeks:
		for wpis in s3._indeks[i]:
			if String(wpis[0]).begins_with("drz_") and cel.is_empty():
				var p3: Vector3 = wpis[2]
				var stan := Vector2(p3.x - 3.0, p3.z - 3.0)
				if not Mapgen.blokuje_ruch(m.kafel(int(stan.x), int(stan.y))) and rajd.linia_wzroku(stan, Vector2(i % 128 + 0.5, i / 128 + 0.5)):
					cel = [stan, wpis]
	var schowane := false
	if not cel.is_empty():
		rajd.gracz.w = cel[0]
		rajd._licz_widok()
		s3.odswiez_widok()
		var tr: Transform3D = s3._mm[cel[1][0]].multimesh.get_instance_transform(cel[1][1])
		schowane = tr.basis.get_scale().length() < 0.01
	_ok("Czarnobór: drzewo między kamerą a bohaterem znika", schowane, "brak takiego miejsca" if cel.is_empty() else "")
	var korony := 0
	for k in s3._mm:
		if String(k).begins_with("korona"):
			korony += s3._mm[k].multimesh.instance_count
	_ok("Czarnobór: głęboki las z koron i las poza mapą (zamiast czarnej pustki)", korony > 1000 and s3._plaszczyzna_otoczenia != null, "%d pól koron" % korony)
	await _zrzut("9c_czarnobor")


## Pilot Czarnoboru (generator lasu, jeszcze bez rajdu): ziarno, osiągalność, szerokość przejść, wyjścia w głębi,
## ślepe odnogi z łupem. Pięć ziaren.
func _test_lasu() -> void:
	var zle: Array = []
	for z in ["LAS_A", "LAS_B", "LAS_C", "LAS_D", "LAS_E"]:
		var m = MapgenLas.new()
		m.generuj({"id": "czarnobor"}, z, 1)
		var m2 = MapgenLas.new()
		m2.generuj({"id": "czarnobor"}, z, 1)
		if m2.teren != m.teren or m2.siatka != m.siatka or m2.skrzynie.size() != m.skrzynie.size() or m2.spawny.size() != m.spawny.size() or m2.start != m.start:
			zle.append(z + ": inne ziarno-wynik")
		var d: PackedInt32Array = m._odl_t(Vector2i(int(m.start.x), int(m.start.y)))
		var punkty: Array = []
		for e in m.ekstrakcje:
			punkty.append(e["w"])
		for sk in m.skrzynie:
			punkty.append(sk["w"])
		for sp in m.spawny:
			punkty.append(sp["w"])
		for w in punkty:
			if d[m.idx(int(w.x), int(w.y))] < 0:
				zle.append(z + ": nieosiągalne %s" % str(w))
		# przejście co najmniej 3 m: od startu do każdej polany po polach, wokół których 3×3 jest wolne
		var rdzen := PackedInt32Array()
		rdzen.resize(m.siatka.size())
		rdzen.fill(-1)
		var kol: Array[Vector2i] = [Vector2i(int(m.start.x), int(m.start.y))]
		rdzen[m.idx(kol[0].x, kol[0].y)] = 0
		var g := 0
		while g < kol.size():
			var p: Vector2i = kol[g]
			g += 1
			for s4 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + s4
				if q.x < 2 or q.y < 2 or q.x >= MapgenLas.ROZMIAR - 2 or q.y >= MapgenLas.ROZMIAR - 2 or rdzen[m.idx(q.x, q.y)] >= 0:
					continue
				var wolne := true
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if MapgenLas.blok_t(m.kt(q.x + dx, q.y + dy)) and m.kt(q.x + dx, q.y + dy) != MapgenLas.T.DRZEWO and m.kt(q.x + dx, q.y + dy) != MapgenLas.T.GLAZ:
							wolne = false
				if wolne:
					rdzen[m.idx(q.x, q.y)] = 1
					kol.append(q)
		var max_g := 1
		for pl in m.polany:
			max_g = maxi(max_g, int(pl["gleb"]))
		var odnogi := 0
		for pl in m.polany:
			var c: Vector2 = pl["c"]
			if rdzen[m.idx(int(c.x), int(c.y))] < 0 and pl["typ"] != "start":
				zle.append(z + ": wąskie przejście do %s" % pl["typ"])
			if pl["typ"] == "ekstrakcja" and float(pl["gleb"]) < 0.45 * max_g:
				zle.append(z + ": wyjście przy starcie")
			if pl["typ"] in ["kurhan", "legowisko"]:
				odnogi += 1
		for sc in m.sciezki:
			if sc["szer"] < 5.0 or sc["szer"] > 6.5:  # autor 26.11: szersze ścieżki (było 4–6 m)
				zle.append(z + ": ścieżka %.1f m" % sc["szer"])
		if m.ekstrakcje.size() != 3:
			zle.append(z + ": wyjść %d" % m.ekstrakcje.size())
		if odnogi < 2:
			zle.append(z + ": ślepych odnóg %d" % odnogi)
		if m.polany.size() < 14 or m.skrzynie.size() < 18:
			zle.append(z + ": polan %d, łupów %d" % [m.polany.size(), m.skrzynie.size()])
	_ok("las (pilot): ziarno, osiągalność, przejścia ≥3 m, 3 wyjścia w głębi, ślepe odnogi", zle.is_empty(), ", ".join(zle.slice(0, 4)))


## Pilot Spalonej Osady (generator, jeszcze bez rajdu): ziarno, osiągalność, przejścia ≥3 m, 3 wyjścia w głębi,
## ślepe odnogi, spalone chaty z wejściem, kościół (przyszła arena bossa). Sześć ziaren.
func _test_osady() -> void:
	var zle: Array = []
	for z in ["OS_A", "OS_B", "OS_C", "OS_D", "OS_E", "OS_F"]:
		var m = MapgenOsada.new()
		m.generuj({"id": "spalona_osada"}, z, 1)
		var m2 = MapgenOsada.new()
		m2.generuj({"id": "spalona_osada"}, z, 1)
		if m2.teren != m.teren or m2.siatka != m.siatka or m2.skrzynie.size() != m.skrzynie.size() or m2.spawny.size() != m.spawny.size() or m2.start != m.start:
			zle.append(z + ": inne ziarno-wynik")
		var d: PackedInt32Array = m._odl_t(Vector2i(int(m.start.x), int(m.start.y)))
		var dk: PackedInt32Array = m._odleglosci(Vector2i(int(m.start.x), int(m.start.y)))
		var punkty: Array = []
		for e in m.ekstrakcje:
			punkty.append(e["w"])
		for sk in m.skrzynie:
			punkty.append(sk["w"])
		for sp in m.spawny:
			punkty.append(sp["w"])
		for w in punkty:
			if d[m.idx(int(w.x), int(w.y))] < 0 or dk[m.idx(int(w.x), int(w.y))] < 0:
				zle.append(z + ": nieosiągalne %s" % str(w))
		# przejście co najmniej 3 m od startu do środka każdego miejsca (osłony punktowe się nie liczą)
		var rdzen := PackedInt32Array()
		rdzen.resize(m.teren.size())
		rdzen.fill(-1)
		var kol: Array[Vector2i] = [Vector2i(int(m.start.x), int(m.start.y))]
		rdzen[m.idx(kol[0].x, kol[0].y)] = 0
		var g := 0
		while g < kol.size():
			var p: Vector2i = kol[g]
			g += 1
			for s4 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + s4
				if q.x < 2 or q.y < 2 or q.x >= MapgenOsada.ROZMIAR - 2 or q.y >= MapgenOsada.ROZMIAR - 2 or rdzen[m.idx(q.x, q.y)] >= 0:
					continue
				var wolne := true
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var t: int = m.kt(q.x + dx, q.y + dy)
						if t == MapgenOsada.T.ZABUDOWA or t == MapgenOsada.T.ZGLISZCZA or t == MapgenOsada.T.PLOT:
							wolne = false
				if wolne:
					rdzen[m.idx(q.x, q.y)] = 1
					kol.append(q)
		var max_g := 1
		for pl in m.polany:
			max_g = maxi(max_g, int(pl["gleb"]))
		var odnogi := 0
		var koscioly := 0
		for pl in m.polany:
			var c: Vector2 = pl["c"]
			if rdzen[m.idx(int(c.x), int(c.y))] < 0 and pl["typ"] != "start" and pl["typ"] != "plac":
				zle.append(z + ": wąskie przejście do %s" % pl["typ"])
			if pl["typ"] == "ekstrakcja" and float(pl["gleb"]) < 0.45 * max_g:
				zle.append(z + ": wyjście przy starcie")
			if pl["typ"] in ["cmentarz", "piwnica", "kosciol"]:
				odnogi += 1
			if pl["typ"] == "kosciol":
				koscioly += 1
				if float(pl["r"]) < 9.0:
					zle.append(z + ": kościół za mały")
		for sc in m.sciezki:
			if sc["szer"] < 5.0 or sc["szer"] > 7.5:
				zle.append(z + ": ulica %.1f m" % sc["szer"])
		for dom in m.domy:
			var dr: Vector2i = dom["drzwi"]
			if d[m.idx(dr.x, dr.y)] < 0:
				zle.append(z + ": chata bez wejścia")
		if m.ekstrakcje.size() != 3:
			zle.append(z + ": wyjść %d" % m.ekstrakcje.size())
		if odnogi < 2 or koscioly != 1:
			zle.append(z + ": odnóg %d, kościołów %d" % [odnogi, koscioly])
		if m.polany.size() < 12 or m.skrzynie.size() < 18 or m.domy.size() < 20:
			zle.append(z + ": miejsc %d, łupów %d, chat %d" % [m.polany.size(), m.skrzynie.size(), m.domy.size()])
	_ok("osada (pilot): ziarno, osiągalność, przejścia ≥3 m, 3 wyjścia w głębi, odnogi, chaty z wejściem, kościół", zle.is_empty(), ", ".join(zle.slice(0, 4)))


## Spalona Osada w rajdzie: generator osady, wyjścia, wrogowie, oprawa 3D z biblioteki NightBrand
## (palisady, mury chat z bali, deski w chatach, martwe drzewa, płoty, studnia), przekrój muru chaty.
func _test_osady_w_rajdzie() -> void:
	rozpocznij_rajd("spalona_osada", "OSADA01")
	await _czekaj(0.5)
	var m = rajd.mapa
	_ok("Osada: rajd w osadzie (generator osady 128×128)", m is MapgenOsada and m.siatka.size() == 128 * 128 and m.domy.size() >= 20, "%d miejsc, %d chat" % [m.komnaty.size(), m.domy.size()])
	var d: PackedInt32Array = m._odleglosci(Vector2i(int(m.start.x), int(m.start.y)))
	var eks := 0
	for e in m.ekstrakcje:
		if d[m.idx(int(e["w"].x), int(e["w"].y))] >= 0:
			eks += 1
	var limit := int(rajd.kraina["enemyCount"])
	_ok("Osada: 3 wyjścia osiągalne, wrogowie wg krainy", eks == 3 and rajd.wrogowie.size() >= int(limit * 0.8) and rajd.wrogowie.size() <= limit + 8, "%d wyjść, %d/%d wrogów" % [eks, rajd.wrogowie.size(), limit])
	var s3 = rajd.swiat3d
	var ile := {"murch": 0, "chata": 0, "drz": 0, "las_os_plot": 0, "mur_": 0}
	for k in s3._mm:
		for pre in ile:
			if String(k).begins_with(pre):
				ile[pre] += s3._mm[k].multimesh.instance_count
	var studnia := false
	for e in s3._dekor:
		if is_instance_valid(e[0]) and String(e[0].scene_file_path).ends_with("p1_well.glb"):
			studnia = true
	_ok("Osada: oprawa z biblioteki (palisady, chaty z bali i desek, martwe drzewa, płoty, studnia)", s3.osada and ile["murch"] > 300 and ile["chata"] > 300 and ile["drz"] > 20 and ile["las_os_plot"] > 10 and ile["mur_"] > 1000 and studnia, str(ile) + (" studnia" if studnia else " brak studni"))
	# przekrój: mur chaty między kamerą a bohaterem obniża się do cokołu
	var cel := []
	for i in s3._indeks:
		for wpis in s3._indeks[i]:
			if String(wpis[0]).begins_with("murch") and cel.is_empty():
				var p3: Vector3 = wpis[2]
				var stan := Vector2(p3.x - 2.0, p3.z - 2.0)
				if not Mapgen.blokuje_ruch(m.kafel(int(stan.x), int(stan.y))) and d[m.idx(int(stan.x), int(stan.y))] >= 0:
					cel = [stan, wpis]
	var obnizony := false
	if not cel.is_empty():
		rajd.gracz.w = cel[0]
		rajd._licz_widok()
		s3.odswiez_widok()
		var tr: Transform3D = s3._mm[cel[1][0]].multimesh.get_instance_transform(cel[1][1])
		obnizony = tr.basis.get_scale().length() < 0.01
	_ok("Osada: mur chaty między kamerą a bohaterem znika (zostaje cokół)", obnizony, "brak takiego miejsca" if cel.is_empty() else "")
	# zrzut: bohater na placu ze studnią
	for p in m.polany:
		if p["typ"] == "plac":
			rajd.gracz.w = (p["c"] as Vector2) + Vector2(-3.0, -3.0)
	rajd._licz_widok()
	s3.odswiez_widok()
	await _czekaj(1.2)
	await _zrzut("9d_osada")
	# autor 26.11: łup w modelach biblioteki NightBrand; poległy rozpada się w pył i zostawia skrzyneczkę lub krzyżyk
	var modele_ok := true
	for sk in s3._skrzynie:
		var plik := String((sk["wezel3d"] as Node3D).get_child(0).scene_file_path)
		if not plik.begins_with("res://zasoby/3d/las/"):
			modele_ok = false
	# autor 26.11 (21:31–21:36): dźwięki NightBrand, chód bez rozkroku, gładka mgła, drzewa w wyższej jakości
	var brak_probek: Array = []
	for nz in ["zamach", "zamach_c", "trafienie", "blok", "parowanie", "riposta", "unik", "krok", "bol", "picie", "lup", "ui", "ekstrakcja", "zapowiedz", "smierc_wroga", "postawa"]:
		if not Dzwiek.z_probki(nz):
			brak_probek.append(nz)
	_ok("dźwięki: próbki NightBrand pod swoimi funkcjami (ostrze, parowanie, blok, kroki…)", brak_probek.is_empty(), ", ".join(brak_probek))
	var podl_nieznana := false
	for k in s3._mm:
		if String(k) == "podloga":
			var mmp: MultiMesh = s3._mm[k].multimesh
			for nn in mini(200, mmp.instance_count):
				if mmp.get_instance_transform(nn).basis.get_scale().length() > 0.5:
					podl_nieznana = true
	var tm: ShaderMaterial = s3._mat["podloga"]
	_ok("mgła: podłoga stoi zawsze, mrok rysuje gładka mapa jasności (bez kwadratów)", podl_nieznana and tm.get_shader_parameter("mgla_gladka") == true and tm.get_shader_parameter("jasnosc_mapy") == s3._jasn_tex)
	var kch = s3._korekta_chodu
	_ok("chód: korekta rozkroku na szkielecie bohatera", kch != null and kch.get_parent() is Skeleton3D and float(kch.sila) > 0.5)
	# autor 26.11: szersze pole widzenia; wróg w walce nie znika za plecami (taktyka jak w soulsach)
	var wr = rajd.wrogowie[1]
	rajd.gracz.pochodnia_w_rece = true
	var pole := Vector2.ZERO
	for p in m.polany:
		if p["typ"] == "plac":
			pole = p["c"]
	# miejsce na placu, z którego widać 9 m za plecy (bez studni, drzew i wozów po drodze)
	for oy in range(-8, 9):
		for ox in range(0, 9):
			var g2: Vector2 = pole + Vector2(ox + 0.5, oy + 0.5)
			var w2: Vector2 = g2 + Vector2(-9.0, 0.0)
			if not Mapgen.blokuje_ruch(m.kafel(int(g2.x), int(g2.y))) and not Mapgen.blokuje_ruch(m.kafel(int(w2.x), int(w2.y))) and rajd.linia_wzroku(g2, w2):
				rajd.gracz.w = g2
	rajd.gracz.kat = 0.0
	wr.w = rajd.gracz.w + Vector2(-9.0, 0.0)   # za plecami, 9 m: dalej niż boczne pole widzenia (8 m)
	wr.stan = "walka"
	wr.uspiony = true
	rajd._licz_widok()
	await _czekaj(0.2)
	var za_plecami: bool = wr.widoczny_dla_gracza
	wr.stan = "patrol"
	await _czekaj(0.2)
	var spokojny_ukryty: bool = not wr.widoczny_dla_gracza
	_ok("pole widzenia: wróg w walce za plecami (9 m) widoczny, spokojny nie", za_plecami and spokojny_ukryty, "w walce %s, spokojny ukryty %s, linia %s, stan %s, d %.1f" % [str(za_plecami), str(spokojny_ukryty), str(rajd.linia_wzroku(rajd.gracz.w, wr.w)), wr.stan, rajd.gracz.w.distance_to(wr.w)])
	_ok("łup w modelach biblioteki (kufer, sarkofag, krzyż z czaszkami)", modele_ok and not s3._skrzynie.is_empty(), "%d pojemników" % s3._skrzynie.size())
	var ofiara = rajd.wrogowie[0]
	var id_of: int = ofiara.get_instance_id()
	var wz: Vector2 = ofiara.w
	rajd.gracz.w = wz + Vector2(-2.0, -2.0)
	rajd._licz_widok()
	s3.odswiez_widok()
	await _czekaj(0.3)
	rajd.zabij(ofiara)
	await _czekaj(0.9)
	var cialo: Node3D = s3._wrogowie[id_of]["wezel"]
	var w_trakcie: bool = cialo.visible
	wz = rajd.zwloki[rajd.zwloki.size() - 1]["w"]
	await _czekaj_az(func(): return not cialo.visible and s3._zwloki.has(str(wz)) and (s3._zwloki[str(wz)] as Node3D).scale.length() > 0.05, 12.0)
	var znak: Node3D = s3._zwloki.get(str(wz))
	var zw2d = rajd.zwloki[rajd.zwloki.size() - 1]["wezel"]
	_ok("poległy: bez starego sprite'a 2D i bez czerwonego kręgu", not zw2d.visible and not (s3._wrogowie[id_of]["krag"] as Node3D).visible)
	var zwl_ok: bool = rajd.zwloki.any(func(z): return z["w"] == wz and not z["przedmioty"].is_empty())
	_ok("poległy: animacja, potem rozpad w pył; zostaje skrzyneczka lub krzyżyk do przeszukania", w_trakcie and not cialo.visible and znak != null and znak.scale.length() > 0.05 and zwl_ok,
		"ciało %s (%.2f s), znak %s" % [str(cialo.visible), float(s3._wrogowie[id_of]["smierc"]), "brak" if znak == null else String(znak.scene_file_path).get_file()])


## Oprawa mapy: materiały krainy z tekstur NightBrand, maska murów, pochodnie nie wiszą w powietrzu.
## Duże mapy (wersja 2 generatora): rozmiar, osiągalność, rodzaje komnat, ziarno, wrogowie, pościg po korytarzach.
func _test_duzej_mapy() -> void:
	var m = rajd.mapa
	_ok("duża mapa: 128×128 pól, rajd 20 min", Mapgen.ROZMIAR == 128 and m.siatka.size() == 128 * 128 and is_equal_approx(rajd.CZAS_RAJDU, 1200.0))
	var d: PackedInt32Array = m._odleglosci(Vector2i(int(m.start.x), int(m.start.y)))
	var eks_ok: bool = m.ekstrakcje.size() >= 3
	for e in m.ekstrakcje:
		if d[m.idx(int(e["w"].x), int(e["w"].y))] < 0:
			eks_ok = false
	_ok("duża mapa: 3+ kręgi ekstrakcji osiągalne od startu", eks_ok, "%d kręgów" % m.ekstrakcje.size())
	# runda mapa-mgla-i-wczytywanie (autor 26.11): szersze korytarze, mniej przeszkód, płynna mgła, głębia zamiast czerni
	var waskie := 0
	for q in m.korytarze.slice(0, mini(400, m.korytarze.size())):
		var ok3 := false
		for oy in range(-2, 1):
			for ox in range(-2, 1):
				var wolne := true
				for dy in 3:
					for dx in 3:
						if m.kafel(q.x + ox + dx, q.y + oy + dy) == Mapgen.K.MUR:
							wolne = false
				ok3 = ok3 or wolne
		if not ok3:
			waskie += 1
	_ok("korytarze lochu szerokości 3 pól (autor: szersze)", waskie == 0, "%d za wąskich miejsc" % waskie)
	var przeszkody := 0
	var podlogi := 0
	for t in m.siatka:
		if t == Mapgen.K.GRUZ or t == Mapgen.K.FILAR:
			przeszkody += 1
		elif t == Mapgen.K.PODLOGA:
			podlogi += 1
	var gestosc := float(przeszkody) / maxf(1.0, float(podlogi))
	_ok("mniej przeszkód w komnatach (gruz + filary)", gestosc < 0.05, "%.1f%% podłogi" % (gestosc * 100.0))
	# minimapa: odkryta podłoga czytelna (nie prawie czarna)
	var pole_pod := -1
	for i in m.siatka.size():
		if m.siatka[i] == Mapgen.K.PODLOGA and rajd.widok[i] == 2:
			pole_pod = i
			break
	if pole_pod >= 0:
		var kp: Color = hud._kolor_pola(rajd, pole_pod)
		_ok("minimapa: odkryta podłoga jaśniejsza i czytelna", kp.get_luminance() > 0.25, "jasność %.2f" % kp.get_luminance())
	var s3 = rajd.swiat3d
	if s3 != null:
		var wierzch := 0
		for k in s3._mm:
			if String(k).begins_with("wierzch"):
				wierzch += s3._mm[k].multimesh.instance_count
		_ok("głębia: wierzch skały w lochu i skała poza mapą (zamiast czarnego tła)", wierzch > 500 and s3._plaszczyzna_otoczenia != null, "%d pól wierzchu" % wierzch)
		var cel_i := -1
		for i in s3._indeks:
			if rajd.widok[i] == 0 and float(s3._cel_jasn[i]) == 0.0:
				cel_i = i
				break
		if cel_i >= 0:
			rajd.widok[cel_i] = 2
			rajd.zmienione_widoku = PackedInt32Array([cel_i])
			s3.odswiez_widok()
			s3._krok_mgly(0.1)
			var posrednio: float = s3._jasn[cel_i]
			s3._krok_mgly(0.5)
			_ok("mgła: odkryte pole wyłania się płynnie (nie w jednej klatce)", posrednio > 0.05 and posrednio < 0.9 and is_equal_approx(s3._jasn[cel_i], 1.0), "po 0,1 s jasność %.2f" % posrednio)
	var sk_ok := true
	for sk in m.skrzynie:
		if d[m.idx(sk["tx"], sk["ty"])] < 0:
			sk_ok = false
	_ok("duża mapa: każda skrzynia osiągalna", sk_ok and m.skrzynie.size() >= 50, "%d skrzyń" % m.skrzynie.size())
	var rodzaje := {}
	for k in m.komnaty:
		rodzaje[k["typ"]] = true
	_ok("duża mapa: różne rodzaje komnat", rodzaje.size() >= 6 and m.komnaty.size() >= 45, "%d komnat: %s" % [m.komnaty.size(), ", ".join(rodzaje.keys())])
	var m2 = Mapgen.new()
	m2.generuj(rajd.kraina, rajd.ziarno, Profil.poziom("scavenger"))
	_ok("to samo ziarno = ten sam duży loch", m2.siatka == m.siatka and m2.start == m.start and m2.skrzynie.size() == m.skrzynie.size())
	_ok("wrogowie: liczba wg krainy, w komnatach", rajd.wrogowie.size() == int(rajd.kraina["enemyCount"]), "%d wrogów" % rajd.wrogowie.size())
	# tytuł obszaru przy pierwszym wejściu do komnaty (np. Krypta, Skarbiec)
	var g = rajd.gracz
	var w0: Vector2 = g.w
	var docel := -1
	for i in m.komnaty.size():
		if rajd.NAZWY_OBSZAROW.has(m.komnaty[i]["typ"]) and not rajd.odwiedzone_komnaty.has(i):
			docel = i
			break
	if docel >= 0:
		var rr: Rect2i = m.komnaty[docel]["r"]
		for dy in range(1, rr.size.y - 1):
			var w := Vector2(rr.position.x + 1.5, rr.position.y + dy + 0.5)
			if not Mapgen.blokuje_ruch(m.kafel(int(w.x), int(w.y))):
				g.w = w
				break
		rajd._sprawdz_obszar()
		await _klatka()
		var nazwa: String = rajd.NAZWY_OBSZAROW[m.komnaty[docel]["typ"]][0]
		_ok("tytuł obszaru przy wejściu do komnaty", hud.tytul_obszaru != null and (hud.tytul_obszaru.get_child(0) as Label).text == nazwa.to_upper(), nazwa)
		g.w = w0
		rajd._sprawdz_obszar()
	# pościg: wróg bez linii wzroku obchodzi mury po polu odległości
	rajd._pole_od = Vector2i(-99, -99)
	rajd._licz_pole()
	var cel := Vector2(-1, -1)
	for y in range(int(g.w.y) - 14, int(g.w.y) + 15):
		for x in range(int(g.w.x) - 14, int(g.w.x) + 15):
			if x < 1 or y < 1 or x >= Mapgen.ROZMIAR - 1 or y >= Mapgen.ROZMIAR - 1:
				continue
			var dd: int = rajd._pole[y * Mapgen.ROZMIAR + x]
			var w := Vector2(x + 0.5, y + 0.5)
			if dd >= 8 and dd <= 24 and not rajd.linia_wzroku(w, g.w) and dd > w.distance_to(g.w) + 3.0:
				cel = w
				break
		if cel.x >= 0:
			break
	if cel.x < 0:
		_ok("pościg: wróg obchodzi mur korytarzem", true, "brak takiego miejsca przy starcie — pominięty")
		return
	var en = rajd.wrogowie[1]
	var stara: Vector2 = en.w
	for inny in rajd.wrogowie:
		inny.uspiony = true
	en.w = cel
	en.hp = 9999.0
	en.stan = "walka"
	en.uspiony = false
	var d0: int = rajd._pole[int(cel.y) * Mapgen.ROZMIAR + int(cel.x)]
	await _czekaj_az(func():
		var i: int = int(en.w.y) * Mapgen.ROZMIAR + int(en.w.x)
		return rajd._pole[i] >= 0 and rajd._pole[i] <= d0 - 4, 8.0)
	var d1: int = rajd._pole[int(en.w.y) * Mapgen.ROZMIAR + int(en.w.x)]
	_ok("pościg: wróg obchodzi mur korytarzem", d1 >= 0 and d1 <= d0 - 4, "z %d do %d kroków" % [d0, d1])
	en.uspiony = true
	en.stan = "patrol"
	en.w = stara
	g.hp = g.hp_max


func _test_mapy() -> void:
	var s3 = rajd.swiat3d
	if s3 == null:
		return
	var mat = s3._mat.get("podloga")
	var tex: Texture2D = mat.get_shader_parameter("a_alb") if mat is ShaderMaterial else null
	_ok("mapa: podłoga z tekstur NightBrand krainy", tex != null and tex.resource_path.contains(s3.wyglad["a"]), tex.resource_path.get_file() if tex else "brak")
	var mur = s3._mat.get("mur")
	_ok("mapa: mury z własnym materiałem", mur is ShaderMaterial and mur.get_shader_parameter("m_alb") != null)
	s3.odswiez_widok()
	var wiszace := 0
	for pm in s3._pochodnie_murow:
		if (pm[0] as Node3D).visible and s3._mury_ciete.get(pm[2], false):
			wiszace += 1
	_ok("mapa: pochodnie na obniżonych murach ukryte", s3._pochodnie_murow.size() > 0 and wiszace == 0, "%d pochodni" % s3._pochodnie_murow.size())


## Płynność ruchu bohatera: obrót bez skoków, doskok dopływa, kroki dopasowane do kierunku ruchu.
func _test_plynnosci(p) -> void:
	var s3 = rajd.swiat3d
	if s3 == null:
		return
	p.pochodnia_w_rece = false
	# 1. obrót o 180° rozkłada się na klatki
	p.kat = 0.0
	await _czekaj(0.3)
	p.kat = PI
	var yaw_prev: float = s3.bohater.rotation.y
	var max_krok := 0.0
	var klatek := 0
	for i in 12:
		await _klatka()
		var y: float = s3.bohater.rotation.y
		var k := absf(angle_difference(yaw_prev, y))
		max_krok = maxf(max_krok, k)
		if k > 0.01:
			klatek += 1
		yaw_prev = y
	_ok("obrót o 180° płynny (bez skoku w jednej klatce)", max_krok < 1.0 and klatek >= 3, "max %.2f rad/klatkę, %d klatek" % [max_krok, klatek])
	# 2. doskok do wroga przy ciosie dopływa, nie teleportuje (doskok jest tylko do celu)
	p.atak_cd = 0.0
	p.combo_reset = 0.0
	p.stamina = p.stamina_max
	var en_d = rajd.wrogowie[0]
	var en_d_w: Vector2 = en_d.w
	en_d.uspiony = true
	en_d.atak_timer = 99.0
	en_d.w = p.w + Vector2(cos(p.kat), sin(p.kat)) * 1.9
	if rajd.pelne(en_d.w.x, en_d.w.y):
		en_d.w = p.w - Vector2(cos(p.kat), sin(p.kat)) * 1.9
	en_d.widoczny_dla_gracza = true
	rajd.atak_wrecz()
	await _po_cieciu()  # doskok następuje w chwili cięcia (po zamachu)
	await _klatka()
	var skok: float = Vector2(s3.bohater.position.x, s3.bohater.position.z).distance_to(p.w)
	if _zrzuty != "":  # sekwencja ciosu do oceny ruchu (co klatkę gry, 0,05 s)
		for i in 10:
			await _zrzut("seq_atak_%02d" % i)
	# czekamy, aż obraz dogoni logikę (nie sztywne 0,6 s — przy wyższym FPS spakowanej gry wynik wypadał na granicy)
	await _czekaj_az(func(): return Vector2(s3.bohater.position.x, s3.bohater.position.z).distance_to(p.w) < 0.03, 1.5)
	var po: float = Vector2(s3.bohater.position.x, s3.bohater.position.z).distance_to(p.w)
	_ok("doskok do wroga dopływa płynnie", skok > 0.05 and po < 0.03, "po ciosie %.2f m od logiki, potem %.2f m" % [skok, po])
	en_d.w = en_d_w
	await _czekaj(0.6)
	# 3. kroki zgodne z kierunkiem ruchu względem twarzy
	var wyniki := {}
	for konf in [["bieg", Vector2(1, 0), Vector2(1, 0), ["_bieg"]], ["tyl", Vector2(1, 0), Vector2(-1, 0), ["_tyl"]], ["bok", Vector2(1, 0), Vector2(0, -1), ["_lewo", "_prawo"]]]:
		_os(JOY_AXIS_LEFT_X, konf[1].x)
		_os(JOY_AXIS_LEFT_Y, konf[1].y)
		_os(JOY_AXIS_RIGHT_X, konf[2].x)
		_os(JOY_AXIS_RIGHT_Y, konf[2].y)
		var pasuje := func() -> bool:
			var an: String = s3._ap_bohatera.current_animation
			return konf[3].any(func(suf): return an.ends_with(suf))
		await _czekaj_az(pasuje, 12.0)  # obrót ciała jest wygładzony, więc przy małym FPS trwa dłużej
		await _czekaj(0.2)
		wyniki[konf[0]] = s3._ap_bohatera.current_animation
		if _zrzuty != "":
			for i in 3:
				await _zrzut("seq_%s_%02d" % [konf[0], i])
	_os(JOY_AXIS_LEFT_X, 0.0)
	_os(JOY_AXIS_LEFT_Y, 0.0)
	_os(JOY_AXIS_RIGHT_X, 0.0)
	_os(JOY_AXIS_RIGHT_Y, 0.0)
	_ok("kroki: bieg przodem, krok w tył, krok w bok", wyniki["bieg"].ends_with("_bieg") and wyniki["tyl"].ends_with("_tyl") and (wyniki["bok"].ends_with("_lewo") or wyniki["bok"].ends_with("_prawo")), str(wyniki))
	await _czekaj(0.3)


func _test_wygladu(p, en) -> void:
	var B = load("res://skrypty/bohater.gd")
	var wyg: Dictionary = Dane.wyglad
	var kom: int = int(wyg.get("komorka", 224))
	# wszystkie arkusze istnieją i mają wymiar: klatki x 8 kierunków
	var braki := []
	for z in wyg.get("klatki", {}).keys():
		for a in wyg["klatki"][z].keys():
			var n: int = int(wyg["klatki"][z][a])
			var sc := "res://zasoby/hadraen/%s_%s.png" % [z, a]
			var t: Texture2D = load(sc) if ResourceLoader.exists(sc) else null
			if t == null or t.get_width() != n * kom or t.get_height() != 8 * kom:
				braki.append("%s_%s" % [z, a])
	_ok("arkusze Hadræna kompletne (%d zestawów)" % wyg.get("klatki", {}).size(), braki.is_empty() and wyg.get("klatki", {}).size() >= 6, ", ".join(braki))
	# broń jest klasą: zestaw zależy od broni i tarczy
	var przypadki := [
		[{"weapon": {"id": "ash_greatsword"}, "shield": null}, "dwureczny"],
		[{"weapon": {"id": "executioner_axe"}, "shield": null}, "topor"],
		[{"weapon": {"id": "warden_glaive"}, "shield": null}, "glewia"],
		[{"weapon": {"id": "rusty_sword"}, "shield": null}, "miecz"],
		[{"weapon": {"id": "rusty_sword"}, "shield": {"id": "wood_buckler"}}, "miecz_tarcza"],
		[{"weapon": null, "shield": null}, "piesci"],
	]
	var zle := []
	for pr in przypadki:
		var z: String = B.zestaw_dla(pr[0])
		if z != pr[1]:
			zle.append("%s→%s" % [pr[1], z])
	_ok("broń w ręce wybiera zestaw animacji", zle.is_empty(), ", ".join(zle))
	_ok("Hadræn ma arkusze swojej broni", p.zestaw == B.zestaw_dla(p.rynsztunek) and p._arkusze.size() >= 9, p.zestaw)
	# 8 kierunków bez odbijania
	var kier := []
	for i in 8:
		kier.append(B.kierunek(i * PI / 4.0))
	_ok("8 kierunków postaci", kier == [0, 1, 2, 3, 4, 5, 6, 7] and B.kierunek(-PI / 4.0) == 7)
	await _zrzut("4_hadraen_postoj")
	en.uspiony = true
	await _czekaj(0.3)
	var biodra_postoj := _biodra3d()
	var dlon_postoj := _dlon3d()
	# parowanie: LB wciśnięty -> animacja parowania, potem blok
	_przycisk(JOY_BUTTON_LEFT_SHOULDER, true)
	await _czekaj_az(func(): return p.blok, 1.0)
	await _klatka()
	var anim_par: String = p.biezaca_anim
	var anim_par3d := _anim3d()
	await _klatka()
	var dlon_par := _dlon3d()
	await _zrzut("5_hadraen_parowanie")
	await _czekaj_az(func(): return p.blok_czas > 0.4, 2.0)
	await _klatka()
	var anim_blok: String = p.biezaca_anim
	_przycisk(JOY_BUTTON_LEFT_SHOULDER, false)
	_ok("LB: animacja parowania, potem bloku", anim_par == "parowanie" and anim_blok == "blok", anim_par + " → " + anim_blok)
	_ok("3D: model Hadræna paruje w grze (widoczna poza)", anim_par3d.ends_with("_parowanie") and dlon_par.distance_to(dlon_postoj) > 0.08,
		"%s, dłoń przesunięta o %.2f m" % [anim_par3d, dlon_par.distance_to(dlon_postoj)])
	await _czekaj(0.7)
	# przewrót: A (układ NightBrand) -> animacja przewrotu z nietykalnością
	p.stamina = p.stamina_max
	p.unik_cd = 0.0
	await _pad(JOY_BUTTON_A, 0.05)
	await _czekaj_az(func(): return p.unik_czas > 0.0 or p.biezaca_anim == "przewrot", 1.0)
	await _klatka()
	var anim_unik: String = p.biezaca_anim
	var anim_unik3d := _anim3d()
	var biodra_min := biodra_postoj
	# Mierzymy cały przewrót; sześć klatek pomijało najniższą pozę przy wyższym FPS.
	while p.unik_czas > 0.0:
		await _klatka()
		biodra_min = minf(biodra_min, _biodra3d())
	await _zrzut("6_hadraen_przewrot")
	_ok("B: przewrót", anim_unik == "przewrot", anim_unik)
	_ok("3D: model Hadræna robi przewrót w grze (widoczna poza)", anim_unik3d.ends_with("_przewrot") and biodra_postoj - biodra_min > 0.15,
		"%s, biodra niżej o %.2f m" % [anim_unik3d, biodra_postoj - biodra_min])
	await _czekaj(0.5)
	en.uspiony = false


func _suma_pd(u: String) -> float:
	var lv := Profil.poziom(u)
	var suma := float(Profil.d["skills"][u]["xp"])
	for k in range(1, lv):
		suma += k * 100.0
	return suma


func _test() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--zrzuty="):
			_zrzuty = a.substr(9)
			DirAccess.make_dir_recursive_absolute(_zrzuty)
	Profil.resetuj()
	_test_ekonomia_danych()
	print("-- test gry Godot (symulowany pad)")
	await _czekaj(0.4)
	await _test_tytulu()
	# Warownia-Przystań: start w 3D, swobodny ruch, NPC otwierają menu
	_ok("Przystań: start w 3D, menu Warowni ukryte", przystan != null and przystan.is_inside_tree() and not hub.is_visible_in_tree())
	await _zrzut("1_przystan")
	var s0: Vector2 = przystan.poz
	_os(JOY_AXIS_LEFT_X, 1.0)
	await _czekaj_az(func(): return przystan.poz.distance_to(s0) > 0.5, 8.0)
	_os(JOY_AXIS_LEFT_X, 0.0)
	_ok("Przystań: lewy drążek chodzi", przystan.poz.distance_to(s0) > 0.5, "%.2f m" % przystan.poz.distance_to(s0))
	przystan.poz = przystan.MIEJSCA["marga"][2] + Vector2(0.9, 0.9)
	await _czekaj_az(func(): return przystan.cel == "marga", 5.0)
	await _pad(JOY_BUTTON_Y)
	await _czekaj_az(func(): return hub.is_visible_in_tree(), 5.0)
	_ok("Przystań: Y przy Mardze otwiera Kupca", hub.is_visible_in_tree() and hub.zakladki.current_tab == 2, "zakładka %d" % hub.zakladki.current_tab)
	await _zrzut("1b_marga_kupiec")
	# przejście zakładek padem (RB): w Kramie najpierw Kup → Sprzedaj, za skrajną zakładką — Warownia
	_ok("Kram Margi na szablonie NightBrand", hub.ekran.visible and hub.ekran.tytul.text == "KRAM MARGI")
	hub.tryb_kupca = "kup"
	hub.odswiez()
	_os(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _klatka()
	_os(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _klatka()
	_ok("Kram: RT przełącza Kup → Sprzedaj łup", hub.tryb_kupca == "sprzedaj" and hub.zakladki.current_tab == 2)
	_os(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _klatka()
	_os(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _klatka()
	_ok("Kram: LT wraca do Kup", hub.tryb_kupca == "kup")
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("RB przełącza sekcję (Kram → Warownia)", hub.zakladki.current_tab == 3 and hub.ekran.tytul.text == "ROZBUDOWA WAROWNI" and hub.ekran.aktywna == 3)
	await _pad(JOY_BUTTON_LEFT_SHOULDER)
	_ok("LB wraca do Kramu", hub.zakladki.current_tab == 2 and hub.ekran.tytul.text == "KRAM MARGI")
	hub.tryb_kupca = "kup"
	hub.zakladki.current_tab = 1
	await _zrzut("2_ekwipunek")
	await _pad(JOY_BUTTON_B)
	await _czekaj_az(func(): return not hub.is_visible_in_tree(), 5.0)
	_ok("B wraca do Przystani", not hub.is_visible_in_tree() and przystan.aktywna)
	# przewoźnik na pomoście: podejście padem + A otwiera Wyprawę
	przystan.poz = Vector2(10.6, 3.0)
	await _czekaj_az(func(): return przystan.cel == "przewoznik", 5.0)
	_ok("Przystań: przewoźnik stoi na pomoście", przystan.cel == "przewoznik" and przystan._npc.has("przewoznik"))
	przystan.poz = Vector2(10.6, 3.0)
	await _czekaj_az(func(): return przystan.cel == "przewoznik" and przystan.krag != null and przystan.krag.visible, 3.0)
	var kp: Vector3 = przystan._npc["przewoznik"]["wezel"].position
	_ok("Przystań: złoty krąg pod rozmówcą", przystan.krag != null and przystan.krag.visible and Vector2(przystan.krag.position.x, przystan.krag.position.z).distance_to(Vector2(kp.x, kp.z)) < 0.1)
	await _pad(JOY_BUTTON_Y)
	await _czekaj_az(func(): return hub.is_visible_in_tree(), 5.0)
	_ok("Przystań: Y przy przewoźniku otwiera Wyprawę", hub.is_visible_in_tree() and hub.zakladki.current_tab == 0, "zakładka %d" % hub.zakladki.current_tab)
	await _zrzut("1c_przewoznik")
	await _pad(JOY_BUTTON_B)
	await _czekaj_az(func(): return not hub.is_visible_in_tree(), 5.0)
	przystan.uzyj("chlop")
	_ok("Przystań: gawędziarz mówi", przystan._dymek.visible and przystan._dymek.text.length() > 10)
	przystan.poz = Vector2(18.0, 22.0)
	_test_lasu()
	_test_osady()
	await _test_pauzy("Przystań", "9a_pauza_przystan")
	await _pad(JOY_BUTTON_BACK)
	await _czekaj_az(func(): return hub.is_visible_in_tree(), 5.0)
	_ok("Back otwiera całe menu Warowni", hub.is_visible_in_tree())
	await _test_kramu()
	await _test_szlifu_menu()
	hub.zakladki.current_tab = 0
	await _czekaj(0.2)
	# ustawienie jakości grafiki: przycisk przełącza i zapamiętuje
	var j0: int = Profil.jakosc()
	pauza._napisy_ustawien()
	pauza._grafika.pressed.emit()  # Grafika i Dźwięk są w pauzie → Opcje (etap 1 przebudowy menu)
	var j1: int = Profil.jakosc()
	_ok("Opcje: przycisk Grafika zmienia i zapamiętuje jakość", j1 == (j0 + 1) % 4 and pauza._grafika.text.ends_with(Profil.JAKOSCI[j1]), "%s → %s" % [Profil.JAKOSCI[j0], Profil.JAKOSCI[j1]])
	Profil.ustaw_jakosc(j0)

	# kontrakt Chojraka do sprawdzenia przy ekstrakcji
	Profil.d["kontrakty"] = [{"typ": "ekstrakcja", "kraina": "catacombs", "cel": 1, "postep": 0, "nagroda": 150}]
	var zloto_przed_rajdem: int = int(Profil.d["gold"])
	hub.zakladki.current_tab = 0
	hub.odswiez()
	var belki := hub.ekran.lista.find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
	var kontrakty := hub.ekran.lista.find_children("*", "Button", true, false).filter(func(b): return b.get_meta("klucz", "") == "kontrakt")
	_ok("Wyprawa: lista kontraktów Chojraka", belki.has("KONTRAKTY CHOJRAKA") and kontrakty.size() >= 1, "%d kontraktów" % kontrakty.size())
	rozpocznij_rajd("catacombs", "TEST01")
	await _czekaj(0.5)
	_ok("rajd startuje", rajd != null and rajd.gracz != null)
	await _test_pauzy("rajd", "9b_pauza_rajd")
	# HUD jak w NightBrand: kule, pasek akcji, zegar, minimapa w ramie; medalion pokazuje postawę
	_ok("HUD: kule życia i wytrzymałości, pasek akcji, zegar, minimapa", hud.kula_hp.is_visible_in_tree() and hud.kula_st.is_visible_in_tree()
		and hud.pasek.is_visible_in_tree() and hud.zegar.is_visible_in_tree() and hud.minimapa.is_visible_in_tree())
	var pp = rajd.gracz
	pp.okno_parowania = 0.2
	var st_par: String = hud.stan_postawy()[1]
	pp.okno_parowania = 0.0
	pp.ladowanie = rajd.PROG_MOCNEGO
	var st_lad: String = hud.stan_postawy()[1]
	pp.ladowanie = 0.0
	_ok("HUD: medalion postawy (parowanie, mocny cios)", st_par == "PAROWANIE!" and st_lad == "MOCNY CIOS", "%s / %s" % [st_par, st_lad])
	_test_mapy()
	await _test_duzej_mapy()
	var p = rajd.gracz
	for en in rajd.wrogowie:
		en.w = Vector2(2.5, 2.5) if rajd.mapa.kafel(2, 2) != 2 else en.w
		en.stan = "patrol"
		en.uspiony = true
	var start: Vector2 = p.w
	_os(JOY_AXIS_LEFT_X, 1.0)
	await _czekaj(0.5)
	_os(JOY_AXIS_LEFT_X, 0.0)
	await _klatka()
	_ok("ruch lewym drążkiem", p.w.distance_to(start) > 0.5, "%.2f pola, %d FPS" % [p.w.distance_to(start), Engine.get_frames_per_second()])
	await _zrzut("3a_hadraen_z_pochodnia")
	_ok("płomień pochodni przy lewej dłoni", p.pochodnia.position.distance_to(p._dlon + Vector2(0, -26)) < 0.5 and p._dlon.y < -20.0, str(p._dlon))

	# pochodnia w ręce: brak parowania
	var en = rajd.wrogowie[0]
	en.uspiony = false
	en.hp = 9999.0
	en.hp_max = 9999.0
	await _pad(JOY_BUTTON_LEFT_SHOULDER, 0.05)
	_ok("pochodnia w ręce blokuje parowanie", p.okno_parowania == 0.0)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _czekaj_az(func(): return not p.pochodnia_w_rece, 1.0)
	_ok("krzyżak ↓ rzuca pochodnię", not p.pochodnia_w_rece and rajd.pochodnia_na_ziemi != null)

	# Hadræn z modelu 3D: zestaw arkuszy wg broni, 8 kierunków, przewrót, parowanie
	await _test_wygladu(p, en)

	# parowanie złotego błysku
	if en.rodzaj == "archer" or en.ciezki:
		en.queue_free()
		rajd.wrogowie.erase(en)
		en = rajd._dodaj_wroga("warden", p.w, 0.0)
		en.hp = 9999.0
		en.hp_max = 9999.0
	_ustaw_wroga_przed(en, 1.2)
	en.zamach = en.zamach_dl
	en.atak_timer = 0.0
	await _czekaj(0.1)
	await _zrzut("3_rajd_zamach")
	if rajd.swiat3d:
		var d3: Dictionary = rajd.swiat3d._wrogowie.get(en.get_instance_id(), {})
		var ap3: AnimationPlayer = d3.get("ap")
		var l3: OmniLight3D = d3.get("swiatlo")
		var sila3: float = float(d3.get("tint_zamachu", 0.0))
		_ok("3D: zapowiedź ciosu wroga (zamach + lekka poświata sylwetki, bez słupa światła)", ap3 != null and ap3.current_animation == "zamach" and l3.light_energy < 0.01 and sila3 > 0.04,
			"%s, światło %.1f, poświata %.2f" % [ap3.current_animation if ap3 else "-", l3.light_energy if l3 else 0.0, sila3])
		var zn: MeshInstance3D = d3.get("znak")
		var przod := Vector2(zn.global_transform.basis.x.x, zn.global_transform.basis.x.z).normalized() if zn else Vector2.ZERO
		var cel := Vector2(cos(en.kat), sin(en.kat))
		_ok("zapowiedź: klin zasięgu na ziemi, w stronę ciosu", zn != null and zn.visible and przod.dot(cel) > 0.95, "zgodność kierunku %.2f" % przod.dot(cel))
		# błysk „paruj teraz” pojawia się przed uderzeniem, w czasie krótszym niż okno parowania
		# (wywołanie wprost, bez czekania na klatki: przy małym FPS cios spadłby w trakcie testu)
		var zostaw: float = en.zamach
		en.zamach = rajd.swiat3d.BLYSK_PRZED * 0.5
		rajd.swiat3d._zapowiedz(en, d3, 0.9, true)
		var gw: Sprite3D = d3.get("glint")
		var widac_blysk: bool = gw != null and gw.visible
		var pr: MeshInstance3D = d3.get("pierscien")
		var pierscien_jasny: bool = pr != null and pr.visible and float(d3["pierscien_mat"].get_shader_parameter("w_oknie")) > 0.5
		en.zamach = maxf(zostaw, 0.3)
		await _zrzut("3b_zapowiedz_blysk")
		_ok("zapowiedź: błysk i jasny pierścień, gdy parowanie już zdąży", widac_blysk and pierscien_jasny and absf(rajd.swiat3d.BLYSK_PRZED - rajd.dlugosc_okna_parowania()) < 0.001, "błysk %.2f s przed ciosem = okno parowania" % rajd.swiat3d.BLYSK_PRZED)
	# LB wciśnięty, a cios wroga spada w oknie parowania (deterministycznie, niezależnie od FPS)
	await _pad(JOY_BUTTON_LEFT_SHOULDER, 0.02)
	en.zamach = 0.01
	await _czekaj(0.1)
	_ok("LB paruje złoty błysk", en.ogluszenie > 0.0 and p.hp == p.hp_max, "ogłuszenie %.2f, HP %d" % [en.ogluszenie, p.hp])
	var hp0: float = en.hp
	_ustaw_wroga_przed(en, 1.0)  # niezależnie od FPS: wróg stoi przed graczem w chwili ciosu
	await _pad(JOY_BUTTON_X, 0.05)
	await _czekaj_az(func(): return en.hp < hp0, 1.5)
	_ok("X: riposta", hp0 - en.hp > 50.0 and en.ogluszenie <= 0.0, "-%d HP" % int(hp0 - en.hp))

	# podpowiedź: parowanie wciśnięte za wcześnie (okno wygasło przed ciosem)
	p.okno_parowania = 0.0
	p.parowanie_cd = 0.3
	p.riposta_niet = 0.0
	p.niet = 0.0  # po parowaniu trwa nietykalność 0,7 s — tu sprawdzamy sam napis
	p.unik_czas = 0.0
	var en_ciezki_byl: bool = en.ciezki
	en.ciezki = false
	rajd.trafienie_gracza(en, 1.0)
	en.ciezki = en_ciezki_byl
	var jest_napis := rajd.efekty.napisy.any(func(n): return str(n["tekst"]).contains("ZA WCZEŚNIE"))
	_ok("podpowiedź „ZA WCZEŚNIE” przy oknie parowania wygasłym przed ciosem", jest_napis)
	p.hp = p.hp_max
	p.parowanie_cd = 0.0

	# postura
	var pekla := false
	var ciosy := {}
	for i in 12:
		_ustaw_wroga_przed(en, 0.9)
		en.atak_timer = 99.0
		en.zamach = 0.0
		p.stamina = p.stamina_max
		await _pad(JOY_BUTTON_X, 0.04)
		ciosy[p.biezaca_anim] = true
		if p.biezaca_anim == "atak3":
			await _zrzut("7_hadraen_ciezki_cios")
		await _czekaj(0.4)
		if en.ogluszenie > 0.0:
			pekla = true
			break
	_ok("ciosy łamią posturę", pekla)
	_ok("combo ma własne animacje ciosów", ciosy.has("atak1") and ciosy.has("atak2"), ", ".join(ciosy.keys()))
	await _test_mocnego_ciosu(p, en)
	await _test_namierzania(p, en)
	await _test_oprawy_walki(p, en)
	await _test_walki_i_oznaczen(p, en)
	en.w = Vector2(2.5, 2.5)
	en.uspiony = true

	await _test_plynnosci(p)

	# skrzynia: A otwiera, przeszukanie, zabierz wszystko, B zamyka
	var sk: Dictionary = rajd.mapa.skrzynie[0]
	p.w = sk["w"] + Vector2(0.6, 0.0)
	if rajd.pelne(p.w.x, p.w.y):
		p.w = sk["w"] + Vector2(0.0, 0.6)
	await _czekaj(0.15)
	var przed: int = p.rynsztunek["backpack"].size()
	await _pad(JOY_BUTTON_Y)
	_ok("Y otwiera skrzynię", okno.otwarte and rajd.aktywny_pojemnik == sk)
	await _czekaj_az(func(): return rajd.aktywny_pojemnik["przedmioty"].all(func(w): return w["odkryty"]), 15.0)
	await _czekaj(0.3)
	await _zrzut("4_okno_lupu")
	okno.zabierz.grab_focus()
	await _klatka()
	await _pad(JOY_BUTTON_A)
	await _czekaj(0.2)
	_ok("łup trafia do sakwy", p.rynsztunek["backpack"].size() > przed, "%d → %d" % [przed, p.rynsztunek["backpack"].size()])
	await _pad(JOY_BUTTON_B)
	await _czekaj(0.2)
	_ok("B zamyka okno", not okno.otwarte and not rajd.okno_otwarte)

	# zrzut sakwy R3
	p.rynsztunek["backpack"].append(Profil.nowy_przedmiot("golden_idol"))
	await _pad(JOY_BUTTON_LEFT_STICK)
	var sakwy := rajd.zwloki.filter(func(z): return z["sakwa"])
	_ok("L3 zrzuca sakwę (pas zostaje)", sakwy.size() == 1 and rajd.sakwa_obciazenie() == 0)
	# podnieś z powrotem
	rajd.otworz(sakwy[0])
	await _czekaj(0.3)
	okno._zabierz_wszystko()
	okno.zamknij_okno()
	_ok("sakwa podniesiona", rajd.sakwa_obciazenie() > 0)

	# ekstrakcja
	p.hp = 9999.0
	p.hp_max = 9999.0
	for w in rajd.wrogowie:  # test ekstrakcji, nie walki: wróg nie może wypchnąć gracza z kręgu
		w.uspiony = true
	await _czekaj_az(func(): return p.unik_czas <= 0.0, 5.0)  # przewrót w toku przesunąłby gracza z kręgu (wyścig przy małym FPS)
	p.w = rajd.mapa.ekstrakcje[0]["w"]
	var eks_diag := ""
	var eks_t := 0.0
	while wynik == null and eks_t < 180.0:
		await _czekaj(0.1)
		eks_t += 0.1
		if rajd != null:
			eks_diag = "pozostało %.1f s, w kręgu %s, odl %.1f, %d FPS" % [rajd.ekstrakcja_czas, str(rajd.w_ekstrakcji), p.w.distance_to(rajd.mapa.ekstrakcje[0]["w"]), Engine.get_frames_per_second()]
	_ok("ekstrakcja kończy rajd", wynik != null and ostatni_wynik.get("przezyl", false), eks_diag)
	await _zrzut("5_wynik")
	await _czekaj(0.2)
	await _pad(JOY_BUTTON_A)
	await _czekaj(0.3)
	_ok("A wraca do Warowni (Przystań)", przystan != null and rajd == null and not hub.is_visible_in_tree())
	var kw: Array = ostatni_wynik["s"].get("kontrakty", [])
	_ok("kontrakt wykonany po ekstrakcji: złoto i nowy kontrakt", kw.size() == 1 and int(Profil.d["gold"]) >= zloto_przed_rajdem + 150 and Profil.d["kontrakty"].size() == 1 and Profil.d["kontrakty"][0]["postep"] == 0, "%s, złoto %d → %d" % [str(kw), zloto_przed_rajdem, int(Profil.d["gold"])])
	_ok("Przystań: budynki wg poziomu Warowni", przystan.poziomy.get("forge", -1) == Profil.budynek("forge") and przystan.poziomy.size() == 4, str(przystan.poziomy))
	Profil.wczytaj()
	_ok("zapis po ekstrakcji", Profil.d["stats"]["survived"] == 1 and Profil.d["stats"]["raids"] == 1)
	_ok("idol trafił do Skrytki", Profil.d["stash"].any(func(i): return i["id"] == "golden_idol"))

	# drugi rajd: śmierć, Relikwiarz zostaje, połowa doświadczenia
	rozpocznij_rajd("catacombs", "TEST02")
	await _czekaj(0.4)
	p = rajd.gracz
	p.rynsztunek["reliquary"] = [Profil.nowy_przedmiot("runic_ring")]
	var xp_przed := _suma_pd("melee")
	rajd.xp("melee", 40.0)
	p.hp = 1.0
	p.hp_max = 100.0
	var wr = rajd.wrogowie[0]
	wr.w = p.w + Vector2(0.8, 0.0)
	wr.stan = "walka"
	wr.zamach = 0.05
	await _czekaj_az(func(): return wynik != null, 120.0)
	_ok("śmierć kończy rajd", wynik != null and not ostatni_wynik.get("przezyl", true))
	await _pad(JOY_BUTTON_A)
	await _czekaj(0.3)
	var l: Dictionary = Profil.d["loadout"]
	_ok("po śmierci: ekwipunek stracony, Relikwiarz ocalał", l["weapon"] == null and l["reliquary"].size() == 1 and l["reliquary"][0]["id"] == "runic_ring")
	var xp_po := _suma_pd("melee")
	_ok("po śmierci połowa doświadczenia", absf((xp_po - xp_przed) - 20.0) < 0.01, "+%.1f PD" % (xp_po - xp_przed))

	# trzeci rajd: Czarnobór (las z ziarna, biotop otwarty)
	await _test_czarnoboru()
	# czwarty rajd: Spalona Osada (wieś z ziarna, biotop otwarty)
	await _test_osady_w_rajdzie()

	var zle := _wyniki.count(false)
	print("\nWYNIK (godot): ", "OK" if zle == 0 else "BŁĘDY: %d" % zle, "  (%d/%d)" % [_wyniki.size() - zle, _wyniki.size()])
	get_tree().quit(0 if zle == 0 else 1)


## Regresja systemu trzech dodatków i zachowanej ekonomii broni.
func _test_ekonomii() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zrzuty="):
			_zrzuty = arg.trim_prefix("--zrzuty=")
			DirAccess.make_dir_recursive_absolute(_zrzuty)
	Profil.resetuj()
	_test_ekonomia_danych()
	var zloto := 0
	var strzaly: Dictionary = Profil.nowy_przedmiot("iron_arrows", 1)
	var cena_strzaly: int = Dane.cena_skupu(strzaly)
	_ok("ekonomia: częściowy kołczan ma proporcjonalną cenę", cena_strzaly > 0 and cena_strzaly < Dane.cena_skupu("iron_arrows"))
	Profil.d["stash"].append(strzaly)
	zloto = int(Profil.d["gold"])
	_ok("ekonomia: sprzedaż jest jednorazowa", Profil.sprzedaj(strzaly["uid"]) == cena_strzaly and Profil.sprzedaj(strzaly["uid"]) == 0 and int(Profil.d["gold"]) == zloto + cena_strzaly)
	Profil.d["gold"] = 0
	Profil.d["stash"] = []
	Profil.d["loadout"]["backpack"] = []
	Profil.d["loadout"]["reliquary"] = [Profil.nowy_przedmiot("steel_falchion")]
	Profil.d["loadout"]["weapon"] = null
	_ok("ekonomia: broń w Relikwiarzu wyklucza dar", not Profil.dar_dostepny())
	Profil.d["loadout"]["reliquary"] = []
	var stara_tarcza: Dictionary = Profil.d["loadout"]["shield"]
	_ok("ekonomia: dar pozwala wrócić do walki", Profil.przyjmij_dar() and not Profil.dar_dostepny())
	_ok("ekonomia: dar zachowuje obecną tarczę", Profil.d["loadout"]["shield"]["uid"] == stara_tarcza["uid"])
	var dar: Dictionary = Profil.d["loadout"]["weapon"]
	Profil.d["loadout"]["weapon"] = null
	Profil.d["stash"].append(dar)
	_ok("ekonomia: daru nie można zamienić w złoto", Dane.cena_skupu(dar) == 0 and Profil.sprzedaj(dar["uid"]) == 0 and int(Profil.d["gold"]) == 0)
	Profil.zapisz()
	Profil.wczytaj()
	_ok("ekonomia: znacznik daru przeżywa zapis", bool(Profil.d["stash"][0].get("dar_margi", false)))

	for wersja in [1, 2]:
		Profil.resetuj()
		Profil.d["version"] = wersja
		Profil.d["loadout"].erase("enhancements")
		var stary: Dictionary = Profil.nowy_przedmiot("ash_plate")
		var uid: String = stary["uid"]
		Profil.d["loadout"]["armor"] = stary
		for para in [["stash", "leather_jerkin"], ["backpack", "chainmail_hauberk"], ["reliquary", "ash_plate"]]:
			var lista: Array = Profil.d["stash"] if para[0] == "stash" else Profil.d["loadout"][para[0]]
			lista.append(Profil.nowy_przedmiot(para[1]))
		Profil.zapisz()
		Profil.wczytaj()
		var l: Dictionary = Profil.d["loadout"]
		_ok("migracja v%d: założona zbroja staje się okuciem, UID zachowane" % wersja, not l.has("armor") and l["enhancements"].size() == 1 and l["enhancements"][0]["id"] == "ulepszenie_ochrona_epic" and l["enhancements"][0]["uid"] == uid)
		var przeniesione := true
		for lista: Array in [Profil.d["stash"], l["backpack"], l["reliquary"]]:
			for inst: Dictionary in lista:
				przeniesione = przeniesione and Dane.typ(inst["id"]) != "armor"
		_ok("migracja v%d: wszystkie pojemniki bez dawnych zbroi" % wersja, przeniesione and int(Profil.d["version"]) == 3)
		var stan := JSON.stringify(Profil.d)
		Profil.wczytaj()
		_ok("migracja v%d: ponowne wczytanie nie duplikuje dodatków" % wersja, JSON.stringify(Profil.d) == stan)
	Profil.resetuj()
	var rodzaje := ["ruch", "ochrona", "odnowa", "unik"]
	var dodatki: Array = []
	for rodzaj: String in rodzaje:
		var inst: Dictionary = Profil.nowy_przedmiot("ulepszenie_%s_legendary" % rodzaj)
		dodatki.append(inst)
		Profil.d["stash"].append(inst)
	for i in 3:
		_ok("dodatek: montaż %d" % (i + 1), Profil.zaloz_dodatek(dodatki[i]["uid"]))
	_ok("dodatek: czwarty nie zajmuje miejsca i nie ginie", not Profil.zaloz_dodatek(dodatki[3]["uid"]) and Profil.przedmiot_uid(dodatki[3]["uid"]) == dodatki[3])
	_ok("dodatek: zdjęcie do Skrytki", Profil.zdejmij_dodatek(dodatki[0]["uid"]))
	var duplikat: Dictionary = Profil.nowy_przedmiot("ulepszenie_ochrona_common")
	Profil.d["stash"].append(duplikat)
	_ok("dodatek: nie można dublować rodzaju", not Profil.zaloz_dodatek(duplikat["uid"]) and Profil.d["loadout"]["enhancements"].size() == 2)
	Profil.zaloz_dodatek(dodatki[0]["uid"])
	Profil.zapisz()
	Profil.wczytaj()
	_ok("dodatek: trzy miejsca zachowane po zapisie", Profil.d["loadout"]["enhancements"].size() == 3 and is_equal_approx(Dane.bonus_ulepszen(Profil.d["loadout"], "ruch"), 0.1))
	# Rzeczywisty ekran, akcja myszy i symulowane A pada.
	otworz_menu(1)
	await _czekaj(0.5)
	var lista_dodatkow: Array = hub.ekran.lista.find_children("*", "Button", true, false).filter(func(b): return str(b.get_meta("klucz", "")).begins_with("dodatek_"))
	_ok("ekwipunek: trzy osobne miejsca do zdjęcia dodatków", lista_dodatkow.size() == 3)
	for w: Button in lista_dodatkow:
		if w.get_meta("klucz", "") == "dodatek_" + str(dodatki[0]["uid"]):
			w.pressed.emit()
			break
	await _klatka()
	_ok("ekwipunek: klik zdejmuje dodatek", Profil.d["loadout"]["enhancements"].size() == 2)
	var idx: int = -1
	for i in Profil.d["stash"].size():
		if Profil.d["stash"][i].get("uid") == dodatki[0]["uid"]:idx = i
	var wiersze: Array = hub.ekran.lista.find_children("*", "Button", true, false).filter(func(b): return b.get_meta("klucz", "") == "st%d" % idx)
	if not wiersze.is_empty():
		wiersze[0].grab_focus()
		await _czekaj(0.4)
		await _pad(JOY_BUTTON_A)
	await _klatka()
	_ok("ekwipunek: A pada zakłada dodatek ze Skrytki", Profil.d["loadout"]["enhancements"].size() == 3)
	await _zrzut("01_dodatki_ekwipunek")
	hub.zakladki.current_tab = 2
	await _klatka()
	var oferty: Array = hub.kram.lista.find_children("*", "Button", true, false).filter(func(b): return str(b.get_meta("klucz", "")).begins_with("kup_"))
	var bez_zbroi := true
	for b: Button in oferty:
		bez_zbroi = bez_zbroi and not Dane.typ(str(b.get_meta("klucz")).trim_prefix("kup_")) in ["armor", "enhancement"]
	_ok("kram: bez zbroi i kupowania dodatków", bez_zbroi and not oferty.is_empty())
	var zloto_przed: int = Profil.d["gold"]
	hub._kup("ash_plate")
	hub._kup("ulepszenie_ruch_common")
	_ok("kram: stare ID nie pozwala kupić wycofanego towaru", Profil.d["gold"] == zloto_przed)
	await _zrzut("02_kram_bez_zbroi")
	var sprzedaz: Dictionary = Profil.nowy_przedmiot("ulepszenie_unik_epic")
	Profil.d["stash"].append(sprzedaz)
	var cena: int = Dane.cena_skupu(sprzedaz)
	_ok("dodatek: można sprzedać łup tylko raz", cena > 0 and Profil.sprzedaj(sprzedaz["uid"]) == cena and Profil.sprzedaj(sprzedaz["uid"]) == 0)
	zamknij_menu()
	rozpocznij_rajd("czarnobor", "DODATKI1")
	await _czekaj(0.4)
	var p = rajd.gracz
	for en in rajd.wrogowie:en.uspiony = true
	var zestaw: Dictionary = p.rynsztunek
	p.niet = 0.0
	p.riposta_niet = 0.0
	p.blok = false
	p.okno_parowania = 0.0
	p.hp = 100.0
	rajd.trafienie_gracza(null, 20.0, true)
	_ok("walka: ochrona stałej zbroi i okucia zmniejsza obrażenia", is_equal_approx(p.hp, 86.8), "HP %.3f, ochrona %.3f" % [p.hp, Dane.ochrona_zbroi(zestaw)])
	p.stamina = 50.0
	p.stamina_przerwa = 0.0
	p.atak_czas = 0.0
	p.blok = false
	var obciazenie: float = maxf(0.55, 1.0 - rajd.sakwa_obciazenie() * 0.035)
	rajd._aktualizuj(0.1)
	_ok("walka: pieczęć przyspiesza faktyczną odnowę staminy", is_equal_approx(p.stamina, 50.0 + 2.4 * 1.16 * obciazenie))
	zestaw["enhancements"] = [Profil.nowy_przedmiot("ulepszenie_unik_legendary")]
	p.stamina = 100.0
	p.unik_cd = 0.0
	rajd.unik(Vector2.RIGHT)
	_ok("walka: rzemień zmniejsza faktyczny koszt przewrotu", is_equal_approx(p.stamina, 100.0 - 22.0 * 0.86))
	p.unik_czas = 0.0
	p.unik_cd = 0.0
	p.niet = 0.0
	p.atak_czas = 0.0
	p.atak_cd = 0.0
	p.ladowanie = 0.0
	p.predkosc = Vector2.ZERO
	zestaw["enhancements"] = [Profil.nowy_przedmiot("ulepszenie_ruch_legendary")]
	Input.action_press("ruch_prawo")
	for i in 3:rajd._aktualizuj(0.1)
	Input.action_release("ruch_prawo")
	_ok("ruch: klamra zwiększa faktyczną prędkość do 3,74 m/s", is_equal_approx(p.predkosc.length(), 3.74), "%.3f m/s" % p.predkosc.length())
	p.predkosc = Vector2.ZERO
	# Dodatek z łupu można przenieść, ale nie montować podczas rajdu.
	var znalezisko: Dictionary = Profil.nowy_przedmiot("ulepszenie_ruch_epic")
	zestaw["backpack"].append(znalezisko)
	okno._klik_sakwa("glowna", zestaw["backpack"].size() - 1)
	_ok("rajd: łup nie zmienia dodatków założonych przed wyprawą", zestaw["enhancements"].size() == 1 and zestaw["backpack"].has(znalezisko))
	zestaw["weapon"] = Profil.nowy_przedmiot("rusty_sword")
	zestaw["shield"] = null
	Profil.d["stronghold"]["altar"] = 2
	Profil.d["skills"]["parry"]["lv"] = 3
	var jednor: float = rajd.dlugosc_okna_parowania()
	zestaw["weapon"] = Profil.nowy_przedmiot("ash_greatsword")
	zestaw["shield"] = Profil.nowy_przedmiot("ash_aegis")
	_ok("ekonomia: dwuręczna ma połowę okna po premiach", is_equal_approx(rajd.dlugosc_okna_parowania(), jednor * 0.5) and Dane.aktywna_tarcza(zestaw).is_empty())
	_ok("ekonomia: animacja dwuręcznej pomija tarczę", p.zestaw_dla(zestaw) == "dwureczny")
	p.parowanie_cd = 0.0
	p.pochodnia_w_rece = true
	rajd.parowanie_start()
	_ok("ekonomia: dwuręczna paruje po odłożeniu pochodni", p.okno_parowania > 0.0 and not p.pochodnia_w_rece and rajd.pochodnia_na_ziemi != null)
	var cel = rajd.wrogowie[0]
	cel.ciezki = false
	p.niet = 0.0
	rajd.trafienie_gracza(cel, 20.0)
	_ok("ekonomia: dwuręczne parowanie ogłusza przeciwnika", cel.ogluszenie > 0.0 and p.okno_parowania == 0.0)
	_ok("ekonomia: postureDmg jest osobne od obrażeń", Dane.postura_broni(Dane.p("executioner_axe")) == 98.0 and Dane.postura_broni(Dane.p("steel_falchion")) == 25.0)
	# Rzeczywisty cios wykorzystuje postureDmg, a nie dmg.
	cel.ogluszenie = 0.0
	cel.hp = 9999.0
	cel.hp_max = 9999.0
	cel.postura = 1000.0
	cel.postura_max = 1000.0
	_ustaw_wroga_przed(cel, 1.2)
	p.cios_bron = Dane.p("executioner_axe")
	p.cios_ciezki = false
	p.atak_kat = p.kat
	rajd._ciecie()
	_ok("ekonomia: faktyczny cios zadaje posturę topora", is_equal_approx(cel.postura, 1000.0 - 98.0 * 0.85), "postura %.2f" % cel.postura)
	zestaw["weapon"] = Profil.nowy_przedmiot("rusty_sword")
	var okno_z_tarcza: float = rajd.dlugosc_okna_parowania()
	_ok("ekonomia: powrót do 1H aktywuje zachowaną tarczę", not Dane.aktywna_tarcza(zestaw).is_empty() and okno_z_tarcza > jednor)

	await _zrzut("03_staly_stroj_w_rajdzie")
	# Rozliczenie prawdziwego rajdu bez uruchamiania ekranu wyniku.
	rajd.koniec.disconnect(_koniec_rajdu)
	var zalozony_uid: String = zestaw["enhancements"][0]["uid"]
	rajd.zakoncz(true, "test")
	_ok("ekstrakcja: założony dodatek wraca z tym samym UID", Profil.d["loadout"]["enhancements"][0]["uid"] == zalozony_uid)
	# Drugi rajd: śmierć gubi dodatki, Relikwiarz przeżywa.
	rajd.queue_free()
	hud.queue_free()
	okno.queue_free()
	rajd = null
	hud = null
	okno = null
	await _klatka()
	Profil.d["loadout"]["reliquary"] = [Profil.nowy_przedmiot("ulepszenie_ochrona_rare")]
	rozpocznij_rajd("czarnobor", "DODATKI2")
	await _czekaj(0.3)
	rajd.koniec.disconnect(_koniec_rajdu)
	rajd.zakoncz(false, "test")
	_ok("śmierć: dodatki stracone, Relikwiarz zachowany", Profil.d["loadout"]["enhancements"].is_empty() and Profil.d["loadout"]["reliquary"][0]["id"] == "ulepszenie_ochrona_rare")
	_ok("śmierć: bazowa ochrona pozostaje bez kupowania zbroi", is_equal_approx(Dane.ochrona_zbroi(Profil.d["loadout"]), 0.24))
	print("WYNIK (ulepszenia): ", "OK" if not _wyniki.has(false) else "BŁĄD", " (", _wyniki.count(true), "/", _wyniki.size(), ")")
	get_tree().quit(0 if not _wyniki.has(false) else 1)


func _test_ekonomia_danych() -> void:
	var rodzaje: Dictionary = {"rusty_sword": 1, "steel_falchion": 1, "warden_glaive": 2, "ash_greatsword": 2, "executioner_axe": 2}
	var poprawne := true
	for id in rodzaje:
		var def: Dictionary = Dane.p(id)
		poprawne = poprawne and int(def.get("hands", 0)) == int(rodzaje[id]) and Dane.postura_broni(def) > 0.0
	_ok("ekonomia: pięć broni ma chwyt i posturę", poprawne)
	_ok("ekonomia: fallback dla starej definicji broni", Dane.postura_broni({"dmg": 17}) == 17.0)
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 7351
	r2.seed = 7351
	var zgodne := true
	var jakosci: Dictionary = {}
	for i in 1000:
		var id: String = Dane.losuj_dodatek(r1)
		zgodne = zgodne and id == Dane.losuj_dodatek(r2) and Dane.typ(id) == "enhancement"
		jakosci[Dane.p(id)["rarity"]] = true
	_ok("łup: dodatki deterministyczne, cztery jakości osiągalne", zgodne and jakosci.size() == 4)
	for rodzaj: String in Dane.ulepszenia_zbroi["kinds"]:
		var poprzedni := 0.0
		var rosnace := true
		for jakosc: String in Dane.ulepszenia_zbroi["rarityWeights"]:
			var def: Dictionary = Dane.p("ulepszenie_%s_%s" % [rodzaj, jakosc])
			rosnace = rosnace and float(def["bonus"]) > poprzedni and Dane.ikona(def["id"]) != null
			poprzedni = float(def["bonus"])
		_ok("jakość: rosnąca siła i ikony — " + rodzaj, rosnace)
	var bez: Dictionary = {"enhancements": []}
	_ok("zbroja: stała ochrona i podstawowy koszt uniku", is_equal_approx(Dane.ochrona_zbroi(bez), 0.24) and is_equal_approx(Dane.koszt_uniku(bez, 1), 22.0))
	for para: Array in [[Mapgen, "catacombs"], [MapgenLas, "czarnobor"], [MapgenOsada, "spalona_osada"]]:
		var mapa = para[0].new()
		mapa.generuj(Dane.kraina(para[1]), "DODATKI_LUP", 1)
		var bez_zbroi := true
		var dodatki := 0
		for skrzynia: Dictionary in mapa.skrzynie:
			for wpis: Dictionary in skrzynia["przedmioty"]:
				var typ: String = Dane.typ(wpis["przedmiot"]["id"])
				bez_zbroi = bez_zbroi and typ != "armor"
				if typ == "enhancement":dodatki += 1
		_ok("łup: bez zbroi, dodatki w pojemnikach — " + str(para[1]), bez_zbroi and dodatki > 0)


func _klik_testowy(punkt: Vector2) -> void:
	var ruch := InputEventMouseMotion.new()
	ruch.position = punkt
	ruch.global_position = punkt
	ruch.relative = Vector2(4, 0)
	get_viewport().push_input(ruch, true)
	await _klatka()
	for nacisniety: bool in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = punkt
		e.global_position = punkt
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = nacisniety
		# push_input dostaje współrzędne viewportu; stan Input uzupełniamy jak przy fizycznym LPM.
		for akcja: String in ["atak", "klik_interakcji"]:
			if nacisniety:Input.action_press(akcja)
			else:Input.action_release(akcja)
		get_viewport().push_input(e, true)
		await _klatka()
	await _klatka()


func _test_interakcji() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zrzuty="):
			_zrzuty = arg.trim_prefix("--zrzuty=")
			DirAccess.make_dir_recursive_absolute(_zrzuty)
	Profil.resetuj()
	await _czekaj(0.4)
	var npc: Vector2 = przystan.MIEJSCA["marga"][2]
	przystan.poz = npc + Vector2(0, 1.2)
	await _czekaj(0.3)
	_ok("NPC: etykieta przy rozmówcy", przystan.cel == "marga" and przystan.podpowiedz_obiektu.visible and not przystan._etykieta.visible)
	var kotwica := przystan.kamera.unproject_position(Vector3(npc.x, 2.05, npc.y))
	var etykieta := przystan.podpowiedz_obiektu.get_global_rect()
	_ok("NPC: napis nad głową, nie u góry ekranu", absf(etykieta.end.y - (kotwica.y - 8)) < 1 and absf(etykieta.get_center().x - kotwica.x) < 1)
	await _zrzut("04_npc_nad_glowa")
	var korpus := przystan.kamera.unproject_position(Vector3(npc.x, 1, npc.y))
	_ok("NPC: wybór sylwetki pod kursorem", przystan.miejsce_pod_kursorem(korpus) == "marga")
	await _klik_testowy(korpus)
	_ok("NPC: klik postaci otwiera handel", hub.is_visible_in_tree() and hub.zakladki.current_tab == 2)
	zamknij_menu()
	await _czekaj(0.5)
	await _pad(JOY_BUTTON_LEFT_STICK)
	_ok("NPC: podpowiedź pokazuje przycisk Y", przystan.podpowiedz_obiektu.text.begins_with("[Y]"))
	await _pad(JOY_BUTTON_Y)
	_ok("NPC: Y otwiera tę samą rozmowę", hub.is_visible_in_tree() and hub.zakladki.current_tab == 2)
	zamknij_menu()
	przystan.poz = npc + Vector2(5, 0)
	await _czekaj(0.5)
	_ok("NPC: nie można kliknąć rozmówcy z daleka", przystan.miejsce_pod_kursorem(przystan.kamera.unproject_position(Vector3(npc.x, 1, npc.y))) == "")
	rozpocznij_rajd("czarnobor", "INTERAKCJE")
	await _czekaj(0.4)
	for en in rajd.wrogowie:
		en.uspiony = true
		en.w = Vector2(1, 1)
	var poj: Dictionary = rajd.mapa.skrzynie[0]
	for kier: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		var obok: Vector2 = poj["w"] + kier * 0.8
		if not Mapgen.blokuje_ruch(rajd.mapa.kafel(floori(obok.x), floori(obok.y))):
			rajd.gracz.w = obok
			break
	rajd._licz_widok()
	rajd._kamera(1.0)
	rajd.kamera.force_update_scroll()
	rajd.swiat3d._ustaw_kamere()
	await _czekaj(0.3)
	_ok("skrzynia: podpowiedź przy obiekcie", hud.podpowiedz_obiektu.visible and hud._cel_podpowiedzi == poj and hud.podpowiedz.text == "")
	await _zrzut("05_skrzynia_nad_obiektem")
	var punkt: Vector2 = rajd.punkt_obiektu(poj, 0.35)
	_ok("skrzynia: wybierana pod kursorem", rajd.pojemnik_pod_kursorem(punkt) == poj)
	await _klik_testowy(punkt)
	_ok("skrzynia: klik otwiera wskazany pojemnik", rajd.okno_otwarte and rajd.aktywny_pojemnik == poj)
	_ok("skrzynia: klik nie wykonuje ataku", not rajd.gracz.trzyma_atak and rajd.bufor_ataku == 0 and rajd.gracz.atak_czas == 0)
	_ok("skrzynia: etykieta znika po otwarciu", not hud.podpowiedz_obiektu.visible)
	okno.zamknij_okno()
	await _czekaj(0.5)
	await _pad(JOY_BUTTON_Y)
	_ok("skrzynia: Y otwiera najbliższy pojemnik", rajd.okno_otwarte and rajd.aktywny_pojemnik == poj)
	okno.zamknij_okno()
	await _czekaj(0.5)
	rajd._dodaj_zwloki({"w": rajd.gracz.w + Vector2(0.3, 0), "rodzaj": "warden", "kat": 0.0, "nazwa": "Szczątki Gwardzisty", "boss": false, "sakwa": false, "przedmioty": [{"przedmiot": Profil.nowy_przedmiot("ulepszenie_ochrona_rare"), "odkryty": true}]})
	var zwloki: Dictionary = rajd.zwloki.back()
	rajd._licz_widok()
	await _czekaj(0.3)
	await _zrzut("06_zwloki_nad_obiektem")
	_ok("zwłoki: własna podpowiedź nad ciałem", hud._cel_podpowiedzi == zwloki and hud.podpowiedz_obiektu.text.contains("Szczątki Gwardzisty"))
	await _klik_testowy(rajd.punkt_obiektu(zwloki, 0.35))
	_ok("zwłoki: klik otwiera właściwe szczątki", rajd.okno_otwarte and rajd.aktywny_pojemnik == zwloki)
	okno.zamknij_okno()
	await _czekaj(0.5)
	# Kliknięcie samej podpowiedzi również wykonuje akcję.
	await _klik_testowy(hud.podpowiedz_obiektu.get_global_rect().get_center())
	_ok("zwłoki: klikalna etykieta", rajd.okno_otwarte and rajd.aktywny_pojemnik == zwloki)
	okno.zamknij_okno()
	await _czekaj(0.5)
	var dawna_pozycja: Vector2 = rajd.gracz.w
	rajd.gracz.w = zwloki["w"] + Vector2(4, 0)
	_ok("zasięg: odległy obiekt nie otwiera się po kliknięciu", not rajd.przeszukaj(zwloki) and not rajd.okno_otwarte)
	rajd.gracz.w = dawna_pozycja
	rajd.widok.fill(0)
	_ok("widoczność: ukryty łup nie daje interakcji", not rajd.mozna_przeszukac(zwloki))
	print("WYNIK (interakcje): ", "OK" if not _wyniki.has(false) else "BŁĄD", " (", _wyniki.count(true), "/", _wyniki.size(), ")")
	get_tree().quit(0 if not _wyniki.has(false) else 1)


func _test_pada_i_powrotu() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zrzuty="):
			_zrzuty = arg.trim_prefix("--zrzuty=")
			DirAccess.make_dir_recursive_absolute(_zrzuty)
	Profil.resetuj()
	Profil.d["gold"] = 5000
	Profil.d["stronghold"]["forge"] = 2
	otworz_menu(2)
	await _czekaj(0.6)
	var fokus := get_viewport().gui_get_focus_owner()
	_ok("pad: sklep zaczyna z fokusem na towarze", fokus != null and str(fokus.get_meta("klucz", "")).begins_with("kup_"))
	await _os_z_klatka(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _os_z_klatka(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_ok("pad: RT przełącza Kup na Sprzedaj", hub.tryb_kupca == "sprzedaj")
	await _os_z_klatka(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _os_z_klatka(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_ok("pad: LT przełącza Sprzedaj na Kup", hub.tryb_kupca == "kup")
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("pad: RB zmienia sekcję sklepu na Warownię", hub.zakladki.current_tab == 3)
	await _pad(JOY_BUTTON_LEFT_SHOULDER)
	_ok("pad: LB wraca do sklepu", hub.zakladki.current_tab == 2)
	await _pad(JOY_BUTTON_B)
	_ok("pad: B zamyka sklep i przywraca ruch w Przystani", not hub.is_visible_in_tree() and przystan.aktywna)
	for sekcja in 5:
		otworz_menu(sekcja)
		await _czekaj(0.5)
		_ok("pad: fokus w sekcji %d" % sekcja, get_viewport().gui_get_focus_owner() != null)
		await _pad(JOY_BUTTON_B)
		_ok("pad: powrót z sekcji %d" % sekcja, not hub.is_visible_in_tree() and przystan.aktywna)
	otworz_menu(2)
	await _czekaj(0.5)
	var karty: Array = hub.ekran.lista.find_children("*", "Button", true, false).filter(func(b): return b.get_meta("klucz", "") == "kup_ember_flask")
	if not karty.is_empty():karty[0].grab_focus()
	await _klatka()
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	_ok("pad: prawo przenosi fokus z towaru na Kup", hub._sz_akcja != null and hub._sz_akcja.has_focus())
	var zloto: int = Profil.d["gold"]
	await _pad(JOY_BUTTON_A)
	await _czekaj_az(func(): return get_viewport().gui_get_focus_owner() != null, 1.0)
	_ok("pad: A kupuje raz za właściwą cenę", int(Profil.d["gold"]) == zloto - int(Dane.p("ember_flask")["price"]))
	fokus = get_viewport().gui_get_focus_owner()
	_ok("pad: po zakupie fokus wraca do aktualnego towaru", fokus != null and fokus.get_meta("klucz", "") == "kup_ember_flask", str(fokus.get_meta("klucz", "")) if fokus != null else "brak fokusu")
	await _os_z_klatka(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _os_z_klatka(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	var oferty: Array = hub.ekran.lista.find_children("*", "Button", true, false).filter(func(b): return str(b.get_meta("klucz", "")).begins_with("sp_") and not b.disabled)
	var cena := 0
	if not oferty.is_empty():
		var ostatni: Button = oferty.back()
		ostatni.grab_focus()
		var klucz: String = ostatni.get_meta("klucz", "")
		var w_sakwie := klucz.begins_with("sp_backpack")
		var indeks: int = int(klucz.trim_prefix("sp_backpack" if w_sakwie else "sp_stash"))
		var przedmiot: Dictionary = Profil.d["loadout"]["backpack"][indeks] if w_sakwie else Profil.d["stash"][indeks]
		cena = Dane.cena_skupu(przedmiot)
	zloto = int(Profil.d["gold"])
	await _pad(JOY_BUTTON_A)
	await _czekaj_az(func(): return get_viewport().gui_get_focus_owner() != null, 1.0)
	_ok("pad: sprzedaż ostatniej pozycji dodaje właściwą kwotę", cena > 0 and int(Profil.d["gold"]) == zloto + cena, "tryb %s, cena %d, złoto %d → %d" % [hub.tryb_kupca, cena, zloto, Profil.d["gold"]])
	fokus = get_viewport().gui_get_focus_owner()
	_ok("pad: po sprzedaży fokus zostaje na istniejącej pozycji", fokus != null and is_instance_valid(fokus) and not fokus.is_queued_for_deletion() and str(fokus.get_meta("klucz", "")).begins_with("sp_"), str(fokus.get_meta("klucz", "")) if fokus != null else "brak fokusu")
	await _zrzut("07_sklep_pad")
	await _pad(JOY_BUTTON_B)
	await _pad(JOY_BUTTON_START)
	_ok("pad: Start otwiera pauzę w Przystani", pauza.visible and get_tree().paused and not pauza.porzuc.visible)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("pad: RB otwiera Opcje pauzy", pauza.zakladki.current_tab == 2)
	pauza._grafika.grab_focus()
	var jakosc := Profil.jakosc()
	await _pad(JOY_BUTTON_A)
	_ok("pad: przycisk jakości reaguje i zapisuje ustawienie", Profil.jakosc() == (jakosc + 1) % Profil.JAKOSCI.size())
	await _pad(JOY_BUTTON_B)
	_ok("pad: B zamyka pauzę i odmraża Przystań", not pauza.visible and not get_tree().paused and przystan.aktywna)
	Profil.d["loadout"]["enhancements"] = [Profil.nowy_przedmiot("ulepszenie_ruch_epic")]
	Profil.d["loadout"]["reliquary"] = [Profil.nowy_przedmiot("ulepszenie_ochrona_rare")]
	Profil.d["stronghold"]["alchemist"] = 1
	var xp_przed: float = _suma_pd("melee")
	var kontrakty_przed := JSON.stringify(Profil.d["kontrakty"])
	var skrytka_przed := JSON.stringify(Profil.d["stash"])
	zloto = int(Profil.d["gold"])
	rozpocznij_rajd("czarnobor", "PORZUCENIE")
	await _czekaj(0.4)
	for en in rajd.wrogowie:en.uspiony = true
	rajd.xp("melee", 60.0)
	rajd.zabici = 9
	rajd.gracz.rynsztunek["backpack"].append(Profil.nowy_przedmiot("golden_idol"))
	await _pad(JOY_BUTTON_START)
	_ok("powrót: opcja porzucenia dostępna tylko w rajdzie", pauza.visible and pauza.porzuc.visible)
	pauza.porzuc.grab_focus()
	await _pad(JOY_BUTTON_A)
	await _czekaj_az(func(): return pauza.dialog_porzuconego_rajdu.visible and pauza.dialog_porzuconego_rajdu.get_cancel_button().has_focus(), 1.0)
	_ok("powrót: A wyświetla potwierdzenie z bezpiecznym fokusem", pauza.dialog_porzuconego_rajdu.visible and pauza.dialog_porzuconego_rajdu.get_cancel_button().has_focus(), "widoczny %s, anuluj ma fokus %s" % [pauza.dialog_porzuconego_rajdu.visible, pauza.dialog_porzuconego_rajdu.get_cancel_button().has_focus()])
	await _zrzut("08_porzucenie_potwierdzenie")
	await _pad(JOY_BUTTON_B)
	_ok("powrót: B anuluje, wyprawa nie jest utracona", not pauza.dialog_porzuconego_rajdu.visible and rajd != null and not rajd.zakonczony)
	pauza.porzuc.grab_focus()
	await _pad(JOY_BUTTON_A)
	await _czekaj_az(func(): return pauza.dialog_porzuconego_rajdu.visible and pauza.dialog_porzuconego_rajdu.get_cancel_button().has_focus(), 1.0)
	await _klatka()
	await _klatka()
	pauza.dialog_porzuconego_rajdu.get_ok_button().grab_focus()
	await _klatka()
	await _pad(JOY_BUTTON_A)
	await _czekaj(0.3)
	_ok("powrót: zatwierdzenie wraca bezpośrednio do Przystani", rajd == null and przystan != null and przystan.aktywna and not get_tree().paused)
	var l: Dictionary = Profil.d["loadout"]
	_ok("powrót: niesiony ekwipunek i dodatki utracone", l["weapon"] == null and l["shield"] == null and l["bow"] == null and l["backpack"].is_empty() and l["enhancements"].is_empty())
	_ok("powrót: Relikwiarz bezpieczny", l["reliquary"].size() == 1 and l["reliquary"][0]["id"] == "ulepszenie_ochrona_rare")
	_ok("powrót: zero doświadczenia i postępu kontraktów", is_equal_approx(_suma_pd("melee"), xp_przed) and JSON.stringify(Profil.d["kontrakty"]) == kontrakty_przed)
	_ok("powrót: bez złota, łupu i darmowej flaszki", int(Profil.d["gold"]) == zloto and JSON.stringify(Profil.d["stash"]) == skrytka_przed)
	Profil.wczytaj()
	_ok("powrót: utrata rajdu została zapisana", Profil.d["loadout"]["weapon"] == null and Profil.d["loadout"]["enhancements"].is_empty())
	print("WYNIK (pad i powrót): ", "OK" if not _wyniki.has(false) else "BŁĄD", " (", _wyniki.count(true), "/", _wyniki.size(), ")")
	get_tree().quit(0 if not _wyniki.has(false) else 1)


func _os_z_klatka(os: JoyAxis, wartosc: float) -> void:
	_os(os, wartosc)
	await _klatka()
	await _klatka()
