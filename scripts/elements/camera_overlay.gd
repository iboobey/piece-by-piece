extends Control

@onready var minimap : MinimapController = get_parent() as MinimapController


func _draw() -> void:
	if minimap == null or minimap.board_camera == null:
		return
	
	var world_view_size := (get_viewport_rect().size / minimap.board_camera.zoom)
	
	var view_center := minimap.board_camera.get_screen_center_position()
	var view_top_left := view_center - world_view_size / 2
	
	var camera_map_rect := Rect2(minimap.world_to_map(view_top_left), world_view_size * minimap.map_scale)
	
	var visible_camera_rect := camera_map_rect.intersection(minimap.map_rect)
	
	if visible_camera_rect.size.x >= 0.0 and visible_camera_rect.size.y >= 0.0:
		draw_rect(
			visible_camera_rect,
			Color(1.0,0.85,0.2),
			false,
			2.0
		)
