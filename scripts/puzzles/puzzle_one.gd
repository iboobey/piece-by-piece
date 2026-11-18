extends Node2D

@onready var puzzle_grid: PuzzleGrid = %PuzzleGrid
@onready var level_controller: LevelController = %LevelController
@onready var pieces_root: Node2D = %PiecesRoot
@onready var group_manager: GroupManager = %PiecesRoot
@onready var board_camera: Camera2D = %BoardCamera
@onready var minimap: CanvasLayer = %Minimap



func _ready() -> void:
	UndoHistory.configure(
		pieces_root,
		group_manager,
		level_controller,
		board_camera
	)
