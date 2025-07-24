extends AnimatedSprite2D


@export var nextLevelCode := "9990"
signal PlayerExits()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if nextLevelCode != "9990" && SoundControl.levelsBgm.has(nextLevelCode): # report next level bgm to sound control
		SoundControl.nextBgm = SoundControl.levelsBgm[nextLevelCode]
	else:
		SoundControl.nextBgm = SoundControl.defaultBgm # defaults so fade out instead of bug at end
	$Area2D.body_entered.connect(bodyEntered)


# play the animation and audio cue, glow activates
func activateExit() -> void:
	$OpenCue.play()
	play("Active")
	self.modulate = Color(1.3,1.3,1.3,1)


# if the player enters the and the exit tile is active tell the level to go to the next level
func bodyEntered(body: Node2D) -> void:
	if animation == "Active" && body.is_in_group("Player"):
		PlayerExits.emit()
		SoundControl.musicFadeOut()
