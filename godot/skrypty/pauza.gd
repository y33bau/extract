extends CanvasLayer
## Pauza (Esc / P, pad Start) w rajdzie i w Przystani — wygląd jak pauza NightBrand (instrukcja przebudowy menu, etap 4):
## nieprzezroczyste malowane tło biotopu, tytuł z separatorem, ciężkie zakładki ze znaczkami LB/RB (Q/E),
## Sterowanie w dwóch podzakładkach (Klawiatura i mysz / Kontroler Xbox) ze znaczkami zamiast tekstu.
## Zatrzymuje drzewo gry (get_tree().paused); sama działa zawsze. Pad: LB/RB zakładki, LT/RT podzakładki,
## A wybiera, B lub Start wraca do gry.

signal wznowiono
signal otwarto
signal zresetowano  # usunięto zapis (Opcje → Dane zapisu)

const Ui = preload("res://skrypty/ui.gd")
const ZAKLADKI := ["Sterowanie", "Umiejętności", "Opcje"]
## Malowane tła biotopów (z NightBrand; docelowo własne — docs/PROMPTY_MENU.md)
const TLA := {"catacombs": "rozdzial_5", "czarnobor": "rozdzial_4", "spalona_osada": "rozdzial_1", "outskirts": "rozdzial_1", "crypt": "rozdzial_2", "": "tlo_menu_1"}

var zakladki: TabContainer   # zawartość zakładek (pasek zakładek rysujemy sami)
var wroc: Button
var wyjdz: Button
var podtytul: Label
var dialog_wyjscia: ConfirmationDialog
var dialog_reset: ConfirmationDialog
var dane_zapisu: Button
var tlo: TextureRect
var _grafika: Button
var _dzwiek: Button
var _umiej: VBoxContainer
var _rzad: HBoxContainer
var _znaczek_l: Control
var _znaczek_p: Control
var _ster_klaw: Control
var _ster_pad: Control
var _podzakladki: HBoxContainer
var pad_w_sterowaniu := false
var w_rajdzie := false
var _pad_byl := false


func _init() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _ready() -> void:
	var korzen := Control.new()
	korzen.theme = Ui.motyw()
	korzen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(korzen)
	var czern := ColorRect.new()
	czern.color = Color.BLACK  # nieprzezroczyste: gra pod pauzą nie przebija
	korzen.add_child(czern)
	czern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tlo = TextureRect.new()
	tlo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tlo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tlo.modulate = Color(0.5, 0.42, 0.4)
	tlo.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
	korzen.add_child(tlo)
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	korzen.add_child(Ui.gradient_pionowy())
	korzen.add_child(Ui.winieta())
	var marg := MarginContainer.new()
	korzen.add_child(marg)
	marg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marg.add_theme_constant_override("margin_left", 54)
	marg.add_theme_constant_override("margin_right", 54)
	marg.add_theme_constant_override("margin_top", 14)
	marg.add_theme_constant_override("margin_bottom", 16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	marg.add_child(v)
	var tyt := Ui.naglowek_menu("PAUZA", 44, Color("f0dcb6"), 4)
	tyt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tyt.add_theme_constant_override("outline_size", 6)
	tyt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	v.add_child(tyt)
	var sep := TextureRect.new()
	sep.texture = load("res://zasoby/ui/menu/separator_z_pietnem.webp")
	sep.custom_minimum_size = Vector2(300, 40)
	sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(sep)
	podtytul = Ui.naglowek_menu("", 12, Ui.M_ZAR, 3)
	podtytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(podtytul)
	# rząd zakładek ze znaczkami LB/RB albo Q/E
	var rz := HBoxContainer.new()
	rz.alignment = BoxContainer.ALIGNMENT_CENTER
	rz.add_theme_constant_override("separation", 10)
	rz.custom_minimum_size = Vector2(0, 58)
	v.add_child(rz)
	_znaczek_l = _znaczek("lb", "Q")
	rz.add_child(_znaczek_l)
	_rzad = HBoxContainer.new()
	_rzad.add_theme_constant_override("separation", 8)
	rz.add_child(_rzad)
	_znaczek_p = _znaczek("rb", "E")
	rz.add_child(_znaczek_p)
	var o := Control.new()
	o.custom_minimum_size = Vector2(0, 6)
	v.add_child(o)
	v.add_child(Ui.linia(Ui.M_LINIA))
	var o2 := Control.new()
	o2.custom_minimum_size = Vector2(0, 8)
	v.add_child(o2)
	zakladki = TabContainer.new()
	zakladki.tabs_visible = false
	zakladki.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zakladki.tab_changed.connect(func(_i): Dzwiek.ui(); _odswiez_rzad(); _fokus_w_zakladce())
	v.add_child(zakladki)
	zakladki.add_child(_sterowanie())
	zakladki.add_child(_umiejetnosci())
	zakladki.add_child(_ustawienia())
	v.add_child(Ui.linia(Ui.M_LINIA))
	var dol := HBoxContainer.new()
	dol.alignment = BoxContainer.ALIGNMENT_END
	dol.add_theme_constant_override("separation", 24)
	dol.custom_minimum_size = Vector2(0, 76)
	wyjdz = Ui.przycisk_menu("Wyjdź z gry")
	wyjdz.custom_minimum_size = Vector2(260, 56)
	wyjdz.add_theme_font_size_override("font_size", 18)
	wyjdz.add_theme_color_override("font_color", Ui.M_WYL)  # wygaszone, bez poświaty (jak „Porzuć noc”)
	wyjdz.pressed.connect(func(): dialog_wyjscia.popup_centered())
	dol.add_child(wyjdz)
	wroc = Ui.przycisk_menu("Wróć do gry", true)
	wroc.custom_minimum_size = Vector2(300, 64)
	wroc.pressed.connect(zamknij)
	dol.add_child(wroc)
	v.add_child(dol)
	dialog_wyjscia = ConfirmationDialog.new()
	dialog_wyjscia.title = "Wyjść z gry?"
	dialog_wyjscia.dialog_text = "Postęp Warowni jest zapisany."
	dialog_wyjscia.ok_button_text = "Wyjdź"
	dialog_wyjscia.cancel_button_text = "Zostań"
	dialog_wyjscia.confirmed.connect(func(): get_tree().quit())
	korzen.add_child(dialog_wyjscia)
	dialog_reset = ConfirmationDialog.new()
	dialog_reset.title = "Zniszczyć Kronikę Warowni?"
	dialog_reset.dialog_text = "Wszystkie przedmioty, ulepszenia, złoto i umiejętności zostaną usunięte."
	dialog_reset.ok_button_text = "Tak, usuń zapis"
	dialog_reset.cancel_button_text = "Anuluj"
	dialog_reset.confirmed.connect(func(): Profil.resetuj(); zresetowano.emit(); _odswiez_umiejetnosci())
	korzen.add_child(dialog_reset)
	_odswiez_rzad()


func _process(_dt: float) -> void:
	if visible and Sterowanie.pad_aktywny != _pad_byl:
		_pad_byl = Sterowanie.pad_aktywny
		_odswiez_rzad()


func _znaczek(pad: String, klaw: String) -> Control:
	var c := HBoxContainer.new()
	c.add_child(Ui.ikona_pada(pad, 26.0))
	c.add_child(Ui.klawisz(klaw))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


func _odswiez_rzad() -> void:
	if _rzad == null:
		return
	for c in _rzad.get_children():
		c.queue_free()
	for i in ZAKLADKI.size():
		var b := Ui.zakladka_menu(ZAKLADKI[i], i == zakladki.current_tab)
		b.focus_mode = Control.FOCUS_NONE
		var nr := i
		b.pressed.connect(func(): zakladki.current_tab = nr)
		_rzad.add_child(b)
	var pad: bool = Sterowanie.pad_aktywny
	for z in [_znaczek_l, _znaczek_p]:
		z.get_child(0).visible = pad
		z.get_child(1).visible = not pad


## Sterowanie: dwie podzakładki (Klawiatura i mysz / Kontroler Xbox) z jednej listy `Sterowanie.OPIS`.
func _sterowanie() -> Control:
	var c := VBoxContainer.new()
	c.name = "Sterowanie"
	c.add_theme_constant_override("separation", 10)
	_podzakladki = HBoxContainer.new()
	_podzakladki.alignment = BoxContainer.ALIGNMENT_CENTER
	_podzakladki.add_theme_constant_override("separation", 18)
	c.add_child(_podzakladki)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.focus_mode = Control.FOCUS_ALL
	c.add_child(sc)
	var srodek := CenterContainer.new()
	srodek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(srodek)
	_ster_klaw = _tabela_sterowania(false)
	_ster_pad = _tabela_sterowania(true)
	var obie := VBoxContainer.new()
	obie.add_child(_ster_klaw)
	obie.add_child(_ster_pad)
	srodek.add_child(obie)
	_ustaw_podzakladke(false)
	return c


func _ustaw_podzakladke(pad: bool) -> void:
	pad_w_sterowaniu = pad
	_ster_klaw.visible = not pad
	_ster_pad.visible = pad
	for ch in _podzakladki.get_children():
		ch.queue_free()
	for p in [[false, "Klawiatura i mysz"], [true, "Kontroler Xbox"]]:
		var b := Ui.przycisk_menu(("◆ " if p[0] == pad else "") + str(p[1]))
		b.custom_minimum_size = Vector2(270, 46)
		b.add_theme_font_size_override("font_size", 17)
		b.focus_mode = Control.FOCUS_NONE
		if p[0] == pad:
			b.add_theme_color_override("font_color", Ui.M_ZLOTO2)
		var wart: bool = p[0]
		b.pressed.connect(func(): _ustaw_podzakladke(wart))
		_podzakladki.add_child(b)


func _tabela_sterowania(pad: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	p.custom_minimum_size = Vector2(820, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(Ui.belka_sekcji("Kontroler Xbox" if pad else "Klawiatura i mysz"))
	for w in Sterowanie.OPIS:
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(0, 38)
		var n := Ui.tekst_menu(w[0], 16, Ui.M_TEKST)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(n)
		var prawa := HBoxContainer.new()
		prawa.add_theme_constant_override("separation", 6)
		prawa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if pad:
			for b in w[2]:
				prawa.add_child(Ui.znaczek_pada(str(b)))
		else:
			for czesc in str(w[1]).split("  /  "):
				prawa.add_child(Ui.klawisz(czesc.strip_edges()))
		h.add_child(prawa)
		v.add_child(h)
		v.add_child(Ui.linia())
	return p


func _umiejetnosci() -> Control:
	var sc := ScrollContainer.new()
	sc.name = "Umiejętności"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.focus_mode = Control.FOCUS_ALL
	var srodek := CenterContainer.new()
	srodek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(srodek)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	srodek.add_child(p)
	_umiej = VBoxContainer.new()
	_umiej.custom_minimum_size = Vector2(820, 0)
	_umiej.add_theme_constant_override("separation", 0)
	p.add_child(_umiej)
	return sc


func _odswiez_umiejetnosci() -> void:
	for c in _umiej.get_children():
		c.queue_free()
	_umiej.add_child(Ui.belka_sekcji("Biegłości rycerza"))
	for id in Dane.umiejetnosci:
		var u: Dictionary = Dane.umiejetnosci[id]
		var sk: Dictionary = Profil.d["skills"][id]
		var wym := int(sk["lv"]) * 100
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var gora := HBoxContainer.new()
		var n := Ui.tekst_menu(str(u["name"]), 17, Ui.M_JASNY)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gora.add_child(n)
		gora.add_child(Ui.tekst_menu("poziom %d" % int(sk["lv"]), 17, Ui.M_ZLOTO))
		v.add_child(gora)
		v.add_child(Ui.tekst_menu("%s   (%d / %d PD)" % [u["bonusDesc"], int(sk["xp"]), wym], 13, Ui.M_DRUGI))
		var pas := Ui.pasek(Color("c26a2c"), 6)
		pas.max_value = wym
		pas.value = float(sk["xp"])
		v.add_child(pas)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		m.add_theme_constant_override("margin_left", 6)
		m.add_theme_constant_override("margin_right", 6)
		m.add_child(v)
		_umiej.add_child(m)
		_umiej.add_child(Ui.linia())


func _ustawienia() -> Control:
	var c := CenterContainer.new()
	c.name = "Opcje"
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(520, 0)
	p.add_child(v)
	v.add_child(Ui.belka_sekcji("Grafika i dźwięk"))
	_grafika = Ui.przycisk_menu("")
	_grafika.custom_minimum_size = Vector2(440, 52)
	_grafika.add_theme_font_size_override("font_size", 17)
	_grafika.tooltip_text = "Jakość grafiki rajdu (cienie, odbicia, mgła). Niższa = płynniej. Działa od następnej wyprawy."
	_grafika.pressed.connect(func():
		Profil.ustaw_jakosc((Profil.jakosc() + 1) % Profil.JAKOSCI.size())
		Dzwiek.ui()
		_napisy_ustawien())
	v.add_child(_grafika)
	_dzwiek = Ui.przycisk_menu("")
	_dzwiek.custom_minimum_size = Vector2(440, 52)
	_dzwiek.add_theme_font_size_override("font_size", 17)
	_dzwiek.pressed.connect(func():
		Dzwiek.wyciszony = not Dzwiek.wyciszony
		_napisy_ustawien())
	v.add_child(_dzwiek)
	var uw := Ui.tekst_menu("Zmiana jakości grafiki działa od następnej wyprawy.", 13, Ui.M_DRUGI)
	uw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(uw)
	# Dane zapisu (przeniesione z górnego paska Warowni): tylko w Przystani, zawsze z potwierdzeniem
	v.add_child(Ui.belka_sekcji("Dane zapisu"))
	dane_zapisu = Ui.przycisk_menu("Dane zapisu: usuń Kronikę Warowni")
	dane_zapisu.custom_minimum_size = Vector2(440, 52)
	dane_zapisu.add_theme_font_size_override("font_size", 15)
	dane_zapisu.add_theme_color_override("font_color", Ui.M_OSTRZ)
	dane_zapisu.pressed.connect(func(): dialog_reset.popup_centered())
	v.add_child(dane_zapisu)
	return c


func _napisy_ustawien() -> void:
	_grafika.text = "Grafika: " + str(Profil.JAKOSCI[Profil.jakosc()])
	_dzwiek.text = "Dźwięk: wyłączony" if Dzwiek.wyciszony else "Dźwięk: włączony"


## miejsce: nazwa (podtytuł); kraina: id biotopu do malowanego tła ("" = Przystań).
func otworz(miejsce: String, rajd_trwa: bool, statystyki := "", kraina := "") -> void:
	w_rajdzie = rajd_trwa
	zakladki.current_tab = 0  # pauza zawsze zaczyna od pierwszej zakładki
	podtytul.text = miejsce.to_upper() + ("   ·   " + statystyki.to_upper() if statystyki != "" else "")
	tlo.texture = load("res://zasoby/ui/menu/%s.webp" % TLA.get(kraina, "tlo_menu_1"))
	wyjdz.visible = not rajd_trwa  # w rajdzie nie ma ucieczki z gry (pauza to nie wyjście z wyprawy)
	dane_zapisu.visible = not rajd_trwa  # w trakcie wyprawy nie kasujemy zapisu
	_ustaw_podzakladke(Sterowanie.pad_aktywny)
	_napisy_ustawien()
	_odswiez_umiejetnosci()
	_odswiez_rzad()
	visible = true
	otwarto.emit()
	get_tree().paused = true
	Dzwiek.ui()
	wroc.grab_focus.call_deferred()


func zamknij() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	Dzwiek.ui()
	wznowiono.emit()


func _fokus_w_zakladce() -> void:
	if wroc == null or not visible:
		return  # zakładki zmieniają się już przy budowie, zanim powstanie przycisk
	var c := zakladki.get_current_tab_control()
	for b in c.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus.call_deferred()
			return
	wroc.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if not visible or dialog_wyjscia.visible or dialog_reset.visible:
		return
	if e.is_action_pressed("pauza") or e.is_action_pressed("ui_cancel"):
		zamknij()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("zakladka_lewo"):
		zakladki.current_tab = (zakladki.current_tab + zakladki.get_tab_count() - 1) % zakladki.get_tab_count()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("zakladka_prawo"):
		zakladki.current_tab = (zakladki.current_tab + 1) % zakladki.get_tab_count()
		get_viewport().set_input_as_handled()
	elif zakladki.current_tab == 0 and (e.is_action_pressed("podzakladka_lewo") or e.is_action_pressed("podzakladka_prawo")):
		_ustaw_podzakladke(e.is_action_pressed("podzakladka_prawo"))
		get_viewport().set_input_as_handled()
