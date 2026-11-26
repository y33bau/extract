extends CanvasLayer
## Pauza (Esc / P, pad Start) w rajdzie i w Przystani — wygląd jak pauza NightBrand.
## Zatrzymuje drzewo gry (get_tree().paused); sama działa zawsze. Pad: LB/RB zakładki, A wybiera, B lub Start wraca do gry.

signal wznowiono

const Ui = preload("res://skrypty/ui.gd")

var zakladki: TabContainer
var wroc: Button
var wyjdz: Button
var podtytul: Label
var dialog_wyjscia: ConfirmationDialog
var _grafika: Button
var _dzwiek: Button
var _umiej: VBoxContainer
var w_rajdzie := false


func _init() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _ready() -> void:
	var korzen := Control.new()
	korzen.theme = Ui.motyw()
	korzen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(korzen)
	var tlo := ColorRect.new()
	tlo.color = Color(0.02, 0.015, 0.02, 0.78)
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	korzen.add_child(tlo)
	var winieta := ColorRect.new()
	winieta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	winieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = """shader_type canvas_item;
void fragment() {
	vec2 d = UV - 0.5;
	float v = smoothstep(0.25, 0.75, length(d * vec2(1.1, 1.0)));
	COLOR = vec4(0.06, 0.01, 0.0, v * 0.75);
}"""
	winieta.material = sm
	korzen.add_child(winieta)
	var marg := MarginContainer.new()
	marg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right"]:
		marg.add_theme_constant_override("margin_" + k, 90)
	marg.add_theme_constant_override("margin_top", 18)
	marg.add_theme_constant_override("margin_bottom", 22)
	korzen.add_child(marg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	marg.add_child(v)
	var tyt := Ui.etykieta("PAUZA", 52, Color("efe2c8"))
	tyt.add_theme_font_override("font", Ui.czcionka(700))
	tyt.add_theme_constant_override("outline_size", 8)
	tyt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tyt)
	var orn := Control.new()
	orn.custom_minimum_size = Vector2(0, 14)
	orn.draw.connect(func(): _ornament(orn))
	v.add_child(orn)
	podtytul = Ui.etykieta("", 16, Color("b9a27a"))
	podtytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(podtytul)
	zakladki = TabContainer.new()
	zakladki.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zakladki.tab_alignment = TabBar.ALIGNMENT_CENTER
	zakladki.tab_changed.connect(func(_i): Dzwiek.ui(); _fokus_w_zakladce())
	v.add_child(zakladki)
	zakladki.add_child(_sterowanie())
	zakladki.add_child(_umiejetnosci())
	zakladki.add_child(_ustawienia())
	var dol := HBoxContainer.new()
	dol.alignment = BoxContainer.ALIGNMENT_END
	dol.add_theme_constant_override("separation", 24)
	wyjdz = Ui.przycisk_akcji("Wyjdź z gry")
	wyjdz.custom_minimum_size = Vector2(300, 64)
	wyjdz.pressed.connect(func(): dialog_wyjscia.popup_centered())
	dol.add_child(wyjdz)
	wroc = Ui.przycisk_akcji("Wróć do gry")
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


func _ornament(c: Control) -> void:
	var s := c.size
	var y := s.y / 2.0
	var k := Color(0.62, 0.48, 0.28, 0.85)
	c.draw_line(Vector2(s.x * 0.33, y), Vector2(s.x * 0.48, y), k, 1.0)
	c.draw_line(Vector2(s.x * 0.52, y), Vector2(s.x * 0.67, y), k, 1.0)
	var m := Vector2(s.x / 2.0, y)
	c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -6), m + Vector2(6, 0), m + Vector2(0, 6), m + Vector2(-6, 0)]), Color("c9873a"))


## Sterowanie: lista z `Sterowanie.OPIS` (jedno źródło z mapą akcji), klawiatura i pad obok siebie.
func _sterowanie() -> Control:
	var sc := ScrollContainer.new()
	sc.name = "Sterowanie"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var srodek := CenterContainer.new()
	srodek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(srodek)
	var p := Ui.panel()
	p.custom_minimum_size = Vector2(980, 0)
	srodek.add_child(p)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 28)
	g.add_theme_constant_override("v_separation", 6)
	p.add_child(g)
	for n in ["CZYNNOŚĆ", "KLAWIATURA I MYSZ", "PAD"]:
		g.add_child(Ui.etykieta(n, 14, Color("c9873a")))
	for w in Sterowanie.OPIS:
		g.add_child(Ui.etykieta(w[0], 17, Color("ede2cc")))
		var kl := Ui.etykieta(w[1], 16, Color("e6ba63"))
		g.add_child(kl)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		for b in w[2]:
			var sciezka := "res://zasoby/ui/pad_%s.webp" % b
			if ResourceLoader.exists(sciezka):
				var t := TextureRect.new()
				t.texture = load(sciezka)
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				t.custom_minimum_size = Vector2(56 if b in ["lb", "rb"] else 34, 32)
				h.add_child(t)
			else:
				h.add_child(Ui.etykieta(b, 15, Color("c8b99c")))
		g.add_child(h)
	# fokus dla pada: przewijanie listy
	sc.focus_mode = Control.FOCUS_ALL
	return sc


func _umiejetnosci() -> Control:
	var sc := ScrollContainer.new()
	sc.name = "Umiejętności"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.focus_mode = Control.FOCUS_ALL
	var srodek := CenterContainer.new()
	srodek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(srodek)
	_umiej = VBoxContainer.new()
	_umiej.custom_minimum_size = Vector2(900, 0)
	_umiej.add_theme_constant_override("separation", 8)
	srodek.add_child(_umiej)
	return sc


func _odswiez_umiejetnosci() -> void:
	for c in _umiej.get_children():
		c.queue_free()
	_umiej.add_child(Ui.etykieta("Biegłości rosną w walce, przy parowaniu, unikach, strzelaniu i przeszukiwaniu.", 15, Color("b9a27a")))
	for id in Dane.umiejetnosci:
		var u: Dictionary = Dane.umiejetnosci[id]
		var sk: Dictionary = Profil.d["skills"][id]
		var wym := int(sk["lv"]) * 100
		var p := Ui.panel()
		var v := VBoxContainer.new()
		var gora := HBoxContainer.new()
		var n := Ui.etykieta(str(u["name"]), 19, Color("efe2c8"))
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gora.add_child(n)
		gora.add_child(Ui.etykieta("poziom %d" % int(sk["lv"]), 17, Ui.ZLOTO))
		v.add_child(gora)
		v.add_child(Ui.etykieta("%s   (%d / %d PD)" % [u["bonusDesc"], int(sk["xp"]), wym], 14))
		var pas := Ui.pasek(Color("c26a2c"), 8)
		pas.max_value = wym
		pas.value = float(sk["xp"])
		v.add_child(pas)
		p.add_child(v)
		_umiej.add_child(p)


func _ustawienia() -> Control:
	var c := CenterContainer.new()
	c.name = "Grafika i dźwięk"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	c.add_child(v)
	_grafika = Button.new()
	_grafika.custom_minimum_size = Vector2(440, 56)
	_grafika.tooltip_text = "Jakość grafiki rajdu (cienie, odbicia, mgła). Niższa = płynniej. Działa od następnej wyprawy."
	_grafika.pressed.connect(func():
		Profil.ustaw_jakosc((Profil.jakosc() + 1) % Profil.JAKOSCI.size())
		Dzwiek.ui()
		_napisy_ustawien())
	v.add_child(_grafika)
	_dzwiek = Button.new()
	_dzwiek.custom_minimum_size = Vector2(440, 56)
	_dzwiek.pressed.connect(func():
		Dzwiek.wyciszony = not Dzwiek.wyciszony
		_napisy_ustawien())
	v.add_child(_dzwiek)
	var uw := Ui.etykieta("Zmiana jakości grafiki działa od następnej wyprawy.", 14, Color("9d8f78"))
	uw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(uw)
	return c


func _napisy_ustawien() -> void:
	_grafika.text = "Grafika: " + str(Profil.JAKOSCI[Profil.jakosc()])
	_dzwiek.text = "Dźwięk: wyłączony" if Dzwiek.wyciszony else "Dźwięk: włączony"


func otworz(miejsce: String, rajd_trwa: bool) -> void:
	w_rajdzie = rajd_trwa
	podtytul.text = miejsce.to_upper()
	wyjdz.visible = not rajd_trwa  # w rajdzie nie ma ucieczki z gry (pauza to nie wyjście z wyprawy)
	_napisy_ustawien()
	_odswiez_umiejetnosci()
	visible = true
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
		if b.is_visible_in_tree():
			b.grab_focus.call_deferred()
			return
	wroc.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if not visible or dialog_wyjscia.visible:
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
