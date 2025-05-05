extends CharacterBody2D


const stepNoise = "res://Assets/Sound/deep_thump.ogg"
const slipNoise = "res://Assets/Sound/squelch.ogg"

enum PlayerState {
	Idle,
	InWater,
	OnExit,
	Sliding
}

@onready var dirToAnimtionName := {
	Vector2.UP: "IdleUp",
	Vector2.RIGHT: "IdleRight",
	Vector2.DOWN: "IdleDown",
	Vector2.LEFT: "IdleLeft"
}

@export var moveSpeed := 0.3
@export var stepMuffleLevel : int = 9 ## value to muffle footsteps
@onready var currentDir: Vector2 = Vector2.DOWN
@onready var sprite := $AnimatedSprite2D
@onready var ray := $RayCast2D
@onready var currentState: PlayerState = PlayerState.Idle
@onready var moveTimer := 0.0
@onready var lastMoveDir := Vector2.DOWN

signal InWater

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	$StepCue.volume_db = SoundControl.sfxLevel-stepMuffleLevel ## default player footsteps to low volume


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currentState == PlayerState.Idle:
		if Input.is_action_just_pressed("DigitalUp"):
			MovePlayer(Vector2.UP)
		elif Input.is_action_just_pressed("DigitalRight"):
			MovePlayer(Vector2.RIGHT)
		elif Input.is_action_just_pressed("DigitalDown"):
			MovePlayer(Vector2.DOWN)
		elif Input.is_action_just_pressed("DigitalLeft"):
			MovePlayer(Vector2.LEFT)
			
		if Input.is_action_pressed("DigitalUp") || Input.is_action_pressed("DigitalRight") || Input.is_action_pressed("DigitalDown") || Input.is_action_pressed("DigitalLeft"):
			moveTimer += delta
			
		if Input.is_action_just_released("DigitalUp") || Input.is_action_just_released("DigitalRight") || Input.is_action_just_released("DigitalDown") || Input.is_action_just_released("DigitalLeft"):
			moveTimer = 0
			
		if moveTimer >= moveSpeed:
			if Input.is_action_pressed("DigitalUp"):
				MovePlayer(Vector2.UP)
			elif Input.is_action_pressed("DigitalRight"):
				MovePlayer(Vector2.RIGHT)
			elif Input.is_action_pressed("DigitalDown"):
				MovePlayer(Vector2.DOWN)
			elif Input.is_action_pressed("DigitalLeft"):
				MovePlayer(Vector2.LEFT)
			
			moveTimer = 0
		
		if Input.is_action_pressed("ActionButton"):
			# Detect if "ray" is colliding with an object
			# - If so, try to interact
			if ray.is_colliding():
				InteractWithRayCollider(ray.get_collider())
	elif currentState == PlayerState.Sliding:
		moveTimer += delta
		
		if moveTimer >= moveSpeed:
			MovePlayer(lastMoveDir)
			moveTimer = 0
	
	if Globals.Current_Settings["passwordWindowOpen"] == true:
		get_tree().paused = true


# Called to move the player
func MovePlayer(dir: Vector2) -> void:
	var _pitch = randf_range(-0.25,0.25)
	$StepCue.pitch_scale = 1+_pitch
	$StepCue.play()

	sprite.play(dirToAnimtionName[dir])
	ray.target_position = dir * Globals.ZETileSize
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collidingObj: Object = ray.get_collider()
		if collidingObj is ZEBoxArea:
			if collidingObj.Move(dir):
				position += dir * Globals.ZETileSize
	elif !ray.is_colliding():
		$ZEHud.movesValue+=1
		position += dir * Globals.ZETileSize
		lastMoveDir = dir

# Called to attempt interaction with various objects when player is facing a collider
func InteractWithRayCollider(obj: Object) -> void:
	# Is colliding object interactable?
	# - This expects a collision body as a child of a different node, like a Sprite2D, CharacterBody2D, or Area2D
	# - See the ZESwitch.tscn file for scene tree example	
	if obj.is_in_group("ZEInteractable"):
		if obj is ZESwitch:
			obj.ChangeState()


func _on_ground_check_area_entered(area: Area2D) -> void:
	var layer := area.collision_layer
	
	if(layer == 2):
		$ZEHud.closeHud()
		SoundControl.playCue(SoundControl.fail,3.0)
		currentState = PlayerState.InWater
	
		# tell the level to restart
		InWater.emit()
	elif(layer == 4):
		if(!ray.is_colliding()):
			currentState = PlayerState.Sliding
			$StepCue.stream = load(slipNoise)
		else:
			currentState = PlayerState.Idle
		


func _on_ground_check_area_exited(_area: Area2D) -> void:
	currentState = PlayerState.Idle
	$StepCue.stream = load(stepNoise)
