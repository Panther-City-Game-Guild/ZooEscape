class_name ZELevelManager extends Node2D

@export var levelCode := "" # stores as password
@export var levelTime := 60 # level time limit relayed to hud
@export var warningTime := 15 # time out warning threshold
@export var exitScoreBonus := 500 # local editor variables to effect bonuses
@export var perSecondBonus := 100
@export var perMovePenalty := 25
@export var tutorialScoreBypass := false
@onready var player := $Player
@onready var exitTile := $ExitTile
@onready var steakManager := $SteakManager
@onready var resetTime := 0.0
@onready var nextLevel: String = exitTile.nextLevelCode # pointer for next scene string
var loadingScore: Variant = Globals.currentGameData.get("player_score") # compare score for reloads
var localHud = null # pointer for hud
var localPassword = null # pointer for password
var localSettings = null # pointer for settings
var timeUp := false # to monitor local hud timer
@export var levelBgm := "res://Assets/Sound/Theme.ogg"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.currentScene = self
	self.add_to_group("LevelManager")
	player.InWater.connect(restartRoom)
	exitTile.PlayerExits.connect(exitLevel)
	steakManager.AllSteaksCollected.connect(allSteaksCollected)
	hudFetch()
	
	# check to ensure bgm fade level is consistent
	# if bgm fade level not normal, reset fade state so it fades in
	if SoundControl.fadeState != SoundControl.FADE_STATES.PEAK_VOLUME or SoundControl.currentBgm != levelBgm:
		SoundControl.fadeState = SoundControl.FADE_STATES.IN_TRIGGER
	
	
## this function grabs the hud elements and adds them to the level
func hudFetch() -> void:
	var _loadHud = load(Scenes.HUD)
	var _newHud = _loadHud.instantiate()
	get_tree().current_scene.add_child(_newHud)
	localHud = _newHud
	hudUpdate()
	passwordFetch()
	settingsFetch()


## this function loads and connects hud with signals and needed game variables
func hudUpdate() -> void:
	localHud.restart_room.connect(restartRoom)
	localHud.exit_game.connect(exitGame)
	localHud.score_processed.connect(nextRoom)
	# update global data report and local UI visual feedback
	localHud.timeLimit = int(levelTime)
	localHud.warningTime = int(warningTime)
	localHud.timerValue = int(levelTime)
	localHud.secondBonus = int(perSecondBonus)
	localHud.movePenalty = int(perMovePenalty)
	localHud.passwordReport(str(levelCode))
	if tutorialScoreBypass == true:
		localHud.tutorialMode = true
	## grab the player and point them to the hud
	var currentPlayer = get_tree().get_first_node_in_group("Player")
	currentPlayer.localHud = localHud


## this function pulls up the password window when needed
func passwordFetch() -> void:
	var _loadWindow = load(Scenes.PASSWORD)
	var _newWindow = _loadWindow.instantiate()
	get_tree().current_scene.add_child(_newWindow)
	_newWindow.inGameMode = true
	localPassword = _newWindow


## and this grabs the settings window when needed
func settingsFetch() -> void:
	var _check = get_tree().get_nodes_in_group("Settings")
	if _check.size()==0:
		var _loadSettings = load(Scenes.SETTINGS)
		var _newSettings = _loadSettings.instantiate()
		get_tree().current_scene.add_child(_newSettings)
		localSettings = _newSettings
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if localHud != null:
		timeUp = localHud.timesUp # watch timer
		localHud.resetGauge = resetTime # compare gauge with HUD meter
		localHud.password = str(levelCode) # update hud password text
	
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


# exit the level function - hold player, process score then go to next room
func exitLevel() -> void:
	player.currentState = player.playerState.ONEXIT
	SoundControl.playCue(SoundControl.success, 2.0) # sound trigger
	if !tutorialScoreBypass: # process score before exit
		localHud.scoreProcessState = 1
	else: # if tutorial, do not apply score bonuses/penalties
		nextRoom()


# load next level and free previous hud elements
func nextRoom() -> void:
	if nextLevel != "9990":
		hudClosing()
		SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[nextLevel])
	else:
		exitGame()


# this function is to free hud elements or they will not overlay or place correctly
# and to prevent stack overflow of hud scenes
func hudClosing() -> void:
	localHud.queue_free()
	localPassword.queue_free()
	localSettings.queue_free()
	Globals.currentAppState.set("passwordWindowOpen", false)
	Globals.currentAppState.set("settingsWindowOpen", false)



# update score and apply exit score and bonus
func allSteaksCollected() -> void:
	exitTile.activateExit()
	Globals.scoreUpdate(exitScoreBonus, true)


# function to close hud and compare original score before reloading the level
func restartRoom() -> void:
	localHud.closeHud()
	var _score : int = Globals.currentGameData.get("player_score")
	if _score != loadingScore: ## load score from first level boot
		Globals.currentGameData.set("player_score", loadingScore)
	hudClosing()
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[levelCode])


# game exit function, returns to title after cleaming out hud
func exitGame() -> void:
	Data.saveGameData()
	hudClosing()
	SceneManager.goToTitle()
