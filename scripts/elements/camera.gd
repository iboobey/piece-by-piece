extends Camera2D

signal camera_view_changed

@export_category("MovementVariables")
@export_subgroup("Movement")
@export var PAN_SPEED : float = 1.0 
@export var ZOOM_AMOUNT : float = 0.05
@export var MAX_ZOOM : float = 3
@export var MIN_ZOOM : float = 1
@export_subgroup("Smoothing")
@export var MOVE_SMOOTHING : float = 8.0
@export var ZOOM_SMOOTHING : float = 8.0


@export_category("MinimapVariables")
@export var MINIMAP : CanvasLayer

var target_position : Vector2
var target_zoom : Vector2


var last_minimap_position : Vector2
var last_minimap_zoom : Vector2



func _process(delta: float) -> void:
	
	target_position = clamp_camera_position(target_position, target_zoom) 
	
	var move_weight := 1.0 - exp(-MOVE_SMOOTHING * delta)
	var zoom_weight := 1.0 - exp(-ZOOM_SMOOTHING * delta)
	
	global_position = global_position.lerp(target_position, move_weight)
	zoom = zoom.lerp(target_zoom, zoom_weight)
	
	global_position = clamp_camera_position(global_position, zoom)
	
	
	if not global_position.is_equal_approx(last_minimap_position) or not zoom.is_equal_approx(last_minimap_zoom):
		last_minimap_position = global_position
		last_minimap_zoom = zoom
		camera_view_changed.emit()


func _ready() -> void:
	last_minimap_position = global_position
	last_minimap_zoom = zoom
	
	target_position = global_position
	target_zoom = zoom


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("pan"):
		target_position -= event.relative * PAN_SPEED / zoom
		target_position = clamp_camera_position(target_position, zoom)
		
	zoom_camera(event)


func clamp_camera_position(position : Vector2, zoom_value : Vector2):
	var half_view := get_viewport_rect().size / zoom_value / 2
	
	position.x = clamp_axis(position.x, limit_left, limit_right, half_view.x)
	position.y = clamp_axis(position.y, limit_top, limit_bottom, half_view.y)
	
	return position


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
	
	var new_zoom_value := target_zoom.x
	
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		new_zoom_value += ZOOM_AMOUNT
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		new_zoom_value -= ZOOM_AMOUNT
	else:
		return
	
	zoom_to_cursor(new_zoom_value)
	get_viewport().set_input_as_handled()
	MINIMAP.request_redraw()


func zoom_to_cursor(new_zoom_value : float):
	new_zoom_value = clampf(new_zoom_value, MIN_ZOOM, MAX_ZOOM)
	
	if is_equal_approx(target_zoom.x, new_zoom_value):
		return
	
	var cursor_screen := get_viewport().get_mouse_position()
	var screen_offset := cursor_screen - get_viewport_rect().size / 2
	
	var world_anchor := target_position + screen_offset / target_zoom.x
	
	target_zoom = Vector2.ONE * new_zoom_value
	target_position = world_anchor - screen_offset / new_zoom_value
	target_position = clamp_camera_position(target_position, target_zoom)


func navigate_to_world(world_pos : Vector2):
	target_position = clamp_camera_position(world_pos, target_zoom)
