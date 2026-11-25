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
const PETLE := ["postoj", "chod", "blok", "ogluszenie", "bieg", "tyl", "lewo", "prawo"]
## Ciosy Hadræna: [moment uderzenia w klipie, koniec ruchu po uderzeniu] w sekundach klipu (zmierzone na dłoni).
## Klip jest odtwarzany jednym, stałym tempem tak, by uderzenie wypadło ~0,1 s po wciśnięciu ataku (okno trafienia w rajd.gd bez zmian).
const ATAK_PLAN := {
	"dwureczny": [[0.33, 0.70], [0.49, 0.95], [0.26, 0.85]],
	"miecz": [[0.56, 1.00], [0.53, 1.20], [1.17, 1.38]],
	"piesci": [[0.30, 0.75], [0.30, 0.75], [0.59, 1.30]],
	"topor": [[0.83, 1.55], [0.92, 1.70], [0.85, 1.60]],
}
const ATAK_PRZED := [0.10, 0.10, 0.17]
## Prędkość (m/s), jaką pokonuje klip przy tempie 1,0: do dopasowania kroków do ruchu (bez ślizgania).
const REF_BIEG := {"dwureczny": 4.0, "miecz": 3.9, "topor": 3.6, "piesci": 3.6}
const REF_BOK := {"dwureczny": 2.3, "miecz": 1.1, "topor": 1.1, "piesci": 1.1}
const REF_TYL := {"dwureczny": 2.5, "miecz": 4.1, "topor": 3.2, "piesci": 3.2}
const REF_CHOD := 1.2
const BLEND_PETLA := 0.2
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
var _kat_wiz := 0.0
var _kat_start := false
var _klucz_anim := ""
var _offsety: Dictionary = {}
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


## Wygląd krain (tekstury z paczki NightBrand, narzedzia/gra_3d/tekstury_swiat.py).
const WYGLAD := {
	"catacombs": {
		"a": "kat_plyty", "a_skala": 0.21, "b": "kat_kostka", "b_skala": 0.42, "c": "kat_mech", "c_skala": 0.24,
		"b_ilosc": 0.32, "c_ilosc": 0.22, "c_przy_murach": 0.75, "sciezka_b": 0.9, "kaluze": 0.6, "zar": 0.0,
		"ton": Color(0.88, 0.9, 0.96), "jasnosc": 0.95,
		"mur": "kat_mur", "mur_skala": 0.55, "akcent": "kat_mech", "wys_akcentu": 0.7, "sila_akcentu": 0.85, "mur_ton": Color(0.9, 0.95, 1.0), "mur_zar": 0.0,
		"otoczenie": Color(0.3, 0.38, 0.5), "otoczenie_sila": 0.38, "mgla": Color(0.32, 0.42, 0.5, 0.42), "ksiezyc": Color(0.5, 0.62, 0.9), "ksiezyc_sila": 0.3,
		"tlo": Color(0.006, 0.01, 0.014), "nasycenie": 0.88, "kontrast": 1.12, "pochodnie": Color(1.0, 0.68, 0.38), "swiatla": 1.0, "mur_jasnosc": 1.35,
	},
	"outskirts": {
		"a": "pod_bruk", "a_skala": 0.3, "b": "pod_ziemia", "b_skala": 0.2, "c": "pod_trawa", "c_skala": 0.3,
		"b_ilosc": 0.38, "c_ilosc": 0.28, "c_przy_murach": 0.55, "sciezka_b": 1.0, "kaluze": 0.3, "zar": 0.0,
		"ton": Color(0.92, 0.92, 0.95), "jasnosc": 1.0,
		"mur": "pod_mur", "mur_skala": 0.42, "akcent": "pod_ziemia", "wys_akcentu": 0.5, "sila_akcentu": 0.7, "mur_ton": Color(0.95, 0.95, 1.0), "mur_zar": 0.0,
		"otoczenie": Color(0.34, 0.38, 0.52), "otoczenie_sila": 0.45, "mgla": Color(0.45, 0.5, 0.6, 0.38), "ksiezyc": Color(0.6, 0.7, 1.0), "ksiezyc_sila": 0.85,
		"tlo": Color(0.01, 0.012, 0.02), "nasycenie": 0.85, "kontrast": 1.1, "pochodnie": Color(1.0, 0.7, 0.42), "swiatla": 1.0, "mur_jasnosc": 1.0,
	},
	"crypt": {
		"a": "kry_plyty", "a_skala": 0.36, "b": "kry_popiol", "b_skala": 0.2, "c": "kry_lawa", "c_skala": 0.3,
		"b_ilosc": 0.4, "c_ilosc": 0.12, "c_przy_murach": 0.3, "sciezka_b": 0.7, "kaluze": 0.0, "zar": 3.0,
		"ton": Color(0.95, 0.9, 0.88), "jasnosc": 1.25,
		"mur": "kry_mur", "mur_skala": 0.35, "akcent": "kry_lawa", "wys_akcentu": 0.32, "sila_akcentu": 0.9, "mur_ton": Color(1.0, 0.92, 0.88), "mur_zar": 1.4,
		"otoczenie": Color(0.5, 0.3, 0.26), "otoczenie_sila": 0.5, "mgla": Color(0.3, 0.16, 0.12, 0.3), "ksiezyc": Color(0.9, 0.5, 0.4), "ksiezyc_sila": 0.35,
		"tlo": Color(0.016, 0.006, 0.004), "nasycenie": 0.95, "kontrast": 1.14, "pochodnie": Color(1.0, 0.55, 0.25), "swiatla": 1.5, "mur_jasnosc": 2.2,
	},
}
var wyglad: Dictionary
var _szum: Texture2D
var _maska: Texture2D
const SHADER_TERENU := preload("res://zasoby/3d/shadery/teren.gdshader")
const SHADER_MURU := preload("res://zasoby/3d/shadery/mur.gdshader")
const SHADER_MGLY := preload("res://zasoby/3d/shadery/mgla.gdshader")


func _tsw(nazwa: String, rodzaj: String) -> Texture2D:
	return load("res://zasoby/3d/swiat/%s_%s" % [nazwa, "albedo.jpg" if rodzaj == "alb" else rodzaj + ".png"])


## Bezszwowy szum w trzech kanałach (różne częstotliwości), deterministyczny.
func _tekstura_szumu() -> Texture2D:
	var kan := []
	for i in 3:
		var fn := FastNoiseLite.new()
		fn.seed = 1337 + i * 71
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = [0.012, 0.025, 0.05][i]
		fn.fractal_octaves = 4
		kan.append(fn.get_seamless_image(256, 256))
	var im := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			im.set_pixel(x, y, Color(kan[0].get_pixel(x, y).r, kan[1].get_pixel(x, y).r, kan[2].get_pixel(x, y).r))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)


## Maska mapy dla shadera podłogi: R = bliskość muru (miękko), G = ścieżka, B = plamy (z ziarna kafla).
func _tekstura_maski() -> Texture2D:
	var mapa = rajd.mapa
	var P := 4
	var R := N * P
	var im := Image.create(R, R, false, Image.FORMAT_RGB8)
	for py in R:
		for px in R:
			var wx := (px + 0.5) / P
			var wy := (py + 0.5) / P
			var tx := int(wx)
			var ty := int(wy)
			var najb := 9.0
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var t: int = mapa.kafel(tx + dx, ty + dy)
					if t == K.MUR or t == K.FILAR:
						var cx := clampf(wx, tx + dx, tx + dx + 1)
						var cy := clampf(wy, ty + dy, ty + dy + 1)
						najb = minf(najb, Vector2(wx - cx, wy - cy).length())
			var bliskosc := clampf(1.0 - najb / 1.1, 0.0, 1.0)
			bliskosc = bliskosc * bliskosc
			var sc := 1.0 if mapa.kafel(tx, ty) == K.SCIEZKA else 0.0
			var plama := float(_hash(tx, ty) % 100) / 100.0
			im.set_pixel(px, py, Color(bliskosc, sc, plama))
	im.resize(R * 2, R * 2, Image.INTERPOLATE_CUBIC)
	return ImageTexture.create_from_image(im)


func _materialy() -> void:
	var id: String = rajd.kraina["id"]
	wyglad = WYGLAD.get(id, WYGLAD["catacombs"])
	var w := wyglad
	_szum = _tekstura_szumu()
	_maska = _tekstura_maski()
	var t := ShaderMaterial.new()
	t.shader = SHADER_TERENU
	for war in ["a", "b", "c"]:
		t.set_shader_parameter(war + "_alb", _tsw(w[war], "alb"))
		t.set_shader_parameter(war + "_nrm", _tsw(w[war], "normal"))
		t.set_shader_parameter(war + "_rh", _tsw(w[war], "rh"))
		t.set_shader_parameter(war + "_skala", w[war + "_skala"])
	t.set_shader_parameter("szum", _szum)
	t.set_shader_parameter("maska_mapy", _maska)
	t.set_shader_parameter("rozmiar_mapy", float(N))
	for k in ["b_ilosc", "c_ilosc", "c_przy_murach", "sciezka_b", "kaluze", "zar", "jasnosc"]:
		t.set_shader_parameter(k, w[k])
	t.set_shader_parameter("ton", w["ton"])
	_mat["podloga"] = t
	_mat["sciezka"] = t
	var m := ShaderMaterial.new()
	m.shader = SHADER_MURU
	m.set_shader_parameter("m_alb", _tsw(w["mur"], "alb"))
	m.set_shader_parameter("m_nrm", _tsw(w["mur"], "normal"))
	m.set_shader_parameter("m_rh", _tsw(w["mur"], "rh"))
	m.set_shader_parameter("d_alb", _tsw(w["akcent"], "alb"))
	m.set_shader_parameter("szum", _szum)
	m.set_shader_parameter("skala", w["mur_skala"])
	m.set_shader_parameter("d_skala", w["mur_skala"] * 0.8)
	m.set_shader_parameter("ton", w["mur_ton"])
	m.set_shader_parameter("wys_akcentu", w["wys_akcentu"])
	m.set_shader_parameter("sila_akcentu", w["sila_akcentu"])
	m.set_shader_parameter("zar", w["mur_zar"])
	m.set_shader_parameter("jasnosc", w["mur_jasnosc"])
	_mat["mur"] = m
	var f: ShaderMaterial = m.duplicate()
	f.set_shader_parameter("skala", w["mur_skala"] * 1.3)
	_mat["filar"] = f
	var g: ShaderMaterial = m.duplicate()
	g.set_shader_parameter("skala", w["mur_skala"] * 1.8)
	g.set_shader_parameter("wys_akcentu", 0.25)
	_mat["gruz"] = g
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
	e.background_color = wyglad["tlo"]
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = wyglad["otoczenie"]
	e.ambient_light_energy = wyglad["otoczenie_sila"]
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
	e.ssr_enabled = wyglad["kaluze"] > 0.0
	e.ssr_max_steps = 48
	e.ssr_fade_in = 0.2
	e.ssr_fade_out = 2.0
	e.fog_enabled = true
	e.fog_light_color = Color(wyglad["mgla"].r, wyglad["mgla"].g, wyglad["mgla"].b) * 0.2
	e.fog_density = 0.004
	e.fog_height = 0.35
	e.fog_height_density = 0.9
	e.adjustment_enabled = true
	e.adjustment_contrast = wyglad["kontrast"]
	e.adjustment_saturation = wyglad["nasycenie"]
	if lekki:
		e.ssr_enabled = false
		e.ssao_enabled = false
		e.ssil_enabled = false
		e.glow_enabled = false
		e.fog_enabled = false
	srodowisko.environment = e
	add_child(srodowisko)
	# chłodne światło wypełniające z góry (księżyc przez szczeliny): czytelne sylwetki w mroku
	var ksiezyc := DirectionalLight3D.new()
	ksiezyc.light_color = wyglad["ksiezyc"]
	ksiezyc.light_energy = wyglad["ksiezyc_sila"]
	ksiezyc.shadow_enabled = not lekki
	ksiezyc.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	ksiezyc.directional_shadow_max_distance = 40.0
	ksiezyc.shadow_opacity = 0.75
	add_child(ksiezyc)
	# z góry, od strony kamery: oświetla lica murów widoczne w rzucie izometrycznym, cienie padają w głąb
	ksiezyc.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -1.0, -0.75), Vector3.UP)


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
		"mur": _box(Vector3(1.0, WYS_MURU, 1.0)), "filar": _filar(), "gruz": _gruz(), "kamyki": _kamyk(),
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
				listy[podl].append([i, Basis(), 0.0])
			match t:
				K.MUR:
					# ruiny: nierówna wysokość murów (wyższe na obwodzie), lekki przekos
					var brzeg := x == 0 or y == 0 or x == N - 1 or y == N - 1
					var h := (1.25 if brzeg else 1.0) + float(_hash(x, y) % 9 - 4) * 0.045
					listy["mur"].append([i, Basis().scaled(Vector3(1.0, h, 1.0)), WYS_MURU * 0.5 * h])
				K.FILAR:
					if _hash(x, y) % 3 == 0:
						_postaw(i, "posag", 2.1, _hash(x, y) % 4 * PI * 0.5)
					else:
						listy["filar"].append([i, Basis(Vector3.UP, float(_hash(x, y) % 628) / 100.0), (WYS_MURU + 0.4) * 0.5])
				K.GRUZ:
					var g: String = ["glaz", "kolumna_lezaca", "kosci"][_hash(x, y) % 3]
					_postaw(i, g, 0.85 if g != "kosci" else 0.4, float(_hash(y, x) % 628) / 100.0)
					listy["gruz"].append([i, Basis(Vector3.UP, float(_hash(x, y) % 628) / 100.0).scaled(Vector3(1.4, 0.5, 1.1)), 0.02])
			# drobny gruz u podstawy murów: osypane kamienie (tylko wygląd)
			if t == K.PODLOGA or t == K.SCIEZKA:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if mapa.kafel(x + d.x, y + d.y) != K.MUR:
						continue
					var ile := _hash(x * 3 + d.x, y * 5 + d.y) % 4
					for k in ile:
						var hh := _hash(x * 31 + k * 7 + d.x, y * 17 + k * 3 + d.y)
						var wzdluz := float(hh % 100) / 100.0 - 0.5
						var odsun := 0.38 - float((hh / 100) % 25) / 100.0
						var off := Vector3(d.x * odsun + (wzdluz if d.x == 0 else 0.0) * 0.9, 0.0, d.y * odsun + (wzdluz if d.y == 0 else 0.0) * 0.9)
						var sk := 0.5 + float((hh / 7) % 100) / 100.0
						var b := Basis(Vector3.UP, float(hh % 628) / 100.0).scaled(Vector3(sk, sk * 0.7, sk * 0.9))
						listy["kamyki"].append([i, b, 0.02 * sk, off])
	for k in listy.keys():
		var mmi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = siatki[k]
		mm.instance_count = listy[k].size()
		for n in listy[k].size():
			var wp: Array = listy[k][n]
			var i: int = wp[0]
			var p := Vector3(i % N + 0.5, 0.0, i / N + 0.5)
			if wp.size() > 3:
				p += wp[3]
			mm.set_instance_transform(n, Transform3D(Basis().scaled(Vector3.ZERO), p))
			mm.set_instance_color(n, Color(0, 0, 0, 0))
			if not _indeks.has(i):
				_indeks[i] = []
			_indeks[i].append([k, n, p, wp[1], wp[2]])
		mmi.multimesh = mm
		var mk: String = {"sciezka": "podloga", "ekstrakcja": "podloga", "kamyki": "gruz"}.get(k, k)
		mmi.material_override = _mat[mk]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if k in ["mur", "filar", "gruz"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_mm[k] = mmi


func _kamyk() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.09
	m.height = 0.12
	m.radial_segments = 6
	m.rings = 3
	return m


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


## Pochodnie w uchwytach na murach (co kilka pól, deterministycznie): ciepłe plamy światła i cienie.
func _pochodnie_scienne() -> void:
	var mapa = rajd.mapa
	var start: Vector2 = mapa.start
	var postawione: Array = []
	for y in range(1, N - 1):
		for x in range(1, N - 1):
			var t: int = mapa.kafel(x, y)
			if t != K.PODLOGA and t != K.SCIEZKA:
				continue
			if _hash(x * 7, y * 13) % 7 != 0:
				continue
			var sciana := Vector2i.ZERO
			for d in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]:
				if mapa.kafel(x + d.x, y + d.y) == K.MUR:
					sciana = d
					break
			if sciana == Vector2i.ZERO:
				continue
			var w := Vector2(x + 0.5, y + 0.5)
			var za_blisko := false
			for q in postawione:
				if (q as Vector2).distance_to(w) < 5.0:
					za_blisko = true
			if za_blisko:
				continue
			postawione.append(w)
			var n := Node3D.new()
			n.position = Vector3(w.x + sciana.x * 0.42, 0.0, w.y + sciana.y * 0.42)
			# uchwyt: płaska żelazna obejma i drzewce
			var uchwyt := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.08, 0.3, 0.08)
			uchwyt.mesh = bm
			uchwyt.material_override = _mat["zelazo"]
			uchwyt.position = Vector3(0, 1.25, 0)
			n.add_child(uchwyt)
			var drz := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.035
			cm.bottom_radius = 0.025
			cm.height = 0.42
			drz.mesh = cm
			drz.material_override = _mat["drewno"]
			drz.position = Vector3(-sciana.x * 0.1, 1.42, -sciana.y * 0.1)
			drz.rotation = Vector3(-sciana.y * 0.35, 0, sciana.x * 0.35)
			n.add_child(drz)
			var ogien := _ogien(0.9, 0.9)
			ogien.position = Vector3(-sciana.x * 0.17, 1.66, -sciana.y * 0.17)
			n.add_child(ogien)
			var l := _swiatlo(wyglad["pochodnie"], 2.6 * wyglad["swiatla"], 6.5)
			l.position = Vector3(-sciana.x * 0.45, 1.7, -sciana.y * 0.45)
			l.set_meta("migotanie", true)
			n.add_child(l)
			n.visible = false
			add_child(n)
			_pochodnie_murow.append([n, mapa.idx(x, y), mapa.idx(x + sciana.x, y + sciana.y)])


## Atmosfera: przyziemna mgła, pył/popiół/iskry w powietrzu, plamy na podłodze (krew, sadza, wilgoć).
var _pyl: GPUParticles3D
var _pochodnie_murow: Array = []  # [węzeł, pole przed murem, pole muru]
var _mury_ciete := {}
func _atmosfera() -> void:
	if not lekki:
		for warstwa in [[0.12, 1.0, 0.06], [0.45, 0.6, 0.035]]:
			var mg := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(N + 16, N + 16)
			mg.mesh = pm
			var mm := ShaderMaterial.new()
			mm.shader = SHADER_MGLY
			mm.set_shader_parameter("szum", _szum)
			var k: Color = wyglad["mgla"]
			mm.set_shader_parameter("kolor", Color(k.r, k.g, k.b, k.a * warstwa[1]))
			mm.set_shader_parameter("skala", warstwa[2])
			mg.material_override = mm
			mg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mg.position = Vector3(N * 0.5, warstwa[0], N * 0.5)
			add_child(mg)
	# cząstki w powietrzu wokół gracza
	_pyl = GPUParticles3D.new()
	var id: String = rajd.kraina["id"]
	var zar: bool = id == "crypt"
	_pyl.amount = 60 if lekki else (150 if zar else 180)
	_pyl.lifetime = 7.0
	_pyl.preprocess = 7.0
	_pyl.local_coords = false
	_pyl.visibility_aabb = AABB(Vector3(-12, -1, -12), Vector3(24, 6, 24))
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ppm.emission_box_extents = Vector3(6.5, 1.4, 6.5) if zar else Vector3(5.5, 1.2, 5.5)
	ppm.direction = Vector3(0.3, 1.0 if zar else -0.2, 0.1)
	ppm.spread = 40.0
	ppm.initial_velocity_min = 0.05
	ppm.initial_velocity_max = 0.35 if zar else 0.15
	ppm.gravity = Vector3(0.05, 0.12 if zar else -0.02, 0.02)
	ppm.turbulence_enabled = true
	ppm.turbulence_noise_strength = 0.6
	ppm.turbulence_noise_scale = 3.0
	ppm.scale_min = 0.4
	ppm.scale_max = 1.2
	var gr := Gradient.new()
	var kol := Color(1.0, 0.45, 0.12) if zar else (Color(0.75, 0.8, 0.9) if id == "catacombs" else Color(0.8, 0.78, 0.74))
	gr.set_color(0, Color(kol.r, kol.g, kol.b, 0.0))
	gr.add_point(0.2, Color(kol.r, kol.g, kol.b, 0.9 if zar else 0.45))
	gr.add_point(0.8, Color(kol.r, kol.g, kol.b, 0.7 if zar else 0.35))
	gr.set_color(gr.get_point_count() - 1, Color(kol.r, kol.g, kol.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = gr
	ppm.color_ramp = gt
	_pyl.process_material = ppm
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05) if zar else Vector2(0.035, 0.035)
	var m := ShaderMaterial.new()
	m.shader = preload("res://zasoby/3d/shadery/czastka.gdshader")
	m.set_shader_parameter("sila", 2.6 if zar else 0.9)
	q.material = m
	_pyl.draw_pass_1 = q
	_pyl.position = Vector3(rajd.gracz.w.x, 1.2, rajd.gracz.w.y)
	add_child(_pyl)
	_plamy()


## Plamy na podłodze (Decal): krew przy gruzie i kościach, sadza przy koszach, zacieki — deterministyczne.
func _plamy() -> void:
	if lekki:
		return
	var mapa = rajd.mapa
	var tex_krew := _tekstura_plamy(1, Color(0.22, 0.015, 0.01, 0.92))
	var tex_sadza := _tekstura_plamy(2, Color(0.02, 0.016, 0.014, 0.85))
	for y in range(2, N - 2):
		for x in range(2, N - 2):
			var t: int = mapa.kafel(x, y)
			if t != K.PODLOGA and t != K.SCIEZKA:
				continue
			var hh := _hash(x * 11, y * 29)
			var rodzaj := ""
			if hh % 37 == 0:
				rodzaj = "krew"
			elif hh % 29 == 0:
				rodzaj = "sadza"
			if rodzaj == "":
				continue
			var d := Decal.new()
			d.texture_albedo = tex_krew if rodzaj == "krew" else tex_sadza
			var r := 0.45 + float(hh % 60) / 80.0
			d.size = Vector3(r * 1.6, 0.6, r * 1.6)
			d.position = Vector3(x + 0.5 + float(hh % 7 - 3) * 0.08, 0.0, y + 0.5 + float((hh / 7) % 7 - 3) * 0.08)
			d.rotation.y = float(hh % 628) / 100.0
			d.upper_fade = 0.5
			d.lower_fade = 0.5
			d.albedo_mix = 0.9
			d.cull_mask = 1
			d.visible = false
			add_child(d)
			_dekor.append([d, mapa.idx(x, y)])
	for k in mapa.kosze:
		var w: Vector2 = k
		var d2 := Decal.new()
		d2.texture_albedo = tex_sadza
		d2.size = Vector3(3.2, 0.8, 3.2)
		d2.position = Vector3(w.x, 0.0, w.y)
		d2.albedo_mix = 0.75
		add_child(d2)


func _tekstura_plamy(ziarno: int, kolor: Color) -> Texture2D:
	var fn := FastNoiseLite.new()
	fn.seed = ziarno * 97
	fn.frequency = 0.03
	fn.fractal_octaves = 5
	var R := 256
	var im := Image.create(R, R, false, Image.FORMAT_RGBA8)
	for y in R:
		for x in R:
			var p := Vector2(x, y) / R * 2.0 - Vector2.ONE
			var r := p.length()
			var n := fn.get_noise_2d(x, y) * 0.5 + 0.5
			var a := clampf((1.0 - r * 1.05) * 1.6 + (n - 0.5) * 1.4, 0.0, 1.0)
			a = smoothstep(0.25, 0.6, a)
			# drobne krople wokół
			var kropla := fn.get_noise_2d(x * 4.0 + 500.0, y * 4.0) > 0.42 and r < 0.95
			if kropla:
				a = maxf(a, 0.85)
			var c := kolor * (0.8 + n * 0.4)
			im.set_pixel(x, y, Color(c.r, c.g, c.b, a * kolor.a))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)


func _plyta() -> Mesh:
	var m := PlaneMesh.new()
	m.size = Vector2(1.0, 1.0)
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
		if dx + dy > 0.6 and absf(dx) < 9.5 and absf(dy) < 9.5 and absf(dx - dy) < 11.0:
			przezr = true
		_mury_ciete[i] = przezr
		var klucz := v + (100 if przezr else 0)
		if _stan_widoku[i] == klucz:
			continue
		_stan_widoku[i] = klucz
		for wpis in _indeks[i]:
			var rodzaj: String = wpis[0]
			var mm: MultiMesh = _mm[rodzaj].multimesh
			var jasn := 0.0 if v == 0 else (1.0 if v == 2 else 0.3)
			var p: Vector3 = wpis[2]
			var b: Basis = wpis[3]
			var y: float = wpis[4]
			if v == 0:
				b = Basis().scaled(Vector3.ZERO)
			# mur między kamerą a graczem obniżony do cokołu (jak w grach izometrycznych AAA)
			if przezr and (rodzaj == "mur" or rodzaj == "filar") and v != 0:
				var h := 0.22
				var pelna := WYS_MURU if rodzaj == "mur" else WYS_MURU + 0.4
				b = Basis(b.get_rotation_quaternion()).scaled(Vector3(1.0, h / pelna, 1.0))
				y = h * 0.5
			if rodzaj == "ekstrakcja":
				mm.set_instance_color(wpis[1], Color(jasn * 0.7, jasn * 1.0, jasn * 0.85, 1.0))
			else:
				mm.set_instance_color(wpis[1], Color(jasn, jasn, jasn, 1.0))
			mm.set_instance_transform(wpis[1], Transform3D(b, Vector3(p.x, y, p.z)))
	for sk in _skrzynie:
		var v2: int = widok[rajd.mapa.idx(sk["tx"], sk["ty"])]
		sk["wezel3d"].visible = v2 > 0
	for d in _dekor:
		(d[0] as Node3D).visible = widok[d[1]] > 0
	for pm in _pochodnie_murow:
		(pm[0] as Node3D).visible = widok[pm[1]] > 0 and not _mury_ciete.get(pm[2], false)


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
		var l := _swiatlo(Color(1.0, 0.6, 0.28), 3.6 * wyglad["swiatla"], 8.0)
		l.position.y = 1.5
		l.set_meta("migotanie", true)
		kosz.add_child(l)
		kosz.visible = false
		add_child(kosz)
		_dekor.append([kosz, mapa.idx(int(w.x), int(w.y))])
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
	_pochodnie_scienne()
	_atmosfera()
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


## Obrót ciała z ograniczoną prędkością i wygładzeniem (bez „śmigła” przy szybkim ruchu myszki).
static func _obracaj(od: float, do: float, max_rad_s: float, dt: float) -> float:
	var r := angle_difference(od, do)
	var krok := r * (1.0 - exp(-dt * 20.0))
	var lim := max_rad_s * dt
	return od + clampf(krok, -lim, lim)


## Wizualne przesunięcie ciała (doskok, odrzut): logika przeskakuje od razu, widok dopływa płynnie.
func impuls(cialo, d: Vector2) -> void:
	var id: int = cialo.get_instance_id()
	var stary: Vector2 = _offsety.get(id, Vector2.ZERO)
	_offsety[id] = stary - d


func _offset(cialo, dt: float) -> Vector2:
	var id: int = cialo.get_instance_id()
	var o: Vector2 = _offsety.get(id, Vector2.ZERO)
	if o != Vector2.ZERO:
		o *= exp(-dt * 11.0)
		if o.length() < 0.003:
			o = Vector2.ZERO
		_offsety[id] = o
	return o


func _kat_celu(p) -> float:
	if p.unik_czas > 0.0 and p.unik_kier != Vector2.ZERO:
		return atan2(p.unik_kier.y, p.unik_kier.x)
	if p.zamach_anim > 0.0:
		return p.atak_kat
	return p.kat


## Co ma grać Hadræn: [nazwa bez zestawu, klucz stanu, pętla?, tempo, start (s klipu), blend].
func _plan_animacji(p, styl: String) -> Array:
	if p.martwy:
		return ["smierc", "smierc", false, 1.0, 0.0, 0.25]
	if p.unik_czas > 0.0:
		# przewrót: klip 1,03 s, gra się od 4% do 80% w czasie uniku (0,3 s)
		return ["przewrot", "przewrot", false, 0.76 * 1.03 / p.UNIK_DLUGOSC, 0.04, 0.05]
	if p.zamach_anim > 0.0:
		var plan: Array = ATAK_PLAN[styl][clampi(p.combo, 0, 2)]
		var d: float = maxf(p.zamach_anim_max, 0.2)
		var przed: float = minf(ATAK_PRZED[clampi(p.combo, 0, 2)], d * 0.45)
		var ts := maxf(0.0, (plan[0] - przed * plan[1] / d) / (1.0 - przed / d))
		return ["atak%d" % (p.combo + 1), "atak%d_%d" % [p.combo, p.atak_licznik], false, (plan[1] - ts) / d, ts, 0.07]
	if p.blok:
		if p.okno_parowania > 0.0 and p.blok_czas < 0.35:
			return ["parowanie", "parowanie", false, clampf(_dl_klipu(styl + "_parowanie") / 0.4, 1.0, 2.2), 0.0, 0.05]
		return ["blok", "blok", true, 1.0, 0.0, BLEND_PETLA]
	if p.w_ruchu and p.ruch_wektor != Vector2.ZERO:
		var v: float = p.ruch_wektor.length()
		var rel := angle_difference(_kat_wiz, atan2(p.ruch_wektor.y, p.ruch_wektor.x))
		if absf(rel) > 2.36:
			return ["tyl", "tyl", true, clampf(v / REF_TYL[styl], 0.8, 1.5), 0.0, BLEND_PETLA]
		if absf(rel) > 0.79:
			# świat: +y to prawa strona postaci (patrz _obrot)
			return ["prawo" if rel > 0.0 else "lewo", "prawo" if rel > 0.0 else "lewo", true, clampf(v / REF_BOK[styl], 0.8, 1.6), 0.0, BLEND_PETLA]
		if v > 2.4:
			return ["bieg", "bieg", true, clampf(v / REF_BIEG[styl], 0.8, 1.5), 0.0, BLEND_PETLA]
		return ["chod", "chod", true, clampf(v / REF_CHOD, 0.8, 1.6), 0.0, BLEND_PETLA]
	return ["postoj", "postoj", true, 1.0, 0.0, BLEND_PETLA]


func _dl_klipu(nazwa: String) -> float:
	return _ap_bohatera.get_animation(nazwa).length if _ap_bohatera.has_animation(nazwa) else 1.0


func _aktualizuj_bohatera(dt: float) -> void:
	var p = rajd.gracz
	var zestaw: String = p.zestaw
	var styl: String = ZESTAW_ANIM.get(zestaw, "dwureczny")
	if not _kat_start:
		_kat_start = true
		_kat_wiz = p.kat
	var szybki: bool = p.zamach_anim > 0.0 or p.unik_czas > 0.0
	_kat_wiz = _obracaj(_kat_wiz, _kat_celu(p), 26.0 if szybki else 15.0, dt)
	var o := _offset(p, dt)
	bohater.position = Vector3(p.w.x + o.x, 0.0, p.w.y + o.y)
	bohater.rotation.y = _obrot(_kat_wiz)
	var pl := _plan_animacji(p, styl)
	var nazwa: String = styl + "_" + str(pl[0])
	if _ap_bohatera.has_animation(nazwa):
		if pl[1] != _klucz_anim or _ap_bohatera.current_animation != nazwa:
			_klucz_anim = pl[1]
			_ap_bohatera.play(nazwa, pl[5])
			if pl[4] > 0.0:
				_ap_bohatera.seek(pl[4], false)
		_ap_bohatera.speed_scale = pl[3]
	p.biezaca_anim = pl[0] if pl[0] not in ["bieg", "tyl", "lewo", "prawo"] else "chod"
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
	# zapowiedź ciosu na ziemi: klin zasięgu wypełniający się aż do uderzenia
	var znak := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var r: float = (12.0 if en.rodzaj == "archer" else en.zasieg + 0.55)
	pm.size = Vector2(r * 2.0, r * 2.0)
	znak.mesh = pm
	var zm := ShaderMaterial.new()
	zm.shader = _shader_znaku()
	zm.set_shader_parameter("kolor", Color(1.0, 0.25, 0.12) if en.ciezki else (Color(0.75, 0.85, 1.0) if en.rodzaj == "archer" else Color(1.0, 0.8, 0.3)))
	zm.set_shader_parameter("kat", 0.07 if en.rodzaj == "archer" else 1.05)
	zm.set_shader_parameter("promien", r)
	znak.material_override = zm
	znak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	znak.position.y = 0.03
	znak.top_level = true
	znak.visible = false
	n.add_child(znak)
	# błysk broni: moment, w którym trzeba wcisnąć parowanie
	var gw := Sprite3D.new()
	gw.texture = _tekstura_blysku()
	gw.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gw.shaded = false
	gw.no_depth_test = true
	gw.render_priority = 10
	gw.pixel_size = 0.0045
	gw.modulate = Color(1.0, 0.45, 0.3) if en.ciezki else Color(1.0, 0.93, 0.6)
	gw.top_level = true
	gw.visible = false
	n.add_child(gw)
	var bron: Node3D = null
	for c in n.find_children("bron_*", "", true, false):
		if c is Node3D and (c as Node3D).visible and c.name != "bron_tarcza":
			bron = c
			break
	var d := {"wezel": n, "ap": ap, "swiatlo": l, "blysk": blysk, "martwy": false, "smierc": 0.0, "wrog": weakref(en), "kat": en.kat,
		"znak": znak, "znak_mat": zm, "glint": gw, "bron": bron, "zamach_byl": false, "glint_byl": false}
	_wrogowie[id] = d
	return d


## Czas przed uderzeniem, w którym pojawia się błysk „paruj teraz” (okno parowania ≥ 0,28 s, więc wciśnięcie na błysk zawsze zdąży).
const BLYSK_PRZED := 0.26


func _zapowiedz(en, d: Dictionary, t: float, widac: bool) -> void:
	var znak: MeshInstance3D = d["znak"]
	var zm: ShaderMaterial = d["znak_mat"]
	if not d["zamach_byl"]:
		d["zamach_byl"] = true
		d["glint_byl"] = false
		if widac:
			Dzwiek.zapowiedz(en.ciezki)
	znak.visible = widac
	znak.global_position = Vector3(en.w.x, 0.03, en.w.y)
	znak.global_rotation = Vector3(0, -en.kat, 0)
	zm.set_shader_parameter("postep", t)
	zm.set_shader_parameter("sila", 1.0)
	var gw: Sprite3D = d["glint"]
	var zostalo: float = en.zamach
	if en.rodzaj != "archer" and zostalo <= BLYSK_PRZED:
		if not d["glint_byl"]:
			d["glint_byl"] = true
			if widac:
				Dzwiek.blysk(en.ciezki)
		var f := 1.0 - zostalo / BLYSK_PRZED
		var bron: Node3D = d["bron"]
		var gdzie: Vector3 = (bron.global_position if bron else d["wezel"].global_position + Vector3(0, 1.6, 0)) + Vector3(0, 0.25, 0)
		gw.global_position = gdzie
		gw.visible = widac
		gw.scale = Vector3.ONE * (0.6 + 1.4 * sin(f * PI) + 0.2)
		gw.rotation.z = f * 1.6
	else:
		gw.visible = false


func _zgas_zapowiedz(d: Dictionary, dt: float) -> void:
	d["zamach_byl"] = false
	(d["glint"] as Sprite3D).visible = false
	var znak: MeshInstance3D = d["znak"]
	if znak.visible:
		var zm: ShaderMaterial = d["znak_mat"]
		var sila: float = zm.get_shader_parameter("sila")
		sila -= dt * 5.0
		zm.set_shader_parameter("sila", sila)
		zm.set_shader_parameter("postep", 1.0)
		if sila <= 0.0:
			znak.visible = false


var _sh_znak: Shader
func _shader_znaku() -> Shader:
	if _sh_znak == null:
		_sh_znak = Shader.new()
		_sh_znak.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 kolor : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float kat = 1.05;
uniform float postep = 0.0;
uniform float sila = 1.0;
uniform float promien = 2.0;
varying vec2 lok;
void vertex() {
	lok = VERTEX.xz / promien;
}
void fragment() {
	float r = length(lok);
	float a = abs(atan(lok.y, lok.x));
	float w_kacie = 1.0 - smoothstep(kat - 0.04, kat, a);
	float w_kole = 1.0 - smoothstep(0.97, 1.0, r);
	float obszar = w_kacie * w_kole * smoothstep(0.12, 0.25, r);
	// fala wypełnienia: od wroga do granicy zasięgu, jasny front
	float wyp = 1.0 - smoothstep(postep - 0.02, postep, r);
	float front = exp(-pow((r - postep) * 14.0, 2.0)) * step(r, 1.0);
	float brzeg = smoothstep(0.9, 0.975, r) * w_kole;
	float boki = smoothstep(kat - 0.1, kat - 0.03, a) * w_kacie;
	float m = obszar * (0.05 + 0.16 * wyp + 0.55 * front + 0.5 * brzeg + 0.35 * boki);
	ALBEDO = kolor.rgb;
	ALPHA = clamp(m * sila, 0.0, 1.0);
}
"""
	return _sh_znak


var _tex_blysk: Texture2D
func _tekstura_blysku() -> Texture2D:
	if _tex_blysk == null:
		var n := 128
		var im := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var p := (Vector2(x, y) - Vector2(n, n) * 0.5) / (n * 0.5)
				var r := p.length()
				var promien := exp(-abs(p.x) * 26.0) * exp(-abs(p.y) * 2.2) + exp(-abs(p.y) * 26.0) * exp(-abs(p.x) * 2.2)
				var rog := exp(-abs(p.x + p.y) * 30.0) * exp(-r * 4.0) * 0.5 + exp(-abs(p.x - p.y) * 30.0) * exp(-r * 4.0) * 0.5
				var rdzen := exp(-r * r * 30.0)
				var v := clampf(promien + rog + rdzen, 0.0, 1.0)
				im.set_pixel(x, y, Color(1, 1, 1, v))
		_tex_blysk = ImageTexture.create_from_image(im)
	return _tex_blysk


func _aktualizuj_wrogow(dt: float, czas: float) -> void:
	var zywi := {}
	for en in rajd.wrogowie:
		var d := _wrog3d(en)
		zywi[en.get_instance_id()] = true
		var n: Node3D = d["wezel"]
		var oo := _offset(en, dt)
		n.position = Vector3(en.w.x + oo.x, 0.0, en.w.y + oo.y)
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
			_zapowiedz(en, d, t, n.visible)
		elif en.cios_anim > 0.0:
			_graj(ap, "cios", 1.0 - en.cios_anim / 0.34)
		elif en.trafiony > 0.0:
			_graj(ap, "trafienie", 1.0 - en.trafiony / 0.15)
		elif czas - en._ruch_czas < 0.15:
			_graj(ap, "chod", -1.0, en.spd / 2.0)
		else:
			_graj(ap, "postoj", -1.0)
		if en.zamach <= 0.0 or en.ogluszenie > 0.0:
			_zgas_zapowiedz(d, dt)
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
			(d2["znak"] as MeshInstance3D).visible = false
			(d2["glint"] as Sprite3D).visible = false
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
	if _pyl:
		_pyl.position = Vector3(rajd.gracz.w.x, 1.2, rajd.gracz.w.y)
	_aktualizuj_bohatera(dt)
	_aktualizuj_wrogow(dt, czas)
	_aktualizuj_rekwizyty(czas)
