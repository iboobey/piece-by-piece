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

# Piece Sprite Variables
var white_texture_cache : Dictionary = {}


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
	
	for piece in pieces_root.get_children():
		if not (piece is Node2D):
			continue
		
		var piece_sprite := piece.get_node_or_null("PuzzlePieceSprite") as Sprite2D
		
		if piece_sprite == null or piece_sprite.texture == null:
			continue
		
		draw_piece_texture(piece_sprite)
	
	var world_view_size := get_viewport_rect().size / board_camera.zoom
	var view_center := board_camera.get_screen_center_position()
	var view_top_left_corner := view_center - world_view_size / 2
	
	var camera_map_rect := Rect2(world_to_map(view_top_left_corner), world_view_size * map_scale)
	
	var visible_camera_rect := camera_map_rect.intersection(map_rect)
	
	if visible_camera_rect.size.x > 0.0 and visible_camera_rect.size.y > 0.0:
		draw_rect(visible_camera_rect, Color(1.0, 0.85, 0.2), false, 2.0)


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
	
	var silhoutte := get_white_silhoutte(sprite.texture)
	draw_texture(silhoutte, texture_origin, Color.WHITE)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func get_white_silhoutte(texture : Texture2D) -> Texture2D:
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
	
	var silhoutte := ImageTexture.create_from_image(image)
	white_texture_cache[texture_id] = silhoutte
	return silhoutte
