extends Node2D
class_name GroupManager

@export var PUZZLE_GRID : PuzzleGrid

var selected_pieces : Array[PuzzlePiece] = []
var groups : Array = []
var groups_by_piece : Dictionary = {}

@onready var closeness_radius := PUZZLE_GRID.GRID_SIZE * 1.5



func toggle_selection(piece : PuzzlePiece):
	if not is_instance_valid(piece):
		return
	
	if piece.locked or piece.is_snapped:
		return
	
	if selected_pieces.has(piece):
		selected_pieces.erase(piece)
	else:
		selected_pieces.append(piece)


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
	var members: Array = groups_by_piece.get(piece.get_instance_id(), [])
	if members.is_empty():
		return [piece]
	
	return members.duplicate()


func ungroup_piece(piece : PuzzlePiece):
	if not is_instance_valid(piece):
		return false
	
	var piece_id := piece.get_instance_id()
	if not groups_by_piece.has(piece_id):
		return false
	
	var group : Array = groups_by_piece[piece_id]
	
	if not group.has(piece):
		groups_by_piece.erase(piece_id)
		return false
	
	group.erase(piece)
	groups_by_piece.erase(piece_id)
	
	if group.size() <= 1:
		groups.erase(group)
		
		for remaining_piece in group:
			if is_instance_valid(remaining_piece):
				groups_by_piece.erase(remaining_piece.get_instance_id())
	else:
		for remaining_piece in group:
			if is_instance_valid(remaining_piece):
				groups_by_piece[remaining_piece.get_instance_id()] = group
	
	return true


func ungroup_selected_pieces():
	for piece in selected_pieces:
		if is_instance_valid(piece):
			ungroup_piece(piece)
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


func _unhandled_input(event: InputEvent) -> void:
	group_input(event)
	ungroup_input(event)
	clear_selection(event)


func try_snapping_to_a_group(main_piece : PuzzlePiece, selected_candidates: Array = []):
	
	var candidates : Array
	
	if selected_candidates.is_empty():
		candidates = eligible_sibling_for_grouping(main_piece)
	else:
		candidates = []
		for candidate in eligible_sibling_for_grouping(main_piece):
			if selected_candidates.has(candidate):
				candidates.append(candidate)
	
	for piece in candidates:
		if piece == main_piece:
			continue
			
		var can_snap : Array = check_piece_closeness(main_piece, piece)
		if check_piece_rotation(main_piece, piece) and can_snap[0]:
			var moving_members : Array = get_drag_members(piece)
			
			if moving_members.has(main_piece):
				continue
			
			var target_pos = main_piece.global_position + can_snap[1]
			var pivot = piece.global_position
			
			var rotation_delta := wrapf(main_piece.global_rotation - piece.global_rotation, -PI, PI)
			
			for member in moving_members:
				if member is PuzzlePiece:
					member.global_position = pivot + (member.global_position - pivot).rotated(rotation_delta)
					member.global_rotation += rotation_delta 
			
			var position_delta = target_pos - piece.global_position
			
			for member in moving_members:
				if member is PuzzlePiece:
					member.global_position += position_delta
			
			merge_pieces(main_piece,piece)
			return true
	return false


func check_piece_closeness(main_piece : PuzzlePiece, piece : PuzzlePiece) -> Array:
	
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
		return [false, Vector2.ZERO]
	
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


func clamp_group_to_bounds(members : Array):
	var valid_members : Array[PuzzlePiece] = []
	
	for candidate in members: 
		if not is_instance_valid(candidate) or not(candidate is PuzzlePiece):
			continue
		
		var piece := candidate as PuzzlePiece
		if not valid_members.has(piece):
			valid_members.append(piece)
	
	if valid_members.is_empty():
		return
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for piece in valid_members:
		min_x = minf(min_x, piece.global_position.x)
		min_y = minf(min_y, piece.global_position.y)
		max_x = maxf(max_x, piece.global_position.x)
		max_y = maxf(max_y, piece.global_position.y)
	
	var bounding_min : Vector2 = get_viewport_rect().position
	var bounding_max : Vector2 = bounding_min + get_viewport_rect().size
	
	
	var correction_offset := Vector2(
		get_axis_correction_offset(min_x, max_x, bounding_min.x, bounding_max.x),
		get_axis_correction_offset(min_y, max_y, bounding_min.y, bounding_max.y)
	)
	
	for piece in valid_members:
		piece.global_position += correction_offset


func get_axis_correction_offset(group_min : float, group_max : float, bound_min : float, bound_max : float):
	var min_delta := bound_min - group_min
	var max_delta := bound_max - group_max
	
	if min_delta < max_delta:
		return clampf(0.0, min_delta, max_delta)
	
	return clampf((bound_min + bound_max) / 2 - (group_min + group_max) / 2, bound_min, bound_max)


func ungroup_input(event : InputEvent):
	if not event.is_action_pressed("ungroup_selected") or event.is_echo():
		return
	
	var changed := false
	
	if not selected_pieces.is_empty():
		UndoHistory.begin_action("Ungroup Selected Pieces")
		changed = ungroup_selected_pieces()
	
	if changed:
		UndoHistory.commit_action()
	elif not selected_pieces.is_empty():
		UndoHistory.cancel_action()
	
	selected_pieces.clear()
	get_viewport().set_input_as_handled()


func group_input(event : InputEvent):
	if not event.is_action_pressed("group_selected") or event.is_echo():
		return
	
	var selected := selected_pieces.duplicate()
	
	if selected_pieces.size() <= 1:
		get_viewport().set_input_as_handled()
		return
	
	UndoHistory.begin_action("Group Selected Pieces")
	
	var changed := false
	var merged_this_pass := true
	
	while merged_this_pass:
		merged_this_pass = false
		
		for main_piece in selected:
			if not is_instance_valid(main_piece):
				continue
				
			if try_snapping_to_a_group(main_piece, selected):
				changed = true
				merged_this_pass = true
	
	if changed:
		UndoHistory.commit_action()
	else:
		UndoHistory.cancel_action()
	
	selected_pieces.clear()
	get_viewport().set_input_as_handled()
	return


func clear_selection(event : InputEvent):
	if event.is_action_pressed("delete_seletion") and not event.is_echo():
		selected_pieces.clear()
