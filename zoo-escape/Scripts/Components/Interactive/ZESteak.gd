extends AnimatedSprite2D

@export var bonus : int = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(bodyEntered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# if the player enter the area delete itself
func bodyEntered(body: Node2D) -> void:
	if body.is_in_group("ZEPlayer"):
		var _oldScore = Globals.Game_Globals.get("player_score")
		Globals.Game_Globals.set("player_score",_oldScore+bonus)
		SoundControl.playSfx(SoundControl.pickup)
		queue_free()
