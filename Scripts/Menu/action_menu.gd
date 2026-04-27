class_name ActionMenu extends Control

@warning_ignore("unused_signal")
signal action_button_press(btn: String)

@onready var gameManager:GameManager = $".."

func _on_action_button_press(btn: String) -> void:
	emit_signal("action_button_press", btn)

func change_visibility(on:bool):
	visible = on
	if on:
		position = gameManager.active_unit.position
		if position.y+size.y > gameManager.map_size.y*32:
			position -= Vector2(0, size.y)
		if position.x+size.x > gameManager.map_size.x*32:
			position -= Vector2(size.x, 0)
