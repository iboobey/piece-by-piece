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


func merge_pieces(piece_a : PuzzlePiece, piece_b : PuzzlePiece):
	if not is_instance_valid(piece_a) or not is_instance_valid(piece_b):
		return
	
	if piece_a == piece_b:
		return
	
	var key_a := piece_a.get_instance_id()
	var key_b := piece_b.get_instance_id()
	
	var group_a : Array = groups_by_piece.get(key_a, [])
	var group_b : Array = groups_by_piece.get(key_b, [])
	
	if group_a.is_empty() and group_b.is_empty():
		var new_group : Array[PuzzlePiece] = [piece_a, piece_b]
		groups.append(new_group)
		groups_by_piece[key_a] = new_group
		groups_by_piece[key_b] = new_group
		return
	
	if group_b.is_empty():
		group_a.append(piece_b)
		groups_by_piece[key_b] = group_a
		return
	
	if group_a.is_empty():
		group_b.append(piece_a)
		groups_by_piece[key_a] = group_b
		return
	
	if group_a.has(piece_b):
		return
	
	for member in group_b:
		if not group_a.has(member):
			group_a.append(member)
		groups_by_piece[member.get_instance_id()] = group_a
	
	groups.erase(group_b)


#func _unhandled_key_input(event: In]putEvent) -> void:
	#if event.is_action_pressed("create_piece_group"):
		#create_group_from_selection()
		#get_viewport().set_input_as_handled()
	#
	#elif event.is_action_pressed("ungroup_selected"):
		#ungroup_selected()
		#get_viewport().set_input_as_handled()


func try_snapping_to_a_group(main_piece : PuzzlePiece):
	for piece in eligible_sibling_for_grouping(main_piece):
		if check_piece_rotation(main_piece, piece) and check_piece_closeness(main_piece, piece)[0]:
			piece.global_rotation = main_piece.global_rotation
			piece.global_position = main_piece.global_position + check_piece_closeness(main_piece, piece)[1]
			merge_pieces(main_piece, piece)


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
