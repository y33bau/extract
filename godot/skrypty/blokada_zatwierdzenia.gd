extends Node
## Przechwytuje wyłącznie trzymane zatwierdzenie z poprzedniego ekranu.
## Nie wyłącza nawigacji, B ani pozostałych kontrolek viewportu.

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(e: InputEvent) -> void:
	if e.is_action_released("ui_accept"):
		get_viewport().set_input_as_handled()
		queue_free()
	elif e.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
