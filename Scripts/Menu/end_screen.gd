extends Control

func end_game(win:bool):
	visible=true
	if win:
		$Label.text = "You Won"
	else:
		$Label.text = "You Lost"

func _on_button_button_down() -> void:
	get_tree().reload_current_scene()
