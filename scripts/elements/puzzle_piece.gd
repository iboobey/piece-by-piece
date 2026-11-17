extends Node2D
class_name PuzzlePiece


@onready var puzzle_piece_sprite: Sprite2D = %PuzzlePieceSprite

@onready var board_min : Vector2 = Vector2(get_viewport_rect().position.x, get_viewport_rect().position.y)
@onready var board_max : Vector2 = board_min + Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y)


@export_category("GridVariables")
@export var GRID_X : int
@export var GRID_Y : int
@export var PUZZLE_GRID : Node2D
@export var LEVEL_CONTROLLER : LevelController

@export_category("PuzzleVariables")
@export var PUZZLE_PIECE_SPRITE : CompressedTexture2D = preload("res://icon.svg")
@export var PUZZLE_MODULE : Color = Color.WHITE

@export_category("MinimapVariables")
@export var MINIMAP : CanvasLayer
@export var PUZZLE_COLOR : Color = Color.WHITE

@onready var GROUP_MANAGER = get_parent()


static var alpha_bitmap_cache : Dictionary = {}

# Position Variables
var target_position : Vector2
var position_treshold : float = 40.0

# Rotation Variables
var rotation_treshold : float = 18
var rotation_speed : float = 160.0

# Drag Variables
var is_dragging : bool = false
var drag_offset : Vector2 = Vector2.ZERO
var alpha_bitmap : BitMap = null

# Snap Variables
var is_snapped : bool = false
var locked : bool = false

# Group Variables
var is_selected : bool = false
var drag_members : Array = []



func _ready() -> void:
	set_process(false)
	
	puzzle_piece_sprite.texture = PUZZLE_PIECE_SPRITE
	puzzle_piece_sprite.modulate = PUZZLE_MODULE
	set_texture_bitmap()
	
	position_treshold = PUZZLE_GRID.GRID_SIZE / 3
	
	target_position = PUZZLE_GRID.piece_position_on_grid(GRID_X, GRID_Y)


func _process(delta: float) -> void:
	rotate_piece(delta)
	if is_dragging:
		
		var desired_position := get_global_mouse_position() + drag_offset
		var movement := desired_position - global_position
		
		for member in drag_members:
			if is_instance_valid(member):
				member.global_position = clamp_to_border(member.global_position + movement)
		
		
		MINIMAP.request_redraw()


func set_texture_bitmap():
	var texture := puzzle_piece_sprite.texture
	if texture == null:
		alpha_bitmap = null
		return
	
	var cache_key := texture.get_instance_id()
	
	if alpha_bitmap_cache.has(cache_key):
		alpha_bitmap = alpha_bitmap_cache[cache_key] as BitMap
		return
	
	var image := texture.get_image()
	
	if image == null or image.is_empty():
		alpha_bitmap = null
		return
	
	var bitmap : BitMap = BitMap.new()
	
	bitmap.create_from_image_alpha(image, 0.01)
	
	alpha_bitmap_cache[cache_key] = bitmap
	alpha_bitmap = bitmap


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
					
					if Input.is_action_pressed("select_piece"):
						GROUP_MANAGER.toggle_selection(self)
						get_viewport().set_input_as_handled()
						return
					
					is_dragging = true
					drag_members = GROUP_MANAGER.get_drag_members(self)
					drag_offset = global_position - get_global_mouse_position()
					move_to_front_z_index()
					get_viewport().set_input_as_handled()
					set_process(true)
		else:
			
			if not is_dragging:
				return
			
			
			
			var did_snap = snap()
			
			is_dragging = false
			set_process(false)
			
			if did_snap:
				GROUP_MANAGER.remove_piece_from_group(self)
			else:
				GROUP_MANAGER.try_snapping_to_a_group(self)
			
			drag_members.clear()
			get_viewport().set_input_as_handled()


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
			print("Clockwise input; speed: ", rotation_speed)
			rotate_dragged_group(rotation_speed, delta)
		elif Input.is_action_pressed("rotate_anticlockwise"):
			print("Anticlockwise input; speed: ", rotation_speed)
			rotate_dragged_group(-rotation_speed, delta)


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


func snap() -> bool:
	if not is_dragging:
		return false
	
	if not check_target():
		return false
	
	if not LEVEL_CONTROLLER.can_snap(GRID_X, GRID_Y):
		return false
	
	is_snapped = true
	lock_piece()
	z_index = -4096
	return true


func move_to_front_z_index():
	var parent := get_parent()
	
	if parent:
		parent.move_child(self, parent.get_child_count() - 1)


func clamp_to_border(pos : Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, board_min.x, board_max.x),
		clampf(pos.y, board_min.y, board_max.y))


func rotate_dragged_group(angle_degrees : float, delta):
	var members : Array = drag_members
	
	if members.is_empty():
		members = GROUP_MANAGER.get_drag_members(self)
	
	var valid_members : Array[PuzzlePiece] = []
	
	for candidate_member in members:
		
		if not is_instance_valid(candidate_member):
			continue
		if not (candidate_member is PuzzlePiece):
			continue
		
		var member := candidate_member as PuzzlePiece
		
		if not valid_members.has(member):
			valid_members.append(member)
	
	if valid_members.is_empty():
		valid_members.append(self)
	
	var group_center := Vector2.ZERO
	
	for member in valid_members:
		group_center += member.global_position
	
	group_center /= float(valid_members.size())
	
	
	var angle_step_degrees = angle_degrees * delta
	var angle_step_radians := deg_to_rad(angle_step_degrees)
	
	
	for member in valid_members:
		var offset := member.global_position - group_center
		
		member.global_position = group_center + offset.rotated(angle_step_radians)
		member.global_rotation_degrees += angle_step_degrees
