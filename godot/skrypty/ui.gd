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


static func motyw() -> Theme:
	var t := Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", POPIOL)
	var panel := _styl(Color(0.1, 0.09, 0.11, 0.94), RAMA, 1, 6)
	panel.shadow_color = Color(0, 0, 0, 0.6)
	panel.shadow_size = 8
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	var n := _styl(Color("26212a"), Color("473e4b"), 1, 4)
	var h := _styl(Color("38313c"), ZLOTO, 1, 4)
	var f := _styl(Color("38313c"), Color("f0cf85"), 2, 4)
	var w := _styl(Color("1b181d"), Color("473e4b"), 1, 4)
	var dis := _styl(Color("1e1b20"), Color("2e2932"), 1, 4)
	for k in ["Button"]:
		t.set_stylebox("normal", k, n)
		t.set_stylebox("hover", k, h)
		t.set_stylebox("focus", k, f)
		t.set_stylebox("pressed", k, w)
		t.set_stylebox("disabled", k, dis)
		t.set_color("font_color", k, POPIOL)
		t.set_color("font_hover_color", k, Color.WHITE)
		t.set_color("font_focus_color", k, Color.WHITE)
		t.set_color("font_disabled_color", k, Color(0.5, 0.48, 0.46))
	t.set_stylebox("panel", "TabContainer", _styl(Color(0.08, 0.07, 0.09, 0.0), RAMA, 0, 0))
	t.set_stylebox("tab_selected", "TabContainer", _styl(Color("5c220e"), Color("d4713b"), 1, 4))
	t.set_stylebox("tab_unselected", "TabContainer", _styl(Color("1b181d"), Color("473e4b"), 1, 4))
	t.set_stylebox("tab_hovered", "TabContainer", _styl(Color("38313c"), ZLOTO, 1, 4))
	t.set_stylebox("tab_focus", "TabContainer", _styl(Color(0, 0, 0, 0), Color("f0cf85"), 2, 4))
	t.set_color("font_selected_color", "TabContainer", Color("fff3e6"))
	t.set_color("font_unselected_color", "TabContainer", POPIOL)
	t.set_stylebox("normal", "LineEdit", _styl(Color("0b090d"), Color("3c3442"), 1, 4))
	t.set_stylebox("focus", "LineEdit", _styl(Color("0b090d"), ZAR, 2, 4))
	t.set_color("font_color", "LineEdit", ZLOTO)
	t.set_stylebox("background", "ProgressBar", _styl(Color("140f12"), Color("2a2328"), 1, 2))
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


static func przycisk_akcji(tekst: String) -> Button:
	var b := Button.new()
	b.text = tekst
	b.add_theme_stylebox_override("normal", _styl(Color("6e2c14"), Color("d4713b"), 1, 4))
	b.add_theme_stylebox_override("hover", _styl(Color("8f3a1b"), Color("f09559"), 1, 4))
	b.add_theme_stylebox_override("focus", _styl(Color("8f3a1b"), Color("ffd8a8"), 2, 4))
	b.add_theme_color_override("font_color", Color("fff3e6"))
	return b


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
