extends Control
class_name MinimapController



# Minimap Variables
@onready var pieces_root : Node2D = $"../..".pieces_root
@onready var board_camera : Camera2D = $"../..".board_camera
@onready var board_bounds : Rect2 = $"../..".board_bounds
@onready var padding : float = $"../..".padding
@onready var piece_dot_radius : float = $"../..".piece_dot_radius

var map_rect : Rect2
var map_origin : Vector2
var map_scale : float


func _process(_delta: float) -> void:
	queue_redraw()


func world_to_map(world_position : Vector2) -> Vector2:
	return map_origin + (world_position - board_bounds.position) * map_scale


func _draw() -> void:
	
	
	if board_camera == null or pieces_root == null:
		return
	
	if board_bounds.size.x <= 0.0 or board_bounds.size.y <= 0.0:
		return
	
	
	var inner_rect := Rect2(
		Vector2(padding,padding),
		size - Vector2(padding * 2, padding * 2)
	)
	
	
	if inner_rect.size.x <= 0.0 or inner_rect.size.y <= 0.0:
		return
	
	
	map_scale = minf(
		inner_rect.size.x / board_bounds.size.x,
		inner_rect.size.y / board_bounds.size.y
	)
	
	var map_size := board_bounds.size * map_scale
	map_origin = inner_rect.position + (inner_rect.size - map_size) / 2
	map_rect = Rect2(map_origin, map_size)
	
	draw_rect(map_rect, Color(0.12, 0.12, 0.12, 0.9), true)
	draw_rect(map_rect, Color(0.75, 0.75, 0.75), false, 1)
	
	for piece in pieces_root.get_children():
		if not (piece is Node2D):
			continue
		
		
		var map_position := world_to_map(piece.global_position)
		
		if map_rect.has_point(map_position):
			draw_circle(map_position, piece_dot_radius, piece.modulate)
	
	var world_view_size := get_viewport_rect().size / board_camera.zoom
	var view_center := board_camera.get_screen_center_position()
	var view_top_left_corner := view_center - world_view_size / 2
	
	var camera_map_rect := Rect2(world_to_map(view_top_left_corner), world_view_size * map_scale)
	
	var visible_camera_rect := camera_map_rect.intersection(map_rect)
	
	if visible_camera_rect.size.x > 0.0 and visible_camera_rect.size.y > 0.0:
		draw_rect(visible_camera_rect, Color(1.0, 0.85, 0.2), false, 2.0)
	
