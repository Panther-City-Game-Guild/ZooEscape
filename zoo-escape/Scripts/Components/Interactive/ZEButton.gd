extends AnimatedSprite2D


enum buttonState { # Track the state of the switch: 0 = off, 1 = on
	OFF,
	ON
}

var controlledChildren: Array = [] # Array to store handles to controlled children in

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ButtonArea.area_entered.connect(areaEnter)
	$ButtonArea.area_exited.connect(areaExit)
	$ButtonArea.body_entered.connect(bodyEnter)
	$ButtonArea.body_exited.connect(bodyExit)
	
	frame = buttonState.OFF
	for child in self.get_children():
		if child != $ButtonArea:
			controlledChildren.append(child)

# Body entered the Button's Area
func bodyEnter(_body: Node2D) -> void:
		SoundControl.playCue(SoundControl.scratch,1.2)
		frame = buttonState.ON
		toggle_children()

# Body exited the Button's Area
func bodyExit(_body: Node2D) -> void:
		SoundControl.playCue(SoundControl.scratch,1.5)
		frame = buttonState.OFF
		toggle_children()

# for areas like box enter
func areaEnter(_area: Area2D) -> void:
	SoundControl.playCue(SoundControl.scuff,1.0)
	frame = buttonState.ON
	toggle_children()

# for areas like box exit
func areaExit(_area: Area2D) -> void:
	SoundControl.playCue(SoundControl.scuff,0.9)
	frame = buttonState.OFF
	toggle_children()

# Called to change the state of controlledChildren nodes
func toggle_children() -> void:
	if controlledChildren:
		for child: Node in controlledChildren:
			child.changeState()
