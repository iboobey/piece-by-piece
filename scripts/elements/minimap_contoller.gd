extends Control
class_name MinimapController



# Minimap Variables
@onready var pieces_root : Node2D = $"../..".pieces_root
@onready var board_camera : Camera2D = $"../..".board_camera
@onready var board_bounds : Rect2 = $"../..".board_bounds
@onready var padding : float = $"../..".padding

var minimap_dragging := false

# Map Variables
var map_rect : Rect2
var map_origin : Vector2
var map_scale : float

# Piece Sprite Variables
var white_texture_cache : Dictionary = {}



func _ready() -> void:
	if board_camera and not board_camera.camera_view_changed.is_connected(on_camera_view_changed):
		board_camera.camera_view_changed.connect(on_camera_view_changed)

func request_redraw():
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
	
	%MinimapPieces.queue_redraw()
	%CameraOverlay.queue_redraw()


func draw_piece_texture(sprite : Sprite2D):
	var map_position := world_to_map(sprite.global_position)
	
	if not map_rect.has_point(map_position):
		return
	
	var texture_size := Vector2(sprite.texture.get_size())
	var texture_origin := sprite.offset
	
	if sprite.centered:
		texture_origin -= texture_size / 2
	
	var minimap_scale := sprite.global_scale * map_scale
	
	if sprite.flip_h:
		minimap_scale.x *= -1
	
	if sprite.flip_v:
		minimap_scale.y *= -1
	
	draw_set_transform(map_position, sprite.global_rotation, minimap_scale)
	
	draw_texture(sprite.texture, texture_origin, Color.WHITE)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func get_white_silhouette(texture : Texture2D) -> Texture2D:
	var texture_id := texture.get_instance_id()
	
	if white_texture_cache.has(texture_id):
		return white_texture_cache[texture_id] as Texture2D
	
	var image := texture.get_image()
	
	if image == null or image.is_empty():
		return texture
	
	image.convert(Image.FORMAT_RGBA8)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var original_pixel := image.get_pixel(x, y)
			
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, original_pixel.a))
	
	var silhouette := ImageTexture.create_from_image(image)
	white_texture_cache[texture_id] = silhouette
	return silhouette


func move_camera_to_minimap_point(point : Vector2):
	if board_camera == null or map_scale <= 0.0:
		return
	
	var map_point := Vector2(clampf(point.x, map_rect.position.x, map_rect.end.x), clampf(point.y, map_rect.position.y, map_rect.end.y))
	
	var world_point := board_bounds.position + (map_point - map_origin) / map_scale
	
	board_camera.navigate_to_world(world_point)


func _input(event: InputEvent) -> void:
	if not minimap_dragging:
		return
	
	if event is InputEventMouseMotion:
		move_camera_to_minimap_point(get_local_mouse_position())
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			minimap_dragging = false
			UndoHistory.commit_action()
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			
			if not map_rect.has_point(event.position):
				return
			
			board_camera.finish_pending_camera_history()
			UndoHistory.begin_action("Navigate camera from minimap")
			
			minimap_dragging = true
			move_camera_to_minimap_point(event.position)
			accept_event()


func on_camera_view_changed():
	queue_redraw()
