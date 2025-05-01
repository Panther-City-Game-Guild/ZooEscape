class_name ZELevelManager extends Node2D

@export var LevelCode: String = "" ## stores as password
@export var LevelTime: int = 60  ## level time limit relayed to hud
@export var WarningTime : int = 15 ## time out warning threshold
@onready var player := $Player
@onready var resetTime := 0.0
var localHud = null ## pointer for hud
var timeUp : bool = false ## to monitor local hud timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.Current_Level_Data.set("time_limit",LevelTime)
	Globals.Current_Level_Data.set("warning_threshold",WarningTime) 
	## check to ensure bgm fade level is consistent
	## if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER

	## connect hud to scene change functions
	localHud = get_node("Player/ZEHud")
	localHud.restart_room.connect(restartRoom)
	localHud.exit_game.connect(exitGame)
	localHud.timeLimit = Globals.Current_Level_Data.get("time_limit")
	localHud.warningTime = Globals.Current_Level_Data.get("warning_threshold")
	localHud.timerValue = localHud.timeLimit



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timeUp = localHud.timesUp ## watch timer
	localHud.resetGauge = resetTime ## compare gauge with HUD meter
	localHud.password = str(LevelCode) ## update hud password text


	if Input.is_action_pressed("RightBumper") and !timeUp:
		resetTime += delta ## do not allow reload when time up!
		if !localHud.resetBarVisible: ## show bar
			localHud.resetBarReveal()


	if Input.is_action_just_released("RightBumper"):
		resetTime = 0 ## fade bar and reset
		if localHud.resetBarVisible:
			localHud.resetBarFade()


	if resetTime > 2:
		resetTime = -10 ## added to avoid crash from input overload
		timeUp = true ## flip cursor to avoid retriggering
		SoundControl.playCue(SoundControl.down,2.0)
		localHud.resetPrompt() ## prompt updates on hud
		restartRoom()
	
	


func _on_exit_tile_player_exits(LevelToGoTo: String) -> void:
	localHud.closeHud() ## close hud
	SoundControl.playCue(SoundControl.success,2.0) ## sound trigger
	player.currentState = player.PlayerState.OnExit
	SceneManager.call_deferred("GoToNewSceneString",self, Globals.Game_Globals[LevelToGoTo])


func _on_steak_manager_all_steak_collected() -> void:
	$ExitTile.ActavateExit()


func restartRoom() -> void:
	localHud.closeHud()
	SceneManager.call_deferred("GoToNewSceneString",self, Globals.Game_Globals[LevelCode])


func exitGame() -> void: ## game exit function, refers to gameroot function
	var _root = get_parent()
	_root.ReturnToTitle()


func _on_player_in_water() -> void:
	localHud.closeHud()
	SceneManager.call_deferred("GoToNewSceneString",self, Globals.Game_Globals[LevelCode])
