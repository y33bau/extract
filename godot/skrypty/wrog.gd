extends Node2D
## Wróg: stan i wygląd. Zachowanie (AI, ciosy) liczy rajd.gd.

const Iso = preload("res://skrypty/iso.gd")
const Ui = preload("res://skrypty/ui.gd")

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


## Wysokość głowy modelu 3D (ekran, piksele świata przed zoomem) wg rodzaju — paski i znaki nad głową.
const WYS_GLOWY := {"scout": 84.0, "warden": 88.0, "archer": 84.0, "knight": 90.0, "brute": 100.0, "boss": 118.0}
var hp_cien := -1.0        # „cień” utraconego życia (dogania hp z opóźnieniem)
var _cien_przerwa := 0.0
var _alfa_paska := 0.0
var _ostatni_czas := -1.0


func _aktualizuj_nakladke(czas: float) -> void:
	var dt := 0.016 if _ostatni_czas < 0.0 else clampf(czas - _ostatni_czas, 0.0, 0.1)
	_ostatni_czas = czas
	if hp_cien < 0.0:
		hp_cien = hp
	if hp < hp_cien:
		if _cien_przerwa <= 0.0 and hp_cien >= hp_max - 0.01:
			_cien_przerwa = 0.45
		_cien_przerwa -= dt
		if _cien_przerwa <= 0.0:
			hp_cien = maxf(hp, hp_cien - hp_max * dt * 0.9)
	else:
		hp_cien = hp
		_cien_przerwa = 0.0
	var pokaz := hp > 0.0 and widoczny_dla_gracza and not boss and (hp < hp_max or postura < postura_max or stan == "walka")
	_alfa_paska = move_toward(_alfa_paska, 1.0 if pokaz else 0.0, dt * 6.0)


func _rysuj_nakladke() -> void:
	if hp <= 0.0 or not widoczny_dla_gracza:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var gora := -float(WYS_GLOWY.get(rodzaj, 88.0)) if tryb_3d else -(152.0 if boss else 92.0)
	if zamach > 0.0 and not tryb_3d:
		# stary wygląd 2D (w 3D zamach pokazują klin, pierścień rytmu i błysk broni)
		var puls := 0.55 + sin(t * 30.0) * 0.45
		var p := Vector2(-14.0 if sprite.flip_h else 14.0, -(110.0 if boss else 62.0))
		var kol := Color(1.0, 0.24, 0.16, puls) if ciezki else Color(1.0, 0.84, 0.31, puls)
		nakladka.draw_circle(p, 7.0 + puls * 5.0, kol)
	var bw := 46.0
	var a := _alfa_paska
	if a > 0.01:
		Ui.rysuj_pasek(nakladka, Rect2(-bw / 2.0, gora, bw, 5.0), hp / hp_max, hp_cien / hp_max, Color("c4252f"), a)
		# postura jak w Sekiro: pasek rośnie od środka, im bliżej złamania, tym goręcej i jaśniej
		var zuzyte := 1.0 - clampf(postura / postura_max, 0.0, 1.0)
		if zuzyte > 0.01 and ogluszenie <= 0.0:
			var szer := bw * zuzyte
			var kp := Color("f2c14e").lerp(Color("ff5a1f"), smoothstep(0.5, 1.0, zuzyte))
			if zuzyte > 0.75:
				kp = kp.lightened(0.25 * (0.5 + 0.5 * sin(t * 18.0)))
				nakladka.draw_rect(Rect2(-szer / 2.0 - 1.0, gora + 7.0, szer + 2.0, 4.0), Color(kp, 0.35 * a))
			nakladka.draw_rect(Rect2(-bw / 2.0, gora + 8.0, bw, 2.0), Color(0.05, 0.035, 0.04, 0.8 * a))
			nakladka.draw_rect(Rect2(-szer / 2.0, gora + 8.0, szer, 2.0), Color(kp, a))
	if ogluszenie > 0.0:
		# wróg odsłonięty: pulsujący złoty romb nad głową = czas na ripostę
		var puls2 := 0.5 + 0.5 * sin(t * 12.0)
		var c := Vector2(0.0, gora - 12.0 - puls2 * 2.0)
		var r := 6.0 + puls2 * 1.5
		var romb := PackedVector2Array([c + Vector2(0, -r * 1.35), c + Vector2(r, 0), c + Vector2(0, r * 1.35), c + Vector2(-r, 0)])
		var poswiata := PackedVector2Array()
		for v in romb:
			poswiata.append(c + (v - c) * 1.9)
		nakladka.draw_colored_polygon(poswiata, Color(1.0, 0.75, 0.25, 0.22 + 0.18 * puls2))
		nakladka.draw_colored_polygon(romb, Color("ffd166"))
		nakladka.draw_polyline(romb + PackedVector2Array([romb[0]]), Color("fff4cf"), 1.0)


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
	_aktualizuj_nakladke(czas)
	nakladka.queue_redraw()
