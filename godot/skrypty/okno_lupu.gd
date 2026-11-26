extends CanvasLayer
## Okno „Sakwa i łupy” w rajdzie. Mysz: klik bierze, Shift+klik do Relikwiarza, PPM wyrzuca.
## Pad: A bierze/używa, Y do Relikwiarza, X wyrzuca, B zamyka.

const Ui = preload("res://skrypty/ui.gd")

var rajd
var tlo: ColorRect
var rynsztunek_txt: Label
var siatka_rel: GridContainer
var siatka_sakwy: GridContainer
var tytul: Label
var szukanie: ProgressBar
var siatka_lupu: GridContainer
var zabierz: Button
var opis: Label
var otwarte := false
var _fokus_klucz := ""
var _blokada := 0.0


func _init() -> void:
	layer = 20
	visible = false


func _ready() -> void:
	# wygląd jak menu NightBrand (instrukcja przebudowy menu, etap 4): tytuł z separatorem, dwa panele w ramie
	# (lewy: rynsztunek, Relikwiarz, Sakwa; prawy: zawartość skrzyni), opis pod panelami, stopka ze znaczkami
	tlo = ColorRect.new()
	tlo.color = Color(0.02, 0.015, 0.02, 0.96)  # HUD i świat nie przebijają przez okno łupu (było 0,86)
	tlo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlo.theme = Ui.motyw()
	add_child(tlo)
	tlo.add_child(Ui.winieta())
	var kol := VBoxContainer.new()
	kol.add_theme_constant_override("separation", 6)
	kol.custom_minimum_size = Vector2(1060, 0)
	kol.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	kol.grow_horizontal = Control.GROW_DIRECTION_BOTH
	kol.grow_vertical = Control.GROW_DIRECTION_BOTH
	tlo.add_child(kol)
	var t := Ui.naglowek_menu("SAKWA I ŁUPY", 30, Color("f0dcb6"), 3)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kol.add_child(t)
	var sep := TextureRect.new()
	sep.texture = load("res://zasoby/ui/menu/separator_z_pietnem.webp")
	sep.custom_minimum_size = Vector2(260, 34)
	sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kol.add_child(sep)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	h.custom_minimum_size = Vector2(0, 430)
	kol.add_child(h)
	var pl := PanelContainer.new()
	pl.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.size_flags_stretch_ratio = 1.2
	h.add_child(pl)
	var lewa := VBoxContainer.new()
	lewa.add_theme_constant_override("separation", 6)
	pl.add_child(lewa)
	lewa.add_child(Ui.belka_sekcji("Rynsztunek"))
	rynsztunek_txt = Ui.tekst_menu("", 14, Ui.M_TEKST)
	lewa.add_child(rynsztunek_txt)
	lewa.add_child(Ui.belka_sekcji("Relikwiarz  (przeżywa śmierć)"))
	siatka_rel = GridContainer.new()
	siatka_rel.columns = 4
	lewa.add_child(siatka_rel)
	lewa.add_child(Ui.belka_sekcji("Sakwa"))
	siatka_sakwy = GridContainer.new()
	siatka_sakwy.columns = 4
	lewa.add_child(siatka_sakwy)
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(pp)
	var prawa := VBoxContainer.new()
	prawa.add_theme_constant_override("separation", 8)
	pp.add_child(prawa)
	var bel := PanelContainer.new()
	bel.add_theme_stylebox_override("panel", Ui._flat(Ui.M_BELKA, Ui.M_BELKA_RAMA, 1, [14, 5, 14, 5]))
	tytul = Ui.naglowek_menu("", 17, Ui.M_JASNY)
	bel.add_child(tytul)
	prawa.add_child(bel)
	szukanie = Ui.pasek(Ui.ZAR, 6)
	prawa.add_child(szukanie)
	siatka_lupu = GridContainer.new()
	siatka_lupu.columns = 2
	prawa.add_child(siatka_lupu)
	var wyp := Control.new()
	wyp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prawa.add_child(wyp)
	zabierz = Ui.przycisk_menu("Zabierz wszystko", true)
	zabierz.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	zabierz.pressed.connect(_zabierz_wszystko)
	prawa.add_child(zabierz)
	# opis zaznaczonego przedmiotu: pasek pod panelami
	var po := PanelContainer.new()
	po.add_theme_stylebox_override("panel", Ui._flat(Color(0.07, 0.066, 0.075, 0.94), Ui.M_LINIA, 1, [16, 8, 16, 8]))
	opis = Ui.tekst_menu("", 14, Ui.M_TEKST)
	opis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opis.custom_minimum_size = Vector2(0, 58)
	po.add_child(opis)
	kol.add_child(po)
	# stopka: znaczki pada albo klawisze zamiast zdania z instrukcją
	_stopka = HBoxContainer.new()
	_stopka.alignment = BoxContainer.ALIGNMENT_CENTER
	_stopka.add_theme_constant_override("separation", 30)
	_stopka.custom_minimum_size = Vector2(0, 40)
	kol.add_child(_stopka)
	var zamknij := Ui.przycisk_menu("Zamknij")
	zamknij.focus_mode = Control.FOCUS_NONE
	zamknij.pressed.connect(zamknij_okno)
	_stopka_zamknij = zamknij
	_odswiez_stopke()


var _stopka: HBoxContainer
var _stopka_zamknij: Button
var _pad_byl := false


func _odswiez_stopke() -> void:
	if _stopka_zamknij.get_parent():
		_stopka_zamknij.get_parent().remove_child(_stopka_zamknij)
	for c in _stopka.get_children():
		c.queue_free()
	var pad: bool = Sterowanie.pad_aktywny
	_pad_byl = pad
	for w in [["a", "Klik", "Weź / użyj"], ["y", "Shift + klik", "Do Relikwiarza"], ["x", "PPM", "Wyrzuć"], ["b", "Tab", "Zamknij"]]:
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 8)
		hh.add_child(Ui.ikona_pada(w[0], 24.0) if pad else Ui.klawisz(w[1]))
		var l := Ui.tekst_menu(w[2], 15, Ui.M_TEKST)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hh.add_child(l)
		_stopka.add_child(hh)
	_stopka.add_child(_stopka_zamknij)


func otworz(_pojemnik) -> void:
	otwarte = true
	visible = true
	_blokada = 0.25
	_fokus_klucz = ""
	odswiez()


func zamknij_okno() -> void:
	if not otwarte:
		return
	otwarte = false
	visible = false
	rajd.zamknij_okno()


func _unhandled_input(e: InputEvent) -> void:
	if not otwarte:
		return
	if e.is_action_pressed("ui_cancel") or e.is_action_pressed("sakwa"):
		get_viewport().set_input_as_handled()
		zamknij_okno()


func _process(_dt: float) -> void:
	_blokada = maxf(0.0, _blokada - _dt)
	if otwarte and Sterowanie.pad_aktywny != _pad_byl:
		_odswiez_stopke()
	if otwarte and rajd.aktywny_pojemnik != null:
		szukanie.value = rajd.postep_szukania * 100.0


func odswiez() -> void:
	if not otwarte:
		return
	var l: Dictionary = rajd.gracz.rynsztunek
	var nazwa := func(k): return Dane.p(l[k]["id"])["name"] if l[k] else "brak"
	rynsztunek_txt.text = "Broń: %s   •   Tarcza: %s\nŁuk: %s   •   Pancerz: %s" % [nazwa.call("weapon"), nazwa.call("shield"), nazwa.call("bow"), nazwa.call("armor")]
	for s in [siatka_rel, siatka_sakwy, siatka_lupu]:
		for c in s.get_children():
			c.queue_free()
	var maks_rel := Profil.max_relikwiarz()
	for i in maks_rel:
		siatka_rel.add_child(_slot(l["reliquary"][i] if i < l["reliquary"].size() else null, "rel%d" % i, _klik_rel.bind(i)))
	for i in Profil.SAKWA_MAX:
		siatka_sakwy.add_child(_slot(l["backpack"][i] if i < l["backpack"].size() else null, "bp%d" % i, _klik_sakwa.bind(i)))
	var poj = rajd.aktywny_pojemnik
	if poj == null:
		tytul.text = "BRAK POJEMNIKA"
		szukanie.visible = false
		zabierz.visible = false
		var l2 := Ui.etykieta("Podejdź do skrzyni, sarkofagu lub szczątków i naciśnij E / Y.", 13, Ui.SZARY)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.custom_minimum_size = Vector2(360, 0)
		siatka_lupu.add_child(l2)
	else:
		tytul.text = str(poj["nazwa"]).to_upper()
		var ukryte := false
		for wpis in poj["przedmioty"]:
			if not wpis["odkryty"]:
				ukryte = true
		szukanie.visible = ukryte
		zabierz.visible = not ukryte and not poj["przedmioty"].is_empty()
		if poj["przedmioty"].is_empty():
			siatka_lupu.add_child(Ui.etykieta("Pusto.", 13, Ui.SZARY))
		for i in poj["przedmioty"].size():
			var wpis: Dictionary = poj["przedmioty"][i]
			if wpis["odkryty"]:
				siatka_lupu.add_child(_slot(wpis["przedmiot"], "lup%d" % i, _klik_lup.bind(i)))
			else:
				var b := Button.new()
				b.text = "Przeszukiwanie…"
				b.custom_minimum_size = Vector2(190, 54)
				b.disabled = true
				siatka_lupu.add_child(b)
	_przywroc_fokus.call_deferred()


func _slot(inst, klucz: String, akcja: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(128, 54)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 12)  # długie nazwy („Tonik Wytrzymałości”) bez ucięcia
	b.add_theme_font_override("font", Ui.czcionka_tekstu())  # szeryf z małymi literami: węższy niż kapitaliki
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("klucz", klucz)
	if inst == null:
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_stylebox_override("normal", Ui.styl_slotu(Color.GRAY))
		b.add_theme_stylebox_override("focus", Ui.styl_slotu(Color.GRAY, true))
		b.add_theme_stylebox_override("hover", Ui.styl_slotu(Color.GRAY, true))
		b.modulate = Color(1, 1, 1, 0.32)  # puste miejsca bledsze niż pełne
		b.focus_entered.connect(func(): opis.text = ""; _fokus_klucz = klucz)
		return b
	var d := Dane.p(inst["id"])
	b.icon = Dane.ikona(inst["id"])
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 32)
	var dop := ""
	if d.get("type") == "arrow":
		dop = " x%d" % int(inst["qty"])
	b.text = str(d["name"]) + dop
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(d.get("rarity"), Color.GRAY)
	for st in ["normal", "hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(st, Ui.styl_slotu(rz, st != "normal"))
	b.add_theme_color_override("font_color", rz.lightened(0.35))
	var tekst_opisu := "%s — %s\n%s\n%s" % [d["name"], Dane.NAZWY_TYPOW.get(d.get("type"), ""), d.get("desc", ""), Dane.opis_statystyk(inst)]
	b.tooltip_text = tekst_opisu
	b.focus_entered.connect(func(): opis.text = tekst_opisu; _fokus_klucz = klucz)
	b.mouse_entered.connect(func(): opis.text = tekst_opisu)
	b.gui_input.connect(func(e: InputEvent): _wejscie_slotu(e, akcja))
	b.pressed.connect(func(): if _blokada <= 0.0: akcja.call("glowna"))
	return b


func _wejscie_slotu(e: InputEvent, akcja: Callable) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_RIGHT:
			akcja.call("wyrzuc")
			get_viewport().set_input_as_handled()
		elif e.button_index == MOUSE_BUTTON_LEFT and e.shift_pressed:
			akcja.call("relikwiarz")
			get_viewport().set_input_as_handled()
	elif e.is_action_pressed("okno_relikwiarz"):
		akcja.call("relikwiarz")
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("okno_wyrzuc"):
		akcja.call("wyrzuc")
		get_viewport().set_input_as_handled()


func _przywroc_fokus() -> void:
	var kandydaci: Array = []
	for s in [siatka_lupu, siatka_sakwy, siatka_rel]:
		for c in s.get_children():
			if c is Button and not c.disabled and not c.is_queued_for_deletion():
				kandydaci.append(c)
	for c in kandydaci:
		if _fokus_klucz != "" and c.get_meta("klucz", "") == _fokus_klucz:
			c.grab_focus()
			return
	if zabierz.visible:
		zabierz.grab_focus()
	elif not kandydaci.is_empty():
		kandydaci[0].grab_focus()


func _zmiana() -> void:
	Dzwiek.ui()
	rajd.zmiana_ekwipunku.emit()
	odswiez()


func _klik_rel(tryb: String, i: int) -> void:
	var l: Dictionary = rajd.gracz.rynsztunek
	if i >= l["reliquary"].size() or tryb == "wyrzuc":
		return
	if l["backpack"].size() >= Profil.SAKWA_MAX:
		rajd.toast.emit("Sakwa jest pełna!", "warn")
		return
	l["backpack"].append(l["reliquary"].pop_at(i))
	_zmiana()


func _klik_sakwa(tryb: String, i: int) -> void:
	var l: Dictionary = rajd.gracz.rynsztunek
	if i >= l["backpack"].size():
		return
	var it: Dictionary = l["backpack"][i]
	var d := Dane.p(it["id"])
	match tryb:
		"wyrzuc":
			l["backpack"].remove_at(i)
		"relikwiarz":
			if l["reliquary"].size() >= Profil.max_relikwiarz():
				rajd.toast.emit("Relikwiarz jest pełny!", "warn")
				return
			l["reliquary"].append(l["backpack"].pop_at(i))
		_:
			if d.get("type") == "elixir":
				zamknij_okno()
				rajd.uzyj_mikstury(d["elixKind"])
				return
			elif d.get("type") in ["weapon", "shield", "bow", "armor"]:
				var stary = l[d["type"]]
				l[d["type"]] = l["backpack"].pop_at(i)
				if stary:
					l["backpack"].append(stary)
			else:
				return
	_zmiana()


func _klik_lup(tryb: String, i: int) -> void:
	var poj = rajd.aktywny_pojemnik
	if poj == null or i >= poj["przedmioty"].size() or tryb == "wyrzuc":
		return
	var wpis: Dictionary = poj["przedmioty"][i]
	if not wpis["odkryty"]:
		return
	var l: Dictionary = rajd.gracz.rynsztunek
	var it: Dictionary = wpis["przedmiot"]
	if tryb == "relikwiarz":
		if l["reliquary"].size() >= Profil.max_relikwiarz():
			rajd.toast.emit("Relikwiarz jest pełny!", "warn")
			return
		l["reliquary"].append(it)
	else:
		if it["id"] == "iron_arrows":
			for b in l["backpack"]:
				if b["id"] == "iron_arrows" and int(b["qty"]) < 32:
					b["qty"] = int(b["qty"]) + int(it["qty"])
					poj["przedmioty"].remove_at(i)
					Dzwiek.lup()
					_zmiana()
					return
		if l["backpack"].size() >= Profil.SAKWA_MAX:
			rajd.toast.emit("Sakwa jest pełna (12/12)!", "warn")
			return
		l["backpack"].append(it)
	poj["przedmioty"].remove_at(i)
	Dzwiek.lup()
	rajd.xp("scavenger", 10)
	_zmiana()


func _zabierz_wszystko() -> void:
	if _blokada > 0.0:
		return
	var poj = rajd.aktywny_pojemnik
	if poj == null:
		return
	var proby: int = poj["przedmioty"].size()
	while proby > 0 and not poj["przedmioty"].is_empty() and rajd.gracz.rynsztunek["backpack"].size() < Profil.SAKWA_MAX:
		_klik_lup("glowna", 0)
		proby -= 1
