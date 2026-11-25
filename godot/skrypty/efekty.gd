extends Node2D
## Cząsteczki (krew, iskry, żar) i unoszące się napisy. Współrzędne w świecie (pola).

const Iso = preload("res://skrypty/iso.gd")
const Ui = preload("res://skrypty/ui.gd")

var czastki: Array = []   # {w, z, v: Vector3, kolor, zycie, max, rozmiar}
var napisy: Array = []    # {w, tekst, kolor, rozmiar, zycie}
var napisy_wezel: Node2D
var swiat3d = null        # gdy jest: większe wybuchy cząsteczek rysuje świat 3D (iskry, krople krwi)


func _ready() -> void:
	z_index = 30
	napisy_wezel = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	napisy_wezel.material = m
	napisy_wezel.z_index = 60
	napisy_wezel.draw.connect(_rysuj_napisy)
	add_child(napisy_wezel)


func czastki_dodaj(w: Vector2, ile: int, kolor: Color, predkosc := 2.6, zycie := 0.45) -> void:
	if swiat3d != null and ile >= 6:
		swiat3d.czastki(w, ile, kolor, predkosc, zycie)
		return
	for i in ile:
		var a := randf() * TAU
		var s := (0.35 + randf() * 0.75) * predkosc
		czastki.append({"w": w, "z": 0.45, "v": Vector3(cos(a) * s, sin(a) * s, 1.2 + randf() * 1.4),
			"kolor": kolor, "zycie": zycie * (0.65 + randf() * 0.45), "max": zycie, "rozmiar": 2 + randi() % 2})


func czastka(w: Vector2, z: float, v: Vector3, kolor: Color, zycie: float, rozmiar := 2) -> void:
	czastki.append({"w": w, "z": z, "v": v, "kolor": kolor, "zycie": zycie, "max": zycie, "rozmiar": rozmiar})


## Napis nad walką. Liczby (obrażenia, leczenie) są duże i „wyskakują”; komunikaty mniejsze i żyją dłużej.
## Napisy blisko siebie układają się jeden nad drugim, a ten sam napis nie dubluje się — odświeża się.
func napis(w: Vector2, tekst: String, kolor := Color.WHITE, rozmiar := 12) -> void:
	var liczba := _ma_cyfre(tekst) and tekst.length() <= 16
	for n in napisy:
		if not liczba and n["tekst"] == tekst and n["wiek"] < 0.6 and (n["w"] as Vector2).distance_to(w) < 1.5:
			n["wiek"] = 0.0
			n["zycie"] = n["max"]
			return
	# układanie na ekranie: napis, który wypadłby na inny świeży napis, idzie piętro wyżej
	var slot := 0
	var e := Iso.ekran(w)
	var zajete := {}
	for n in napisy:
		var d := Iso.ekran(n["w"]) - e
		if n["wiek"] < 0.7 and absf(d.x) < 170.0 and absf(d.y) < 34.0:
			zajete[int(n["slot"])] = true
	while zajete.has(slot):
		slot += 1
	var dl := 0.9 if liczba else 1.15
	napisy.append({"w": w, "tekst": tekst, "kolor": kolor, "rozmiar": rozmiar, "zycie": dl, "max": dl, "wiek": 0.0,
		"liczba": liczba, "slot": mini(slot, 5), "dryf": randf_range(-14.0, 14.0)})


static func _ma_cyfre(t: String) -> bool:
	for c in t:
		if c >= "0" and c <= "9":
			return true
	return false


func aktualizuj(dt: float) -> void:
	var i := czastki.size() - 1
	while i >= 0:
		var c: Dictionary = czastki[i]
		c["zycie"] -= dt
		if c["zycie"] <= 0.0:
			czastki.remove_at(i)
		else:
			var v: Vector3 = c["v"]
			c["w"] += Vector2(v.x, v.y) * dt
			c["z"] = maxf(0.0, c["z"] + v.z * dt)
			v.z -= 4.5 * dt
			c["v"] = v
		i -= 1
	i = napisy.size() - 1
	while i >= 0:
		napisy[i]["zycie"] -= dt
		napisy[i]["wiek"] += dt
		if napisy[i]["zycie"] <= 0.0:
			napisy.remove_at(i)
		i -= 1
	queue_redraw()
	napisy_wezel.queue_redraw()


func _draw() -> void:
	# miękkie kropki zamiast kwadratowych pikseli; jasne (iskry, żar) z poświatą
	for c in czastki:
		var p := Iso.ekran(c["w"])
		var k: Color = c["kolor"]
		var a := clampf(c["zycie"] / c["max"], 0.0, 1.0)
		var pp := Vector2(p.x, p.y - c["z"] * 26.0)
		var r: float = float(c["rozmiar"]) * 0.6
		if k.get_luminance() > 0.45:
			draw_circle(pp, r * 2.6, Color(k, a * 0.18))
		draw_circle(pp, r, Color(k, a))


func _rysuj_napisy() -> void:
	for n in napisy:
		var wiek: float = n["wiek"]
		var liczba: bool = n["liczba"]
		var f := Ui.czcionka(800 if liczba else 700)
		var rozm := int(float(n["rozmiar"]) * (1.3 if liczba else 0.95))
		# wyskok: start powiększony, szybko do 1; potem spokojne unoszenie z lekkim dryfem
		var skala := 1.0 + (0.7 if liczba else 0.25) * exp(-wiek * 16.0)
		var unos := 1.0 - exp(-wiek * 3.2)
		var off := Vector2(float(n["dryf"]) * unos, -12.0 - 34.0 * unos - float(n["slot"]) * 24.0)
		var p := Iso.ekran(n["w"]) + Vector2(0, -40) + off
		var a := clampf(n["zycie"] / (float(n["max"]) * 0.35), 0.0, 1.0)
		var k: Color = n["kolor"]
		napisy_wezel.draw_set_transform(p, 0.0, Vector2(skala, skala))
		napisy_wezel.draw_string_outline(f, Vector2(-160, 2), n["tekst"], HORIZONTAL_ALIGNMENT_CENTER, 320, rozm, 7, Color(0, 0, 0, 0.55 * a))
		napisy_wezel.draw_string_outline(f, Vector2(-160, 0), n["tekst"], HORIZONTAL_ALIGNMENT_CENTER, 320, rozm, 4, Color(0.08, 0.03, 0.02, a))
		napisy_wezel.draw_string(f, Vector2(-160, 0), n["tekst"], HORIZONTAL_ALIGNMENT_CENTER, 320, rozm, Color(k, a))
	napisy_wezel.draw_set_transform(Vector2.ZERO)
