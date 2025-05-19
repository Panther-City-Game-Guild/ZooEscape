extends Control

## info to display for options
@export_multiline var masterInfo : String
@export_multiline var bgmInfo : String
@export_multiline var sfxInfo : String
@export_multiline var cueInfo : String
@export_multiline var deadzoneInfo : String
@export_multiline var exitInfo : String

## grab global value references
var masterVolume : float = Globals.Current_Options_Settings.get("master_volume")
var bgmVolume : float = Globals.Current_Options_Settings.get("music_volume")
var sfxVolume : float = Globals.Current_Options_Settings.get("sfx_volume")
var cueVolume : float = Globals.Current_Options_Settings.get("cue_volume")
var analogDeadzone : float = Globals.Current_Options_Settings.get("analog_deadzone")

## holders for percentage values
var masterPercent : int
var bgmPercent : int
var sfxPercent : int
var cuePercent : int

## set hard limits
const DEADZONE_MAX := 1.0
const DEADZONE_MIN := 0.20

var bufferState := true ## hold player input until timer flips
var focusGroup := FOCUS_GROUPS.MASTER ## shows which control area has focus
enum FOCUS_GROUPS {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE}


func _ready() -> void:
	## update text and set first button on master bgm down
	## update all text and values with globals from load data
	ZeData.loadData()
	SoundControl.setSoundPreferences(masterVolume,bgmVolume,sfxVolume,cueVolume)
	
	## update percents
	masterPercent = percentageConversion(masterVolume)
	bgmPercent = percentageConversion(bgmVolume)
	sfxPercent = percentageConversion(sfxVolume)
	cuePercent = percentageConversion(cueVolume)
	
	## update slider positions
	$MasterGroup/MasterSlider.value = masterVolume
	$BGMGroup/BGMSlider.value = bgmVolume
	$SFXGroup/SFXSlider.value = sfxVolume
	$CueGroup/CueSlider.value = cueVolume
	
	## update percent texts
	$MasterGroup/MasterValue.text = str(masterPercent)+"%"
	$BGMGroup/BGMValue.text = str(bgmPercent)+"%"
	$SFXGroup/SFXValue.text = str(sfxPercent)+"%"
	$CueGroup/CueValue.text = str(cuePercent)+"%"
	$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	
	## grab first focus and roll in info text
	$MasterGroup/MasterSlider.grab_focus()
	focusInfoRelay("MASTER",masterInfo)
	$Description.text = masterInfo
	$Animator.play("roll_info")


func _process(_delta: float) -> void: ## single button fast value scroll in deadzone
	if !bufferState:
		if Input.is_action_pressed("ActionButton") and focusGroup == FOCUS_GROUPS.DEADZONE:
			if $DeadzoneGroup/DeadzoneDown.has_focus() and analogDeadzone > DEADZONE_MIN:
				analogDeadzone-=0.01 ## adjust deadzone and update text
				$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
			if $DeadzoneGroup/DeadzoneUp.has_focus() and analogDeadzone < DEADZONE_MAX:
				analogDeadzone+=0.01
				$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	
		if Input.is_action_just_released("DigitalLeft") or Input.is_action_just_released("DigitalRight"):
			if focusGroup == FOCUS_GROUPS.SFX: ## add sound cues to test fx levels
				SoundControl.playSfx(SoundControl.scratch)
			if focusGroup == FOCUS_GROUPS.CUE:
				SoundControl.playCue(SoundControl.pickup,1.0)
	
		if Input.is_action_just_pressed("CancelButton") or Input.is_action_just_pressed("PasswordButton"):
			if focusGroup != FOCUS_GROUPS.ESCAPE: ## move to escape button on press
				_on_escape_button_focus_entered()
				$EscapeButton.grab_focus()
			else:
				_on_escape_button_pressed() ## trigger escape function


func globalSettingsUpdate() -> void: ## update global settings
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
func focusInfoRelay(logic:String,info:String) -> void:
	if focusGroup != FOCUS_GROUPS[logic]:
		focusGroup = FOCUS_GROUPS[logic] ## pull group and grab info
		$Description.visible_ratio = 0.0 ## roll text back
		$Description.text = str(info) ## update
		$Animator.play("roll_info") ## roll in text


## widget to convert audio level to visual percent feedback
func percentageConversion(_volumeLevel) -> int:
	var _volume = abs(_volumeLevel) ## get volume level
	const _rate = 0.2 ## 20/100
	var _percentage = 100-roundi(abs(_volume/_rate)) ## take total from 100 for rate, clean display
	return _percentage ## return value and display in scene


## update master volume on slide
func _on_master_slider_value_changed(_value: float) -> void:
	if !bufferState: ## if no buffer, change levels
		masterTextUpdate()
		$MasterGroup/MasterValue.text = str(masterPercent)+"%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


## update text for master volume level
func masterTextUpdate() -> void:
	masterVolume = $MasterGroup/MasterSlider.value
	masterPercent = abs(percentageConversion(masterVolume))
	$MasterGroup/MasterValue.text = str(masterPercent)+"%"


## grab master group focus
func _on_master_slider_focus_entered() -> void:
	focusInfoRelay("MASTER",masterInfo) ## focus grab


func _on_master_slider_mouse_entered() -> void:
	focusInfoRelay("MASTER",masterInfo) ## focus grab


## update bgm levels
func _on_bgm_slider_value_changed(_value: float) -> void:
	if !bufferState:
		bgmTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


## on drag grab and release, check values for mute
func _on_bgm_slider_drag_ended(_value_changed: bool) -> void:
	if $BGMGroup/BGMSlider.value <= -20:
		SoundControl.stopBgm()
	else:
		SoundControl.playBgm()

## on drag grab and release, check values for mute
func _on_bgm_slider_drag_started() -> void:
	if $BGMGroup/BGMSlider.value <= -20:
		SoundControl.stopBgm()
	else:
		SoundControl.playBgm()


## update text for bgm volume level
func bgmTextUpdate() -> void:
	bgmVolume = $BGMGroup/BGMSlider.value
	bgmPercent = percentageConversion(bgmVolume)
	$BGMGroup/BGMValue.text = str(bgmPercent)+"%"


## grab bgm focus
func _on_bgm_slider_focus_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


func _on_bgm_slider_mouse_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


## update sfx level
func _on_sfx_slider_value_changed(_value: float) -> void:
	if !bufferState:
		sfxTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


## update text for sfx volume level
func sfxTextUpdate() -> void:
	sfxVolume = $SFXGroup/SFXSlider.value
	sfxPercent = percentageConversion(sfxVolume)
	$SFXGroup/SFXValue.text = str(sfxPercent)+"%"


## grab sfx focus
func _on_sfx_slider_focus_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


func _on_sfx_slider_mouse_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


func _on_sfx_slider_drag_started() -> void:
	SoundControl.playSfx(SoundControl.scratch) ## audio cue for testing on grab


func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playSfx(SoundControl.scratch) ## audio cue for testing after release


## update cue levels
func _on_cue_slider_value_changed(_value: float) -> void:
	if !bufferState:
		cueTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


## update text for cue volume level
func cueTextUpdate() -> void:
	cueVolume = $CueGroup/CueSlider.value
	cuePercent = percentageConversion(cueVolume)
	$CueGroup/CueValue.text = str(cuePercent)+"%"


## grab cue group focus
func _on_cue_slider_focus_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


func _on_cue_slider_mouse_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


func _on_cue_slider_drag_started() -> void:
	SoundControl.playCue(SoundControl.pickup,1.0) ## audio cue for testing on grab


func _on_cue_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playCue(SoundControl.pickup,1.0) ## audio cue for testing after release


## update deadzone levels
func _on_deadzone_down_pressed() -> void:
	if !bufferState:
		var _downValue = analogDeadzone-0.01
		if _downValue < DEADZONE_MIN:
			_downValue = DEADZONE_MIN

		analogDeadzone = _downValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		globalSettingsUpdate()


## grab deadzone focus
func _on_deadzone_down_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


func _on_deadzone_down_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


## update deadzone levels
func _on_deadzone_up_pressed() -> void:
	if !bufferState:
		var _upValue = analogDeadzone+0.01
		if _upValue > DEADZONE_MAX:
			_upValue = DEADZONE_MAX

		analogDeadzone = _upValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		globalSettingsUpdate()


## grab deadzone focus
func _on_deadzone_up_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


func _on_deadzone_up_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


## save data on escape
func _on_escape_button_pressed() -> void:
	if !bufferState:
		ZeData.saveGameData()
		globalSettingsUpdate() ## update global settings
		SceneManager.GoToTitle() ## go to title


## grab escape button focus
func _on_escape_button_focus_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


func _on_escape_button_mouse_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


## input buffer added to avoid accidental input on load
func _on_input_buffer_timeout() -> void:
	bufferState = false
