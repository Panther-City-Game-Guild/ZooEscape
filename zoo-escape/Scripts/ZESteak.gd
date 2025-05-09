extends AnimatedSprite2D

@export var bonus : int = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("ZEPlayer"):
		var _oldScore = Globals.Game_Globals.get("player_score")
		Globals.Game_Globals.set("player_score",_oldScore+bonus)
		SoundControl.playSfx(SoundControl.pickup)
		queue_free()
