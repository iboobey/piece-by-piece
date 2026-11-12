extends Node2D

signal grid_is_set

@export_category("GridSystem")
@export var GRID_X : int
@export var GRID_Y : int
@export var GRID_SIZE : int

@onready var icon := preload("res://icon.svg") 

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
	print(grid_x_list)
	print(grid_y_list)
	for x in range(GRID_X):
		for y in range(GRID_Y):
			var sprite = Sprite2D.new()
			sprite.texture = icon
			sprite.global_position = piece_position_on_grid(x,y)
			add_child(sprite)


func piece_position_on_grid(x,y):
	var target_position : Vector2
	target_position.x = grid_x_list[x-1]
	target_position.y = grid_y_list[y-1]
	return target_position
