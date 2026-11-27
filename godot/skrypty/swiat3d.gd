extends Node3D
## Świat rajdu w 3D (Forward+). Tylko wygląd: reguły dalej liczy rajd.gd na współrzędnych świata.
## Układ: świat (x, y) w polach -> 3D (x, 0, y), 1 pole = 1 m. Kamera ortogonalna w rzucie Iso
## (64x32 px na pole), więc paski HP, napisy i efekty 2D rysowane nad sceną trafiają w postacie.

const WygladPostaci = preload("res://skrypty/wyglad_postaci.gd")
const WygladRynsztunku = preload("res://skrypty/wyglad_rynsztunku.gd")
const Iso = preload("res://skrypty/iso.gd")
const Mapgen = preload("res://skrypty/mapgen.gd")
const K = Mapgen.K
const MapgenLas = preload("res://skrypty/mapgen_las.gd")
const T = MapgenLas.T
const MapgenOsada = preload("res://skrypty/mapgen_osada.gd")
const TO = MapgenOsada.T
const N := Mapgen.ROZMIAR
const PX_NA_M := 45.254834  # 32 * sqrt(2): pole świata -> piksele ekranu (zgodnie z Iso)
const WYS_MURU := 1.7
const WYS_COKOLU := 0.22  # wysokość muru obniżonego w przekroju przed bohaterem

const GLB_BOHATERA := WygladRynsztunku.SCENA
const ZESTAW_ANIM := {"dwureczny": "dwureczny", "glewia": "glewia", "topor": "topor",
	"miecz": "miecz", "miecz_tarcza": "miecz", "piesci": "piesci"}
const PETLE := ["postoj", "chod", "blok", "ogluszenie", "bieg", "tyl", "lewo", "prawo"]
## Ciosy Hadræna: [moment uderzenia w klipie, koniec ruchu po uderzeniu] w sekundach klipu (zmierzone na dłoni).
## Klip jest odtwarzany jednym, stałym tempem tak, by uderzenie wypadło ~0,1 s po wciśnięciu ataku (okno trafienia w rajd.gd bez zmian).
const ATAK_PLAN := {
	"glewia": [[0.75, 1.70], [0.85, 1.75], [0.85, 1.85]],
	"dwureczny": [[0.33, 0.70], [0.49, 0.95], [0.26, 0.85]],
	"miecz": [[0.56, 1.00], [0.53, 1.20], [1.17, 1.38]],
	"piesci": [[0.30, 0.75], [0.30, 0.75], [0.59, 1.30]],
	"topor": [[0.83, 1.55], [0.92, 1.70], [0.85, 1.60]],
}
const ATAK_PRZED := [0.10, 0.10, 0.17]
## Prędkość (m/s), jaką pokonuje klip przy tempie 1,0: do dopasowania kroków do ruchu (bez ślizgania).
const REF_BIEG := {"dwureczny": 4.0, "glewia": 4.0, "miecz": 3.9, "topor": 3.6, "piesci": 3.6}
const REF_BOK := {"dwureczny": 2.3, "glewia": 2.3, "miecz": 1.1, "topor": 1.1, "piesci": 1.1}
const REF_TYL := {"dwureczny": 2.5, "glewia": 2.5, "miecz": 4.1, "topor": 3.2, "piesci": 3.2}
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
var _wyglad_rynsztunku := WygladRynsztunku.new()
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
var lekki := false  # tryb testowy albo jakość Niska: bez cieni i efektów ekranowych
var jakosc := 2      # 0 Niska, 1 Średnia, 2 Wysoka, 3 Ultra (Profil.jakosc)
var las := false     # biotop otwarty (Czarnobór, Spalona Osada): ściana z natury zamiast murów lochu
var osada := false   # Spalona Osada: palisady, spalone chaty, martwe drzewa, żar (las == true)
var _teren := PackedByteArray()
var _odl_przejscia := PackedByteArray()  # las: odległość (w polach, do 6) od najbliższego pola przechodniego
var _kotwica := PackedInt32Array()        # las: najbliższe pole przechodnie — od niego zależy widoczność drzewa (mgła wojny)
var _kotwica_pelna := PackedInt32Array()  # najbliższe pole przechodnie bez limitu odległości (wierzch skały, korony lasu)
# Mgła wojny płynnie (autor 26.11: „assety długo się ładują przy odsłanianiu”): nieznane jest niewidoczne
# (jak dotąd — nie zdradza mapy), a odsłonięte wyłania się z czerni i rozjaśnia w ~0,3 s zamiast wyskakiwać.
var _jasn := PackedFloat32Array()
var _cel_jasn := PackedFloat32Array()
var _fade := {}
var _indeks_wys := {}   # pole, na którym rzecz NAPRAWDĘ stoi -> [[rodzaj, nr, p, basis, y]] (drzewa, korony, wierzch skały)
var _maska_widocznych := {} # pole -> bity widocznych wpisów (odkryta kotwica i nie w przekroju przed bohaterem)
var _do_sprawdzenia := {}    # pola wysokich rzeczy, których kotwica zmieniła stan widoku
const CZAS_ODSLONY := 0.3
const CZAS_PRZYGASZENIA := 0.7
const SHADER_OTOCZENIA := preload("res://zasoby/3d/shadery/otoczenie.gdshader")


func zbuduj(r) -> void:
	rajd = r
	lekki = ("--test" in OS.get_cmdline_user_args() or "--lekki" in OS.get_cmdline_user_args()) and not "--pelna" in OS.get_cmdline_user_args()
	jakosc = 3 if "--pelna" in OS.get_cmdline_user_args() else Profil.jakosc()
	if not lekki:
		var vp0 := get_viewport()
		vp0.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][jakosc]
		vp0.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if jakosc <= 1 else Viewport.SCREEN_SPACE_AA_DISABLED
		vp0.scaling_3d_scale = 0.75 if jakosc == 0 else 1.0
		if jakosc == 0:
			lekki = true  # Niska: ścieżka jak w trybie lekkim (bez cieni świateł, SSAO, odbić, mgły, plam)
	if lekki and jakosc != 0:
		var vp := get_viewport()
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		vp.scaling_3d_scale = 0.5
	var typ_krainy := String(rajd.kraina.get("typ", ""))
	las = typ_krainy in ["las", "osada"]
	osada = typ_krainy == "osada"
	if las:
		_teren = rajd.mapa.teren
		_licz_odl_przejscia()
	_licz_kotwice_pelna()
	_licz_zalezne()
	_jasn.resize(N * N)
	_cel_jasn.resize(N * N)
	_materialy()
	_srodowisko()
	_kamera()
	_otoczenie_materialy()
	_mapa()
	_otoczenie()
	_rekwizyty()
	_bohater()
	_wyostrzenie()
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
		"tlo": Color(0.006, 0.01, 0.014), "nasycenie": 1.08, "kontrast": 1.12, "pochodnie": Color(1.0, 0.68, 0.38), "swiatla": 1.3, "mur_jasnosc": 1.35,
	},
	"outskirts": {
		"a": "pod_bruk", "a_skala": 0.3, "b": "pod_ziemia", "b_skala": 0.2, "c": "pod_trawa", "c_skala": 0.3,
		"b_ilosc": 0.38, "c_ilosc": 0.28, "c_przy_murach": 0.55, "sciezka_b": 1.0, "kaluze": 0.3, "zar": 0.0,
		"ton": Color(0.92, 0.92, 0.95), "jasnosc": 1.0,
		"mur": "pod_mur", "mur_skala": 0.42, "akcent": "pod_ziemia", "wys_akcentu": 0.5, "sila_akcentu": 0.7, "mur_ton": Color(0.95, 0.95, 1.0), "mur_zar": 0.0,
		"otoczenie": Color(0.34, 0.38, 0.52), "otoczenie_sila": 0.45, "mgla": Color(0.45, 0.5, 0.6, 0.38), "ksiezyc": Color(0.6, 0.7, 1.0), "ksiezyc_sila": 0.85,
		"tlo": Color(0.01, 0.012, 0.02), "nasycenie": 1.06, "kontrast": 1.1, "pochodnie": Color(1.0, 0.7, 0.42), "swiatla": 1.0, "mur_jasnosc": 1.0,
	},
	"czarnobor": {
		"a": "las_mech", "a_skala": 0.2, "b": "las_ziemia", "b_skala": 0.26, "c": "las_liscie", "c_skala": 0.3,
		"b_ilosc": 0.22, "c_ilosc": 0.3, "c_przy_murach": 0.95, "sciezka_b": 1.0, "kaluze": 0.15, "zar": 0.0,
		"ton": Color(0.9, 0.95, 0.88), "jasnosc": 1.05,
		"mur": "las_skala", "mur_skala": 0.3, "akcent": "las_mchy", "wys_akcentu": 0.85, "sila_akcentu": 0.95, "mur_ton": Color(0.9, 0.95, 0.9), "mur_zar": 0.0,
		"otoczenie": Color(0.26, 0.34, 0.3), "otoczenie_sila": 0.5, "mgla": Color(0.34, 0.44, 0.42, 0.5), "ksiezyc": Color(0.55, 0.68, 0.9), "ksiezyc_sila": 0.95,
		"tlo": Color(0.004, 0.009, 0.006), "nasycenie": 1.05, "kontrast": 1.1, "pochodnie": Color(1.0, 0.66, 0.38), "swiatla": 1.15, "mur_jasnosc": 1.1,
		"sciezka_jasn": 1.55, "sciezka_czysta": 0.85,  # autor 26.11: widoczna, wydeptana ścieżka (do strojenia)
	},
	"spalona_osada": {
		"a": "os_popiol", "a_skala": 0.22, "b": "os_ziemia", "b_skala": 0.24, "c": "os_wegiel", "c_skala": 0.26,
		"b_ilosc": 0.3, "c_ilosc": 0.2, "c_przy_murach": 0.85, "sciezka_b": 1.0, "kaluze": 0.05, "zar": 1.1,
		"ton": Color(0.96, 0.9, 0.85), "jasnosc": 1.12,
		"mur": "os_palisada", "mur_skala": 0.5, "akcent": "os_wegiel", "wys_akcentu": 0.45, "sila_akcentu": 0.85, "mur_ton": Color(0.95, 0.88, 0.82), "mur_zar": 0.5,
		"otoczenie": Color(0.36, 0.32, 0.32), "otoczenie_sila": 0.45, "mgla": Color(0.27, 0.26, 0.29, 0.42), "ksiezyc": Color(0.62, 0.64, 0.78), "ksiezyc_sila": 0.7,
		"tlo": Color(0.012, 0.008, 0.006), "nasycenie": 1.05, "kontrast": 1.12, "pochodnie": Color(1.0, 0.6, 0.3), "swiatla": 1.25, "mur_jasnosc": 1.2,
		"sciezka_jasn": 1.35, "sciezka_czysta": 0.7,
		"wierzch": "os_popiol", "wierzch_ton": Color(0.17, 0.15, 0.14),  # zgliszcza z góry: szary popiół, wyraźnie ciemniejszy od podłogi
		# podłoga chat i mury chat (zwęglone bale z żarem w szczelinach) — do strojenia
		"chata": "os_deski", "chata_skala": 0.5, "mur_chaty": "os_bale", "mur_chaty_skala": 0.5, "mur_chaty_zar": 0.9,
	},
	"crypt": {
		"a": "kry_plyty", "a_skala": 0.36, "b": "kry_popiol", "b_skala": 0.2, "c": "kry_lawa", "c_skala": 0.3,
		"b_ilosc": 0.4, "c_ilosc": 0.12, "c_przy_murach": 0.3, "sciezka_b": 0.7, "kaluze": 0.0, "zar": 3.0,
		"ton": Color(0.95, 0.9, 0.88), "jasnosc": 1.25,
		"mur": "kry_mur", "mur_skala": 0.35, "akcent": "kry_lawa", "wys_akcentu": 0.32, "sila_akcentu": 0.9, "mur_ton": Color(1.0, 0.92, 0.88), "mur_zar": 1.4,
		"otoczenie": Color(0.5, 0.3, 0.26), "otoczenie_sila": 0.5, "mgla": Color(0.3, 0.16, 0.12, 0.3), "ksiezyc": Color(0.9, 0.5, 0.4), "ksiezyc_sila": 0.35,
		"tlo": Color(0.016, 0.006, 0.004), "nasycenie": 1.12, "kontrast": 1.14, "pochodnie": Color(1.0, 0.55, 0.25), "swiatla": 1.5, "mur_jasnosc": 2.2,
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
	_mgla_obraz = Image.create(N, N, false, Image.FORMAT_L8)
	_mgla_tex = ImageTexture.create_from_image(_mgla_obraz)
	_jasn_obraz = Image.create(N, N, false, Image.FORMAT_L8)
	_jasn_tex = ImageTexture.create_from_image(_jasn_obraz)
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
	t.set_shader_parameter("sciezka_jasn", float(w.get("sciezka_jasn", 1.0)))
	t.set_shader_parameter("sciezka_czysta", float(w.get("sciezka_czysta", 0.0)))
	_mgla_do(t)
	t.set_shader_parameter("jasnosc_mapy", _jasn_tex)
	t.set_shader_parameter("mgla_gladka", true)
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
	_mgla_do(m)
	m.set_shader_parameter("jasnosc_mapy", _jasn_tex)
	m.set_shader_parameter("mgla_gladka", true)
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
	if osada:
		var ch: ShaderMaterial = t.duplicate()
		ch.set_shader_parameter("a_alb", _tsw(w["chata"], "alb"))
		ch.set_shader_parameter("a_nrm", _tsw(w["chata"], "normal"))
		ch.set_shader_parameter("a_rh", _tsw(w["chata"], "rh"))
		ch.set_shader_parameter("a_skala", w["chata_skala"])
		ch.set_shader_parameter("b_ilosc", 0.2)
		ch.set_shader_parameter("c_ilosc", 0.12)
		ch.set_shader_parameter("zar", 0.4)
		ch.set_shader_parameter("sciezka_jasn", 1.0)
		_mat["chata"] = ch
		var mc: ShaderMaterial = m.duplicate()
		mc.set_shader_parameter("m_alb", _tsw(w["mur_chaty"], "alb"))
		mc.set_shader_parameter("m_nrm", _tsw(w["mur_chaty"], "normal"))
		mc.set_shader_parameter("m_rh", _tsw(w["mur_chaty"], "rh"))
		mc.set_shader_parameter("skala", w["mur_chaty_skala"])
		mc.set_shader_parameter("zar", w["mur_chaty_zar"])
		_mat["mur_chaty"] = mc
	if las:
		for war in [["woda", Color(0.035, 0.08, 0.085), 0.6], ["brod", Color(0.12, 0.18, 0.16), 0.35]]:
			var wm := ShaderMaterial.new()
			wm.shader = preload("res://zasoby/3d/shadery/woda.gdshader")
			wm.set_shader_parameter("szum", _szum)
			wm.set_shader_parameter("kolor_toni", war[1])
			wm.set_shader_parameter("kolor_polysku", Color(0.6, 0.85, 0.9))
			wm.set_shader_parameter("skala", 0.14)
			wm.set_shader_parameter("sila_fal", war[2])
			wm.set_shader_parameter("predkosc", 0.05)
			_mat[war[0]] = wm


# ---------------------------------------------------------------- ŚRODOWISKO
func _srodowisko() -> void:
	srodowisko = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = wyglad["tlo"]
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = wyglad["otoczenie"]
	e.ambient_light_energy = wyglad["otoczenie_sila"]
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC  # AgX odbarwiał postacie
	e.tonemap_exposure = 1.0
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_strength = 1.1
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 1.1
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.ssao_enabled = true
	e.ssao_radius = 1.4
	e.ssao_intensity = 1.6
	e.ssil_enabled = jakosc >= 3
	e.ssil_radius = 3.0
	e.ssr_enabled = wyglad["kaluze"] > 0.0 and jakosc >= 2
	e.ssr_max_steps = 48
	e.ssr_fade_in = 0.2
	e.ssr_fade_out = 2.0
	e.fog_enabled = true
	e.fog_light_color = Color(wyglad["mgla"].r, wyglad["mgla"].g, wyglad["mgla"].b) * 0.2
	e.fog_density = 0.004
	e.fog_height = 0.35
	e.fog_height_density = 0.9
	e.fog_sky_affect = 0.0  # tło (nieodkryte) zostaje czarne; głębię dają wierzch skały, korony i płaszczyzna poza mapą
	e.adjustment_enabled = true
	e.adjustment_contrast = wyglad["kontrast"]
	e.adjustment_saturation = wyglad["nasycenie"]
	if lekki:
		e.ssr_enabled = false
		e.ssao_enabled = false
		e.ssil_enabled = false
		e.glow_enabled = jakosc == 0 and not ("--test" in OS.get_cmdline_user_args())
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
	var kat := deg_to_rad(Iso.KAT_KAMERY)   # ten sam kąt co rzut 2D (nakładki, mysz)
	var kier := Vector3(cos(kat) / sqrt(2.0), sin(kat), cos(kat) / sqrt(2.0))
	kamera.position = cel + kier * 40.0
	kamera.look_at(cel, Vector3.UP)
	kamera.size = get_viewport().get_visible_rect().size.y / (PX_NA_M * zoom)


# ---------------------------------------------------------------- MAPA
func _mapa() -> void:
	var siatki := {
		"podloga": _plyta(), "sciezka": _plyta(), "ekstrakcja": _plyta(),
		"filar": _filar(), "gruz": _gruz(), "kamyki": _kamyk(), "naroznik": _naroznik(),
		"cokol": _box(Vector3(1.0, WYS_COKOLU, 1.0)),
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
			if osada:
				_pole_osady(x, y, i, t, listy, siatki)
				continue
			if las:
				_pole_lasu(x, y, i, t, listy, siatki)
				continue
			if t != K.MUR:
				listy[podl].append([i, Basis(), 0.0])
			match t:
				K.MUR:
					# lita skała bez żadnego odsłoniętego sąsiada: zamiast czarnej dziury płaski wierzch skały (głębia)
					if _wnetrze_skaly(x, y):
						_wierzch(i, WYS_MURU * 0.98, listy, siatki, "wierzch")
						continue
					# ruiny: nierówna wysokość murów (wyższe na obwodzie), moduł wg odsłoniętych boków
					var brzeg := x == 0 or y == 0 or x == N - 1 or y == N - 1
					var h := (1.25 if brzeg else 1.0) + float(_hash(x, y) % 9 - 4) * 0.045
					var maska := _maska_muru(x, y)
					var wariant := _hash(y * 3, x * 5) % 3
					var klucz := "mur_%d_%d" % [maska, wariant]
					if not listy.has(klucz):
						listy[klucz] = []
						siatki[klucz] = _mesh_muru(maska, wariant)
					listy[klucz].append([i, Basis().scaled(Vector3(1.0, h, 1.0)), WYS_MURU * 0.5 * h])
					listy["cokol"].append([i, Basis(), WYS_COKOLU * 0.5])  # pokazywany zamiast muru w przekroju przed bohaterem
					# filar w zewnętrznym narożniku: rytm architektury jak w ruinach Diablo II
					for nr in [[1, 2, Vector2(0.5, 0.5)], [2, 4, Vector2(-0.5, 0.5)], [4, 8, Vector2(-0.5, -0.5)], [8, 1, Vector2(0.5, -0.5)]]:
						if (maska & nr[0]) and (maska & nr[1]) and _hash(x * 13, y * 7) % 2 == 0:
							var c: Vector2 = nr[2] * 0.86
							listy["naroznik"].append([i, Basis().scaled(Vector3(1.0, h, 1.0)), (WYS_MURU + 0.3) * 0.5 * h, Vector3(c.x, 0, c.y)])
				K.FILAR:
					if _hash(x, y) % 3 == 0 or _srodek_kaplicy(x, y):
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
					var ile := 1 if _hash(x * 3 + d.x, y * 5 + d.y) % 3 == 0 else 0  # autor 26.11: mniej osypanych kamieni (było 0–3)
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
			if k in PODLOGI or k.begins_with("wierzch") or k.begins_with("korona"):
				# podłoga i płaskie wierzchy stoją zawsze; mrok i brzeg odsłaniania rysują shadery z gładkiej mapy
				# jasności (autor 26.11: bez kwadratów; mgła nad mapą leży równo, nie tylko nad odkrytymi polami)
				mm.set_instance_transform(n, Transform3D(wp[1], Vector3(p.x, wp[2], p.z)))
				mm.set_instance_color(n, Color(0.7, 1.0, 0.85, 1.0) if k == "ekstrakcja" else Color.WHITE)
			else:
				mm.set_instance_transform(n, Transform3D(Basis().scaled(Vector3.ZERO), p))  # nieznane: niewidoczne
				mm.set_instance_color(n, Color(0, 0, 0, 1))  # po odkryciu wyłania się z czerni (_krok_mgly)
			if not _indeks.has(i):
				_indeks[i] = []
			_indeks[i].append([k, n, p, wp[1], wp[2]])
			if k.begins_with("drz") or k.begins_with("korona") or k.begins_with("wierzch"):
				var tp := clampi(int(p.z), 0, N - 1) * N + clampi(int(p.x), 0, N - 1)
				if not _indeks_wys.has(tp):
					_indeks_wys[tp] = []
				_indeks_wys[tp].append([k, n, p, wp[1], wp[2], i])
		mmi.multimesh = mm
		if "@" in k:
			var kw: PackedStringArray = k.get_slice("@", 1).split("_")
			mmi.custom_aabb = AABB(Vector3(int(kw[0]) * KWADRAT - 4, -1.0, int(kw[1]) * KWADRAT - 4), Vector3(KWADRAT + 8, 10.0, KWADRAT + 8))
		var mk: String = {"sciezka": "podloga", "ekstrakcja": "podloga", "kamyki": "gruz", "naroznik": "filar", "dno": "podloga", "cokol": "mur", "cokol_ch": "mur_chaty"}.get(k, k)
		if k.begins_with("murch"):
			mk = "mur_chaty"
		elif k.begins_with("mur"):
			mk = "mur"
		elif k.begins_with("wierzch"):
			mk = "wierzch"
		elif k.begins_with("korona"):
			mk = "korona"
		mmi.material_override = _mat[mk]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (k.begins_with("mur") or k.begins_with("drz_") or k.begins_with("las_") or k in ["filar", "gruz", "naroznik"]) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if k.begins_with("runo_") or k.begins_with("drzg_") or k.begins_with("wierzch") or k.begins_with("korona"):
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_mm[k] = mmi


func _srodek_kaplicy(x: int, y: int) -> bool:
	for k in rajd.mapa.komnaty:
		if k["typ"] == "kaplica":
			var rr: Rect2i = k["r"]
			var w := Rect2i(rr.position.x + 2, rr.position.y + 2, rr.size.x - 4, rr.size.y - 4)
			if x == w.position.x + w.size.x / 2 and y == w.position.y + w.size.y / 2:
				return true
	return false


func _wnetrze_skaly(x: int, y: int) -> bool:
	var mapa = rajd.mapa
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if mapa.kafel(x + dx, y + dy) != K.MUR:
				return false
	return true


## Bity odsłoniętych boków muru: 1 = +x, 2 = +z (y mapy), 4 = -x, 8 = -z.
func _maska_muru(x: int, y: int) -> int:
	var mapa = rajd.mapa
	var m := 0
	for b in [[1, 1, 0], [2, 0, 1], [4, -1, 0], [8, 0, -1]]:
		var t: int = mapa.kafel(x + b[1], y + b[2])
		if t != K.MUR and x + b[1] >= 0 and y + b[2] >= 0 and x + b[1] < N and y + b[2] < N:
			m |= b[0]
	return m


## Moduł muru: bryła z nierówną, wyszczerbioną koroną, fazą na odsłoniętych krawędziach i cokołem
## u podstawy od strony podłogi. Środek w (0, 0, 0), wysokość WYS_MURU (jak dawny klocek).
func _mesh_muru(maska: int, wariant: int) -> Mesh:
	var H := WYS_MURU
	var G := 4
	var faza := 0.07
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0xFFFFFFFF)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001 + maska * 31 + wariant * 977
	# siatka korony
	var gora := []
	var ubytek := rng.randi_range(0, 3) if wariant == 2 else -1  # wyłamana ćwiartka korony
	for j in G + 1:
		var wiersz := []
		for i in G + 1:
			var u := float(i) / G - 0.5
			var v := float(j) / G - 0.5
			var px := u
			var pz := v
			# faza: zewnętrzny pierścień odsunięty do środka na odsłoniętych bokach
			if i == G and (maska & 1): px -= faza
			if j == G and (maska & 2): pz -= faza
			if i == 0 and (maska & 4): px += faza
			if j == 0 and (maska & 8): pz += faza
			var hy := H * 0.5 + rng.randf_range(-0.07, 0.05)
			if ubytek >= 0:
				var qx := 1 if u > 0.0 else 0
				var qz := 1 if v > 0.0 else 0
				if qx + qz * 2 == ubytek and absf(u) > 0.1 and absf(v) > 0.1:
					hy -= rng.randf_range(0.25, 0.4)
			wiersz.append(Vector3(px, hy, pz))
		gora.append(wiersz)
	for j in G:
		for i in G:
			var a: Vector3 = gora[j][i]
			var b: Vector3 = gora[j][i + 1]
			var c: Vector3 = gora[j + 1][i + 1]
			var d: Vector3 = gora[j + 1][i]
			_quad_n(st, a, b, c, d, Vector3.UP)
	# boki: od dołu do krawędzi korony (z fazą na odsłoniętych)
	var dol := -H * 0.5
	var boki := [[1, func(k): return gora[k][G], Vector3(0.5, 0, 0)], [2, func(k): return gora[G][k], Vector3(0, 0, 0.5)],
		[4, func(k): return gora[k][0], Vector3(-0.5, 0, 0)], [8, func(k): return gora[0][k], Vector3(0, 0, -0.5)]]
	for bok in boki:
		var bit: int = bok[0]
		var kraw: Callable = bok[1]
		var n: Vector3 = bok[2]
		var odsl := (maska & bit) != 0
		for k in G:
			var t0: Vector3 = kraw.call(k)
			var t1: Vector3 = kraw.call(k + 1)
			# punkty lica na granicy pola (x lub z = ±0.5)
			# lico zawsze na pełnej szerokości pola (bez szczelin w narożnikach)
			var w0 := float(k) / G - 0.5
			var w1 := float(k + 1) / G - 0.5
			var f0 := Vector3(n.x if n.x != 0 else w0, 0, n.z if n.z != 0 else w0)
			var f1 := Vector3(n.x if n.x != 0 else w1, 0, n.z if n.z != 0 else w1)
			var hf0 := t0.y - (faza if odsl else 0.0)
			var hf1 := t1.y - (faza if odsl else 0.0)
			var p0 := Vector3(f0.x, dol, f0.z)
			var p1 := Vector3(f1.x, dol, f1.z)
			var q0 := Vector3(f0.x, hf0, f0.z)
			var q1 := Vector3(f1.x, hf1, f1.z)
			_quad_n(st, p0, p1, q1, q0, n)
			if odsl:
				_quad_n(st, q0, q1, t1, t0, n)  # pas fazy
	# cokół na odsłoniętych bokach
	for bok in boki:
		if (maska & int(bok[0])) == 0:
			continue
		var n: Vector3 = bok[2] * 2.0  # jednostkowa normalna boku
		var polowa := Vector3(0.035 if n.x != 0 else 0.5, 0.12, 0.035 if n.z != 0 else 0.5)
		var srodek := n * 0.535
		_skrzynka(st, Vector3(srodek.x, dol + 0.12, srodek.z), polowa)
	st.generate_normals()
	return st.commit()


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)


func _quad_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	# kolejność wierzchołków tak, by normalna trójkąta patrzyła w n (Godot: przednia ściana zgodnie z ruchem wskazówek)
	var nn := (b - a).cross(c - a)
	if nn.dot(n) > 0.0:
		_quad(st, a, d, c, b)
	else:
		_quad(st, a, b, c, d)


func _skrzynka(st: SurfaceTool, c: Vector3, r: Vector3) -> void:
	var dx := Vector3(r.x, 0, 0)
	var dy := Vector3(0, r.y, 0)
	var dz := Vector3(0, 0, r.z)
	for sc in [[dx, dy, dz], [-dx, dy, -dz], [dz, dy, -dx], [-dz, dy, dx], [dy, dz, dx], [-dy, dz, -dx]]:
		var n: Vector3 = sc[0]
		var u: Vector3 = sc[1]
		var v: Vector3 = sc[2]
		var o: Vector3 = c + n
		_quad_n(st, o - u - v, o - u + v, o + u + v, o + u - v, n.normalized())


## Filar narożny: kwadratowy trzon z głowicą i cokołem.
func _naroznik() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var H := WYS_MURU + 0.3
	_skrzynka(st, Vector3(0, 0, 0), Vector3(0.2, H * 0.5, 0.2))
	_skrzynka(st, Vector3(0, H * 0.5 - 0.06, 0), Vector3(0.25, 0.07, 0.25))
	_skrzynka(st, Vector3(0, -H * 0.5 + 0.1, 0), Vector3(0.25, 0.1, 0.25))
	st.generate_normals()
	return st.commit()


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
	var n: Node3D = _scena("res://zasoby/3d/%s.glb" % nazwa if nazwa.begins_with("las/") else "res://zasoby/3d/rekwizyty/%s.glb" % nazwa).instantiate()
	add_child(n)
	if nazwa.begins_with("las/"):
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = _mat_las(nazwa.substr(4))
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
			if sciana == Vector2.ZERO or _hash(x, y) % 17 != 0:  # autor 26.11: mniej rekwizytów (było co 9.)
				continue
			var wybor: Array = [["kandelabr", 1.25], ["lancuchy", 1.5], ["nagrobek", 0.95], ["beczka", 0.95], ["kosci", 0.35], ["kandelabr", 1.25]][_hash(y, x) % 6]
			var n := _postaw(mapa.idx(x, y), wybor[0], wybor[1], atan2(-sciana.x, -sciana.y))
			n.position += Vector3(sciana.x, 0, sciana.y) * 0.28
			if wybor[0] == "kandelabr":
				var l := _swiatlo(Color(1.0, 0.75, 0.45), 1.3, 3.2, false)
				l.position.y = 1.4 / n.scale.y
				l.set_meta("migotanie", true)
				n.add_child(l)


## Wystrój wg rodzaju komnaty (tylko wygląd): krypty z nagrobkami, legowiska z kośćmi i krwią,
## skarbce z kuframi i złotym światłem, sale filarów z kandelabrami, dziedzińce z gruzem i kolumnami.
func _wystroj_komnat() -> void:
	var mapa = rajd.mapa
	var zajete := {}
	for sk in mapa.skrzynie:
		zajete[mapa.idx(sk["tx"], sk["ty"])] = true
	for k in mapa.komnaty:
		var typ: String = k["typ"]
		var rr: Rect2i = k["r"]
		for y in range(rr.position.y + 1, rr.end.y - 1):
			for x in range(rr.position.x + 1, rr.end.x - 1):
				var i: int = mapa.idx(x, y)
				if mapa.kafel(x, y) != K.PODLOGA or zajete.has(i):
					continue
				var sciana := Vector2.ZERO
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if mapa.kafel(x + d.x, y + d.y) == K.MUR:
						sciana = Vector2(d)
				var h := _hash(x * 17 + 3, y * 23 + 5)
				var obr := atan2(-sciana.x, -sciana.y) if sciana != Vector2.ZERO else float(h % 628) / 100.0
				var n: Node3D = null
				match typ:
					"krypta":
						if sciana != Vector2.ZERO and h % 5 == 0:
							n = _postaw(i, "nagrobek" if h % 2 == 0 else "sarkofag", 0.95 if h % 2 == 0 else 0.8, obr)
					"legowisko":
						if h % 10 == 0:
							n = _postaw(i, "kosci", 0.35, obr)
						elif sciana != Vector2.ZERO and h % 13 == 0:
							n = _postaw(i, "lancuchy", 1.5, obr)
					"skarbiec":
						if sciana != Vector2.ZERO and h % 4 == 0:
							n = _postaw(i, "kufer" if h % 2 == 0 else "beczka", 0.7 if h % 2 == 0 else 0.95, obr)
					"sala_filarow":
						if sciana != Vector2.ZERO and h % 9 == 0:
							n = _postaw(i, "kandelabr", 1.25, obr)
							var l := _swiatlo(Color(1.0, 0.75, 0.45), 1.3, 3.2, false)
							l.position.y = 1.4 / n.scale.y
							l.set_meta("migotanie", true)
							n.add_child(l)
					"dziedziniec":
						if h % 23 == 0:
							n = _postaw(i, "glaz" if h % 2 == 0 else "kolumna_lezaca", 0.6, obr)
				if n != null and sciana != Vector2.ZERO:
					n.position += Vector3(sciana.x, 0, sciana.y) * 0.28
		# złote światło skarbca i krwawe plamy legowiska
		var c: Vector2 = k["srodek"]
		var ic: int = mapa.idx(int(c.x), int(c.y))
		if typ == "skarbiec":
			var zl := Node3D.new()
			zl.position = Vector3(c.x, 0.0, c.y)
			var l2 := _swiatlo(Color(1.0, 0.8, 0.35), 1.8, 5.0, false)
			l2.position.y = 1.6
			zl.add_child(l2)
			zl.visible = false
			add_child(zl)
			_dekor.append([zl, ic])
		elif typ == "legowisko" and not lekki:
			for j in 3:
				var hh := _hash(int(c.x) * 7 + j, int(c.y) * 11 + j)
				var dc := Decal.new()
				dc.texture_albedo = _tex_ef("krew_kaluza_%d" % (hh % 4))
				var rozm := 1.2 + float(hh % 50) / 40.0
				dc.size = Vector3(rozm, 0.6, rozm)
				dc.position = Vector3(c.x + float(hh % 5 - 2) * 0.9, 0.0, c.y + float((hh / 5) % 5 - 2) * 0.9)
				dc.rotation.y = float(hh % 628) / 100.0
				dc.visible = false
				add_child(dc)
				_dekor.append([dc, mapa.idx(int(dc.position.x), int(dc.position.z))])


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
var _ciete_ost := PackedInt32Array()
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
	var zar: bool = id == "crypt" or osada
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
	var kol := Color(1.0, 0.45, 0.12) if zar else (Color(0.75, 0.8, 0.9) if id == "catacombs" else (Color(0.78, 0.86, 0.62) if las else Color(0.8, 0.78, 0.74)))
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
			d.texture_albedo = _tex_ef("krew_kaluza_%d" % (hh % 4)) if rodzaj == "krew" else tex_sadza
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


# ---------------------------------------------------------------- LAS (Czarnobór)
## Modele lasu: drzewa ze ściany lasu i z polan (wysokość w m), głaz, runo 2D (wysokość w m).
const DRZEWA_LASU := [["p4_spruce", 4.6, 40], ["p4_tall_pine", 5.0, 28], ["p4_birch", 4.0, 12], ["p4_dead_oak", 3.6, 6],
	["p4_dead_spruce", 4.2, 8], ["p1_dead_tree", 3.4, 4], ["p4_hanging_tree", 3.6, 2]]
const RUNO_BRZEGU := [["p4_ferns", 1.1], ["p0_np_fern", 1.0], ["p4_wd0", 1.0], ["p4_wd1", 1.0], ["p4_wd11", 1.1], ["p4_brambles", 0.9], ["p0_np_tall", 1.2], ["p4_wd4", 0.8]]
const RUNO_POLANY := [["p0_np_grass", 0.5], ["p4_sp0", 0.6], ["p4_sp1", 0.55], ["p4_sp5", 0.5], ["p4_sp6", 0.5], ["p4_sp8", 0.7], ["p4_sp11", 0.6], ["p4_wd2", 0.7], ["p4_wd3", 0.7], ["p4_mushrooms", 0.4]]


## Odległość (w polach, najwyżej 6) od najbliższego pola, po którym się chodzi albo które widać (woda).
func _licz_odl_przejscia() -> void:
	var mapa = rajd.mapa
	_odl_przejscia.resize(N * N)
	_odl_przejscia.fill(255)
	_kotwica.resize(N * N)
	_kotwica.fill(-1)
	var kol: Array[int] = []
	for i in N * N:
		var t: int = mapa.siatka[i]
		if t != K.MUR:
			_odl_przejscia[i] = 0
			_kotwica[i] = i
			kol.append(i)
	var g := 0
	while g < kol.size():
		var i: int = kol[g]
		g += 1
		var d: int = _odl_przejscia[i]
		if d >= 6:
			continue
		var x := i % N
		var y := i / N
		for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var qx: int = x + s.x
			var qy: int = y + s.y
			if qx < 0 or qy < 0 or qx >= N or qy >= N:
				continue
			var j := qy * N + qx
			if _odl_przejscia[j] > d + 1:
				_odl_przejscia[j] = d + 1
				_kotwica[j] = _kotwica[i]
				kol.append(j)


func _mat_las(nazwa: String) -> StandardMaterial3D:
	var k := "lasmat_" + nazwa
	if not _mat.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://zasoby/3d/las/%s.webp" % nazwa)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.45
		if jakosc >= 2 and not lekki:
			# gładkie brzegi liści i gałęzi przy MSAA (Wysoka, Ultra) zamiast poszarpanych pikseli
			m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
			m.alpha_antialiasing_edge = 0.3
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.92
		m.vertex_color_use_as_albedo = true
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_mat[k] = m
	return _mat[k]


var _siatki_las := {}
## [Mesh, AABB, Transform] modelu lasu (jedna siatka na model — sprawdzone dla wszystkich modeli w zasoby/3d/las).
## lod > 0: siatka z uproszczenia, które Godot wygenerował przy imporcie (drzewo ma ok. 12,8 tys. trójkątów;
## LOD 1 ok. 3,2 tys., LOD 2 ok. 1,3 tys.) — tysiące drzew w MultiMesh bez tego dławią kartę.
func _siatka_las(nazwa: String, lod := 0) -> Array:
	var klucz := "%s_%d" % [nazwa, lod]
	if not _siatki_las.has(klucz):
		var n: Node = _scena("res://zasoby/3d/las/%s.glb" % nazwa).instantiate()
		var mi := n.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var ab: AABB = mi.transform * mi.get_aabb()
		var mesh: Mesh = mi.mesh
		if lod > 0:
			var sd: Dictionary = RenderingServer.mesh_get_surface(mi.mesh.get_rid(), 0)
			var lods: Array = sd.get("lods", [])
			if lods.size() >= lod:
				var dane: PackedByteArray = lods[lod - 1]["index_data"]
				var dlugie: bool = int(sd["vertex_count"]) > 65535
				var ind := PackedInt32Array()
				ind.resize(dane.size() / (4 if dlugie else 2))
				for j in ind.size():
					ind[j] = dane.decode_u32(j * 4) if dlugie else dane.decode_u16(j * 2)
				var tab: Array = mi.mesh.surface_get_arrays(0)
				# zostają tylko wierzchołki używane przez uproszczenie (mniej pracy dla karty)
				var nowy := PackedInt32Array()
				nowy.resize(int(sd["vertex_count"]))
				nowy.fill(-1)
				var stare: Array[int] = []
				for j in ind.size():
					var v: int = ind[j]
					if nowy[v] < 0:
						nowy[v] = stare.size()
						stare.append(v)
					ind[j] = nowy[v]
				for a in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
					if tab[a] == null:
						continue
					var src = tab[a]
					var dst = src.duplicate()
					dst.resize(stare.size())
					for j in stare.size():
						dst[j] = src[stare[j]]
					tab[a] = dst
				if tab[Mesh.ARRAY_TANGENT] != null:
					var ts: PackedFloat32Array = tab[Mesh.ARRAY_TANGENT]
					var td := PackedFloat32Array()
					td.resize(stare.size() * 4)
					for j in stare.size():
						for c in 4:
							td[j * 4 + c] = ts[stare[j] * 4 + c]
					tab[Mesh.ARRAY_TANGENT] = td
				tab[Mesh.ARRAY_INDEX] = ind
				var am := ArrayMesh.new()
				am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tab)
				mesh = am
		_siatki_las[klucz] = [mesh, ab, mi.transform]
		n.free()
	return _siatki_las[klucz]


## Jeden model lasu w MultiMesh (drzewo, głaz): skala do wysokości, losowy obrót i przesunięcie z ziarna pola.
func _model_las(klucz: String, nazwa: String, wys: float, i: int, h: int, listy: Dictionary, siatki: Dictionary, rozrzut := 0.35, lod := 1) -> void:
	var dane := _siatka_las(nazwa, lod)
	var ab: AABB = dane[1]
	klucz += _kwadrat(_kotw(i))
	if not listy.has(klucz):
		listy[klucz] = []
		siatki[klucz] = dane[0]
		_mat[klucz] = _mat_las(nazwa)
	var s := wys / maxf(ab.size.y, 0.01) * (0.85 + float(h % 31) / 100.0)
	var b := Basis(Vector3.UP, float(h % 628) / 100.0).scaled(Vector3.ONE * s) * (dane[2] as Transform3D).basis
	var off := Vector3(float(h % 7 - 3) / 3.0 * rozrzut, 0.0, float((h / 7) % 7 - 3) / 3.0 * rozrzut)
	var k := _kotw(i)
	listy[klucz].append([k, b, -ab.position.y * s, off + _przes(i, k)])


## Runo 2D: pionowy obrazek zwrócony do kamery izometrycznej (kamera patrzy z +x+z), podstawa na ziemi.
func _runo(nazwa: String, wys: float, i: int, h: int, listy: Dictionary, siatki: Dictionary) -> void:
	var klucz := "runo_" + nazwa + _kwadrat(_kotw(i))
	if not _mat.has("runomat_" + nazwa):
		var tex: Texture2D = load("res://zasoby/3d/las/runo/%s.webp" % nazwa)
		var q := QuadMesh.new()
		var asp := float(tex.get_width()) / maxf(1.0, tex.get_height())
		q.size = Vector2(asp, 1.0)
		q.center_offset = Vector3(0, 0.5, 0)
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 1.0
		m.vertex_color_use_as_albedo = true
		q.material = m
		_mat["runomat_" + nazwa] = m
		_siatki_las["runo_" + nazwa] = q
	if not listy.has(klucz):
		listy[klucz] = []
		siatki[klucz] = _siatki_las["runo_" + nazwa]
		_mat[klucz] = _mat["runomat_" + nazwa]
	var s := wys * (0.8 + float(h % 41) / 100.0)
	var b := Basis(Vector3.UP, PI * 0.25).scaled(Vector3.ONE * s)
	var off := Vector3(float(h % 9 - 4) * 0.1, 0.0, float((h / 9) % 9 - 4) * 0.1)
	var k := _kotw(i)
	listy[klucz].append([k, b, 0.0, off + _przes(i, k)])


const KWADRAT := 16
## Las dzielony na kwadraty 16×16 m: każdy rodzaj drzewa i runa ma osobny MultiMesh na kwadrat, więc karta
## pomija kwadraty poza kadrem (jedna paczka na całą mapę rysowała wszystkie drzewa w każdej klatce).
func _kwadrat(i: int) -> String:
	return "@%d_%d" % [(i % N) / KWADRAT, (i / N) / KWADRAT]


## Pole, od którego zależy widoczność rzeczy stojącej w polu i (w lesie: najbliższe przejście).
func _kotw(i: int) -> int:
	return _kotwica[i] if _kotwica.size() == N * N and _kotwica[i] >= 0 else i


func _przes(i: int, k: int) -> Vector3:
	return Vector3(i % N - k % N, 0.0, i / N - k / N)


## Pole mapy w lesie: podłoże, woda i bród, drzewa ze ściany lasu, skały (moduły murów), runo.
func _pole_lasu(x: int, y: int, i: int, t: int, listy: Dictionary, siatki: Dictionary) -> void:
	var tt: int = _teren[i]
	var d: int = _odl_przejscia[i]
	var h := _hash(x * 7 + 11, y * 13 + 5)
	for k in ["woda", "brod", "dno"]:
		if not listy.has(k):
			listy[k] = []
			siatki[k] = _plyta()
	if t == K.WODA:
		listy["dno"].append([i, Basis(), -0.5])
		listy["woda"].append([i, Basis(), -0.1])
		return
	if tt == T.BROD:
		listy["brod"].append([i, Basis(), -0.06])
		listy["sciezka"].append([i, Basis(), -0.2])
		return
	if t != K.MUR or d <= 5:
		var podl := "sciezka" if t == K.SCIEZKA else ("ekstrakcja" if t == K.EKSTRAKCJA else "podloga")
		var kp := _kotw(i)
		listy[podl].append([kp, Basis(), 0.0, _przes(i, kp)])
	match t:
		K.MUR:
			if tt == T.SKALA:
				if _wnetrze_skaly(x, y):
					_wierzch(i, WYS_MURU * 1.12, listy, siatki, "wierzch")
					return
				var brzeg := x == 0 or y == 0 or x == N - 1 or y == N - 1
				var hh := (1.35 if brzeg else 1.15) + float(_hash(x, y) % 9 - 4) * 0.06
				var maska := _maska_muru(x, y)
				var wariant := _hash(y * 3, x * 5) % 3
				var klucz := "mur_%d_%d" % [maska, wariant]
				if not listy.has(klucz):
					listy[klucz] = []
					siatki[klucz] = _mesh_muru(maska, wariant)
				listy[klucz].append([i, Basis().scaled(Vector3(1.0, hh, 1.0)), WYS_MURU * 0.5 * hh])
				if not listy.has("cokol"):
					listy["cokol"] = []
					siatki["cokol"] = _box(Vector3(1.0, WYS_COKOLU, 1.0))
				listy["cokol"].append([i, Basis(), WYS_COKOLU * 0.5])
				return
			# ściana lasu: gęsto przy przejściu, rzadziej w głębi; runo na samym skraju
			var co := 1 if d <= 1 else (2 if d == 2 else (3 if d <= 4 else 0))
			if d >= 4:
				_wierzch(i, 3.1, listy, siatki, "korona")  # głęboki las: zwarte korony zamiast czarnej pustki
			if co > 0 and h % co == 0:
				var dr: Array = _wybierz_drzewo(h)
				# autor 26.11: drzewa w wyższej jakości — przy ścieżce pełna siatka (Wysoka i Ultra), dalej uproszczenia
				if d <= 1:
					_model_las("drz_" + dr[0], dr[0], dr[1], i, h, listy, siatki, 0.35, _lod_blisko())
				elif d == 2:
					_model_las("drzs_" + dr[0], dr[0], dr[1], i, h, listy, siatki, 0.35, 1)  # bez cieni
				else:
					_model_las("drzg_" + dr[0], dr[0], dr[1], i, h, listy, siatki, 0.35, _lod_daleko())  # głębiej: prostsze, bez cieni
			if d == 1:
				var r1: Array = RUNO_BRZEGU[h % RUNO_BRZEGU.size()]
				_runo(r1[0], r1[1], i, h, listy, siatki)
				if h % 3 == 0:
					var r2: Array = RUNO_BRZEGU[(h / 3) % RUNO_BRZEGU.size()]
					_runo(r2[0], r2[1], i, h / 5, listy, siatki)
		K.FILAR:
			var dr2: Array = _wybierz_drzewo(h)
			_model_las("drz_" + dr2[0], dr2[0], dr2[1] * 0.75, i, h, listy, siatki, 0.1, _lod_blisko())
		K.GRUZ:
			_model_las("las_glaz", "p4_mossy_boulder", 0.9, i, h, listy, siatki, 0.1)
		K.PODLOGA:
			var przy_wodzie := false
			for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if rajd.mapa.kafel(x + s.x, y + s.y) == K.WODA:
					przy_wodzie = true
			if przy_wodzie and h % 3 == 0:
				_runo("p4_reeds", 1.2, i, h, listy, siatki)
			elif h % 100 < 5:  # autor 26.11: mniej runa na polanach (było 9%)
				var r3: Array = RUNO_POLANY[(h / 100) % RUNO_POLANY.size()]
				_runo(r3[0], r3[1], i, h, listy, siatki)


## Poziom szczegółów drzew wg ustawienia jakości: 0 = pełna siatka (ok. 12,8 tys. trójkątów), 1 i 2 = uproszczenia.
func _lod_blisko() -> int:
	return 0 if jakosc >= 2 and not lekki else 1


func _lod_daleko() -> int:
	return 1 if jakosc >= 3 and not lekki else 2


func _wybierz_drzewo(h: int) -> Array:
	var suma := 0
	for dr in DRZEWA_LASU:
		suma += int(dr[2])
	var q := (h / 13) % suma
	for dr in DRZEWA_LASU:
		q -= int(dr[2])
		if q < 0:
			return dr
	return DRZEWA_LASU[0]


## Wystrój polan wg rodzaju (tylko wygląd, nie blokuje ruchu; duże rzeczy na skraju polany).
func _wystroj_lasu() -> void:
	var mapa = rajd.mapa
	var zajete := {}
	for sk in mapa.skrzynie:
		zajete[mapa.idx(sk["tx"], sk["ty"])] = true
	for k in mapa.kosze:
		zajete[mapa.idx(int(k.x), int(k.y))] = true
	for p in mapa.polany:
		var c: Vector2 = p["c"]
		var rad: float = p["r"]
		var skraj: Array = []
		var srodek: Array = []
		for y in range(int(c.y - rad) - 1, int(c.y + rad) + 2):
			for x in range(int(c.x - rad) - 1, int(c.x + rad) + 2):
				if mapa.kafel(x, y) != K.PODLOGA or zajete.has(mapa.idx(x, y)):
					continue
				if Vector2(x + 0.5, y + 0.5).distance_to(c) > rad + 1.0:
					continue
				var sciana := Vector2.ZERO
				for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if mapa.kafel(x + s.x, y + s.y) == K.MUR:
						sciana = Vector2(s)
				if sciana != Vector2.ZERO:
					skraj.append([x, y, sciana])
				elif Vector2(x + 0.5, y + 0.5).distance_to(c) > 2.5:
					srodek.append([x, y])
		var h0 := _hash(int(c.x) * 31, int(c.y) * 17)
		var plan: Array = []  # [nazwa, wysokość, na skraju?, po długości?]
		match String(p["typ"]):
			"oboz":
				plan = [["p4_cz_tent", 2.4, true], ["p4_cz_pelts", 1.5, true], ["p4_cz_firewood", 0.8, true], ["p8_pal_czaszki", 1.8, true]]
			"kapliczka":
				plan = [["p8_kapliczka_lesna", 2.1, true], ["p8_grzyby_blade", 0.45, false]]
			"kurhan":
				plan = [["p4_burial_mound", 2.6, true, true], ["p8_kamien_runiczny", 1.6, true], ["p8_czaszki", 0.5, false]]
			"legowisko":
				plan = [["p4_cz_bones", 1.6, false, true], ["p8_skora_kosci", 1.4, false, true], ["p8_czaszki", 0.5, false], ["p8_pal_czaszki", 1.8, true], ["p4_wolf_skull_bush", 1.0, true]]
			"ekstrakcja":
				plan = [["p8_menhir_runy", 2.4, true], ["p8_menhir_runy", 2.2, true]]
			"start":
				plan = [["p4_axe_stump", 0.6, true], ["p4_cz_firewood", 0.8, true]]
			_:
				var pula := [["p8_kloda", 2.0, true, true], ["p8_korzenie", 0.9, true], ["p8_grzyby_zolte", 0.45, false], ["p8_muchomory", 0.5, false],
					["p4_axe_stump", 0.6, true], ["p8_huby_na_klodzie", 1.6, true, true], ["p8_grzyby_niebieskie", 0.45, false]]
				for n in 1 + h0 % 2:  # autor 26.11: mniej przedmiotów na polanach (było 2–4)
					plan.append(pula[(h0 / (n + 1) + n * 3) % pula.size()])
		for n in plan.size():
			var e: Array = plan[n]
			var lista: Array = skraj if (e[2] or srodek.is_empty()) else srodek
			if lista.is_empty():
				continue
			var w: Array = lista[(h0 / (n + 2) + n * 7) % lista.size()]
			lista.erase(w)
			var i: int = mapa.idx(w[0], w[1])
			var obr := float(_hash(w[0] * 3, w[1] * 5) % 628) / 100.0
			if w.size() > 2 and w[2] != Vector2.ZERO:
				obr = atan2(-(w[2] as Vector2).x, -(w[2] as Vector2).y)
			var nd := _rekwizyt("las/" + e[0], e[1], e.size() > 3 and e[3])
			nd.position = Vector3(w[0] + 0.5, float(nd.get_meta("y0")), w[1] + 0.5)
			if w.size() > 2:
				nd.position += Vector3((w[2] as Vector2).x, 0, (w[2] as Vector2).y) * 0.3
			nd.rotation.y = obr
			nd.visible = false
			_dekor.append([nd, i])
			if e[0] == "p8_kapliczka_lesna":
				var l := _swiatlo(Color(1.0, 0.78, 0.45), 1.6, 4.5, false)
				l.position.y = 1.2 / nd.scale.y
				l.set_meta("migotanie", true)
				nd.add_child(l)


# ---------------------------------------------------------------- SPALONA OSADA
## Martwe drzewa osady (sad, zgliszcza): [model, wysokość]. Wszystkie z biblioteki NightBrand.
const DRZEWA_OSADY := [["p1_dead_tree", 3.4], ["p4_dead_oak", 3.6], ["p4_dead_spruce", 4.2], ["p1_dead_tree", 3.0]]
## Osłony na placach i podwórzach (K.GRUZ, T.WOZ): [model, wymiar, po długości?].
const OSLONY_OSADY := [["p1_barrel", 0.95, false], ["p8_beczki_lina", 1.1, false], ["p1_burnt_hay", 1.5, true], ["p8_stos", 1.2, false],
	["p8_worki_zboze", 0.9, false], ["p1_wheel", 1.1, false]]


## Pole mapy w osadzie: podłoże (ziemia, ulica, deski chat), palisady i zgliszcza zamiast ścian lochu,
## mury chat ze zwęglonych bali, płoty, groby, martwe drzewa, wozy i beczki.
func _pole_osady(x: int, y: int, i: int, t: int, listy: Dictionary, siatki: Dictionary) -> void:
	var tt: int = _teren[i]
	var d: int = _odl_przejscia[i]
	var h := _hash(x * 7 + 11, y * 13 + 5)
	if not listy.has("chata"):
		listy["chata"] = []
		siatki["chata"] = _plyta()
		listy["cokol_ch"] = []
		siatki["cokol_ch"] = _box(Vector3(1.0, WYS_COKOLU, 1.0))
	if t != K.MUR:
		var podl := "sciezka" if t == K.SCIEZKA else ("ekstrakcja" if t == K.EKSTRAKCJA else ("chata" if tt == TO.CHATA else "podloga"))
		var kp := _kotw(i)
		listy[podl].append([kp, Basis(), 0.0, _przes(i, kp)])
	match t:
		K.MUR:
			if tt == TO.ZGLISZCZA:
				# mur spalonej chaty: niższy, nierówny (bale się obsypały), żar w szczelinach
				var hc := 0.72 + float(_hash(x * 5, y * 3) % 9) * 0.035
				var maska_c := _maska_muru(x, y)
				var klucz_c := "murch_%d_%d" % [maska_c, _hash(y * 3, x * 5) % 3]
				if not listy.has(klucz_c):
					listy[klucz_c] = []
					siatki[klucz_c] = _mesh_muru(maska_c, _hash(y * 3, x * 5) % 3)
				listy[klucz_c].append([i, Basis().scaled(Vector3(1.0, hc, 1.0)), WYS_MURU * 0.5 * hc])
				listy["cokol_ch"].append([i, Basis(), WYS_COKOLU * 0.5])
				return
			# zabudowa: osmalona palisada na brzegu, w głębi zgliszcza (płaski wierzch z węgla) i sterczące martwe drzewa
			if _wnetrze_skaly(x, y):
				_wierzch(i, WYS_MURU * 0.98, listy, siatki, "wierzch")
				if d >= 2 and d <= 5 and h % 11 == 0:
					var dr: Array = DRZEWA_OSADY[(h / 11) % DRZEWA_OSADY.size()]
					_model_las("drzg_" + dr[0], dr[0], dr[1], i, h, listy, siatki, 0.35, _lod_daleko())
				return
			var brzeg := x == 0 or y == 0 or x == N - 1 or y == N - 1
			var hh := (1.2 if brzeg else 1.0) + float(_hash(x, y) % 9 - 4) * 0.05
			var maska := _maska_muru(x, y)
			var wariant := _hash(y * 3, x * 5) % 3
			var klucz := "mur_%d_%d" % [maska, wariant]
			if not listy.has(klucz):
				listy[klucz] = []
				siatki[klucz] = _mesh_muru(maska, wariant)
			listy[klucz].append([i, Basis().scaled(Vector3(1.0, hh, 1.0)), WYS_MURU * 0.5 * hh])
			if not listy.has("cokol"):
				listy["cokol"] = []
				siatki["cokol"] = _box(Vector3(1.0, WYS_COKOLU, 1.0))
			listy["cokol"].append([i, Basis(), WYS_COKOLU * 0.5])
		K.FILAR:
			if tt == TO.DRZEWO:
				var dr2: Array = DRZEWA_OSADY[h % DRZEWA_OSADY.size()]
				_model_las("drz_" + dr2[0], dr2[0], dr2[1] * 0.85, i, h, listy, siatki, 0.1, _lod_blisko())
			# studnia (2×2) stoi jako rekwizyt w _wystroj_osady
		K.GRUZ:
			if tt == TO.PLOT:
				# płot wzdłuż linii płotu (sąsiedni płot wyznacza kierunek)
				var wzdluz_x := _teren_os(x - 1, y) == TO.PLOT or _teren_os(x + 1, y) == TO.PLOT
				_model_os("las_os_plot", "p8_plot_zlamany", 1.15, i, 0.0 if wzdluz_x else PI * 0.5, listy, siatki, h)
			elif tt == TO.GROB:
				_model_os("las_os_grob" + str(h % 2), ["p1_tombstone", "p1_grave_cross"][h % 2], [0.9, 1.0][h % 2], i, PI * 0.25 + float(h % 3 - 1) * 0.2, listy, siatki, h)
			else:
				# w chacie: zwalona belka i gruz; na podwórzu: beczki, siano, koła, worki
				var w_chacie := false
				for s4 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if _teren_os(x + s4.x, y + s4.y) == TO.CHATA:
						w_chacie = true
				var o: Array = ["p8_stos", 1.0, false] if w_chacie else OSLONY_OSADY[h % OSLONY_OSADY.size()]
				_model_os("las_os_" + String(o[0]), o[0], o[1], i, float(h % 628) / 100.0, listy, siatki, h, o[2])


func _teren_os(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= N or y >= N:
		return TO.ZABUDOWA
	return _teren[y * N + x]


## Model osady w MultiMesh z podanym obrotem (płot wzdłuż linii, groby rzędem). Wymiar = wysokość albo długość.
func _model_os(klucz: String, nazwa: String, wymiar: float, i: int, obrot: float, listy: Dictionary, siatki: Dictionary, h: int, po_dlugosci := false) -> void:
	var dane := _siatka_las(nazwa, 1)
	var ab: AABB = dane[1]
	klucz += _kwadrat(_kotw(i))
	if not listy.has(klucz):
		listy[klucz] = []
		siatki[klucz] = dane[0]
		_mat[klucz] = _mat_las(nazwa)
	var miara := maxf(ab.size.x, ab.size.z) if po_dlugosci else ab.size.y
	var s := wymiar / maxf(miara, 0.01) * (0.92 + float(h % 17) / 100.0)
	var b := Basis(Vector3.UP, obrot).scaled(Vector3.ONE * s) * (dane[2] as Transform3D).basis
	var k := _kotw(i)
	listy[klucz].append([k, b, -ab.position.y * s, _przes(i, k)])


## Wystrój miejsc osady wg rodzaju (tylko wygląd, nie blokuje ruchu; duże rzeczy na skraju).
func _wystroj_osady() -> void:
	var mapa = rajd.mapa
	var zajete := {}
	for sk in mapa.skrzynie:
		zajete[mapa.idx(sk["tx"], sk["ty"])] = true
	for k in mapa.kosze:
		zajete[mapa.idx(int(k.x), int(k.y))] = true
	for p in mapa.polany:
		var c: Vector2 = p["c"]
		var rad: float = p["r"]
		var typ := String(p["typ"])
		if typ == "plac":
			# studnia na polach T.STUDNIA (2×2 od środka placu)
			var ci := Vector2i(int(c.x), int(c.y))
			var st := _rekwizyt("las/p1_well", 2.1)
			st.position = Vector3(ci.x + 1.0, float(st.get_meta("y0")), ci.y + 1.0)
			st.visible = false
			_dekor.append([st, mapa.idx(ci.x, ci.y)])
		var skraj: Array = []
		var srodek: Array = []
		for y in range(int(c.y - rad) - 1, int(c.y + rad) + 2):
			for x in range(int(c.x - rad) - 1, int(c.x + rad) + 2):
				if mapa.kafel(x, y) != K.PODLOGA or zajete.has(mapa.idx(x, y)) or _teren_os(x, y) != TO.PLAC:
					continue
				if Vector2(x + 0.5, y + 0.5).distance_to(c) > rad + 1.0:
					continue
				var sciana := Vector2.ZERO
				for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if mapa.kafel(x + s.x, y + s.y) == K.MUR:
						sciana = Vector2(s)
				if sciana != Vector2.ZERO:
					skraj.append([x, y, sciana])
				elif Vector2(x + 0.5, y + 0.5).distance_to(c) > 3.0:
					srodek.append([x, y])
		var h0 := _hash(int(c.x) * 31, int(c.y) * 17)
		var plan: Array = []  # [nazwa, wymiar, na skraju?, po długości?]
		match typ:
			"plac":
				plan = [["p1_stocks", 1.6, true], ["p1_order_banner", 2.4, true], ["p1_crow_post", 2.2, true]]
			"zagroda":
				var pula := [["p1_wheel", 1.1, true], ["p8_strach_na_wroble", 1.9, false], ["p1_dead_horse", 2.2, true, true], ["p1_barrel", 0.95, true], ["p1_burnt_hay", 1.6, true, true]]
				for n in 2:
					plan.append(pula[(h0 / (n + 1) + n * 2) % pula.size()])
			"kuznia":
				plan = [["p8_beczki_lina", 1.1, true], ["p1_wheel", 1.1, true], ["p1_barrel", 0.95, true]]
			"stodola":
				plan = [["p1_burnt_hay", 1.8, true, true], ["p1_burnt_hay", 1.5, true, true], ["p8_worki_zboze", 0.9, true]]
			"sad":
				plan = [["p8_strach_na_wroble", 1.9, false], ["p1_crow_post", 2.2, true]]
			"cmentarz":
				plan = [["p1_crow_post", 2.2, true], ["p1_grave_cross", 1.0, true]]
			"piwnica":
				plan = [["p8_beczki_lina", 1.1, true], ["p8_worki_zboze", 0.9, true], ["p1_barrel", 0.95, true]]
			"kosciol":
				plan = [["p1_gallows", 3.0, true], ["p3_gibbet", 2.6, true], ["p1_order_banner", 2.4, true], ["p1_crow_post", 2.2, true]]
			"ekstrakcja":
				plan = [["p8_menhir_runy", 2.4, true], ["p8_menhir_runy", 2.2, true]]
			"start":
				plan = [["p4_cz_wagon", 3.2, true, true], ["p1_barrel", 0.95, true]]
		for n in plan.size():
			var e: Array = plan[n]
			var lista: Array = skraj if (e[2] or srodek.is_empty()) else srodek
			if lista.is_empty():
				continue
			var w: Array = lista[(h0 / (n + 2) + n * 7) % lista.size()]
			lista.erase(w)
			var i: int = mapa.idx(w[0], w[1])
			var obr := float(_hash(w[0] * 3, w[1] * 5) % 628) / 100.0
			if w.size() > 2 and w[2] != Vector2.ZERO:
				obr = atan2(-(w[2] as Vector2).x, -(w[2] as Vector2).y)
			var nd := _rekwizyt("las/" + e[0], e[1], e.size() > 3 and e[3])
			nd.position = Vector3(w[0] + 0.5, float(nd.get_meta("y0")), w[1] + 0.5)
			if w.size() > 2:
				nd.position += Vector3((w[2] as Vector2).x, 0, (w[2] as Vector2).y) * 0.3
			nd.rotation.y = obr
			nd.visible = false
			_dekor.append([nd, i])


## Mgła wojny: 0 nieznane (ukryte), 1 widziane (przygaszone), 2 widoczne. Mury przy graczu od strony kamery przezroczyste.
func odswiez_widok() -> void:
	var widok: PackedByteArray = rajd.widok
	var g: Vector2 = rajd.gracz.w
	# tylko pola, które mogły się zmienić: zmiany mgły + okolica gracza (przekrój murów) + dawny przekrój
	var kandydaci: PackedInt32Array = rajd.zmienione_widoku + _ciete_ost
	var gx := int(g.x)
	var gy := int(g.y)
	for yy in range(maxi(0, gy - 10), mini(N, gy + 11)):
		for xx in range(maxi(0, gx - 10), mini(N, gx + 11)):
			kandydaci.append(yy * N + xx)
	var ciete_teraz := PackedInt32Array()
	for i in kandydaci:
		if not _indeks.has(i):
			continue
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
		if przezr:
			ciete_teraz.append(i)
		var klucz := v + (100 if przezr else 0)
		if _stan_widoku[i] == klucz:
			continue
		_stan_widoku[i] = klucz
		for wpis in _indeks[i]:
			var rodzaj: String = wpis[0]
			if rodzaj in PODLOGI:
				continue  # podłoga: zawsze stoi, jasność z mapy jasności (_krok_mgly)
			if rodzaj.begins_with("drz") or rodzaj.begins_with("korona") or rodzaj.begins_with("wierzch"):
				var pw: Vector3 = wpis[2]
				_do_sprawdzenia[clampi(int(pw.z), 0, N - 1) * N + clampi(int(pw.x), 0, N - 1)] = true
				continue  # drzewa i wierzch: widoczność i przekrój wg prawdziwej pozycji (_przekroj_wysokich)
			var mm: MultiMesh = _mm[rodzaj].multimesh
			var p: Vector3 = wpis[2]
			var b: Basis = wpis[3]
			var y: float = wpis[4]
			if v == 0:
				b = Basis().scaled(Vector3.ZERO)
			# mur między kamerą a graczem obniżony do cokołu (jak w grach izometrycznych AAA)
			elif rodzaj == "cokol" or rodzaj == "cokol_ch":
				if not przezr:
					b = Basis().scaled(Vector3.ZERO)
			elif przezr and (rodzaj.begins_with("mur") or rodzaj == "naroznik"):
				b = Basis().scaled(Vector3.ZERO)  # zamiast ściśniętych ruin (drobna „pikseloza”) równy cokół
			elif przezr and rodzaj == "filar":
				var h := 0.22
				var pelna := WYS_MURU if rodzaj.begins_with("mur") else (WYS_MURU + 0.3 if rodzaj == "naroznik" else WYS_MURU + 0.4)
				b = Basis(b.get_rotation_quaternion()).scaled(Vector3(1.0, h / pelna, 1.0))
				y = h * 0.5
			mm.set_instance_transform(wpis[1], Transform3D(b, Vector3(p.x, y, p.z)))
		# jasność nie skacze: cel dla płynnego przejścia (_krok_mgly co klatkę)
		var cel := 0.0 if v == 0 else (1.0 if v == 2 else 0.3)
		if not is_equal_approx(_cel_jasn[i], cel):
			_cel_jasn[i] = cel
			_fade[i] = true
	_ciete_ost = ciete_teraz
	_przekroj_wysokich(g)
	# mapa znanych pól dla miękkiego brzegu mgły (raz na przeliczenie widoku)
	var zmiana := false
	for i in rajd.zmienione_widoku:
		if widok[i] > 0 and _mgla_obraz.get_pixel(i % N, i / N).r < 0.5:
			_mgla_obraz.set_pixel(i % N, i / N, Color.WHITE)
			zmiana = true
	if zmiana:
		_mgla_tex.update(_mgla_obraz)
	for sk in _skrzynie:
		var v2: int = widok[rajd.mapa.idx(sk["tx"], sk["ty"])]
		sk["wezel3d"].visible = v2 > 0
	for d in _dekor:
		(d[0] as Node3D).visible = widok[d[1]] > 0
	for pm in _pochodnie_murow:
		(pm[0] as Node3D).visible = widok[pm[1]] > 0 and widok[pm[2]] > 0 and not _mury_ciete.get(pm[2], false)


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
	l.shadow_enabled = cien and not lekki and (jakosc >= 2 or energia >= 3.0)
	l.shadow_blur = 1.5
	l.light_specular = 0.6
	return l


func _rekwizyty() -> void:
	var mapa = rajd.mapa
	for k in mapa.kosze:
		var w: Vector2 = k
		var kosz := Node3D.new()
		kosz.position = Vector3(w.x, 0, w.y)
		var misa := _rekwizyt("las/p8_ognisko_gruz", 1.5, true) if osada else (_rekwizyt("las/p8_ognisko_krag", 1.6, true) if las else _rekwizyt("misa_zar", 1.05))
		remove_child(misa)
		misa.position.y = float(misa.get_meta("y0"))
		kosz.add_child(misa)
		var ogien := _ogien(1.4, 1.6)
		ogien.position.y = 0.25 if las else 1.05
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
	if osada:
		_wystroj_osady()
	elif las:
		_wystroj_lasu()
	else:
		_wystroj()
		_wystroj_komnat()
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
		# autor 26.11: malowane modele biblioteki NightBrand zamiast pikselowych brył (kufer, sarkofag, zbroja)
		"loot_sarcophagus":
			r = _rekwizyt("las/p3_sarcophagus", 1.75, true)
		"loot_knight":
			r = _rekwizyt("las/p1_grave_cross", 1.05)
		_:
			r = _rekwizyt("las/p8_kufer", 0.95, true)
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


## Wyostrzenie obrazu 3D (pod nakładkami 2D i HUD-em).
func _wyostrzenie() -> void:
	if lekki:
		return
	var w := CanvasLayer.new()
	w.layer = -100
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://zasoby/3d/shadery/wyostrz.gdshader")
	m.set_shader_parameter("sila", 0.55 if jakosc >= 2 else 0.4)
	r.material = m
	w.add_child(r)
	add_child(w)


func _bohater() -> void:
	bohater = _scena(GLB_BOHATERA).instantiate()
	add_child(bohater)
	_wyglad_rynsztunku.przygotuj(bohater)
	WygladPostaci.ozyw(bohater, 0.35, 0.4)
	WygladPostaci.swiatlo_postaci(bohater, 1.35)  # ciemna zbroja: mocniejsze światło postaci, żeby nie ginął w mroku
	_ap_bohatera = bohater.find_child("AnimationPlayer", true, false)
	_przygotuj_ap(_ap_bohatera)
	var szk: Skeleton3D = bohater.find_children("*", "Skeleton3D", true, false)[0] if not bohater.find_children("*", "Skeleton3D", true, false).is_empty() else null
	if szk:
		_korekta_chodu = preload("res://skrypty/korekta_chodu.gd").new()
		_korekta_chodu.influence = 0.0
		szk.add_child(_korekta_chodu)
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
	_poswiata = _swiatlo(Color(0.78, 0.74, 0.8), 2.2, 5.5, false)
	_poswiata.position.y = 1.6
	bohater.add_child(_poswiata)
	_cienie(bohater)
	_blysk_bohatera = StandardMaterial3D.new()
	_blysk_bohatera.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blysk_bohatera.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blysk_bohatera.albedo_color = Color(1, 1, 1, 0)
	var cialo_b: MeshInstance3D = bohater.find_child("cialo*", true, false)
	if cialo_b:
		cialo_b.material_overlay = _blysk_bohatera
	_krag_bohatera = _krag(Color(1.0, 0.75, 0.4), 0.42)  # autor 26.11: krąg mniejszy (było 0,6)
	(_krag_bohatera.material_override as ShaderMaterial).set_shader_parameter("sila", 0.7)
	add_child(_krag_bohatera)


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
	if styl == "luk":
		return ["strzal", "luk_strzal", false, 1.0, 0.0, 0.04] if p.luk_cd > 0.0 else ["celowanie", "luk_celowanie", true, 1.0, 0.0, 0.1]
	if p.martwy:
		return ["smierc", "smierc", false, 1.0, 0.0, 0.25]
	if p.unik_czas > 0.0:
		# przewrót: klip 1,03 s, gra się od 4% do 80% w czasie uniku (0,3 s)
		return ["przewrot", "przewrot", false, 0.76 * 1.03 / p.UNIK_DLUGOSC, 0.04, 0.05]
	if p.ladowanie >= rajd.PROG_MOCNEGO and p.zamach_anim <= 0.0:
		# ładowanie mocnego ciosu: zamach ciężkiego ciosu napina się powoli i zatrzymuje przed uderzeniem
		var pl3: Array = ATAK_PLAN[styl][2]
		var t3: float = clampf((p.ladowanie - rajd.PROG_MOCNEGO) / 0.6, 0.0, 1.0)
		return ["atak3", "ladowanie", false, 0.0, maxf(0.01, pl3[0] * (0.25 + 0.5 * t3)), 0.12]
	if p.zamach_anim > 0.0:
		var plan: Array = ATAK_PLAN[styl][clampi(p.combo, 0, 2)]
		var d: float = maxf(p.zamach_anim_max, 0.2)
		var przed: float = minf(ATAK_PRZED[clampi(p.combo, 0, 2)], d * 0.45)
		var ts := maxf(0.0, (plan[0] - przed * plan[1] / d) / (1.0 - przed / d))
		return ["atak%d" % (p.combo + 1), "atak%d_%d" % [p.combo, p.atak_licznik], false, (plan[1] - ts) / d, ts, 0.07]
	if p.blok:
		if p.okno_parowania > 0.0 and p.blok_czas < 0.35:
			return ["parowanie", "parowanie", false, clampf(_dl_klipu(styl + "_parowanie") / 0.55, 1.0, 1.6), 0.0, 0.1]
		return ["blok", "blok", true, 1.0, 0.0, 0.22]
	if p.w_ruchu and p.ruch_wektor != Vector2.ZERO:
		var v: float = p.ruch_wektor.length()
		var rel := angle_difference(_kat_wiz, atan2(p.ruch_wektor.y, p.ruch_wektor.x))
		var swobodny: bool = rajd.cel_namierzony == null and not p.blok and p.ladowanie <= 0.0 and p.zamach_anim <= 0.0 and not p.celuje_drazkiem
		if swobodny:
			rel = 0.0  # twarz podąża za ruchem: bez kroków w bok i w tył przy skręcie
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


var _korekta_chodu: SkeletonModifier3D
func _aktualizuj_bohatera(dt: float) -> void:
	var p = rajd.gracz
	var zestaw: String = p.zestaw
	var styl: String = ZESTAW_ANIM.get(zestaw, "dwureczny")
	var luk_w_rece: bool = WygladRynsztunku.celuje_z_luku(p)
	if luk_w_rece:
		styl = "luk"
	if not _kat_start:
		_kat_start = true
		_kat_wiz = p.kat
	var szybki: bool = p.zamach_anim > 0.0 or p.unik_czas > 0.0
	if szybki or p.blok or rajd.cel_namierzony != null or p.celuje_drazkiem:
		_kat_wiz = _obracaj(_kat_wiz, _kat_celu(p), 26.0 if szybki else 15.0, dt)
	else:
		var rk := angle_difference(_kat_wiz, _kat_celu(p))
		_kat_wiz += clampf(rk * (1.0 - exp(-dt * 12.0)), -11.0 * dt, 11.0 * dt)
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
		if pl[1] == "ladowanie":
			_ap_bohatera.seek(pl[4], true)
	p.biezaca_anim = pl[0] if pl[0] not in ["bieg", "tyl", "lewo", "prawo"] else "chod"
	if _korekta_chodu:
		# autor 26.11: bez „kowbojskiego” rozkroku w ruchu; postawa bojowa w miejscu bez zmian
		var w_ruchu: bool = pl[0] in ["chod", "bieg", "tyl", "lewo", "prawo"]
		_korekta_chodu.influence = move_toward(_korekta_chodu.influence, 1.0 if w_ruchu else 0.0, dt * 4.0)
	for n in _bronie.keys():
		var b: Node3D = _bronie[n]
		if n != "bron_pochodnia":
			b.visible = false
			continue
		match n:
			"bron_dwureczny": b.visible = zestaw == "dwureczny"
			"bron_glewia": b.visible = zestaw == "glewia"
			"bron_topor": b.visible = zestaw == "topor"
			"bron_miecz": b.visible = zestaw == "miecz" or zestaw == "miecz_tarcza"
			"bron_tarcza": b.visible = zestaw == "miecz_tarcza"
			"bron_pochodnia": b.visible = p.pochodnia_w_rece and not p.martwy
	var napiecie: float = clampf((p.luk_cd - 0.43) / 0.15, 0.0, 1.0) if p.luk_cd > 0.0 else 1.0
	_wyglad_rynsztunku.odswiez(p.rynsztunek, zestaw, luk_w_rece, p.luk_cd > 0.45 or p.luk_cd <= 0.0, napiecie)
	if luk_w_rece and _bronie.has("bron_pochodnia"):
		(_bronie["bron_pochodnia"] as Node3D).visible = false
	_swiatlo_pochodni.visible = p.pochodnia_w_rece and not p.martwy and not luk_w_rece
	_plomien_bohatera.emitting = _swiatlo_pochodni.visible
	# nietykalność po otrzymanym ciosie: postać miga (jak w NightBrand), po bloku i parowaniu bez migania
	bohater.visible = not (p.niet_miganie and p.niet > 0.0 and fmod(Time.get_ticks_msec() / 1000.0, 0.12) < 0.05)
	_poswiata.visible = not _swiatlo_pochodni.visible and not p.martwy


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
	WygladPostaci.ozyw(n)
	WygladPostaci.swiatlo_postaci(n, 1.0 if not en.boss else 1.3, 3.6 * s if en.boss else 3.6, 2.3 * s)
	var cialo: MeshInstance3D = n.find_child("cialo*", true, false)
	if cialo:
		cialo.material_overlay = blysk
	# obrys wroga w walce (NightBrand: wróg odróżnialny od tła; ostrzeżenie = podświetlenie, nie ikona):
	# odwrócona powłoka (grow + cull front) jako następny przebieg nakładki błysku
	var obrys := StandardMaterial3D.new()
	obrys.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	obrys.cull_mode = BaseMaterial3D.CULL_FRONT
	obrys.grow = true
	obrys.grow_amount = GRUBOSC_OBRYSU
	obrys.albedo_color = KOLOR_OBRYSU
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
	gw.pixel_size = 0.003
	gw.modulate = Color(1.0, 0.45, 0.3) if en.ciezki else Color(1.0, 0.93, 0.6)
	gw.top_level = true
	gw.visible = false
	n.add_child(gw)
	# pierścień rytmu: zwęża się do koła wewnętrznego w chwili ciosu; jasny = paruj teraz
	var pr := MeshInstance3D.new()
	var pp := PlaneMesh.new()
	pp.size = Vector2(2.0, 2.0) * s  # pierścień rytmu: mniejszy, nie przykrywa postaci
	pr.mesh = pp
	var prm := ShaderMaterial.new()
	prm.shader = _shader_pierscienia()
	prm.set_shader_parameter("kolor", Color(1.0, 0.25, 0.12) if en.ciezki else Color(1.0, 0.82, 0.3))
	prm.set_shader_parameter("ciezki", 1.0 if en.ciezki else 0.0)
	pr.material_override = prm
	pr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pr.top_level = true
	pr.visible = false
	n.add_child(pr)
	var bron: Node3D = null
	for c in n.find_children("bron_*", "", true, false):
		if c is Node3D and (c as Node3D).visible and c.name != "bron_tarcza":
			bron = c
			break
	var krag := _krag(Color(0.62, 0.07, 0.05), 0.42 * s if not en.boss else 0.66 * s)  # autor 26.11: kręgi mniejsze (było 0,62 / 0,95)
	add_child(krag)
	var d := {"wezel": n, "ap": ap, "swiatlo": l, "blysk": blysk, "martwy": false, "smierc": 0.0, "wrog": weakref(en), "kat": en.kat, "rodzaj": en.rodzaj,
		"znak": znak, "znak_mat": zm, "glint": gw, "pierscien": pr, "pierscien_mat": prm, "bron": bron, "zamach_byl": false, "glint_byl": false,
		"krag": krag, "obrys": obrys, "obrys_wl": false, "skala": s, "ost_traf": en.licznik_trafien, "reakcja": 0.0, "flash": 0.0, "odchyl": 0.0, "odchyl_v": 0.0, "ost_hp": en.hp, "traf_licznik": 0}
	_wrogowie[id] = d
	return d


## Błysk „paruj teraz” zapala się dokładnie wtedy, gdy wciśnięcie parowania już zdąży (początek okna gracza),
## a zwężający się pierścień od początku zamachu pokazuje, kiedy to nastąpi (jak w grach rytmicznych).
var BLYSK_PRZED := 0.28
const SILA_KLINA := 0.95  # klin zasięgu na ziemi (autor 26.11: „nie widzę ciosu wroga”; było 0,6)
var _podpowiedz_pochodni := 0.0


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
	zm.set_shader_parameter("sila", SILA_KLINA)
	if en.rodzaj == "archer":
		zm.set_shader_parameter("dlugosc", clampf((en.w.distance_to(rajd.gracz.w) + 1.0) / 12.0, 0.15, 1.0))
	BLYSK_PRZED = rajd.dlugosc_okna_parowania()
	var pr: MeshInstance3D = d["pierscien"]
	var pm: ShaderMaterial = d["pierscien_mat"]
	var zostalo: float = en.zamach
	pr.visible = widac and en.rodzaj != "archer"
	pr.global_position = Vector3(en.w.x, 0.04, en.w.y)
	# promień: od szerokiego do wewnętrznego koła dokładnie w chwili ciosu
	pm.set_shader_parameter("promien_frontu", clampf(zostalo / maxf(en.zamach_dl, 0.01), 0.0, 1.0))
	pm.set_shader_parameter("w_oknie", 1.0 if zostalo <= BLYSK_PRZED else 0.0)
	if widac and rajd.gracz.pochodnia_w_rece and not en.ciezki and en.rodzaj != "archer" and _podpowiedz_pochodni <= 0.0:
		_podpowiedz_pochodni = 6.0
		rajd.napis(rajd.gracz.w - Vector2(1.1, 1.1), "Z POCHODNIĄ NIE SPARUJESZ — F / krzyżak dół", Color("f59e0b"), 11)
	var gw: Sprite3D = d["glint"]
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
		gw.scale = Vector3.ONE * (0.5 + 0.8 * sin(f * PI) + 0.15)
		gw.rotation.z = f * 1.6
	else:
		gw.visible = false


func _zgas_zapowiedz(d: Dictionary, dt: float) -> void:
	d["zamach_byl"] = false
	(d["pierscien"] as MeshInstance3D).visible = false
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


var _sh_pier: Shader
func _shader_pierscienia() -> Shader:
	if _sh_pier == null:
		_sh_pier = Shader.new()
		_sh_pier.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 kolor : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float promien_frontu = 1.0;
uniform float w_oknie = 0.0;
uniform float ciezki = 0.0;
varying vec2 lok;
void vertex() { lok = VERTEX.xz / 1.6; }
void fragment() {
	float r = length(lok);
	// koło docelowe (chwila ciosu)
	float r0 = 0.32;
	float cel = exp(-pow((r - r0) * 38.0, 2.0));
	// front zwęża się od krawędzi do koła docelowego
	float rf = mix(r0, 1.0, promien_frontu);
	float front = exp(-pow((r - rf) * 22.0, 2.0));
	// w oknie parowania: wypełnienie i mocny, biały rozbłysk
	float wyp = w_oknie * (1.0 - smoothstep(r0 - 0.02, r0 + 0.02, r)) * 0.35;
	vec3 k = mix(kolor.rgb, vec3(1.0, 0.97, 0.85), w_oknie * (1.0 - ciezki) * 0.7);
	float a = cel * (0.45 + 0.55 * w_oknie) + front * (0.8 + 0.6 * w_oknie) + wyp;
	ALBEDO = k * (1.2 + 1.8 * w_oknie);
	ALPHA = clamp(a, 0.0, 1.0);
}
"""
	return _sh_pier


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
uniform float dlugosc = 1.0;
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
	// wąski klin strzały: kończy się tuż za graczem i wygasa ku końcowi (nie snop światła w mrok)
	if (kat < 0.1) { m *= (1.0 - smoothstep(dlugosc * 0.55, dlugosc, r)) * 0.8; }
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
	_podpowiedz_pochodni = maxf(0.0, _podpowiedz_pochodni - dt)
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
			# zapowiedź ciosu: poświata sylwetki (poswiata.gdshader w _reakcja_wroga), bez światła na otoczenie
			# (autor 26.11: „lekki shader zamiast słupa światła”)
			_zapowiedz(en, d, t, n.visible)
		elif en.cios_anim > 0.0:
			_graj(ap, "cios", 1.0 - en.cios_anim / 0.34)
		elif d["reakcja"] > 0.0:
			_graj(ap, "trafienie", 1.0 - d["reakcja"] / REAKCJA)
		elif czas - en._ruch_czas < 0.15:
			_graj(ap, "chod", -1.0, en.spd / 2.0)
		else:
			_graj(ap, "postoj", -1.0)
		if en.zamach <= 0.0 or en.ogluszenie > 0.0:
			_zgas_zapowiedz(d, dt)
		_reakcja_wroga(en, d, n, dt)
		_obrys_wroga(en, d)
		var krag: MeshInstance3D = d["krag"]
		var namierzony: bool = rajd.cel_namierzony == en
		krag.visible = n.visible and (en.stan == "walka" or namierzony) and not lekki_krag
		(krag.material_override as ShaderMaterial).set_shader_parameter("kolor", Color(1.0, 0.75, 0.3) if namierzony else Color(0.62, 0.07, 0.05))
		(krag.material_override as ShaderMaterial).set_shader_parameter("sila", 1.6 if namierzony else 1.0)
		krag.global_position = Vector3(n.position.x, 0.025, n.position.z)
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
			(d2["blysk"] as StandardMaterial3D).next_pass = null   # bez obrysu i poświaty na poległym
			(d2["znak"] as MeshInstance3D).visible = false
			(d2["glint"] as Sprite3D).visible = false
			(d2["pierscien"] as MeshInstance3D).visible = false
			(d2["krag"] as MeshInstance3D).visible = false   # czerwony krąg walki nie zostaje pod poległym
		d2["smierc"] += dt
		var ap2: AnimationPlayer = d2["ap"]
		_graj(ap2, "smierc", minf(1.0, d2["smierc"] / 1.4))
		# autor 26.11: ciało rozpada się w pył, zostaje skrzyneczka albo krzyżyk do przeszukania (_aktualizuj_rekwizyty)
		var n2: Node3D = d2["wezel"]
		if d2["smierc"] >= SMIERC_DO_ROZPADU and not d2.get("pyl", false):
			d2["pyl"] = true
			d2["skala0"] = n2.scale
			if n2.visible:
				var pyl := _pyl_rozpadu(float(SKALA_WROGA.get(d2.get("rodzaj", ""), 1.0)))
				pyl.position = n2.position + Vector3(0, 0.6, 0)
				add_child(pyl)
		if d2.get("pyl", false) and n2.visible:
			var t2 := clampf((d2["smierc"] - SMIERC_DO_ROZPADU) / CZAS_ROZPADU, 0.0, 1.0)
			if t2 >= 1.0:
				n2.visible = false
				d2["rozpadl"] = true
			else:
				var s0: Vector3 = d2["skala0"]
				n2.scale = Vector3(s0.x * (1.0 - 0.35 * t2), s0.y * (1.0 - t2 * 0.97), s0.z * (1.0 - 0.35 * t2))


const SMIERC_DO_ROZPADU := 1.45   # po animacji śmierci (1,4 s)
const CZAS_ROZPADU := 0.55
const ZNAK_PO := 1.7               # skrzyneczka / krzyżyk pojawia się, gdy ciało się rozsypie


## Pył po rozpadzie wroga: szary popiół z kilkoma iskrami, unosi się i opada (jednorazowo).
func _pyl_rozpadu(skala: float) -> GPUParticles3D:
	var c := GPUParticles3D.new()
	c.amount = 70
	c.lifetime = 1.6
	c.one_shot = true
	c.explosiveness = 0.75
	c.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.35, 0.6, 0.35) * skala
	pm.direction = Vector3.UP
	pm.spread = 50.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0.15, 0.25, 0.05)
	pm.damping_min = 0.4
	pm.damping_max = 0.9
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var gr := Gradient.new()
	gr.set_color(0, Color(0.55, 0.52, 0.5, 0.95))
	gr.add_point(0.15, Color(1.0, 0.45, 0.12, 0.9))
	gr.add_point(0.35, Color(0.42, 0.4, 0.38, 0.75))
	gr.set_color(gr.get_point_count() - 1, Color(0.2, 0.19, 0.18, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = gr
	pm.color_ramp = gt
	c.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _kropka()
	q.material = m
	c.draw_pass_1 = q
	c.emitting = true
	get_tree().create_timer(2.5).timeout.connect(c.queue_free)
	return c


## Znak po poległym: skrzyneczka albo krzyżyk (boss: złoty kufer). Rośnie z ziemi, gdy ciało się rozsypie.
func _znak_zwlok(z: Dictionary, czas: float) -> Node3D:
	var wz: Vector2 = z["w"]
	var h := _hash(int(wz.x * 10.0), int(wz.y * 10.0))
	var n: Node3D
	if z.get("boss", false):
		n = _rekwizyt("las/p8_kufer_zloto", 0.9, true)
	elif h % 2 == 0:
		n = _rekwizyt("las/p8_kufer", 0.6, true)
	else:
		n = _rekwizyt("las/p1_grave_cross", 0.8)
	n.position = Vector3(wz.x, float(n.get_meta("y0")), wz.y)
	n.rotation.y = float(h % 628) / 100.0
	n.set_meta("skala", n.scale)
	n.set_meta("od", czas)
	n.scale = Vector3.ONE * 0.001
	return n


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
		elif not z.get("sakwa", false) and not _zwloki.has(klucz):
			_zwloki[klucz] = _znak_zwlok(z, czas)
		if not z.get("sakwa", false) and _zwloki.has(klucz):
			var zn: Node3D = _zwloki[klucz]
			var t3 := clampf((czas - float(zn.get_meta("od"))) - ZNAK_PO, 0.0, 0.35) / 0.35
			var sk: Vector3 = zn.get_meta("skala")
			zn.scale = sk * maxf(0.001, t3)
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



const GRUBOSC_OBRYSU := 0.035  # m (cieńszy ginie w izometrii)
const KOLOR_OBRYSU := Color(0.9, 0.2, 0.1)


## Obrys: włączony, gdy wróg walczy (albo jest namierzony); w zamachu jaśnieje barwą ciosu
## (złoty = paruj, czerwony = ciężki / tylko unik, błękitny = strzała), ogłuszony = złoty puls (riposta).
func _obrys_wroga(en, d: Dictionary) -> void:
	var blysk: StandardMaterial3D = d["blysk"]
	var obrys: StandardMaterial3D = d["obrys"]
	var wl: bool = en.hp > 0.0 and (en.stan == "walka" or rajd.cel_namierzony == en)
	if wl != bool(d["obrys_wl"]):
		d["obrys_wl"] = wl
		blysk.next_pass = obrys if wl else null
	if not wl:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var k := KOLOR_OBRYSU
	if en.ogluszenie > 0.0:
		k = Color(1.0, 0.8, 0.45).lerp(Color(1.0, 0.92, 0.7), 0.5 + 0.5 * sin(t * 4.0))   # ogłuszony: wolny, łagodny puls
	elif en.zamach > 0.0 and en.zamach_dl > 0.0:
		var f: float = 1.0 - en.zamach / en.zamach_dl
		var kz := Color(0.95, 0.25, 0.12) if en.ciezki else (Color(0.65, 0.82, 1.0) if en.rodzaj == "archer" else Color(1.0, 0.82, 0.48))
		k = KOLOR_OBRYSU.lerp(kz, 0.35 + 0.65 * f)
	obrys.albedo_color = k


# ---------------------------------------------------------------- MIĘSO TRAFIEŃ (tylko wygląd)
## Reakcja na trafienie trwa dłużej niż okno logiki (en.trafiony 0,15 s), żeby cios był widoczny:
## błysk ciała, wzdrygnięcie (klip „trafienie”), odchylenie do tyłu na sprężynie i krótki „przysiad” sylwetki.
const REAKCJA := 0.42
var lekki_krag := false


func _reakcja_wroga(en, d: Dictionary, n: Node3D, dt: float) -> void:
	var nowe_traf: bool = en.licznik_trafien != int(d["ost_traf"])
	d["ost_traf"] = en.licznik_trafien
	if nowe_traf:
		var strata: float = maxf(0.0, float(d["ost_hp"]) - en.hp) / maxf(1.0, en.hp_max)
		var mocno: float = clampf(0.45 + strata * 3.0, 0.45, 1.0)
		d["flash"] = 1.0
		d["traf_licznik"] = int(d["traf_licznik"]) + 1
		d["odchyl_v"] = float(d["odchyl_v"]) - 10.0 * mocno
		if en.zamach <= 0.0 and en.cios_anim <= 0.0 and en.ogluszenie <= 0.0:
			d["reakcja"] = REAKCJA
	d["ost_hp"] = en.hp
	d["reakcja"] = maxf(0.0, float(d["reakcja"]) - dt)
	d["flash"] = maxf(0.0, float(d["flash"]) - dt / 0.16)
	# sprężyna odchylenia (rad): szybki odrzut, sprężysty powrót
	var o: float = d["odchyl"]
	var v: float = d["odchyl_v"]
	v += (-o * 220.0 - v * 18.0) * dt
	o += v * dt
	d["odchyl"] = clampf(o, -0.35, 0.2)
	d["odchyl_v"] = v
	n.rotation.x = d["odchyl"]
	var f: float = d["flash"]
	var sk: float = d["skala"]
	n.scale = Vector3(sk * (1.0 + 0.08 * f), sk * (1.0 - 0.1 * f), sk * (1.0 + 0.08 * f))
	var b: StandardMaterial3D = d["blysk"]
	var kol := Color(1.0, 0.93, 0.82, 0.85 * f * f)
	# zapowiedź ciosu na ciele (autor 26.11: „nie widzę ciosu wroga”): sylwetka nabiera barwy aż do uderzenia —
	# złota = do sparowania, czerwona = ciężki (tylko unik), błękitna = strzała
	# zapowiedź ciosu: lekka, złotawa poświata całej sylwetki narastająca płynnie (autor 26.11: „bardziej
	# złotawe, lekkie”; bez migania i bez osobnego shadera, który zacinał grę przy pierwszym użyciu)
	var sila_p := 0.0
	if en.zamach > 0.0 and en.ogluszenie <= 0.0 and en.zamach_dl > 0.0:
		var t: float = 1.0 - en.zamach / en.zamach_dl
		var kz := Color(0.95, 0.32, 0.18) if en.ciezki else (Color(0.7, 0.82, 1.0) if en.rodzaj == "archer" else Color(1.0, 0.84, 0.52))
		sila_p = 0.05 + 0.17 * t * t   # do strojenia
		if sila_p > kol.a:
			kol = Color(kz, sila_p)
	d["tint_zamachu"] = sila_p
	b.albedo_color = kol


## Krąg pod stopami: czerwony pod wrogiem w walce, ciepły pod bohaterem — postać nie ginie w mroku.
var _sh_krag: Shader
func _krag(kolor: Color, promien: float) -> MeshInstance3D:
	if _sh_krag == null:
		_sh_krag = Shader.new()
		_sh_krag.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 kolor : source_color = vec4(0.85, 0.12, 0.08, 1.0);
uniform float sila = 1.0;
uniform float promien = 1.0;
varying vec2 lok;
void vertex() { lok = VERTEX.xz / promien; }
void fragment() {
	float r = length(lok);
	float obwod = exp(-pow((r - 0.86) * 11.0, 2.0));
	float wnetrze = (1.0 - smoothstep(0.2, 0.95, r)) * 0.12;
	ALBEDO = kolor.rgb;
	ALPHA = clamp((obwod * 0.5 + wnetrze) * sila, 0.0, 1.0) * step(r, 1.0);
}
"""
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(promien * 2.0, promien * 2.0)
	m.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = _sh_krag
	mat.set_shader_parameter("kolor", kolor)
	mat.set_shader_parameter("promien", promien)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.top_level = true
	m.visible = false
	return m


## Wybuch cząsteczek w 3D (zamiast kwadratowych pikseli 2D): jasne = iskry z poświatą, ciemne = krople krwi.
var _mat_iskry: StandardMaterial3D
var _mat_krople: StandardMaterial3D
func czastki(w: Vector2, ile: int, kolor: Color, predkosc: float, zycie: float) -> void:
	var jasne := kolor.get_luminance() > 0.45
	var gp := GPUParticles3D.new()
	gp.one_shot = true
	gp.explosiveness = 0.95
	gp.amount = clampi(int(ile * (1.6 if jasne else 2.2)), 4, 64)
	gp.lifetime = zycie * (0.9 if jasne else 1.6)
	gp.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 75.0
	pm.initial_velocity_min = predkosc * 0.5
	pm.initial_velocity_max = predkosc * 1.2
	pm.gravity = Vector3(0, -9.0 if jasne else -12.0, 0)
	pm.damping_min = 1.0
	pm.damping_max = 3.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var krzywa := Curve.new()
	krzywa.add_point(Vector2(0, 1))
	krzywa.add_point(Vector2(1, 0.15))
	var ct := CurveTexture.new()
	ct.curve = krzywa
	pm.scale_curve = ct
	pm.color = kolor
	gp.process_material = pm
	var q := QuadMesh.new()
	if jasne:
		q.size = Vector2(0.07, 0.07)
		if _mat_iskry == null:
			_mat_iskry = StandardMaterial3D.new()
			_mat_iskry.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_mat_iskry.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			_mat_iskry.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mat_iskry.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			_mat_iskry.vertex_color_use_as_albedo = true
			_mat_iskry.albedo_texture = _kropka()
			_mat_iskry.albedo_color = Color(2.2, 2.0, 1.7)
		q.material = _mat_iskry
	else:
		q.size = Vector2(0.06, 0.06)
		if _mat_krople == null:
			_mat_krople = StandardMaterial3D.new()
			_mat_krople.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_mat_krople.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mat_krople.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			_mat_krople.vertex_color_use_as_albedo = true
			_mat_krople.albedo_texture = _kropka()
		q.material = _mat_krople
	gp.draw_pass_1 = q
	gp.position = Vector3(w.x, 1.0, w.y)
	add_child(gp)
	gp.emitting = true
	get_tree().create_timer(gp.lifetime + 0.3, false).timeout.connect(gp.queue_free)


## Zamrożenie klatki przy trafieniu (rajd.hitstop): animacje stają razem z logiką.
func zamroz() -> void:
	if _ap_bohatera:
		_ap_bohatera.speed_scale = 0.0
	for id in _wrogowie:
		(_wrogowie[id]["ap"] as AnimationPlayer).speed_scale = 0.0


## Bohater: błysk ciała przy otrzymanym ciosie (czerwony) i przy parowaniu (złoty).
var _blysk_bohatera: StandardMaterial3D
var _krag_bohatera: MeshInstance3D


func _aktualizuj_blysk_bohatera() -> void:
	if _blysk_bohatera == null:
		return
	var tr: float = rajd.blysk_trafienia
	var pa: float = rajd.blysk_parowania
	if pa > tr:
		_blysk_bohatera.albedo_color = Color(1.0, 0.85, 0.45, 0.55 * pa * pa)
	else:
		_blysk_bohatera.albedo_color = Color(1.0, 0.2, 0.15, 0.6 * tr * tr)
	if _krag_bohatera:
		var lad: float = rajd.gracz.ladowanie
		var km: ShaderMaterial = _krag_bohatera.material_override
		if lad >= rajd.PROG_MOCNEGO:
			var puls := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 16.0)
			km.set_shader_parameter("kolor", Color(1.0, 0.55, 0.15))
			km.set_shader_parameter("sila", 1.6 + 0.8 * puls)
		elif lad > 0.05:
			km.set_shader_parameter("kolor", Color(1.0, 0.65, 0.3))
			km.set_shader_parameter("sila", 0.7 + 1.4 * lad / rajd.PROG_MOCNEGO)
		else:
			km.set_shader_parameter("kolor", Color(1.0, 0.75, 0.4))
			km.set_shader_parameter("sila", 0.7)
		_krag_bohatera.global_position = Vector3(bohater.position.x, 0.024, bohater.position.z)
		_krag_bohatera.visible = not rajd.gracz.martwy and not lekki_krag


# ---------------------------------------------------------------- EFEKTY WALKI (arkusze NightBrand)
var _efekty3d: Array = []   # [Sprite3D, czas, długość, opóźnienie]
var _plamy_krwi: Array = []
var _tex_efekt := {}


func _tex_ef(nazwa: String) -> Texture2D:
	if not _tex_efekt.has(nazwa):
		_tex_efekt[nazwa] = load("res://zasoby/3d/efekty/%s.png" % nazwa)
	return _tex_efekt[nazwa]


## Krótka animacja z paska 4 klatek nad sceną. kat: kierunek w świecie (odbicie w poziomie wg kierunku na ekranie).
func efekt(nazwa: String, w: Vector2, wys: float, kat: float, skala: float, dlugosc: float, opoznienie := 0.0, losowa := false) -> void:
	var sp := Sprite3D.new()
	sp.texture = _tex_ef(nazwa)
	sp.hframes = 4
	sp.frame = randi() % 4 if losowa else 0
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.double_sided = true
	sp.pixel_size = skala / 256.0
	sp.render_priority = 5
	sp.position = Vector3(w.x, wys, w.y)
	# kierunek na ekranie izometrycznym: x świata w prawo-dół, y świata w lewo-dół
	sp.flip_h = (cos(kat) - sin(kat)) < 0.0
	sp.visible = opoznienie <= 0.0
	add_child(sp)
	_efekty3d.append([sp, 0.0, dlugosc, opoznienie, losowa])


## Krew: bryzg w kierunku ciosu i (czasem) kałuża na podłodze; kałuże zostają (limit).
func krew(w: Vector2, kat: float, mocno := false, zawsze_kaluza := false) -> void:
	efekt("krew_bryzg", w + Vector2(cos(kat), sin(kat)) * 0.35, 0.9, kat, 1.2 if mocno else 0.9, 0.24, 0.0)
	if lekki or not (zawsze_kaluza or (mocno and randf() < 0.6) or randf() < 0.25):
		return
	var d := Decal.new()
	d.texture_albedo = _tex_ef("krew_kaluza_%d" % (randi() % 4))
	var r := randf_range(0.9, 1.5) * (1.3 if zawsze_kaluza else 1.0)
	d.size = Vector3(r, 0.6, r)
	d.position = Vector3(w.x + cos(kat) * 0.3, 0.0, w.y + sin(kat) * 0.3)
	d.rotation.y = randf() * TAU
	d.albedo_mix = 0.95
	d.upper_fade = 0.4
	d.lower_fade = 0.4
	add_child(d)
	_plamy_krwi.append(d)
	if _plamy_krwi.size() > 60:
		(_plamy_krwi.pop_front() as Node).queue_free()


func _aktualizuj_efekty(dt: float) -> void:
	for i in range(_efekty3d.size() - 1, -1, -1):
		var e: Array = _efekty3d[i]
		var sp: Sprite3D = e[0]
		if e[3] > 0.0:
			e[3] -= dt
			if e[3] > 0.0:
				continue
			sp.visible = true
		e[1] += dt
		var t: float = e[1] / e[2]
		if t >= 1.0:
			sp.queue_free()
			_efekty3d.remove_at(i)
			continue
		if e[4]:
			sp.modulate.a = 1.0 - t * t
		else:
			sp.frame = mini(3, int(t * 4.0))
			sp.modulate.a = 1.0 if t < 0.75 else (1.0 - t) * 4.0


func aktualizuj(dt: float, czas: float) -> void:
	_ustaw_kamere()
	_krok_mgly(dt)
	_aktualizuj_efekty(dt)
	if _pyl:
		_pyl.position = Vector3(rajd.gracz.w.x, 1.2, rajd.gracz.w.y)
	_aktualizuj_bohatera(dt)
	_aktualizuj_blysk_bohatera()
	_aktualizuj_wrogow(dt, czas)
	_aktualizuj_rekwizyty(czas)


# ---------------------------------------------------------------- MGŁA PŁYNNIE I GŁĘBIA (runda mapa-mgla-i-wczytywanie)
## Jasność pól zmienia się płynnie do celu: odsłonięcie ~0,3 s, przygaszenie do „widzianego” ~0,7 s.
const PODLOGI := ["podloga", "sciezka", "ekstrakcja", "chata"]
var _jasn_obraz: Image
var _jasn_tex: ImageTexture
var _jasn_brudne := false
var _zalezne := {}   # pole przejścia -> pola nieprzechodnie, które biorą od niego jasność (gładka mgła)


var _podl_wl := PackedByteArray()
## Podłoga wokół odkrytych pól (promień 2): shader ściemnia ją gładko ku nieznanemu, więc brzeg nie jest
## schodkiem z kafli; dalej podłogi nie ma (nie zdradza układu i nie obciąża karty).
func _odslon_podloge(widok: PackedByteArray) -> void:
	if _podl_wl.size() != N * N:
		_podl_wl.resize(N * N)
		_podl_wl.fill(0)
	for i in rajd.zmienione_widoku:
		if widok[i] == 0:
			continue
		var x: int = i % N
		var y: int = i / N
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var ux := x + dx
				var uy := y + dy
				if ux < 0 or uy < 0 or ux >= N or uy >= N:
					continue
				var u := uy * N + ux
				if _podl_wl[u] == 1:
					continue
				_podl_wl[u] = 1
				for wpis in _indeks.get(u, []):
					if wpis[0] in PODLOGI:
						var pp: Vector3 = wpis[2]
						(_mm[wpis[0]].multimesh as MultiMesh).set_instance_transform(wpis[1], Transform3D(wpis[3], Vector3(pp.x, wpis[4], pp.z)))


func _licz_zalezne() -> void:
	var tmp := {}
	for j in N * N:
		var k: int = _kotwica_pelna[j]
		if k >= 0 and k != j:
			if not tmp.has(k):
				tmp[k] = []
			tmp[k].append(j)
	for k in tmp:
		_zalezne[k] = PackedInt32Array(tmp[k])


func _krok_mgly(dt: float) -> void:
	if _fade.is_empty():
		return
	var gotowe: Array = []
	for i in _fade:
		var c: float = _jasn[i]
		var cel: float = _cel_jasn[i]
		c = move_toward(c, cel, dt / (CZAS_ODSLONY if cel > c else CZAS_PRZYGASZENIA))
		_jasn[i] = c
		if is_equal_approx(c, cel):
			gotowe.append(i)
		# gładka mgła: jasność pola i pól, które od niego zależą (mury, gąszcz — najbliższe przejście)
		var kol_j := Color(c, c, c)
		_jasn_obraz.set_pixel(i % N, i / N, kol_j)
		for j in _zalezne.get(i, PackedInt32Array()):
			_jasn_obraz.set_pixel(j % N, j / N, kol_j)
		_jasn_brudne = true
		if not _indeks.has(i):
			continue
		for wpis in _indeks[i]:
			if wpis[0] in PODLOGI:
				continue
			var mm: MultiMesh = _mm[wpis[0]].multimesh
			if wpis[0] == "ekstrakcja":
				mm.set_instance_color(wpis[1], Color(c * 0.7, c, c * 0.85, 1.0))
			else:
				mm.set_instance_color(wpis[1], Color(c, c, c, 1.0))
	for i in gotowe:
		_fade.erase(i)
	if _jasn_brudne:
		_jasn_brudne = false
		_jasn_tex.update(_jasn_obraz)


## Najbliższe pole przechodnie dla każdego pola mapy (BFS bez limitu): wierzch skały i korony lasu
## odsłaniają się razem z przejściem, przy którym leżą (nie zdradzają układu mapy w mgle).
func _licz_kotwice_pelna() -> void:
	var mapa = rajd.mapa
	_kotwica_pelna.resize(N * N)
	_kotwica_pelna.fill(-1)
	var kol := PackedInt32Array()
	for i in N * N:
		if mapa.siatka[i] != K.MUR:
			_kotwica_pelna[i] = i
			kol.append(i)
	var g := 0
	while g < kol.size():
		var i: int = kol[g]
		g += 1
		var x := i % N
		var y := i / N
		for s in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var qx: int = x + s.x
			var qy: int = y + s.y
			if qx < 0 or qy < 0 or qx >= N or qy >= N:
				continue
			var j := qy * N + qx
			if _kotwica_pelna[j] < 0:
				_kotwica_pelna[j] = _kotwica_pelna[i]
				kol.append(j)


## Płaski wierzch (skały albo koron) na polu i, w kwadracie 16×16 m, widoczny wg najbliższego przejścia.
func _wierzch(i: int, wys: float, listy: Dictionary, siatki: Dictionary, rodzaj: String) -> void:
	var k: int = _kotwica_pelna[i] if _kotwica_pelna[i] >= 0 else i
	var klucz := rodzaj + _kwadrat(i)
	if not listy.has(klucz):
		listy[klucz] = []
		siatki[klucz] = _plyta()
	listy[klucz].append([k, Basis().scaled(Vector3(1.02, 1.0, 1.02)), wys, _przes(i, k)])


## Materiały głębi: wierzch litej skały (tekstura muru krainy) i zwarte korony lasu (liście z ziemi lasu, ciemne).
func _otoczenie_materialy() -> void:
	var w := wyglad
	for rodz in ["wierzch", "korona"]:
		var m := ShaderMaterial.new()
		m.shader = SHADER_OTOCZENIA
		var tex: String = w["c"] if rodz == "korona" else String(w.get("wierzch", w["mur"]))
		m.set_shader_parameter("alb", _tsw(tex, "alb"))
		m.set_shader_parameter("szum", _szum)
		m.set_shader_parameter("skala", 0.22 if rodz == "korona" else float(w["mur_skala"]) * 0.6)
		var ton_muru: Color = w["mur_ton"]
		# jasność wierzchu: ciemniejszy od oświetlonej podłogi, ale z czytelną fakturą (unshaded w shaderze)
		m.set_shader_parameter("ton", Color(0.3, 0.4, 0.27) if rodz == "korona" else w.get("wierzch_ton", Color(0.4 * ton_muru.r, 0.38 * ton_muru.g, 0.4 * ton_muru.b)))
		m.set_shader_parameter("rozmiar_mapy", float(N))
		_mgla_do(m)
		m.set_shader_parameter("jasnosc_mapy", _jasn_tex)
		m.set_shader_parameter("mgla_gladka", true)
		_mat[rodz] = m


## Płaszczyzna poza mapą: skała (loch) albo korony (las) ciągną się dalej i gasną w tło (autor 26.11:
## „czarne tło odcina się brzydko”). Wewnątrz granic mapy płaszczyzna jest czarna (nie zdradza układu).
var _plaszczyzna_otoczenia: MeshInstance3D
var _mgla_obraz: Image
var _mgla_tex: ImageTexture


func _mgla_do(m: ShaderMaterial) -> void:
	m.set_shader_parameter("mgla_znane", _mgla_tex)
	m.set_shader_parameter("rozmiar_mgly", float(N))


func _otoczenie() -> void:
	var zew: ShaderMaterial = (_mat["korona"] if las and not osada else _mat["wierzch"]).duplicate()
	zew.set_shader_parameter("poza_mapa", 1.0)
	zew.set_shader_parameter("mgla_gladka", false)
	var plaszcz := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var marg := 70.0
	pm.size = Vector2(N + marg * 2.0, N + marg * 2.0)
	plaszcz.mesh = pm
	plaszcz.material_override = zew
	plaszcz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plaszcz.position = Vector3(N * 0.5, 3.1 if las and not osada else WYS_MURU * 1.15, N * 0.5)
	add_child(plaszcz)
	_plaszczyzna_otoczenia = plaszcz



## Przekrój wysokich rzeczy przed bohaterem (od strony kamery) wg miejsca, w którym NAPRAWDĘ stoją:
## drzewa i korony w lesie znikają (korona zasłoniłaby walkę), wierzch skały w lochu znika jak obniżony mur.
## Poza przekrojem rzecz jest widoczna, gdy jej kotwica (najbliższe przejście) jest odkryta.
func _przekroj_wysokich(g: Vector2) -> void:
	var widok: PackedByteArray = rajd.widok
	var gx := int(g.x)
	var gy := int(g.y)
	var sprawdz := _do_sprawdzenia
	_do_sprawdzenia = {}
	for yy in range(maxi(0, gy - 16), mini(N, gy + 17)):
		for xx in range(maxi(0, gx - 16), mini(N, gx + 17)):
			var t := yy * N + xx
			if _indeks_wys.has(t):
				sprawdz[t] = true
	for t in _przekroj_ost:
		sprawdz[t] = true
	var w_przekroju := {}
	for t in sprawdz:
		if not _indeks_wys.has(t):
			continue
		var dx := float(t % N) + 0.5 - g.x
		var dy := float(t / N) + 0.5 - g.y
		var maska := 0
		var lista: Array = _indeks_wys[t]
		for n in lista.size():
			var rodzaj: String = lista[n][0]
			var tnij := false
			if rodzaj.begins_with("wierzch"):
				tnij = dx + dy > 0.6 and absf(dx) < 9.5 and absf(dy) < 9.5 and absf(dx - dy) < 11.0
			elif las:
				tnij = dx + dy > 0.6 and dx + dy < 18.0 and absf(dx - dy) < 9.0   # autor 26.11: drzewa dalej zasłaniały (było 15 / 7,5)
			if tnij:
				w_przekroju[t] = true
			elif widok[int(lista[n][5])] > 0 or rodzaj.begins_with("wierzch") or rodzaj.begins_with("korona"):
				maska |= 1 << n   # wierzch i korony stoją zawsze (mrok z gładkiej mapy jasności); drzewa wg kotwicy
		var domyslna := 0   # wierzch i korony stoją od początku (_mapa), drzewa nie
		for n2 in lista.size():
			var r2: String = lista[n2][0]
			if r2.begins_with("wierzch") or r2.begins_with("korona"):
				domyslna |= 1 << n2
		if maska == int(_maska_widocznych.get(t, domyslna)):
			continue
		for n in lista.size():
			var wpis: Array = lista[n]
			var p: Vector3 = wpis[2]
			var b: Basis = (wpis[3] as Basis) if (maska & (1 << n)) else Basis().scaled(Vector3.ZERO)
			(_mm[wpis[0]].multimesh as MultiMesh).set_instance_transform(wpis[1], Transform3D(b, Vector3(p.x, wpis[4], p.z)))
		_maska_widocznych[t] = maska
	_przekroj_ost = w_przekroju


var _przekroj_ost := {}
