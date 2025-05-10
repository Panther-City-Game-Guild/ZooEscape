extends Node2D

var menuState = MENU_STATES.NEW_GAME
enum MENU_STATES {
	NEW_GAME,
	PASSWORD,
	SETTINGS,
	EXIT}
var areYouSure : bool = false


func _ready() -> void:
	$NewGameButton.grab_focus()
	setLevelGlobals()
	SoundControl.resetMusicFade() ## reset music state
	SceneManager.currentScene = self


func setLevelGlobals() -> void:
	# debug levels
	Globals.Game_Globals["9990"] = Scenes.ZETitle
	Globals.Game_Globals["9991"] = Scenes.ZEDebug
	Globals.Game_Globals["9992"] = Scenes.ZEDebug2
	
	# Real Levels
	Globals.Game_Globals["0001"] = Scenes.ZETutorial1
	
	Globals.Game_Globals["0387"] = Scenes.ZELevel1
	# Globals.Game_Globals["9102"] = 
	# Globals.Game_Globals["1476"] = 
	# Globals.Game_Globals["5829"] = 
	# Globals.Game_Globals["0053"] = 
	
	# Globals.Game_Globals["7618"] = 
	# Globals.Game_Globals["2940"] = 
	# Globals.Game_Globals["8365"] = 
	# Globals.Game_Globals["0721"] = 
	# Globals.Game_Globals["6594"] = 
	
	# Globals.Game_Globals["3082"] = 
	# Globals.Game_Globals["9817"] = 
	# Globals.Game_Globals["4250"] = 
	# Globals.Game_Globals["1639"] = 
	# Globals.Game_Globals["7048"] = 
	
	# Globals.Game_Globals["2561"] = 
	# Globals.Game_Globals["8934"] = 
	# Globals.Game_Globals["0195"] = 
	# Globals.Game_Globals["5473"] = 
	# Globals.Game_Globals["3706"] = 


func _on_new_game_button_pressed() -> void:
	SoundControl.playCue(SoundControl.start,1.0)
	SceneManager.GoToNewSceneString(Scenes.ZETutorial1)
	Globals.Game_Globals.set("player_score",0)
	### change bgm and fade on out
	SoundControl.levelChangeSoundCall(1.0,SoundControl.defaultBgm)


func _on_password_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.ZEPassword)


func _on_settings_button_pressed() -> void:
	SceneManager.GoToNewSceneString(Scenes.ZESettings)


func _on_exit_button_pressed() -> void:
	if !areYouSure:
		$ExitButton/RollText.speed_scale = 1.0
		areYouSure = true
		$ExitButton/RollText.play("roll_in")
	else:
		get_tree().quit()


func areYouSureReset():
	areYouSure = false
	$ExitButton/RollText.speed_scale = 2.0
	$ExitButton/RollText.play_backwards("roll_in")


func focusEntered(_focusSelect:Button):
	_focusSelect.grab_click_focus()


func mouseEntered(_mouseSelect:Button):
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
	if areYouSure:
		areYouSureReset()
