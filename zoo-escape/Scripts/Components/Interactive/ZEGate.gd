extends Node2D


@export_enum("CLOSED", "OPEN") var gateState: int = 0 # the initial state of the Gate, Closed or Open


# Called when the Node enters the Scene Tree for the first time
func _ready() -> void:
	$Sprite2D.frame = gateState


# Called to change the state of the Gate
func changeState() -> void:
	gateState = !gateState
	$Sprite2D.frame = gateState
	
	if gateState == 1:
		$Area2D.collision_layer = 0
	else:
		$Area2D.collision_layer = 1
