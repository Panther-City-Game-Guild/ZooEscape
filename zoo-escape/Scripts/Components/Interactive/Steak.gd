extends AnimatedSprite2D


@export var bonus : int = 50  # The points for collecting a steak

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(bodyEntered)


# if the player enter the area delete itself
func bodyEntered(body: Node2D) -> void:
	if body.is_in_group("ZEPlayer"):
		var _oldScore : int = Globals.currentGameData.get("player_score") # QUERY: Should scoring be handled by a steak or by a more significant node, such as the GameRoot?
		Globals.currentGameData.set("player_score",_oldScore + bonus)
		SoundControl.playSfx(SoundControl.pickup)
		queue_free()
