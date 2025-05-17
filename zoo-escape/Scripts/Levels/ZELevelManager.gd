class_name ZELevelManager extends Node2D

@export var LevelCode := "" ## stores as password
@export var LevelTime := 60 ## level time limit relayed to hud
@export var WarningTime := 15 ## time out warning threshold
@export var ExitScoreBonus := 500 ## local editor variables to effect bonuses
@export var PerSecondBonus := 100
@export var PerMovePenalty := 25
@export var TutorialScoreBypass := false
@onready var player := $Player
@onready var resetTime := 0.0
@onready var nextLevel: String = $ExitTile.NextLevelCode ## pointer for next scene string
var loadingScore = Globals.Game_Globals.get("player_score") ## compare score for reloads
var localHud = null ## pointer for hud
var timeUp := false ## to monitor local hud timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.Current_Level_Data.set("time_limit", LevelTime)
	Globals.Current_Level_Data.set("warning_threshold", WarningTime)
	## check to ensure bgm fade level is consistent
	## if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER

	## connect hud to scene change and score process functions

	localHud = get_node("Player/ZEHud")
	if localHud != null:
		localHud.RestartRoom.connect(restartRoom)
		localHud.ExitGame.connect(exitGame)
		localHud.ScoreProcessed.connect(nextRoom)
		## update global data report and local UI feedback
		localHud.timeLimit = Globals.Current_Level_Data.get("time_limit")
		localHud.warningTime = Globals.Current_Level_Data.get("warning_threshold")
		localHud.timerValue = localHud.timeLimit
		localHud.secondBonus = PerSecondBonus
		localHud.movePenalty = PerMovePenalty
		localHud.passwordReport(str(LevelCode))
	else:
		var _settings = get_node("ZESettings")
		_settings.escapePressed.connect(exitGame)

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
		SoundControl.playCue(SoundControl.down, 2.0)
		localHud.resetPrompt() ## prompt updates on hud
		restartRoom()
	
	
func _on_exit_tile_player_exits() -> void:
	SoundControl.playCue(SoundControl.success, 2.0) ## sound trigger
	if !TutorialScoreBypass: ## process score before exit
		localHud.scoreProcessState = 1
	else: ## if tutorial, do not apply score bonuses/penalties
		nextRoom()


func nextRoom(): ## load next level
	player.currentState = player.playerState.ONEXIT
	if nextLevel != str(SceneManager.gameRoot.title):
		SceneManager.call_deferred("GoToNewSceneString", Globals.Game_Globals[nextLevel])
	else:
		Globals.Game_Globals.set("player_score", 0)
		exitGame()

func _on_steak_manager_all_steak_collected() -> void:
	$ExitTile.ActavateExit() ## update score and apply exit score open bonus
	var _old = Globals.Game_Globals.get("player_score")
	Globals.Game_Globals.set("player_score", (_old + ExitScoreBonus))


func restartRoom() -> void:
	localHud.closeHud() ## close hud and compare original score before reload
	var _score = Globals.Game_Globals.get("player_score")
	if _score != loadingScore:
		Globals.Game_Globals.set("player_score", loadingScore)
	SceneManager.call_deferred("GoToNewSceneString", Globals.Game_Globals[LevelCode])


func exitGame() -> void: ## game exit function, refers to gameroot function
	Globals.Game_Globals.set("player_score", 0) ## reset score to zero on exit
	var _root = get_parent()
	_root.ReturnToTitle()


func _on_player_in_water() -> void:
	restartRoom()
