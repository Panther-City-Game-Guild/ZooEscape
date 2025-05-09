extends Control

## states to control focus and input
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
var numberFocusState : int = 1 ## current focus

@onready var code := $Code ## text ref for code
var codeTextPos : int = 0 ## position in code

@export var inGameMode : bool = false ## used to determine behavior in and out of frontend
var windowOpenFlag : bool = false ## flag for checking if window is open
var inputBufferActive : bool = true ## hold input until window fades in
@export var loadSceneBufferTime : int = 1 ## buffer until password scene loads


## materials for shader changes on password entry
const correctShader = preload("res://Assets/Shaders/wobbly_material.tres")
const failShader = preload("res://Assets/Shaders/error_shake_x.tres")
const title = "res://Scenes/ZETitle.tscn"
const empty = "----"
const correctedVector = Vector2(-320,-160)


func _ready() -> void:
	code.text = empty ## reset text
	if !inGameMode: ## fade in and queue buffers, grab focus
		$Animator.play("fade_in")
		$InputBufferTimer.start()
		$ButtonBox/Button1.grab_focus()
		allStatesFlywheel(true,true) ## all hud flags true with animation in
	else:
		allStatesFlywheel(false,false) ## hud flags off but no animation
		self.position = correctedVector


func _input(_event: InputEvent) -> void:
	if !inGameMode and !inputBufferActive:
		fetchInput() ## listen for input outside game from frontend
		numberInputGrab()
	
	if inGameMode: ## listen for password button (escape)
		if Input.is_action_just_pressed("PasswordButton"):
			if !inputBufferActive: ## is input buffer expired? (waits from start)
				if windowOpenFlag == false: ## is window already open?
					$InputBufferTimer.start()
					$ButtonBox/Button1.grab_focus()
					buttonBatchControl(true)
					allStatesFlywheel(true,true) ## open all hud states, animation in
				else:
					buttonBatchControl(false)
					allStatesFlywheel(false,true)
			else: ## close all states with animation out
				allStatesFlywheel(false,true)


	if inGameMode and windowOpenFlag == true:
		fetchInput()
		numberInputGrab()


## for grabbing numeric input and updating number state
func numberInputGrab():
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


func _numericFocusCheck():
	if codeTextPos == 4:
		$ButtonBox/ButtonEnter.grab_focus()


func allStatesFlywheel(logic:bool,animate:bool):
	## first bool, logic for all hud states, second bool determines if animation necessary
	Globals.Current_Settings["passwordWindowOpen"] = logic ## global hud logic
	get_tree().paused = logic ## pause action and physics
	inputBufferActive = logic ## keep input buffer from hud
	windowOpenFlag = logic ## note input that window is open
	buttonBatchControl(logic)
	if animate: ## choose animation based on first bool or stay invisisble
		if logic:
			$Animator.play("fade_in") ## true
		else:
			$Animator.play_backwards("fade_in") ## false


func randomBlipCue(): ## sound cue for input sounds
	var _variant = randf_range(-0.7,0.7) ## random blips
	SoundControl.playCue(SoundControl.blip,(3.0+_variant))


func fetchInput(): ## grabbing global input
	if Input.is_action_just_pressed("PasswordButton"):
		SoundControl.playCue(SoundControl.down,2.0)
		if !inGameMode:
			returnToTitle()
		else:
			if !windowOpenFlag:
				get_tree().paused = true
				$Animator.play_backwards("fade_in")
				code.text = empty
				codeTextPos = 0
				inputBufferActive = true
				windowOpenFlag = true
			else:
				get_tree().paused = false
				
		
	if Input.is_action_just_pressed("ActionButton"):
		if numberFocusState == NUMBER_FOCUS_STATES.ENTER:
			answerCheck() ## check answers if on answer button
			
		if Globals.Game_Globals.has(code.text): ## if level code correct, show feedback
			SoundControl.playCue(SoundControl.success,2.5)
			$Code.material = correctShader
			$Code.modulate = Color.GREEN_YELLOW
			$LoadSceneBuffer.start(loadSceneBufferTime) ## begin buffer to load


		if !"-" in code.text: ## if no blanks, go to enter button
			numberFocusState = NUMBER_FOCUS_STATES.ENTER
			$ButtonBox/ButtonEnter.grab_focus()


	if Input.is_action_just_pressed("CancelButton"): ## if hitting backspace
		if codeTextPos > -1: ## single delete
			numberFocusState = NUMBER_FOCUS_STATES.CLEAR
			$ButtonBox/ButtonClear.grab_focus()
			codeRemoval()
		else:
			buttonBatchControl(false)
			allStatesFlywheel(false,true)
			if !inGameMode: ## if in from frontend, return thru frontend
				returnToTitle()


func codeRemoval(): ## code deletion function
	if codeTextPos != 0:
		codeTextPos -= 1
		code.text[codeTextPos] = "-"
	if codeTextPos <= 0: ## if on first, keep all code clear
		codeTextPos = 0
		code.text = empty


func buttonBatchControl(logic:bool): ## batch button logic for disabling and buffering
	var _buttons = get_tree().get_nodes_in_group("buttons")
	for _button in _buttons:
		if logic:
			_button.disabled = false
		else:
			_button.disabled = true


func returnToTitle(): ## return sound cue and load function
	SoundControl.playCue(SoundControl.down,1.4)
	SceneManager.call_deferred("GoToNewSceneString", title)


func answerCheck(): ## check code for answer
	if !code.text.contains("-") and Globals.Game_Globals.has(code.text): # yay
		$Code.material = correctShader
		$Code.modulate = Color.GREEN_YELLOW
		SoundControl.playCue(SoundControl.success,1.5)
		$LoadSceneBuffer.start(1)
	else: # nay, code clears out and timer sets for shader reset
		codeTextPos = 0
		$Code.text = "XXXX"
		$Code.material = failShader
		$Code.modulate = Color.CRIMSON
		SoundControl.playCue(SoundControl.down,1.5)
		$TextEffectTimer.start(0.5)


func _on_load_scene_buffer_timeout() -> void: ## load scene at end of load buffer timer
	SceneManager.call_deferred("GoToNewSceneString", Globals.Game_Globals[code.text])


## if there are dashes, accept input
func SetNum(): ## get number by state and input
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
	
	if codeTextPos < 4: ## add code until full
		code.text[codeTextPos] = num
		codeTextPos += 1
	## other functions will handle code once codeTestPos is full (4)



## this effect resets the password box to default material and style
func _on_effect_timer_timeout() -> void:
	codeTextPos = 0
	$Code.modulate = Color.WHITE
	$Code.material = null
	$Code.text = empty


## turns off input buffer, timer runs on window open
func _on_buffer_timer_timeout() -> void:
	inputBufferActive = false
	buttonBatchControl(true)


## number functions
func _on_button_1_pressed() -> void:
	SetNum() ## set number by button state


func _on_button_1_focus_entered() -> void:
	numberFocusState = 1 ## grab state


func _on_button_1_mouse_entered() -> void:
	numberFocusState = 1 ## grab state


func _on_button_2_pressed() -> void:
	SetNum()


func _on_button_2_focus_entered() -> void:
	numberFocusState = 2


func _on_button_2_mouse_entered() -> void:
	numberFocusState = 2


func _on_button_3_pressed() -> void:
	SetNum()


func _on_button_3_focus_entered() -> void:
	numberFocusState = 3


func _on_button_3_mouse_entered() -> void:
	numberFocusState = 3


func _on_button_4_pressed() -> void:
	SetNum()


func _on_button_4_focus_entered() -> void:
	numberFocusState = 4


func _on_button_4_mouse_entered() -> void:
	numberFocusState = 4


func _on_button_5_pressed() -> void:
	SetNum()


func _on_button_5_focus_entered() -> void:
	numberFocusState = 5


func _on_button_5_mouse_entered() -> void:
	numberFocusState = 5


func _on_button_6_pressed() -> void:
	SetNum()


func _on_button_6_focus_entered() -> void:
	numberFocusState = 6


func _on_button_6_mouse_entered() -> void:
	numberFocusState = 6


func _on_button_7_pressed() -> void:
	SetNum()


func _on_button_7_focus_entered() -> void:
	numberFocusState = 7


func _on_button_7_mouse_entered() -> void:
	numberFocusState = 7


func _on_button_8_pressed() -> void:
	SetNum()


func _on_button_8_focus_entered() -> void:
	numberFocusState = 8


func _on_button_8_mouse_entered() -> void:
	numberFocusState = 8


func _on_button_9_pressed() -> void:
	SetNum()


func _on_button_9_focus_entered() -> void:
	numberFocusState = 9


func _on_button_9_mouse_entered() -> void:
	numberFocusState = 9


func _on_button_0_pressed() -> void:
	SetNum()


func _on_button_0_focus_entered() -> void:
	numberFocusState = 0


func _on_button_0_mouse_entered() -> void:
	numberFocusState = 0


func _on_button_clear_pressed() -> void:
	if codeTextPos > 0:
		codeRemoval() ## delete one unit
	else:
		if !inGameMode:
			returnToTitle()
		else:
			allStatesFlywheel(false,true)


func _on_button_clear_focus_entered() -> void:
	numberFocusState = 10


func _on_button_clear_mouse_entered() -> void:
	numberFocusState = 10


func _on_button_enter_pressed() -> void:
	answerCheck() ## always check on enter button


func _on_button_enter_focus_entered() -> void:
	numberFocusState = 11


func _on_button_enter_mouse_entered() -> void:
	numberFocusState = 11
