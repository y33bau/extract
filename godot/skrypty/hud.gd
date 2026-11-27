extends CanvasLayer
## HUD rajdu: życie, stamina, pancerz, mikstury, broń, minimapa, ekstrakcja, podpowiedzi, toasty.

const Ui = preload("res://skrypty/ui.gd")
const Mapgen = preload("res://skrypty/mapgen.gd")
const PodpowiedzObiektu = preload("res://skrypty/podpowiedz_obiektu.gd")

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
var podpowiedz_obiektu: PodpowiedzObiektu
var _cel_podpowiedzi = null
var _podpowiedz_pochodni := false
var toasty: VBoxContainer
var winieta_trafienie: ColorRect
var winieta_parowanie: ColorRect
var pasek_bossa: Control
var zegar: Control
var kula_hp: Control
var kula_st: Control
var pasek: Control
var stan_sakwy: Label
const ROZMIAR_RAMY := 156.0     # autor 26.11: mniejszy HUD (było 210)
const PROMIEN_OKNA := 0.39       # okrągłe okno w ramie minimapy (część boku)
const ROZMIAR_KULI := 124.0     # autor 26.11: mniejszy HUD (było 168)
const SKALA_PASKA := 0.62        # autor 26.11: mniejszy HUD (było 0.82)
const ROZMIAR_ZEGARA := 72.0  # autor 26.11: mniejszy HUD (było 92)
const SKALA_TEKSTU := SKALA_PASKA / 0.82  # czcionki paska rosną/maleją razem z nim
## Sloty paska akcji (piksele grafiki pasek_akcji.webp 724x241): środki x, środek y, rozmiar.
const SLOTY_X := [72.5, 128.5, 182.5, 236.0, 290.0, 434.0, 488.5, 543.5, 597.5, 652.5]
const SLOT_Y := 113.0
const SLOT_ROZ := Vector2(46, 56)
var _tex_kula_zycia: Texture2D = preload("res://zasoby/ui/kula_zycia.webp")
var _tex_kula_many: Texture2D = preload("res://zasoby/ui/kula_many.webp")
var _tex_kula_pusta: Texture2D = preload("res://zasoby/ui/kula_pusta.webp")
var _tex_pasek: Texture2D = preload("res://zasoby/ui/pasek_akcji.webp")
var _tex_zegar: Texture2D = preload("res://zasoby/ui/kula_drewno.webp")
var _ikony_hud := {}
var _hp_cien := -1.0
var _boss = null
var _boss_alfa := 0.0


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
	# dół środek: pasek bossa (jak w Soulsach) — imię, życie z cieniem utraty, postura
	# pasek bossa u dołu nad paskiem akcji, gruby, z jasną nazwą (wzór soulsów / NightBrand)
	pasek_bossa = Control.new()
	pasek_bossa.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pasek_bossa.offset_left = -300.0
	pasek_bossa.offset_right = 300.0
	pasek_bossa.offset_bottom = -(241.0 * SKALA_PASKA + 30.0)
	pasek_bossa.offset_top = pasek_bossa.offset_bottom - 58.0
	pasek_bossa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pasek_bossa.draw.connect(_rysuj_pasek_bossa)
	korzen.add_child(pasek_bossa)

	# lewy górny: kraina i wynik (bez panelu, cień pod tekstem)
	info = Ui.etykieta("", 13, Color("e9dcc3"))
	info.add_theme_constant_override("outline_size", 6)
	info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	korzen.add_child(info)
	_rog(info, Control.PRESET_TOP_LEFT)

	# prawy górny: minimapa w drewnianej ramie NightBrand (okrągłe okno) + kierunki do kręgów
	var v2 := VBoxContainer.new()
	var ramka := Control.new()
	ramka.custom_minimum_size = Vector2(ROZMIAR_RAMY, ROZMIAR_RAMY)
	minimapa = Control.new()
	minimapa.position = Vector2(ROZMIAR_RAMY, ROZMIAR_RAMY) * (0.5 - PROMIEN_OKNA)
	minimapa.size = Vector2(ROZMIAR_RAMY, ROZMIAR_RAMY) * PROMIEN_OKNA * 2.0
	minimapa.draw.connect(_rysuj_minimape)
	var maska := ShaderMaterial.new()
	maska.shader = Shader.new()
	maska.shader.code = """shader_type canvas_item;
uniform float bok = 100.0;
varying vec2 lok;
void vertex() { lok = VERTEX; }
void fragment() {
	float r = length(lok - vec2(bok * 0.5)) / (bok * 0.5);
	COLOR.a *= 1.0 - smoothstep(0.96, 1.0, r);
}"""
	maska.set_shader_parameter("bok", minimapa.size.x)
	minimapa.material = maska
	ramka.add_child(minimapa)
	var rama_tex := TextureRect.new()
	rama_tex.texture = load("res://zasoby/ui/rama_minimapy.webp")
	rama_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rama_tex.size = Vector2(ROZMIAR_RAMY, ROZMIAR_RAMY)
	rama_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ramka.add_child(rama_tex)
	v2.add_child(ramka)
	kierunki = Ui.etykieta("", 12, Color("8ee0b8"))
	kierunki.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kierunki.add_theme_constant_override("outline_size", 5)
	kierunki.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	v2.add_child(kierunki)
	korzen.add_child(v2)
	_rog(v2, Control.PRESET_TOP_RIGHT)

	# środek góra: zegar wyprawy w drewnianym kole; pod nim ekstrakcja, podpowiedź, komunikaty
	var srodek := VBoxContainer.new()
	srodek.custom_minimum_size = Vector2(420, 0)
	srodek.alignment = BoxContainer.ALIGNMENT_CENTER
	srodek.add_theme_constant_override("separation", 4)
	zegar = Control.new()
	zegar.custom_minimum_size = Vector2(420, ROZMIAR_ZEGARA)
	zegar.draw.connect(_rysuj_zegar)
	srodek.add_child(zegar)
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
	podpowiedz = Ui.etykieta("", 16, Color("f0cf85"))
	podpowiedz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	podpowiedz.add_theme_constant_override("outline_size", 6)
	podpowiedz.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	srodek.add_child(podpowiedz)
	podpowiedz.visible = false
	podpowiedz_obiektu = PodpowiedzObiektu.new()
	add_child(podpowiedz_obiektu)
	podpowiedz_obiektu.pressed.connect(func():
		if _cel_podpowiedzi != null:
			rajd.przeszukaj(_cel_podpowiedzi)
		elif _podpowiedz_pochodni and not rajd.okno_otwarte:
			rajd.przerwij_klik_ataku()
			rajd.pochodnia())
	toasty = VBoxContainer.new()
	toasty.alignment = BoxContainer.ALIGNMENT_CENTER
	srodek.add_child(toasty)
	korzen.add_child(srodek)
	_rog(srodek, Control.PRESET_CENTER_TOP)

	# dół: kula życia (lewo), kula wytrzymałości (prawo), pasek akcji (środek) — jak HUD NightBrand
	kula_hp = Control.new()
	kula_hp.custom_minimum_size = Vector2(ROZMIAR_KULI, ROZMIAR_KULI)
	kula_hp.draw.connect(func(): _rysuj_kule(kula_hp, _tex_kula_zycia, "hp"))
	korzen.add_child(kula_hp)
	_rog(kula_hp, Control.PRESET_BOTTOM_LEFT)
	kula_st = Control.new()
	kula_st.custom_minimum_size = Vector2(ROZMIAR_KULI, ROZMIAR_KULI)
	kula_st.draw.connect(func(): _rysuj_kule(kula_st, _tex_kula_many, "st"))
	korzen.add_child(kula_st)
	_rog(kula_st, Control.PRESET_BOTTOM_RIGHT)
	pasek = Control.new()
	pasek.custom_minimum_size = Vector2(724, 241) * SKALA_PASKA
	pasek.draw.connect(_rysuj_pasek_akcji)
	korzen.add_child(pasek)
	pasek.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 0)
	pasek.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pasek.grow_vertical = Control.GROW_DIRECTION_BEGIN
	stan_sakwy = Ui.etykieta("", 12, Color("f0b35a"))
	stan_sakwy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stan_sakwy.add_theme_constant_override("outline_size", 5)
	stan_sakwy.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	korzen.add_child(stan_sakwy)
	stan_sakwy.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 0)
	stan_sakwy.grow_horizontal = Control.GROW_DIRECTION_BOTH
	stan_sakwy.offset_bottom = -SKALA_PASKA * 241.0 + 18.0
	stan_sakwy.offset_top = stan_sakwy.offset_bottom - 22.0


## Przypina kontrolkę do rogu/krawędzi ekranu; rośnie do środka ekranu.
func _rog(c: Control, preset: Control.LayoutPreset) -> void:
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 10)
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
	# tylko krawędzie ekranu i krótko (nie zalewa obrazu walki)
	sh.code = "shader_type canvas_item;\nuniform vec4 kolor;\nuniform float sila = 0.0;\nvoid fragment(){ vec2 d = (UV - vec2(0.5)) * vec2(1.25, 1.0); float v = smoothstep(0.42, 0.78, length(d)); COLOR = vec4(kolor.rgb, v * v * sila * sila * 0.75 * kolor.a); }"
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("kolor", kolor)
	c.material = m
	return c


## Tytuł obszaru: duży napis na środku, pojawia się i gaśnie (wejście do nowej komnaty).
var tytul_obszaru: VBoxContainer
var _tytul_tw: Tween


func pokaz_obszar(nazwa: String, opis: String) -> void:
	if tytul_obszaru == null:
		tytul_obszaru = VBoxContainer.new()
		tytul_obszaru.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := Ui.etykieta("", 30, Color("e6ba63"))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var o := Ui.etykieta("", 14, Color("c8bba8"))
		o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tytul_obszaru.add_child(t)
		tytul_obszaru.add_child(o)
		add_child(tytul_obszaru)
		tytul_obszaru.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		tytul_obszaru.position.y -= 170
	(tytul_obszaru.get_child(0) as Label).text = nazwa.to_upper()
	(tytul_obszaru.get_child(1) as Label).text = opis
	tytul_obszaru.reset_size()
	tytul_obszaru.position.x = (get_viewport().get_visible_rect().size.x - tytul_obszaru.size.x) * 0.5
	if _tytul_tw:
		_tytul_tw.kill()
	tytul_obszaru.modulate.a = 0.0
	tytul_obszaru.visible = true
	_tytul_tw = create_tween()
	_tytul_tw.tween_property(tytul_obszaru, "modulate:a", 1.0, 0.5)
	_tytul_tw.tween_interval(2.2)
	_tytul_tw.tween_property(tytul_obszaru, "modulate:a", 0.0, 0.9)


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
	# Pokonani i parowania: w pauzie i na ekranie wyniku; ziarno tylko w trybie autora
	info.text = str(r.kraina["name"]).to_upper() + ("\nziarno %s" % r.ziarno if Ui.tryb_autora() else "")
	if _hp_cien < 0.0 or p.hp > _hp_cien:
		_hp_cien = p.hp
	else:
		_hp_cien = move_toward(_hp_cien, p.hp, p.hp_max * 0.6 * _dt)
	var obc: int = r.sakwa_obciazenie()
	stan_sakwy.text = "Ciężka sakwa: odnowa staminy −%d%%" % roundi(minf(45.0, obc * 3.5)) if obc > 0 else ""
	kula_hp.queue_redraw()
	kula_st.queue_redraw()
	pasek.queue_redraw()
	zegar.queue_redraw()
	baner.visible = r.w_ekstrakcji
	if r.w_ekstrakcji:
		baner_txt.text = "%.1f s" % maxf(0.0, r.ekstrakcja_czas)  # bez „−0,0 s”
		baner_pasek.value = (1.0 - r.ekstrakcja_czas / r.CZAS_EKSTRAKCJI) * 100.0
	var linie: Array = []
	for e in r.mapa.ekstrakcje:
		linie.append("%s: %d m" % [e["nazwa"], roundi(p.w.distance_to(e["w"]))])
	kierunki.text = "\n".join(linie)
	podpowiedz.text = ""
	_cel_podpowiedzi = null
	_podpowiedz_pochodni = false
	var poj = r.cel_interakcji() if not r.okno_otwarte and not r.zakonczony else null
	if poj != null:
		_cel_podpowiedzi = poj
		podpowiedz_obiektu.pokaz(r.punkt_obiektu(poj, 0.75 if not r.zwloki.has(poj) else 0.45), str(poj["nazwa"]), "Przeszukaj")
	elif not r.okno_otwarte and not r.zakonczony and r.pochodnia_na_ziemi != null and not p.pochodnia_w_rece and p.w.distance_to(r.pochodnia_na_ziemi) < 1.6:
		_podpowiedz_pochodni = true
		podpowiedz_obiektu.pokaz(r.punkt_obiektu({"w": r.pochodnia_na_ziemi}, 0.4), "Pochodnia", "Podnieś", "F", "krzyżak dół")
	else:
		podpowiedz_obiektu.hide()
	(winieta_trafienie.material as ShaderMaterial).set_shader_parameter("sila", r.blysk_trafienia)
	(winieta_parowanie.material as ShaderMaterial).set_shader_parameter("sila", r.blysk_parowania)
	minimapa.queue_redraw()
	_aktualizuj_bossa(_dt)


func _aktualizuj_bossa(dt: float) -> void:
	var cel = null
	for en in rajd.wrogowie:
		if en.boss and en.hp > 0.0 and (en.stan == "walka" or en.hp < en.hp_max):
			cel = en
	if cel != null:
		_boss = cel
	elif _boss != null and (not is_instance_valid(_boss) or _boss.hp <= 0.0 or not rajd.wrogowie.has(_boss)):
		_boss = null if _boss_alfa <= 0.01 else _boss
	_boss_alfa = move_toward(_boss_alfa, 1.0 if cel != null else 0.0, dt * 3.0)
	pasek_bossa.visible = _boss_alfa > 0.01 and _boss != null and is_instance_valid(_boss)
	if pasek_bossa.visible:
		pasek_bossa.queue_redraw()


func _rysuj_pasek_bossa() -> void:
	var b = _boss
	if b == null or not is_instance_valid(b):
		return
	var a := _boss_alfa
	var f := Ui.czcionka(700)
	var szer := pasek_bossa.size.x
	var nazwa := str(b.nazwa).to_upper()
	pasek_bossa.draw_string_outline(f, Vector2(0, 20), nazwa, HORIZONTAL_ALIGNMENT_CENTER, szer, 22, 6, Color(0, 0, 0, 0.95 * a))
	pasek_bossa.draw_string(f, Vector2(0, 20), nazwa, HORIZONTAL_ALIGNMENT_CENTER, szer, 22, Color(Ui.M_JASNY, a))
	# rama paska: ciemne tło, mosiężny brzeg, gruby pasek życia (16 px) z cieniem utraty
	var r := Rect2(0, 28, szer, 16)
	pasek_bossa.draw_rect(r.grow(4.0), Color(0.02, 0.015, 0.015, 0.75 * a))
	pasek_bossa.draw_rect(r.grow(3.0), Color(Ui.M_BELKA_RAMA, a), false, 1.0)
	Ui.rysuj_pasek(pasek_bossa, r, maxf(0.0, b.hp) / b.hp_max, maxf(0.0, b.hp_cien) / b.hp_max, Color("b8321c"), a)
	var zuzyte := 1.0 - clampf(b.postura / b.postura_max, 0.0, 1.0)
	if zuzyte > 0.01 and b.ogluszenie <= 0.0:
		var sz := szer * 0.6 * zuzyte
		var kp := Color("f2c14e").lerp(Color("ff5a1f"), smoothstep(0.5, 1.0, zuzyte))
		pasek_bossa.draw_rect(Rect2(szer * 0.2, 51, szer * 0.6, 4), Color(0.05, 0.035, 0.04, 0.8 * a))
		pasek_bossa.draw_rect(Rect2(szer / 2.0 - sz / 2.0, 51, sz, 4), Color(kp, a))


# ---------------------------------------------------------------- HUD NightBrand: kule, pasek akcji, zegar
## Kula: ciemne szkło w obręczy, kolorowe szkło odsłaniane od dołu wg wartości; liczby na środku.
func _rysuj_kule(c: Control, tex: Texture2D, co: String) -> void:
	if rajd == null or rajd.gracz == null:
		return
	var p = rajd.gracz
	var b := c.size.x
	var wart: float = p.hp if co == "hp" else p.stamina
	var maks: float = p.hp_max if co == "hp" else p.stamina_max
	var u := clampf(wart / maxf(maks, 1.0), 0.0, 1.0)
	c.draw_texture_rect(_tex_kula_pusta, Rect2(0, 0, b, b), false)
	# pełne szkło: obszar szkła w grafice ~ od 14% do 86% wysokości
	var gora := 0.14 + (1.0 - u) * 0.72
	var ts := tex.get_size()
	if u > 0.0:
		c.draw_texture_rect_region(tex, Rect2(0, b * gora, b, b * (1.0 - gora)), Rect2(0, ts.y * gora, ts.x, ts.y * (1.0 - gora)))
	if co == "hp" and _hp_cien > wart:
		# jasny ślad utraconego życia
		var g2 := 0.14 + (1.0 - clampf(_hp_cien / maks, 0.0, 1.0)) * 0.72
		c.draw_rect(Rect2(b * 0.2, b * g2, b * 0.6, b * (gora - g2)), Color(1.0, 0.85, 0.6, 0.35))
	if co == "hp" and u < 0.3:
		var puls := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 7.0)
		c.draw_circle(Vector2(b, b) * 0.5, b * 0.36, Color(1.0, 0.1, 0.05, 0.12 * puls))
	var f := Ui.czcionka(700)
	var txt := "%d / %d" % [ceili(wart), int(maks)]
	c.draw_string_outline(f, Vector2(0, b * 0.53), txt, HORIZONTAL_ALIGNMENT_CENTER, b, roundi(b * 0.113), 5, Color(0, 0, 0, 0.9))
	c.draw_string(f, Vector2(0, b * 0.53), txt, HORIZONTAL_ALIGNMENT_CENTER, b, roundi(b * 0.113), Color("f6ead2"))
	var podpis := "ŻYCIE" if co == "hp" else "WYTRZYMAŁOŚĆ"
	if co == "hp" and p.plonie:
		podpis = "PŁONIESZ!"
	c.draw_string_outline(f, Vector2(0, b * 0.66), podpis, HORIZONTAL_ALIGNMENT_CENTER, b, maxi(8, roundi(b * 0.066)), 3, Color(0, 0, 0, 0.9))
	c.draw_string(f, Vector2(0, b * 0.66), podpis, HORIZONTAL_ALIGNMENT_CENTER, b, maxi(8, roundi(b * 0.066)), Color("ffb070") if p.plonie and co == "hp" else Color("d8c8aa"))


func _ikona_hud(n: String) -> Texture2D:
	if not _ikony_hud.has(n):
		_ikony_hud[n] = load("res://zasoby/ui/hud/%s.webp" % n)
	return _ikony_hud[n]


func _pad_tex(n: String) -> Texture2D:
	if not _ikony_hud.has("pad_" + n):
		_ikony_hud["pad_" + n] = load("res://zasoby/ui/pad_%s.webp" % n)
	return _ikony_hud["pad_" + n]


## Pasek akcji: mikstury 1-3, pochodnia, łuk | medalion postawy | broń, tarcza, pancerz, sakwa, relikwiarz.
## Podpowiedzi: klawisze przy myszy/klawiaturze, ikony pada przy grze padem (rajd.mysz_aktywna).
func _rysuj_pasek_akcji() -> void:
	if rajd == null or rajd.gracz == null:
		return
	var r = rajd
	var p = r.gracz
	var k := SKALA_PASKA
	pasek.draw_texture_rect(_tex_pasek, Rect2(Vector2.ZERO, Vector2(724, 241) * k), false)
	var f := Ui.czcionka(700)
	var pad: bool = not r.mysz_aktywna
	var z = p.rynsztunek
	var wpisy := [
		["ikona:ember_flask", r.liczba_mikstur("heal"), "1", "krzyzak"],
		["ikona:stamina_tonic", r.liczba_mikstur("stamina"), "2", "krzyzak"],
		["ikona:ash_salve", r.liczba_mikstur("salve"), "3", "krzyzak"],
		["hud:pochodnia", -1, "F", "krzyzak"],
		["ikona:" + (str(z["bow"]["id"]) if z["bow"] else ""), r.liczba_strzal(), "Q", "b"],
		["ikona:" + (str(z["weapon"]["id"]) if z["weapon"] else ""), -1, "LPM", "x"],
		["ikona:" + (str(z["shield"]["id"]) if z["shield"] else ""), -1, "PPM", "lb"],
		["ikona:ulepszenie_ochrona_common", z.get("enhancements", []).size(), "", ""],
		["hud:sakwa", z["backpack"].size(), "Tab", "widok"],
		["hud:relikwiarz", z["reliquary"].size(), "", ""],
	]
	for i in wpisy.size():
		var w: Array = wpisy[i]
		var srodek := Vector2(SLOTY_X[i], SLOT_Y) * k
		var roz := SLOT_ROZ * k
		var tex: Texture2D = null
		var nazwa: String = w[0]
		if nazwa.begins_with("ikona:") and nazwa.length() > 6:
			tex = Dane.ikona(nazwa.substr(6))
		elif nazwa.begins_with("hud:"):
			tex = _ikona_hud(nazwa.substr(4))
		var ile: int = w[1]
		var pusty := tex == null or (ile == 0 and i < 3) or (i == 6 and Dane.dwureczna(z))
		# podświetlenia stanu: pochodnia w ręce, tarcza przy bloku/parowaniu
		if (i == 3 and p.pochodnia_w_rece) or (i == 6 and p.blok):
			pasek.draw_rect(Rect2(srodek - roz * 0.5, roz), Color(1.0, 0.6, 0.2, 0.22))
		if tex:
			var bok := minf(roz.x, roz.y) * 0.82
			var mod := Color(1, 1, 1, 0.3) if pusty else Color.WHITE
			pasek.draw_texture_rect(tex, Rect2(srodek - Vector2(bok, bok) * 0.5, Vector2(bok, bok)), false, mod)
		if ile > 0:  # pusty slot bez licznika „0”
			var t := str(ile)
			pasek.draw_string_outline(f, srodek + Vector2(-roz.x * 0.5, roz.y * 0.48), t, HORIZONTAL_ALIGNMENT_RIGHT, roz.x - 3, roundi(13 * SKALA_TEKSTU), 3, Color(0, 0, 0, 0.95))
			pasek.draw_string(f, srodek + Vector2(-roz.x * 0.5, roz.y * 0.48), t, HORIZONTAL_ALIGNMENT_RIGHT, roz.x - 3, roundi(13 * SKALA_TEKSTU), Color("f6ead2") if not pusty else Color(0.6, 0.55, 0.5))
		# podpowiedź klawisza / przycisku pada nad slotem
		if pad and str(w[3]) != "":
			var pt := _pad_tex(str(w[3]))
			var pb := Vector2(20, 20) * SKALA_TEKSTU * (1.4 if str(w[3]) in ["lb", "rb"] else 1.0)
			pb.x = pb.y * (pt.get_size().x / pt.get_size().y)
			pasek.draw_texture_rect(pt, Rect2(srodek + Vector2(-pb.x * 0.5, -roz.y * 0.5 - pb.y - 1), pb), false)
		elif str(w[2]) != "":
			pasek.draw_string_outline(f, srodek + Vector2(-roz.x, -roz.y * 0.5 - 4), w[2], HORIZONTAL_ALIGNMENT_CENTER, roz.x * 2.0, roundi(12 * SKALA_TEKSTU), 3, Color(0, 0, 0, 0.95))
			pasek.draw_string(f, srodek + Vector2(-roz.x, -roz.y * 0.5 - 4), w[2], HORIZONTAL_ALIGNMENT_CENTER, roz.x * 2.0, roundi(12 * SKALA_TEKSTU), Color("e6ba63"))
	# medalion postawy (środek) + tabliczka z nazwą stanu
	var sp := stan_postawy()
	var stan: String = sp[0]
	var napis: String = sp[1]
	var kol: Color = sp[2]
	var m := Vector2(361.5, 113.0) * k
	var mb := 52.0 * k
	if stan != "gotowy":
		pasek.draw_circle(m, mb * 0.75, Color(kol, 0.25))
	pasek.draw_texture_rect(_ikona_hud("postawa_" + stan), Rect2(m - Vector2(mb, mb) * 0.5, Vector2(mb, mb)), false, Color(1, 1, 1, 0.95))
	pasek.draw_string_outline(f, Vector2(0, 56 * k), napis, HORIZONTAL_ALIGNMENT_CENTER, 724 * k, roundi(13 * SKALA_TEKSTU), 3, Color(0, 0, 0, 0.95))
	pasek.draw_string(f, Vector2(0, 56 * k), napis, HORIZONTAL_ALIGNMENT_CENTER, 724 * k, roundi(13 * SKALA_TEKSTU), kol)
	# Trzy miejsca na dodatki stałej zbroi, kolor oznacza jakość.
	for i in 3:
		var kolor := Color("49433a")
		if i < z.get("enhancements", []).size():
			var def: Dictionary = Dane.p(z["enhancements"][i]["id"])
			kolor = Dane.KOLORY_RZADKOSCI.get(def.get("rarity"), Color.GRAY)
		pasek.draw_rect(Rect2((294 + i * 48) * k, 171 * k, 38 * k, 5 * k), kolor)



## Stan na medalionie paska akcji: [ikona, napis, kolor].
func stan_postawy() -> Array:
	var p = rajd.gracz
	if p.okno_parowania > 0.0:
		return ["parowanie", "PAROWANIE!", Color("ffd166")]
	if p.ladowanie >= rajd.PROG_MOCNEGO:
		return ["ladowanie", "MOCNY CIOS", Color("ff9a3c")]
	if p.blok:
		return ["blok", "BLOK", Color("9fd3f2")]
	if p.unik_czas > 0.0:
		return ["unik", "UNIK", Color("8fe3b8")]
	if p.pochodnia_w_rece:
		return ["gotowy", "POCHODNIA W RĘCE", Color("f0b35a")]
	return ["gotowy", "GOTOWY", Color("d8c8aa")]


## Zegar wyprawy: drewniane koło z pozostałym czasem; ostatnia minuta pulsuje czerwienią.
func _rysuj_zegar() -> void:
	if rajd == null:
		return
	var b := ROZMIAR_ZEGARA
	var x := (zegar.size.x - b) * 0.5
	zegar.draw_texture_rect(_tex_zegar, Rect2(x, 0, b, b), false)
	var f := Ui.czcionka(700)
	var t: float = rajd.czas_pozostaly
	var kol := Color("f6ead2")
	if t < 60.0:
		kol = Color(1.0, 0.45 + 0.3 * sin(Time.get_ticks_msec() / 1000.0 * 6.0), 0.35)
	var txt := "%d:%02d" % [int(t / 60.0), int(t) % 60]
	zegar.draw_string_outline(f, Vector2(x, b * 0.6), txt, HORIZONTAL_ALIGNMENT_CENTER, b, 17, 5, Color(0, 0, 0, 0.9))
	zegar.draw_string(f, Vector2(x, b * 0.6), txt, HORIZONTAL_ALIGNMENT_CENTER, b, 17, kol)
	zegar.draw_string_outline(f, Vector2(x, b * 0.36), "DO ZMROKU", HORIZONTAL_ALIGNMENT_CENTER, b, 8, 3, Color(0, 0, 0, 0.9))
	zegar.draw_string(f, Vector2(x, b * 0.36), "DO ZMROKU", HORIZONTAL_ALIGNMENT_CENTER, b, 8, Color("c9b898"))


## Minimapa: obraz N×N aktualizowany tylko w polach, które zmieniły stan mgły; widać okno wokół gracza.
const OKNO_MINIMAPY := 56.0  # ile pól mapy mieści się w kwadracie minimapy
var _mm_obraz: Image
var _mm_tex: ImageTexture
var _mm_mapa = null
var _mm_numer := -1


## Kolory minimapy (autor 26.11 wg oceny NightBrand: „prawie pusta i ciemna”): jaśniej, ciepło, czytelne przejścia.
func _kolor_pola(r, i: int) -> Color:
	var v: int = r.widok[i]
	if v == 0:
		return Color("08070a")
	var t: int = r.mapa.siatka[i]
	var las: bool = str(r.kraina.get("typ", "")) == "las"
	var k: Color
	if t == Mapgen.K.MUR or t == Mapgen.K.FILAR:
		k = Color("2f4a2a") if las else Color("8a7a66")
	elif t == Mapgen.K.KOSZ:
		k = Color("e07a38")
	elif t == Mapgen.K.WODA:
		k = Color("2f5e6e")
	elif t == Mapgen.K.EKSTRAKCJA:
		k = Color("34d399")
	elif t == Mapgen.K.SCIEZKA:
		k = Color("9a8466") if las else Color("6a5e52")
	else:
		k = Color("5a5046") if not las else Color("4a5a3c")
	return k if v == 2 else k.darkened(0.5)


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
	# wyjścia: znacznik w oknie, a poza nim zielona strzałka na brzegu okrągłego okna (kierunek do kręgu)
	var c := Vector2(bok, bok) * 0.5
	var r_okna := bok * 0.43
	for e in r.mapa.ekstrakcje:
		var pe: Vector2 = ((e["w"] as Vector2) - o) * s
		var rel := pe - c
		if rel.length() <= r_okna:
			var romb := PackedVector2Array([pe + Vector2(0, -5), pe + Vector2(5, 0), pe + Vector2(0, 5), pe + Vector2(-5, 0)])
			minimapa.draw_colored_polygon(romb, Color("34d399"))
			minimapa.draw_polyline(romb + PackedVector2Array([romb[0]]), Color(0, 0, 0, 0.8), 1.0)
		else:
			var kier := rel.normalized()
			var czub := c + kier * (r_okna + 2.0)
			var bok_k := Vector2(-kier.y, kier.x)
			var strz := PackedVector2Array([czub, czub - kier * 9.0 + bok_k * 5.0, czub - kier * 9.0 - bok_k * 5.0])
			minimapa.draw_colored_polygon(strz, Color("34d399"))
			minimapa.draw_polyline(strz + PackedVector2Array([strz[0]]), Color(0, 0, 0, 0.85), 1.0)
	for en in r.wrogowie:
		if r.widoczne(en.w) == 2:
			var pw: Vector2 = (en.w - o) * s
			minimapa.draw_rect(Rect2(pw.x - 1.5, pw.y - 1.5, 4 if en.boss else 3, 4 if en.boss else 3), Color("f97316") if en.boss else Color("ef4444"))
	var pg: Vector2 = (r.gracz.w - o) * s
	minimapa.draw_rect(Rect2(pg.x - 2, pg.y - 2, 4, 4), Color("e6ba63"))
