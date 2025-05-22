class_name GameRoot extends Node2D

@onready var aniPlayer: AnimationPlayer = $AnimationPlayer
var title := load(Scenes.TITLE)
var settings := load(Scenes.SETTINGS)


func _ready() -> void:
	SceneManager.gameRoot = self
	aniPlayer.play("RESET")
	SoundControl.resetMusicFade() # reset music state
	Globals.currentGameData["player_score"] = 0


# Called to progress the game to the next sceene
func GoToNextScene(OldScene: Node, NewScene: PackedScene) -> void:
	# start the Fade out , close processing
	set_process_input(false)
	set_physics_process(false)
	aniPlayer.play("FadeOut")
	await aniPlayer.animation_finished # wait until animation finish before change
	
	OldScene.queue_free() # free old scene
	var newCurrentScene := NewScene.instantiate()
	add_child(newCurrentScene) # add new scene
	SceneManager.currentScene = newCurrentScene
	
	aniPlayer.play("FadeIn") # start animation
	await aniPlayer.animation_finished # and when it finishes
	set_process_input(true) # restore processing
	set_physics_process(true)


# Called to return to the game's Title scene
func ReturnToTitle() -> void:
	set_process_input(false) # end processing, just like new scene
	set_physics_process(false)
	aniPlayer.play("FadeOut")
	await aniPlayer.animation_finished

	get_tree().reload_current_scene()

	aniPlayer.play("FadeIn") # restore processing on animation end
	await aniPlayer.animation_finished
	set_process_input(true)
	set_physics_process(true)
