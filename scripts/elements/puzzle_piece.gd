extends Node2D

@export_category("GridVariables")
@export var GRID_X : int
@export var GRID_Y : int
@export var PUZZLE_GRID : Node2D
@export var LEVEL_CONTROLLER : LevelController

@export_category("PuzzleVariables")
@export var PUZZLE_PIECE_SPRITE : CompressedTexture2D = preload("res://icon.svg")
@export var PUZZLE_MODULE : Color = Color.WHITE

@onready var puzzle_piece_sprite: Sprite2D = %PuzzlePieceSprite


# Position Variables
var target_position : Vector2
var position_treshold : float = 40.0

# Rotation Variables
var rotation_treshold : float = 18
var rotation_speed : float = 3.0

# Drag Variables
var is_dragging : bool = false
var drag_offset : Vector2 = Vector2.ZERO
var alpha_bitmap : BitMap = null

# Snap Variables
var is_snapped : bool = false

var locked : bool = false



func _ready() -> void:
	puzzle_piece_sprite.texture = PUZZLE_PIECE_SPRITE
	puzzle_piece_sprite.modulate = PUZZLE_MODULE
	set_texture_bitmap()
	
	position_treshold = PUZZLE_GRID.GRID_SIZE / 3
	
	target_position = PUZZLE_GRID.piece_position_on_grid(GRID_X, GRID_Y)


func _process(delta: float) -> void:
	rotate_piece(delta)
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset


func set_texture_bitmap():
	if not puzzle_piece_sprite.texture:
		alpha_bitmap = null
		return
	
	var image = puzzle_piece_sprite.texture.get_image()
	if image:
		alpha_bitmap = BitMap.new()
		alpha_bitmap.create_from_image_alpha(image, 0.1)


func _unhandled_input(event: InputEvent) -> void:
	if not locked:
		grab_and_drag(event)


func grab_and_drag(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_mouse_over_opaque_pixel():
				if obscured_by_higher_piece():
					is_dragging = false
				else:
					is_dragging = true
					drag_offset = global_position - get_global_mouse_position()
					move_to_front_z_index()
		else:
			snap()
			is_dragging = false


func obscured_by_higher_piece() -> bool:
	
	var children = get_parent().get_children()
	
	if children != null:
		for piece in children:
			if piece == self:
				continue
			elif piece.is_mouse_over_opaque_pixel() and not piece.is_snapped:
				if piece.get_index() >= self.get_index():
					return true
	return false


func is_mouse_over_opaque_pixel():
	if not puzzle_piece_sprite.texture or alpha_bitmap == null:
		return false
	
	var local_pos = puzzle_piece_sprite.get_local_mouse_position()
	var texture_size = puzzle_piece_sprite.texture.get_size()
	
	if puzzle_piece_sprite.centered:
		local_pos += texture_size / 2.0
	
	
	var bitmap_size = alpha_bitmap.get_size()
	if local_pos.x < 0 or local_pos.y < 0 or local_pos.x >= bitmap_size.x or local_pos.y >= bitmap_size.y:
		return false
	
	return alpha_bitmap.get_bit(floori(local_pos.x), floori(local_pos.y))


func rotate_piece(delta):
	if not locked and is_dragging:
		if Input.is_action_pressed("rotate_clockwise"):
			rotation += rotation_speed * delta
		if Input.is_action_pressed("rotate_anticlockwise"):
			rotation -= rotation_speed * delta


func check_target():
	var rotation_modulated = fposmod(rotation_degrees, 360)
	if not locked:
		if global_position.distance_to(target_position) < position_treshold:
			if rotation_modulated < rotation_treshold or rotation_modulated > (360 - rotation_treshold):
				return true
	else: return false


func lock_piece():
	rotation_degrees = 0
	global_position = target_position
	locked = true
	is_dragging = false


func snap():
	if check_target():
		if LEVEL_CONTROLLER.can_snap(GRID_X, GRID_Y):
			is_snapped = true
			lock_piece()
			z_index = -10


func move_to_front_z_index():
	var parent := get_parent()
	
	if parent:
		parent.move_child(self, parent.get_child_count() - 1)
