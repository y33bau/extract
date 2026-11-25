extends Node2D
## Upadły Gwardzista: pościg, zamach ze złotym błyskiem (okno parowania), cios, ogłuszenie, śmierć.

const Iso = preload("res://skrypty/iso.gd")
const TEX := preload("res://zasoby/en_warden.webp")

var w := Vector2(8.5, 6.5)
var kat := PI
var hp := 115.0
var hp_max := 115.0
var zamach := 0.0          # odliczanie zamachu (złoty błysk)
const ZAMACH_CZAS := 0.62
var cios_anim := 0.0
var odnowienie := 1.0
var ogluszenie := 0.0
var trafiony := 0.0
var krok_anim := 0.0
var zasieg := 1.75
var obrazenia := 30.0

var cel  # bohater
var scena
var sprite: Sprite2D
var blysk: Sprite2D

signal wynik_ciosu(rodzaj)

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.scale = Vector2(0.8, 0.8)
	sprite.offset = Vector2(0, -55)
	add_child(sprite)
	# Złoty błysk zapowiedzi ataku: nie podlega ciemności (unshaded)
	blysk = Sprite2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.86, 0.35, 1))
	g.set_color(1, Color(1.0, 0.75, 0.2, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 48
	t.height = 48
	blysk.texture = t
	blysk.position = Vector2(14, -62)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	blysk.material = mat
	blysk.visible = false
	add_child(blysk)

func otrzymaj(obr: float, riposta: bool) -> void:
	if hp <= 0.0:
		return
	hp -= obr
	trafiony = 0.15
	if riposta:
		ogluszenie = 0.0
	if hp <= 0.0:
		zamach = 0.0

func _process(dt: float) -> void:
	trafiony = maxf(0.0, trafiony - dt)
	cios_anim = maxf(0.0, cios_anim - dt)
	if hp <= 0.0:
		sprite.frame = 7  # klatka śmierci
		blysk.visible = false
		sprite.modulate = Color(0.8, 0.8, 0.8)
		position = Iso.ekran(w)
		return
	if ogluszenie > 0.0:
		ogluszenie -= dt
		sprite.frame = 4
		sprite.position.x = sin(Time.get_ticks_msec() * 0.04) * 2.0
		position = Iso.ekran(w)
		blysk.visible = false
		return
	sprite.position.x = 0.0
	odnowienie = maxf(0.0, odnowienie - dt)
	var d: Vector2 = cel.w - w
	var dist := d.length()
	var w_ruchu := false

	if zamach > 0.0:
		zamach -= dt
		if zamach <= 0.0:
			cios_anim = 0.22
			odnowienie = 1.45
			if dist <= zasieg + 0.4 and cel.hp > 0.0:
				wynik_ciosu.emit(cel.przyjmij_cios(self, obrazenia))
	else:
		kat = atan2(d.y, d.x)
		if dist > zasieg - 0.15:
			var nowa := w + d.normalized() * 1.9 * dt
			if scena == null or scena.wolne(nowa):
				w = nowa
			w_ruchu = true
			krok_anim += dt * 7.0
		elif odnowienie <= 0.0 and cel.hp > 0.0:
			zamach = ZAMACH_CZAS

	# Animacja (arkusz: rząd 0 chód, rząd 1 atak 3 klatki + śmierć; patrzy w prawo)
	if zamach > 0.0:
		sprite.frame = 4
	elif cios_anim > 0.0:
		sprite.frame = 5 if cios_anim > 0.11 else 6
	elif w_ruchu:
		sprite.frame = int(krok_anim) % 4
	else:
		sprite.frame = 0
	var k := Iso.kierunek_arkusza(kat)
	sprite.flip_h = k["sdx"] < 0.0
	blysk.position.x = -14.0 if sprite.flip_h else 14.0
	blysk.visible = zamach > 0.0
	blysk.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.3)
	sprite.modulate = Color(3, 3, 3) if trafiony > 0.0 else Color.WHITE
	position = Iso.ekran(w)
