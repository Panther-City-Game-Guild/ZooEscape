class_name LevelManager extends Node2D


enum levelStates {
	IDLE,
	NORMAL,
	PRESCORE,
	SCORETIME,
	SCOREMOVES
}

@export var levelCode := "----" # stores as password
@export var timeLimit := 60 # level time limit relayed to hud
@export var warningTime := 15 # time out warning threshold
@export var exitBonus := 500 # points for winning the level
@export var timeBonus := 100 # bonus points per second remaining on the clock
@export var movePenalty := 25 # penalty for every move made
@export var isLevelTutorial := false # Is this a tutorial level?
@export var levelBgm := "res://Assets/Sound/Theme.ogg" # Background music for this level

var hud: Hud = preload(Scenes.HUD).instantiate() # instantiate a new hud when this level is initialized
var processDelay := 0.15 # how long to wait between rounds of time and move processing (should be around 0.15)
var elapsedTime := 0.0 # how long the level has been running (a level timer)
var timeLeft := 0 # how long before this level times out (rounded to nearest second)
var resetTime := 0.0 # how long the player has held the "RightBumper" action
var timesUp := false # has the level's time run out?
var hasPlayerMoved := false # has the player moved yet?
var score := 0 # the player's score for this level
var moveCount := 0 # number of moves player has made this level (gets reduced during score tally)
var totalMoves := 0 # number of moves player has made this level (does not get reduced during score tally)
var steakCount := 0 # number of steaks present in the level
var levelState := levelStates.NORMAL # The current state of the level

@onready var player := $Player # Handle to the player
@onready var exitTile := $ExitTile # Handle to the exitTile
@onready var nextLevel: String = exitTile.nextLevelCode # pointer for next scene string


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE # Allow the LevelManager to be paused when the scene tree is paused
	SceneManager.currentScene = self
	add_to_group("LevelManager")
	MenuManager.updatePassword(levelCode)
	MenuManager.RestartGame.connect(restartRoom)
	MenuManager.QuitGame.connect(quitGame)
	player.InWater.connect(restartRoom)
	player.PlayerMoved.connect(updateMoveCount)
	exitTile.PlayerExits.connect(exitLevel)
	
	# Set currentGameData in Globals
	if !Globals.currentGameData.gameRunning:
		Globals.currentGameData.gameRunning = true # Critical for MenuManager to work as intended in-game
	
	setupSteaks()
	setupHud()
	
	if isLevelTutorial:
		player.showMoveThought() # Show tutorial bubble if in tutorial stage
	
	SoundControl.musicFadeIn()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match levelState:
		# If done processing, exit early (wait for other processes to finish)
		levelStates.IDLE:
			return
		
		# Game Loop: Track level logic
		levelStates.NORMAL:
			# Track elapsed time, even for tutorial levels
			if hasPlayerMoved:
				elapsedTime += delta
			
			# If player has moved, player still has time, and not playing a tutorial
			if hasPlayerMoved && !timesUp && !isLevelTutorial:
				timeLeft = roundi(timeLimit - elapsedTime) # Calculate how much time is left, and update the HUD
				hud.updateTimeText(timeLeft)
					
				# If the remaining time is less than warning time, give warnings
				if timeLeft <= warningTime && timeLeft % 2 == 0:
					hud.giveTimeWarning()
				
				# If elapsedTime is greater than timeLimit, time's up!
				if elapsedTime >= timeLimit:
					timesUp = true
				
			# If time has run out, change processing mode and display Timeout window
			if timesUp:
				levelState = levelStates.IDLE
				hud.closeHud()
				MenuManager.setMenu(MenuManager.menuTypes.TIMEOUT)
			
			# If player just released "RightBumper," reset resetTime and hide resetBar
			if Input.is_action_just_released("RightBumper"):
				resetTime = 0
				hud.resetBarFade()
			
			# If player is pressing "RightBumper," show resetBar and update its value
			if Input.is_action_pressed("RightBumper") && !timesUp: # do not allow reload when time up!
				resetTime += delta
				hud.resetBarReveal()
				hud.resetBarUpdate(resetTime)
			
			# If resetTime has been met, reset the level
			if resetTime >= 2:
				levelState = levelStates.IDLE
				SoundControl.playCue(SoundControl.down, 2.0)
				hud.resetPrompt() # Update restartBar prompt on HUD
				restartRoom()
		
		# Score Pre-processing: Prepare to process SCORETIME and SCOREMOVES
		levelStates.PRESCORE:
			timeLimit -= roundi(elapsedTime)
			totalMoves = moveCount
			updateScore(exitBonus) # Apply exitBonus to score
			
			# If playing regular level, being score processing
			if !isLevelTutorial:
				levelState = levelStates.SCORETIME
			
			# if playing tutorial, wait for the next level to load
			else:
				levelState = levelStates.IDLE # Stop processing
				setHighScore()
				loadNextLevel()
		
		# Score processing: Add bonus points for remaining time
		levelStates.SCORETIME:
			if timeLimit > 0: # Timer adds bonus until zero
				timeLimit -= 1
				updateScore(timeBonus) # Adding bonus
				hud.updateTimeText(timeLimit)
				await get_tree().create_timer(processDelay).timeout # Create a small delay to visually count down
				return
			else:
				levelState = levelStates.SCOREMOVES # When done scoring time, score moves
		
		# Score processing: Subtract moveCount penalties from the score
		levelStates.SCOREMOVES:
			if moveCount > 0:
				moveCount -= 1
				updateScore(-movePenalty) # Subtracting penalty
				hud.updateMovesText(moveCount)
				await get_tree().create_timer(processDelay).timeout # Create a small delay to visually count down
				return
			else:
				levelState = levelStates.IDLE # Stop processing and wait for next level
				setHighScore()
				loadNextLevel()


# Initialize the HUD for this level
func setupHud() -> void:
	# Setup initial values on HUD
	hud.updateScoreText(score)
	hud.updatePasswordText(levelCode)
	hud.updateSteaksText(steakCount)
	hud.updateMovesText(moveCount)
	add_child(hud)


# Called to play some animations on the HUD when the player first moves (indicating level has begun)
func startLevel() -> void:
	if !isLevelTutorial:
		hud.playTimerStart() # If playing a regular level, set time value to "START" and play an icon animation
	else:
		hud.setTutorialText() # If playing a tutorial level, set the TimeValue text to "NONE"


# Updates the score with the provided value (can be positive or negative)
func updateScore(value) -> void:
	score += value
	if score < 0: # Score will not fall below zero
		score = 0
	hud.updateScoreText(score)


# Updates the moveCount variable
func updateMoveCount() -> void:
	if !hasPlayerMoved:
		hasPlayerMoved = true
		startLevel()
	
	moveCount += 1 # Update the move counter
	hud.updateMovesText(moveCount)


# Updates the steaksCollected variable
func steakCollected(value: int) -> void:
	steakCount -= 1
	hud.updateSteaksText(steakCount)
	updateScore(value)
	
	if steakCount <= 0: # If steakCount dropped to 0, activate the exitTile
		exitTile.activateExit()


# When a level loads count all steaks
func setupSteaks() -> void:
	var steaks := findChildrenInGroup("steaks")
	if steaks:
		steakCount = steaks.size()
		for steak: Steak in steaks:
			steak.Collected.connect(steakCollected)


# Find all children in a given group
func findChildrenInGroup(group := "", which: Node = self, arr := []) -> Array:
	for child in which.get_children():
		if child.is_in_group(group):
			arr.push_back(child)
		
		# If the child has children, see if that child has nodes in the group
		if child.get_children().size() >= 1:
			arr = findChildrenInGroup(group, child, arr)
	
	return arr


func setHighScore() -> void:
	if Globals.THRESHOLDS.has(levelCode) && Globals.THRESHOLDS[levelCode].size() == 3: # If threshold data exists, we can track score
		# After score tally, check the score values for this level to see if this score is higher
		var levelData: Array = Globals.highScores.get(levelCode, [])
		
		# Create new score entry
		var new_entry := [ score, round(elapsedTime *  100) / 100, totalMoves ]
		
		# Add new entry to levelData
		levelData.append(new_entry)
		
		# Sort levelData: descending by score, ascending by moves, ascending by time
		levelData.sort_custom(func(a, b):
			if a[0] != b[0]:
				return a[0] > b[0]  # Higher score comes first
			if a[2] != b[2]:
				return a[2] < b[2]  # Lower moves comes first if scores equal
			return a[1] < b[1]   # Lower time comes first if moves equal
		)
		
		# Keep only the top 3 entries
		if levelData.size() > 3:
			levelData.resize(3)
		
		# Update global high scores and save the data
		Globals.highScores[levelCode] = levelData
		Data.saveScoreData()



# Exit the level function - hold player, process score then go to next room
func exitLevel() -> void:
	player.endLevelAnimation() # trigger player win animation and prevent walk retrigger
	player.currentState = player.playerState.ONEXIT
	SoundControl.playCue(SoundControl.success, 2.0) # sound trigger
	levelState = levelStates.PRESCORE # The current state of the level


# Load the next level
func loadNextLevel() -> void:
	hud.closeHud()
	if nextLevel != Globals.PASSWORDS.find_key(Scenes.TITLE):
		SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[nextLevel])
	else:
		quitGame()


# Function to close hud
func restartRoom() -> void:
	hud.closeHud()
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[levelCode])


# Game quit function, returns to title scene
func quitGame() -> void:
	hud.closeHud()
	Globals.currentGameData.gameRunning = false
	SoundControl.resetMusicFade()
	SceneManager.call_deferred("goToNewSceneString", Scenes.TITLE)
