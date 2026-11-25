extends Node2D
## Wróg: stan i wygląd. Zachowanie (AI, ciosy) liczy rajd.gd.

const Iso = preload("res://skrypty/iso.gd")

const TYPY := {
	"scout": {"nazwa": "Popielny Zwiadowca", "hp": 65, "spd": 2.6, "dmg": 18, "zasieg": 1.45, "zamach": 0.42, "cd": 1.0, "pancerz": 0.0, "postura": 40, "promien": 0.27, "skala": 0.8},
	"warden": {"nazwa": "Upadły Gwardzista", "hp": 115, "spd": 1.9, "dmg": 30, "zasieg": 1.75, "zamach": 0.62, "cd": 1.45, "pancerz": 0.22, "postura": 75, "promien": 0.32, "skala": 0.8},
	"archer": {"nazwa": "Kusznik Cienia", "hp": 55, "spd": 2.1, "dmg": 19, "zasieg": 9.5, "zamach": 0.68, "cd": 1.8, "pancerz": 0.0, "postura": 30, "promien": 0.27, "skala": 0.8},
	"knight": {"nazwa": "Zakonny Rycerz", "hp": 150, "spd": 1.8, "dmg": 34, "zasieg": 1.85, "zamach": 0.55, "cd": 1.3, "pancerz": 0.30, "postura": 95, "promien": 0.32, "skala": 0.8},
	"brute": {"nazwa": "Kat Ruin", "hp": 190, "spd": 1.6, "dmg": 46, "zasieg": 1.95, "zamach": 0.85, "cd": 1.9, "pancerz": 0.12, "postura": 120, "promien": 0.36, "skala": 0.9, "ciezki": true},
	"boss": {"nazwa": "Popielny Strażnik", "hp": 340, "spd": 2.25, "dmg": 44, "zasieg": 2.15, "zamach": 0.72, "cd": 1.35, "pancerz": 0.30, "postura": 230, "promien": 0.38, "skala": 0.95, "boss": true},
}

var rodzaj := "scout"
var nazwa := ""
var boss := false
var ciezki := false
var w := Vector2.ZERO
var promien := 0.27
var kat := 0.0
var hp := 1.0
var hp_max := 1.0
var pancerz := 0.0
var spd := 2.0
var dmg := 10.0
var zasieg := 1.5
var zamach_dl := 0.5
var cd_max := 1.0
var postura := 1.0
var postura_max := 1.0
var postura_przerwa := 0.0
var stan := "patrol"
var cel_patrolu := Vector2.ZERO
var atak_timer := 0.0
var zamach := 0.0
var ogluszenie := 0.0
var cios_anim := 0.0
var krok_anim := 0.0
var trafiony := 0.0
var _ostatni_krok := 0.0
var _ruch_czas := -1.0

var sprite: Sprite2D
var nakladka: Node2D
var widoczny_dla_gracza := true
var uspiony := false  # pomijany przez AI (testy)
var tryb_3d := false  # wygląd rysuje swiat3d.gd; tu zostaje stan i nakładka


func ustaw(r: String, pozycja: Vector2, kat_start: float) -> void:
	rodzaj = r
	var t: Dictionary = TYPY[r]
	nazwa = t["nazwa"]
	boss = t.get("boss", false)
	ciezki = t.get("ciezki", false)
	w = pozycja
	cel_patrolu = pozycja
	kat = kat_start
	hp = t["hp"]
	hp_max = t["hp"]
	spd = t["spd"]
	dmg = t["dmg"]
	zasieg = t["zasieg"]
	zamach_dl = t["zamach"]
	cd_max = t["cd"]
	pancerz = t["pancerz"]
	postura = t["postura"]
	postura_max = t["postura"]
	promien = t["promien"]


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://zasoby/en_%s.webp" % rodzaj)
	sprite.hframes = 4
	sprite.vframes = 2
	var sk: float = TYPY[rodzaj]["skala"]
	sprite.scale = Vector2(sk, sk)
	var fh := 192.0 if boss else 128.0
	sprite.offset = Vector2(0, -(fh * 0.93 - fh * 0.5))
	add_child(sprite)
	sprite.visible = not tryb_3d
	# Paski, błysk i napisy rysujemy bez cieniowania, żeby były widoczne w mroku
	nakladka = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	nakladka.material = m
	nakladka.z_index = 40
	nakladka.draw.connect(_rysuj_nakladke)
	add_child(nakladka)


func _rysuj_nakladke() -> void:
	if hp <= 0.0 or not widoczny_dla_gracza:
		return
	var gora := -(152.0 if boss else 92.0)
	var t := Time.get_ticks_msec() / 1000.0
	var f := font()
	if zamach > 0.0:
		var puls := 0.55 + sin(t * 30.0) * 0.45
		var p := Vector2(-14.0 if sprite.flip_h else 14.0, -(110.0 if boss else 62.0))
		if boss:
			p.x *= 1.6
		var kol := Color(1.0, 0.24, 0.16, puls) if ciezki else Color(1.0, 0.84, 0.31, puls)
		nakladka.draw_circle(p, 7.0 + puls * 5.0, kol)
		var srodek := Color("ffd0c8") if ciezki else Color("fff9db")
		nakladka.draw_rect(Rect2(p.x - 10, p.y - 1, 20, 2), srodek)
		nakladka.draw_rect(Rect2(p.x - 1, p.y - 10, 2, 20), srodek)
	if ogluszenie > 0.0:
		nakladka.draw_string(f, Vector2(-45, gora - 8), "★ RIPOSTA! ★", HORIZONTAL_ALIGNMENT_CENTER, 90, 11, Color("ffd166"))
	var bw := 70.0 if boss else 30.0
	if hp < hp_max:
		nakladka.draw_rect(Rect2(-bw / 2, gora, bw, 4), Color(0.04, 0.03, 0.05, 0.85))
		nakladka.draw_rect(Rect2(-bw / 2, gora, bw * maxf(0.0, hp / hp_max), 4), Color("e06324") if boss else Color("c92a35"))
	if postura < postura_max and ogluszenie <= 0.0:
		nakladka.draw_rect(Rect2(-bw / 2, gora + 5, bw, 2), Color(0.04, 0.03, 0.05, 0.85))
		nakladka.draw_rect(Rect2(-bw / 2, gora + 5, bw * maxf(0.0, postura / postura_max), 2), Color("f2c14e"))
	if boss:
		nakladka.draw_string(f, Vector2(-80, gora - 10), "POPIELNY STRAŻNIK", HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color("f0b96e"))


static var _font: Font
static func font() -> Font:
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


func animuj(czas: float) -> void:
	position = Iso.ekran(w)
	if krok_anim != _ostatni_krok:
		_ostatni_krok = krok_anim
		_ruch_czas = czas
	var w_ruchu := czas - _ruch_czas < 0.15
	var klatka := 0
	if hp <= 0.0:
		klatka = 7
	elif zamach > 0.0:
		klatka = 4
	elif cios_anim > 0.0:
		klatka = 5 if cios_anim > 0.11 else 6
	elif w_ruchu:
		klatka = int(krok_anim) % 4
	sprite.frame = klatka
	sprite.flip_h = Iso.kierunek_arkusza(kat)["sdx"] < 0.0
	sprite.position.x = sin(czas * 40.0) * 2.0 if ogluszenie > 0.0 else 0.0
	sprite.modulate = Color(3, 3, 3) if trafiony > 0.0 else Color.WHITE
	nakladka.queue_redraw()
