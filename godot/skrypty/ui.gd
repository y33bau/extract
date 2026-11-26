extends RefCounted
## Wspólny wygląd interfejsu (mroczne panele, złote napisy) + małe fabryki kontrolek.

const ZLOTO := Color("e6ba63")
const ZAR := Color("e07a38")
const POPIOL := Color("dcd6ce")
const SZARY := Color("a8a29e")
const TLO := Color("1a171c")
const RAMA := Color("352f38")


## Czcionka oprawy walki: Cinzel (SIL OFL, `zasoby/czcionki/cinzel_OFL.txt`) o zadanej grubości (400–900).
static var _czcionki := {}
static func czcionka(waga := 700) -> Font:
	if not _czcionki.has(waga):
		var fv := FontVariation.new()
		fv.base_font = load("res://zasoby/czcionki/cinzel.ttf")
		# klucz musi być liczbowym tagiem OpenType (sprawdzone testem: klucz tekstowy nie działa)
		fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): waga}
		_czcionki[waga] = fv
	return _czcionki[waga]


## Ozdobny pasek (HP wrogów i bossa): ciemne tło, brązowa rama, wypełnienie z jaśniejszą górą,
## „cień” utraconego życia (jasny ślad, który dogania wartość z opóźnieniem).
static func rysuj_pasek(ci: CanvasItem, r: Rect2, ulamek: float, cien: float, kolor: Color, alfa := 1.0) -> void:
	var ramka := Color(0.42, 0.32, 0.2, 0.95 * alfa)
	ci.draw_rect(r.grow(2.0), Color(0.0, 0.0, 0.0, 0.55 * alfa))
	ci.draw_rect(r.grow(1.0), ramka)
	ci.draw_rect(r, Color(0.05, 0.035, 0.04, 0.92 * alfa))
	var w_cien := r.size.x * clampf(cien, 0.0, 1.0)
	var w_ul := r.size.x * clampf(ulamek, 0.0, 1.0)
	if w_cien > w_ul:
		ci.draw_rect(Rect2(r.position.x + w_ul, r.position.y, w_cien - w_ul, r.size.y), Color(1.0, 0.86, 0.6, 0.85 * alfa))
	if w_ul > 0.0:
		var k := Color(kolor, alfa)
		ci.draw_rect(Rect2(r.position, Vector2(w_ul, r.size.y)), k.darkened(0.35))
		ci.draw_rect(Rect2(r.position, Vector2(w_ul, ceilf(r.size.y * 0.55))), k)
		ci.draw_rect(Rect2(r.position, Vector2(w_ul, 1.0)), Color(k.lightened(0.45), 0.8 * alfa))


## Grafiki 9-slice (z NightBrand, wybór autora 26.11.2026): `zasoby/ui/9/`.
## m = [lewo, góra, prawo, dół] marginesy rozciągania, ex = doklejona poświata (piksele), ct = marginesy treści.
static func _tex(nazwa: String, m: Array, ex := 0, ct := [18, 8, 18, 8]) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://zasoby/ui/9/%s.png" % nazwa)
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	for b in ["left", "top", "right", "bottom"]:
		sb.set("expand_margin_" + b, ex)
	sb.content_margin_left = ct[0]
	sb.content_margin_top = ct[1]
	sb.content_margin_right = ct[2]
	sb.content_margin_bottom = ct[3]
	return sb


static var _motyw: Theme
static func motyw() -> Theme:
	if _motyw != null:
		return _motyw
	var t := Theme.new()
	t.default_font = czcionka(600)
	t.default_font_size = 16
	t.set_color("font_color", "Label", POPIOL)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	# panele: ciemne płótno w nitowanej ramie (slot NightBrand)
	# duże panele: ciemne płótno z cienką mosiężną ramą (jak panele pauzy NightBrand; tekstura nie rozciąga się w smugi)
	var panel := _styl(Color(0.045, 0.035, 0.04, 0.92), Color("7a6040"), 1, 2)
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.shadow_size = 10
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	# zwykły przycisk: ciemna tablica w mosiężnej ramie; fokus/najechanie: bordo (standard gotycki NightBrand)
	var n := _tex("btn", [26, 14, 26, 14])
	var f := _tex("btn_fokus", [26, 14, 26, 14])
	var dis := _tex("btn_wyl", [26, 14, 26, 14])
	t.set_stylebox("normal", "Button", n)
	t.set_stylebox("hover", "Button", f)
	t.set_stylebox("focus", "Button", f)
	t.set_stylebox("pressed", "Button", f)
	t.set_stylebox("hover_pressed", "Button", f)
	t.set_stylebox("disabled", "Button", dis)
	t.set_color("font_color", "Button", Color("e7dcc6"))
	t.set_color("font_hover_color", "Button", Color("fff4dc"))
	t.set_color("font_focus_color", "Button", Color("fff4dc"))
	t.set_color("font_pressed_color", "Button", Color("ffd9a0"))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.85))
	# zakładki: drewniane tablice z okuciami; wybrana żarzy się (jak pauza NightBrand)
	var tab := _tex("tab", [24, 14, 24, 14], 0, [22, 8, 22, 8])
	var tab_w := _tex("tab_wybrana", [34, 24, 34, 24], 10, [22, 8, 22, 8])
	var tab_h := _tex("tab_hover", [24, 14, 24, 14], 0, [22, 8, 22, 8])
	t.set_stylebox("tab_unselected", "TabContainer", tab)
	t.set_stylebox("tab_selected", "TabContainer", tab_w)
	t.set_stylebox("tab_hovered", "TabContainer", tab_h)
	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	t.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	t.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())
	t.set_constant("side_margin", "TabContainer", 0)
	t.set_color("font_selected_color", "TabContainer", Color("fff1d6"))
	t.set_color("font_unselected_color", "TabContainer", Color("c9b898"))
	t.set_color("font_hovered_color", "TabContainer", Color("fff1d6"))
	t.set_constant("outline_size", "TabContainer", 4)
	t.set_color("font_outline_color", "TabContainer", Color(0, 0, 0, 0.9))
	t.set_font_size("font_size", "TabContainer", 18)
	t.set_stylebox("normal", "LineEdit", _styl(Color(0.04, 0.035, 0.04, 0.9), Color("6b5636"), 1, 2))
	t.set_stylebox("focus", "LineEdit", _styl(Color(0.04, 0.035, 0.04, 0.9), ZAR, 2, 2))
	t.set_color("font_color", "LineEdit", ZLOTO)
	t.set_stylebox("background", "ProgressBar", _styl(Color("140f12"), Color("6b5636"), 1, 1))
	t.set_stylebox("panel", "TooltipPanel", _styl(Color(0.06, 0.05, 0.06, 0.96), Color("8a6d3b"), 1, 2))
	t.set_color("font_color", "TooltipLabel", POPIOL)
	# przewijanie: cienki mosiężny suwak
	var suw := _styl(Color("8a6d3b"), Color("8a6d3b"), 0, 3)
	suw.content_margin_left = 3
	suw.content_margin_right = 3
	var tor := _styl(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 3)
	tor.content_margin_left = 3
	tor.content_margin_right = 3
	for k in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", k, suw)
		t.set_stylebox("grabber_highlight", k, _styl(Color("c9a25e"), Color("c9a25e"), 0, 3))
		t.set_stylebox("grabber_pressed", k, _styl(Color("e6ba63"), Color("e6ba63"), 0, 3))
		t.set_stylebox("scroll", k, tor)
	t.set_stylebox("panel", "AcceptDialog", _styl(Color(0.06, 0.05, 0.06, 0.98), Color("8a6d3b"), 1, 2))
	_motyw = t
	return t


static func _styl(tlo: Color, rama: Color, grubosc: int, zaokr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = tlo
	s.border_color = rama
	s.set_border_width_all(grubosc)
	s.set_corner_radius_all(zaokr)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s


## Tryb autora: narzędzia autora (ziarno mapy, „Losuj”, ziarno w HUD) widać tylko z parametrem gry --autor
## (np. `Warownia_Popiolow.exe -- --autor`). Gracz ich nie widzi.
static func tryb_autora() -> bool:
	return "--autor" in OS.get_cmdline_user_args()


## Wybrana opcja (kraina, tryb kramu, kategoria): spokojny znak — jaśniejsza tablica i złoty napis, bez drugiej ramki.
## Fokus zostaje jeden: złota poświata z motywu (btn_fokus).
static func styl_wybrany() -> StyleBoxTexture:
	var sb := _tex("btn", [26, 14, 26, 14])
	sb.modulate_color = Color(1.45, 1.25, 0.95)
	return sb


## Znaczki LB / RB po bokach paska zakładek (rysowane na nakładce `c`, gdy gracz używa pada).
static func rysuj_znaczki_zakladek(c: Control, zakladki: TabContainer) -> void:
	if not Sterowanie.pad_aktywny or not zakladki.is_visible_in_tree() or zakladki.get_tab_count() == 0:
		return
	var tb := zakladki.get_tab_bar()
	var r0 := tb.get_tab_rect(0)
	var r1 := tb.get_tab_rect(zakladki.get_tab_count() - 1)
	var przes := tb.global_position - c.global_position
	for z in [["lb", r0, -1.0], ["rb", r1, 1.0]]:
		var tex: Texture2D = load("res://zasoby/ui/pad_%s.webp" % z[0])
		var r: Rect2 = z[1]
		var wys := 26.0
		var szer := wys * tex.get_size().x / maxf(1.0, tex.get_size().y)
		var y := przes.y + r.position.y + (r.size.y - wys) * 0.5
		var x := przes.x + (r.position.x - szer - 6.0 if z[2] < 0.0 else r.end.x + 6.0)
		c.draw_texture_rect(tex, Rect2(x, y, szer, wys), false)


## Główny przycisk (start wyprawy, rozbudowa, wznowienie gry): drewniana tablica z okuciami, fokus = żar.
static func przycisk_akcji(tekst: String) -> Button:
	var b := Button.new()
	b.text = tekst
	b.add_theme_stylebox_override("normal", _tex("akcja", [28, 18, 28, 18], 0, [30, 10, 30, 10]))
	var fok := _tex("akcja_fokus", [40, 30, 40, 30], 12, [30, 10, 30, 10])
	b.add_theme_stylebox_override("hover", fok)
	b.add_theme_stylebox_override("focus", fok)
	b.add_theme_stylebox_override("pressed", fok)
	b.add_theme_stylebox_override("disabled", _tex("akcja_wyl", [28, 18, 28, 18], 0, [30, 10, 30, 10]))
	b.add_theme_color_override("font_color", Color("f6ead2"))
	b.add_theme_font_override("font", czcionka(700))
	b.add_theme_font_size_override("font_size", 19)
	return b


## Ramka slotu przedmiotu: nitowana ramka + pasek koloru rzadkości po lewej.
static func styl_slotu(kolor_rzadkosci: Color, fokus := false) -> StyleBoxTexture:
	var sb := _tex("slot", [18, 18, 18, 18], 0, [14, 6, 10, 6])
	sb.modulate_color = Color(1.25, 1.1, 0.95) if fokus else Color.WHITE
	return sb


static func etykieta(tekst: String, rozmiar := 15, kolor := POPIOL) -> Label:
	var l := Label.new()
	l.text = tekst
	l.add_theme_font_size_override("font_size", rozmiar)
	l.add_theme_color_override("font_color", kolor)
	return l


static func pasek(kolor: Color, wysokosc := 10) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, wysokosc)
	var s := _styl(kolor, kolor.darkened(0.3), 0, 2)
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	p.add_theme_stylebox_override("fill", s)
	return p


static func panel() -> PanelContainer:
	return PanelContainer.new()
