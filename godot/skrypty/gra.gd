extends Node
## Korzeń gry: Warownia ⇄ rajd ⇄ ekran wyniku. Tryb testu: godot --path godot -- --test [--zrzuty=/katalog] [--zapis=/plik.json]

const Mapgen = preload("res://skrypty/mapgen.gd")
const MapgenLas = preload("res://skrypty/mapgen_las.gd")
const Ui = preload("res://skrypty/ui.gd")
const Hub = preload("res://skrypty/hub.gd")
const Rajd = preload("res://skrypty/rajd.gd")
const Hud = preload("res://skrypty/hud.gd")
const Okno = preload("res://skrypty/okno_lupu.gd")
const Przystan = preload("res://skrypty/przystan.gd")
const Pauza = preload("res://skrypty/pauza.gd")

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
	_przystan()
	if "--test" in OS.get_cmdline_user_args():
		_test.call_deferred()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--podglad="):
			_podglad.call_deferred(a.substr(10))
		if a.begins_with("--podglad-przystan="):
			_podglad_przystani.call_deferred(a.substr(19))
		if a.begins_with("--podglad-walki="):
			_podglad_walki.call_deferred(a.substr(16))
		if a.begins_with("--podglad-ruchu="):
			_podglad_ruchu.call_deferred(a.substr(16))
		if a.begins_with("--podglad-lasu="):
			_podglad_lasu.call_deferred(a.substr(15))


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


func moze_pauzowac() -> bool:
	if rajd != null:
		return not rajd.zakonczony and not rajd.okno_otwarte
	return przystan != null and przystan.aktywna and not hub.is_visible_in_tree()


func otworz_pauze() -> void:
	if rajd != null:
		pauza.otworz(str(rajd.kraina["name"]), true)
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
	wynik = CanvasLayer.new()
	wynik.layer = 30
	add_child(wynik)
	var tlo := ColorRect.new()
	tlo.color = Color(0, 0, 0, 0.82)
	tlo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlo.theme = Ui.motyw()
	wynik.add_child(tlo)
	var p := Ui.panel()
	p.custom_minimum_size = Vector2(520, 0)
	tlo.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var t := Ui.etykieta("Ekstrakcja udana" if przezyl else "Poległeś w ruinach", 26, Color("34d399") if przezyl else Color("ef4444"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var pw := Ui.etykieta(powod, 14)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pw)
	var m := int(s["czas"] / 60.0)
	var sek := int(s["czas"]) % 60
	var txt := "Kraina: %s (%s)\nCzas wyprawy: %d:%02d\nPokonani wrogowie: %d\nUdane parowania: %d\nRynsztunek: %s\nDoświadczenie: %s" % [
		s["kraina"], s["ziarno"], m, sek, s["zabici"], s["parowania"],
		"zabezpieczony w Warowni" if przezyl else "utracony (Relikwiarz ocalał)",
		"zaliczone w całości" if przezyl else "zaliczona połowa"]
	if przezyl:
		txt += "\nWartość łupu z sakwy: %d zł" % s["wartosc"]
	for kt in s.get("kontrakty", []):
		txt += "\nKontrakt Chojraka wykonany: %s" % kt
	for a in s["awanse"]:
		txt += "\nAwans: %s — poziom %d" % [Dane.umiejetnosci[a[0]]["name"], a[1]]
	v.add_child(Ui.etykieta(txt, 14))
	wynik_przycisk = Ui.przycisk_akcji("POWRÓT DO WAROWNI")
	wynik_przycisk.custom_minimum_size = Vector2(0, 48)
	wynik_przycisk.pressed.connect(powrot_do_warowni)
	v.add_child(wynik_przycisk)
	wynik_przycisk.grab_focus.call_deferred()


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
	rajd.atak_wrecz()
	_ok("trafienie: zatrzymanie klatki i kopnięcie obrazu", rajd.hitstop >= 0.05 and rajd.kop_kamery.length() > 1.0,
		"hitstop %.3f s, kop %.1f px" % [rajd.hitstop, rajd.kop_kamery.length()])
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
	await _zrzut("8b_pasek_bossa")
	boss.stan = "patrol"
	boss.w = boss_w
	if nowy_boss:
		rajd.wrogowie.erase(boss)
		boss.queue_free()
	en.hp = en.hp_max


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
	await _zrzut(zrzut)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("%s: RB przełącza zakładkę pauzy" % gdzie, pauza.zakladki.current_tab == 1)
	await _zrzut(zrzut + "_umiejetnosci")
	pauza.zakladki.current_tab = 0
	await _pad(JOY_BUTTON_B)
	await _czekaj_az(func(): return not pauza.visible, 2.0)
	_ok("%s: B wraca do gry" % gdzie, not pauza.visible and not get_tree().paused)
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


## Pilot Czarnoboru (generator lasu, jeszcze bez rajdu): ziarno, osiągalność, szerokość przejść, wyjścia w głębi,
## ślepe odnogi z łupem. Pięć ziaren.
func _test_lasu() -> void:
	var zle: Array = []
	for z in ["LAS_A", "LAS_B", "LAS_C", "LAS_D", "LAS_E"]:
		var m = MapgenLas.new()
		m.generuj({"id": "czarnobor"}, z, 1)
		var m2 = MapgenLas.new()
		m2.generuj({"id": "czarnobor"}, z, 1)
		if m2.siatka != m.siatka or m2.skrzynie.size() != m.skrzynie.size() or m2.spawny.size() != m.spawny.size() or m2.start != m.start:
			zle.append(z + ": inne ziarno-wynik")
		var d: PackedInt32Array = m._odleglosci(Vector2i(int(m.start.x), int(m.start.y)))
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
						if MapgenLas.blokuje_ruch(m.kafel(q.x + dx, q.y + dy)) and m.kafel(q.x + dx, q.y + dy) != MapgenLas.T.DRZEWO and m.kafel(q.x + dx, q.y + dy) != MapgenLas.T.GLAZ:
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
			if sc["szer"] < 4.0 or sc["szer"] > 6.0:
				zle.append(z + ": ścieżka %.1f m" % sc["szer"])
		if m.ekstrakcje.size() != 3:
			zle.append(z + ": wyjść %d" % m.ekstrakcje.size())
		if odnogi < 2:
			zle.append(z + ": ślepych odnóg %d" % odnogi)
		if m.polany.size() < 8 or m.skrzynie.size() < 10:
			zle.append(z + ": polan %d, łupów %d" % [m.polany.size(), m.skrzynie.size()])
	_ok("las (pilot): ziarno, osiągalność, przejścia ≥3 m, 3 wyjścia w głębi, ślepe odnogi", zle.is_empty(), ", ".join(zle.slice(0, 4)))


## Oprawa mapy: materiały krainy z tekstur NightBrand, maska murów, pochodnie nie wiszą w powietrzu.
## Duże mapy (wersja 2 generatora): rozmiar, osiągalność, rodzaje komnat, ziarno, wrogowie, pościg po korytarzach.
func _test_duzej_mapy() -> void:
	var m = rajd.mapa
	_ok("duża mapa: 96×96 pól", Mapgen.ROZMIAR == 96 and m.siatka.size() == 96 * 96)
	var d: PackedInt32Array = m._odleglosci(Vector2i(int(m.start.x), int(m.start.y)))
	var eks_ok: bool = m.ekstrakcje.size() >= 3
	for e in m.ekstrakcje:
		if d[m.idx(int(e["w"].x), int(e["w"].y))] < 0:
			eks_ok = false
	_ok("duża mapa: 3+ kręgi ekstrakcji osiągalne od startu", eks_ok, "%d kręgów" % m.ekstrakcje.size())
	var sk_ok := true
	for sk in m.skrzynie:
		if d[m.idx(sk["tx"], sk["ty"])] < 0:
			sk_ok = false
	_ok("duża mapa: każda skrzynia osiągalna", sk_ok and m.skrzynie.size() >= 30, "%d skrzyń" % m.skrzynie.size())
	var rodzaje := {}
	for k in m.komnaty:
		rodzaje[k["typ"]] = true
	_ok("duża mapa: różne rodzaje komnat", rodzaje.size() >= 6 and m.komnaty.size() >= 25, "%d komnat: %s" % [m.komnaty.size(), ", ".join(rodzaje.keys())])
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
	for i in 6:
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
	print("-- test gry Godot (symulowany pad)")
	await _czekaj(0.4)
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
	# przejście zakładek padem (RB)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("RB przełącza zakładkę", hub.zakladki.current_tab == 3)
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
	await _test_pauzy("Przystań", "9a_pauza_przystan")
	await _pad(JOY_BUTTON_BACK)
	await _czekaj_az(func(): return hub.is_visible_in_tree(), 5.0)
	_ok("Back otwiera całe menu Warowni", hub.is_visible_in_tree())
	await _test_kramu()
	hub.zakladki.current_tab = 0
	await _czekaj(0.2)
	# ustawienie jakości grafiki: przycisk przełącza i zapamiętuje
	var j0: int = Profil.jakosc()
	hub.przycisk_grafiki.pressed.emit()
	var j1: int = Profil.jakosc()
	_ok("przycisk Grafika zmienia i zapamiętuje jakość", j1 == (j0 + 1) % 4 and hub.przycisk_grafiki.text.ends_with(Profil.JAKOSCI[j1]), "%s → %s" % [Profil.JAKOSCI[j0], Profil.JAKOSCI[j1]])
	Profil.ustaw_jakosc(j0)

	# kontrakt Chojraka do sprawdzenia przy ekstrakcji
	Profil.d["kontrakty"] = [{"typ": "ekstrakcja", "kraina": "catacombs", "cel": 1, "postep": 0, "nagroda": 150}]
	var zloto_przed_rajdem: int = int(Profil.d["gold"])
	hub.zakladki.current_tab = 0
	hub.odswiez()
	_ok("Wyprawa: lista kontraktów Chojraka", hub.t_wyprawa.get_children().any(func(c): return c is Label and c.text.contains("KONTRAKTY")))
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
		_ok("3D: zapowiedź ciosu wroga (zamach + rozbłysk)", ap3 != null and ap3.current_animation == "zamach" and l3.light_energy > 0.5,
			"%s, %.1f" % [ap3.current_animation if ap3 else "-", l3.light_energy if l3 else 0.0])
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

	var zle := _wyniki.count(false)
	print("\nWYNIK (godot): ", "OK" if zle == 0 else "BŁĘDY: %d" % zle, "  (%d/%d)" % [_wyniki.size() - zle, _wyniki.size()])
	get_tree().quit(0 if zle == 0 else 1)
