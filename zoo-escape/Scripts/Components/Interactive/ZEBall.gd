class_name ZEBall extends Area2D

enum STATES {
	IDLE,
	MOVING}
var currentState = STATES.IDLE
var moveDistance = Globals.ZETileSize
var dirCheck = Vector2.ZERO
@onready var raycast = $RayCast2D
@onready var checkSpace = $EnvironmentCheck
@export var moveWidthTime : float = 0.75
var skidTime = moveWidthTime * 2 


func Move(dir:Vector2):
	$BallSprite.play("roll")
	raycast.target_position = dir * (Globals.ZETileSize*4)
	dirCheck = dir
	raycast.force_raycast_update()
	
	if currentState == STATES.IDLE && !raycast.is_colliding():
		currentState = STATES.MOVING
		SoundControl.playSfx(SoundControl.flutter)
		position += dir * Globals.ZETileSize
		$MoveTimer.start(moveWidthTime)


func Idle():
	SoundControl.playSfx(SoundControl.thump)
	$BallSprite.play("idle")
	currentState = STATES.IDLE
	dirCheck = Vector2.ZERO
	$MoveTimer.stop()


func _physics_process(_delta: float) -> void:
	if $RayCast2D.is_colliding() and currentState != STATES.IDLE:
		var collider = $RayCast2D.get_collider()
		if collider.name == "Wall":
			Idle()


func _on_body_entered(body: Node2D) -> void:
	if currentState != STATES.IDLE && raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.name == "Wall":
			SoundControl.playSfx(SoundControl.thump)
			Idle()
		if "Ice" in collider.name:
			moveWidthTime = skidTime


func _on_move_timer_timeout() -> void:
	match currentState:
		STATES.IDLE:
			position = Vector2.ZERO
			$MoveTimer.stop()
		STATES.MOVING:
			position += dirCheck * Globals.ZETileSize
			$MoveTimer.start(moveWidthTime)



func _on_environment_check_area_entered(area: Area2D) -> void:
	if "Ice" in area.name:
		moveWidthTime = skidTime
