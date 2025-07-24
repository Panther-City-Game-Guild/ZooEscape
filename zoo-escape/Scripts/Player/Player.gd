class_name Player extends CharacterBody2D

const STEPNOISE := "res://Assets/Sound/DeepThump.ogg"
const SLIPNOISE := "res://Assets/Sound/Squelch.ogg"

enum playerState {
	IDLE,
	INWATER,
	ONEXIT,
	SLIDING,
	CORNERSLIDING
}

@onready var dirToAnimationName := {
	Vector2.UP: "IdleUp",
	Vector2.RIGHT: "IdleRight",
	Vector2.DOWN: "IdleDown",
	Vector2.LEFT: "IdleLeft"
}

@onready var walkToAnimationName1 := {
	Vector2.UP: "WalkUp1",
	Vector2.RIGHT: "WalkRight1",
	Vector2.DOWN: "WalkDown1",
	Vector2.LEFT: "WalkLeft1"
}

@onready var walkToAnimationName2 := {
	Vector2.UP: "WalkUp2",
	Vector2.RIGHT: "WalkRight2",
	Vector2.DOWN: "WalkDown2",
	Vector2.LEFT: "WalkLeft2"
}

@export var moveSpeed := 0.3
@export var slideSpeed := 0.1
@export var stepMuffleLevel := 9 # value to muffle footsteps
@onready var currentDir := Vector2.DOWN
@onready var sprite := $AnimatedSprite2D
@onready var ray := $RayCast2D
@onready var thoughtBubble := $ThoughtBubble
@onready var idleTimer := $IdleTimer
@onready var currentState := playerState.IDLE
@onready var moveTimer := 0.0
@onready var lastMoveDir := Vector2.DOWN
@onready var facingDir := Vector2.DOWN # this catches the last input to determine ball direction
var stepFlip := false

signal InWater
signal PlayerMoved

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	$StepCue.volume_db = SoundControl.sfxLevel - stepMuffleLevel # default player footsteps to low volume
	$GroundCheck.body_entered.connect(bodyEnter)
	$GroundCheck.body_exited.connect(bodyExit)
	$GroundCheck.area_entered.connect(areaEnter)
	idleTimer.timeout.connect(showResetThought)
	sprite.play("IdleDown")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currentState == playerState.IDLE:
		if idleTimer.is_stopped(): # is player is idle, idle bubble timer starts
			idleTimer.start()
			
		# move player in direction of input
		if Input.is_action_just_pressed("DigitalUp"):
			movePlayer(Vector2.UP)
		elif Input.is_action_just_pressed("DigitalRight"):
			movePlayer(Vector2.RIGHT)
		elif Input.is_action_just_pressed("DigitalDown"):
			movePlayer(Vector2.DOWN)
		elif Input.is_action_just_pressed("DigitalLeft"):
			movePlayer(Vector2.LEFT)
			
		if Input.is_action_pressed("DigitalUp") || Input.is_action_pressed("DigitalRight") || Input.is_action_pressed("DigitalDown") || Input.is_action_pressed("DigitalLeft"):
			moveTimer += delta
			
		if Input.is_action_just_released("DigitalUp") || Input.is_action_just_released("DigitalRight") || Input.is_action_just_released("DigitalDown") || Input.is_action_just_released("DigitalLeft"):
			moveTimer = 0
			
		if moveTimer >= moveSpeed:
			if Input.is_action_pressed("DigitalUp"):
				movePlayer(Vector2.UP)
			elif Input.is_action_pressed("DigitalRight"):
				movePlayer(Vector2.RIGHT)
			elif Input.is_action_pressed("DigitalDown"):
				movePlayer(Vector2.DOWN)
			elif Input.is_action_pressed("DigitalLeft"):
				movePlayer(Vector2.LEFT)
			
			moveTimer = 0
		
		if Input.is_action_just_pressed("ActionButton"):
			# Detect if "ray" is colliding with an object (e.g., Player is facing a Switch)
			# - If so, try to interact
			if ray.is_colliding():
				interactWithRayCollider(ray.get_collider())
	elif currentState == playerState.SLIDING:
		moveTimer += delta
		
		# move player and choose slide animation when sliding
		if moveTimer >= slideSpeed:
			movePlayer(lastMoveDir)
			moveTimer = 0
			slideAnimationCall()


# for a "victory" animation
# TODO: make a "victory" animation
func endLevelAnimation() -> void:
	sprite.play(dirToAnimationName[Vector2.DOWN])


# this function determines which of two walk animations to play (flag flips each input)
func walkStepAnimationQueue(_dir:Vector2) -> void:
	if !stepFlip:
		sprite.play(walkToAnimationName1[_dir])
	else:
		sprite.play(walkToAnimationName2[_dir])


# called to fetch and compare the slide animation to slide direction and movement
func slideAnimationCall() -> void:
	if moveTimer == 0:
		match lastMoveDir:
			Vector2.DOWN:
				sprite.play("SlideDown")
			Vector2.LEFT:
				sprite.play("SlideLeft")
			Vector2.RIGHT:
				sprite.play("SlideRight")
			Vector2.UP:
				sprite.play("SlideUp")
			Vector2.ZERO: # return to idle if still
				currentState = playerState.IDLE
				sprite.play(dirToAnimationName[lastMoveDir])


# Called to move the player
func movePlayer(dir: Vector2) -> void:
	stepFlip = !stepFlip # flip step flag every step for alternating animation
	facingDir = dir # update direction of "pushing" for ball
	var _pitch = randf_range(-0.25, 0.25)
	$StepCue.pitch_scale = 1 + _pitch
	$StepCue.play()
	idleTimer.stop()
	
	# Change the direction the Player is facing and determine animation update behavior
	if currentState != playerState.SLIDING:
		walkStepAnimationQueue(dir)
	# update facing direction
	ray.target_position = dir * Globals.TILESIZE
	ray.force_raycast_update()
	
	# After changing the direction the Player is facing,
	# if the Player's RayCast2D is colliding, do logic
	if ray.is_colliding():
		var collidingObj: Object = ray.get_collider()
		if collidingObj is ZEBoxArea:
		# If the collider is a Box, try to move the Box and the Player
			if collidingObj.move(dir):
				position += dir * Globals.TILESIZE
				if currentState == playerState.IDLE:
					PlayerMoved.emit()
	# Otherwise, if the RayCast2D is not colliding, simply move
	elif !ray.is_colliding():
		position += dir * Globals.TILESIZE
		lastMoveDir = dir
		if currentState == playerState.IDLE:
			PlayerMoved.emit()


	checkForInteract()


# Called to attempt interaction with various objects when player is facing a collider
func interactWithRayCollider(collidingObj: Object) -> void:
	# - This expects a collision body as a child of a different node, like a Sprite2D, CharacterBody2D, or Area2D
	# - See the ZESwitch.tscn file for scene tree example
	if collidingObj is ZESwitchArea: # Is the object a Switch?
		thoughtBubble.hide()
		collidingObj.flipSwitch()
	if collidingObj is ZEBall:
		thoughtBubble.hide()
		collidingObj.move(facingDir)


# give feedback and state change dependent on terrain
func bodyEnter(body: Node2D) -> void:
	if body is TileMapLayer:
		var tilePos: Vector2i = body.local_to_map($GroundCheck.global_position)
		if body.get_cell_tile_data(tilePos).get_custom_data("Water"):
			# if in water, visual and audio cues before level call triggers
			SoundControl.resetMusicFade() # music stops on drown
			SoundControl.playCue(SoundControl.fail, 3.0)
			currentState = playerState.INWATER
			sprite.play("Drown")
		elif body.get_cell_tile_data(tilePos).get_custom_data("Ice"):
			if (!ray.is_colliding()):
				# if ice, audio cues and state change
				currentState = playerState.SLIDING
				$StepCue.stream = load(SLIPNOISE)
			else:
				# retrigger idle after stopping sliding movement
				currentState = playerState.IDLE
				sprite.play(dirToAnimationName[lastMoveDir])


# go back to idle when exiting area
func bodyExit(_body: Node2D) -> void:
	currentState = playerState.IDLE
	$StepCue.stream = load(STEPNOISE)


# check the ground to any area 2dAdd commentMore actions
func areaEnter(area: Area2D) -> void:
	# if on a ice corner prvent input by setting the state to CORNERSLIDING
	if area.get_collision_mask_value(4):
		currentState = playerState.CORNERSLIDING


# sets the thought bubble to reset
func showResetThought() -> void:
	# at some point we should check if last input was keyboard or controller
	thoughtBubble.show()
	thoughtBubble.play("ResetKB")


# sets the thought bubble to move
func showMoveThought() -> void:
	thoughtBubble.show()
	thoughtBubble.play("MoveKB")


# check if we should show the interact thought bubble
func checkForInteract() -> void:
	ray.force_raycast_update()
	thoughtBubble.hide()
	
	if ray.is_colliding():
		var collidingObj: Object = ray.get_collider()
		if collidingObj is ZESwitchArea:
			thoughtBubble.show()
			thoughtBubble.play("ActionKB")
		if collidingObj is ZEBall:
			thoughtBubble.show()
			thoughtBubble.play("ActionKB")


# this function reloads the level after the player's drown animation
func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "Drown":
		InWater.emit() # level reload call

	if "Walk" in sprite.animation: # repeat walk if moving or return to idle
		if moveTimer != 0: # return to idle from work
			walkStepAnimationQueue(facingDir)
		else:
			sprite.play(dirToAnimationName[facingDir])



# check to see if slide animation still running and if so, return to idle animation
func _on_animated_sprite_2d_frame_changed() -> void:
	if "Slide" in sprite.animation and currentState != playerState.SLIDING:
		sprite.play(dirToAnimationName[lastMoveDir])
