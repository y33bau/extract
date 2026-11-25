extends Node2D
## Hadræn: stan i wygląd. Logikę walki prowadzi rajd.gd (jedno miejsce reguł).

const Iso = preload("res://skrypty/iso.gd")
const TEX_CHOD := preload("res://zasoby/knight_d.webp")
const TEX_ATAK := preload("res://zasoby/knight_dc.webp")
const TEX_BLOK := preload("res://zasoby/knight_def.webp")
const TEX_SMIERC := preload("res://zasoby/knight_death.webp")

var w := Vector2.ZERO
var promien := 0.28
var kat := 0.0
var hp := 100.0
var hp_max := 100.0
var stamina := 100.0
var stamina_max := 100.0
var dopalacz_staminy := 0.0
var plonie := false
var plon_tik := 0.0
var krok_anim := 0.0
var krok_dzwiek := 0.0
var w_ruchu := false
# walka
var atak_czas := 0.0
var atak_dlugosc := 0.0
var atak_cd := 0.0
var atak_kat := 0.0
var combo := 0
var combo_reset := 0.0
var zamach_anim := 0.0
var zamach_anim_max := 0.3
var blok := false
var okno_parowania := 0.0
var parowanie_cd := 0.0
var unik_czas := 0.0
var unik_kier := Vector2.ZERO
var unik_cd := 0.0
var luk_cd := 0.0
var riposta_niet := 0.0
var pochodnia_w_rece := true
var martwy := false
var smierc_anim := 0.0
var rynsztunek: Dictionary = {}  # kopia profilu na czas rajdu

var sprite: Sprite2D
var plomien: Node2D
var pochodnia: PointLight2D
var poswiata: PointLight2D
var aura: Node2D


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEX_CHOD
	sprite.hframes = 4
	sprite.vframes = 6
	sprite.scale = Vector2(0.82, 0.82)
	sprite.offset = Vector2(0, -55)
	add_child(sprite)
	pochodnia = Swiatla.nowe(Color(1.0, 0.78, 0.52), 1.5, 270.0)
	pochodnia.position = Vector2(-12, -48)
	add_child(pochodnia)
	poswiata = Swiatla.nowe(Color(0.6, 0.55, 0.75), 0.5, 105.0)
	poswiata.position = Vector2(0, -20)
	add_child(poswiata)
	plomien = Node2D.new()
	plomien.draw.connect(_rysuj_plomien)
	add_child(plomien)
	aura = Node2D.new()
	aura.draw.connect(_rysuj_aure)
	aura.z_index = -1
	add_child(aura)


func _rysuj_plomien() -> void:
	if not pochodnia_w_rece or martwy:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var reka := 13.0 if sprite.flip_h else -13.0
	plomien.draw_line(Vector2(reka, -30), Vector2(reka * 1.2, -50), Color("3a2618"), 3.0)
	var h := 9.0 + sin(t * 17.0) * 2.0 + cos(t * 29.0)
	var c := Vector2(reka * 1.2, -58)
	plomien.draw_set_transform(c, 0, Vector2(1.0, h / 6.0))
	plomien.draw_circle(Vector2.ZERO, 6.0, Color(0.88, 0.33, 0.1, 0.9))
	plomien.draw_circle(Vector2(0, 1), 3.3, Color(1.0, 0.82, 0.4, 0.95))
	plomien.draw_set_transform(Vector2.ZERO)


func _rysuj_aure() -> void:
	if okno_parowania > 0.0 and not martwy:
		aura.draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.5))
		aura.draw_arc(Vector2.ZERO, 22, 0, TAU, 32, Color(1.0, 0.82, 0.43, 0.35 + okno_parowania), 2.0)
		aura.draw_set_transform(Vector2.ZERO)


func animuj(czas: float) -> void:
	position = Iso.ekran(w)
	var klatka := 0
	var odbij := false
	if martwy:
		var f := mini(7, int(smierc_anim * 6.0))
		sprite.texture = TEX_SMIERC
		sprite.vframes = 2
		klatka = f
		odbij = Iso.kierunek_arkusza(kat)["sdx"] < 0.0
	elif zamach_anim > 0.0:
		var k := Iso.kierunek_arkusza(atak_kat)
		var t := 1.0 - zamach_anim / zamach_anim_max
		var ciezki := combo == 2
		var rzad := 0
		if k["rzad"] == 0:
			rzad = 4 if ciezki else 3
		elif k["rzad"] == 2:
			rzad = 2 if ciezki else (1 if combo == 1 else 0)
		else:
			rzad = 5
			odbij = k["sdx"] < 0.0
		sprite.texture = TEX_ATAK
		sprite.vframes = 6
		klatka = rzad * 4 + mini(3, int(t * 4.0))
	elif blok:
		var k2 := Iso.kierunek_arkusza(kat)
		sprite.texture = TEX_BLOK
		sprite.vframes = 6
		klatka = int(k2["rzad"]) * 4 + (1 if okno_parowania > 0.0 else 0)
		odbij = k2["rzad"] == 1 and k2["sdx"] < 0.0
	else:
		var k3 := Iso.kierunek_arkusza(kat)
		sprite.texture = TEX_CHOD
		sprite.vframes = 6
		odbij = k3["rzad"] == 1 and k3["sdx"] < 0.0
		if w_ruchu:
			klatka = (3 + int(k3["rzad"])) * 4 + int(krok_anim) % 4
		else:
			klatka = int(k3["rzad"]) * 4 + int(czas * 4.0) % 4
	sprite.frame = klatka
	sprite.flip_h = odbij
	sprite.modulate = Color(1.7, 1.7, 1.8, 0.55) if unik_czas > 0.0 else Color.WHITE
	pochodnia.visible = pochodnia_w_rece and not martwy
	poswiata.visible = not pochodnia_w_rece
	pochodnia.position.x = 13.0 * 1.2 if odbij else -13.0 * 1.2
	pochodnia.energy = 1.45 + sin(czas * 14.0) * 0.08 + cos(czas * 23.0) * 0.05
	plomien.queue_redraw()
	aura.queue_redraw()
