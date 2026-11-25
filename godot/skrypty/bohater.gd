extends Node2D
## Hadræn: ruch, atak (combo uproszczone), parowanie/blok, unik z nietykalnością.

const Iso = preload("res://skrypty/iso.gd")

const TEX_CHOD := preload("res://zasoby/knight_d.webp")
const TEX_ATAK := preload("res://zasoby/knight_dc.webp")
const TEX_BLOK := preload("res://zasoby/knight_def.webp")

var w := Vector2(3.5, 3.5)        # pozycja w świecie (pola)
var kat := 0.0                    # kierunek patrzenia (świat)
var hp := 100.0
var predkosc := 3.4
var krok_anim := 0.0
var w_ruchu := false

var atak_czas := 0.0              # trwanie animacji ciosu
var atak_cd := 0.0
var okno_parowania := 0.0
var parowanie_cd := 0.0
var blok := false
var unik_czas := 0.0
var unik_kier := Vector2.ZERO
var unik_cd := 0.0
var mysz_aktywna := false

var sprite: Sprite2D
var swiatlo: PointLight2D
var scena  # pilot.gd (wrogowie, kolizje)

signal zadal_cios(cel, obrazenia, riposta)

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEX_CHOD
	sprite.hframes = 4
	sprite.vframes = 6
	sprite.scale = Vector2(0.82, 0.82)
	sprite.offset = Vector2(0, -55)
	add_child(sprite)
	# Pochodnia: ciepłe, migoczące światło 2D (silnik liczy je sam)
	swiatlo = PointLight2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 512
	t.height = 512
	swiatlo.texture = t
	swiatlo.color = Color(1.0, 0.78, 0.52)
	swiatlo.energy = 1.6
	swiatlo.texture_scale = 1.4
	swiatlo.position = Vector2(0, -40)
	add_child(swiatlo)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		mysz_aktywna = true
	elif e is InputEventJoypadMotion and absf(e.axis_value) > 0.3:
		mysz_aktywna = false

func _process(dt: float) -> void:
	atak_czas = maxf(0.0, atak_czas - dt)
	atak_cd = maxf(0.0, atak_cd - dt)
	okno_parowania = maxf(0.0, okno_parowania - dt)
	parowanie_cd = maxf(0.0, parowanie_cd - dt)
	unik_cd = maxf(0.0, unik_cd - dt)
	if hp <= 0.0:
		return

	# Celowanie: prawy drążek > mysz > kierunek ruchu
	var cel := Input.get_vector("celuj_lewo", "celuj_prawo", "celuj_gora", "celuj_dol")
	var ruch := Input.get_vector("ruch_lewo", "ruch_prawo", "ruch_gora", "ruch_dol")
	if cel.length() > 0.3:
		var c := Iso.ekran_na_swiat_kierunek(cel)
		kat = atan2(c.y, c.x)
	elif mysz_aktywna:
		var m := Iso.swiat(get_global_mouse_position())
		kat = atan2(m.y - w.y, m.x - w.x)
	elif ruch.length() > 0.3 and atak_czas <= 0.0:
		var c2 := Iso.ekran_na_swiat_kierunek(ruch)
		kat = atan2(c2.y, c2.x)

	# Parowanie / blok
	blok = Input.is_action_pressed("parowanie") and unik_czas <= 0.0
	if Input.is_action_just_pressed("parowanie") and parowanie_cd <= 0.0 and unik_czas <= 0.0:
		okno_parowania = 0.3
		parowanie_cd = 0.65

	# Unik
	if Input.is_action_just_pressed("unik") and unik_cd <= 0.0:
		var k := Iso.ekran_na_swiat_kierunek(ruch)
		unik_kier = k if k != Vector2.ZERO else Vector2(cos(kat), sin(kat))
		unik_czas = 0.3
		unik_cd = 0.62
		blok = false

	# Atak
	if Input.is_action_just_pressed("atak") and atak_cd <= 0.0 and unik_czas <= 0.0:
		atak_czas = 0.3
		atak_cd = 0.35
		_cios()

	# Ruch
	w_ruchu = false
	if unik_czas > 0.0:
		unik_czas -= dt
		_przesun(unik_kier * 7.6 * dt)
		w_ruchu = true
	elif ruch.length() > 0.0:
		var v := Iso.ekran_na_swiat_kierunek(ruch)
		var spd := 1.9 if blok else (1.6 if atak_czas > 0.0 else predkosc)
		_przesun(v * spd * dt)
		w_ruchu = true
		krok_anim += dt * 8.0

	position = Iso.ekran(w)
	_animuj()

func _przesun(d: Vector2) -> void:
	var nowa := w + d
	if scena and scena.wolne(nowa):
		w = nowa

func _cios() -> void:
	if scena == null:
		return
	for en in scena.wrogowie:
		if en.hp <= 0.0:
			continue
		var d: Vector2 = en.w - w
		if d.length() > 1.6:
			continue
		if absf(angle_difference(kat, atan2(d.y, d.x))) > 0.8:
			continue
		var riposta: bool = en.ogluszenie > 0.0
		var obr := 22.0 * (2.6 if riposta else 1.0)
		en.otrzymaj(obr, riposta)
		zadal_cios.emit(en, obr, riposta)

## Wywoływane przez wroga w chwili ciosu. Zwraca, co się stało.
func przyjmij_cios(od, obr: float) -> String:
	if unik_czas > 0.0:
		return "unik"
	if okno_parowania > 0.0:
		okno_parowania = 0.0
		od.ogluszenie = 2.5
		return "parowanie"
	if blok:
		hp -= obr * 0.2
		return "blok"
	hp -= obr
	return "trafienie"

func _animuj() -> void:
	var k := Iso.kierunek_arkusza(kat)
	var rzad: int = k["rzad"]
	var odbij: bool = rzad == 1 and k["sdx"] < 0.0
	if atak_czas > 0.0:
		sprite.texture = TEX_ATAK
		var t := 1.0 - atak_czas / 0.3
		sprite.frame = (5 if rzad == 1 else (3 if rzad == 0 else 0)) * 4 + mini(3, int(t * 4.0))
	elif blok:
		sprite.texture = TEX_BLOK
		sprite.frame = rzad * 4 + (1 if okno_parowania > 0.0 else 0)
	else:
		sprite.texture = TEX_CHOD
		if w_ruchu:
			sprite.frame = (3 + rzad) * 4 + int(krok_anim) % 4
		else:
			sprite.frame = rzad * 4 + int(Time.get_ticks_msec() / 250) % 4
	sprite.flip_h = odbij
	sprite.modulate = Color(1.6, 1.6, 1.6, 0.6) if unik_czas > 0.0 else Color.WHITE
	# migotanie pochodni
	swiatlo.energy = 1.55 + sin(Time.get_ticks_msec() * 0.014) * 0.08 + cos(Time.get_ticks_msec() * 0.023) * 0.05
