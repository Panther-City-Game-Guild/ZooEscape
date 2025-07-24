@tool
extends Node2D

@export_enum("TopLeft", "TopRight", "BottomLeft", "BottomRight") var cornerPos := "TopLeft"


func _ready() -> void:
	$AnimatedSprite2D.play(cornerPos)
	$Area2D.body_entered.connect(bodyEntered)


func bodyEntered(body: Node2D) -> void:
	if body is Player:
		var lastDir: Vector2 = body.lastMoveDir
		
		match cornerPos:
			"TopLeft": 
				if lastDir == Vector2.UP:
					body.movePlayer(Vector2.RIGHT)
				else:
					body.movePlayer(Vector2.DOWN)
			"TopRight": 
				if lastDir == Vector2.UP:
					body.movePlayer(Vector2.LEFT)
				else:
					body.movePlayer(Vector2.DOWN)
			"BottomLeft": 
				if lastDir == Vector2.DOWN:
					body.movePlayer(Vector2.RIGHT)
				else:
					body.movePlayer(Vector2.UP)
			"BottomRight": 
				if lastDir == Vector2.DOWN:
					body.movePlayer(Vector2.LEFT)
				else:
					body.movePlayer(Vector2.UP)
