class_name ZEHud extends Control


signal restart_room # reload signal
signal exit_game # exit to title signal
signal score_processed # score processing signal for process score

enum FOCUS_STATES {
	RESTART,
	EXIT
}

enum SCORE_PROCESS_STATES {
	IDLE,
	TIME_PROCESS,
	MOVE_PROCESS,
	POST
}

var steakValue := 1 # live monitor of steak total
var timerValue := 1 # live monitor of timer
var movesValue := 0 # live monitor of moves
var scoreCurrent := 0  # player score
var secondBonus := 50 # values for abstraction from parent to apply
var movePenalty := 25 # score penalty per move
var moveMonitoring := false # shows timer has started
var timesUp := false # shows time is out
var allSteaksCollected := false # shows goal is open
var resetBarVisible := false # reset bar flag for external reference
var resetGauge := 0.0 # to compare with level manager
var password := "ABCD" # abstraction for password
var warningTime := 10 # value when warning cues
var timeLimit := 30 # value to change for each level
var scoreProcessState := SCORE_PROCESS_STATES.IDLE # state of score process function at level end
var focusState := 0 # state of time out window ui focus
var passwordState := false # shows password window is open
var tutorialMode := false # tutorial mode state (goes to hud)



# Runs at the start set up
func _ready() -> void: # reset animations at ready, fetch start values
	self.add_to_group("hud")
	$HUDAnimation.play("RESET")
	$HUDAnimationAlt.play("RESET")
	$HudWindow/TimerValue.text = str(timeLimit) + "s" # update value at start
	steakValueFetch()
	timeCheck()
	# to avoid queueing error on prompt
	$OpenCue.volume_db = SoundControl.cueLevel
	$AlertCue.volume_db = SoundControl.cueLevel
	scoreCurrent = Globals.currentGameData.get("player_score")
	passwordState = Globals.currentAppState.get("passwordWindowOpen")


## double check value vs globals
func timeCheck() -> void:
	var _manager : Node = get_parent().get_parent() # get level manager root
	var _timeCheck : int = _manager.levelTime # check time
	var _warningCheck : int = _manager.warningTime # check warning
	if timeLimit != _timeCheck: # update if needed
		timeLimit = _timeCheck
	if warningTime != _warningCheck:
		warningTime = _warningCheck


# Runs every frame
func _process(_delta: float) -> void:
	$SettingsButton/GearSprite.play("default") # play gear sprite animation
	# monitor password state to hold hud move monitoring
	passwordState = Globals.currentAppState["passwordWindowOpen"]
	scoreCurrent = Globals.currentGameData.get("player_score")
	$HudWindow/ScoreValue.text = str(scoreCurrent)
	# fetch password from level manager and update
	$TimeOutCurtain/PasswordBox/PasswordLabel.text = "PASSWORD: "+str(password)
	if !timesUp and passwordState == false: # if timer not out, update values and monitor inputs
		steakValueFetch()
		valueMonitoring()
	
	# level timer does not start until first input
	if !moveMonitoring and !timesUp and passwordState == false:
		if Input.is_action_just_pressed("DigitalDown"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalLeft"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalRight"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalUp"):
			levelTimerStart()
	
	# this number taken from levelManager
	$ResetBar.value = resetGauge 
	
	if timesUp:
		if Input.is_action_just_pressed("DigitalDown"):
			buttonFocusGrab()
		if Input.is_action_just_pressed("DigitalLeft"):
			buttonFocusGrab()
		if Input.is_action_just_pressed("DigitalRight"):
			buttonFocusGrab()
		if Input.is_action_just_pressed("DigitalUp"):
			buttonFocusGrab()
	
	if scoreProcessState != SCORE_PROCESS_STATES.IDLE:
		scoreProcessing()
	
	if scoreProcessState == SCORE_PROCESS_STATES.IDLE:
		if Input.is_action_just_pressed("SettingsButton"):
			_on_settings_button_pressed()


# button to grab focus from keyboard for timeout buttons
func buttonFocusGrab() -> void:
	# lock state values and adjust each button press
	focusState += 1
	if focusState == 2:
		focusState = 0
	
	var _variant := randf_range(-0.7, 0.7) # random blips
	SoundControl.playCue(SoundControl.blip, (2.3 + _variant))
	
	# listen for state
	match focusState:
		FOCUS_STATES.RESTART:
			$ExitButton.grab_focus()
			$ExitButton.grab_click_focus()
		FOCUS_STATES.EXIT:
			$RestartButton.grab_focus()
			$RestartButton.grab_click_focus()


# input start function and flip flop state
func levelTimerStart() -> void:
	$HUDAnimationAlt.play("time_text_reset") # reset time text (bugfix)
	if $HudWindow.scale.x < 1: # window bug fixing
		$HudWindow.scale.x = 1
	
	if !moveMonitoring:
		if !tutorialMode: ## check for tutorial state (given by level manager)
			$HUDAnimationAlt.play("timer_start") # play timer ping on separate animator
			moveMonitoring = true # moves now monitored
			$LevelTimer.start(1) # timer starts on first input
		else:
			$HudWindow/TimerValue.text = "NONE" ## put tutorial time text


# update label values with strings
func valueMonitoring() -> void:
	# listen for steaks collected and update as needed
	if !allSteaksCollected:
		$HudWindow/SteaksValue.text = str(steakValue) + "x"
	else:
		$HudWindow/SteaksValue.text = "GOAL!!" # if all captured, goal text
	
	$HudWindow/MovesValue.text = str(movesValue) + "m"
	
	# update timer as it counts down
	if timerValue < timeLimit and moveMonitoring:
		$HudWindow/TimerValue.text = str(timerValue) + "s"
	if timerValue == 0 and scoreProcessState == SCORE_PROCESS_STATES.IDLE: # last second warning
		$HudWindow/TimerValue.modulate = Color.RED
		$HudWindow/TimerText.modulate = Color.RED


# if all collected, run animation
	if steakValue == 0 and !allSteaksCollected: 
		allSteaksCollected = true
		$HUDAnimationAlt.play("goal") # play on alt to prevent conflicts


# function for updating password, referenced by manager/ui
func passwordReport(data:String) -> void: 
	$HudWindow/PasswordValue.text = data


# count amount of steaks in scene
func steakValueFetch() -> void: 
	var steakCount = get_tree().get_node_count_in_group("steaks")
	steakValue = steakCount


# time functionality
func _on_level_timer_timeout() -> void:
	if scoreProcessState == SCORE_PROCESS_STATES.IDLE and !tutorialMode: # do not log timeouts during score processing
		if timerValue >= 1 and !timesUp: # if time not up, clock counts down
			timerValue -= 1
			$LevelTimer.start(1)
		
		if timerValue == 0: # on time up, flip state, stop non-system noises and trigger feedback
			$HUDAnimationAlt.play("close")
			SoundControl.stopSounds()
			$RestartButton.disabled = false
			$ExitButton.disabled = false
			get_tree().paused = true
			moveMonitoring = false
			$LevelTimer.stop()
			SoundControl.playCue(SoundControl.fail, 3.0)
			$HUDAnimation.play("time_out")
			timesUp = true
			$AlertCue.pitch_scale = 0.5 # alert noise
			$AlertCue.play()
		
		# warnings during period of time before time out (variable)
		if timerValue < warningTime and timerValue > 0:
			$HUDAnimation.play("warning")
			$OpenCue.play() # additional warning cue every even second for dynamics


# buttons open when time out animation ends
func _on_hud_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "time_out":
		$RestartButton.disabled = false
		$ExitButton.disabled = false
		$RestartButton.grab_focus()
		$RestartButton.grab_click_focus()
		$HUDAnimation.stop()


# time out animation triggers when time is up
func _on_open_timer_timeout() -> void:
	$HUDAnimation.play("open")


# button for restart
func _on_restart_button_pressed() -> void:
	$HudWindow.visible = false # hide window to avoid artifacting/bugs
	SoundControl.playCue(SoundControl.flutter, 3.0)
	buttonsDisabled()
	SoundControl.resetMusicFade()
	restart_room.emit() # signal to levelManager to reload


# button for exiting the game
func _on_exit_button_pressed() -> void:
	$HudWindow.visible = false
	SoundControl.playCue(SoundControl.ruined, 0.5)
	buttonsDisabled()
	SoundControl.resetMusicFade()
	Globals.gameRun(false)
	exit_game.emit() # signal to levelManager to exit to title


# function to close buttons on input
func buttonsDisabled()  -> void: 
	$RestartButton.disabled = true
	$ExitButton.disabled = true


# remote hud close button
func closeHud()  -> void: 
	$HUDAnimationAlt.play("close")


# functions to hide and reveal reset bar
func resetBarReveal() -> void: 
	resetBarVisible = true
	$HUDAnimationAlt.play("reset_fader")


# remote function to fade out reset bar on release
func resetBarFade() -> void: 
	resetBarVisible = false
	$HUDAnimationAlt.play_backwards("reset_fader")


# remote function to show reload message on full reset bar
func resetPrompt() -> void: 
	$HUDAnimationAlt.play("close")
	$ResetBar/ResetLabel.text = "RELOADING..."


# score processing state machine
func scoreProcessing() -> void:
	match scoreProcessState:
		SCORE_PROCESS_STATES.IDLE:
			pass # don't process
		SCORE_PROCESS_STATES.TIME_PROCESS:
			if timerValue > 0: # timer adds bonus until zero
				timerValue -= 1
				Globals.scoreUpdate(secondBonus, true)
			else:
				scoreProcessState = SCORE_PROCESS_STATES.MOVE_PROCESS # then state flips
		SCORE_PROCESS_STATES.MOVE_PROCESS:
			if movesValue > 0: # moves subtract penalty until zero
				movesValue-=1
				Globals.scoreUpdate(movePenalty, false)
			else: # then state flips back to off
				print("Score processed!")
				score_processed.emit() # after emitting one signal
				scoreProcessState = SCORE_PROCESS_STATES.POST
		SCORE_PROCESS_STATES.POST:
			pass
			# empty state to end processing


# grab mouse focus for restart
func _on_restart_button_focus_entered() -> void:
	$RestartButton.grab_click_focus()


# grab click focus for restart
func _on_restart_button_mouse_entered() -> void:
	$RestartButton.grab_focus()


# grab mouse focus for exit
func _on_exit_button_focus_entered() -> void:
	$ExitButton.grab_click_focus()


# grab input focus for exit
func _on_exit_button_mouse_entered() -> void:
	$ExitButton.grab_focus()


# go to settings menu
func _on_settings_button_pressed() -> void:
	SceneManager.goToSettings()
