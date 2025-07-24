extends Node2D


@export_enum("CLOSED", "OPEN") var gateState: int = 0 # The initial state of the Gate; Closed = 0 or Open = 1
@export_range(0.25,0.5,0.01) var soundBufferTime := 0.5
var soundBufferExpired := false
@export var isHorizontal := false



# Called when the Node enters the Scene Tree for the first time
func _ready() -> void:
	if isHorizontal:
		$Sprite2D.rotation = -90
	$SoundBuffer.start(soundBufferTime)
	$Sprite2D.frame = gateState
	setCollision()


# Called to change the state of the Gate
func changeState() -> void:
	gateState = !gateState
	$Sprite2D.frame = gateState
	setCollision()
	if soundBufferExpired:
		$GateCue.play()


# Called to set the Gate's collision layer, which is what allows the player to pass through
func setCollision() -> void:
	if gateState == 1:
		$Area2D.collision_layer = 0
		$GateCue.pitch_scale = 1.1
	else:
		$Area2D.collision_layer = 1
		$GateCue.pitch_scale = 1.0


func _on_sound_buffer_timeout() -> void:
	soundBufferExpired = true
