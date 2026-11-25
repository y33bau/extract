extends Node
## Korzeń gry: Warownia ⇄ rajd ⇄ ekran wyniku. Tryb testu: godot --path godot -- --test [--zrzuty=/katalog] [--zapis=/plik.json]

const Ui = preload("res://skrypty/ui.gd")
const Hub = preload("res://skrypty/hub.gd")
const Rajd = preload("res://skrypty/rajd.gd")
const Hud = preload("res://skrypty/hud.gd")
const Okno = preload("res://skrypty/okno_lupu.gd")

var hub_warstwa: CanvasLayer
var hub: Hub
var rajd: Rajd
var hud: Hud
var okno: Okno
var wynik: CanvasLayer
var wynik_przycisk: Button
var ostatni_wynik := {}


func _ready() -> void:
	randomize()
	hub_warstwa = CanvasLayer.new()
	add_child(hub_warstwa)
	hub = Hub.new()
	hub.start_rajdu.connect(rozpocznij_rajd)
	hub_warstwa.add_child(hub)
	if "--test" in OS.get_cmdline_user_args():
		_test.call_deferred()


func rozpocznij_rajd(kraina: String, ziarno: String) -> void:
	Dzwiek.ui()
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
	rajd.koniec.connect(_koniec_rajdu)
	hud.pokaz_toast.call_deferred("🔥 Pochodnia zajmuje rękę tarczy: nie parujesz. [F / ↓] rzuć ją przed walką.", "info")


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
	var t := Ui.etykieta("✨ EKSTRAKCJA UDANA" if przezyl else "💀 POLEGŁEŚ W RUINACH", 26, Color("34d399") if przezyl else Color("ef4444"))
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
	for a in s["awanse"]:
		txt += "\n📜 Awans: %s — poziom %d" % [Dane.umiejetnosci[a[0]]["name"], a[1]]
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
	hub_warstwa.visible = true
	hub.visible = true
	hub.zakladki.current_tab = 0
	hub.odswiez()


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


func _ustaw_wroga_przed(en, odl := 1.0) -> void:
	var p = rajd.gracz
	en.w = p.w + Vector2(cos(p.kat), sin(p.kat)) * odl
	en.stan = "walka"


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
	_ok("Warownia widoczna", hub.is_visible_in_tree())
	await _zrzut("1_warownia")
	# przejście zakładek padem (RB)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_ok("RB przełącza zakładkę", hub.zakladki.current_tab == 1)
	await _zrzut("2_ekwipunek")
	hub.zakladki.current_tab = 0
	await _czekaj(0.2)

	rozpocznij_rajd("catacombs", "TEST01")
	await _czekaj(0.5)
	_ok("rajd startuje", rajd != null and rajd.gracz != null)
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
	_ok("ruch lewym drążkiem", p.w.distance_to(start) > 0.5, "%.2f pola" % p.w.distance_to(start))

	# pochodnia w ręce: brak parowania
	var en = rajd.wrogowie[0]
	en.uspiony = false
	en.hp = 9999.0
	en.hp_max = 9999.0
	await _pad(JOY_BUTTON_LEFT_SHOULDER, 0.05)
	_ok("pochodnia w ręce blokuje parowanie", p.okno_parowania == 0.0)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	_ok("krzyżak ↓ rzuca pochodnię", not p.pochodnia_w_rece and rajd.pochodnia_na_ziemi != null)

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
	# LB wciśnięty, a cios wroga spada w oknie parowania (deterministycznie, niezależnie od FPS)
	await _pad(JOY_BUTTON_LEFT_SHOULDER, 0.02)
	en.zamach = 0.01
	await _czekaj(0.1)
	_ok("LB paruje złoty błysk", en.ogluszenie > 0.0 and p.hp == p.hp_max, "ogłuszenie %.2f, HP %d" % [en.ogluszenie, p.hp])
	var hp0: float = en.hp
	await _pad(JOY_BUTTON_X, 0.05)
	await _czekaj(0.2)
	_ok("X: riposta", hp0 - en.hp > 50.0 and en.ogluszenie <= 0.0, "-%d HP" % int(hp0 - en.hp))

	# postura
	var pekla := false
	for i in 12:
		_ustaw_wroga_przed(en, 0.9)
		en.atak_timer = 99.0
		en.zamach = 0.0
		p.stamina = p.stamina_max
		await _pad(JOY_BUTTON_X, 0.04)
		await _czekaj(0.4)
		if en.ogluszenie > 0.0:
			pekla = true
			break
	_ok("ciosy łamią posturę", pekla)
	en.w = Vector2(2.5, 2.5)
	en.uspiony = true

	# skrzynia: A otwiera, przeszukanie, zabierz wszystko, B zamyka
	var sk: Dictionary = rajd.mapa.skrzynie[0]
	p.w = sk["w"] + Vector2(0.6, 0.0)
	if rajd.pelne(p.w.x, p.w.y):
		p.w = sk["w"] + Vector2(0.0, 0.6)
	await _czekaj(0.15)
	var przed: int = p.rynsztunek["backpack"].size()
	await _pad(JOY_BUTTON_A)
	_ok("A otwiera skrzynię", okno.otwarte and rajd.aktywny_pojemnik == sk)
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
	await _pad(JOY_BUTTON_RIGHT_STICK)
	var sakwy := rajd.zwloki.filter(func(z): return z["sakwa"])
	_ok("R3 zrzuca sakwę (pas zostaje)", sakwy.size() == 1 and rajd.sakwa_obciazenie() == 0)
	# podnieś z powrotem
	rajd.otworz(sakwy[0])
	await _czekaj(0.3)
	okno._zabierz_wszystko()
	okno.zamknij_okno()
	_ok("sakwa podniesiona", rajd.sakwa_obciazenie() > 0)

	# ekstrakcja
	p.hp = 9999.0
	p.hp_max = 9999.0
	p.w = rajd.mapa.ekstrakcje[0]["w"]
	await _czekaj_az(func(): return wynik != null, 30.0)
	_ok("ekstrakcja kończy rajd", wynik != null and ostatni_wynik.get("przezyl", false))
	await _zrzut("5_wynik")
	await _czekaj(0.2)
	await _pad(JOY_BUTTON_A)
	await _czekaj(0.3)
	_ok("A wraca do Warowni", hub.is_visible_in_tree() and rajd == null)
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
	await _czekaj_az(func(): return wynik != null, 20.0)
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
