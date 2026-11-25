extends Node
## Mapa sterowania: klawiatura + mysz ORAZ pad (układ Xbox; na PS odpowiednio).
## Wszystkie akcje w jednym miejscu. Pad w stylu Soulsborne:
##   lewy drążek ruch, prawy drążek celowanie, RB/X atak, LB parowanie i blok, B unik,
##   Y łuk, A interakcja, krzyżak: góra/lewo/prawo mikstury, dół pochodnia,
##   R3 zrzut sakwy, Back sakwa, LB/RB w menu przełączają zakładki.

const MARTWA_STREFA := 0.25


func _ready() -> void:
	_akcja("ruch_lewo", [_klaw(KEY_A), _klaw(KEY_LEFT), _os(JOY_AXIS_LEFT_X, -1.0)])
	_akcja("ruch_prawo", [_klaw(KEY_D), _klaw(KEY_RIGHT), _os(JOY_AXIS_LEFT_X, 1.0)])
	_akcja("ruch_gora", [_klaw(KEY_W), _klaw(KEY_UP), _os(JOY_AXIS_LEFT_Y, -1.0)])
	_akcja("ruch_dol", [_klaw(KEY_S), _klaw(KEY_DOWN), _os(JOY_AXIS_LEFT_Y, 1.0)])
	_akcja("celuj_lewo", [_os(JOY_AXIS_RIGHT_X, -1.0)])
	_akcja("celuj_prawo", [_os(JOY_AXIS_RIGHT_X, 1.0)])
	_akcja("celuj_gora", [_os(JOY_AXIS_RIGHT_Y, -1.0)])
	_akcja("celuj_dol", [_os(JOY_AXIS_RIGHT_Y, 1.0)])
	_akcja("atak", [_mysz(MOUSE_BUTTON_LEFT), _pr(JOY_BUTTON_X), _pr(JOY_BUTTON_RIGHT_SHOULDER)])
	_akcja("parowanie", [_mysz(MOUSE_BUTTON_RIGHT), _pr(JOY_BUTTON_LEFT_SHOULDER)])
	_akcja("unik", [_klaw(KEY_SPACE), _pr(JOY_BUTTON_B)])
	_akcja("luk", [_klaw(KEY_Q), _pr(JOY_BUTTON_Y)])
	_akcja("interakcja", [_klaw(KEY_E), _pr(JOY_BUTTON_A)])
	_akcja("pochodnia", [_klaw(KEY_F), _pr(JOY_BUTTON_DPAD_DOWN)])
	_akcja("zrzut_sakwy", [_klaw(KEY_G), _pr(JOY_BUTTON_RIGHT_STICK)])
	_akcja("sakwa", [_klaw(KEY_TAB), _klaw(KEY_I), _pr(JOY_BUTTON_BACK)])
	_akcja("mikstura_1", [_klaw(KEY_1), _pr(JOY_BUTTON_DPAD_UP)])
	_akcja("mikstura_2", [_klaw(KEY_2), _pr(JOY_BUTTON_DPAD_LEFT)])
	_akcja("mikstura_3", [_klaw(KEY_3), _pr(JOY_BUTTON_DPAD_RIGHT)])
	# Menu: Godot 4.7 domyślnie NIE przypisuje pada do zatwierdź/anuluj (wykryte testem): A zatwierdza, B wraca
	_akcja("ui_accept", [_pr(JOY_BUTTON_A)])
	_akcja("ui_cancel", [_pr(JOY_BUTTON_B)])
	# W oknach: Y = do Relikwiarza, X = wyrzuć, LB/RB = zakładki
	_akcja("okno_relikwiarz", [_pr(JOY_BUTTON_Y)])
	_akcja("okno_wyrzuc", [_pr(JOY_BUTTON_X)])
	_akcja("zakladka_lewo", [_pr(JOY_BUTTON_LEFT_SHOULDER)])
	_akcja("zakladka_prawo", [_pr(JOY_BUTTON_RIGHT_SHOULDER)])


func _akcja(nazwa: String, zdarzenia: Array) -> void:
	if not InputMap.has_action(nazwa):
		InputMap.add_action(nazwa, MARTWA_STREFA)
	for z in zdarzenia:
		InputMap.action_add_event(nazwa, z)


func _klaw(k: Key) -> InputEventKey:
	var z := InputEventKey.new()
	z.physical_keycode = k
	return z


func _mysz(b: MouseButton) -> InputEventMouseButton:
	var z := InputEventMouseButton.new()
	z.button_index = b
	return z


func _pr(b: JoyButton) -> InputEventJoypadButton:
	var z := InputEventJoypadButton.new()
	z.button_index = b
	z.device = -1
	return z


func _os(os: JoyAxis, kierunek: float) -> InputEventJoypadMotion:
	var z := InputEventJoypadMotion.new()
	z.axis = os
	z.axis_value = kierunek
	z.device = -1
	return z
