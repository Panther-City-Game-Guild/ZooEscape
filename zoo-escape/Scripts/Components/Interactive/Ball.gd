class_name ZEBall extends Area2D


enum STATES {
	IDLE,
	MOVING
}

@export var moveWidthTime := 0.75
var currentState := STATES.IDLE
var moveDistance := Globals.TILESIZE
var dirCheck := Vector2.ZERO
var skidTime := moveWidthTime * 2
@onready var raycast := $RayCast2D
@onready var checkSpace := $EnvironmentCheck


# Called to move the ball if possible
func move(dir:Vector2):
	$BallSprite.play("roll")
	raycast.target_position = dir * (Globals.TILESIZE * 4)
	dirCheck = dir
	raycast.force_raycast_update()
	
	if currentState == STATES.IDLE && !raycast.is_colliding():
		currentState = STATES.MOVING
		SoundControl.playSfx(SoundControl.flutter)
		position += dir * Globals.TILESIZE
		$MoveTimer.start(moveWidthTime)


# Called to set the ball to Idle
func idle():
	SoundControl.playSfx(SoundControl.thump)
	$BallSprite.play("idle")
	currentState = STATES.IDLE
	dirCheck = Vector2.ZERO
	$MoveTimer.stop()


# Called every physics frame
func _physics_process(_delta: float) -> void:
	if $RayCast2D.is_colliding() and currentState != STATES.IDLE:
		var collider = $RayCast2D.get_collider()
		if collider.name == "Wall":
			idle()


# Called to detect what the ball is colliding with
func _on_body_entered(_body: Node2D) -> void:
	if currentState != STATES.IDLE && raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.name == "Wall":
			SoundControl.playSfx(SoundControl.thump)
			idle()
		if "Ice" in collider.name:
			moveWidthTime = skidTime


# Called when the move timer expires
func _on_move_timer_timeout() -> void:
	match currentState:
		STATES.IDLE:
			position = Vector2.ZERO
			$MoveTimer.stop()
		STATES.MOVING:
			position += dirCheck * Globals.TILESIZE
			$MoveTimer.start(moveWidthTime)


# Called to detect which terrain the ball is on
func _on_environment_check_area_entered(area: Area2D) -> void:
	if "Ice" in area.name:
		moveWidthTime = skidTime
