extends Node2D
## Pilot: jedna komnata, Hadræn i Upadły Gwardzista. Sprawdza silnik, pad i automatyczne testy.
## Tryb testu: godot --path godot -- --test [--zrzut=/sciezka.png]

const Iso = preload("res://skrypty/iso.gd")
const Bohater = preload("res://skrypty/bohater.gd")
const Wrog = preload("res://skrypty/wrog.gd")

const ROZMIAR := 12
var bohater
var wrogowie: Array = []
var kamera: Camera2D
var napis: Label
var komunikat := ""
var komunikat_czas := 0.0

func _ready() -> void:
	# Mrok: całą scenę przyciemnia CanvasModulate, światło daje tylko pochodnia
	var mrok := CanvasModulate.new()
	mrok.color = Color(0.16, 0.14, 0.19)
	add_child(mrok)

	var podloga := Node2D.new()
	podloga.z_index = -10
	podloga.draw.connect(_rysuj_podloge.bind(podloga))
	add_child(podloga)

	var swiat := Node2D.new()
	swiat.y_sort_enabled = true
	add_child(swiat)

	bohater = Bohater.new()
	bohater.scena = self
	swiat.add_child(bohater)

	var wrog = Wrog.new()
	wrog.cel = bohater
	wrog.scena = self
	wrog.wynik_ciosu.connect(_po_ciosie_wroga)
	swiat.add_child(wrog)
	wrogowie.append(wrog)
	bohater.zadal_cios.connect(_po_ciosie_bohatera)

	kamera = Camera2D.new()
	kamera.position_smoothing_enabled = true
	kamera.position_smoothing_speed = 8.0
	add_child(kamera)

	var hud := CanvasLayer.new()
	add_child(hud)
	napis = Label.new()
	napis.position = Vector2(16, 12)
	napis.add_theme_font_size_override("font_size", 18)
	napis.add_theme_color_override("font_color", Color(0.93, 0.85, 0.7))
	napis.add_theme_color_override("font_outline_color", Color.BLACK)
	napis.add_theme_constant_override("outline_size", 6)
	hud.add_child(napis)

	if "--test" in OS.get_cmdline_user_args():
		_test_automatyczny()

func wolne(p: Vector2) -> bool:
	return p.x > 1.3 and p.y > 1.3 and p.x < ROZMIAR - 1.3 and p.y < ROZMIAR - 1.3

func _rysuj_podloge(n: Node2D) -> void:
	for y in ROZMIAR:
		for x in ROZMIAR:
			var c := Iso.ekran(Vector2(x, y))
			var pts := PackedVector2Array([c, c + Vector2(32, 16), c + Vector2(0, 32), c + Vector2(-32, 16)])
			var brzeg := x == 0 or y == 0 or x == ROZMIAR - 1 or y == ROZMIAR - 1
			var kolor := Color(0.32, 0.29, 0.33) if brzeg else (Color(0.21, 0.19, 0.22) if (x + y) % 2 == 0 else Color(0.24, 0.22, 0.25))
			n.draw_colored_polygon(pts, kolor)
			n.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0, 0, 0, 0.35), 1.0)
			if brzeg:  # niski murek jako znacznik krawędzi komnaty
				var gora := PackedVector2Array([pts[0] + Vector2(0, -18), pts[1] + Vector2(0, -18), pts[2] + Vector2(0, -18), pts[3] + Vector2(0, -18)])
				n.draw_colored_polygon(gora, Color(0.38, 0.34, 0.39))

func _po_ciosie_wroga(rodzaj: String) -> void:
	var opis := {"unik": "UNIK!", "parowanie": "PAROWANIE! [atak = RIPOSTA]", "blok": "BLOK", "trafienie": "TRAFIONY!"}
	_pokaz(opis.get(rodzaj, rodzaj))

func _po_ciosie_bohatera(_cel, obr: float, riposta: bool) -> void:
	_pokaz(("RIPOSTA -%d!" if riposta else "-%d") % int(obr))

func _pokaz(t: String) -> void:
	komunikat = t
	komunikat_czas = 1.2

func _process(dt: float) -> void:
	kamera.position = bohater.position + Vector2(0, -40)
	komunikat_czas = maxf(0.0, komunikat_czas - dt)
	var w = wrogowie[0]
	var pady := Input.get_connected_joypads()
	napis.text = "HADRÆN  HP %d   |   %s  HP %d%s\nPad: %s   |   WASD/lewy drążek • LPM/X atak • PPM/L1 parowanie • Spacja/B unik\n%s" % [
		int(bohater.hp), "Gwardzista", int(maxf(0.0, w.hp)),
		"  (OGŁUSZONY)" if w.ogluszenie > 0.0 else "",
		Input.get_joy_name(pady[0]) if pady.size() > 0 else "brak",
		komunikat if komunikat_czas > 0.0 else ""]

# ---------------- TEST AUTOMATYCZNY (symuluje PAD) ----------------
var _wyniki: Array = []

func _ok(nazwa: String, warunek: bool, szczegol := "") -> void:
	_wyniki.append(warunek)
	print(("  OK   " if warunek else "  BŁĄD ") + nazwa + ("  [" + szczegol + "]" if szczegol != "" else ""))

func _pad_os(os: JoyAxis, v: float) -> void:
	var z := InputEventJoypadMotion.new()
	z.device = 0
	z.axis = os
	z.axis_value = v
	Input.parse_input_event(z)

func _pad_przycisk(b: JoyButton, wcisniety: bool) -> void:
	var z := InputEventJoypadButton.new()
	z.device = 0
	z.button_index = b
	z.pressed = wcisniety
	Input.parse_input_event(z)

func _czekaj(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _test_automatyczny() -> void:
	print("-- test pilota Godot (symulowany pad)")
	var w = wrogowie[0]
	w.set_process(false)  # wróg czeka, aż ustawimy scenę
	await _czekaj(0.3)

	# 1. Ruch lewym drążkiem w prawo
	var start: Vector2 = bohater.w
	_pad_os(JOY_AXIS_LEFT_X, 1.0)
	await _czekaj(0.5)
	_pad_os(JOY_AXIS_LEFT_X, 0.0)
	await _czekaj(0.1)
	_ok("ruch lewym drążkiem", bohater.w.distance_to(start) > 0.8, "przesunięcie %.2f pola" % bohater.w.distance_to(start))

	# 2. Wróg przed bohaterem zaczyna zamach; parowanie L1 tuż przed ciosem
	var przod := Vector2(cos(bohater.kat), sin(bohater.kat))
	w.w = bohater.w + przod * 1.2
	w.odnowienie = 0.0
	w.set_process(true)
	await _czekaj(0.15)
	_ok("wróg zaczyna zamach (złoty błysk)", w.zamach > 0.0 and w.blysk.visible)
	while w.zamach > 0.2:
		await get_tree().process_frame
	_pad_przycisk(JOY_BUTTON_LEFT_SHOULDER, true)
	await _czekaj(0.4)
	_pad_przycisk(JOY_BUTTON_LEFT_SHOULDER, false)
	_ok("parowanie padem ogłusza wroga", w.ogluszenie > 0.0, "ogłuszenie %.2f s" % w.ogluszenie)
	_ok("bohater nie stracił życia", bohater.hp >= 100.0, "HP %d" % int(bohater.hp))

	# 3. Riposta przyciskiem X
	var hp_przed: float = w.hp
	_pad_przycisk(JOY_BUTTON_X, true)
	await _czekaj(0.15)
	_pad_przycisk(JOY_BUTTON_X, false)
	await _czekaj(0.15)
	_ok("riposta X zadaje podwójne obrażenia", hp_przed - w.hp > 50.0, "-%d HP" % int(hp_przed - w.hp))
	_ok("riposta kończy ogłuszenie", w.ogluszenie <= 0.0)

	# 4. Zrzut ekranu
	await _czekaj(0.2)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--zrzut="):
			get_viewport().get_texture().get_image().save_png(a.substr(8))
			print("  zrzut: ", a.substr(8))

	var zle := _wyniki.count(false)
	print("\nWYNIK (godot-pilot): ", "OK" if zle == 0 else "BŁĘDY: %d" % zle, "  (%d/%d)" % [_wyniki.size() - zle, _wyniki.size()])
	get_tree().quit(0 if zle == 0 else 1)
