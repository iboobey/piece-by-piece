extends CanvasLayer

@export_category("Minimap Variables")
@export var pieces_root : Node2D
@export var board_camera : Camera2D
@export var board_bounds : Rect2 = Rect2(
	Vector2.ZERO,
	Vector2(1280,720))

@export var padding : float = 8.0
@export var piece_dot_radius : float = 3.0
