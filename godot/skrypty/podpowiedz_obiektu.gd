extends Button
## Mała klikalna etykieta w rzucie obiektu, wspólna dla Przystani i rajdu.
const Ui = preload("res://skrypty/ui.gd")

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", Ui.czcionka(600))
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color(0.94, 0.86, 0.68, 0.78))
	add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.78, 0.96))
	add_theme_color_override("font_pressed_color", Color(1.0, 0.93, 0.78, 0.96))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	add_theme_constant_override("outline_size", 2)
	var styl := StyleBoxEmpty.new()
	styl.content_margin_left = 6
	styl.content_margin_right = 6
	styl.content_margin_top = 3
	styl.content_margin_bottom = 3
	for stan in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(stan, styl)
	hide()


func pokaz(punkt: Vector2, nazwa: String, akcja: String, klawisz := "E", przycisk := "Y") -> void:
	text = "[%s] %s\n%s" % [przycisk if Sterowanie.pad_aktywny else klawisz, akcja, nazwa]
	reset_size()
	var ekran := get_viewport().get_visible_rect()
	position = punkt - Vector2(size.x * 0.5, size.y + 8)
	visible = ekran.encloses(Rect2(position, size))


func ukryj() -> void:
	hide()
