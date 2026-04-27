extends Node2D

@onready var gameManager = $".."
var units: Dictionary
var unit_count=0:
	set(val):
		unit_count=val
		if gameManager.game_start && unit_count <= 0:
			gameManager.end_game(false)

@export var unit_scene:PackedScene

var unit_resources:={}
const path = "res://Resources/Units/"

func _init() -> void:
	var dir = DirAccess.open(path)
	if dir:
		var file_list = dir.get_files()
		for file in file_list:
			var file_path = path + "/" + file
			var resource = load(file_path.replace(".remap",""))
			
			unit_resources[resource.id] = resource
	else:
		print("An error occurred when trying to access the path.")
	
func initialize_unit(resource_id:String, pos:Vector2i):
	var unit = unit_scene.instantiate()
	
	add_child(unit)
	unit.unit_id = resource_id
	unit.cell = pos
	units[unit.cell] = unit
	unit.team = 1
	
	unit.initialize()
	unit_count+=1

func clear_units():
	for child in get_children():
		units.erase(child.cell)
		child.free()
		unit_count-=1

func all_units_end()->bool:
	for child in get_children():
		if !child.turn_end:
			return false
	return true

func next_turn():
	for child in get_children():
		child.turn_end = false

func get_target_units():
	return gameManager.enemyManager.units
