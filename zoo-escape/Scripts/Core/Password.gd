extends Control


# materials for shader changes on password entry
const correctShader := preload("res://Assets/Shaders/WobblyMaterial.tres")
const failShader := preload("res://Assets/Shaders/ErrorShakeX.tres")
const title := Scenes.TITLE
const empty := "----"
const correctedVector := Vector2(-320,-160)

# states to control focus and input
enum NUMBER_FOCUS_STATES {
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
	ENTER}

var inGameMode := false # Determine behavior in and out of frontend
@export var loadSceneBufferTime := 1 # Buffer until password scene loads
var numberFocusState := 1 # current focus
var codeTextPos := 0 # position in code
var windowOpenFlag := false # flag for checking if window is open
var inputBufferActive := true # hold input until window fades in
@onready var code := $Code # text ref for code


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	code.text = empty # reset text
	if Globals.currentAppState.get("gameRunning") == false:
#	if !inGameMode: # fade in and queue buffers, grab focus
		inGameMode = false
		$Animator.play("fade_in")
		$InputBufferTimer.start()
		$ButtonBox/Button1.grab_focus()
		allStatesFlywheel(true, true) # all hud flags true with animation in
	else:
		allStatesFlywheel(false, false) # hud flags off but no animation
		self.position = correctedVector
		inGameMode = true


# Called when input is detected
func _input(_event: InputEvent) -> void:
	if !inGameMode and !inputBufferActive:
		fetchInput() # listen for input outside game from frontend
		numberInputGrab()
		
	if inGameMode: # listen for password button (escape)
		if Input.is_action_just_pressed("PasswordButton"):
			if !inputBufferActive: # is input buffer expired? (waits from start)
				if windowOpenFlag == false: # is window already open?
					$InputBufferTimer.start()
					$ButtonBox/Button1.grab_focus()
					buttonBatchControl(true)
					allStatesFlywheel(true, true) # open all hud states, animation in
				else:
					buttonBatchControl(false)
					allStatesFlywheel(false, true)
			else: # close all states with animation out
				allStatesFlywheel(false, true)
		
	if inGameMode and windowOpenFlag == true:
		fetchInput()
		numberInputGrab()


# for grabbing numeric input and updating number state
func numberInputGrab() -> void:
	if Input.is_action_just_pressed("Numeric_0"):
		numberFocusState = 0
		_on_button_0_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_1"):
		numberFocusState = 1
		_on_button_1_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_2"):
		numberFocusState = 2
		_on_button_2_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_3"):
		numberFocusState = 3
		_on_button_3_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_4"):
		numberFocusState = 4
		_on_button_4_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_5"):
		numberFocusState = 5
		_on_button_5_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_6"):
		numberFocusState = 6
		_on_button_6_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_7"):
		numberFocusState = 7
		_on_button_7_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_8"):
		numberFocusState = 8
		_on_button_8_pressed()
		_numericFocusCheck()
	if Input.is_action_just_pressed("Numeric_9"):
		numberFocusState = 9
		_on_button_9_pressed()
		_numericFocusCheck()


# check for focus on numbers
func _numericFocusCheck() -> void:
	if codeTextPos == 4:
		$ButtonBox/ButtonEnter.grab_focus()


# disable all buttons widget
func allStatesFlywheel(logic: bool, animate: bool) -> void:
	# first bool, logic for all hud states, second bool determines if animation necessary
	Globals.currentAppState["passwordWindowOpen"] = logic # global hud logic
	get_tree().paused = logic # pause action and physics
	inputBufferActive = logic # keep input buffer from hud
	windowOpenFlag = logic # note input that window is open
	buttonBatchControl(logic)
	if animate: # choose animation based on first bool or stay invisisble
		if logic:
			$Animator.play("fade_in") # true
		else:
			$Animator.play_backwards("fade_in") # false


# sound cue for input sounds
func randomBlipCue() -> void:
	var _variant := randf_range(-0.7, 0.7) # random blips
	SoundControl.playCue(SoundControl.blip, (3.0 + _variant))


# grabbing global input
func fetchInput() -> void:
	if Input.is_action_just_pressed("PasswordButton"):
		SoundControl.playCue(SoundControl.down, 2.0)
		if inGameMode and !windowOpenFlag:
			get_tree().paused = true
			$Animator.play_backwards("fade_in")
			code.text = empty
			codeTextPos = 0
			inputBufferActive = true
			windowOpenFlag = true
		else:
			get_tree().paused = false
		
		if !inGameMode:
			returnToTitle()
		
	if Input.is_action_just_pressed("ActionButton"):
		if numberFocusState == NUMBER_FOCUS_STATES.ENTER:
			answerCheck() # check answers if on answer button
			if codeTextPos == 4:
				$ButtonBox/ButtonEnter.grab_focus()
			
		if Globals.PASSWORDS.has(code.text): # if level code correct, show feedback
			SoundControl.playCue(SoundControl.success, 2.5)
			code.material = correctShader
			code.modulate = Color.GREEN_YELLOW
			$LoadSceneBuffer.start(loadSceneBufferTime) # begin buffer to load
			
		if !"-" in code.text: # if no blanks, go to enter button
			numberFocusState = NUMBER_FOCUS_STATES.ENTER
			$ButtonBox/ButtonEnter.grab_focus()
		
	if Input.is_action_just_pressed("CancelButton"): # if hitting backspace
		if codeTextPos > -1: # single delete
			numberFocusState = NUMBER_FOCUS_STATES.CLEAR
			$ButtonBox/ButtonClear.grab_focus()
			codeRemoval()
		else:
			buttonBatchControl(false)
			allStatesFlywheel(false, true)
			if Globals.currentAppState.get("gameRunning") == true:
				returnToTitle()


# code deletion function
func codeRemoval() -> void:
	if codeTextPos != 0:
		codeTextPos -= 1
		code.text[codeTextPos] = "-"
	if codeTextPos <= 0: # if on first, keep all code clear
		codeTextPos = 0
		code.text = empty


# batch button logic for disabling and buffering
func buttonBatchControl(logic:bool) -> void:
	var _buttons = get_tree().get_nodes_in_group("buttons")
	for _button in _buttons:
		if logic:
			_button.disabled = false
		else:
			_button.disabled = true


# return sound cue and load function
func returnToTitle() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	SceneManager.call_deferred("goToNewSceneString", title)


# check code for answer
func answerCheck() -> void:
	if !code.text.contains("-") and Globals.PASSWORDS.has(code.text): # yay
		code.material = correctShader
		code.modulate = Color.GREEN_YELLOW
		SoundControl.playCue(SoundControl.success, 1.5)
		Globals.gameRun(true)
		$LoadSceneBuffer.start(1)
	else: # nay, code clears out and timer sets for shader reset
		codeTextPos = 0
		code.text = "XXXX"
		code.material = failShader
		code.modulate = Color.CRIMSON
		SoundControl.playCue(SoundControl.down, 1.5)
		$TextEffectTimer.start(0.5)


# load scene at end of load buffer timer
func _on_load_scene_buffer_timeout() -> void:
	SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[code.text])


# get number by state and input
func SetNum() -> void: # if there are dashes, accept input
	randomBlipCue()
	var num := ""
	match numberFocusState:
		0:
			num = "0"
		1:
			num = "1"
		2:
			num = "2"
		3:
			num = "3"
		4:
			num = "4"
		5:
			num = "5"
		6:
			num = "6"
		7:
			num = "7"
		8:
			num = "8"
		9:
			num = "9"
	
	if codeTextPos < 4: # add code until full
		code.text[codeTextPos] = num
		codeTextPos += 1
	# other functions will handle code once codeTestPos is full (4)


# this effect resets the password box to default material and style
func _on_effect_timer_timeout() -> void:
	codeTextPos = 0
	code.modulate = Color.WHITE
	code.material = null
	code.text = empty


# turns off input buffer, timer runs on window open
func _on_buffer_timer_timeout() -> void:
	inputBufferActive = false
	buttonBatchControl(true)


# TODO:  Let's consider connecting these different button events programmatically in _ready() to a function for each event type that can take the button number or name as a parameter, to reduce the number of functions in code.

# number functions
# Called when button 1 pressed
func _on_button_1_pressed() -> void:
	SetNum() # set number by button state


# Called when button 1 focused
func _on_button_1_focus_entered() -> void:
	numberFocusState = 1 # grab state


# Called when mouse hovers button 1
func _on_button_1_mouse_entered() -> void:
	numberFocusState = 1 # grab state


# Called when button 2 pressed
func _on_button_2_pressed() -> void:
	SetNum()


# Called when button 2 focused
func _on_button_2_focus_entered() -> void:
	numberFocusState = 2


# Called when mouse hovers button 2
func _on_button_2_mouse_entered() -> void:
	numberFocusState = 2


# Called when button 3 pressed
func _on_button_3_pressed() -> void:
	SetNum()


# Called when button 3 focused
func _on_button_3_focus_entered() -> void:
	numberFocusState = 3


# Called when mouse hovers button 3
func _on_button_3_mouse_entered() -> void:
	numberFocusState = 3


# Called when button 4 pressed
func _on_button_4_pressed() -> void:
	SetNum()


# Called when button 4 focused
func _on_button_4_focus_entered() -> void:
	numberFocusState = 4


# Called when mouse hovers button 4
func _on_button_4_mouse_entered() -> void:
	numberFocusState = 4


# Called when button 5 pressed
func _on_button_5_pressed() -> void:
	SetNum()


# Called when button 5 focused
func _on_button_5_focus_entered() -> void:
	numberFocusState = 5


# Called when mouse hovers button 5
func _on_button_5_mouse_entered() -> void:
	numberFocusState = 5


# Called when button 6 pressed
func _on_button_6_pressed() -> void:
	SetNum()


# Called when button 6 focused
func _on_button_6_focus_entered() -> void:
	numberFocusState = 6


# Called when mouse hovers button 6
func _on_button_6_mouse_entered() -> void:
	numberFocusState = 6


# Called when button 7 pressed
func _on_button_7_pressed() -> void:
	SetNum()


# Called when button 7 focused
func _on_button_7_focus_entered() -> void:
	numberFocusState = 7


# Called when mouse hovers button 7
func _on_button_7_mouse_entered() -> void:
	numberFocusState = 7


# Called when button 8 pressed
func _on_button_8_pressed() -> void:
	SetNum()


# Called when button 8 focused
func _on_button_8_focus_entered() -> void:
	numberFocusState = 8


# Called when mouse hovers button 8
func _on_button_8_mouse_entered() -> void:
	numberFocusState = 8


# Called when button 9 pressed
func _on_button_9_pressed() -> void:
	SetNum()


# Called when button 9 focused
func _on_button_9_focus_entered() -> void:
	numberFocusState = 9


# Called when mouse hovers button 9
func _on_button_9_mouse_entered() -> void:
	numberFocusState = 9


# Called when button 0 pressed
func _on_button_0_pressed() -> void:
	SetNum()


# Called when button 0 focused
func _on_button_0_focus_entered() -> void:
	numberFocusState = 0


# Called when mouse hovers button 0
func _on_button_0_mouse_entered() -> void:
	numberFocusState = 0


# Called when Clear button pressed
func _on_button_clear_pressed() -> void:
	if codeTextPos > 0:
		codeRemoval() # delete one unit
	else:
		if !inGameMode:
			returnToTitle()
		else:
			allStatesFlywheel(false, true)


# Called when Clear button focused
func _on_button_clear_focus_entered() -> void:
	numberFocusState = 10


# Called when mouse hovers Clear button
func _on_button_clear_mouse_entered() -> void:
	numberFocusState = 10


# Called when Enter button pressed
func _on_button_enter_pressed() -> void:
	answerCheck() # always check on enter button


# Called when Enter button focused
func _on_button_enter_focus_entered() -> void:
	numberFocusState = 11


# Called when mouse hovers Enter button
func _on_button_enter_mouse_entered() -> void:
	numberFocusState = 11


# alpha of blur backdrop changes each frame with parent (self)
func _process(_delta: float) -> void:
	$Backdrop.material.set_shader_parameter("parentAlpha", self.modulate.a)

	inGameMode = Globals.currentAppState.get("gameRunning")
