class_name LevelController
extends Node

var grid_x_bool : Array = []
var grid_y_bool : Array = []



func set_grid_bools(GRID_X, GRID_Y):
	for x in range(GRID_X):
		grid_x_bool.append(false)
	for y in range(GRID_Y):
		grid_y_bool.append(false)


func update_grid_bools(GRID_X, GRID_Y):
	grid_x_bool[GRID_X - 1] = true
	grid_y_bool[GRID_Y - 1] = true
