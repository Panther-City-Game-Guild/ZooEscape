class_name ZELevelManager extends Node2D

@export var LevelCode := "" ## stores as password
@export var LevelTime := 60 ## level time limit relayed to hud
@export var WarningTime := 15 ## time out warning threshold
@export var ExitScoreBonus := 500 ## local editor variables to effect bonuses
@export var PerSecondBonus := 100
@export var PerMovePenalty := 25
@export var TutorialScoreBypass := false
@onready var player := $Player
@onready var exitTile := $ExitTile
@onready var steakManager := $SteakManager
@onready var resetTime := 0.0
@onready var nextLevel: String = exitTile.nextLevelCode # pointer for next scene string
var loadingScore: Variant = Globals.currentGameData.get("player_score") # compare score for reloads
var localHud: Control # pointer for hud
var timeUp := false # to monitor local hud timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !AudioServer.is_bus_mute(3) or SoundControl.bgmLevel > -20:
		SoundControl.resetMusicFade() # reset music state
	player.InWater.connect(restartRoom)
	exitTile.PlayerExits.connect(exitLevel)
	steakManager.AllSteaksCollected.connect(allSteaksCollected)
	Globals.currentGameData.set("time_limit", LevelTime)
	Globals.currentGameData.set("warning_threshold", WarningTime)
	
	# check to ensure bgm fade level is consistent
	# if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER
	
	# connect hud to scene change and score process functions
	localHud = get_node("Player/ZEHud")
	if localHud != null:
		localHud.restart_room.connect(restartRoom)
		localHud.exit_game.connect(exitGame)
		localHud.score_processed.connect(nextRoom)
		# update global data report and local UI feedback
		localHud.timeLimit = Globals.currentGameData.get("time_limit")
		localHud.warningTime = Globals.currentGameData.get("warning_threshold")
		localHud.timerValue = localHud.timeLimit
		localHud.secondBonus = PerSecondBonus
		localHud.movePenalty = PerMovePenalty
		localHud.passwordReport(str(LevelCode))
	else:
		var _settings = get_node("ZESettings")
		_settings.escapePressed.connect(exitGame)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timeUp = localHud.timesUp # watch timer
	localHud.resetGauge = resetTime # compare gauge with HUD meter
	localHud.password = str(LevelCode) # update hud password text
	
	if Input.is_action_pressed("RightBumper") and !timeUp:
		resetTime += delta # do not allow reload when time up!
		if !localHud.resetBarVisible: # show bar
			localHud.resetBarReveal()
	
	if Input.is_action_just_released("RightBumper"):
		resetTime = 0 # fade bar and reset
		if localHud.resetBarVisible:
			localHud.resetBarFade()
	
	if resetTime > 2:
		resetTime = -10 # added to avoid crash from input overload
		timeUp = true # flip cursor to avoid retriggering
		SoundControl.playCue(SoundControl.down, 2.0)
		localHud.resetPrompt() # prompt updates on hud
		restartRoom()


# TODO: Need descriptive comment here
func exitLevel() -> void:
	player.currentState = player.playerState.ONEXIT
	SoundControl.playCue(SoundControl.success, 2.0) # sound trigger
	if !TutorialScoreBypass: # process score before exit
		localHud.scoreProcessState = 1
	else: # if tutorial, do not apply score bonuses/penalties
		nextRoom()


# load next level
func nextRoom():
	if nextLevel != str(SceneManager.gameRoot.title):
		SceneManager.call_deferred("GoToNewSceneString", Globals.PASSWORDS[nextLevel])
	else:
		Globals.currentGameData.set("player_score", 0)
		exitGame()


# update score and apply exit score and bonus
func allSteaksCollected() -> void:
	exitTile.activateExit()
	var _old = Globals.currentGameData.get("player_score")
	Globals.currentGameData.set("player_score", (_old + ExitScoreBonus))


# function to close hud and compare original score before reloading the level
func restartRoom() -> void:
	localHud.closeHud()
	var _score = Globals.currentGameData.get("player_score")
	if _score != loadingScore:
		Globals.currentGameData.set("player_score", loadingScore)
	SceneManager.call_deferred("GoToNewSceneString", Globals.PASSWORDS[LevelCode])


# game exit function, refers to gameroot function
func exitGame() -> void:
	Globals.currentGameData.set("player_score", 0) # reset score to zero on exit
	var _root = get_parent()
	_root.ReturnToTitle()
	
