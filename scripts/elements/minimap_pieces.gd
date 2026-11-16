extends Control

@onready var minimap: MinimapController = get_parent() as MinimapController

@onready var use_average_color = $"../../..".USE_AVERAGE_COLOR

static var average_color_cache : Dictionary = {}



func _draw() -> void:
	if minimap == null or minimap.pieces_root == null:
		return
	
	for piece in minimap.pieces_root.get_children():
		if not (piece is Node2D):
			continue
		
		var sprite := piece.get_node_or_null("PuzzlePieceSprite") as Sprite2D
		
		if sprite== null or sprite.texture == null:
			continue
		
		var map_position := minimap.world_to_map(sprite.global_position)
		
		if not minimap.map_rect.has_point(map_position):
			continue
		
		var texture_origin := sprite.offset
		
		if sprite.centered:
			texture_origin -= Vector2(sprite.texture.get_size()) / 2
		
		var draw_scale := sprite.global_scale * minimap.map_scale
		
		if sprite.flip_h:
			draw_scale.x *= -1
		if sprite.flip_v:
			draw_scale.y *= -1
		
		draw_set_transform(map_position, sprite.global_rotation, draw_scale)
		
		var piece_color: Color = piece.get("PUZZLE_MODULE")
		draw_texture(sprite.texture, texture_origin, piece_color)
		
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func get_average_color(texture : Texture2D):
	var texture_id := texture.get_instance_id()
	
	if average_color_cache.has(texture_id):
		var cached_color : Color = average_color_cache[texture_id]
		return cached_color
	
	var image := texture.get_image()
	
	if image == null or image.is_empty():
		return Color.WHITE
	
	image.convert(Image.FORMAT_RGBA8)
	
	var rgb_sum := Vector3.ZERO
	var alpha_sum := 0.0
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			
			rgb_sum += Vector3(pixel.r, pixel.g, pixel.b) * pixel.a
			alpha_sum += pixel.a
	
	var average := Color.WHITE
	
	if alpha_sum > 0.0:
		var rgb_average := rgb_sum / alpha_sum
		average = Color(rgb_average.x, rgb_average.y, rgb_average.z, 1.0)
	
	average_color_cache[texture_id] = average
	return average
