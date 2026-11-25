extends Node2D
## Cząsteczki (krew, iskry, żar) i unoszące się napisy. Współrzędne w świecie (pola).

const Iso = preload("res://skrypty/iso.gd")

var czastki: Array = []   # {w, z, v: Vector3, kolor, zycie, max, rozmiar}
var napisy: Array = []    # {w, tekst, kolor, rozmiar, zycie}
var napisy_wezel: Node2D


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
	for i in ile:
		var a := randf() * TAU
		var s := (0.35 + randf() * 0.75) * predkosc
		czastki.append({"w": w, "z": 0.45, "v": Vector3(cos(a) * s, sin(a) * s, 1.2 + randf() * 1.4),
			"kolor": kolor, "zycie": zycie * (0.65 + randf() * 0.45), "max": zycie, "rozmiar": 2 + randi() % 2})


func czastka(w: Vector2, z: float, v: Vector3, kolor: Color, zycie: float, rozmiar := 2) -> void:
	czastki.append({"w": w, "z": z, "v": v, "kolor": kolor, "zycie": zycie, "max": zycie, "rozmiar": rozmiar})


func napis(w: Vector2, tekst: String, kolor := Color.WHITE, rozmiar := 12) -> void:
	napisy.append({"w": w, "tekst": tekst, "kolor": kolor, "rozmiar": rozmiar, "zycie": 1.05})


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
		napisy[i]["w"] -= Vector2(0.32, 0.32) * dt
		if napisy[i]["zycie"] <= 0.0:
			napisy.remove_at(i)
		i -= 1
	queue_redraw()
	napisy_wezel.queue_redraw()


func _draw() -> void:
	for c in czastki:
		var p := Iso.ekran(c["w"])
		var k: Color = c["kolor"]
		k.a = clampf(c["zycie"] / c["max"], 0.0, 1.0)
		draw_rect(Rect2(roundf(p.x), roundf(p.y - c["z"] * 26.0), c["rozmiar"], c["rozmiar"]), k)


func _rysuj_napisy() -> void:
	var f := ThemeDB.fallback_font
	for n in napisy:
		var p := Iso.ekran(n["w"]) + Vector2(-120, -26)
		var a := minf(1.0, n["zycie"] * 1.4)
		var k: Color = n["kolor"]
		k.a = a
		napisy_wezel.draw_string_outline(f, p, n["tekst"], HORIZONTAL_ALIGNMENT_CENTER, 240, n["rozmiar"], 4, Color(0, 0, 0, a))
		napisy_wezel.draw_string(f, p, n["tekst"], HORIZONTAL_ALIGNMENT_CENTER, 240, n["rozmiar"], k)
