extends CharacterBody2D

const STEPNOISE := "res://Assets/Sound/deep_thump.ogg"
const SLIPNOISE := "res://Assets/Sound/squelch.ogg"

enum playerState {
	IDLE,
	INWATER,
	ONEXIT,
	SLIDING
}

@onready var dirToAnimtionName := {
	Vector2.UP: "IdleUp",
	Vector2.RIGHT: "IdleRight",
	Vector2.DOWN: "IdleDown",
	Vector2.LEFT: "IdleLeft"
}

@export var moveSpeed := 0.3
@export var stepMuffleLevel := 9 # value to muffle footsteps
@onready var currentDir := Vector2.DOWN
@onready var sprite := $AnimatedSprite2D
@onready var ray := $RayCast2D
@onready var currentState := playerState.IDLE
@onready var moveTimer := 0.0
@onready var lastMoveDir := Vector2.DOWN

signal InWater

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	$StepCue.volume_db = SoundControl.sfxLevel-stepMuffleLevel # default player footsteps to low volume
	$GroundCheck.body_entered.connect(bodyEnter)
	$GroundCheck.body_exited.connect(bodyExit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currentState == playerState.IDLE:
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
		
		if moveTimer >= moveSpeed:
			movePlayer(lastMoveDir)
			moveTimer = 0
	
	if Globals.currentAppState["passwordWindowOpen"] == true:
		get_tree().paused = true # NOTE: This should be happening at a higher level in the scene tree


# Called to move the player
func movePlayer(dir: Vector2) -> void:
	var _pitch = randf_range(-0.25, 0.25)
	$StepCue.pitch_scale = 1 + _pitch
	$StepCue.play()
	
	# Change the direction the Player is facing
	sprite.play(dirToAnimtionName[dir])
	ray.target_position = dir * Globals.TILESIZE
	ray.force_raycast_update()
	
	# After changing the direction the Player is facing,
	# if the Player's RayCast2D is colliding, do logic
	if ray.is_colliding():
		var collidingObj: Object = ray.get_collider()
		if collidingObj is ZEBoxArea or collidingObj is ZEBall:
		# If the collider is a Box, try to move the Box and the Player
			if collidingObj.move(dir):
				$ZEHud.movesValue += 1
				position += dir * Globals.TILESIZE
	
	# Otherwise, if the RayCast2D is not colliding, simply move
	elif !ray.is_colliding():
		$ZEHud.movesValue += 1
		position += dir * Globals.TILESIZE
		lastMoveDir = dir


# Called to attempt interaction with various objects when player is facing a collider
func interactWithRayCollider(collidingObj: Object) -> void:
	# - This expects a collision body as a child of a different node, like a Sprite2D, CharacterBody2D, or Area2D
	# - See the ZESwitch.tscn file for scene tree example
	if collidingObj is ZESwitchArea: # Is the object a Switch?
		collidingObj.flipSwitch()


# do stuff depending on what you step on. 
func bodyEnter(body: Node2D) -> void:
	if body is TileMapLayer:
		var tilePos: Vector2i = body.local_to_map($GroundCheck.global_position)
		if body.get_cell_tile_data(tilePos).get_custom_data("Water"):
			$ZEHud.closeHud()
			SoundControl.playCue(SoundControl.fail,3.0)
			currentState = playerState.INWATER
		
			# tell the level to restart
			InWater.emit()
		elif body.get_cell_tile_data(tilePos).get_custom_data("Ice"):
			if(!ray.is_colliding()):
				currentState = playerState.SLIDING
				$StepCue.stream = load(SLIPNOISE)
			else:
				currentState = playerState.IDLE


# go back to idle when exiting area
func bodyExit(_body: Node2D) -> void:
	currentState = playerState.IDLE
	$StepCue.stream = load(STEPNOISE)
