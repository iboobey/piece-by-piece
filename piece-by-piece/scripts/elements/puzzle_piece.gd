extends Node2D

@export_category("GridVariables")
@export var GRID_Y : int
@export var GRID_X : int
@export var PUZZLE_GRID : Node2D

# Position Variables
var target_position : Vector2
var position_treshold : float = 40.0

# Rotation Variables
var target_rotation : float = 0.0
var rotation_treshold : float = 15.0


func _ready() -> void:
	pass
	"await PUZZLE_GRID.grid_is_set
	target_position = PUZZLE_GRID.piece_position_on_grid(GRID_X, GRID_Y)
	print(target_position)"


#func _process(_delta: float) -> void:
#	if global_position.distance_to(target_position) >= position_treshold:
#		global_position = target_position
#		print("SNAP!")
