extends AnimatedSprite2D

@export var NextLevelCode: String

signal PlayerExits(LevelToGoTo: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$OpenCue.volume_db = SoundControl.sfxLevel ## has own sound for solo trigger
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func ActavateExit() -> void:
	$OpenCue.play()
	play("Active")
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if animation == "Active" && body.is_in_group("ZEPlayer"):
		PlayerExits.emit() ## emit signal no longer needs level data
