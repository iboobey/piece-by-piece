extends Node2D

signal grid_is_set

@export_category("GridSystem")
@export var GRID_X : int
@export var GRID_Y : int
@export var GRID_SIZE : int

const CORNER_GHOST_PIECE = preload("res://assets/graphics/puzzlegrid/Corner_Ghost_Piece.svg")
const GHOST_PIECE = preload("res://assets/graphics/puzzlegrid/Ghost_Piece.svg")

# Position Variables
var target_position_x : int
var target_position_y : int
var position_treshold : int

# Rotation Variables
var target_rotation : float = 0.0
var rotation_treshold : float = 15.0

var grid_x_list : Array = []
var grid_y_list : Array = []

func _ready() -> void:
	set_grid()


func set_grid():
	for index in range(GRID_X):
		grid_x_list.append(GRID_SIZE * (index + 1))
	for index in range(GRID_Y):
		grid_y_list.append(GRID_SIZE * (index + 1))
	grid_is_set.emit()
	for x in GRID_X:
		for y in GRID_Y:
			print(x," and ",y)
			draw_ghost_piece(x,y)


func piece_position_on_grid(x,y):
	var target_position : Vector2
	target_position.x = grid_x_list[x-1]
	target_position.y = grid_y_list[y-1]
	return target_position


func draw_ghost_piece(x,y):
	var sprite = Sprite2D.new()
	var scale_factor := GRID_SIZE / 64.0
	
	var is_corner : bool = (
		(x == 0 or x == (GRID_X - 1))
	and 
		(y == 0 or y == (GRID_Y - 1))
	)
	
	var corner : Dictionary = {
		Vector2(0,0) : 0,
		Vector2(GRID_X - 1, 0) : 90,
		Vector2(GRID_X - 1, GRID_Y -1) : 180,
		Vector2(0, GRID_Y - 1) : 270
	}
	
	var key := Vector2(x,y)
	
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.global_position = piece_position_on_grid(x+1,y+1)
	
	if corner.has(key):
		sprite.rotation_degrees = corner[key]
	
	if is_corner:
		sprite.texture = CORNER_GHOST_PIECE
	else:
		sprite.texture = GHOST_PIECE
	
	add_child(sprite)
