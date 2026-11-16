extends Node2D
class_name GroupManager

@export var PUZZLE_GRID : PuzzleGrid

var selected_pieces : Array[PuzzlePiece] = []
var groups : Array = []
var groups_by_piece : Dictionary = {}

@onready var closeness_radius := PUZZLE_GRID.GRID_SIZE * 1.5



func toggle_selection(piece : PuzzlePiece):
	if bool(piece.get("locked")):
		return
	
	if selected_pieces.has(piece):
		selected_pieces.erase(piece)
		piece.set("is_selected", false)
	else:
		selected_pieces.append(piece)
		piece.set("is_selected", true)


func create_group_from_selection():
	var members : Array[PuzzlePiece] = []
	
	for piece in selected_pieces:
		if is_instance_valid(piece) and not bool(piece.get("locked")):
			if not members.has(piece):
				members.append(piece)
	
	if members.size() <= 1:
		return
	
	for piece in members:
		remove_piece_from_group(piece)
	
	
	var new_group: Array[PuzzlePiece] = members.duplicate()
	groups.append(new_group)
	
	for piece in new_group:
		groups_by_piece[piece.get_instance_id()] = new_group
		piece.set("is_selected", false)


func remove_piece_from_group(piece : PuzzlePiece):
	var piece_id := piece.get_instance_id()
	
	if not groups_by_piece.has(piece_id):
		return
	
	var group : Array = groups_by_piece[piece_id]
	groups_by_piece.erase(piece_id)
	groups.erase(piece)
	
	if group.size() <= 1:
		for remaining_piece in group:
			groups_by_piece.erase(remaining_piece.get_instance_id())
			
			groups.erase(group)


func get_drag_members(piece : PuzzlePiece):
	var piece_id := piece.get_instance_id()
	
	if groups_by_piece.has(piece_id):
		return groups_by_piece[piece_id]
	
	return [piece]


func ungroup_selected():
	for piece in selected_pieces.duplicate():
		remove_piece_from_group(piece)
		piece.set("is_selected", false)
	
	selected_pieces.clear()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("create_piece_group"):
		create_group_from_selection()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ungroup_selected"):
		ungroup_selected()
		get_viewport().set_input_as_handled()


func try_snapping_to_a_group(main_piece : PuzzlePiece):
	for piece in eligible_sibling_for_grouping(main_piece):
		if check_piece_rotation(main_piece, piece) and check_piece_closeness(main_piece, piece)[0]:
			piece.global_rotation = main_piece.global_rotation
			piece.global_position = main_piece.global_position + check_piece_closeness(main_piece, piece)[1]
			print("yes")


func check_piece_closeness(main_piece : PuzzlePiece, piece : PuzzlePiece):
	
	var piece_grid_target : Vector2 = Vector2(piece.GRID_X, piece.GRID_Y)
	var main_piece_grid_target : Vector2 = Vector2(main_piece.GRID_X, main_piece.GRID_Y)
	
	var directions : Dictionary = {
		piece_grid_target == main_piece_grid_target + Vector2.UP : Vector2.UP,
		piece_grid_target == main_piece_grid_target + Vector2.RIGHT : Vector2.RIGHT,
		piece_grid_target == main_piece_grid_target + Vector2.DOWN : Vector2.DOWN,
		piece_grid_target == main_piece_grid_target + Vector2.LEFT : Vector2.LEFT
	}
	
	var piece_target_direction : Vector2 = directions.get(true, Vector2.ZERO)
	
	if piece_target_direction == Vector2.ZERO:
		return [false]
	
	var excepted_offset := (piece_target_direction * float(PUZZLE_GRID.GRID_SIZE)).rotated(main_piece.global_rotation)
	
	
	return [true, excepted_offset]


func check_piece_rotation(main_piece : PuzzlePiece, piece : PuzzlePiece):
	
	var main_piece_rotation_modulated := fposmod(main_piece.global_rotation_degrees, 360)
	var piece_rotation_modulated := fposmod(piece.global_rotation_degrees, 360)
	
	var rotation_difference := absf(main_piece_rotation_modulated - piece_rotation_modulated)
	
	rotation_difference = minf(rotation_difference, 360 - rotation_difference)
	
	if rotation_difference > main_piece.rotation_treshold:
		return false
	
	return true


func eligible_sibling_for_grouping(main_piece : PuzzlePiece):
	var eligible_list : Array = []
	for piece in main_piece.get_parent().get_children():
		
		if piece == self or not (piece is PuzzlePiece):
			continue
		
		if piece.locked:
			continue
		
		if main_piece.global_position.distance_to(piece.global_position) > closeness_radius:
			continue
		
		eligible_list.append(piece)
	
	return eligible_list 
