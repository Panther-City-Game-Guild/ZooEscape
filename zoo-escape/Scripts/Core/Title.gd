extends Node2D

var areYouSure: bool = false

func _ready() -> void:
	if OS.get_name() == "Web":
		$ExitButton.hide()
	Data.loadData()
	$NewGameButton.grab_focus()
	# set global sound
	if !AudioServer.is_bus_mute(3) and SoundControl.bgmLevel > -20:
		SoundControl.resetMusicFade() # reset music state
	SceneManager.currentScene = self


# listen for exit call from escape button
func _process(_delta: float) -> void:
	if OS.get_name() != "Web" && Input.is_action_just_pressed("CancelButton"):
		if !areYouSure: # if not on warning, move focus to exit button
			$ExitButton.grab_focus()
			_on_exit_button_pressed()
		else:
			get_tree().quit()


# start a new game after pressing button
func _on_new_game_button_pressed() -> void:
	Data.saveGameData() # save options data
	SoundControl.playCue(SoundControl.start, 1.0) # audio feedback
	SceneManager.GoToNewSceneString(Scenes.TUTORIAL1) # This will need to be moved to the menu script when the menu is added
	Globals.currentGameData.set("player_score", 0) # Why is this being done here AND in GameRoot.gd?!  Let's make a central function to do this type of thing in the GameRoot when a new game starts.
	# change bgm and fade on out
	SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm)


# go to password screen after pressing button
func _on_password_button_pressed() -> void:
	SoundControl.playCue(SoundControl.zap, 1.0) # audio feedback
	SceneManager.GoToNewSceneString(Scenes.PASSWORD)


# go to settings screen after pressing button
func _on_settings_button_pressed() -> void:
	SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
	SceneManager.GoToNewSceneString(Scenes.SETTINGS)


# check for warning state. if in warning, exit, else show warning and open state
func _on_exit_button_pressed() -> void: # listen for exit call
	Data.saveGameData()
	if !areYouSure: # feedback and warning
		$ExitButton/RollText.speed_scale = 1.0
		areYouSure = true
		$ExitButton/RollText.play("roll_in")
	else: # close program
		get_tree().quit()


# reset warning state and roll out message
func areYouSureReset(): # closes warning state for exit
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


# functions to grab focus
func focusEntered(_focusSelect: Button):
	_focusSelect.grab_click_focus()


# grab focus from mouse
func mouseEntered(_mouseSelect: Button):
	_mouseSelect.grab_focus()


# grab mouse focus from input
func _on_new_game_button_focus_entered() -> void:
	focusEntered($NewGameButton)


# grab focus from mouse
func _on_new_game_button_mouse_entered() -> void:
	mouseEntered($NewGameButton)


# grab mouse focus from input
func _on_password_button_focus_entered() -> void:
	focusEntered($PasswordButton)


# grab focus from mouse
func _on_password_button_mouse_entered() -> void:
	mouseEntered($PasswordButton)


# if leaving exit, reset warning state and roll text back
func _on_settings_button_focus_entered() -> void:
	focusEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


# if leaving exit, reset warning state and roll text back
func _on_settings_button_mouse_entered() -> void:
	mouseEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


# grab exit button focus
func _on_exit_button_focus_entered() -> void:
	if areYouSure: # are you sure warning
		focusEntered($ExitButton)


# grab exit button focus
func _on_exit_button_mouse_entered() -> void:
	if areYouSure:
		focusEntered($ExitButton)


# if leaving exit, reset warning state and roll text back
func _on_exit_button_focus_exited() -> void:
	if areYouSure: # if are you sure visible, reset
		areYouSureReset()


# if leaving exit, reset warning state and roll text back
func _on_exit_button_mouse_exited() -> void:
	if areYouSure: # if leaving exit area, reset state
		areYouSureReset()
