extends Node2D

var areYouSure: bool = false

func _ready() -> void:
	ZeData.loadData()
	$NewGameButton.grab_focus()
	# set global sound
	if !AudioServer.is_bus_mute(3) and SoundControl.bgmLevel > -20:
		SoundControl.resetMusicFade() # reset music state
	SceneManager.currentScene = self


# listen for exit call from escape button
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("CancelButton") or Input.is_action_just_pressed("PasswordButton"):
		if !areYouSure: # if not on warning, move focus to exit button
			$ExitButton.grab_focus()
			_on_exit_button_pressed()
		else:
			get_tree().quit()


# TODO: Need descriptive comment here
func _on_new_game_button_pressed() -> void:
	ZeData.saveGameData()
	SoundControl.playCue(SoundControl.start, 1.0)
	SceneManager.GoToNewSceneString(Scenes.TUTORIAL1) # This will need to be moved to the menu script when the menu is added
	Globals.currentGameData.set("player_score", 0) # Why is this being done here AND in GameRoot.gd?!  Let's make a central function to do this type of thing in the GameRoot when a new game starts.
	# change bgm and fade on out
	SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm)


# TODO: Need descriptive comment here
func _on_password_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.PASSWORD)


# TODO: Need descriptive comment here
func _on_settings_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.SETTINGS)


# TODO: Need descriptive comment here
func _on_exit_button_pressed() -> void: # listen for exit call
	ZeData.saveGameData()
	if !areYouSure: # feedback and warning
		$ExitButton/RollText.speed_scale = 1.0
		areYouSure = true
		$ExitButton/RollText.play("roll_in")
	else: # close program
		get_tree().quit()


# TODO: Need descriptive comment here
func areYouSureReset(): # closes warning state for exit
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


## functions to grab focus
func focusEntered(_focusSelect: Button):
	_focusSelect.grab_click_focus()


# TODO: Need descriptive comment here
func mouseEntered(_mouseSelect: Button):
	_mouseSelect.grab_focus()


# TODO: Need descriptive comment here
func _on_new_game_button_focus_entered() -> void:
	focusEntered($NewGameButton)


# TODO: Need descriptive comment here
func _on_new_game_button_mouse_entered() -> void:
	mouseEntered($NewGameButton)


# TODO: Need descriptive comment here
func _on_password_button_focus_entered() -> void:
	focusEntered($PasswordButton)


# TODO: Need descriptive comment here
func _on_password_button_mouse_entered() -> void:
	mouseEntered($PasswordButton)


# TODO: Need descriptive comment here
func _on_settings_button_focus_entered() -> void:
	focusEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


# TODO: Need descriptive comment here
func _on_settings_button_mouse_entered() -> void:
	mouseEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


# TODO: Need descriptive comment here
func _on_exit_button_focus_entered() -> void:
	if areYouSure: # are you sure warning
		focusEntered($ExitButton)


# TODO: Need descriptive comment here
func _on_exit_button_mouse_entered() -> void:
	if areYouSure:
		focusEntered($ExitButton)


# TODO: Need descriptive comment here
func _on_exit_button_focus_exited() -> void:
	if areYouSure: # if are you sure visible, reset
		areYouSureReset()


# TODO: Need descriptive comment here
func _on_exit_button_mouse_exited() -> void:
	if areYouSure: # if leaving exit area, reset state
		areYouSureReset()
