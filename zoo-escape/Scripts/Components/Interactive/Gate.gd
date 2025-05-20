extends Node2D

# NOTE: A double hashtag comment next to exported variables provides the editor with hints
@export_enum("CLOSED", "OPEN") var gateState: int = 0 ## The initial state of the Gate; Closed = 0 or Open = 1


# Called when the Node enters the Scene Tree for the first time
func _ready() -> void:
	$Sprite2D.frame = gateState
	setCollision()


# Called to change the state of the Gate
func changeState() -> void:
	gateState = !gateState
	$Sprite2D.frame = gateState
	setCollision()


# Called to set the Gate's collision layer, which is what allows the player to pass through
func setCollision() -> void:
	if gateState == 1:
		$Area2D.collision_layer = 0
	else:
		$Area2D.collision_layer = 1
