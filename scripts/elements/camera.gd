extends Camera2D

@export_category("Movement Variables")
@export var PAN_SPEED : float = 1.0 
@export var ZOOM_AMOUNT : float = 0.05
@export var MAX_ZOOM : float = 3
@export var MIN_ZOOM : float = 1


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("pan"):
		global_position -= event.relative * PAN_SPEED / zoom
		clampt_to_limits()
	zoom_camera(event)


func clampt_to_limits():
	var half_view := get_viewport_rect().size / zoom * 0.5
	var camera_position := global_position
	
	camera_position.x = clamp_axis(
		camera_position.x, limit_left, limit_right, half_view.x
	)
	
	camera_position.y = clamp_axis(
		camera_position.y, limit_top, limit_bottom, half_view.y
	)
	
	global_position = camera_position


func clamp_axis(value : float, world_min : float, world_max : float, half_view : float):
	
	var min_center := world_min + half_view
	var max_center := world_max - half_view
	
	if min_center > max_center:
		return (world_min + world_max) * 0.5
	
	return clampf(value, min_center, max_center)


func zoom_camera(event: InputEvent):
	if not (event is InputEventMouseButton):
		return
	
	var mouse_event := event as InputEventMouseButton
	
	if not mouse_event.pressed:
		return
	
	var target_zoom := zoom.x
	
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		target_zoom += ZOOM_AMOUNT
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		target_zoom -= ZOOM_AMOUNT
	else:
		return
	
	target_zoom = clampf(target_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom_to_cursor(target_zoom)
	get_viewport().set_input_as_handled()
	


func zoom_to_cursor(target_zoom : float):
	var old_zoom := zoom.x
	var new_zoom := clampf(target_zoom, MIN_ZOOM, MAX_ZOOM)
	
	if is_equal_approx(old_zoom, new_zoom):
		return
	
	
	var cursor_world_before := get_global_mouse_position()
	var cursor_offset := cursor_world_before - global_position
	
	zoom = Vector2.ONE * new_zoom
	
	
	global_position += cursor_offset * (1.0 - old_zoom / new_zoom)
	
	clampt_to_limits()
