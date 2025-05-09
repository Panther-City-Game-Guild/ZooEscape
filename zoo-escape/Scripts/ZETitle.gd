extends Node2D

@onready var newGamePos := Vector2(272, 240)
@onready var passwordPos := Vector2(272, 264)
@onready var selector := $Selector

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selector.position = newGamePos
	setLevelGlobals()
	SoundControl.resetMusicFade() ## reset music state
	SceneManager.currentScene = self

# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# TODO: Tell player that the "ActionButton" is <Z>, etc.
	# NOTE: Had to re-add the "ui_accept" action to allow keyboard use, as <Enter> and <Space> do not work with "ActionButton"
	if event.is_action_pressed("ActionButton"):
		if selector.position == newGamePos:
			SoundControl.playCue(SoundControl.start,1.0)
			SceneManager.GoToNewSceneString(Scenes.ZETutorial1)
			Globals.Game_Globals.set("player_score",0)
			### change bgm and fade on out
			SoundControl.levelChangeSoundCall(1.0,SoundControl.defaultBgm)
		elif selector.position == passwordPos:
			SceneManager.GoToNewSceneString(Scenes.ZEPassword)
			
	if Input.is_action_just_pressed("DigitalDown") || Input.is_action_just_pressed("DigitalUp"):
		swapSelectorPos()


func swapSelectorPos() -> void:
	if selector.position == newGamePos:
		selector.position = passwordPos
	else: 
		selector.position = newGamePos


func setLevelGlobals() -> void:
	# debug levels
	Globals.Game_Globals["9990"] = Scenes.ZETitle
	Globals.Game_Globals["9991"] = Scenes.ZEDebug
	Globals.Game_Globals["9992"] = Scenes.ZEDebug2
	
	# Real Levels
	Globals.Game_Globals["0001"] = Scenes.ZETutorial1
	
	Globals.Game_Globals["0387"] = Scenes.ZELevel1
	# Globals.Game_Globals["9102"] = 
	# Globals.Game_Globals["1476"] = 
	# Globals.Game_Globals["5829"] = 
	# Globals.Game_Globals["0053"] = 
	
	# Globals.Game_Globals["7618"] = 
	# Globals.Game_Globals["2940"] = 
	# Globals.Game_Globals["8365"] = 
	# Globals.Game_Globals["0721"] = 
	# Globals.Game_Globals["6594"] = 
	
	# Globals.Game_Globals["3082"] = 
	# Globals.Game_Globals["9817"] = 
	# Globals.Game_Globals["4250"] = 
	# Globals.Game_Globals["1639"] = 
	# Globals.Game_Globals["7048"] = 
	
	# Globals.Game_Globals["2561"] = 
	# Globals.Game_Globals["8934"] = 
	# Globals.Game_Globals["0195"] = 
	# Globals.Game_Globals["5473"] = 
	# Globals.Game_Globals["3706"] = 
