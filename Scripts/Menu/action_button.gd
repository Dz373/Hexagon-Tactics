extends Button

@warning_ignore("unused_signal")
signal button_press(btn:String)


func _on_button_down() -> void:
	emit_signal("button_press", name)
