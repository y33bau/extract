extends Node
## Efekty dźwiękowe syntetyzowane przy starcie (port syntezatora z wersji JS): szum przez filtr + tony.

const HZ := 22050
var wyciszony := false
var _bufory := {}
var _gracze: Array = []
var _nastepny := 0


func _ready() -> void:
	for i in 10:
		var g := AudioStreamPlayer.new()
		g.volume_db = -4.0
		add_child(g)
		_gracze.append(g)
	_bufory["zamach"] = _miks([_szum(0.14, 880, 0.15, "bp", true), _ton(280, 90, 0.10, "tri", 0.08)])
	_bufory["zamach_c"] = _miks([_szum(0.22, 520, 0.22, "bp", true), _ton(180, 90, 0.16, "tri", 0.08)])
	_bufory["trafienie"] = _miks([_szum(0.09, 650, 0.22, "lp", true), _ton(160, 55, 0.10, "saw", 0.16)])
	_bufory["blok"] = _miks([_szum(0.11, 1400, 0.22, "bp", true), _ton(420, 210, 0.12, "sq", 0.12)])
	_bufory["parowanie"] = _miks([_ton(1320, 1280, 0.42, "sin", 0.22), _ton(1980, 1920, 0.36, "tri", 0.16),
		_ton(2640, 2400, 0.24, "sin", 0.10), _szum(0.12, 3200, 0.24, "hp", false)])
	_bufory["riposta"] = _miks([_ton(220, 60, 0.30, "saw", 0.26), _ton(880, 440, 0.22, "tri", 0.16), _szum(0.18, 1200, 0.28, "lp", true)])
	_bufory["cieciwa"] = _miks([_ton(440, 190, 0.12, "tri", 0.14), _szum(0.07, 1800, 0.10, "hp", true)])
	_bufory["unik"] = _miks([_szum(0.14, 480, 0.12, "lp", true)])
	_bufory["krok"] = _miks([_szum(0.04, 340, 0.045, "lp", false)])
	_bufory["bol"] = _miks([_ton(135, 50, 0.20, "saw", 0.20)])
	_bufory["picie"] = _miks([_ton(360, 540, 0.14, "sin", 0.10), _przesun(_ton(540, 740, 0.18, "sin", 0.10), 0.13)])
	_bufory["lup"] = _miks([_ton(580, 880, 0.10, "tri", 0.09)])
	_bufory["ui"] = _miks([_ton(420, 320, 0.04, "tri", 0.05)])
	_bufory["tik"] = _miks([_ton(528, 528, 0.10, "sin", 0.09)])
	# zapowiedzi ciosów wrogów: zwykły = metaliczny dźwięk ostrza, ciężki = niski pomruk
	_bufory["zapowiedz"] = _miks([_ton(760, 980, 0.16, "tri", 0.07), _szum(0.18, 2600, 0.05, "bp", true)])
	_bufory["zapowiedz_c"] = _miks([_ton(70, 52, 0.42, "saw", 0.16), _ton(105, 78, 0.38, "sq", 0.06)])
	_bufory["blysk"] = _miks([_ton(2350, 2300, 0.20, "sin", 0.15), _ton(3520, 3450, 0.14, "sin", 0.08)])
	_bufory["blysk_c"] = _miks([_ton(150, 90, 0.18, "saw", 0.14), _szum(0.10, 600, 0.12, "lp", true)])
	_bufory["ekstrakcja"] = _miks([_ton(392, 523, 0.24, "tri", 0.13), _przesun(_ton(523, 784, 0.40, "tri", 0.15), 0.18)])


func _graj(nazwa: String) -> void:
	if wyciszony or not _bufory.has(nazwa):
		return
	var g: AudioStreamPlayer = _gracze[_nastepny]
	_nastepny = (_nastepny + 1) % _gracze.size()
	g.stream = _bufory[nazwa]
	g.play()


func zamach(ciezki := false) -> void: _graj("zamach_c" if ciezki else "zamach")
func trafienie() -> void: _graj("trafienie")
func blok() -> void: _graj("blok")
func parowanie() -> void: _graj("parowanie")
func riposta() -> void: _graj("riposta")
func cieciwa() -> void: _graj("cieciwa")
func unik() -> void: _graj("unik")
func krok() -> void: _graj("krok")
func bol() -> void: _graj("bol")
func picie() -> void: _graj("picie")
func lup() -> void: _graj("lup")
func ui() -> void: _graj("ui")
func tik() -> void: _graj("tik")
func ekstrakcja() -> void: _graj("ekstrakcja")
func zapowiedz(ciezki := false) -> void: _graj("zapowiedz_c" if ciezki else "zapowiedz")
func blysk(ciezki := false) -> void: _graj("blysk_c" if ciezki else "blysk")


# ---------------- synteza
func _ton(f1: float, f2: float, dl: float, ksztalt: String, glosnosc: float) -> PackedFloat32Array:
	var n := int(dl * HZ)
	var out := PackedFloat32Array()
	out.resize(n)
	var faza := 0.0
	var f2b := maxf(25.0, f2)
	for i in n:
		var t := float(i) / n
		var f := f1 * pow(f2b / f1, t)
		faza += f / HZ
		var x := faza - floorf(faza)
		var s := 0.0
		match ksztalt:
			"sin": s = sin(x * TAU)
			"tri": s = 4.0 * absf(x - 0.5) - 1.0
			"saw": s = 2.0 * x - 1.0
			"sq": s = 1.0 if x < 0.5 else -1.0
		out[i] = s * glosnosc * pow(0.001 / glosnosc, t) if glosnosc > 0.001 else 0.0
	return out


func _szum(dl: float, czestotliwosc: float, glosnosc: float, filtr: String, opad: bool) -> PackedFloat32Array:
	var n := int(dl * HZ)
	var out := PackedFloat32Array()
	out.resize(n)
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in n:
		var t := float(i) / n
		var f := czestotliwosc * pow(140.0 / czestotliwosc, t) if opad else czestotliwosc
		f = clampf(f, 30.0, HZ * 0.45)
		var w0 := TAU * f / HZ
		var al := sin(w0) / (2.0 * 0.9)
		var cw := cos(w0)
		var b0 := 0.0
		var b1 := 0.0
		var b2 := 0.0
		match filtr:
			"lp":
				b0 = (1.0 - cw) / 2.0; b1 = 1.0 - cw; b2 = b0
			"hp":
				b0 = (1.0 + cw) / 2.0; b1 = -(1.0 + cw); b2 = b0
			_:
				b0 = al; b1 = 0.0; b2 = -al
		var a0 := 1.0 + al
		var a1 := -2.0 * cw
		var a2 := 1.0 - al
		var x := randf() * 2.0 - 1.0
		var y := (b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
		x2 = x1; x1 = x; y2 = y1; y1 = y
		out[i] = y * glosnosc * pow(0.001 / glosnosc, t) * 2.0
	return out


func _przesun(s: PackedFloat32Array, o: float) -> PackedFloat32Array:
	var pre := PackedFloat32Array()
	pre.resize(int(o * HZ))
	pre.append_array(s)
	return pre


func _miks(skladowe: Array) -> AudioStreamWAV:
	var n := 0
	for s in skladowe:
		n = maxi(n, s.size())
	var dane := PackedByteArray()
	dane.resize(n * 2)
	for i in n:
		var v := 0.0
		for s in skladowe:
			if i < s.size():
				v += s[i]
		dane.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = dane
	return w
