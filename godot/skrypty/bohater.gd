extends Node2D
## Hadræn: stan i wygląd. Logikę walki prowadzi rajd.gd (jedno miejsce reguł).
## Wygląd: arkusze z modelu 3D (dane/wyglad_bohatera.json, zasoby/hadraen/<zestaw>_<anim>.png).
## Arkusz: wiersze = 8 kierunków (wiersz d = kąt świata d*45°), kolumny = klatki.
## Zestaw arkuszy zależy od broni w ręce (broń jest klasą) i od tarczy.

const Iso = preload("res://skrypty/iso.gd")
const UNIK_DLUGOSC := 0.3

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
var celuje_drazkiem := false  # prawy drążek wskazuje kierunek (wtedy kroki w bok/tył mają sens)
var predkosc := Vector2.ZERO  # wygładzona prędkość (m/s): płynne ruszanie, hamowanie i skręt
var ruch_wektor := Vector2.ZERO  # świat: kierunek * prędkość z wejścia (do animacji chodu/biegu/uników bocznych)
var atak_licznik := 0  # rośnie z każdym zamachem (animacja startuje od nowa, także przy powtórzeniu tego samego ciosu)
# walka
var atak_czas := 0.0
var atak_dlugosc := 0.0
var atak_cd := 0.0
var atak_kat := 0.0
var combo := 0
var combo_reset := 0.0
var trzyma_atak := false   # przycisk ciosu wciśnięty (ładowanie mocnego ciosu)
var ladowanie := 0.0       # jak długo trzymany (s); od rajd.PROG_MOCNEGO cios po puszczeniu jest mocny
var zamach_anim := 0.0
var zamach_anim_max := 0.3
var blok := false
var blok_czas := 0.0
var okno_parowania := 0.0
var parowanie_cd := 0.0
var unik_czas := 0.0
var unik_kier := Vector2.ZERO
var unik_cd := 0.0
var luk_cd := 0.0
var riposta_niet := 0.0
var niet := 0.0              # nietykalność po trafieniu / bloku / parowaniu (s)
var niet_miganie := false    # miganie postaci (tylko po otrzymanym ciosie)
var stamina_przerwa := 0.0   # stamina nie odnawia się chwilę po akcji (s)
var faza_ciosu := ""         # "" / "zamach" / "ciecie" / "powrot" — cios w fazach (zobowiązanie)
var faza_czas := 0.0
var cios_ciezki := false
var cios_bron: Dictionary = {}
var pochodnia_w_rece := true
var martwy := false
var smierc_anim := 0.0
var rynsztunek: Dictionary = {}  # kopia profilu na czas rajdu

# wygląd
var zestaw := ""
var biezaca_anim := ""
var biezacy_kierunek := 0
var tryb_3d := false  # wygląd rysuje swiat3d.gd; tu zostaje stan i nakładki
var _arkusze: Dictionary = {}  # anim -> Texture2D
var _klucz_zestawu := ""

var sprite: Sprite2D
var plomien: Node2D
var pochodnia: PointLight2D
var poswiata: PointLight2D
var aura: Node2D
var _dlon := Vector2(-12, -48)  # lewa dłoń w układzie postaci (piksele ekranu)


func _ready() -> void:
	sprite = Sprite2D.new()
	var skala: float = Dane.wyglad.get("skala", 0.95)
	var kom: float = Dane.wyglad.get("komorka", 224)
	var stopy: float = Dane.wyglad.get("stopy_y", 176)
	sprite.scale = Vector2(skala, skala)
	sprite.offset = Vector2(0, kom * 0.5 - stopy)
	add_child(sprite)
	pochodnia = Swiatla.nowe(Color(1.0, 0.78, 0.52), 1.5, 270.0)
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
	odswiez_zestaw()


## Zestaw arkuszy dla wyposażenia: broń decyduje o stylu (klasie), tarcza o wariancie.
static func zestaw_dla(rynsz: Dictionary) -> String:
	var wyg: Dictionary = Dane.wyglad
	var bron_wyg: Dictionary = wyg.get("bron_zestaw", {})
	var z: String = wyg.get("bez_broni", "piesci")
	if rynsz.get("weapon"):
		var id: String = rynsz["weapon"]["id"]
		z = bron_wyg.get(id, wyg.get("domyslny", "dwureczny"))
	if rynsz.get("shield"):
		var z_tarcza: Dictionary = wyg.get("z_tarcza", {})
		z = z_tarcza.get(z, z)
	return z


func odswiez_zestaw() -> void:
	var klucz := str(rynsztunek.get("weapon")) + "|" + str(rynsztunek.get("shield"))
	if klucz == _klucz_zestawu and zestaw != "":
		return
	_klucz_zestawu = klucz
	zestaw = zestaw_dla(rynsztunek)
	_arkusze.clear()
	var klatki: Dictionary = Dane.wyglad.get("klatki", {}).get(zestaw, {})
	for anim in klatki.keys():
		var sc := "res://zasoby/hadraen/%s_%s.png" % [zestaw, anim]
		if ResourceLoader.exists(sc):
			_arkusze[anim] = load(sc)


func liczba_klatek(anim: String) -> int:
	return int(Dane.wyglad.get("klatki", {}).get(zestaw, {}).get(anim, 1))


## Kierunek arkusza (0..7) z kąta świata.
static func kierunek(k: float) -> int:
	return posmod(roundi(k / (PI / 4.0)), 8)


func _rysuj_plomien() -> void:
	if not pochodnia_w_rece or martwy:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var reka := _dlon
	var szczyt := reka + Vector2(0, -20)
	plomien.draw_line(reka + Vector2(0, 4), szczyt, Color("3a2618"), 3.0)
	var h := 9.0 + sin(t * 17.0) * 2.0 + cos(t * 29.0)
	var c := szczyt + Vector2(0, -7)
	plomien.draw_set_transform(c, 0, Vector2(1.0, h / 6.0))
	plomien.draw_circle(Vector2.ZERO, 6.0, Color(0.88, 0.33, 0.1, 0.9))
	plomien.draw_circle(Vector2(0, 1), 3.3, Color(1.0, 0.82, 0.4, 0.95))
	plomien.draw_set_transform(Vector2.ZERO)


func _rysuj_aure() -> void:
	if okno_parowania > 0.0 and not martwy:
		aura.draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.5))
		aura.draw_arc(Vector2.ZERO, 22, 0, TAU, 32, Color(1.0, 0.82, 0.43, 0.35 + okno_parowania), 2.0)
		aura.draw_set_transform(Vector2.ZERO)


## Wybór animacji i klatki ze stanu walki. Zwraca [anim, kąt, klatka].
func _wybierz(czas: float) -> Array:
	if martwy:
		var n := liczba_klatek("smierc")
		return ["smierc", kat, mini(n - 1, int(smierc_anim * 7.0))]
	if unik_czas > 0.0:
		var t := clampf(1.0 - unik_czas / UNIK_DLUGOSC, 0.0, 0.999)
		var ku := atan2(unik_kier.y, unik_kier.x) if unik_kier != Vector2.ZERO else kat
		return ["przewrot", ku, int(t * liczba_klatek("przewrot"))]
	if zamach_anim > 0.0:
		var nazwa := "atak%d" % (combo + 1)
		var t2 := clampf(1.0 - zamach_anim / zamach_anim_max, 0.0, 0.999)
		return [nazwa, atak_kat, int(t2 * liczba_klatek(nazwa))]
	if blok:
		if okno_parowania > 0.0 and blok_czas < 0.35:
			var np := liczba_klatek("parowanie")
			return ["parowanie", kat, mini(np - 1, int(blok_czas / 0.35 * np))]
		return ["blok", kat, int(czas * 5.0) % liczba_klatek("blok")]
	if w_ruchu:
		return ["chod", kat, int(krok_anim) % liczba_klatek("chod")]
	return ["postoj", kat, int(czas * 6.0) % liczba_klatek("postoj")]


func animuj(czas: float) -> void:
	position = Iso.ekran(w)
	odswiez_zestaw()
	blok_czas = blok_czas + get_process_delta_time() if blok else 0.0
	var wyb := _wybierz(czas)
	var anim: String = wyb[0]
	if not _arkusze.has(anim):
		anim = "postoj"
	var tex: Texture2D = _arkusze.get(anim)
	var d := kierunek(wyb[1])
	var n := liczba_klatek(anim)
	var f := clampi(int(wyb[2]), 0, n - 1)
	biezaca_anim = anim
	biezacy_kierunek = d
	if tex:
		sprite.texture = tex
		sprite.hframes = n
		sprite.vframes = 8
		sprite.frame = d * n + f
	sprite.flip_h = false
	sprite.modulate = Color(1.25, 1.22, 1.3, 0.92) if unik_czas > 0.0 else Color.WHITE
	_ustaw_dlon(anim, d, f)
	pochodnia.visible = pochodnia_w_rece and not martwy
	poswiata.visible = not pochodnia_w_rece
	pochodnia.position = _dlon + Vector2(0, -26)
	pochodnia.energy = 1.45 + sin(czas * 14.0) * 0.08 + cos(czas * 23.0) * 0.05
	plomien.queue_redraw()
	aura.queue_redraw()
	if tryb_3d:
		sprite.visible = false
		plomien.visible = false
		pochodnia.visible = false
		poswiata.visible = false


## Lewa dłoń z danych renderu (piksele klatki) -> układ postaci.
func _ustaw_dlon(anim: String, d: int, f: int) -> void:
	var dl: Dictionary = Dane.wyglad.get("dlon", {}).get(zestaw, {}).get(anim, {})
	var lista: Array = dl.get(str(d), [])
	if f >= lista.size():
		return
	var pkt: Array = lista[f]
	var kom: float = Dane.wyglad.get("komorka", 224)
	var stopy: float = Dane.wyglad.get("stopy_y", 176)
	var px: float = pkt[0]
	var py: float = pkt[1]
	_dlon = Vector2(px - kom * 0.5, py - stopy) * sprite.scale.x
