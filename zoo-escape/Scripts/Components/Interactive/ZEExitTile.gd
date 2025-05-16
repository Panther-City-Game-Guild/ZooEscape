extends AnimatedSprite2D

@export var NextLevelCode := "9990"
signal PlayerExits()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(bodyEntered)
	$OpenCue.volume_db = SoundControl.cueLevel ## has own sound for solo trigger

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# play the animation and audio cue
func activateExit() -> void:
	$OpenCue.play()
	play("Active")
	
# if the player enters the and the exit tile is active tell the level to go to the next level
func bodyEntered(body: Node2D) -> void:
	if animation == "Active" && body.is_in_group("ZEPlayer"):
		PlayerExits.emit()
