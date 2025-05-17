class_name ZESwitchArea extends Area2D

@export_category("Default State")
@export_enum("OFF:0", "ON:1") var switchState: int = 0 ## The Switch's state; Off = 0 or On = 1
@export_category("Auto-Revert Settings")
@export var autoRevert := false ## Does this switch revert to the previous state automatically?
@export_enum("Buttons:0", "Toggle:2") var switchStyle: int = 0 ## If auto-revert is enabled, style of the auto-reverting switch
@export var autoRevertTime := 5.0 ## Time elapse before autoRevert
var recentlySwitched := false ## Was this Switch recently switched?
var controlledChildren: Array[Node] = [] ## Array to store handles to controlled children
@onready var sprite := $AnimatedSprite2D ## Handle to the Switch's sprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if autoRevert:
		sprite.animation = switchStyle
	sprite.frame = switchState
	for child in get_children():
		if child != $CollisionShape2D && child != $AnimatedSprite2D:
			controlledChildren.append(child)


# Called to change the state of this switch
func set_switch_state(newState: int) -> void:
			switchState = newState
			sprite.frame = switchState
			toggle_children()


# Called to change the state of controlledChildren nodes
func toggle_children() -> void:
	if controlledChildren:
			for child: Node in controlledChildren:
				# Set some variable / property -- replace below as needed
				child.changeState()


# Called to retrieve the state of this switch
func get_switch_state() -> int:
	return switchState


# Externally accessible function called by the player
func flipSwitch() -> void:
	if !autoRevert:
		set_switch_state(!switchState)
	else:
		if !recentlySwitched:
			# Prevent Switch from being toggled before revert timer
			recentlySwitched = true
			set_switch_state(!switchState)
			# Set timer for auto reversion, then revert
			await get_tree().create_timer(autoRevertTime, false, false, false).timeout
			recentlySwitched = false
			set_switch_state(!switchState)
		else:
			print("Cannot operate switch right now!")
