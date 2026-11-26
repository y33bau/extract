extends CanvasLayer
## Ekran tytułowy (instrukcja przebudowy menu, etap 5; zgoda autora 26.11: „rób wszystkie kolejne etapy”).
## Wzór: menu główne NightBrand — znak i nazwa gry po lewej, pod nimi kolumna dużych przycisków,
## po prawej malowany plac z Hadrænem przy ognisku, na dole pasek postępu.
## Logo to na razie napis Cinzel + Piętno (prompt na logo graficzne: docs/PROMPTY_MENU.md).

signal kontynuuj
signal opcje

const Ui = preload("res://skrypty/ui.gd")

var przycisk_kontynuuj: Button
var przycisk_opcje: Button
var przycisk_wyjdz: Button
var pasek: Label
var dialog_wyjscia: ConfirmationDialog


func _init() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var k := Control.new()
	k.theme = Ui.motyw()
	k.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(k)
	var czern := ColorRect.new()
	czern.color = Color.BLACK
	k.add_child(czern)
	czern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tlo := TextureRect.new()
	tlo.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
	tlo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tlo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tlo.modulate = Color(0.85, 0.78, 0.74)
	k.add_child(tlo)
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# ciemniej z lewej, żeby kolumna przycisków była czytelna
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 0.62])
	g.colors = PackedColorArray([Color(0.03, 0.02, 0.02, 0.88), Color(0.03, 0.02, 0.02, 0.55), Color(0, 0, 0, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 4
	var lewo := TextureRect.new()
	lewo.texture = gt
	lewo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lewo.stretch_mode = TextureRect.STRETCH_SCALE
	lewo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.add_child(lewo)
	lewo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	k.add_child(Ui.winieta())
	# Hadræn przy ognisku
	var bohater := TextureRect.new()
	bohater.texture = load("res://zasoby/ui/menu/hadraen.webp")
	bohater.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bohater.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bohater.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.add_child(bohater)
	bohater.anchor_left = 0.64
	bohater.anchor_right = 0.84
	bohater.anchor_top = 0.5
	bohater.anchor_bottom = 0.86
	# lewa kolumna: znak, nazwa, przyciski, pasek postępu
	var kol := VBoxContainer.new()
	kol.add_theme_constant_override("separation", 10)
	k.add_child(kol)
	kol.anchor_left = 0.07
	kol.anchor_right = 0.42
	kol.anchor_top = 0.06
	kol.anchor_bottom = 0.95
	var znak := TextureRect.new()
	znak.texture = load("res://zasoby/ui/menu/pietno.webp")
	znak.custom_minimum_size = Vector2(0, 92)
	znak.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	znak.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kol.add_child(znak)
	for t in [["WAROWNIA", 50, Color("e8d2a8")], ["POPIOŁÓW", 40, Color("e07a38")]]:
		var l := Ui.naglowek_menu(t[0], t[1], t[2], 5)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.02, 0.9))
		kol.add_child(l)
	var odst := Control.new()
	odst.custom_minimum_size = Vector2(0, 12)
	kol.add_child(odst)
	przycisk_kontynuuj = _przycisk("Kontynuuj")
	przycisk_kontynuuj.pressed.connect(func(): kontynuuj.emit())
	kol.add_child(przycisk_kontynuuj)
	przycisk_opcje = _przycisk("Opcje")
	przycisk_opcje.pressed.connect(func(): opcje.emit())
	kol.add_child(przycisk_opcje)
	przycisk_wyjdz = _przycisk("Wyjdź")
	przycisk_wyjdz.pressed.connect(func(): dialog_wyjscia.popup_centered())
	kol.add_child(przycisk_wyjdz)
	var wyp := Control.new()
	wyp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kol.add_child(wyp)
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", Ui._tm("przycisk_zwykly", [32, 20, 32, 20], [30, 8, 30, 8]))
	pasek = Ui.tekst_menu("", 15, Ui.M_TEKST)
	pasek.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pp.add_child(pasek)
	kol.add_child(pp)
	dialog_wyjscia = ConfirmationDialog.new()
	dialog_wyjscia.title = "Wyjść z gry?"
	dialog_wyjscia.dialog_text = "Postęp Warowni jest zapisany."
	dialog_wyjscia.ok_button_text = "Wyjdź"
	dialog_wyjscia.cancel_button_text = "Zostań"
	dialog_wyjscia.confirmed.connect(func(): get_tree().quit())
	k.add_child(dialog_wyjscia)
	przycisk_kontynuuj.focus_neighbor_top = przycisk_kontynuuj.get_path_to(przycisk_wyjdz)
	przycisk_wyjdz.focus_neighbor_bottom = przycisk_wyjdz.get_path_to(przycisk_kontynuuj)


func _przycisk(t: String) -> Button:
	var b := Ui.przycisk_menu(t)
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 28)
	return b


## Pokaż ekran (pasek postępu z zapisu) i ustaw fokus na „Kontynuuj”.
func pokaz() -> void:
	var d := Profil.d
	pasek.text = "Złoto %d   ·   Wyprawy %d (przeżyte %d)   ·   Pokonani %d" % [int(d["gold"]), int(d["stats"]["raids"]), int(d["stats"]["survived"]), int(d["stats"].get("kills", 0))]
	visible = true
	przycisk_kontynuuj.grab_focus.call_deferred()
	Ui.blokada_po_otwarciu(przycisk_kontynuuj, 0.4)


func _unhandled_input(e: InputEvent) -> void:
	if visible and not dialog_wyjscia.visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()  # B na ekranie tytułowym nic nie zamyka
