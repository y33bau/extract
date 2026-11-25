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
	tlo = ColorRect.new()
	tlo.color = Color(0, 0, 0, 0.72)
	tlo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlo.theme = Ui.motyw()
	add_child(tlo)
	var pan := Ui.panel()
	pan.custom_minimum_size = Vector2(980, 560)
	pan.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	pan.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pan.grow_vertical = Control.GROW_DIRECTION_BOTH
	tlo.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pan.add_child(v)
	var naglowek := HBoxContainer.new()
	var t := Ui.etykieta("SAKWA I ŁUPY", 18, Ui.ZLOTO)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	naglowek.add_child(t)
	naglowek.add_child(Ui.etykieta("Klik/A bierze • Shift/Y → Relikwiarz • PPM/X wyrzuca • Tab/B zamyka", 12, Ui.SZARY))
	var zamknij := Button.new()
	zamknij.text = "Zamknij"
	zamknij.pressed.connect(zamknij_okno)
	naglowek.add_child(zamknij)
	v.add_child(naglowek)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var lewa := VBoxContainer.new()
	lewa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lewa.size_flags_stretch_ratio = 1.3
	h.add_child(lewa)
	rynsztunek_txt = Ui.etykieta("", 13)
	lewa.add_child(rynsztunek_txt)
	lewa.add_child(Ui.etykieta("🔒 RELIKWIARZ (chroniony po śmierci)", 13, Ui.ZLOTO))
	siatka_rel = GridContainer.new()
	siatka_rel.columns = 5
	lewa.add_child(siatka_rel)
	lewa.add_child(Ui.etykieta("🎒 SAKWA", 13, Ui.SZARY))
	siatka_sakwy = GridContainer.new()
	siatka_sakwy.columns = 4
	lewa.add_child(siatka_sakwy)
	var prawa := VBoxContainer.new()
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(prawa)
	var hp := HBoxContainer.new()
	tytul = Ui.etykieta("", 15, Ui.ZAR)
	tytul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp.add_child(tytul)
	zabierz = Ui.przycisk_akcji("Zabierz wszystko")
	zabierz.pressed.connect(_zabierz_wszystko)
	hp.add_child(zabierz)
	prawa.add_child(hp)
	szukanie = Ui.pasek(Ui.ZAR, 6)
	prawa.add_child(szukanie)
	siatka_lupu = GridContainer.new()
	siatka_lupu.columns = 2
	prawa.add_child(siatka_lupu)
	opis = Ui.etykieta("", 13, Ui.POPIOL)
	opis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opis.custom_minimum_size = Vector2(0, 64)
	v.add_child(opis)


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
		var l2 := Ui.etykieta("Podejdź do skrzyni, sarkofagu lub szczątków i naciśnij [E / A].", 13, Ui.SZARY)
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
				b.text = "❓ Przeszukiwanie…"
				b.custom_minimum_size = Vector2(190, 58)
				b.disabled = true
				siatka_lupu.add_child(b)
	_przywroc_fokus.call_deferred()


func _slot(inst, klucz: String, akcja: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 58)
	b.clip_text = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("klucz", klucz)
	if inst == null:
		b.text = "—"
		b.focus_mode = Control.FOCUS_ALL
		b.modulate = Color(1, 1, 1, 0.5)
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
	var ramka := StyleBoxFlat.new()
	ramka.bg_color = Color("16131a")
	ramka.border_color = Dane.KOLORY_RZADKOSCI.get(d.get("rarity"), Color.GRAY)
	ramka.border_width_left = 4
	ramka.set_corner_radius_all(3)
	ramka.content_margin_left = 8
	b.add_theme_stylebox_override("normal", ramka)
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
