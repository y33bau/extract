extends Control
## Szablon ekranu menu na wzór NightBrand (instrukcja przebudowy menu 26.11, §2; wzór: Kaplica NightBrand).
## Klocki: malowane tło na cały ekran, nagłówek z ornamentem, rząd ciężkich zakładek ze znaczkami LB/RB (Q/E),
## dwa panele w ramie (lista po lewej 44%, szczegóły z ilustracją po prawej 56%), stopka ze znaczkami klawiszy.
## Ekran sam niczego nie liczy: treść list i szczegółów wkłada właściciel (np. hub.gd → Kram Margi).

signal wroc_wcisniety
signal zakladka_wybrana(indeks: int)

const Ui = preload("res://skrypty/ui.gd")

var tlo: TextureRect
var tytul: Label
var podtytul: Label
var przycisk_wroc: Button
var licznik: Label
var rzad_zakladek: HBoxContainer
var lista: VBoxContainer          # wiersze i belki sekcji (przewijane)
var przewijanie_listy: ScrollContainer
var stopka_listy: Label           # mała linia pod listą (np. „Kuźnia poz. 1”)
var szczegoly: VBoxContainer      # treść panelu szczegółów (pod ilustracją)
var przewijanie_szczegolow: ScrollContainer
var ilustracja: TextureRect
var duza_ikona: TextureRect
var stopka: HBoxContainer
var zakladki: Array = []          # Button
var aktywna := 0
var _znaczek_l: Control
var _znaczek_p: Control
var _stopka_wpisy: Array = []     # [[pad, klawisz, podpis]]
var _pad_byl := false


func _ready() -> void:
	theme = Ui.motyw()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 1. Tło: malowana scena + czarne półcienie u góry i u dołu + winieta (świat 3D nie prześwituje)
	var czern := ColorRect.new()
	czern.color = Color.BLACK
	add_child(czern)
	czern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tlo = TextureRect.new()
	tlo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tlo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tlo.modulate = Color(0.55, 0.45, 0.42)
	tlo.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
	add_child(tlo)
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_gradient_pionowy())
	add_child(_winieta())
	# 2–6: układ
	var marg := MarginContainer.new()
	add_child(marg)
	marg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marg.add_theme_constant_override("margin_left", 54)
	marg.add_theme_constant_override("margin_right", 54)
	marg.add_theme_constant_override("margin_top", 22)
	marg.add_theme_constant_override("margin_bottom", 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	marg.add_child(v)
	# pas górny: Wróć | tytuł z ornamentem i podtytułem | licznik
	var gora := Control.new()
	gora.custom_minimum_size = Vector2(0, 106)
	v.add_child(gora)
	var srodek := VBoxContainer.new()
	srodek.alignment = BoxContainer.ALIGNMENT_BEGIN
	srodek.add_theme_constant_override("separation", -6)
	gora.add_child(srodek)
	srodek.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	srodek.grow_horizontal = Control.GROW_DIRECTION_BOTH
	srodek.offset_left = -320
	srodek.offset_right = 320
	tytul = Ui.naglowek_menu("", 40, Color("f0dcb6"), 4)
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tytul.add_theme_constant_override("outline_size", 6)
	tytul.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	srodek.add_child(tytul)
	var sep := TextureRect.new()
	sep.texture = load("res://zasoby/ui/menu/separator_z_pietnem.webp")
	sep.custom_minimum_size = Vector2(300, 46)
	sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	srodek.add_child(sep)
	podtytul = Ui.naglowek_menu("", 12, Ui.M_ZAR, 3)
	podtytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	srodek.add_child(podtytul)
	przycisk_wroc = Ui.przycisk_menu("←  Wróć")
	przycisk_wroc.pressed.connect(func(): wroc_wcisniety.emit())
	gora.add_child(przycisk_wroc)
	przycisk_wroc.position = Vector2(0, 14)
	przycisk_wroc.focus_mode = Control.FOCUS_NONE  # B / Esc wraca; fokus padem zostaje w liście
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", Ui._tm("przycisk_zwykly", [32, 20, 32, 20], [20, 4, 24, 4]))
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", 8)
	var urna := TextureRect.new()
	urna.texture = load("res://zasoby/ui/menu/urna_popiolow.webp")
	urna.custom_minimum_size = Vector2(26, 26)
	urna.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	urna.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	urna.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lh.add_child(urna)
	licznik = Ui.tekst_menu("", 17, Ui.M_ZLOTO2)
	licznik.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lh.add_child(licznik)
	lp.add_child(lh)
	gora.add_child(lp)
	lp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE)
	lp.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lp.offset_top = 14
	# zakładki ze znaczkami LB/RB (pad) albo Q/E (klawiatura)
	var rz := HBoxContainer.new()
	rz.alignment = BoxContainer.ALIGNMENT_CENTER
	rz.add_theme_constant_override("separation", 10)
	rz.custom_minimum_size = Vector2(0, 60)
	v.add_child(rz)
	_znaczek_l = _znaczek("lb", "Q")
	rz.add_child(_znaczek_l)
	rzad_zakladek = HBoxContainer.new()
	rzad_zakladek.add_theme_constant_override("separation", 8)
	rz.add_child(rzad_zakladek)
	_znaczek_p = _znaczek("rb", "E")
	rz.add_child(_znaczek_p)
	var odst := Control.new()
	odst.custom_minimum_size = Vector2(0, 10)
	v.add_child(odst)
	v.add_child(Ui.linia(Ui.M_LINIA))
	var odst2 := Control.new()
	odst2.custom_minimum_size = Vector2(0, 16)
	v.add_child(odst2)
	# dwa panele
	var panele := HBoxContainer.new()
	panele.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panele.add_theme_constant_override("separation", 26)
	v.add_child(panele)
	var pl := PanelContainer.new()
	pl.add_theme_stylebox_override("panel", Ui.styl_panelu_menu())
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.size_flags_stretch_ratio = 44.0
	panele.add_child(pl)
	var plv := VBoxContainer.new()
	plv.add_theme_constant_override("separation", 6)
	pl.add_child(plv)
	przewijanie_listy = ScrollContainer.new()
	przewijanie_listy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	przewijanie_listy.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	przewijanie_listy.follow_focus = true
	plv.add_child(przewijanie_listy)
	lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 0)
	przewijanie_listy.add_child(lista)
	stopka_listy = Ui.tekst_menu("", 14, Ui.M_DRUGI)
	plv.add_child(stopka_listy)
	var pp := PanelContainer.new()
	var sp := Ui.styl_panelu_menu()
	sp.content_margin_left = 8
	sp.content_margin_right = 8
	sp.content_margin_top = 8
	sp.content_margin_bottom = 8
	pp.add_theme_stylebox_override("panel", sp)
	pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pp.size_flags_stretch_ratio = 56.0
	pp.clip_contents = true
	panele.add_child(pp)
	var wnetrze := Control.new()
	wnetrze.clip_contents = true
	pp.add_child(wnetrze)
	ilustracja = TextureRect.new()
	ilustracja.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ilustracja.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ilustracja.modulate = Color(0.8, 0.72, 0.68)
	wnetrze.add_child(ilustracja)
	ilustracja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cien := _gradient_ilustracji()
	wnetrze.add_child(cien)
	cien.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	duza_ikona = TextureRect.new()
	duza_ikona.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	duza_ikona.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	duza_ikona.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wnetrze.add_child(duza_ikona)
	duza_ikona.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	duza_ikona.offset_left = -150
	duza_ikona.offset_right = -22
	duza_ikona.offset_top = 22
	duza_ikona.offset_bottom = 150
	przewijanie_szczegolow = ScrollContainer.new()
	przewijanie_szczegolow.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wnetrze.add_child(przewijanie_szczegolow)
	przewijanie_szczegolow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	przewijanie_szczegolow.offset_left = 26
	przewijanie_szczegolow.offset_right = -26
	przewijanie_szczegolow.offset_bottom = -18
	var kol := VBoxContainer.new()
	kol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kol.alignment = BoxContainer.ALIGNMENT_END
	kol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	przewijanie_szczegolow.add_child(kol)
	var wypelnienie := Control.new()
	wypelnienie.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wypelnienie.custom_minimum_size = Vector2(0, 96)
	kol.add_child(wypelnienie)
	szczegoly = VBoxContainer.new()
	szczegoly.add_theme_constant_override("separation", 8)
	kol.add_child(szczegoly)
	# stopka
	var odst3 := Control.new()
	odst3.custom_minimum_size = Vector2(0, 12)
	v.add_child(odst3)
	v.add_child(Ui.linia(Ui.M_LINIA))
	stopka = HBoxContainer.new()
	stopka.alignment = BoxContainer.ALIGNMENT_CENTER
	stopka.add_theme_constant_override("separation", 34)
	stopka.custom_minimum_size = Vector2(0, 42)
	v.add_child(stopka)
	ustaw_stopke([["lb", "Q / E", "Zakładki"], ["a", "Enter", "Wybierz"], ["b", "Esc", "Wróć"]])


var _krzyzak_czas := 0.0
var _krzyzak_nast := 0.0


func _process(dt: float) -> void:
	if not is_visible_in_tree():
		return
	if Sterowanie.pad_aktywny != _pad_byl:
		_pad_byl = Sterowanie.pad_aktywny
		_odswiez_znaczki()
	# prawa gałka przewija panel szczegółów (zasada pada NightBrand)
	var os := Input.get_axis("celuj_gora", "celuj_dol")
	if absf(os) > 0.2:
		przewijanie_szczegolow.scroll_vertical += int(os * 600.0 * dt)
	# krzyżak przytrzymany: pierwszy krok, 0,4 s przerwy, potem co 0,16 s (pad nie ma autopowtarzania)
	var kier := 0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		kier = 1
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		kier = -1
	if kier == 0:
		_krzyzak_czas = 0.0
		return
	_krzyzak_czas += dt
	if _krzyzak_czas >= 0.4 and _krzyzak_czas >= _krzyzak_nast:
		_krzyzak_nast = _krzyzak_czas + 0.16
		var f := get_viewport().gui_get_focus_owner()
		if f != null and is_ancestor_of(f):
			var n := f.find_valid_focus_neighbor(SIDE_BOTTOM if kier > 0 else SIDE_TOP)
			if n != null:
				n.grab_focus()
	elif _krzyzak_czas < 0.4:
		_krzyzak_nast = 0.4


## Zakładki ekranu (nazwy) i która jest aktywna.
func ustaw_zakladki(nazwy: Array, indeks: int) -> void:
	aktywna = indeks
	for c in rzad_zakladek.get_children():
		c.queue_free()
	zakladki.clear()
	for i in nazwy.size():
		var b := Ui.zakladka_menu(str(nazwy[i]), i == indeks)
		b.focus_mode = Control.FOCUS_NONE  # zakładki: LB/RB (pad), Q/E (klawiatura) albo mysz
		var nr := i
		b.pressed.connect(func(): zakladka_wybrana.emit(nr))
		rzad_zakladek.add_child(b)
		zakladki.append(b)


## Stopka: [[ikona pada, klawisz, podpis], ...] — pokazuje ikony pada albo klawisze wg ostatniego wejścia.
func ustaw_stopke(wpisy: Array) -> void:
	_stopka_wpisy = wpisy
	_odswiez_znaczki()


func _odswiez_znaczki() -> void:
	if stopka == null:
		return
	for c in stopka.get_children():
		c.queue_free()
	var pad: bool = Sterowanie.pad_aktywny
	for w in _stopka_wpisy:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		if pad:
			for n in str(w[0]).split("/"):
				h.add_child(_ikona_pada(n, 24.0))
		else:
			h.add_child(Ui.klawisz(str(w[1])))
		var l := Ui.tekst_menu(str(w[2]), 15, Ui.M_TEKST)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
		stopka.add_child(h)
	for z in [_znaczek_l, _znaczek_p]:
		z.get_child(0).visible = pad
		z.get_child(1).visible = not pad


func _znaczek(pad: String, klaw: String) -> Control:
	var c := HBoxContainer.new()
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(_ikona_pada(pad, 26.0))
	c.add_child(Ui.klawisz(klaw))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


func _ikona_pada(n: String, wys: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://zasoby/ui/pad_%s.webp" % n)
	var r := t.texture.get_size()
	t.custom_minimum_size = Vector2(wys * r.x / maxf(1.0, r.y), wys)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


## Czyści listę i szczegóły (przed przebudową treści).
func wyczysc() -> void:
	for c in lista.get_children():
		lista.remove_child(c)
		c.queue_free()
	for c in szczegoly.get_children():
		szczegoly.remove_child(c)
		c.queue_free()
	duza_ikona.texture = null


func _gradient_pionowy() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.28, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.1), Color(0, 0, 0, 0.7)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return t


func _winieta() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0.1, 0.0, 0.0, 0.15), Color(0.12, 0.0, 0.0, 0.6)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 256
	gt.height = 256
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return t


func _gradient_ilustracji() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 1.0])
	g.colors = PackedColorArray([Color(0.04, 0.035, 0.04, 0.1), Color(0.04, 0.035, 0.04, 0.25), Color(0.05, 0.045, 0.05, 0.88), Color(0.05, 0.045, 0.05, 0.97)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
