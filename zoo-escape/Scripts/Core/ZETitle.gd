extends Node2D

var areYouSure: bool = false

func _ready() -> void:
	$NewGameButton.grab_focus()
	## set global sound
	SoundControl.resetMusicFade() ## reset music state
	SceneManager.currentScene = self


## listen for exit call from escape button
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("CancelButton") or Input.is_action_just_pressed("PasswordButton"):
		if !areYouSure: ## if not on warning, move focus to exit button
			$ExitButton.grab_focus()
			_on_exit_button_pressed()
		else:
			get_tree().quit()


func _on_new_game_button_pressed() -> void:
	SoundControl.playCue(SoundControl.start, 1.0)
	SceneManager.GoToNewSceneString(Scenes.TUTORIAL1)
	Globals.Game_Globals.set("player_score", 0)
	### change bgm and fade on out
	SoundControl.levelChangeSoundCall(1.0, SoundControl.defaultBgm)


func _on_password_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.PASSWORD)


func _on_settings_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.SETTINGS)


func _on_exit_button_pressed() -> void: # listen for exit call
	if !areYouSure: ## feedback and warning
		$ExitButton/RollText.speed_scale = 1.0
		areYouSure = true
		$ExitButton/RollText.play("roll_in")
	else: ## close program
		get_tree().quit()


func areYouSureReset(): ## closes warning state for exit
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


## functions to grab focus
func focusEntered(_focusSelect: Button):
	_focusSelect.grab_click_focus()


func mouseEntered(_mouseSelect: Button):
	_mouseSelect.grab_focus()


func _on_new_game_button_focus_entered() -> void:
	focusEntered($NewGameButton)


func _on_new_game_button_mouse_entered() -> void:
	mouseEntered($NewGameButton)


func _on_password_button_focus_entered() -> void:
	focusEntered($PasswordButton)


func _on_password_button_mouse_entered() -> void:
	mouseEntered($PasswordButton)


func _on_settings_button_focus_entered() -> void:
	focusEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


func _on_settings_button_mouse_entered() -> void:
	mouseEntered($SettingsButton)
	if areYouSure:
		areYouSureReset()


func _on_exit_button_focus_entered() -> void:
	if areYouSure: ## are you sure warning
		focusEntered($ExitButton)


func _on_exit_button_mouse_entered() -> void:
	if areYouSure:
		focusEntered($ExitButton)


func _on_exit_button_focus_exited() -> void:
	if areYouSure: ## if are you sure visible, reset
		areYouSureReset()


func _on_exit_button_mouse_exited() -> void:
	if areYouSure: ## if leaving exit area, reset state
		areYouSureReset()
