class_name Hud extends CanvasLayer


var resetBarVisible := false # is the resetBar visible?


# Called when the node first enters the scene tree
func _ready() -> void: # reset animations at ready, fetch volume values
	$HUDAnimation.play("RESET")
	$HUDAnimationAlt.play("RESET")
	$MenuButton.pressed.connect(onMenuButtonPressed)
	$OpenTimer.timeout.connect(onOpenTimerTimeout)


# Play animation when level begins
func playTimerStart() -> void:
	$HUDAnimationAlt.play("timer_start") # play timer ping on separate animator


# Play HUD close animation
func closeHud()  -> void: 
	$MenuButton.hide()
	$HUDAnimationAlt.play("close")


# Give visual and audio warnings when running low on time
func giveTimeWarning() -> void:
	$MBox/HUDWindow/Timer/Control/TimerIcon.play("feedback")
	$HUDAnimation.play("warning")


# Play the HUD open animation (when hud loaded, e.g.)
func onOpenTimerTimeout() -> void:
	$HUDAnimation.play("open")


# Functions to reveal reset bar
func resetBarReveal() -> void:
	if !resetBarVisible:
		$HUDAnimationAlt.play("reset_fader")
		resetBarVisible = true


# Function to fade out reset bar on release
func resetBarFade() -> void:
	$HUDAnimationAlt.play_backwards("reset_fader")
	resetBarVisible = false


# Function to show reload message on full reset bar
func resetPrompt() -> void: 
	$HUDAnimationAlt.play("close")
	$ResetBar/ResetLabel.text = "RELOADING..."


# Update the reset bar value (for filling the progress bar)
func resetBarUpdate(value: float) -> void:
	$ResetBar.value = value


# Set some text values if we're playing a tutorial
func setTutorialText():
	$MBox/HUDWindow/Timer/TimerValue.text = "NONE"


# Updates time text on hud
func updateTimeText(time: int) -> void:
	if !$HUDAnimationAlt.current_animation == "timer_start":
		$MBox/HUDWindow/Timer/TimerValue.text = str(time) + "s" # If not playing a tutorial, display how much time is left


# Updates score text on hud
func updateScoreText(value) -> void:
	$MBox/HUDWindow/ScoreValue.text = str(value)


# Updates move text on hud
func updateMovesText(count) -> void:
	$MBox/HUDWindow/Moves/MovesValue.text = str(count) + "m"


# Updates steak text on hud (play animations if count = 0)
func updateSteaksText(count: int) -> void:
	if count > 0: # If the new value is more than 0, show that
		$MBox/HUDWindow/Steaks/SteaksValue.text = str(count) + "x"
		
	else: # If the new value is less than or equal to 0, goal has been met
		$MBox/HUDWindow/Steaks/SteaksValue.text = "GOAL"
		$MBox/HUDWindow/Steaks/Control/SteakIcon.play("feedback")
		$HUDAnimationAlt.play("goal")


# updates password text on hud
func updatePasswordText(code: String) -> void:
	$MBox/HUDWindow/PasswordValue.text = code # Password value in the HUD


# Open menu in game (handled by MenuManager)
func onMenuButtonPressed() -> void:
	SoundControl.playCue(SoundControl.blip, 3.0)
	MenuManager.setMenu(MenuManager.menuTypes.MAIN)
