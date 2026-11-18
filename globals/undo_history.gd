extends Node
class_name UndoRedoHistory

var max_history_entries:int = 50

# Puzzle Nodes
var pieces_root : Node2D
var group_manager : GroupManager
var level_controller : LevelController
var board_camera : Camera2D

# Undo / Redo
var undo_stack : Array[Dictionary] = []
var redo_stack : Array[Dictionary] = []

var before_action: Dictionary = {}
var action_label : String = ""



func configure(
	new_pieces_root : Node2D,
	new_group_manager : GroupManager,
	new_level_controller : LevelController,
	new_board_camera : Camera2D):
	
	pieces_root = new_pieces_root
	group_manager = new_group_manager
	level_controller = new_level_controller
	board_camera = new_board_camera


func begin_action(label : String):
	if not before_action.is_empty():
		return
	
	action_label = label
	before_action = capture_state()


func commit_action():
	if before_action.is_empty():
		return
	
	var after_state := capture_state()
	
	undo_stack.append({
		"label" : action_label,
		"before" : before_action,
		"after" : after_state
	})
	
	while undo_stack.size() > max_history_entries:
		undo_stack.pop_front()
	
	redo_stack.clear()
	before_action = {}
	action_label = ""


func cancel_action():
	before_action = {}
	action_label = ""


func capture_state() -> Dictionary:
	var piece_states : Array[Dictionary] = []
	
	for candidate in pieces_root.get_children():
		if not (candidate is PuzzlePiece):
			continue
		
		var piece := candidate as PuzzlePiece
		
		piece_states.append({
			"piece" : piece,
			"position" : piece.global_position,
			"rotation" : piece.global_rotation,
			"is_snapped": piece.is_snapped,
			"locked" : piece.locked,
			"z_index" : piece.z_index})
	
	var saved_groups : Array = []
	
	for group in group_manager.groups:
		saved_groups.append(group.duplicate())
	
	return {
		"pieces" : piece_states,
		"groups" : saved_groups,
		"grid_bools" : level_controller.grid_bools.duplicate(true),
		"camera_target_position" : board_camera.get("target_position"),
		"camera_target_zoom" : board_camera.get("target_zoom")
	}


func restore_state(state : Dictionary):
	push_warning("Restore called")
	for piece_state in state["pieces"]:
		
		var piece : PuzzlePiece = piece_state["piece"]
		
		if not is_instance_valid(piece):
			continue
		
		piece.global_position = piece_state["position"]
		piece.global_rotation = piece_state["rotation"]
		piece.is_snapped = piece_state["is_snapped"]
		piece.locked = piece_state["locked"]
		piece.z_index = piece_state["z_index"]
		
	group_manager.groups.clear()
	group_manager.groups_by_piece.clear()
	
	for saved_group in state["groups"]:
		
		var restored_group : Array[PuzzlePiece] = []
		
		for member in saved_group:
			if is_instance_valid(member):
				restored_group.append(member)
		
		if restored_group.size() <= 1:
			continue
		
		group_manager.groups.append(restored_group)
		
		for member in restored_group:
			group_manager.groups_by_piece[member.get_instance_id()] = restored_group
		
		level_controller.grid_bools = state["grid_bools"].duplicate(true)
		
		
	board_camera.set("target_position", state["camera_target_position"])
	board_camera.set("target_zoom", state["camera_target_zoom"])


func undo():
	if undo_stack.is_empty() or not before_action.is_empty():
		return
	
	var action : Dictionary = undo_stack.pop_back()
	
	restore_state(action["before"])
	redo_stack.append(action)


func redo():
	if redo_stack.is_empty() or not before_action.is_empty():
		return
	
	var action : Dictionary = redo_stack.pop_back()
	
	restore_state(action["after"])
	undo_stack.append(action)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("undo") and not event.is_echo():
		undo()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("redo") and not event.is_echo():
		redo()
		get_viewport().set_input_as_handled()
