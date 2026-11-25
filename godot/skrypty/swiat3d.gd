extends Node3D
## Świat rajdu w 3D (Forward+). Tylko wygląd: reguły dalej liczy rajd.gd na współrzędnych świata.
## Układ: świat (x, y) w polach -> 3D (x, 0, y), 1 pole = 1 m. Kamera ortogonalna w rzucie Iso
## (64x32 px na pole), więc paski HP, napisy i efekty 2D rysowane nad sceną trafiają w postacie.

const Iso = preload("res://skrypty/iso.gd")
const Mapgen = preload("res://skrypty/mapgen.gd")
const K = Mapgen.K
const N := Mapgen.ROZMIAR
const PX_NA_M := 45.254834  # 32 * sqrt(2): pole świata -> piksele ekranu (zgodnie z Iso)
const WYS_MURU := 1.7

const GLB_BOHATERA := "res://zasoby/3d/postacie/hadraen.glb"
const ZESTAW_ANIM := {"dwureczny": "dwureczny", "glewia": "dwureczny", "topor": "topor",
	"miecz": "miecz", "miecz_tarcza": "miecz", "piesci": "piesci"}
const PETLE := ["postoj", "chod", "blok", "ogluszenie"]
const SKALA_WROGA := {"scout": 1.0, "warden": 1.04, "archer": 1.0, "knight": 1.06, "brute": 1.18, "boss": 1.38}

var rajd
var kamera: Camera3D
var srodowisko: WorldEnvironment
var _mm := {}            # rodzaj kafla -> MultiMeshInstance3D
var _indeks := {}        # idx kafla -> [rodzaj, nr instancji]
var _stan_widoku := PackedByteArray()
var _mur_przezr := {}    # idx -> bool
var bohater: Node3D
var _ap_bohatera: AnimationPlayer
var _bronie := {}        # nazwa -> MeshInstance3D
var _swiatlo_pochodni: OmniLight3D
var _plomien_bohatera: GPUParticles3D
var _poswiata: OmniLight3D
var _pochodnia_ziemia: Node3D
var _wrogowie := {}      # instance_id Wrog -> {wezel, ap, swiatlo, martwy, czas_smierci, ...}
var _skrzynie := []
var _zwloki := {}        # id słownika zwłok -> Node3D
var _mat := {}
var _sceny := {}
var _dekor := []         # [Node3D, idx kafla] - rekwizyty widoczne wg mgły wojny
var _skala_rek := {}     # nazwa -> [skala, przesunięcie y]
var lekki := false  # tryb testowy: bez cieni i efektów ekranowych (software rendering w testach)


func zbuduj(r) -> void:
	rajd = r
	lekki = "--test" in OS.get_cmdline_user_args() and not "--pelna" in OS.get_cmdline_user_args()
	if lekki:
		var vp := get_viewport()
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		vp.scaling_3d_scale = 0.5
	_materialy()
	_srodowisko()
	_kamera()
	_mapa()
	_rekwizyty()
	_bohater()
	_stan_widoku.resize(N * N)
	_stan_widoku.fill(255)


# ---------------------------------------------------------------- MATERIAŁY
func _tekstura(n: String) -> Texture2D:
	return load("res://zasoby/3d/tekstury/%s" % n)


func _mat_pbr(baza: String, kolor: Color, skala: float, przezr := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tekstura(baza + "_albedo.jpg")
	m.albedo_color = kolor
	m.normal_enabled = true
	m.normal_texture = _tekstura(baza + "_normal.png")
	m.normal_scale = 1.4
	m.roughness_texture = _tekstura(baza + "_rough.png")
	m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(skala, skala, skala)
	m.vertex_color_use_as_albedo = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if przezr:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	return m


func _mat_prosty(kolor: Color, metal := 0.0, szorstk := 0.8, emisja := Color.BLACK, sila := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = kolor
	m.metallic = metal
	m.roughness = szorstk
	if sila > 0.0:
		m.emission_enabled = true
		m.emission = emisja
		m.emission_energy_multiplier = sila
	return m


func _materialy() -> void:
	var id: String = rajd.kraina["id"]
	var ton: Color = {"catacombs": Color(0.95, 0.88, 0.8), "outskirts": Color(0.9, 0.9, 0.92), "crypt": Color(0.72, 0.74, 0.86)}.get(id, Color.WHITE)
	_mat["podloga"] = _mat_pbr("kamien", ton * Color(0.78, 0.76, 0.74), 0.55)
	_mat["sciezka"] = _mat_pbr("deski", ton * Color(0.9, 0.85, 0.8), 0.5)
	_mat["mur"] = _mat_pbr("kamien", ton, 0.42)
	_mat["filar"] = _mat_pbr("kamien", ton * Color(1.05, 1.0, 0.95), 0.6)
	_mat["gruz"] = _mat_pbr("kamien", ton * Color(0.85, 0.82, 0.8), 0.9)
	_mat["drewno"] = _mat_pbr("bale", Color(1, 1, 1), 0.9)
	_mat["skrzynia"] = _mat_pbr("deski", Color(0.75, 0.62, 0.5), 1.6)
	(_mat["skrzynia"] as StandardMaterial3D).metallic = 0.25
	_mat["zelazo"] = _mat_prosty(Color(0.1, 0.095, 0.09), 0.85, 0.5)
	_mat["ekstrakcja"] = _mat_prosty(Color(0.05, 0.25, 0.18), 0.0, 0.4, Color(0.25, 1.0, 0.7), 3.2)
	_mat["zar"] = _mat_prosty(Color(0.06, 0.02, 0.0), 0.0, 0.95, Color(1.0, 0.35, 0.08), 1.4)


# ---------------------------------------------------------------- ŚRODOWISKO
func _srodowisko() -> void:
	srodowisko = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.01, 0.008, 0.012)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.36, 0.34, 0.48)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 1.05
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_strength = 1.1
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 1.1
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.ssao_enabled = true
	e.ssao_radius = 1.4
	e.ssao_intensity = 1.6
	e.ssil_enabled = true
	e.ssil_radius = 3.0
	e.fog_enabled = true
	e.fog_light_color = Color(0.09, 0.08, 0.1)
	e.fog_density = 0.004
	e.fog_height = 0.35
	e.fog_height_density = 0.9
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.08
	e.adjustment_saturation = 0.92
	if lekki:
		e.ssao_enabled = false
		e.ssil_enabled = false
		e.glow_enabled = false
		e.fog_enabled = false
	srodowisko.environment = e
	add_child(srodowisko)
	# chłodne światło wypełniające z góry (księżyc przez szczeliny): czytelne sylwetki w mroku
	var ksiezyc := DirectionalLight3D.new()
	ksiezyc.light_color = Color(0.55, 0.62, 0.9)
	ksiezyc.light_energy = 0.32
	ksiezyc.shadow_enabled = false
	ksiezyc.rotation_degrees = Vector3(-62, 20, 0)
	add_child(ksiezyc)


func _kamera() -> void:
	kamera = Camera3D.new()
	kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
	kamera.keep_aspect = Camera3D.KEEP_HEIGHT
	kamera.near = 0.5
	kamera.far = 120.0
	add_child(kamera)
	kamera.current = true


## Kamera 3D w dokładnie tym samym rzucie co Camera2D rajdu.
func _ustaw_kamere() -> void:
	var k2: Camera2D = rajd.kamera
	var zoom: float = k2.zoom.x
	var srodek: Vector2 = k2.get_screen_center_position()
	var w := Iso.swiat(srodek)
	var cel := Vector3(w.x, 0.0, w.y)
	var kier := Vector3(cos(deg_to_rad(30.0)) / sqrt(2.0), sin(deg_to_rad(30.0)), cos(deg_to_rad(30.0)) / sqrt(2.0))
	kamera.position = cel + kier * 40.0
	kamera.look_at(cel, Vector3.UP)
	kamera.size = get_viewport().get_visible_rect().size.y / (PX_NA_M * zoom)


# ---------------------------------------------------------------- MAPA
func _mapa() -> void:
	var siatki := {
		"podloga": _plyta(), "sciezka": _plyta(), "ekstrakcja": _plyta(),
		"mur": _box(Vector3(1.0, WYS_MURU, 1.0)), "filar": _filar(), "gruz": _gruz(),
	}
	var listy := {}
	for k in siatki.keys():
		listy[k] = []
	var mapa = rajd.mapa
	for y in N:
		for x in N:
			var t: int = mapa.kafel(x, y)
			var i: int = mapa.idx(x, y)
			var podl := "podloga"
			if t == K.SCIEZKA:
				podl = "sciezka"
			elif t == K.EKSTRAKCJA:
				podl = "ekstrakcja"
			if t != K.MUR:
				listy[podl].append(i)
			match t:
				K.MUR: listy["mur"].append(i)
				K.FILAR:
					if _hash(x, y) % 3 == 0:
						_postaw(i, "posag", 2.1, _hash(x, y) % 4 * PI * 0.5)
					else:
						listy["filar"].append(i)
				K.GRUZ:
					var g: String = ["glaz", "kolumna_lezaca", "kosci"][_hash(x, y) % 3]
					_postaw(i, g, 0.85 if g != "kosci" else 0.4, float(_hash(y, x) % 628) / 100.0)
	for k in listy.keys():
		var mmi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = siatki[k]
		mm.instance_count = listy[k].size()
		for n in listy[k].size():
			var i: int = listy[k][n]
			var p := Vector3(i % N + 0.5, 0.0, i / N + 0.5)
			mm.set_instance_transform(n, Transform3D(Basis(), p))
			mm.set_instance_color(n, Color(0, 0, 0, 0))
			if not _indeks.has(i):
				_indeks[i] = []
			_indeks[i].append([k, n, p])
		mmi.multimesh = mm
		mmi.material_override = _mat["mur" if k == "mur" else k] if _mat.has(k) else _mat["podloga"]
		if k == "ekstrakcja":
			mmi.material_override = _mat["podloga"]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if k in ["mur", "filar", "gruz"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_mm[k] = mmi


static func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ 0x5bd1e995)


## Rekwizyt z modeli Meshy autora: skala do zadanej wysokości (albo długości), stopa na podłodze.
func _rekwizyt(nazwa: String, wymiar: float, po_dlugosci := false) -> Node3D:
	var n: Node3D = _scena("res://zasoby/3d/rekwizyty/%s.glb" % nazwa).instantiate()
	add_child(n)
	if not _skala_rek.has(nazwa + str(wymiar)):
		var ab := AABB()
		var pierwszy := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var a := (n.global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
			ab = a if pierwszy else ab.merge(a)
			pierwszy = false
		var miara := maxf(ab.size.x, ab.size.z) if po_dlugosci else ab.size.y
		var s := wymiar / maxf(miara, 0.01)
		_skala_rek[nazwa + str(wymiar)] = [s, -ab.position.y * s]
	var sk: Array = _skala_rek[nazwa + str(wymiar)]
	n.scale = Vector3.ONE * float(sk[0])
	n.set_meta("y0", float(sk[1]))
	_cienie(n)
	return n


func _postaw(i: int, nazwa: String, wys: float, obrot: float) -> Node3D:
	var n := _rekwizyt(nazwa, wys)
	n.position = Vector3(i % N + 0.5, float(n.get_meta("y0")), i / N + 0.5)
	n.rotation.y = obrot
	n.visible = false
	_dekor.append([n, i])
	return n


## Wystrój przy ścianach (tylko wygląd, nie blokuje ruchu): deterministyczny z położenia kafla.
func _wystroj() -> void:
	var mapa = rajd.mapa
	var zajete := {}
	for sk in mapa.skrzynie:
		zajete[mapa.idx(sk["tx"], sk["ty"])] = true
	var start: Vector2 = mapa.start
	for y in range(1, N - 1):
		for x in range(1, N - 1):
			if mapa.kafel(x, y) != K.PODLOGA or zajete.has(mapa.idx(x, y)):
				continue
			if Vector2(x + 0.5, y + 0.5).distance_to(start) < 2.5:
				continue
			var sciana := Vector2.ZERO
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if mapa.kafel(x + d.x, y + d.y) == K.MUR:
					sciana = Vector2(d)
			if sciana == Vector2.ZERO or _hash(x, y) % 9 != 0:
				continue
			var wybor: Array = [["kandelabr", 1.25], ["lancuchy", 1.5], ["nagrobek", 0.95], ["beczka", 0.95], ["kosci", 0.35], ["kandelabr", 1.25]][_hash(y, x) % 6]
			var n := _postaw(mapa.idx(x, y), wybor[0], wybor[1], atan2(-sciana.x, -sciana.y))
			n.position += Vector3(sciana.x, 0, sciana.y) * 0.28
			if wybor[0] == "kandelabr":
				var l := _swiatlo(Color(1.0, 0.75, 0.45), 1.3, 3.2, false)
				l.position.y = 1.4 / n.scale.y
				l.set_meta("migotanie", true)
				n.add_child(l)


func _plyta() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(1.0, 0.1, 1.0)
	return m


func _box(r: Vector3) -> Mesh:
	var m := BoxMesh.new()
	m.size = r
	return m


func _filar() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.3
	m.bottom_radius = 0.36
	m.height = WYS_MURU + 0.4
	m.radial_segments = 16
	return m


func _gruz() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.38
	m.height = 0.42
	m.radial_segments = 10
	m.rings = 5
	return m


## Mgła wojny: 0 nieznane (ukryte), 1 widziane (przygaszone), 2 widoczne. Mury przy graczu od strony kamery przezroczyste.
func odswiez_widok() -> void:
	var widok: PackedByteArray = rajd.widok
	var g: Vector2 = rajd.gracz.w
	for i in _indeks.keys():
		var v: int = widok[i]
		var przezr := false
		var tx: int = i % N
		var ty: int = i / N
		# przekrój: mury od strony kamery (większe x+y) blisko gracza
		var dx := tx + 0.5 - g.x
		var dy := ty + 0.5 - g.y
		if dx + dy > 0.6 and absf(dx) < 4.6 and absf(dy) < 4.6 and absf(dx - dy) < 6.0:
			przezr = true
		var klucz := v + (100 if przezr else 0)
		if _stan_widoku[i] == klucz:
			continue
		_stan_widoku[i] = klucz
		for wpis in _indeks[i]:
			var rodzaj: String = wpis[0]
			var mm: MultiMesh = _mm[rodzaj].multimesh
			var jasn := 0.0 if v == 0 else (1.0 if v == 2 else 0.42)
			var alfa := 1.0
			var p: Vector3 = wpis[2]
			var b := Basis()
			if v == 0:
				b = b.scaled(Vector3.ZERO)
			var y := 0.0
			match rodzaj:
				"mur": y = WYS_MURU * 0.5
				"filar": y = (WYS_MURU + 0.4) * 0.5
				"gruz": y = 0.05
				_: y = -0.05
			# mur między kamerą a graczem obniżony do cokołu (jak w grach izometrycznych AAA)
			if przezr and (rodzaj == "mur" or rodzaj == "filar") and v != 0:
				var h := 0.22
				var pelna := WYS_MURU if rodzaj == "mur" else WYS_MURU + 0.4
				b = b.scaled(Vector3(1.0, h / pelna, 1.0))
				y = h * 0.5
			if rodzaj == "ekstrakcja":
				mm.set_instance_color(wpis[1], Color(jasn * 0.7, jasn * 1.0, jasn * 0.85, 1.0))
			else:
				mm.set_instance_color(wpis[1], Color(jasn, jasn, jasn, alfa))
			mm.set_instance_transform(wpis[1], Transform3D(b, Vector3(p.x, y, p.z)))
	for sk in _skrzynie:
		var v2: int = widok[rajd.mapa.idx(sk["tx"], sk["ty"])]
		sk["wezel3d"].visible = v2 > 0
	for d in _dekor:
		(d[0] as Node3D).visible = widok[d[1]] > 0


# ---------------------------------------------------------------- REKWIZYTY I ŚWIATŁA
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
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var krzywa := Curve.new()
	krzywa.add_point(Vector2(0, 1))
	krzywa.add_point(Vector2(1, 0.15))
	var kt := CurveTexture.new()
	kt.curve = krzywa
	pm.scale_curve = kt
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.08 * rozmiar
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
	m.albedo_texture = _kropka()
	q.material = m
	c.draw_pass_1 = q
	return c


var _tex_kropka: Texture2D
func _kropka() -> Texture2D:
	if _tex_kropka == null:
		var gr := Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 1))
		gr.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = gr
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 32
		t.height = 32
		_tex_kropka = t
	return _tex_kropka


func _swiatlo(kolor: Color, energia: float, zasieg: float, cien := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = kolor
	l.light_energy = energia
	l.omni_range = zasieg
	l.omni_attenuation = 1.0
	l.shadow_enabled = cien and not lekki
	l.shadow_blur = 1.5
	l.light_specular = 0.6
	return l


func _rekwizyty() -> void:
	var mapa = rajd.mapa
	for k in mapa.kosze:
		var w: Vector2 = k
		var kosz := Node3D.new()
		kosz.position = Vector3(w.x, 0, w.y)
		var misa := _rekwizyt("misa_zar", 1.05)
		remove_child(misa)
		misa.position.y = float(misa.get_meta("y0"))
		kosz.add_child(misa)
		var ogien := _ogien(1.4, 1.6)
		ogien.position.y = 1.05
		kosz.add_child(ogien)
		var l := _swiatlo(Color(1.0, 0.6, 0.28), 3.6, 8.0)
		l.position.y = 1.5
		l.set_meta("migotanie", true)
		kosz.add_child(l)
		add_child(kosz)
	for e in mapa.ekstrakcje:
		var w2: Vector2 = e["w"]
		var krag := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.0
		tm.outer_radius = 1.12
		krag.mesh = tm
		krag.scale = Vector3(1, 0.15, 1)
		krag.position = Vector3(w2.x, 0.04, w2.y)
		krag.material_override = _mat["ekstrakcja"]
		add_child(krag)
		var l2 := _swiatlo(Color(0.3, 1.0, 0.72), 2.2, 6.0, false)
		l2.position = Vector3(w2.x, 1.2, w2.y)
		add_child(l2)
		var iskry := _ogien(0.9, 1.0)
		var pm: ParticleProcessMaterial = iskry.process_material
		var gr := Gradient.new()
		gr.set_color(0, Color(0.6, 1.0, 0.85, 1.0))
		gr.set_color(1, Color(0.1, 0.6, 0.4, 0.0))
		var gt := GradientTexture1D.new()
		gt.gradient = gr
		pm.color_ramp = gt
		pm.emission_sphere_radius = 0.9
		iskry.lifetime = 1.8
		iskry.position = Vector3(w2.x, 0.1, w2.y)
		add_child(iskry)
	for sk in mapa.skrzynie:
		var n := _skrzynia(sk["rodzaj"])
		var w3: Vector2 = sk["w"]
		n.position = Vector3(w3.x, 0, w3.y)
		n.rotation.y = float(hash(str(sk["tx"]) + str(sk["ty"])) % 4) * PI * 0.5
		n.visible = false
		add_child(n)
		sk["wezel3d"] = n
		_skrzynie.append(sk)
	_wystroj()
	_pochodnia_ziemia = Node3D.new()
	var kij := MeshInstance3D.new()
	var km := CylinderMesh.new()
	km.top_radius = 0.025
	km.bottom_radius = 0.025
	km.height = 0.55
	kij.mesh = km
	kij.rotation.z = deg_to_rad(70)
	kij.position.y = 0.1
	kij.material_override = _mat["drewno"]
	_pochodnia_ziemia.add_child(kij)
	var og := _ogien(1.0, 1.0)
	og.position = Vector3(0.22, 0.2, 0)
	_pochodnia_ziemia.add_child(og)
	var lz := _swiatlo(Color(1.0, 0.72, 0.42), 4.0, 9.5)
	lz.position = Vector3(0.22, 0.6, 0)
	lz.set_meta("migotanie", true)
	_pochodnia_ziemia.add_child(lz)
	_pochodnia_ziemia.visible = false
	add_child(_pochodnia_ziemia)


func _skrzynia(rodzaj: String) -> Node3D:
	var n := Node3D.new()
	var r: Node3D
	match rodzaj:
		"loot_sarcophagus":
			r = _rekwizyt("sarkofag", 1.75, true)
		"loot_knight":
			r = _rekwizyt("zbroja", 1.9)
		_:
			r = _rekwizyt("kufer", 0.95, true)
			for mi in r.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = _mat["skrzynia"]
	remove_child(r)
	r.position.y = float(r.get_meta("y0"))
	n.add_child(r)
	return n


# ---------------------------------------------------------------- POSTACIE
func _scena(sc: String) -> PackedScene:
	if not _sceny.has(sc):
		_sceny[sc] = load(sc)
	return _sceny[sc]


func _przygotuj_ap(ap: AnimationPlayer) -> void:
	for nazwa in ap.get_animation_list():
		var a := ap.get_animation(nazwa)
		var petla := false
		for p in PETLE:
			if nazwa.ends_with(p):
				petla = true
		a.loop_mode = Animation.LOOP_LINEAR if petla else Animation.LOOP_NONE


func _bohater() -> void:
	bohater = _scena(GLB_BOHATERA).instantiate()
	add_child(bohater)
	_ap_bohatera = bohater.find_child("AnimationPlayer", true, false)
	_przygotuj_ap(_ap_bohatera)
	for n in ["bron_dwureczny", "bron_glewia", "bron_topor", "bron_miecz", "bron_tarcza", "bron_pochodnia"]:
		var b: Node3D = bohater.find_child(n, true, false)
		if b:
			_bronie[n] = b
	var punkt: Node3D = bohater.find_child("plomien_punkt", true, false)
	_swiatlo_pochodni = _swiatlo(Color(1.0, 0.7, 0.4), 4.5, 10.5)
	_swiatlo_pochodni.set_meta("migotanie", true)
	_plomien_bohatera = _ogien(0.9, 0.8)
	if punkt:
		punkt.add_child(_swiatlo_pochodni)
		punkt.add_child(_plomien_bohatera)
	_poswiata = _swiatlo(Color(0.62, 0.58, 0.8), 2.4, 5.5, false)
	_poswiata.position.y = 1.6
	bohater.add_child(_poswiata)
	_cienie(bohater)


func _cienie(n: Node) -> void:
	for c in n.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _graj(ap: AnimationPlayer, nazwa: String, t: float, predkosc := 1.0) -> void:
	if not ap.has_animation(nazwa):
		return
	if ap.current_animation != nazwa:
		# Animacje sterowane stanem walki (t >= 0) bez przejścia: przy speed_scale 0 przejście
		# nigdy by się nie skończyło i na ekranie zostałaby poprzednia animacja.
		ap.play(nazwa, 0.08 if t < 0.0 else 0.0)
	if t >= 0.0:
		ap.speed_scale = 0.0
		ap.seek(clampf(t, 0.0, 0.999) * ap.current_animation_length, true)
	else:
		ap.speed_scale = predkosc


static func _obrot(k: float) -> float:
	# model patrzy w +Z; kierunek świata (cos k, sin k) -> 3D (cos k, 0, sin k)
	return atan2(cos(k), sin(k))


## Stan bohatera -> [animacja (bez prefiksu zestawu), kąt, postęp 0..1 albo -1 dla pętli].
func _stan_bohatera(p) -> Array:
	if p.martwy:
		return ["smierc", p.kat, minf(1.0, p.smierc_anim / 1.3)]
	if p.unik_czas > 0.0:
		var ku: float = atan2(p.unik_kier.y, p.unik_kier.x) if p.unik_kier != Vector2.ZERO else p.kat
		return ["przewrot", ku, 1.0 - p.unik_czas / p.UNIK_DLUGOSC]
	if p.zamach_anim > 0.0:
		return ["atak%d" % (p.combo + 1), p.atak_kat, 1.0 - p.zamach_anim / p.zamach_anim_max]
	if p.blok:
		if p.okno_parowania > 0.0 and p.blok_czas < 0.35:
			return ["parowanie", p.kat, p.blok_czas / 0.35]
		return ["blok", p.kat, -1.0]
	if p.w_ruchu:
		return ["chod", p.kat, -1.0]
	return ["postoj", p.kat, -1.0]


func _aktualizuj_bohatera(dt: float) -> void:
	var p = rajd.gracz
	bohater.position = Vector3(p.w.x, 0.0, p.w.y)
	var st := _stan_bohatera(p)
	var zestaw: String = p.zestaw
	var anim_zestaw: String = ZESTAW_ANIM.get(zestaw, "dwureczny")
	var cel_obr := _obrot(st[1])
	bohater.rotation.y = lerp_angle(bohater.rotation.y, cel_obr, minf(1.0, dt * 18.0)) if st[2] < 0.0 else cel_obr
	_graj(_ap_bohatera, anim_zestaw + "_" + str(st[0]), st[2], 1.0 if st[0] != "chod" else 1.15)
	p.biezaca_anim = st[0]
	for n in _bronie.keys():
		var b: Node3D = _bronie[n]
		match n:
			"bron_dwureczny": b.visible = zestaw == "dwureczny"
			"bron_glewia": b.visible = zestaw == "glewia"
			"bron_topor": b.visible = zestaw == "topor"
			"bron_miecz": b.visible = zestaw == "miecz" or zestaw == "miecz_tarcza"
			"bron_tarcza": b.visible = zestaw == "miecz_tarcza"
			"bron_pochodnia": b.visible = p.pochodnia_w_rece and not p.martwy
	_swiatlo_pochodni.visible = p.pochodnia_w_rece and not p.martwy
	_plomien_bohatera.emitting = _swiatlo_pochodni.visible
	_poswiata.visible = not p.pochodnia_w_rece and not p.martwy


func _wrog3d(en) -> Dictionary:
	var id: int = en.get_instance_id()
	if _wrogowie.has(id):
		return _wrogowie[id]
	var sc := "res://zasoby/3d/postacie/wrog_%s.glb" % en.rodzaj
	var n: Node3D = _scena(sc).instantiate()
	var s: float = SKALA_WROGA.get(en.rodzaj, 1.0)
	n.scale = Vector3(s, s, s)
	add_child(n)
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	_przygotuj_ap(ap)
	ap.play("postoj")
	ap.seek(randf() * ap.current_animation_length, true)
	var l := _swiatlo(Color(1.0, 0.8, 0.3), 0.0, 3.2, false)
	l.position.y = 1.7 * s
	n.add_child(l)
	var blysk := StandardMaterial3D.new()
	blysk.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blysk.albedo_color = Color(1, 0.9, 0.8, 0.0)
	blysk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var cialo: MeshInstance3D = n.find_child("cialo", true, false)
	if cialo:
		cialo.material_overlay = blysk
	_cienie(n)
	var d := {"wezel": n, "ap": ap, "swiatlo": l, "blysk": blysk, "martwy": false, "smierc": 0.0, "wrog": weakref(en), "kat": en.kat}
	_wrogowie[id] = d
	return d


func _aktualizuj_wrogow(dt: float, czas: float) -> void:
	var zywi := {}
	for en in rajd.wrogowie:
		var d := _wrog3d(en)
		zywi[en.get_instance_id()] = true
		var n: Node3D = d["wezel"]
		n.position = Vector3(en.w.x, 0.0, en.w.y)
		n.visible = en.widoczny_dla_gracza or rajd.widoczne(en.w) == 2
		d["kat"] = en.kat
		n.rotation.y = lerp_angle(n.rotation.y, _obrot(en.kat), minf(1.0, dt * 12.0))
		var ap: AnimationPlayer = d["ap"]
		var l: OmniLight3D = d["swiatlo"]
		l.light_energy = 0.0
		if en.ogluszenie > 0.0:
			_graj(ap, "ogluszenie", -1.0)
		elif en.zamach > 0.0:
			var t: float = 1.0 - en.zamach / en.zamach_dl
			_graj(ap, "zamach", t)
			# zapowiedź ciosu: rozbłysk na wrogu (złoty = do sparowania, czerwony = ciężki)
			l.light_color = Color(1.0, 0.22, 0.12) if en.ciezki else Color(1.0, 0.82, 0.3)
			l.light_energy = 1.6 + 1.6 * t + sin(czas * 30.0) * 0.6
		elif en.cios_anim > 0.0:
			_graj(ap, "cios", 1.0 - en.cios_anim / 0.22)
		elif en.trafiony > 0.0:
			_graj(ap, "trafienie", 1.0 - en.trafiony / 0.15)
		elif czas - en._ruch_czas < 0.15:
			_graj(ap, "chod", -1.0, en.spd / 2.0)
		else:
			_graj(ap, "postoj", -1.0)
		var b: StandardMaterial3D = d["blysk"]
		b.albedo_color.a = 0.28 if en.trafiony > 0.0 else 0.0
	# polegli: animacja śmierci i ciało zostaje na ziemi
	for id in _wrogowie.keys():
		if zywi.has(id):
			continue
		var d2: Dictionary = _wrogowie[id]
		if not d2["martwy"]:
			d2["martwy"] = true
			d2["smierc"] = 0.0
			(d2["swiatlo"] as OmniLight3D).light_energy = 0.0
			(d2["blysk"] as StandardMaterial3D).albedo_color.a = 0.0
		d2["smierc"] += dt
		var ap2: AnimationPlayer = d2["ap"]
		_graj(ap2, "smierc", minf(1.0, d2["smierc"] / 1.4))


func _aktualizuj_rekwizyty(czas: float) -> void:
	if rajd.pochodnia_na_ziemi != null:
		var w: Vector2 = rajd.pochodnia_na_ziemi
		_pochodnia_ziemia.position = Vector3(w.x, 0, w.y)
		_pochodnia_ziemia.visible = true
	else:
		_pochodnia_ziemia.visible = false
	var obecne := {}
	for z in rajd.zwloki:
		var klucz := str(z["w"])
		obecne[klucz] = true
		if z.get("sakwa", false) and not _zwloki.has(klucz):
			var worek := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.24
			sm.height = 0.36
			worek.mesh = sm
			worek.material_override = _mat_prosty(Color(0.28, 0.18, 0.1), 0.0, 0.85)
			var wz: Vector2 = z["w"]
			worek.position = Vector3(wz.x, 0.16, wz.y)
			add_child(worek)
			_zwloki[klucz] = worek
	for k in _zwloki.keys():
		if not obecne.has(k):
			(_zwloki[k] as Node3D).queue_free()
			_zwloki.erase(k)
	# migotanie płomieni
	for l in find_children("*", "OmniLight3D", true, false):
		if l.has_meta("migotanie"):
			var baza: float = l.get_meta("baza", l.light_energy)
			l.set_meta("baza", baza)
			l.light_energy = baza * (1.0 + sin(czas * 13.0 + l.position.x * 7.0) * 0.06 + sin(czas * 31.0 + l.position.z) * 0.04)


func aktualizuj(dt: float, czas: float) -> void:
	_ustaw_kamere()
	_aktualizuj_bohatera(dt)
	_aktualizuj_wrogow(dt, czas)
	_aktualizuj_rekwizyty(czas)
