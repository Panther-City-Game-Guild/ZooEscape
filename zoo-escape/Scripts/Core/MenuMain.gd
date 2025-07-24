extends Control

# Signals
signal SetMenu(menu: MenuManager.menuTypes)

# Enums
enum buttonTypes {
	RESUME,
	NEWGAME,
	PASSWORD,
	SCORES,
	SETTINGS,
	CREDITS,
	BACK,
	EXIT
}

# Variables
var areYouSure := false
var lastButton := buttonTypes.NEWGAME

# Handles to child nodes
@onready var bgRect := $Background
@onready var pausedHint := $PausedHint
@onready var buttons: Dictionary[buttonTypes, Button] = {
	buttonTypes.RESUME: $MarginBox/VBox/ResumeButton,
	buttonTypes.NEWGAME: $MarginBox/VBox/NewGameButton,
	buttonTypes.PASSWORD: $MarginBox/VBox/PasswordButton,
	buttonTypes.SCORES: $MarginBox/VBox/ScoresButton,
	buttonTypes.SETTINGS: $MarginBox/VBox/SettingsButton,
	buttonTypes.CREDITS: $MarginBox/VBox/CreditsButton,
	buttonTypes.BACK: $MarginBox/VBox/BackButton,
	buttonTypes.EXIT: $ExitMargin/ExitButton
}


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Connect menu button signals to Event Handlers
	for button in buttons.values():
		button.pressed.connect(onButtonPressed.bind(buttons.find_key(button)))
		button.mouse_entered.connect(onButtonMouseEntered.bind(buttons.find_key(button)))
		button.focus_entered.connect(onButtonFocusEntered.bind(buttons.find_key(button)))
	
	# Focus on the last button to be used in this window (New Game by default)
	lastButtonFocus()

func _input(event: InputEvent) -> void:
	# ONLY detect inputs if MainMenu is visible
	if visible:
		# Only handle single, intentional 'press' events
		if !event.is_pressed() || event.is_echo():
			return
		
		# Hide all menus if a game is running
		if event.is_action("CancelButton"):
			get_viewport().set_input_as_handled() # Mark InputEvent as handled
			if Globals.currentGameData["gameRunning"]:
				onButtonMouseEntered(buttonTypes.RESUME)
				onButtonPressed(buttonTypes.RESUME)
			else:
				onButtonMouseEntered(buttonTypes.EXIT)
				onButtonPressed(buttonTypes.EXIT)


# Reset exit warning state and roll out message
func areYouSureReset():
	areYouSure = false
	$ExitMargin/ExitButton/RollText.speed_scale = 2.0
	$ExitMargin/ExitButton/RollText.play_backwards("roll_in")


# Event handler for when a menu button is pressed
func onButtonPressed(btn: int) -> void:
	match btn as buttonTypes: #  Determine which button got pressed
		# Resume button
		buttonTypes.RESUME:
			lastButton = buttonTypes.RESUME
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.NONE)
			
		# New Game button
		buttonTypes.NEWGAME:
			SoundControl.resetMusicFade()
			lastButton = buttonTypes.NEWGAME
			SoundControl.playCue(SoundControl.start, 1.0) # audio feedback
			SceneManager.call_deferred("goToNewSceneString", Scenes.TUTORIAL1) # Load the first tutorial level
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		# Password button
		buttonTypes.PASSWORD:
			lastButton = buttonTypes.PASSWORD
			SoundControl.playCue(SoundControl.zap, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.PASSWORD)
		
		# Scores button
		buttonTypes.SCORES:
			lastButton = buttonTypes.SCORES
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.SCORES)
		
		# Settings button
		buttonTypes.SETTINGS:
			lastButton = buttonTypes.SETTINGS
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			SetMenu.emit(MenuManager.menuTypes.SETTINGS)
			
		# Credits button
		buttonTypes.CREDITS:
			lastButton = buttonTypes.CREDITS
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			#SetMenu.emit(MenuManager.menuTypes.CREDITS) # This will be added in another PR, so leave it in
			
		# Back button
		buttonTypes.BACK:
			lastButton = buttonTypes.NEWGAME # Set to NEWGAME since quitting to the title scene
			SoundControl.playCue(SoundControl.flutter, 1.0) # audio feedback
			Data.saveSettingsData()
			Globals.currentGameData.gameRunning = false
			SceneManager.call_deferred("goToNewSceneString", Scenes.TITLE) # Go to title scene
			SoundControl.resetMusicFade()
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		# Exit button
		buttonTypes.EXIT:
			SoundControl.playCue(SoundControl.down, 1.4)
			if !areYouSure: # feedback and warning
				$ExitMargin/ExitButton/RollText.speed_scale = 1.0
				areYouSure = true
				$ExitMargin/ExitButton/RollText.play("roll_in")
			else: # close program
				Data.saveSettingsData()
				get_tree().quit()


# Event handler for when the mouse hovers a menu button
func onButtonMouseEntered(btn: int) -> void:
	# Make the button grab_focus
	buttons[btn].call_deferred("grab_focus")


# Event handler for when a menu button receives focus
func onButtonFocusEntered(btn: int) -> void:
	buttons[btn].call_deferred("grab_click_focus")


# Event handler for when Exit button loses focus (useful for confirming user wants to exit)
func onExitButtonFocusExited() -> void:
	if areYouSure: # if are you sure visible, reset
		areYouSureReset()


# Event handler for when mouse un-hovers the Exit button (useful for confirming user wants to exit)
func onExitButtonMouseExited() -> void:
	if areYouSure: # if leaving exit area, reset state
		areYouSureReset()


# Called to re-focus the last button used on the MainMenu
func lastButtonFocus() -> void:
	buttons[lastButton].call_deferred("grab_focus")


# Called by the MenuManager to show the MainMenu
func showMenu() -> void:
	if Globals.currentGameData.gameRunning: # If a game is running, use all these settings
		bgRect.hide()
		pausedHint.show()
		$MarginBox.add_theme_constant_override("margin_bottom", 126)
		buttons[buttonTypes.RESUME].show()
		buttons[buttonTypes.NEWGAME].hide()
		buttons[buttonTypes.SCORES].hide()
		buttons[buttonTypes.CREDITS].hide()
		buttons[buttonTypes.BACK].show()
		buttons[buttonTypes.EXIT].hide()
		buttons[buttonTypes.PASSWORD].focus_neighbor_top = "../ResumeButton"
		buttons[buttonTypes.PASSWORD].focus_previous = "../ResumeButton"
		buttons[buttonTypes.SETTINGS].focus_neighbor_bottom = "../BackButton"
		buttons[buttonTypes.SETTINGS].focus_next = "../BackButton"
		buttons[buttonTypes.SETTINGS].focus_neighbor_right = ""
		onButtonMouseEntered(buttonTypes.RESUME)
	
	else: # If a game is not running, use all these settings
		bgRect.show()
		pausedHint.hide()
		$MarginBox.add_theme_constant_override("margin_bottom", 60)
		buttons[buttonTypes.RESUME].hide()
		buttons[buttonTypes.NEWGAME].show()
		buttons[buttonTypes.SCORES].show()
		buttons[buttonTypes.SCORES].disabled = Globals.highScores.is_empty()
		buttons[buttonTypes.CREDITS].show()
		buttons[buttonTypes.BACK].hide()
		buttons[buttonTypes.EXIT].visible = !OS.get_name() == "Web" # If playing the web version, hide the Exit button
		buttons[buttonTypes.PASSWORD].focus_neighbor_top = "../NewGameButton"
		buttons[buttonTypes.PASSWORD].focus_previous = "../NewGameButton"
		buttons[buttonTypes.SETTINGS].focus_neighbor_bottom = "../CreditsButton"
		buttons[buttonTypes.SETTINGS].focus_next = "../CreditsButton"
		if lastButton == buttonTypes.RESUME:
			lastButton = buttonTypes.NEWGAME
		lastButtonFocus()
	show()
