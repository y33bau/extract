extends Node
## Mapa sterowania: klawiatura + mysz ORAZ pad (Xbox/PlayStation, układ SDL).
## Akcje definiujemy w kodzie, żeby każdy agent widział je w jednym miejscu.

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
	# Atak: LPM / pad X (PS: kwadrat) lub R1
	_akcja("atak", [_mysz(MOUSE_BUTTON_LEFT), _przycisk(JOY_BUTTON_X), _przycisk(JOY_BUTTON_RIGHT_SHOULDER)])
	# Parowanie / blok: PPM / pad L1
	_akcja("parowanie", [_mysz(MOUSE_BUTTON_RIGHT), _przycisk(JOY_BUTTON_LEFT_SHOULDER)])
	# Unik: Spacja / pad B (PS: kółko)
	_akcja("unik", [_klaw(KEY_SPACE), _przycisk(JOY_BUTTON_B)])

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

func _przycisk(b: JoyButton) -> InputEventJoypadButton:
	var z := InputEventJoypadButton.new()
	z.button_index = b
	z.device = -1  # każdy pad
	return z

func _os(os: JoyAxis, kierunek: float) -> InputEventJoypadMotion:
	var z := InputEventJoypadMotion.new()
	z.axis = os
	z.axis_value = kierunek
	z.device = -1
	return z
