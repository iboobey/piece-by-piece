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
@export_subgroup("Undo/Redo")
@export var PAN_DELAY : float = 0.5
@export var ZOOM_DELAY : float = 0.35

@export_category("MinimapVariables")
@export var MINIMAP : CanvasLayer

var target_position : Vector2
var target_zoom : Vector2


var last_minimap_position : Vector2
var last_minimap_zoom : Vector2

# Undo / Redo Variables
var pan_history_active := false
var pan_history_timer : Timer 
var zoom_history_active := false
var zoom_history_timer : Timer



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
	
	zoom_history_timer = Timer.new()
	zoom_history_timer.one_shot = true
	zoom_history_timer.wait_time = ZOOM_DELAY
	add_child(zoom_history_timer)
	zoom_history_timer.timeout.connect(on_zoom_history_timeout)
	
	
	
	pan_history_timer = Timer.new()
	pan_history_timer.one_shot = true
	pan_history_timer.wait_time = PAN_DELAY
	add_child(pan_history_timer)
	pan_history_timer.timeout.connect(on_pan_history_timeout)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pan") and not event.is_echo():
		if pan_history_timer.time_left > 0.0:
			pan_history_timer.stop()
		elif not pan_history_active:
			finish_pending_camera_history()
			UndoHistory.begin_action("Pan camera")
			pan_history_active = true
		
	if event.is_action_released("pan") and pan_history_active:
		pan_history_timer.start()
	
	if  event is InputEventMouseMotion and Input.is_action_pressed("pan"):
		target_position -= event.relative * PAN_SPEED / zoom
		target_position = clamp_camera_position(target_position, zoom)
	
	
	zoom_camera(event)


func clamp_camera_position(pos : Vector2, zoom_value : Vector2):
	var half_view := get_viewport_rect().size / zoom_value / 2
	
	pos.x = clamp_axis(pos.x, limit_left, limit_right, half_view.x)
	pos.y = clamp_axis(pos.y, limit_top, limit_bottom, half_view.y)
	
	return pos


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
	
	new_zoom_value = clampf(new_zoom_value, MIN_ZOOM, MAX_ZOOM)
	
	if is_equal_approx(new_zoom_value, target_zoom.x):
		return
	
	if not zoom_history_active:
		finish_pending_camera_history()
		UndoHistory.begin_action("Zoom camera")
		zoom_history_active = true
	
	zoom_to_cursor(new_zoom_value)
	zoom_history_timer.start()
	
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


func on_zoom_history_timeout():
	if not zoom_history_active:
		return
	
	UndoHistory.commit_action()
	zoom_history_active = false


func on_pan_history_timeout():
	if not pan_history_active:
		return
	
	pan_history_active = false
	UndoHistory.commit_action()


func finish_pending_camera_history():
	if pan_history_active:
		pan_history_timer.stop()
		on_pan_history_timeout() 
	if zoom_history_active:
		zoom_history_timer.stop()
		on_zoom_history_timeout() 
