class_name ZESwitchArea extends Area2D

# Enums
enum switchStates {
	OFF,
	ON
}

# Exported Variables
@export_category("Basic Switch Settings")
@export_enum("Buttons", "Lever", "Toggle") var switchStyle := "Lever" ## The chosen switch style.  Defaults to "Lever."  If auto-revert is enabled, an appropriate switch style is used instead.
@export var switchState := switchStates.OFF ## The Switch's state; Off = 0 or On = 1.
@export_category("Auto-Revert Settings")
@export var autoRevert := false ## Does this switch revert to the previous state automatically?  If auto-revert is enabled, an appropriate switch style is used automatically.
@export_range(0.5, 60.0, 0.1) var autoRevertTime := 3.0 ## Time elapse before autoRevert; Minimum: 0.5, Maximum: 60.0

# Additional Variables
var recentlySwitched := false ## Was this Switch recently switched?
var revertTimer := 0.0 ## Track the time until the switch auto-Reverts
var controlledChildren: Array[Node] = [] ## Array to store handles to controlled children
var frameCount := 0 ## Track how many frames are in the animation when using an autoRevert Switch

# Handles to child nodes
@onready var collider := $CollisionShape2D ## Handle to the Switch's collisionshape
@onready var sprite := $AnimatedSprite2D ## Handle to the Switch's sprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# If not autoRevert, set animation according to switchStyle
	if !autoRevert:
		sprite.animation = switchStyle
		sprite.frame = switchState
	# If autoRevert, build a String to set animation according to (switchStyle + switchState)
	else:
		sprite.animation = switchStyle + str(switchStates.find_key(switchState))
		
		# Determine how many frames are in the animation
		frameCount = sprite.sprite_frames.get_frame_count(sprite.animation)
	
	# Create an array of all objects controlled by this Switch
	for child in get_children():
		if child != collider && child != sprite:
			controlledChildren.append(child)


# Called every render frame
func _process(delta: float) -> void:
	# If not autoRevert, exit early
	if !autoRevert:
		return
	
	# If autoRevert and recentlySwitched, do logic based on revertTimer as percentage of autoRevertTime
	if autoRevert && recentlySwitched:
		# If revertTimer is less than autoReverTime
		if revertTimer < autoRevertTime:
			# Add "delta" time to revertTime
			revertTimer += delta
			
			# Calculate progress through autoRevertTime
			var progress := revertTimer / autoRevertTime
			
			# Determine which frame index to display
			var frameIdx := roundi(progress * (frameCount - 2)) + 1
			
			# Set the sprite's frame to the frame index
			sprite.frame = frameIdx
		
		# If revertTimer greater than or equal to autoRevertTime, revert state and children
		else:
			setSwitchState(!switchState)
			recentlySwitched = false
			revertTimer = 0
			sprite.frame = 0


# Called to change the state of the Switch
func setSwitchState(newState: int) -> void:
	if newState == 0:
		switchState = switchStates.OFF
	else:
		switchState = switchStates.ON
	toggleChildren()
	if !autoRevert:
		sprite.frame = switchState


# Called to change the state of nodes in the controlledChildren array
func toggleChildren() -> void:
	if controlledChildren:
			for child: Node in controlledChildren:
				# Set some variable / property -- replace below as needed
				child.changeState()


# Called to retrieve the state of this switch
func getSwitchState() -> int:
	return switchState


# Called by the Player script (typically) to tell the Switch to change its state
func flipSwitch() -> void:
	# If Switch is not autoRevert, change state
	if !autoRevert:
		setSwitchState(!switchState)
	
	# If Switch is autoRevert, determine if recently used
	else:
		# If not recently used, change state
		if !recentlySwitched:
			# Prevent Switch from being toggled before revert timer
			recentlySwitched = true
			setSwitchState(!switchState)
		
		# If reecently used, do nothing
		else:
			# TODO: Play a type of "bzzzt" sound to indicate switch is busy
			return
