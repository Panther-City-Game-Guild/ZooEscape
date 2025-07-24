extends Control

# Signals
signal SetMenu(menu: MenuManager.menuTypes)
signal GoBack

# materials for shader changes on password entry
const CORRECTSHADER := preload("res://Assets/Shaders/WobblyMaterial.tres")
const FAILSHADER := preload("res://Assets/Shaders/ErrorShakeX.tres")
const EMPTY := "----"

# states to control focus and input
enum buttonTypes {
	ZERO,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	CLEAR,
	ENTER
}

# Variables
@export var loadSceneBufferTime := 1 # Buffer until password scene loads
var inputHandlers: Dictionary[String, Callable] = {}
var focusedBtn := buttonTypes.ONE # current focus
var codeTextPos := 0 # position in code
var tempCode := "9990"
var inputBufferActive := false # hold input until window fades in

# Handles to child nodes
@onready var code := $Window/Code # text ref for code
@onready var buttons: Dictionary[buttonTypes, Button] = {
	buttonTypes.ZERO: $Window/Buttons/Row4/Button0,
	buttonTypes.ONE: $Window/Buttons/Row1/Button1,
	buttonTypes.TWO: $Window/Buttons/Row1/Button2,
	buttonTypes.THREE: $Window/Buttons/Row1/Button3,
	buttonTypes.FOUR: $Window/Buttons/Row2/Button4,
	buttonTypes.FIVE: $Window/Buttons/Row2/Button5,
	buttonTypes.SIX: $Window/Buttons/Row2/Button6,
	buttonTypes.SEVEN: $Window/Buttons/Row3/Button7,
	buttonTypes.EIGHT: $Window/Buttons/Row3/Button8,
	buttonTypes.NINE: $Window/Buttons/Row3/Button9,
	buttonTypes.CLEAR: $Window/Buttons/Row4/ButtonClear,
	buttonTypes.ENTER: $Window/Buttons/Row4/ButtonEnter,
}


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Connect buttons to event handlers
	for button: Button in buttons.values():
		var btnKey: buttonTypes = buttons.find_key(button)
		button.pressed.connect(onButtonPressed.bind(btnKey))
		button.focus_entered.connect(onButtonFocusEntered.bind(btnKey))
		button.mouse_entered.connect(onButtonMouseEntered.bind(btnKey))
	
	# Map actions to their corresponding handlers
	inputHandlers = {
		"ActionButton": func() -> void: onButtonPressed(focusedBtn),
		"CancelButton": func() -> void:
			onButtonMouseEntered(buttonTypes.CLEAR)
			onButtonPressed(buttonTypes.CLEAR),
		"Numeric_0": func() -> void: handleNumericInput(0),
		"Numeric_1": func() -> void: handleNumericInput(1),
		"Numeric_2": func() -> void: handleNumericInput(2),
		"Numeric_3": func() -> void: handleNumericInput(3),
		"Numeric_4": func() -> void: handleNumericInput(4),
		"Numeric_5": func() -> void: handleNumericInput(5),
		"Numeric_6": func() -> void: handleNumericInput(6),
		"Numeric_7": func() -> void: handleNumericInput(7),
		"Numeric_8": func() -> void: handleNumericInput(8),
		"Numeric_9": func() -> void: handleNumericInput(9)
	}


# Called when input is detected
func _input(event: InputEvent) -> void:
	# Exit early if not visible or input buffer is active
	if !visible || inputBufferActive:
		return
	
	# Check all possible actions
	for action: String in inputHandlers:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			inputHandlers[action].call()
			return


# Called by _input to handle "Numeric_" actions
func handleNumericInput(number: int) -> void:
	onButtonMouseEntered(number)
	onButtonPressed(number)


# Sound cue for input sounds
func randomBlipCue() -> void:
	var variant := randf_range(-0.7, 0.7) # random blips
	SoundControl.playCue(SoundControl.blip, (3.0 + variant))


# Called to reset the code input field
func codeReset() -> void:
	code.text = EMPTY
	codeTextPos = 0


# code deletion function
func codeEraseDigit() -> void:
	if codeTextPos > 0 && codeTextPos <= 4:
		codeTextPos -= 1
		code.text[codeTextPos] = "-"
	else:
		returnToLastMenu()


# Called to check if the code input field has 4 digits
func codeCompleteCheck() -> void:
	if codeTextPos >= 3:
		# Make the 'E' (Enter) button grab_focus
		onButtonMouseEntered(buttonTypes.ENTER)


# get number by state and input
func codeSetDigit(num: int) -> void: # if there are dashes, accept input
	# Play sound
	randomBlipCue()
	codeCompleteCheck()
	
	# Set the value in the password string, at the current position
	if codeTextPos < 4: # add code until full
		code.text[codeTextPos] = str(num)
		codeTextPos += 1
	# other functions will handle code once codeTestPos is full (4)


# check code for answer
func codeCheck() -> void:
	if !code.text.contains("-") && Globals.PASSWORDS.has(code.text): # yay
		tempCode = code.text # Store the entered code
		code.material = CORRECTSHADER
		code.modulate = Color.GREEN_YELLOW
		SoundControl.playCue(SoundControl.success, 1.5)
		$LoadSceneBuffer.start(loadSceneBufferTime) # begin buffer to load
	else: # nay, code clears out and timer sets for shader reset
		codeTextPos = 0
		code.text = "XXXX"
		code.material = FAILSHADER
		code.modulate = Color.CRIMSON
		SoundControl.playCue(SoundControl.down, 1.5)
	
	startInputBuffer()
	$TextEffectTimer.start(0.5)


# Start a timer to block input events on this window
func startInputBuffer() -> void:
	inputBufferActive = true
	$InputBufferTimer.start(loadSceneBufferTime)


# Called by the MenuManager to show the PasswordMenu
func showMenu() -> void:
	codeReset() # Reset code value
	onButtonMouseEntered(buttonTypes.ONE) # set focusedBtn and grab_focus
	show() # Now You See Me


# Called to return to the last menu
func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	GoBack.emit() # Bye!


### Timer Event Handlers
# this effect resets the password box to default material and style
func onTextEffectTimerTimeout() -> void:
	code.modulate = Color.WHITE
	code.material = null


# turns off input buffer, timer runs on window open
func onInputBufferTimerTimeout() -> void:
	inputBufferActive = false
	codeReset()


# load scene at end of load buffer timer
func onLoadSceneBufferTimeout() -> void:
	SetMenu.emit(MenuManager.menuTypes.NONE)
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[tempCode])


### Button Event Handlers
# Called when a button is pressed
func onButtonPressed(btnType: buttonTypes) -> void:
	match btnType:
		# If a Numeric_ buttons was pressed (0 - 9)
		buttonTypes.ZERO, \
		buttonTypes.ONE, \
		buttonTypes.TWO, \
		buttonTypes.THREE, \
		buttonTypes.FOUR, \
		buttonTypes.FIVE, \
		buttonTypes.SIX, \
		buttonTypes.SEVEN, \
		buttonTypes.EIGHT, \
		buttonTypes.NINE:
			codeSetDigit(btnType) # Try add one didgt to code
		
		# If Clear button was pressed
		buttonTypes.CLEAR: # 10
			codeEraseDigit() # Try to delete digit from end of code
		
		# If Enter button was pressed
		buttonTypes.ENTER: # 11
			codeCheck() # Check for correct code


# Called when mouse hovers a button, have that button grab_focus
func onButtonMouseEntered(btnType: buttonTypes) -> void:
	focusedBtn = btnType # grab state
	buttons[btnType].call_deferred("grab_focus")


# Called when a button is focused, have that button grab_click_focus
func onButtonFocusEntered(btnType: buttonTypes) -> void:
	focusedBtn = btnType # grab state
	buttons[btnType].call_deferred("grab_click_focus")
