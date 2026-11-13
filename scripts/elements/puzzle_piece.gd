extends Node2D

@export_category("GridVariables")
@export var GRID_Y : int
@export var GRID_X : int
@export var PUZZLE_GRID : Node2D

@export_category("PuzzleVariables")
@export var PUZZLE_PIECE_SPRITE : CompressedTexture2D = preload("res://icon.svg")
@export var PUZZLE_MODULE : Color = Color.WHITE

@onready var puzzle_piece_sprite: Sprite2D = %PuzzlePieceSprite

# Position Variables
var target_position : Vector2
var position_treshold : float = 40.0

# Rotation Variables
var rotation_treshold : float = 15.0
var rotation_speed : float = 3.0

# Drag Variables
var is_draging : bool = false
var drag_offset : Vector2 = Vector2.ZERO

var locked : bool = false


func _ready() -> void:
	puzzle_piece_sprite.texture = PUZZLE_PIECE_SPRITE
	puzzle_piece_sprite.modulate = PUZZLE_MODULE
	
	
	position_treshold = PUZZLE_GRID.GRID_SIZE / 3
	
	target_position = PUZZLE_GRID.piece_position_on_grid(GRID_X, GRID_Y)


func _unhandled_input(event: InputEvent) -> void:
	if not locked:
		grab_and_drag(event)


func grab_and_drag(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if global_position.distance_to(get_global_mouse_position()) < 50:
				is_draging = true
				drag_offset = global_position - get_global_mouse_position()
		else:
			is_draging = false


func rotate_piece(delta):
	if not locked and is_draging:
		if Input.is_action_pressed("rotate_clockwise"):
			rotation += rotation_speed * delta
		if Input.is_action_pressed("rotate_anticlockwise"):
			rotation -= rotation_speed * delta


func _process(delta: float) -> void:
	rotate_piece(delta)
	if is_draging:
		global_position = get_global_mouse_position() + drag_offset
	
	check_target()


func check_target():
	var rotation_modulated = fposmod(rotation_degrees, 360)
	if global_position.distance_to(target_position) < position_treshold:
		if rotation_modulated < rotation_treshold or rotation_degrees > (360 - rotation_treshold):
			rotation_degrees = 0
			global_position = target_position
			locked = true
			is_draging = false
