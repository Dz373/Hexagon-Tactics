extends Control

@onready var gameManager = $"../.."
@onready var playerManager = $"../../PlayerManager"
@onready var selectMenu = $SelectUnit
@onready var optionMenu = $OptionMenu

var start_positions = []
var unit_count=0:
	set(val):
		$SelectUnit/Label.text = "%d / %d" %[val, start_positions.size()]
		unit_count=val

@warning_ignore("unused_signal")
signal unit_button_press(resource: Resource)

func _ready() -> void:
	for pos in $"../../PlayerPosition".get_children():
		start_positions.append(pos.cell)

func select_units():
	optionMenu.visible = false
	selectMenu.visible = true

func view_map():
	optionMenu.visible = false
	gameManager.view_mode = true
	$ReturnView.visible = true

func return_view():
	gameManager.view_mode=false
	optionMenu.visible = true
	$ReturnView.visible = false

func start_game():
	gameManager.start_game()

func clear_units():
	playerManager.clear_units()
	unit_count=0

func return_select():
	optionMenu.visible = true
	selectMenu.visible = false

func _on_unit_button_press(id: String) -> void:
	if unit_count >= 6:
		return
	
	playerManager.initialize_unit(id, start_positions[unit_count])
	unit_count+=1
