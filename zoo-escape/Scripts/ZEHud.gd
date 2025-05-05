extends Control


var steakValue : int = 1 ## live monitor of steak total
var timerValue : int = 1 ## live monitor of timer
var movesValue : int = 0 ## live monitor of moves
var scoreCurrent : int = Globals.Game_Globals.get("player_score") ## player score
var secondBonus : int = 50 ## values for abstraction from parent to apply
var movePenalty : int = 25
var moveMonitoring : bool = false ## shows timer has started
var timesUp : bool = false ## shows time is out
var allSteaksCollected : bool = false ## shows goal is open
var resetBarVisible : bool = false ## reset bar flag for external reference
var resetGauge : float = 0.0 ## to compare with level manager
var password : String = "ABCD" ## abstraction for password
@export var warningTime : int = 10 ## value when warning cues
@export var timeLimit : int = 30 # value to change for each level
signal restart_room ## reload signal
signal exit_game ## exit to title signal
signal score_processed ## score processing signal for process score
var scoreProcessFlag : bool = false
var focusState : int = 0
var passwordState = Globals.Current_Settings["passwordWindowOpen"]
enum FOCUS_STATES {
	RESTART,
	EXIT}



func _ready() -> void: ## reset animations at ready, fetch start values
	self.add_to_group("hud")
	$HUDAnimation.play("RESET")
	$HUDAnimationAlt.play("RESET")
	$HudWindow/TimerValue.text = str(timeLimit)+"s" ## update value at start
	steakValueFetch()
	timerValue = timeLimit
	## to avoid queueing error on prompt
	

func _process(_delta: float) -> void:
	## monitor password state to hold hud move monitoring
	passwordState = Globals.Current_Settings["passwordWindowOpen"]
	scoreCurrent = Globals.Game_Globals.get("player_score")
	$HudWindow/ScoreValue.text = str(scoreCurrent)
	## fetch password from level manager and update
	$TimeOutCurtain/PasswordBox/PasswordLabel.text = "PASSWORD: "+str(password)
	if !timesUp and passwordState == false: ## if timer not out, update values and monitor inputs
		steakValueFetch()
		valueMonitoring()


	## level timer does not start until first input
	if !moveMonitoring and !timesUp and passwordState == false:
		if Input.is_action_just_pressed("DigitalDown"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalLeft"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalRight"):
			levelTimerStart()
		if Input.is_action_just_pressed("DigitalUp"):
			levelTimerStart()

	## this number taken from levelManager
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


	if scoreProcessFlag:
		scoreProcessFlag = false
		scoreProcessing()
		get_tree().paused = true


## button to grab focus from keyboard for timeout buttons
func buttonFocusGrab():
	## lock state values and adjust each button press
	focusState+=1
	if focusState == 2:
		focusState = 0

	var _variant = randf_range(-0.7,0.7) ## random blips
	SoundControl.playCue(SoundControl.blip,(2.3+_variant))
	
	## listen for state
	match focusState:
		FOCUS_STATES.RESTART:
			$ExitButton.grab_focus()
		FOCUS_STATES.EXIT:
			$RestartButton.grab_focus()


## input start function and flip flop state
func levelTimerStart():
	$HUDAnimationAlt.play("time_text_reset") ## reset time text (bugfix)
	if $HudWindow.scale.x < 1: ## window bug fixing
		$HudWindow.scale.x = 1

	if !moveMonitoring:
		$HUDAnimationAlt.play("timer_start") ## play timer ping on separate animator
		moveMonitoring = true ## moves now monitored
		$LevelTimer.start(1) ## timer starts on first input


## update label values with strings
func valueMonitoring():
	## listen for steaks collected and update as needed
	if !allSteaksCollected:
		$HudWindow/SteaksValue.text = str(steakValue)+"x"
	else:
		$HudWindow/SteaksValue.text = "GOAL!!" ## if all captured, goal text
	
	$HudWindow/MovesValue.text = str(movesValue)+"m"
	
	## update timer as it counts down
	if timerValue < timeLimit and moveMonitoring:
		$HudWindow/TimerValue.text = str(timerValue)+"s"
	if timerValue == 0: ## last second warning
		$HudWindow/TimerValue.modulate = Color.RED
		$HudWindow/TimerText.modulate = Color.RED


	if steakValue == 0 and !allSteaksCollected: ## if all collected, run animation
		allSteaksCollected = true
		$HUDAnimationAlt.play("goal") ## play on alt to prevent conflicts


func passwordReport(data:String): ## function for updating password, referenced by manager/ui
	$HudWindow/PasswordValue.text = data


func steakValueFetch(): ## count amount of steaks in scene
	var steakCount = get_tree().get_node_count_in_group("steaks")
	steakValue = steakCount

## time functionality
func _on_level_timer_timeout() -> void:
	if !scoreProcessFlag: ## do not log timeouts during score processing
		if timerValue >= 1 and !timesUp: ## if time not up, clock counts down
			timerValue-=1
			$LevelTimer.start(1)

		if timerValue == 0: ## on time up, flip state, stop non-system noises and trigger feedback
			$HUDAnimationAlt.play("close")
			SoundControl.stopSounds()
			get_tree().paused = true
			moveMonitoring = false
			$LevelTimer.stop()
			SoundControl.playCue(SoundControl.fail,3.0)
			$HUDAnimation.play("time_out")
			timesUp = true
			$AlertCue.pitch_scale = 0.5 ## alert noise
			$AlertCue.play()


		## warnings during period of time before time out (variable)
		if timerValue < warningTime and timerValue > 0:
			$HUDAnimation.play("warning")
			$OpenCue.play() ## additional warning cue every even second for dynamics



## buttons open when time out animation ends
func _on_hud_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "time_out":
		$RestartButton.disabled = false
		$ExitButton.disabled = false
		$RestartButton.grab_focus()
		$HUDAnimation.stop()


## time out animation triggers when time is up
func _on_open_timer_timeout() -> void:
	$HUDAnimation.play("open")


## button for restart
func _on_restart_button_pressed() -> void:
	$HudWindow.visible = false ## hide window to avoid artifacting/bugs
	SoundControl.playCue(SoundControl.flutter,3.0)
	buttonsDisabled()
	SoundControl.resetMusicFade()
	restart_room.emit() ## signal to levelManager to reload


func _on_exit_button_pressed() -> void:
	$HudWindow.visible = false
	SoundControl.playCue(SoundControl.ruined,0.5)
	buttonsDisabled()
	SoundControl.resetMusicFade()
	exit_game.emit() ## signal to levelManager to exit to title


func buttonsDisabled(): ## function to close buttons on input
	$RestartButton.disabled = true
	$ExitButton.disabled = true


func closeHud(): ## remote hud close button
	$HUDAnimationAlt.play("close")


func resetBarReveal(): ## functions to hide and reveal reset bar
	resetBarVisible = true
	$HUDAnimationAlt.play("reset_fader")


func resetBarFade():
	resetBarVisible = false
	$HUDAnimationAlt.play_backwards("reset_fader")


func resetPrompt():
	$HUDAnimationAlt.play("close")
	$ResetBar/ResetLabel.text = "RELOADING..."


func scoreProcessing():
	var timer := Timer.new()
	add_child(timer)
	for time in timerValue:
		if timerValue == 0:
			break
		timerValue-=1
		var _old = Globals.Game_Globals.get("player_score")
		Globals.Game_Globals.set("player_score",(_old+secondBonus))
		timer.start(.01)
		await timer.timeout
		
	for move in movesValue:
		if movesValue== 0:
			break
		movesValue-=1
		var _old2 = Globals.Game_Globals.get("player_score")
		Globals.Game_Globals.set("player_score",(_old2-movePenalty))
		timer.start(.01)
		await timer.timeout
	
	score_processed.emit()
