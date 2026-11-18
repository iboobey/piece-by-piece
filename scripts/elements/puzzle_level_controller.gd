class_name LevelController
extends Node

@export var PUZZLE_GRID : Node2D
@export var MINIMAP : CanvasLayer


var grid_x_bool : Array = []
var grid_y_bool : Array = []
var grid_bools : Array = []

var grid_columns : int = 0
var grid_rows : int = 0


func set_grid_bools(columns, rows):
	
	grid_columns = columns
	grid_rows = rows
	
	grid_bools.clear()
	
	for y in range(grid_rows):
		var row : Array[bool] = []
		
		for x in range(grid_columns):
			row.append(false)
		
		grid_bools.append(row)


func is_inside_board(cell : Vector2i):
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x <= grid_columns
		and cell.y <= grid_rows
	)


func is_occupied(cell : Vector2i):
	if not is_inside_board(cell):
		return false
	
	return bool(grid_bools[cell.y - 1][cell.x - 1])


func has_cardinal_neighbors(cell : Vector2i):
	return(
		is_occupied(cell + Vector2i.LEFT)
		or is_occupied(cell + Vector2i.UP)
		or is_occupied(cell + Vector2i.RIGHT)
		or is_occupied(cell + Vector2i.DOWN)
	)


func is_side(cell : Vector2i):
	return (
		cell.x == 1
		or cell.y == 1
		or cell.x == PUZZLE_GRID.GRID_X
		or cell.y == PUZZLE_GRID.GRID_Y
	)


func can_snap(grid_x : int, grid_y : int):
	var cell := Vector2i(grid_x, grid_y)
	
	if not is_inside_board(cell):
		return false
	
	if is_occupied(cell):
		return false
	
	if not is_side(cell) and not has_cardinal_neighbors(cell):
		return false
	
	grid_bools[cell.y - 1][cell.x - 1] = true
	return true


func try_snap_group(members : Array):
	if members.is_empty():
		return false
	
	var planned_pieces : Array[PuzzlePiece] = []
	var planned_cells : Dictionary = {}
	
	for candidate in members:
		if not is_instance_valid(candidate) or not(candidate is PuzzlePiece):
			return false
		
		var piece := candidate as PuzzlePiece
		
		if piece.locked or piece.is_snapped:
			return false
		
		var cell := Vector2i(piece.GRID_X,piece.GRID_Y) 
		
		if not is_inside_board(cell):
			return false
		
		if is_occupied(cell):
			return false
		
		if planned_cells.has(cell):
			return false
		
		if not piece.check_target():
			return false
		
		
		planned_cells[cell] = true
		planned_pieces.append(piece)
	
	var has_board_connection := false
	
	for cell in planned_cells:
		if is_side(cell) or has_cardinal_neighbors(cell):
			has_board_connection = true
			break
	
	if not has_board_connection:
		return false
	
	
	for piece in planned_pieces:
		var cell := Vector2i(piece.GRID_X, piece.GRID_Y)
		grid_bools[cell.y - 1][cell.x - 1] = true
		piece.is_snapped = true
		piece.lock_piece()
		piece.z_index = -4096
	
	MINIMAP.request_redraw()
	
	return true
