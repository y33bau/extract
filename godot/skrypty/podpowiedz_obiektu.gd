extends Button
## Mała klikalna etykieta w rzucie obiektu, wspólna dla Przystani i rajdu.

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 13)
	add_theme_color_override("font_color", Color("f0cf85"))
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(0.035, 0.028, 0.018, 0.88)
	styl.border_color = Color("8d744b")
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(4)
	styl.content_margin_left = 10
	styl.content_margin_right = 10
	styl.content_margin_top = 5
	styl.content_margin_bottom = 5
	add_theme_stylebox_override("normal", styl)
	var hover: StyleBoxFlat = styl.duplicate()
	hover.border_color = Color("edc881")
	hover.bg_color = Color(0.18, 0.12, 0.045, 0.96)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	hide()


func pokaz(punkt: Vector2, nazwa: String, akcja: String, klawisz := "E", przycisk := "Y") -> void:
	text = "[%s] %s\n%s" % [przycisk if Sterowanie.pad_aktywny else klawisz, akcja, nazwa]
	reset_size()
	var ekran := get_viewport().get_visible_rect()
	position = punkt - Vector2(size.x * 0.5, size.y + 8)
	visible = ekran.encloses(Rect2(position, size))


func ukryj() -> void:
	hide()
