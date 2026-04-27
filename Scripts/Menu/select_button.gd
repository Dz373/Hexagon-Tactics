extends Button

@export var unit_id:String

func _on_button_down() -> void:
	$"../../..".emit_signal("unit_button_press", unit_id)
