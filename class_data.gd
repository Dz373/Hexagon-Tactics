extends Node

var data

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	import_json_file("res://HexagonTactics - class_stats.json")

func import_json_file(path:String):
	var json_as_text = FileAccess.get_file_as_string(path)
	var json_as_dict = JSON.parse_string(json_as_text)
	if json_as_dict:
		data = json_as_dict
