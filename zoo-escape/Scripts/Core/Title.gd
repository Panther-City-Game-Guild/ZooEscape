extends Node2D

var areYouSure: bool = false

func _ready() -> void:
	Data.loadData()
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


## save current settings, start new game with feedback call
func _on_new_game_button_pressed() -> void:
	Data.saveGameData()
	SoundControl.playCue(SoundControl.start, 1.0)
	SceneManager.GoToNewSceneString(Scenes.TUTORIAL1) # This will need to be moved to the menu script when the menu is added
	Globals.currentGameData.set("player_score", 0) # Why is this being done here AND in GameRoot.gd?!  Let's make a central function to do this type of thing in the GameRoot when a new game starts.
	# change bgm and fade on out
	SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm)


## go to the password input scene
func _on_password_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.PASSWORD)


## go to the settings input scene
func _on_settings_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.SETTINGS)


## if exit warning is visible, exit game, else show warning
func _on_exit_button_pressed() -> void: # listen for exit call
	Data.saveGameData()
	if !areYouSure: # feedback and warning
		$ExitButton/RollText.speed_scale = 1.0
		areYouSure = true
		$ExitButton/RollText.play("roll_in")
	else: # close program
		get_tree().quit()


# closes exit warning, resetting exit check state
func areYouSureReset(): # closes warning state for exit
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


# functions to grab click focus
func focusEntered(_focusSelect: Button):
	_focusSelect.grab_click_focus()


# function to grab mouse focus
func mouseEntered(_mouseSelect: Button):
	_mouseSelect.grab_focus()


# function to start new game
func _on_new_game_button_focus_entered() -> void:
	focusEntered($NewGameButton)


# grab mouse focus
func _on_new_game_button_mouse_entered() -> void:
	mouseEntered($NewGameButton)


# grab click focus
func _on_password_button_focus_entered() -> void:
	focusEntered($PasswordButton)


# grab mouse focus
func _on_password_button_mouse_entered() -> void:
	mouseEntered($PasswordButton)


# grab focus and clear exit warning
func _on_settings_button_focus_entered() -> void:
	focusEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


# grab mouse focus and clear exit warning
func _on_settings_button_mouse_entered() -> void:
	mouseEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


# grab exit button focus
func _on_exit_button_focus_entered() -> void:
	if areYouSure: # are you sure warning
		focusEntered($ExitButton)


# grab mouse focus
func _on_exit_button_mouse_entered() -> void:
	if areYouSure:
		focusEntered($ExitButton)


# reset exit warning text
func _on_exit_button_focus_exited() -> void:
	if areYouSure: # if are you sure visible, reset
		areYouSureReset()


# reset exit warning text
func _on_exit_button_mouse_exited() -> void:
	if areYouSure: # if leaving exit area, reset state
		areYouSureReset()
