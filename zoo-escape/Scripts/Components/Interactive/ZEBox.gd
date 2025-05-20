class_name ZEBoxArea extends Area2D

enum states {
	MOVABLE,
	INWATER,
	SLIDING
}

@onready var currentState := states.MOVABLE
@onready var ray := $RayCast2D
@onready var currentDir := Vector2.DOWN

# set up signals
func _ready() -> void:
	$GroundCheck.body_entered.connect(bodyEnter)

# if possable moves the box and reports back to caller
func move(dir: Vector2) -> bool:
	currentDir = dir
	ray.target_position = dir * Globals.ZETileSize
	ray.force_raycast_update()
	
	if currentState != states.INWATER && !ray.is_colliding():
		SoundControl.playSfx(SoundControl.scuff)
		position += dir * Globals.ZETileSize
		return true
	else:
		SoundControl.playSfx(SoundControl.scuff)
		return false

# check for 
func bodyEnter(body: Node2D) -> void:
	if body is TileMapLayer:
		var tilePos: Vector2i = body.local_to_map($GroundCheck.global_position)
		if body.get_cell_tile_data(body.local_to_map($GroundCheck.global_position)).get_custom_data("Water"):
			body.set_cell(body.local_to_map($GroundCheck.global_position), 2, body.get_cell_atlas_coords(body.local_to_map($GroundCheck.global_position)))
			SoundControl.playSfx(SoundControl.splorch)
			currentState = states.INWATER
			collision_layer = 0
		elif body.get_cell_tile_data(tilePos).get_custom_data("Ice"):
			if(!ray.is_colliding()):
				currentState = states.SLIDING
				move(currentDir)
			else:
				currentState = states.MOVABLE
