class_name ZESwitchArea extends Area2D


# Exported Variables
@export_category("Basic Switch Settings")
@export_enum("Buttons", "Lever", "Toggle") var switchStyle: String = "Lever" ## The chosen switch style.  Defaults to "Lever."  If auto-revert is enabled, an appropriate switch style is used instead.
@export_enum("Off:0", "On:1") var switchState: int = 0 ## The Switch's state; Off = 0 or On = 1.
@export_category("Auto-Revert Settings")
@export var autoRevert := false ## Does this switch revert to the previous state automatically?  If auto-revert is enabled, an appropriate switch style is used automatically.
@export var autoRevertTime := 5.0 ## Time elapse before autoRevert

# Additional Variables
var recentlySwitched := false ## Was this Switch recently switched?
var controlledChildren: Array[Node] = [] ## Array to store handles to controlled children

# Handles to child nodes
@onready var collider := $CollisionShape2D ## Handle to the Switch's collisionshape
@onready var sprite := $AnimatedSprite2D ## Handle to the Switch's sprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# If autoRevert is 'false,' set animation according to switchStyle
	if !autoRevert:
		sprite.animation = switchStyle
		sprite.frame = switchState
	# If autoRevert is 'true,' set animation according to switchState
	else:
		var aniName := switchStyle
		if switchState == 0:
			aniName += "Off"
		elif switchState == 1:
			aniName += "On"
		sprite.animation = aniName
	
	# Create an array of all objects controlled by this Switch
	for child in get_children():
		if child != collider && child != sprite:
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
