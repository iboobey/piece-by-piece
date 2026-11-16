extends Node
class_name GroupManager 

var selected_pieces : Array[PuzzlePiece] = []
var groups : Array = []
var groups_by_piece : Dictionary = {}



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
