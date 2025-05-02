extends Control


## numbers to hone focus
var numberFocusState : int = 1
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

@onready var code := $Code ## code label
@onready var codeTextPos := 0 ## position in code label
@export var inGameMode : bool = false ## used to determine behavior in-game
var windowOpenFlag : bool = false ## flag for checking if window is open
var inputBufferActive : bool = true ## hold input until window fades in


## materials for shader changes on password entry
const correctShader = preload("res://Assets/Shaders/wobbly_material.tres")
const failShader = preload("res://Assets/Shaders/error_shake_x.tres")
const empty = "----"
var loadedScene = "" ## holder for scene reference when successful



func _ready() -> void:
	code.text = empty ## empty code box

	if !inGameMode: ## if in game, start animator and buffer
		$Animator.play("fade_in")
		$BufferTimer.start()
	else: ## disable buffer if opened in game
		inputBufferActive = false


func _input(_event: InputEvent) -> void:
	## fetch player input and feedback if open
	if !inGameMode and !inputBufferActive:
		fetch_UI_Input()
		randomInputSoundCue()


	if inGameMode: ## listen for cancel commands to open/close password menu
		if Input.is_action_just_pressed("ui_cancel") and !inputBufferActive:
			if windowOpenFlag == false:
				Globals.Game_Globals["IsPasswordInterfaceOpen"] = true
				$BufferTimer.start(0.5)
				get_tree().paused = true
				windowOpenFlag = true
				$Animator.play("fade_in")
			else:
				Globals.Game_Globals["IsPasswordInterfaceOpen"] = false
				batchButtonDisabled(true)


		fetch_UI_Input() ## listen for UI changes in password window if open


func randomInputSoundCue(): ## for randomizing sound cues
	var _variant = randf_range(-0.7,0.7) ## random blips
	SoundControl.playCue(SoundControl.blip,(3.0+_variant))


func fetch_UI_Input(): ## listen for cancel and answer commands
	if Input.is_action_just_pressed("ui_cancel"):
		SoundControl.playCue(SoundControl.down,2.0)

		if !inGameMode:
			SceneManager.GoToNewSceneString(self, Scenes.ZETitle)




		if !inGameMode:
			SceneManager.GoToNewSceneString(self, Scenes.ZETitle)
		else:
			Globals.Game_Globals["isPasswordWindowOpen"] = false


	if Input.is_action_just_released("ActionButton"):
		if numberFocusState == NUMBER_FOCUS_STATES.ENTER:
			answerCheck()


func answerCheck(): ## check answer and deliver feedback accordingly
	if !code.text.contains("-"):
		if Globals.Game_Globals.has(code.text):
			## if correct, close open password global flag, throw feedback and disable buttons
			Globals.Game_Globals["IsPasswordInterfaceOpen"] = false
			SoundControl.playCue(SoundControl.success,2.5)
			$Code.material = correctShader
			$Code.modulate = Color.GREEN_YELLOW
			$LevelChangeTimer.start(0.5)
			batchButtonDisabled(true)
		else: ## if fail, reset code and show feedback
			$EffectTimer.start(0.25)
			code.text = empty
			codeTextPos = 0
			loadedScene = null
			failFeedback()


func failFeedback(): ## shortcut for fail visual feedback
	$Code.modulate = Color.CRIMSON
	$Code.material = failShader
	SoundControl.playCue(SoundControl.alert,1.0)


## if there are dashes, accept input
func SetNum():
	randomInputSoundCue()
	var num := ""
	match numberFocusState: ## match number to enum for entry
		NUMBER_FOCUS_STATES.ZERO:
			num = "0"
		NUMBER_FOCUS_STATES.ONE:
			num = "1"
		NUMBER_FOCUS_STATES.TWO:
			num = "2"
		NUMBER_FOCUS_STATES.THREE:
			num = "3"
		NUMBER_FOCUS_STATES.FOUR:
			num = "4"
		NUMBER_FOCUS_STATES.FIVE:
			num = "5"
		NUMBER_FOCUS_STATES.SIX:
			num = "6"
		NUMBER_FOCUS_STATES.SEVEN:
			num = "7"
		NUMBER_FOCUS_STATES.EIGHT:
			num = "8"
		NUMBER_FOCUS_STATES.NINE:
			num = "9"
	

	if codeTextPos < 4: ## progress digit for entry if not at end
		code.text[codeTextPos] = num
		codeTextPos += 1

	if codeTextPos == 4: ## go to answer button if ready
		numberFocusState = NUMBER_FOCUS_STATES.ENTER
		$ButtonBox/ButtonE.grab_focus()



## this effect resets the password box to default material and style after fail
func _on_effect_timer_timeout() -> void:
	if loadedScene == null:
		$Code.modulate = Color.WHITE
		$Code.material = null
		$Code.text = empty



## turns off input buffer, timer runs on window open
func _on_buffer_timer_timeout() -> void:
	inputBufferActive = false
	batchButtonDisabled(false)
	$ButtonBox/Button1.grab_focus()


func _on_level_change_timer_timeout() -> void: ## go to password level on timeout
	SceneManager.GoToNewSceneString(self,Globals.Game_Globals[code.text])


#### ______ BUTTON PRESS & CONTROL FUNCTIONS ______ #####


## function to disable buttons on scene changes
func batchButtonDisabled(mode:bool):
	var _buttonBatch = get_tree().get_nodes_in_group("pw_buttons")
	for _button in _buttonBatch:
		if mode == true:
			_button.disabled = true
		else:
			_button.disabled = false


## buttons set state 
func _on_button_0_pressed() -> void:
	numberFocusState = 0
	SetNum()


func _on_button_1_pressed() -> void:
	numberFocusState = 1
	SetNum()


func _on_button_2_pressed() -> void:
	numberFocusState = 2
	SetNum()


func _on_button_3_pressed() -> void:
	numberFocusState = 3
	SetNum()


func _on_button_4_pressed() -> void:
	numberFocusState = 4
	SetNum()


func _on_button_5_pressed() -> void:
	numberFocusState = 5
	SetNum()


func _on_button_6_pressed() -> void:
	numberFocusState = 6
	SetNum()


func _on_button_7_pressed() -> void:
	numberFocusState = 7
	SetNum()


func _on_button_8_pressed() -> void:
	numberFocusState = 8
	SetNum()


func _on_button_9_pressed() -> void:
	numberFocusState = 9
	SetNum()


func _on_button_c_pressed() -> void:
	$EffectTimer.start(0.25)
	$ButtonBox/ButtonC.grab_focus()
	failFeedback()
	if code.text != empty:
		if codeTextPos > -1:
			codeClear()
			codeTextPos-=1
		elif codeTextPos >= 3:
			code.text[3] = "-"
			codeTextPos-=1


	if codeTextPos == -1:
		if !inGameMode:
			SceneManager.GoToNewSceneString(self, Scenes.ZETitle)
		else:
			Globals.Game_Globals["isPasswordWindowOpen"] = false
			$Animator.play_backwards("fade_in")


func codeClear() -> void:
	SoundControl.playCue(SoundControl.down,2.0)
	if codeTextPos >= -1 and codeTextPos <= 3:
		code.text[codeTextPos] = "-"
		$EffectTimer.start(0.25)


func _on_button_e_pressed() -> void:
	if codeTextPos == 4:
		if Globals.Game_Globals.has(code.text):
			loadedScene = code.text
			$LevelChangeTimer.start()
			batchButtonDisabled(true)
			SoundControl.playCue(SoundControl.success,2.5)
			$Code.material = correctShader
			$Code.modulate = Color.GREEN_YELLOW
			Globals.Game_Globals["isPasswordInteraceOpen"] = false
		else:
			code.text = empty
			codeTextPos = 0
			loadedScene = null
			$EffectTimer.start(0.5)
			failFeedback()
	else:
		code.text = empty
		codeTextPos = 0
		loadedScene = null
		$EffectTimer.start(0.5)
		failFeedback()


	

### _______ MOUSE ENTRY FUNCTIONS __________ ###
### mouse entry changes focus state ###

func _on_button_0_mouse_entered() -> void:
	numberFocusState = 0


func _on_button_1_mouse_entered() -> void:
	numberFocusState = 1


func _on_button_2_mouse_entered() -> void:
	numberFocusState = 2


func _on_button_3_mouse_entered() -> void:
	numberFocusState = 3


func _on_button_4_mouse_entered() -> void:
	numberFocusState = 4


func _on_button_5_mouse_entered() -> void:
	numberFocusState = 5


func _on_button_6_mouse_entered() -> void:
	numberFocusState = 6


func _on_button_7_mouse_entered() -> void:
	numberFocusState = 7


func _on_button_8_mouse_entered() -> void:
	numberFocusState = 8


func _on_button_9_mouse_entered() -> void:
	numberFocusState = 9


func _on_button_c_mouse_entered() -> void:
	numberFocusState = 10


func _on_button_e_mouse_entered() -> void:
	numberFocusState = 11


### _____ FOCUS ENTRY FUNCTIONS _____ ###
### focus entry changes button state ###

func _on_button_0_focus_entered() -> void:
	numberFocusState = 0


func _on_button_1_focus_entered() -> void:
	numberFocusState = 1


func _on_button_2_focus_entered() -> void:
	numberFocusState = 2


func _on_button_3_focus_entered() -> void:
	numberFocusState = 3


func _on_button_4_focus_entered() -> void:
	numberFocusState = 4


func _on_button_5_focus_entered() -> void:
	numberFocusState = 5


func _on_button_6_focus_entered() -> void:
	numberFocusState = 6


func _on_button_7_focus_entered() -> void:
	numberFocusState = 7


func _on_button_8_focus_entered() -> void:
	numberFocusState = 8


func _on_button_9_focus_entered() -> void:
	numberFocusState = 9


func _on_button_c_focus_entered() -> void:
	numberFocusState = 10


func _on_button_e_focus_entered() -> void:
	numberFocusState = 11

