class_name GameManager extends Node2D 

@onready var cur_tile_label = $TestingUI/Point
@onready var cur_unit_label = $TestingUI/Unit
@onready var cur_state_label = $TestingUI/State
@onready var turn_label = $UI/Turn

@onready var overlay = $Tiles/Overlay
@onready var map = $Tiles
@onready var cursor = $Cursor

@onready var playerManager = $PlayerManager
@onready var player_starts = $PlayerPosition
@onready var enemyManager = $EnemyManager

@onready var actionMenu = $ActionMenu
@onready var unitMenu = $UI/UnitMenu
@onready var preMenu = $UI/PreBattleScreen
@onready var endMenu = $UI/EndScreen

@export var map_size:Vector2i

var active_unit: Unit
var active_unit_pos: Vector2i
var active_unit_range: Array[Vector2i]

enum States {IDLE, MOVE, ACTION, ATTACK, ENEMY}
var state: States = States.IDLE
var turn:=1:
	set(val):
		turn = val
		turn_label.text = "Turn: " + str(turn)

signal action_menu_press(btn:String)
signal select_attack_cell(cell:Vector2)

var view_mode:bool
var game_start:bool

func _ready() -> void:
	cursor.camera.limit_right = map_size.x *32
	cursor.camera.limit_bottom = map_size.y *32
	turn_label.visible=false
	set_process(false)

func start_game():
	turn_label.text = "Turn: " + str(turn)
	turn_label.visible=true
	preMenu.visible=false
	game_start=true

func end_game(win:bool):
	endMenu.end_game(win)

func _process(_delta: float) -> void:
	cur_tile_label.text = "Cursor: " + str(HexNavi.global_to_cell(get_local_mouse_position()))
	cur_unit_label.text = "Selected Unit: " + str(active_unit)
	cur_state_label.text = "State: " + str(state)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
	
	if event.is_action_pressed("see_range") && state == States.IDLE:
		if enemyManager.units.has(cursor.cell):
			enemyManager.units[cursor.cell].draw_danger()
	
	elif event.is_action_pressed("display_stats") && state == States.IDLE:
		if unitMenu.visible:
			unitMenu.visible = false
		elif enemyManager.units.has(cursor.cell):
			unitMenu.display_stats(enemyManager.units[cursor.cell])
		elif playerManager.units.has(cursor.cell):
			unitMenu.display_stats(playerManager.units[cursor.cell])
	
	elif view_mode:
		return
	
	elif event.is_action_pressed("confirm"):
		match state:
			States.IDLE:
				select_unit(cursor.cell)
			States.MOVE:
				unit_move(cursor.cell)
			States.ACTION:
				pass
			States.ATTACK:
				if active_unit_range.has(cursor.cell) && enemyManager.units.has(cursor.cell):
					emit_signal("select_attack_cell", cursor.cell)
	
	elif event.is_action_pressed("cancel"):
		match state:
			States.MOVE:
				deselect_unit()
			States.ACTION:
				emit_signal("action_menu_press", "cancel")
			States.ATTACK:
				emit_signal("select_attack_cell", Vector2i(-9,-9))

func is_occupied(pos:Vector2i)->bool:
	if active_unit:
		if active_unit.team==1:
			if enemyManager.units.has(pos):
				return true
		elif active_unit.team==2:
			if playerManager.units.has(pos):
				return true
	
	return false

func select_unit(cell:Vector2i):
	if playerManager.units.has(cell):
		if playerManager.units[cell].turn_end:
			return
		active_unit = playerManager.units[cell]
		active_unit.draw_overlay()
		active_unit_pos = cell
		
		state = States.MOVE

func deselect_unit():
	active_unit= null
	
	overlay.clear()
	actionMenu.change_visibility(false)
	state = States.IDLE

func unit_move(cell:Vector2i):
	if is_occupied(cell):
		return
	if playerManager.units.has(cell) && cell!=active_unit.cell:
		return
	if active_unit.mv_range.has(cell):
		active_unit.cell = cell
		overlay.clear()
		
		state = States.ACTION
		unit_action()
	
func unit_action():
	var action = true
	
	active_unit_range = HexNavi.get_cells_in_attack_range([active_unit.cell], active_unit.stats["min_range"], active_unit.stats["max_range"])
	overlay.draw_attack_range(active_unit_range)
	while action:
		actionMenu.change_visibility(true)
		var btn = await action_menu_press
		
		match btn:
			"Attack":
				action = await unit_attack()
			"Wait":
				action = false
			"cancel":
				active_unit.cell = active_unit_pos
				active_unit.draw_overlay()
				
				actionMenu.change_visibility(false)
				state = States.MOVE
				return
	
	#print(active_unit.name + " turn end")
	var temp = active_unit
	deselect_unit()
	temp.end_turn()

func _on_action_menu_button_press(btn: String) -> void:
	emit_signal("action_menu_press", btn)

func unit_attack()->bool:
	state = States.ATTACK
	actionMenu.change_visibility(false)
	
	var atk_cell = await select_attack_cell
	
	if atk_cell == Vector2i(-9,-9):
		state = States.ACTION
		return true
	else:
		active_unit.attack_unit(enemyManager.units[atk_cell])
	
	return false

func next_turn():
	state = States.ENEMY
	await enemyManager.enemy_turn()
	
	turn+=1
	
	playerManager.next_turn()
	state = States.IDLE

func unit_has_skill(skl:String)->bool:
	if skl in active_unit.stats["skills"]:
		return true
	return false
