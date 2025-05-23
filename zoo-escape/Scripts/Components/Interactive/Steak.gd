extends AnimatedSprite2D


@export var bonus : int = 50  # The points for collecting a steak

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(bodyEntered)


# if the player enters the area delete itself
func bodyEntered(body: Node2D) -> void:
	if body.is_in_group("ZEPlayer"):
		Globals.scoreUpdate(bonus,true) # global score update
		SoundControl.playSfx(SoundControl.pickup) # global sound call
		queue_free()
