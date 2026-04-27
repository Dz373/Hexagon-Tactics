extends Node2D

@onready var gameManager = $".."
var units: Dictionary
var unit_count=0:
	set(val):
		unit_count=val
		if gameManager.game_start && unit_count <= 0:
			gameManager.end_game(true)

var unit_resources:={}
const path = "res://Resources/UnitsEnemy"

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

func _ready() -> void:
	for child in get_children():
		units[child.cell] = child
		child.team = 2
		child.initialize()
		
		unit_count+=1

func enemy_turn():
	for child in get_children():
		if is_instance_valid(child):
			await get_tree().create_timer(0.3).timeout
			gameManager.active_unit=child
			child.auto_move()
		
	gameManager.active_unit=null
	
func clear_danger():
	for child in get_children():
		child.d_zone.clear()

func draw_danger():
	for child in get_children():
		child.draw_danger()

func get_target_units():
	return gameManager.playerManager.units
