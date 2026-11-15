extends Control

@onready var minimap: MinimapController = get_parent() as MinimapController


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
		draw_texture(sprite.texture, texture_origin, sprite.modulate)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
