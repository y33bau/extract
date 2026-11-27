extends Node3D
## Warownia-Przystań (projekt: docs/WAROWNIA_PRZYSTAN.md): miejsce startowe w 3D, po którym Hadræn chodzi swobodnie.
## NPC i miejsca obozu otwierają zakładki Warowni (hub.gd), gawędziarz mówi w dymku. Bez walki.
## Układ: świat (x, z) w metrach; kamera izometryczna jak w rajdzie. Ląd x, z w [LAD_OD, ROZMIAR], woda za nim.

signal otworz(zakladka: int)  # 0 Wyprawa, 1 Ekwipunek i Skrytka, 2 Kupiec, 3 Warownia, 4 Umiejętności

const WygladPostaci = preload("res://skrypty/wyglad_postaci.gd")
const Iso = preload("res://skrypty/iso.gd")
const Bohater = preload("res://skrypty/bohater.gd")
const WygladRynsztunku = preload("res://skrypty/wyglad_rynsztunku.gd")
const SHADER_TERENU := preload("res://zasoby/3d/shadery/teren.gdshader")
const SHADER_MURU := preload("res://zasoby/3d/shadery/mur.gdshader")
const SHADER_MGLY := preload("res://zasoby/3d/shadery/mgla.gdshader")
const PX_NA_M := 45.254834
const ZOOM := 1.35  # 26.11.2026 autor: w Warowni postacie mniejsze / kamera dalej (było 1.85); rajd bez zmian
const ROZMIAR := 32.0
const LAD_OD := 6.0
const P := "res://zasoby/3d/przystan/"
const R := "res://zasoby/3d/rekwizyty/"
const ZESTAW_ANIM := {"dwureczny": "dwureczny", "glewia": "dwureczny", "topor": "topor",
	"miecz": "miecz", "miecz_tarcza": "miecz", "piesci": "piesci"}

## Miejsca interakcji: [nazwa wyświetlana, zakładka (-1 = dymek), pozycja (x, z)].
const MIEJSCA := {
	"marga": ["Marga — handel", 2, Vector2(11.0, 13.0)],
	"chojrak": ["Chojrak — kontrakty i wyprawy", 0, Vector2(12.6, 8.4)],
	"przewoznik": ["Przewoźnik — wypłyń na wyprawę", 0, Vector2(10.1, 1.4)],
	"chlop": ["Gawędziarz przy ognisku", -1, Vector2(20.4, 17.4)],
	"kuznia": ["Kuźnia — rozbudowa obozu", 3, Vector2(25.5, 12.5)],
	"zielarnia": ["Zielarnia — rozbudowa obozu", 3, Vector2(12.5, 24.5)],
	"oltarz": ["Ołtarz Żaru — umiejętności", 4, Vector2(19.0, 27.0)],
	"namiot": ["Namiot Hadræna — ekwipunek", 1, Vector2(26.0, 22.0)],
	"skrytka": ["Skrytka — ekwipunek i Relikwiarz", 1, Vector2(28.5, 27.0)],
}
const KWESTIE := [
	"Woda tu czarna, bo pamięta pożar. Nie pij z niej, panie.",
	"Kat Ruin nie paruje się jak zwykły trup. Czerwony błysk — uciekaj albo przetocz się.",
	"Pochodnia w ręce to światło, ale tarcza wtedy śpi. Rzuć ją, zanim zacznie się taniec.",
	"Marga skupuje kości. Nie pytaj czyje.",
	"Chojrak był kiedyś paladynem. Teraz liczy łodzie, które nie wróciły.",
	"W Krypcie żar oddycha pod płytami. Słuchaj, zanim zrobisz krok.",
	"Kto wraca z pełną sakwą, ten śpi spokojnie. Kto nie wraca — nie śpi wcale.",
	"Złoty błysk na ostrzu wroga to zaproszenie. Odpowiedz parowaniem.",
]

var kamera: Camera3D
var bohater: Node3D
var _ap: AnimationPlayer
var _wyglad_rynsztunku := WygladRynsztunku.new()
var _styl := "miecz"
var poz := Vector2(18.0, 22.0)
var kat := 2.4
var _kat_wiz := 2.4
var aktywna := true
var lekki := false
var _npc := {}            # nazwa -> {wezel, ap}
var _przeszkody: Array = []  # [Vector2 środek, promień]
var _etykieta: Label3D
var _dymek: Label3D
var _dymek_czas := 0.0
var _kwestia := 0
var cel := ""             # najbliższe miejsce interakcji
var _anim := ""
var _szum: Texture2D
var _pyl: GPUParticles3D
var _popiol: GPUParticles3D
var _budynki: Node3D
var _przeszkody_bud: Array = []
var poziomy := {}         # budynek -> poziom pokazany na scenie (do testów)


func _ready() -> void:
	lekki = "--test" in OS.get_cmdline_user_args() and not "--pelna" in OS.get_cmdline_user_args()
	_srodowisko()
	_kamera()
	_teren()
	_pomost()
	_oboz()
	_zakatki()
	_drugi_brzeg()
	_za_palisada()
	_npc_wszyscy()
	_bohater()
	_atmosfera()
	_etykieta = _label(44, Color(1.0, 0.86, 0.6))
	_dymek = _label(38, Color(0.92, 0.9, 0.86))
	_dymek.width = 700.0
	if not lekki:
		var w := CanvasLayer.new()
		w.layer = -100
		var r := ColorRect.new()
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = preload("res://zasoby/3d/shadery/wyostrz.gdshader")
		m.set_shader_parameter("sila", 0.5)
		r.material = m
		w.add_child(r)
		add_child(w)
	_dymek.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# ---------------------------------------------------------------- BUDOWA SCENY
func _srodowisko() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.008, 0.01, 0.016)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.36, 0.37, 0.46)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC  # AgX odbarwiał postacie
	e.tonemap_exposure = 1.0
	e.glow_enabled = not lekki
	e.glow_intensity = 0.9
	e.glow_hdr_threshold = 1.1
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.ssao_enabled = not lekki
	e.ssao_radius = 1.4
	e.ssr_enabled = not lekki
	e.ssr_max_steps = 48
	e.fog_enabled = not lekki
	e.fog_light_color = Color(0.06, 0.07, 0.09)
	e.fog_density = 0.006
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.1
	e.adjustment_saturation = 1.08
	we.environment = e
	add_child(we)
	var ksiezyc := DirectionalLight3D.new()
	ksiezyc.light_color = Color(0.58, 0.68, 1.0)
	ksiezyc.light_energy = 0.7
	ksiezyc.shadow_enabled = not lekki
	ksiezyc.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	ksiezyc.directional_shadow_max_distance = 40.0
	add_child(ksiezyc)
	ksiezyc.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -1.0, -0.75), Vector3.UP)


func _kamera() -> void:
	kamera = Camera3D.new()
	kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
	kamera.keep_aspect = Camera3D.KEEP_HEIGHT
	kamera.near = 0.5
	kamera.far = 120.0
	add_child(kamera)
	kamera.current = true
	_ustaw_kamere()


func _ustaw_kamere() -> void:
	var c := Vector3(poz.x, 0.0, poz.y)
	var kier := Vector3(cos(deg_to_rad(30.0)) / sqrt(2.0), sin(deg_to_rad(30.0)), cos(deg_to_rad(30.0)) / sqrt(2.0))
	kamera.position = c + kier * 40.0
	kamera.look_at(c, Vector3.UP)
	kamera.size = get_viewport().get_visible_rect().size.y / (PX_NA_M * ZOOM)


func _tsw(nazwa: String, rodzaj: String) -> Texture2D:
	return load("res://zasoby/3d/swiat/%s_%s" % [nazwa, "albedo.jpg" if rodzaj == "alb" else rodzaj + ".png"])


func _teren() -> void:
	_szum = _tekstura_szumu()
	var czarna := Image.create(4, 4, false, Image.FORMAT_RGB8)
	var t := ShaderMaterial.new()
	t.shader = SHADER_TERENU
	for war in [["a", "pod_bruk", 0.3], ["b", "pod_ziemia", 0.2], ["c", "pod_trawa", 0.3]]:
		t.set_shader_parameter(war[0] + "_alb", _tsw(war[1], "alb"))
		t.set_shader_parameter(war[0] + "_nrm", _tsw(war[1], "normal"))
		t.set_shader_parameter(war[0] + "_rh", _tsw(war[1], "rh"))
		t.set_shader_parameter(war[0] + "_skala", war[2])
	t.set_shader_parameter("szum", _szum)
	t.set_shader_parameter("maska_mapy", ImageTexture.create_from_image(czarna))
	t.set_shader_parameter("b_ilosc", 0.45)
	t.set_shader_parameter("c_ilosc", 0.35)
	t.set_shader_parameter("kaluze", 0.35)
	t.set_shader_parameter("ton", Color(0.92, 0.92, 0.96))
	var lad := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ROZMIAR - LAD_OD, ROZMIAR - LAD_OD)
	lad.mesh = pm
	lad.material_override = t
	lad.position = Vector3((ROZMIAR + LAD_OD) * 0.5, 0.0, (ROZMIAR + LAD_OD) * 0.5)
	add_child(lad)
	# nabrzeże z kamienia od strony wody
	var m := ShaderMaterial.new()
	m.shader = SHADER_MURU
	m.set_shader_parameter("m_alb", _tsw("pod_mur", "alb"))
	m.set_shader_parameter("m_nrm", _tsw("pod_mur", "normal"))
	m.set_shader_parameter("m_rh", _tsw("pod_mur", "rh"))
	m.set_shader_parameter("d_alb", _tsw("kat_mech", "alb"))
	m.set_shader_parameter("szum", _szum)
	m.set_shader_parameter("skala", 0.45)
	m.set_shader_parameter("wys_akcentu", 0.2)
	for bok in [[Vector3(LAD_OD - 0.3, -0.25, (ROZMIAR + LAD_OD) * 0.5), Vector3(0.6, 0.6, ROZMIAR - LAD_OD + 0.6)],
			[Vector3((ROZMIAR + LAD_OD) * 0.5, -0.25, LAD_OD - 0.3), Vector3(ROZMIAR - LAD_OD + 0.6, 0.6, 0.6)]]:
		var nb := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = bok[1]
		nb.mesh = bm
		nb.material_override = m
		nb.position = bok[0]
		add_child(nb)
	# czarna woda: gładka, odbija ogniska (SSR)
	var woda := MeshInstance3D.new()
	var wm := PlaneMesh.new()
	wm.size = Vector2(90, 90)
	woda.mesh = wm
	var wmat := ShaderMaterial.new()
	wmat.shader = preload("res://zasoby/3d/shadery/woda.gdshader")
	wmat.set_shader_parameter("szum", _szum)
	woda.material_override = wmat
	woda.position = Vector3(ROZMIAR * 0.5, -0.42, ROZMIAR * 0.5)
	add_child(woda)


func _drewno() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tsw("drewno", "alb")
	m.normal_enabled = true
	m.normal_texture = _tsw("drewno", "normal")
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.7, 0.7, 0.7)
	m.roughness = 0.9
	return m


func _pomost() -> void:
	var d := _drewno()
	var pomost := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.2, 0.16, 7.0)
	pomost.mesh = bm
	pomost.material_override = d
	pomost.position = Vector3(10.1, -0.02, 3.4)
	add_child(pomost)
	for z in [0.4, 2.4, 4.4, 6.4]:
		for x in [9.1, 11.1]:
			var pal := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.11
			cm.bottom_radius = 0.13
			cm.height = 1.6
			pal.mesh = cm
			pal.material_override = d
			pal.position = Vector3(x, -0.3, z)
			add_child(pal)
	# łódź przewoźnika przy końcu pomostu (model Meshy; zapasowo prosta bryła)
	if ResourceLoader.exists(P + "lodz.glb"):
		var lodz_m := _rek(P + "lodz.glb", 2.0, Vector2(12.0, 1.3), 1.57)
		lodz_m.position.y -= 0.55
		# latarnia łodzi — żeby łódź nie ginęła w czarnej wodzie
		var sw := OmniLight3D.new()
		sw.light_color = Color(1.0, 0.62, 0.3)
		sw.light_energy = 1.6
		sw.omni_range = 3.2
		sw.position = Vector3(12.2, 1.1, 1.3)
		add_child(sw)
	else:
		var lodz := MeshInstance3D.new()
		var kap := CapsuleMesh.new()
		kap.radius = 0.55
		kap.height = 3.4
		lodz.mesh = kap
		lodz.material_override = d
		lodz.scale = Vector3(1.0, 0.45, 1.0)
		lodz.rotation_degrees = Vector3(90, 0, 0)
		lodz.position = Vector3(12.2, -0.38, 1.4)
		add_child(lodz)
	_rek(P + "rune_lantern.glb", 1.3, Vector2(11.0, 6.6), 0.0)
	_latarnia(Vector2(11.0, 6.6), 1.2, Color(0.55, 0.8, 1.0))
	_przeszkody.append([Vector2(11.0, 6.6), 0.35])


## Rekwizyt autora: skala do wysokości, stopa na ziemi, cienie, przeszkoda dla ruchu.
func _rek(sc: String, wys: float, w: Vector2, obrot: float, przeszkoda := 0.0) -> Node3D:
	var n: Node3D = (load(sc) as PackedScene).instantiate()
	add_child(n)
	var ab := AABB()
	var pierwszy := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var a := (n.global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
		ab = a if pierwszy else ab.merge(a)
		pierwszy = false
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var s := wys / maxf(ab.size.y, 0.01)
	n.scale = Vector3.ONE * s
	n.position = Vector3(w.x, -ab.position.y * s, w.y)
	n.rotation.y = obrot
	if przeszkoda > 0.0:
		_przeszkody.append([w, przeszkoda])
	return n


func _swiatlo(kolor: Color, energia: float, zasieg: float, cien := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = kolor
	l.light_energy = energia
	l.omni_range = zasieg
	l.shadow_enabled = cien and not lekki
	l.set_meta("migotanie", true)
	return l


func _latarnia(w: Vector2, wys: float, kolor := Color(1.0, 0.7, 0.42)) -> void:
	var l := _swiatlo(kolor, 2.2, 6.0, false)
	l.position = Vector3(w.x, wys, w.y)
	add_child(l)


func _oboz() -> void:
	# ognisko: serce obozu
	_rek(P + "firewood.glb", 0.55, Vector2(19.0, 19.0), 0.3, 0.9)
	var ogien := _ogien(2.0, 2.2)
	ogien.position = Vector3(19.0, 0.35, 19.0)
	add_child(ogien)
	var l := _swiatlo(Color(1.0, 0.6, 0.3), 5.5, 11.0)
	l.position = Vector3(19.0, 1.4, 19.0)
	add_child(l)
	for i in 7:
		var a := TAU * i / 7.0
		var k := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.2
		sm.height = 0.24
		k.mesh = sm
		k.material_override = _drewno()
		k.position = Vector3(19.0 + cos(a) * 0.85, 0.06, 19.0 + sin(a) * 0.85)
		add_child(k)
	_rek(P + "bench_b.glb", 0.55, Vector2(17.0, 20.2), 0.9, 0.6)
	_rek(P + "bench_b.glb", 0.55, Vector2(20.8, 21.0), -0.6, 0.6)
	# kupiec Marga: wóz, waga, szyld
	_rek(P + "marga_cart.glb", 1.8, Vector2(9.0, 14.2), 0.4, 1.3)
	_rek(P + "scale.glb", 1.1, Vector2(12.4, 14.4), 0.0, 0.4)
	_rek(P + "shop_sign.glb", 2.2, Vector2(12.8, 11.6), 0.8, 0.3)
	_latarnia(Vector2(11.5, 12.6), 1.8)
	# stół wypraw Chojraka przy pomoście
	_rek(P + "lectern.glb", 1.2, Vector2(13.8, 8.0), -0.6, 0.45)
	_rek(P + "order_banner.glb", 2.6, Vector2(14.6, 7.0), 0.2, 0.3)
	_budynki = Node3D.new()
	add_child(_budynki)
	odswiez_budynki()
	# namiot i skrytka
	_rek(P + "tent.glb", 2.3, Vector2(27.5, 20.5), -2.2, 1.4)
	_rek(P + "pelts.glb", 0.9, Vector2(25.2, 23.6), 0.4, 0.5)
	# niska palisada od strony lądu (zaostrzone pale)
	var d := _drewno()
	for i in int((ROZMIAR - LAD_OD) / 0.36):
		for bok in 2:
			var t := LAD_OD + 0.2 + i * 0.36
			var pal := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = 0.16
			var h := 1.1 + float((i * 7 + bok * 3) % 5) * 0.08
			cm.height = h
			cm.radial_segments = 8
			pal.mesh = cm
			pal.material_override = d
			pal.position = Vector3(ROZMIAR - 0.15, h * 0.5, t) if bok == 0 else Vector3(t, h * 0.5, ROZMIAR - 0.15)
			add_child(pal)
	# reszta: studnia, latarnie, sztandar
	_rek(P + "well.glb", 1.8, Vector2(15.0, 16.0), 0.0, 0.9)
	_rek(P + "clan_banner.glb", 2.8, Vector2(22.5, 15.0), 0.3, 0.3)
	for w in [Vector2(16.0, 10.0), Vector2(23.5, 25.0), Vector2(8.0, 20.0)]:
		_rek(P + "street_lantern.glb", 2.6, w, 0.0, 0.25)
		_latarnia(w + Vector2(0.15, 0.15), 2.3)


## Zakątki placu (tylko wygląd + przeszkody): beczki przy wodzie, opał, cmentarzyk tych, co nie wrócili,
## kandelabr i kości przy ołtarzu, ławka przy studni, zbroja na stojaku u Chojraka.
func _zakatki() -> void:
	for d in [[R + "beczka.glb", 0.95, Vector2(8.0, 9.4), 0.2, 0.4], [R + "beczka.glb", 0.95, Vector2(8.8, 10.3), 1.1, 0.4],
			[R + "kufer.glb", 0.7, Vector2(9.4, 8.9), 0.7, 0.45], [P + "firewood.glb", 0.5, Vector2(29.8, 15.6), 1.2, 0.6],
			[R + "beczka.glb", 0.95, Vector2(30.6, 17.1), 0.0, 0.4], [R + "glaz.glb", 0.7, Vector2(7.2, 29.6), 0.5, 0.6],
			[R + "glaz.glb", 0.55, Vector2(30.9, 30.7), 2.0, 0.5], [R + "kosci.glb", 0.35, Vector2(16.9, 29.7), 0.8, 0.0],
			[P + "bench_b.glb", 0.55, Vector2(13.4, 17.6), 0.2, 0.5], [R + "zbroja.glb", 1.6, Vector2(15.9, 9.7), -0.7, 0.4]]:
		_rek(d[0], d[1], d[2], d[3], d[4])
	# cmentarzyk: groby tych, którzy nie wrócili, z runiczną latarnią
	for i in 4:
		_rek(R + "nagrobek.glb", 0.8 + (i % 2) * 0.12, Vector2(22.4 + i * 1.15, 30.0 + (i % 2) * 0.35), 0.1 * (i - 2), 0.35)
	_rek(P + "rune_lantern.glb", 1.3, Vector2(21.2, 29.2), 0.0, 0.3)
	var lr := _swiatlo(Color(0.55, 0.75, 1.0), 1.2, 4.0, false)
	lr.position = Vector3(21.2, 1.1, 29.2)
	lr.set_meta("migotanie", true)
	add_child(lr)
	# kandelabr przy ołtarzu
	_rek(R + "kandelabr.glb", 1.25, Vector2(16.6, 27.9), 0.3, 0.3)
	_latarnia(Vector2(16.6, 27.9), 1.3)


## Drugi brzeg za czarną wodą: sylwetki spalonej warowni (mury z blankami, wieże) i dogasające pożary.
## Poza zasięgiem ruchu; daje głębię i punkt orientacyjny przy pomoście.
func _drugi_brzeg() -> void:
	var m := ShaderMaterial.new()
	m.shader = SHADER_MURU
	m.set_shader_parameter("m_alb", _tsw("pod_mur", "alb"))
	m.set_shader_parameter("m_nrm", _tsw("pod_mur", "normal"))
	m.set_shader_parameter("m_rh", _tsw("pod_mur", "rh"))
	m.set_shader_parameter("d_alb", _tsw("kat_mech", "alb"))
	m.set_shader_parameter("szum", _szum)
	m.set_shader_parameter("skala", 0.35)
	m.set_shader_parameter("wys_akcentu", 0.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	var odcinki := [[Vector2(-9.0, -6.5), Vector2(36.0, -6.5)], [Vector2(-6.5, -9.0), Vector2(-6.5, 36.0)]]
	for od in odcinki:
		var a: Vector2 = od[0]
		var b: Vector2 = od[1]
		var dl := a.distance_to(b)
		var kier := (b - a).normalized()
		var t := 0.0
		while t < dl:
			var seg := rng.randf_range(3.0, 6.0)
			var w := a + kier * (t + seg * 0.5)
			var wys := rng.randf_range(2.5, 5.5)
			if rng.randf() < 0.22:
				wys = rng.randf_range(0.8, 1.6)  # wyłom
			var blok := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(seg if kier.x != 0.0 else 1.6, wys, seg if kier.y != 0.0 else 1.6)
			blok.mesh = bm
			blok.material_override = m
			blok.position = Vector3(w.x, wys * 0.5 - 0.4, w.y)
			add_child(blok)
			# blanki
			if wys > 2.0:
				var n := int(seg / 0.9)
				for i in n:
					if rng.randf() < 0.3:
						continue
					var bl := MeshInstance3D.new()
					var bb := BoxMesh.new()
					bb.size = Vector3(0.5, 0.55, 0.5)
					bl.mesh = bb
					bl.material_override = m
					var q := a + kier * (t + 0.45 + i * 0.9)
					bl.position = Vector3(q.x, wys - 0.4 + 0.27, q.y)
					add_child(bl)
			t += seg
	# wieże
	for wz in [Vector2(-6.5, -6.5), Vector2(5.0, -6.5), Vector2(20.0, -6.5), Vector2(-6.5, 12.0), Vector2(-6.5, 27.0)]:
		var wie := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var h := rng.randf_range(6.0, 9.0)
		cm.top_radius = 1.7
		cm.bottom_radius = 2.1
		cm.height = h
		wie.mesh = cm
		wie.material_override = m
		wie.position = Vector3(wz.x, h * 0.5 - 0.4, wz.y)
		add_child(wie)
		# dogasający pożar na szczycie albo w oknie
		if rng.randf() < 0.7:
			var og := _ogien(1.2, 1.6)
			og.position = Vector3(wz.x, h - 0.2, wz.y)
			add_child(og)
			var l := _swiatlo(Color(1.0, 0.45, 0.15), 3.0, 9.0, false)
			l.position = Vector3(wz.x + 1.5, h - 0.5, wz.y + 1.5)
			l.set_meta("migotanie", true)
			add_child(l)


## Za palisadą: ziemia ciągnie się dalej (zamiast czarnej pustki), głazy i zwalone kolumny we mgle.
func _za_palisada() -> void:
	var t := ShaderMaterial.new()
	t.shader = SHADER_TERENU
	for war in [["a", "pod_ziemia", 0.25], ["b", "pod_trawa", 0.25], ["c", "pod_bruk", 0.3]]:
		t.set_shader_parameter(war[0] + "_alb", _tsw(war[1], "alb"))
		t.set_shader_parameter(war[0] + "_nrm", _tsw(war[1], "normal"))
		t.set_shader_parameter(war[0] + "_rh", _tsw(war[1], "rh"))
		t.set_shader_parameter(war[0] + "_skala", war[2])
	t.set_shader_parameter("szum", _szum)
	t.set_shader_parameter("maska_mapy", ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGB8)))
	t.set_shader_parameter("b_ilosc", 0.6)
	t.set_shader_parameter("c_ilosc", 0.1)
	t.set_shader_parameter("kaluze", 0.2)
	t.set_shader_parameter("ton", Color(0.8, 0.8, 0.86))
	for pas in [[Vector3(ROZMIAR + 9.0, -0.01, (ROZMIAR + LAD_OD) * 0.5 + 9.0), Vector2(18.0, ROZMIAR - LAD_OD + 18.0)],
			[Vector3((ROZMIAR + LAD_OD) * 0.5, -0.01, ROZMIAR + 9.0), Vector2(ROZMIAR - LAD_OD, 18.0)]]:
		var z := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = pas[1]
		z.mesh = pm
		z.material_override = t
		z.position = pas[0]
		add_child(z)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 14:
		var w := Vector2(rng.randf_range(ROZMIAR + 1.2, ROZMIAR + 8.0), rng.randf_range(LAD_OD, ROZMIAR + 8.0))
		if i % 2 == 0:
			w = Vector2(w.y, w.x)
		var nazwa: String = ["glaz", "kolumna_lezaca", "glaz", "nagrobek"][i % 4]
		_rek(R + nazwa + ".glb", rng.randf_range(0.5, 1.0), w, rng.randf() * TAU, 0.0)


## Budynki obozu rosną z poziomem z Warowni (Profil.budynek): 0 = puste miejsce, 1–3 = coraz więcej i jaśniej.
## Wywoływane przy starcie i po zamknięciu menu (np. po rozbudowie).
func odswiez_budynki() -> void:
	for pr in _przeszkody_bud:
		_przeszkody.erase(pr)
	_przeszkody_bud.clear()
	for c in _budynki.get_children():
		c.queue_free()
	var kont := _budynki
	var dodaj := func(sc: String, wys: float, w: Vector2, obr: float, prz: float) -> void:
		var n := _rek(sc, wys, w, obr, 0.0)
		n.reparent(kont)
		if prz > 0.0:
			var pr := [w, prz]
			_przeszkody.append(pr)
			_przeszkody_bud.append(pr)
	var swiatlo := func(kol: Color, e: float, z: float, w: Vector3) -> void:
		var l := _swiatlo(kol, e, z)
		l.position = w
		kont.add_child(l)
	var plac := func(w: Vector2) -> void:  # pusty plac budowy: krąg kamieni i pal z szarfą
		for i in 6:
			var a := TAU * i / 6.0
			var k := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.16
			sm.height = 0.18
			k.mesh = sm
			k.material_override = _drewno()
			k.position = Vector3(w.x + cos(a) * 1.0, 0.05, w.y + sin(a) * 1.0)
			kont.add_child(k)
	# Kuźnia
	var lk: int = Profil.budynek("forge")
	poziomy["forge"] = lk
	dodaj.call(P + "pickaxe_rack.glb", 1.5, Vector2(27.6, 13.8), -0.8, 0.5)
	if lk == 0:
		plac.call(Vector2(25.5, 11.5))
	if lk >= 1:
		dodaj.call(P + "anvil.glb", 0.8, Vector2(25.0, 11.0), 0.5, 0.6)
		swiatlo.call(Color(1.0, 0.5, 0.2), 1.6, 4.5, Vector3(25.5, 1.0, 11.5))
	if lk >= 2:
		dodaj.call(P + "bellows.glb", 1.0, Vector2(27.2, 11.2), 0.0, 0.6)
		var og := _ogien(1.0, 1.0)
		og.position = Vector3(27.2, 0.9, 11.2)
		kont.add_child(og)
		swiatlo.call(Color(1.0, 0.45, 0.15), 3.2, 6.5, Vector3(27.0, 1.0, 11.4))
	if lk >= 3:
		dodaj.call(P + "clan_banner.glb", 2.8, Vector2(28.6, 9.6), -0.4, 0.3)
		dodaj.call(R + "zbroja.glb", 1.6, Vector2(23.4, 10.2), 0.6, 0.4)
	# Zielarnia (Alchemik)
	var la: int = Profil.budynek("alchemist")
	poziomy["alchemist"] = la
	if la == 0:
		plac.call(Vector2(11.5, 25.5))
	if la >= 1:
		dodaj.call(P + "desk.glb", 1.0, Vector2(11.5, 26.0), 0.9, 0.8)
		swiatlo.call(Color(0.7, 1.0, 0.6), 1.4, 4.0, Vector3(12.0, 1.6, 23.0))
	if la >= 2:
		dodaj.call(P + "bookcase_a.glb", 2.0, Vector2(9.6, 24.0), 1.57, 0.6)
	if la >= 3:
		dodaj.call(P + "lectern.glb", 1.2, Vector2(13.6, 27.0), 0.3, 0.45)
		swiatlo.call(Color(0.6, 1.0, 0.55), 2.6, 6.0, Vector3(11.5, 1.8, 25.5))
	# Ołtarz Żaru
	var lo: int = Profil.budynek("altar")
	poziomy["altar"] = lo
	dodaj.call(P + "idol.glb", 2.2, Vector2(18.0, 28.6), 0.0, 0.6)
	if lo >= 1:
		dodaj.call(R + "misa_zar.glb", 1.0, Vector2(20.0, 28.0), 0.0, 0.5)
		var og2 := _ogien(0.8 + lo * 0.4, 1.0 + lo * 0.3)
		og2.position = Vector3(20.0, 1.0, 28.0)
		kont.add_child(og2)
		swiatlo.call(Color(1.0, 0.5, 0.2), 1.6 + lo * 0.9, 4.5 + lo, Vector3(20.0, 1.5, 28.0))
	if lo >= 3:
		dodaj.call(P + "order_banner.glb", 2.6, Vector2(16.4, 27.6), 0.4, 0.3)
	# Skarbiec / Skrytka
	var lv: int = Profil.budynek("vault")
	poziomy["vault"] = lv
	if lv == 0:
		dodaj.call(R + "kufer.glb", 0.7, Vector2(29.0, 27.6), -0.8, 0.6)
	if lv >= 1:
		dodaj.call(P + "vault.glb", 1.6, Vector2(29.4, 27.8), -0.8, 0.9)
	if lv >= 2:
		dodaj.call(R + "kufer.glb", 0.7, Vector2(27.4, 29.4), 0.3, 0.5)
		dodaj.call(R + "beczka.glb", 0.95, Vector2(30.4, 25.6), 0.0, 0.4)
	if lv >= 3:
		dodaj.call(P + "street_lantern.glb", 2.6, Vector2(27.0, 26.0), 0.0, 0.25)
		swiatlo.call(Color(1.0, 0.75, 0.45), 2.2, 6.0, Vector3(27.1, 2.3, 26.1))


func _npc_wszyscy() -> void:
	var lista := [["marga", "npc_marga", Vector2(11.0, 13.0), "postoj"], ["chojrak", "npc_chojrak", Vector2(12.6, 8.4), "postoj"],
			["chlop", "npc_chlop", Vector2(20.4, 17.4), "postoj"]]
	if ResourceLoader.exists("res://zasoby/3d/postacie/npc_przewoznik.glb"):
		lista.append(["przewoznik", "npc_przewoznik", Vector2(10.1, 1.4), "postoj"])
	for d in lista:
		var n: Node3D = (load("res://zasoby/3d/postacie/%s.glb" % d[1]) as PackedScene).instantiate()
		add_child(n)
		n.position = Vector3(d[2].x, 0.0, d[2].y)
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		for a in ap.get_animation_list():
			ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		ap.play(d[3] if ap.has_animation(d[3]) else "postoj")
		ap.seek(randf() * ap.current_animation_length, true)
		WygladPostaci.ozyw(n)
		WygladPostaci.swiatlo_postaci(n)
		_npc[d[0]] = {"wezel": n, "ap": ap, "zmiana": 6.0 + randf() * 8.0}
		_przeszkody.append([d[2], 0.45])
	# gawędziarz patrzy w ogień
	(_npc["chlop"]["wezel"] as Node3D).rotation.y = atan2(19.0 - 20.4, 19.0 - 17.4)


func _bohater() -> void:
	bohater = (load(WygladRynsztunku.SCENA) as PackedScene).instantiate()
	add_child(bohater)
	_ap = bohater.find_child("AnimationPlayer", true, false)
	for a in _ap.get_animation_list():
		_ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	var zestaw: String = Bohater.zestaw_dla(Profil.d["loadout"])
	_styl = ZESTAW_ANIM.get(zestaw, "dwureczny")
	for nazwa in ["bron_dwureczny", "bron_glewia", "bron_topor", "bron_miecz", "bron_tarcza", "bron_pochodnia"]:
		var b: Node3D = bohater.find_child(nazwa, true, false)
		if b:
			match nazwa:
				"bron_dwureczny": b.visible = zestaw == "dwureczny"
				"bron_glewia": b.visible = zestaw == "glewia"
				"bron_topor": b.visible = zestaw == "topor"
				"bron_miecz": b.visible = zestaw == "miecz" or zestaw == "miecz_tarcza"
				"bron_tarcza": b.visible = zestaw == "miecz_tarcza"
				"bron_pochodnia": b.visible = false
	_wyglad_rynsztunku.przygotuj(bohater)
	_wyglad_rynsztunku.odswiez(Profil.d["loadout"], zestaw)
	WygladPostaci.ozyw(bohater, 0.35, 0.4)
	WygladPostaci.swiatlo_postaci(bohater, 0.9)
	var poswiata := _swiatlo(Color(0.62, 0.58, 0.8), 1.6, 4.5, false)
	poswiata.position.y = 1.6
	poswiata.remove_meta("migotanie")
	bohater.add_child(poswiata)


func _atmosfera() -> void:
	if not lekki:
		var mg := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(ROZMIAR - LAD_OD, ROZMIAR - LAD_OD)
		mg.mesh = pm
		var mm := ShaderMaterial.new()
		mm.shader = SHADER_MGLY
		mm.set_shader_parameter("szum", _szum)
		mm.set_shader_parameter("kolor", Color(0.45, 0.5, 0.6, 0.28))
		mm.set_shader_parameter("skala", 0.05)
		mg.material_override = mm
		mg.position = Vector3((ROZMIAR + LAD_OD) * 0.5, 0.15, (ROZMIAR + LAD_OD) * 0.5)
		add_child(mg)
	_pyl = GPUParticles3D.new()
	_pyl.amount = 60 if lekki else 160
	_pyl.lifetime = 6.0
	_pyl.preprocess = 6.0
	_pyl.local_coords = false
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ppm.emission_box_extents = Vector3(2.5, 0.2, 2.5)
	ppm.direction = Vector3(0, 1, 0)
	ppm.spread = 25.0
	ppm.initial_velocity_min = 0.3
	ppm.initial_velocity_max = 0.8
	ppm.gravity = Vector3(0.05, 0.15, 0.0)
	ppm.turbulence_enabled = true
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.5, 0.15, 0.0))
	gr.add_point(0.15, Color(1.0, 0.5, 0.15, 1.0))
	gr.set_color(gr.get_point_count() - 1, Color(1.0, 0.3, 0.05, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = gr
	ppm.color_ramp = gt
	_pyl.process_material = ppm
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := ShaderMaterial.new()
	m.shader = preload("res://zasoby/3d/shadery/czastka.gdshader")
	m.set_shader_parameter("sila", 2.6)
	m.set_shader_parameter("zasieg_tla", 8.0)
	q.material = m
	_pyl.draw_pass_1 = q
	_pyl.position = Vector3(19.0, 0.6, 19.0)  # iskry nad ogniskiem
	add_child(_pyl)
	# popiół opadający z nieba wokół bohatera (szary, powolny, kołysze się)
	_popiol = GPUParticles3D.new()
	_popiol.amount = 40 if lekki else 140
	_popiol.lifetime = 9.0
	_popiol.preprocess = 9.0
	_popiol.local_coords = false
	_popiol.visibility_aabb = AABB(Vector3(-14, -2, -14), Vector3(28, 12, 28))
	var pp2 := ParticleProcessMaterial.new()
	pp2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pp2.emission_box_extents = Vector3(10.0, 0.5, 10.0)
	pp2.direction = Vector3(0.2, -1.0, 0.1)
	pp2.spread = 20.0
	pp2.initial_velocity_min = 0.25
	pp2.initial_velocity_max = 0.5
	pp2.gravity = Vector3(0.0, -0.05, 0.0)
	pp2.turbulence_enabled = true
	pp2.turbulence_noise_strength = 0.6
	var gr2 := Gradient.new()
	gr2.set_color(0, Color(0.7, 0.68, 0.66, 0.0))
	gr2.add_point(0.2, Color(0.7, 0.68, 0.66, 0.8))
	gr2.set_color(gr2.get_point_count() - 1, Color(0.5, 0.48, 0.46, 0.0))
	var gt2 := GradientTexture1D.new()
	gt2.gradient = gr2
	pp2.color_ramp = gt2
	_popiol.process_material = pp2
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.04, 0.04)
	var m2 := ShaderMaterial.new()
	m2.shader = preload("res://zasoby/3d/shadery/czastka.gdshader")
	m2.set_shader_parameter("sila", 0.5)
	m2.set_shader_parameter("zasieg_tla", 8.0)
	q2.material = m2
	_popiol.draw_pass_1 = q2
	_popiol.position = Vector3(poz.x, 6.0, poz.y)
	add_child(_popiol)


func _label(rozmiar: int, kolor: Color) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0009
	l.font_size = rozmiar
	l.outline_size = 10
	l.modulate = kolor
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 20
	l.visible = false
	add_child(l)
	return l


# ---------------------------------------------------------------- RUCH I INTERAKCJA
func _process(dt: float) -> void:
	if aktywna:
		_ruch(dt)
		_interakcja()
	else:
		_etykieta.visible = false
	_ustaw_kamere()
	if _popiol:
		_popiol.position = Vector3(poz.x, 6.0, poz.y)
	_npc_patrza(dt)
	_npc_zyja(dt)
	if _dymek_czas > 0.0:
		_dymek_czas -= dt
		if _dymek_czas <= 0.0:
			_dymek.visible = false
	var t := Time.get_ticks_msec() / 1000.0
	for l in find_children("*", "OmniLight3D", true, false):
		if l.has_meta("migotanie"):
			var baza: float = l.get_meta("baza", l.light_energy)
			l.set_meta("baza", baza)
			l.light_energy = baza * (1.0 + sin(t * 13.0 + l.position.x * 7.0) * 0.06 + sin(t * 31.0 + l.position.z) * 0.04)


func _ruch(dt: float) -> void:
	var zestaw: String = Bohater.zestaw_dla(Profil.d["loadout"])
	_styl = "glewia" if zestaw == "glewia" else ZESTAW_ANIM.get(zestaw, "dwureczny")
	_wyglad_rynsztunku.odswiez(Profil.d["loadout"], zestaw)
	var wej := Input.get_vector("ruch_lewo", "ruch_prawo", "ruch_gora", "ruch_dol")
	var w := Iso.ekran_na_swiat_kierunek(wej)
	var anim := "postoj"
	var tempo := 1.0
	if w.length() > 0.05:
		var v := 4.3 * minf(1.0, wej.length())  # 26.11.2026 autor: chód w Warowni był za wolny (3,4)
		kat = atan2(w.y, w.x)
		var nowa := poz + w.normalized() * v * dt
		nowa = _dozwolona(nowa)
		poz = nowa
		anim = "bieg" if v > 2.4 else "chod"
		tempo = clampf(v / (4.0 if _styl == "dwureczny" else 3.8), 0.8, 1.45)
	var r := angle_difference(_kat_wiz, kat)
	_kat_wiz += clampf(r * (1.0 - exp(-dt * 14.0)), -12.0 * dt, 12.0 * dt)
	bohater.position = Vector3(poz.x, 0.0, poz.y)
	bohater.rotation.y = atan2(cos(_kat_wiz), sin(_kat_wiz))
	var nazwa := _styl + "_" + anim
	if _ap.has_animation(nazwa) and _anim != nazwa:
		_anim = nazwa
		_ap.play(nazwa, 0.2)
	_ap.speed_scale = tempo


## Ruch tylko po lądzie i pomoście, z ominięciem rekwizytów i postaci.
func _dozwolona(n: Vector2) -> Vector2:
	var na_pomoscie := n.x > 9.25 and n.x < 10.95 and n.y > 0.3 and n.y < LAD_OD + 0.5
	if not na_pomoscie:
		n.x = clampf(n.x, LAD_OD + 0.4, ROZMIAR - 0.4)
		n.y = clampf(n.y, LAD_OD + 0.4, ROZMIAR - 0.4)
	for pr in _przeszkody:
		var c: Vector2 = pr[0]
		var rr: float = pr[1] + 0.3
		var d := n - c
		if d.length() < rr:
			n = c + d.normalized() * rr if d.length() > 0.001 else c + Vector2(rr, 0)
	return n


func _interakcja() -> void:
	var najb := ""
	var dn := 2.0
	for k in MIEJSCA.keys():
		var w: Vector2 = MIEJSCA[k][2]
		var d := poz.distance_to(w)
		if d < dn:
			dn = d
			najb = k
	cel = najb
	_krag_celu(najb)
	if cel == "":
		_etykieta.visible = false
		return
	var m: Array = MIEJSCA[cel]
	var w2: Vector2 = m[2]
	_etykieta.text = "E / Y:  " + str(m[0])
	_etykieta.position = Vector3(w2.x, 2.5, w2.y)
	_etykieta.visible = true
	if Input.is_action_just_pressed("interakcja"):
		uzyj(cel)


## Złoty krąg pod stopami rozmówcy (albo przy miejscu) — zamiast podświetlania całej postaci.
var krag: MeshInstance3D


func _krag_celu(k: String) -> void:
	if krag == null:
		krag = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.62
		tm.outer_radius = 0.7
		tm.rings = 48
		krag.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.78, 0.4, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = Color(1.0, 0.7, 0.3)
		krag.material_override = m
		krag.scale = Vector3(1.0, 0.05, 1.0)
		krag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(krag)
	krag.visible = k != "" and aktywna
	if k == "":
		return
	var w: Vector2 = MIEJSCA[k][2]
	if _npc.has(k):
		var n: Node3D = _npc[k]["wezel"]
		w = Vector2(n.position.x, n.position.z)
	krag.position = Vector3(w.x, 0.04, w.y)
	var t := Time.get_ticks_msec() / 1000.0
	(krag.material_override as StandardMaterial3D).albedo_color.a = 0.55 + 0.25 * sin(t * 3.0)


## Interakcja z miejscem: otwarcie zakładki Warowni albo kwestia gawędziarza.
func uzyj(miejsce: String) -> void:
	var m: Array = MIEJSCA[miejsce]
	Dzwiek.ui()
	if int(m[1]) < 0:
		_dymek.text = "„" + KWESTIE[_kwestia % KWESTIE.size()] + "”"
		_kwestia += 1
		var w: Vector2 = m[2]
		_dymek.position = Vector3(w.x, 2.1, w.y)
		_dymek.visible = true
		_dymek_czas = 6.0
		return
	otworz.emit(int(m[1]))


## Życie NPC: co kilka-kilkanaście sekund inna poza spoczynku (płynne przejście).
func _npc_zyja(dt: float) -> void:
	for k in _npc:
		var d: Dictionary = _npc[k]
		var ap0: AnimationPlayer = d["ap"]
		# rozmówca w zasięgu mówi do bohatera (animacja z gestami), potem wraca do spoczynku
		if k == cel and aktywna and ap0.has_animation("rozmowa"):
			if ap0.current_animation != "rozmowa":
				ap0.play("rozmowa", 0.6)
			d["zmiana"] = 2.0
			continue
		d["zmiana"] = float(d["zmiana"]) - dt
		if float(d["zmiana"]) > 0.0 and ap0.current_animation != "rozmowa":
			continue
		d["zmiana"] = 7.0 + randf() * 9.0
		var ap: AnimationPlayer = d["ap"]
		var pozy: Array = []
		for a in ["postoj", "postoj2", "rozglad"]:
			if ap.has_animation(a) and a != ap.current_animation:
				pozy.append(a)
		if not pozy.is_empty():
			ap.play(pozy[randi() % pozy.size()], 0.8)


func _npc_patrza(dt: float) -> void:
	for k in ["marga", "chojrak", "przewoznik"]:
		if not _npc.has(k):
			continue
		var n: Node3D = _npc[k]["wezel"]
		var d := poz - Vector2(n.position.x, n.position.z)
		if d.length() < 5.0:
			var cel_kat := atan2(d.x, d.y)
			n.rotation.y = lerp_angle(n.rotation.y, cel_kat, minf(1.0, dt * 4.0))


# ---------------------------------------------------------------- POMOCNICZE
func _tekstura_szumu() -> Texture2D:
	var kan := []
	for i in 3:
		var fn := FastNoiseLite.new()
		fn.seed = 1337 + i * 71
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = [0.012, 0.025, 0.05][i]
		fn.fractal_octaves = 4
		kan.append(fn.get_seamless_image(128, 128))
	var im := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			im.set_pixel(x, y, Color(kan[0].get_pixel(x, y).r, kan[1].get_pixel(x, y).r, kan[2].get_pixel(x, y).r))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)


func _ogien(sila: float, rozmiar: float) -> GPUParticles3D:
	var c := GPUParticles3D.new()
	c.amount = int(30 * sila)
	c.lifetime = 0.7
	c.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.5 * rozmiar
	pm.initial_velocity_max = 1.1 * rozmiar
	pm.gravity = Vector3(0, 0.6, 0)
	var krzywa := Curve.new()
	krzywa.add_point(Vector2(0, 1))
	krzywa.add_point(Vector2(1, 0.15))
	var kt := CurveTexture.new()
	kt.curve = krzywa
	pm.scale_curve = kt
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.1 * rozmiar
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.85, 0.45, 1.0))
	gr.add_point(0.45, Color(1.0, 0.38, 0.08, 0.9))
	gr.set_color(gr.get_point_count() - 1, Color(0.3, 0.05, 0.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = gr
	pm.color_ramp = gt
	c.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.15, 0.15) * rozmiar
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	var g2 := Gradient.new()
	g2.set_color(0, Color(1, 1, 1, 1))
	g2.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g2
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	m.albedo_texture = t
	q.material = m
	c.draw_pass_1 = q
	return c
