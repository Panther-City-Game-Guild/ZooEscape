extends Control

## info to display for options
@export_multiline var masterInfo : String
@export_multiline var bgmInfo : String
@export_multiline var sfxInfo : String
@export_multiline var cueInfo : String
@export_multiline var deadzoneInfo : String
@export_multiline var exitInfo : String

## grab global value references
var masterVolume : int = Globals.Current_Options_Settings.get("master_volume")
var bgmVolume : int = Globals.Current_Options_Settings.get("music_volume")
var sfxVolume : int = Globals.Current_Options_Settings.get("sfx_volume")
var cueVolume : int = Globals.Current_Options_Settings.get("cue_volume")
var analogDeadzone : float = Globals.Current_Options_Settings.get("analog_deadzone")

## holders for percentage values
var masterPercent
var bgmPercent
var sfxPercent
var cuePercent

## set hard limits
const DEADZONE_MAX = 1.0
const DEADZONE_MIN = 0.20

var bufferState : bool = true
var focusGroup = FOCUS_GROUPS.MASTER
enum FOCUS_GROUPS {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE}


func _ready() -> void:
	## update text and set first button on master bgm down
	$MasterGroup/MasterSlider.grab_focus()
	focusInfoRelay("MASTER",masterInfo)
	$Description.text = masterInfo
	$Animator.play("roll_info")
	


func _process(_delta: float) -> void: ## single button fast value scroll in deadzone
	if !bufferState:
		if Input.is_action_pressed("ActionButton") and focusGroup == FOCUS_GROUPS.DEADZONE:
			if $DeadzoneGroup/DeadzoneDown.has_focus() and analogDeadzone > DEADZONE_MIN:
				analogDeadzone-=0.01
				$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
			if $DeadzoneGroup/DeadzoneUp.has_focus() and analogDeadzone < DEADZONE_MAX:
				analogDeadzone+=0.01
				$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	
		if Input.is_action_just_released("DigitalLeft") or Input.is_action_just_released("DigitalRight"):
			if focusGroup == FOCUS_GROUPS.SFX:
				SoundControl.playSfx(SoundControl.scratch)
			if focusGroup == FOCUS_GROUPS.CUE:
				SoundControl.playCue(SoundControl.pickup,1.0)
	
		if Input.is_action_just_pressed("CancelButton") or Input.is_action_just_pressed("PasswordButton"):
			if focusGroup != FOCUS_GROUPS.ESCAPE:
				_on_escape_button_focus_entered()
				$EscapeButton.grab_focus()
			else:
				_on_escape_button_pressed()


func globalSettingsUpdate(): ## update global settings
	Globals.Current_Options_Settings["master_volume"] = masterVolume
	Globals.Current_Options_Settings["music_volume"] = bgmVolume
	Globals.Current_Options_Settings["sfx_volume"] = sfxVolume
	Globals.Current_Options_Settings["cue_volume"] = cueVolume
	Globals.Current_Options_Settings["analog_deadzone"] = analogDeadzone
	SoundControl.setSoundPreferences(masterVolume,bgmVolume,sfxVolume,cueVolume)
	## set deadzones
	InputMap.action_set_deadzone("DigitalDown",analogDeadzone)
	InputMap.action_set_deadzone("DigitalUp",analogDeadzone)
	InputMap.action_set_deadzone("DigitalLeft",analogDeadzone)
	InputMap.action_set_deadzone("DigitalRight",analogDeadzone)


## focus info widget to update info text on focus change
func focusInfoRelay(logic:String,info:String):
	if focusGroup != FOCUS_GROUPS[logic]:
		focusGroup = FOCUS_GROUPS[logic]
		$Description.visible_ratio = 0.0
		$Description.text = str(info)
		$Animator.play("roll_info")


## widget to convert audio level to visual percent feedback
func percentageConversion(_volumeLevel):
	var _volume = abs(_volumeLevel) ## get volume level
	const _rate = 0.2 ## 20/100
	var _percentage = 100-roundi(abs(_volume/_rate)) ## take total from 100 for rate, clean display
	return _percentage ## return value and display in scene


func _on_master_slider_value_changed(value: float) -> void:
	if !bufferState: ## if no buffer, change levels
		masterVolume = $MasterGroup/MasterSlider.value
		masterPercent = abs(percentageConversion(masterVolume))
		$MasterGroup/MasterValue.text = str(masterPercent)+"%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


func _on_master_slider_focus_entered() -> void:
	focusInfoRelay("MASTER",masterInfo) ## focus grab


func _on_master_slider_mouse_entered() -> void:
	focusInfoRelay("MASTER",masterInfo) ## focus grab


func _on_bgm_slider_value_changed(value: float) -> void:
	if !bufferState:
		bgmVolume = $BGMGroup/BGMSlider.value
		bgmPercent = percentageConversion(bgmVolume)
		$BGMGroup/BGMValue.text = str(bgmPercent)+"%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()



func _on_bgm_slider_focus_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


func _on_bgm_slider_mouse_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


func _on_sfx_slider_value_changed(value: float) -> void:
	if !bufferState:
		sfxVolume = $SFXGroup/SFXSlider.value
		sfxPercent = percentageConversion(sfxVolume)
		$SFXGroup/SFXValue.text = str(sfxPercent)+"%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


func _on_sfx_slider_focus_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


func _on_sfx_slider_mouse_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


func _on_sfx_slider_drag_started() -> void:
	SoundControl.playSfx(SoundControl.scratch) ## audio cue for testing on grab


func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playSfx(SoundControl.scratch) ## audio cue for testing after release


func _on_cue_slider_value_changed(value: float) -> void:
	if !bufferState:
		cueVolume = $CueGroup/CueSlider.value
		cuePercent = percentageConversion(cueVolume)
		$CueGroup/CueValue.text = str(cuePercent)+"%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


func _on_cue_slider_focus_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


func _on_cue_slider_mouse_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


func _on_cue_slider_drag_started() -> void:
	SoundControl.playCue(SoundControl.pickup,1.0) ## audio cue for testing on grab


func _on_cue_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playCue(SoundControl.pickup,1.0) ## audio cue for testing after release


func _on_deadzone_down_pressed() -> void:
	if !bufferState:
		var _downValue = analogDeadzone-0.01
		if _downValue < DEADZONE_MIN:
			_downValue = DEADZONE_MIN

		analogDeadzone = _downValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		globalSettingsUpdate()


func _on_deadzone_down_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


func _on_deadzone_down_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


func _on_deadzone_up_pressed() -> void:
	if !bufferState:
		var _upValue = analogDeadzone+0.01
		if _upValue > DEADZONE_MAX:
			_upValue = DEADZONE_MAX

		analogDeadzone = _upValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		globalSettingsUpdate()


func _on_deadzone_up_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


func _on_deadzone_up_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


func _on_escape_button_pressed() -> void:
	if !bufferState:
		globalSettingsUpdate() ## update global settings
		SceneManager.GoToTitle() ## go to title


func _on_escape_button_focus_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


func _on_escape_button_mouse_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


func _on_input_buffer_timeout() -> void:
	bufferState = false
