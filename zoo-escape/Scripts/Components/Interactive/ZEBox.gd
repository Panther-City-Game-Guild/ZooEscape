class_name ZEBoxArea extends Area2D

enum states {
	Movable,
	InWater
}

@onready var currentState := states.Movable
@onready var ray := $RayCast2D

# set up signals
func _ready() -> void:
	$WaterCheck.area_entered.connect(waterCheckAreaEnter)

# if possable moves the box and reports back to caller
func move(dir: Vector2) -> bool:
	ray.target_position = dir * Globals.ZETileSize
	ray.force_raycast_update()
	
	if currentState == states.Movable && !ray.is_colliding():
		SoundControl.playSfx(SoundControl.scuff)
		position += dir * Globals.ZETileSize
		return true
	else:
		SoundControl.playSfx(SoundControl.scuff)
		return false

# when the area see water update the state of the box
func waterCheckAreaEnter(area: Area2D) -> void:
		SoundControl.playSfx(SoundControl.splorch)
		area.queue_free()
		
		currentState = states.InWater
	
		# TODO: set to water frame
		
		# removes the collision of the box
		collision_layer = 0
