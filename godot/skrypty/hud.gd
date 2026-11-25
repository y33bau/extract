extends CanvasLayer
## HUD rajdu: życie, stamina, pancerz, mikstury, broń, minimapa, ekstrakcja, podpowiedzi, toasty.

const Ui = preload("res://skrypty/ui.gd")
const Mapgen = preload("res://skrypty/mapgen.gd")

var rajd
var info: Label
var hp_pasek: ProgressBar
var hp_txt: Label
var st_pasek: ProgressBar
var st_txt: Label
var zb_pasek: ProgressBar
var zb_txt: Label
var mikstury: Label
var bron: Label
var postawa: Label
var sprzet: Label
var minimapa: Control
var kierunki: Label
var baner: PanelContainer
var baner_txt: Label
var baner_pasek: ProgressBar
var podpowiedz: Label
var toasty: VBoxContainer
var winieta_trafienie: ColorRect
var winieta_parowanie: ColorRect


func _init() -> void:
	layer = 10


func _ready() -> void:
	var korzen := Control.new()
	korzen.set_anchors_preset(Control.PRESET_FULL_RECT)
	korzen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	korzen.theme = Ui.motyw()
	add_child(korzen)
	winieta_trafienie = _winieta(Color(0.69, 0.09, 0.11))
	korzen.add_child(winieta_trafienie)
	winieta_parowanie = _winieta(Color(0.92, 0.75, 0.3))
	korzen.add_child(winieta_parowanie)

	# lewy górny: kraina, czas, wynik
	var p1 := Ui.panel()
	p1.position = Vector2(14, 14)
	info = Ui.etykieta("", 14)
	p1.add_child(info)
	korzen.add_child(p1)

	# prawy górny: minimapa i kierunki do kręgów
	var p2 := Ui.panel()
	var v2 := VBoxContainer.new()
	minimapa = Control.new()
	minimapa.custom_minimum_size = Vector2(196, 196)
	minimapa.draw.connect(_rysuj_minimape)
	v2.add_child(minimapa)
	kierunki = Ui.etykieta("", 12, Color("34d399"))
	v2.add_child(kierunki)
	p2.add_child(v2)
	korzen.add_child(p2)
	_rog(p2, Control.PRESET_TOP_RIGHT)

	# środek góra: rytuał ekstrakcji i podpowiedź interakcji
	var srodek := VBoxContainer.new()
	srodek.custom_minimum_size = Vector2(420, 0)
	srodek.alignment = BoxContainer.ALIGNMENT_CENTER
	baner = Ui.panel()
	var vb := VBoxContainer.new()
	vb.add_child(Ui.etykieta("RYTUAŁ EKSTRAKCJI", 14, Color("6ee7b7")))
	baner_txt = Ui.etykieta("6.0 s", 22, Color.WHITE)
	baner_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(baner_txt)
	baner_pasek = Ui.pasek(Color("34d399"), 6)
	vb.add_child(baner_pasek)
	baner.add_child(vb)
	baner.visible = false
	srodek.add_child(baner)
	podpowiedz = Ui.etykieta("", 15, Color("f0cf85"))
	podpowiedz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	srodek.add_child(podpowiedz)
	toasty = VBoxContainer.new()
	toasty.alignment = BoxContainer.ALIGNMENT_CENTER
	srodek.add_child(toasty)
	korzen.add_child(srodek)
	_rog(srodek, Control.PRESET_CENTER_TOP)

	# lewy dół: życie, stamina, pancerz, mikstury
	var p3 := Ui.panel()
	p3.custom_minimum_size = Vector2(330, 0)
	var v3 := VBoxContainer.new()
	hp_txt = Ui.etykieta("", 13, Color("f87171"))
	hp_pasek = Ui.pasek(Color("b52a33"), 12)
	st_txt = Ui.etykieta("", 12, Color("6ee7b7"))
	st_pasek = Ui.pasek(Color("3fa868"), 9)
	zb_txt = Ui.etykieta("", 12, Color("7dd3fc"))
	zb_pasek = Ui.pasek(Color("38bdf8"), 6)
	mikstury = Ui.etykieta("", 13, Color("e6ba63"))
	for c in [hp_txt, hp_pasek, st_txt, st_pasek, zb_txt, zb_pasek, mikstury]:
		v3.add_child(c)
	p3.add_child(v3)
	korzen.add_child(p3)
	_rog(p3, Control.PRESET_BOTTOM_LEFT)

	# prawy dół: broń, tarcza/pochodnia, strzały, sakwa, postawa
	var p4 := Ui.panel()
	p4.custom_minimum_size = Vector2(326, 0)
	var v4 := VBoxContainer.new()
	var h4 := HBoxContainer.new()
	bron = Ui.etykieta("", 15, Color("e6ba63"))
	bron.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	postawa = Ui.etykieta("", 12)
	h4.add_child(bron)
	h4.add_child(postawa)
	v4.add_child(h4)
	sprzet = Ui.etykieta("", 12)
	v4.add_child(sprzet)
	v4.add_child(Ui.etykieta("[F/↓] pochodnia • [G/R3] zrzuć sakwę • [Tab/Back] sakwa", 11, Ui.SZARY))
	p4.add_child(v4)
	korzen.add_child(p4)
	_rog(p4, Control.PRESET_BOTTOM_RIGHT)


## Przypina kontrolkę do rogu/krawędzi ekranu; rośnie do środka ekranu.
func _rog(c: Control, preset: Control.LayoutPreset) -> void:
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 14)
	if preset in [Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT]:
		c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	if preset == Control.PRESET_CENTER_TOP:
		c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	if preset in [Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT]:
		c.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _winieta(kolor: Color) -> ColorRect:
	var c := ColorRect.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform vec4 kolor;\nuniform float sila = 0.0;\nvoid fragment(){ vec2 d = UV - vec2(0.5); float v = smoothstep(0.25, 0.75, length(d) * 1.3); COLOR = vec4(kolor.rgb, v * sila * kolor.a); }"
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("kolor", kolor)
	c.material = m
	return c


func pokaz_toast(tekst: String, rodzaj := "info") -> void:
	var kolory := {"info": Color("f0e6d8"), "warn": Color("fcd34d"), "danger": Color("fca5a5"), "success": Color("6ee7b7")}
	var pc := Ui.panel()
	var l := Ui.etykieta(tekst, 14, kolory.get(rodzaj, Color.WHITE))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(l)
	toasty.add_child(pc)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(pc, "modulate:a", 0.0, 0.3)
	tw.tween_callback(pc.queue_free)


func _process(_dt: float) -> void:
	if rajd == null or rajd.gracz == null:
		return
	var r = rajd
	var p = r.gracz
	var m := int(r.czas_pozostaly / 60.0)
	var s := int(r.czas_pozostaly) % 60
	info.text = "%s   •   ziarno %s\nCZAS %d:%02d    POKONANI %d    PAROWANIA %d" % [str(r.kraina["name"]).to_upper(), r.ziarno, m, s, r.zabici, r.parowania]
	hp_txt.text = "❤ ŻYWOTNOŚĆ  %d / %d%s" % [ceili(p.hp), int(p.hp_max), "   POPARZENIE!" if p.plonie else ""]
	hp_pasek.max_value = p.hp_max
	hp_pasek.value = p.hp
	st_txt.text = "⚡ WYTRZYMAŁOŚĆ  %d / %d" % [ceili(p.stamina), int(p.stamina_max)]
	st_pasek.max_value = p.stamina_max
	st_pasek.value = p.stamina
	var zb = p.rynsztunek["armor"]
	if zb:
		var d := Dane.p(zb["id"])
		zb_txt.text = "PANCERZ (Kl.%d)  %d / %d" % [d["tier"], ceili(zb["durability"]), d["maxDurability"]]
		zb_pasek.max_value = float(d["maxDurability"])
		zb_pasek.value = float(zb["durability"])
	else:
		zb_txt.text = "BRAK PANCERZA"
		zb_pasek.value = 0
	mikstury.text = "[1/↑] Żar %d     [2/←] Tonik %d     [3/→] Maść %d" % [r.liczba_mikstur("heal"), r.liczba_mikstur("stamina"), r.liczba_mikstur("salve")]
	bron.text = Dane.p(p.rynsztunek["weapon"]["id"])["name"] if p.rynsztunek["weapon"] else "Gołe pięści"
	var tarcza: String = Dane.p(p.rynsztunek["shield"]["id"])["name"] if p.rynsztunek["shield"] else "Brak tarczy"
	var obc: int = r.sakwa_obciazenie()
	sprzet.text = "%s   •   🏹 %d strzał\nSakwa %d/12%s" % ["🔥 Pochodnia w ręce" if p.pochodnia_w_rece else "Tarcza: " + tarcza, r.liczba_strzal(),
		p.rynsztunek["backpack"].size(), "  (odnowa staminy −%d%%)" % roundi(minf(45.0, obc * 3.5)) if obc > 0 else ""]
	if p.okno_parowania > 0.0:
		postawa.text = "PAROWANIE!"
		postawa.add_theme_color_override("font_color", Color("fbbf24"))
	elif p.blok:
		postawa.text = "BLOK"
		postawa.add_theme_color_override("font_color", Color("7dd3fc"))
	elif p.unik_czas > 0.0:
		postawa.text = "UNIK"
		postawa.add_theme_color_override("font_color", Color("6ee7b7"))
	else:
		postawa.text = "GOTOWY"
		postawa.add_theme_color_override("font_color", Ui.SZARY)
	baner.visible = r.w_ekstrakcji
	if r.w_ekstrakcji:
		baner_txt.text = "%.1f s" % r.ekstrakcja_czas
		baner_pasek.value = (1.0 - r.ekstrakcja_czas / r.CZAS_EKSTRAKCJI) * 100.0
	var linie: Array = []
	for e in r.mapa.ekstrakcje:
		linie.append("✦ %s: %dm" % [e["nazwa"], roundi(p.w.distance_to(e["w"]))])
	kierunki.text = "\n".join(linie)
	var poj = r.najblizszy_pojemnik() if not r.okno_otwarte else null
	if poj != null:
		podpowiedz.text = "[E / A] Przeszukaj: " + poj["nazwa"]
	elif not r.okno_otwarte and r.pochodnia_na_ziemi != null and not p.pochodnia_w_rece and p.w.distance_to(r.pochodnia_na_ziemi) < 1.6:
		podpowiedz.text = "[F / ↓] Podnieś pochodnię"
	else:
		podpowiedz.text = ""
	(winieta_trafienie.material as ShaderMaterial).set_shader_parameter("sila", r.blysk_trafienia)
	(winieta_parowanie.material as ShaderMaterial).set_shader_parameter("sila", r.blysk_parowania)
	minimapa.queue_redraw()


## Minimapa: obraz N×N aktualizowany tylko w polach, które zmieniły stan mgły; widać okno wokół gracza.
const OKNO_MINIMAPY := 56.0  # ile pól mapy mieści się w kwadracie minimapy
var _mm_obraz: Image
var _mm_tex: ImageTexture
var _mm_mapa = null
var _mm_numer := -1


func _kolor_pola(r, i: int) -> Color:
	var v: int = r.widok[i]
	if v == 0:
		return Color("08070a")
	var t: int = r.mapa.siatka[i]
	if t == Mapgen.K.MUR or t == Mapgen.K.FILAR:
		return Color("594e5c") if v == 2 else Color("2c262e")
	if t == Mapgen.K.KOSZ:
		return Color("b45309") if v == 2 else Color("5a2d0c")
	return Color("29242c") if v == 2 else Color("161318")


func _odswiez_obraz_minimapy(r) -> void:
	var n: int = Mapgen.ROZMIAR
	if _mm_mapa != r.mapa or _mm_obraz == null:
		_mm_mapa = r.mapa
		_mm_obraz = Image.create(n, n, false, Image.FORMAT_RGBA8)
		for i in n * n:
			_mm_obraz.set_pixel(i % n, i / n, _kolor_pola(r, i))
		_mm_tex = ImageTexture.create_from_image(_mm_obraz)
		_mm_numer = r.numer_widoku
		return
	if _mm_numer == r.numer_widoku:
		return
	_mm_numer = r.numer_widoku
	for i in r.zmienione_widoku:
		_mm_obraz.set_pixel(i % n, i / n, _kolor_pola(r, i))
	_mm_tex.update(_mm_obraz)


func _rysuj_minimape() -> void:
	var r = rajd
	if r == null:
		return
	_odswiez_obraz_minimapy(r)
	var n: float = Mapgen.ROZMIAR
	var bok := minimapa.size.x
	var okno := minf(OKNO_MINIMAPY, n)
	var s := bok / okno
	# lewy górny róg okna (w polach), przyklejony do brzegów mapy
	var o := Vector2(clampf(r.gracz.w.x - okno * 0.5, 0.0, n - okno), clampf(r.gracz.w.y - okno * 0.5, 0.0, n - okno))
	minimapa.draw_rect(Rect2(0, 0, bok, bok), Color("08070a"))
	minimapa.draw_texture_rect_region(_mm_tex, Rect2(0, 0, bok, bok), Rect2(o, Vector2(okno, okno)))
	for e in r.mapa.ekstrakcje:
		var pe: Vector2 = ((e["w"] as Vector2) - o) * s
		pe = pe.clamp(Vector2(3, 3), Vector2(bok - 3, bok - 3))
		minimapa.draw_rect(Rect2(pe.x - 2.5, pe.y - 2.5, 5, 5), Color("34d399"))
	for en in r.wrogowie:
		if r.widoczne(en.w) == 2:
			var pw: Vector2 = (en.w - o) * s
			minimapa.draw_rect(Rect2(pw.x - 1.5, pw.y - 1.5, 4 if en.boss else 3, 4 if en.boss else 3), Color("f97316") if en.boss else Color("ef4444"))
	var pg: Vector2 = (r.gracz.w - o) * s
	minimapa.draw_rect(Rect2(pg.x - 2, pg.y - 2, 4, 4), Color("e6ba63"))
	minimapa.draw_rect(Rect2(0, 0, bok, bok), Color("6b5a3e"), false, 1.0)
