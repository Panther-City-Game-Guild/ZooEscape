extends Control

# Signals
signal SetMenu(menu: MenuManager.menuTypes)
signal RestartGame
signal QuitGame

# Called when InputEvents are detected
func _input(event: InputEvent) -> void:
	if !event.is_pressed() || event.is_echo():
		return # Only handle single, intentional 'press' events
	
	if visible: # Only process inputs if window is visible
		if event.is_action("CancelButton"):
			get_viewport().set_input_as_handled()
			if !$TimeOutCurtain/Buttons/QuitButton.has_focus():
				onQuitButtonMouseEntered()
			else:
				onQuitButtonPressed()


# Called by MenuManager to show this menu
func showMenu() -> void:
	get_tree().paused = true
	SoundControl.stopSounds()
	SoundControl.playCue(SoundControl.fail, 3.0)
	show()
	playFadeIn()


# Called by the MenuManager when a new level loads
func updatePassword(levelCode) -> void:
	$TimeOutCurtain/PasswordBox/PasswordLabel.text = "PASSWORD: " + levelCode


# Called to play the FadeIn animation
func playFadeIn() -> void:
	$AnimationPlayer.play("FadeIn")
	$TimeOutCurtain/Buttons/RestartButton.call_deferred("grab_focus")
	$TimeOutCurtain/Buttons/RestartButton.call_deferred("grab_click_focus")


# Called to play the Reset animation
func playReset() -> void:
	$AnimationPlayer.play("RESET")


# Called when the mouse hovers the Restart button
func onRestartButtonMouseEntered() -> void:
	$TimeOutCurtain/Buttons/RestartButton.call_deferred("grab_focus")


# Called when the mouse hovers the QuitGame button
func onQuitButtonMouseEntered() -> void:
	$TimeOutCurtain/Buttons/QuitButton.call_deferred("grab_focus")


# Called when the Restart button gains focus
func onRestartButtonFocusEntered() -> void:
	$TimeOutCurtain/Buttons/RestartButton.call_deferred("grab_click_focus")


# Called when the QuitGame button gains focus
func onQuitButtonFocusEntered() -> void:
	$TimeOutCurtain/Buttons/QuitButton.call_deferred("grab_click_focus")


# Called the Restart button is pressed
func onRestartButtonPressed() -> void:
	playReset()
	SoundControl.playCue(SoundControl.start, 1.0) # audio feedback
	RestartGame.emit()
	SoundControl.resetMusicFade()
	SetMenu.emit(MenuManager.menuTypes.NONE)


# Called the QuitGame button is pressed
func onQuitButtonPressed() -> void:
	SoundControl.playCue(SoundControl.ruined, 0.5)
	Globals.currentGameData.gameRunning = false
	QuitGame.emit()
	SoundControl.resetMusicFade()
	playReset()
	SetMenu.emit(MenuManager.menuTypes.NONE)
