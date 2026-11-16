extends CanvasLayer

@export_category("MinimapVariables")
@export var pieces_root : Node2D
@export var board_camera : Camera2D
@export var board_bounds : Rect2 = Rect2(
	Vector2.ZERO,
	Vector2(1280,720))

@export var padding : float = 8.0

@export var USE_AVERAGE_COLOR : bool = false

@onready var minimap_control: MinimapController = $PanelContainer/MinimapControl

func request_redraw():
	minimap_control.request_redraw()
