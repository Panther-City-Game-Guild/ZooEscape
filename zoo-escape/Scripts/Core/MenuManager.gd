extends CanvasLayer

# Signals
signal RestartGame
signal QuitGame

# Enums
enum menuTypes {
	NONE,
	MAIN,
	PASSWORD,
	SCORES,
	SETTINGS,
	CREDITS,
	TIMEOUT
}

# Variables
var menuActions: Dictionary[String, Callable]= {}
var currentMenu: menuTypes = menuTypes.NONE
var menuHeap: Array[menuTypes] = []

# Handles to menus
@onready var menus: Dictionary[menuTypes, Control] = {
	menuTypes.MAIN: $MainMenu,
	menuTypes.PASSWORD: $PasswordMenu,
	menuTypes.SCORES: $ScoresMenu,
	menuTypes.SETTINGS: $SettingsMenu,
	#menuTypes.CREDITS: $CreditsMenu,
	menuTypes.TIMEOUT: $TimeoutWindow
}

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Prevent this Node and its children from being paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect all menu signals
	for menu in menus.values():
		if menu.has_signal("SetMenu"):
			menu.SetMenu.connect(setMenu)
		
		if menu.has_signal("GoBack"):
			menu.GoBack.connect(goBack)
		
		if menu.has_signal("RestartGame"):
			menu.RestartGame.connect(func(): RestartGame.emit())
		
		if menu.has_signal("QuitGame"):
			menu.QuitGame.connect(func(): QuitGame.emit())
	
	# Map actions to menu handling logic
	menuActions = {
		"MenuButton": func() -> void:
			if currentMenu != menuTypes.MAIN:
				setMenu(menuTypes.MAIN)
			elif Globals.currentGameData.gameRunning:
				setMenu(menuTypes.NONE),
		"PasswordButton": func() -> void:
			if currentMenu != menuTypes.PASSWORD:
				setMenu(menuTypes.PASSWORD)
			else:
				goBack(),
		"SettingsButton": func() -> void:
			if currentMenu != menuTypes.SETTINGS:
				setMenu(menuTypes.SETTINGS)
			else:
				goBack(),
		"CancelButton": func()-> void:
			if Globals.currentGameData.gameRunning && currentMenu == menuTypes.NONE:
				setMenu(menuTypes.MAIN)
			elif currentMenu != menuTypes.MAIN && currentMenu != menuTypes.NONE:
				goBack()
	}
	
	# Open the MainMenu by default
	if get_tree().current_scene == GameRoot: # This keeps the menu from appearing automatically if running a scene independently.
		$BGM.stop()
		setMenu(menuTypes.MAIN)


func _input(event: InputEvent) -> void:
	# Ignore non-pressed or echo events
	if !event.is_pressed() || event.is_echo() || currentMenu == menuTypes.TIMEOUT:
		return
	
	# Handle menu toggle actions
	for action: String in menuActions:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			menuActions[action].call()
			return


# Called to switch menus
func switchMenu() -> void:
	# Hide all menus
	hideMenus()
	
	# Open the correct menu
	if currentMenu != menuTypes.NONE:
		var menu = menus[currentMenu]
		if menu && menu.has_method("showMenu"):
			menu.showMenu()
		else:
			setMenu(menuTypes.MAIN)
		
	# If no menu is showing, unpause the game
	if currentMenu == menuTypes.NONE:
		get_tree().paused = false
	
	# If any menu is showing, pause the game
	else:
		get_tree().paused = true


# Called to hide all menus
func hideMenus() -> void:
	for menu in menus.values():
			menu.hide()


# Called by all functions everywhere to change menus
func setMenu(newMenu: menuTypes) -> void:
	# Check newMenu against various scenarios
	match newMenu:
		menuTypes.NONE: # If requested menu is NONE, close all menus
			menuHeap.clear()
			currentMenu = menuTypes.NONE
			switchMenu()
			return
		
		currentMenu: # If requested menu is same as current menu, do nothing
			return
		
		menuTypes.MAIN: # If requested menu is MAIN, clear the heap
			menuHeap.clear()
	
	# If newMenu is in the heap, remove all elements on the top of the array
	if menuHeap.has(newMenu):
		while menuHeap.has(newMenu):
			menuHeap.pop_back()
	
	# Finally, open the requested menu
	menuHeap.push_back(newMenu)
	currentMenu = newMenu
	switchMenu()


# Called to reverse the menuHeap (useful for when ESC is used to close menus)
func goBack() -> void:
	if menuHeap.size() > 1:  # Ensure there's a previous menu to go back to
		menuHeap.pop_back()  # Remove the current menu
		currentMenu = menuHeap.back()  # Set currentMenu to the last menu in the heap
		switchMenu()
	else:
		if !Globals.currentGameData.gameRunning:
			setMenu(menuTypes.MAIN)
			return
		setMenu(menuTypes.NONE)  # If no previous menu, close all menus


# Called by LevelManager to update password string on TimeoutWindow when new level loads
func updatePassword(levelCode) -> void:
	menus[menuTypes.TIMEOUT].updatePassword(levelCode)
