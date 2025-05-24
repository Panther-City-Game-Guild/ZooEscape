extends Control

enum FOCUS_GROUPS {
	ESCAPE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE
}

# info to display for options
@export_multiline var masterInfo : String
@export_multiline var bgmInfo : String
@export_multiline var sfxInfo : String
@export_multiline var cueInfo : String
@export_multiline var deadzoneInfo : String
@export_multiline var exitInfo : String

# grab global value references
var masterVolume : float = Globals.currentSettings.get("master_volume")
var bgmVolume : float = Globals.currentSettings.get("music_volume")
var sfxVolume : float = Globals.currentSettings.get("sfx_volume")
var cueVolume : float = Globals.currentSettings.get("cue_volume")
var analogDeadzone : float = Globals.currentSettings.get("analog_deadzone")

# holders for percentage values
var masterPercent : int
var bgmPercent : int
var sfxPercent : int
var cuePercent : int

# set hard limits
const DEADZONE_MAX := 1.0
const DEADZONE_MIN := 0.20

var bufferState := true # hold player input until timer flips
var focusGroup := FOCUS_GROUPS.MASTER # shows which control area has focus

# holders for UI elements for batch disabling/enabling
var sliders : Array = []
var buttons : Array = []


# Called when node enters the scene tree for the first time
func _ready() -> void:
	sliders = get_tree().get_nodes_in_group("sliders")
	buttons = get_tree().get_nodes_in_group("buttons")
	# update text and set first button on master bgm down
	# update all text and values with globals from load data
	
	# update percents
	masterPercent = percentageConversion(masterVolume)
	bgmPercent = percentageConversion(bgmVolume)
	sfxPercent = percentageConversion(sfxVolume)
	cuePercent = percentageConversion(cueVolume)
	
	# update slider positions
	$MasterGroup/MasterSlider.value = masterVolume
	$BGMGroup/BGMSlider.value = bgmVolume
	$SFXGroup/SFXSlider.value = sfxVolume
	$CueGroup/CueSlider.value = cueVolume
	
	# update percent texts
	$MasterGroup/MasterValue.text = str(masterPercent) + "%"
	$BGMGroup/BGMValue.text = str(bgmPercent) + "%"
	$SFXGroup/SFXValue.text = str(sfxPercent) + "%"
	$CueGroup/CueValue.text = str(cuePercent) + "%"
	$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	
	# grab first focus and roll in info text
	$MasterGroup/MasterSlider.grab_focus()
	focusInfoRelay("MASTER", masterInfo)
	$Description.text = masterInfo
	$Animator.play("roll_info")
	
	
	if Globals.currentAppState.get("gameRunning") == false:
		$Fader.play("open")
	else:
		windowPlacement()
		$EscapeButton.text = "0 / TAB"
		exitInfo = "Return to game and unpause."


## places the window in player view
func windowPlacement() -> void:
	var _player : CharacterBody2D = get_tree().get_first_node_in_group("Player")
	var _pos = Vector2(_player.global_position)
		
	self.position.x = _pos.x-320
	self.position.y = _pos.y-180


# Called every render frame
func _process(_delta: float) -> void: # single button fast value scroll in deadzone
	if !bufferState: # make sure buffer has passed to avoid ghost input
		if Input.is_action_pressed("ActionButton") and focusGroup == FOCUS_GROUPS.DEADZONE:
			if $DeadzoneGroup/DeadzoneDown.has_focus() and analogDeadzone > DEADZONE_MIN:
				analogDeadzone -= 0.01 # adjust deadzone and update text
				$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
			if $DeadzoneGroup/DeadzoneUp.has_focus() and analogDeadzone < DEADZONE_MAX:
				analogDeadzone += 0.01
				$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
	
		## give audio cues on input for sfx and cue value change
		if Input.is_action_just_released("DigitalLeft") or Input.is_action_just_released("DigitalRight"):
			if focusGroup == FOCUS_GROUPS.SFX: # add sound cues to test fx levels
				SoundControl.playSfx(SoundControl.scratch)
			if focusGroup == FOCUS_GROUPS.CUE:
				SoundControl.playCue(SoundControl.pickup, 1.0)


		## is game not running, allow exit/focus on exit with either button
		if Globals.currentAppState.get("gameRunning") == false:
			if Input.is_action_just_pressed("CancelButton") or Input.is_action_just_pressed("PasswordButton"):
				if focusGroup != FOCUS_GROUPS.ESCAPE: # move to escape button on press
					_on_escape_button_focus_entered()
					$EscapeButton.grab_focus()
				else:
					_on_escape_button_pressed() # trigger escape function
		
		
		## if settings button pressed in game, place window then open or close
		if Input.is_action_just_pressed("SettingsButton"):
			if Globals.currentAppState.get("gameRunning") == true: ## only do this in game
				if !get_tree().paused: ## listen to process state to determine correct behavior
					windowPlacement()
					openSettingsCall()
				else:
					closeSettingsCall()


# update settings in global dictionary, update global volume buses and set deadzones
func globalSettingsUpdate() -> void: # update global settings
	Globals.currentSettings["master_volume"] = masterVolume
	Globals.currentSettings["music_volume"] = bgmVolume
	Globals.currentSettings["sfx_volume"] = sfxVolume
	Globals.currentSettings["cue_volume"] = cueVolume
	Globals.currentSettings["analog_deadzone"] = analogDeadzone
	# set sound levels
	SoundControl.setSoundPreferences(masterVolume, bgmVolume, sfxVolume, cueVolume)
	# set deadzones
	Globals.deadzoneUpdate()


# focus info widget to update info text on focus change
func focusInfoRelay(logic:String,info:String) -> void:
	if focusGroup != FOCUS_GROUPS[logic]:
		focusGroup = FOCUS_GROUPS[logic] # pull group and grab info
		$Description.visible_ratio = 0.0 # roll text back
		$Description.text = str(info) # update
		$Animator.play("roll_info") # roll in text


# widget to convert audio level to visual percent feedback
func percentageConversion(_volumeLevel) -> int:
	var _volume: float = abs(_volumeLevel) # get volume level
	const _rate := 0.2 # 20/100
	var _percentage := 100 - roundi(abs(_volume / _rate)) # take total from 100 for rate, clean display
	return _percentage # return value and display in scene


# function to open the settings window in-game
func openSettingsCall() -> void:
	Globals.currentAppState.set("settingsWindowOpen", true)
	$Fader.play("open") ## open animation
	get_tree().paused = true # hold processing
	for button in buttons: # enable buttons and sliders
		button.disabled = false
	for slider in sliders:
		slider.editable = true


# function to close settings window in-game
func closeSettingsCall() -> void:
	Globals.currentAppState.set("settingsWindowOpen", false)
	$Fader.play_backwards("open") ## close animation
	get_tree().paused = false # resume processing
	for button in buttons: # disable buttons and sliders
		button.disabled = true
	for slider in sliders:
		slider.editable = false
	
	$EscapeButton.disabled = false


# update master volume on slide
func _on_master_slider_value_changed(_value: float) -> void:
	if !bufferState: # if no buffer, change levels
		masterTextUpdate()
		$MasterGroup/MasterValue.text = str(masterPercent) + "%"
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# update text for master volume level
func masterTextUpdate() -> void:
	masterVolume = $MasterGroup/MasterSlider.value
	masterPercent = abs(percentageConversion(masterVolume))
	$MasterGroup/MasterValue.text = str(masterPercent) + "%"


# grab master group focus
func _on_master_slider_focus_entered() -> void:
	focusInfoRelay("MASTER", masterInfo) # focus grab


# mouse hovering master slider
func _on_master_slider_mouse_entered() -> void:
	focusInfoRelay("MASTER", masterInfo) # focus grab


# update bgm levels
func _on_bgm_slider_value_changed(_value: float) -> void:
	if !bufferState:
		bgmTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# on drag grab and release, check values for mute
func _on_bgm_slider_drag_ended(_value_changed: bool) -> void:
	if $BGMGroup/BGMSlider.value <= -20:
		SoundControl.stopBgm()
	else:
		SoundControl.playBgm()


# on drag grab and release, check values for mute
func _on_bgm_slider_drag_started() -> void:
	if $BGMGroup/BGMSlider.value <= -20:
		SoundControl.stopBgm()
	else:
		SoundControl.playBgm()


# update text for bgm volume level
func bgmTextUpdate() -> void:
	bgmVolume = $BGMGroup/BGMSlider.value
	bgmPercent = percentageConversion(bgmVolume)
	$BGMGroup/BGMValue.text = str(bgmPercent) + "%"


# grab bgm focus
func _on_bgm_slider_focus_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


# mouse hovering bgm slider
func _on_bgm_slider_mouse_entered() -> void:
	focusInfoRelay("BGM", bgmInfo)


# update sfx level
func _on_sfx_slider_value_changed(_value: float) -> void:
	if !bufferState:
		sfxTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# update text for sfx volume level
func sfxTextUpdate() -> void:
	sfxVolume = $SFXGroup/SFXSlider.value
	sfxPercent = percentageConversion(sfxVolume)
	$SFXGroup/SFXValue.text = str(sfxPercent) + "%"


# grab sfx focus
func _on_sfx_slider_focus_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


# mouse hovering sfx slider
func _on_sfx_slider_mouse_entered() -> void:
	focusInfoRelay("SFX", sfxInfo)


# sound fx test on starting drag
func _on_sfx_slider_drag_started() -> void:
	SoundControl.playSfx(SoundControl.scratch) # audio cue for testing on grab


# sound fx test on releasing drag
func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playSfx(SoundControl.scratch) # audio cue for testing after release


# update cue levels
func _on_cue_slider_value_changed(_value: float) -> void:
	if !bufferState:
		cueTextUpdate()
		globalSettingsUpdate()
		SoundControl.muteAudioBusCheck()


# update text for cue volume level
func cueTextUpdate() -> void:
	cueVolume = $CueGroup/CueSlider.value
	cuePercent = percentageConversion(cueVolume)
	$CueGroup/CueValue.text = str(cuePercent) + "%"


# grab cue group focus
func _on_cue_slider_focus_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


# grab cue focus
func _on_cue_slider_mouse_entered() -> void:
	focusInfoRelay("CUE", cueInfo)


# cue test on drag
func _on_cue_slider_drag_started() -> void:
	SoundControl.playCue(SoundControl.pickup, 1.0) # audio cue for testing on grab


# cue test on release
func _on_cue_slider_drag_ended(_value_changed: bool) -> void:
	SoundControl.playCue(SoundControl.pickup, 1.0) # audio cue for testing after release


# update deadzone levels
func _on_deadzone_down_pressed() -> void:
	if !bufferState:
		var _downValue := analogDeadzone - 0.01
		if _downValue < DEADZONE_MIN:
			_downValue = DEADZONE_MIN

		analogDeadzone = _downValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		Globals.deadzoneUpdate()


# grab deadzone focus
func _on_deadzone_down_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# grab deadzone focus
func _on_deadzone_down_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# update deadzone levels
func _on_deadzone_up_pressed() -> void:
	if !bufferState:
		var _upValue := analogDeadzone + 0.01
		if _upValue > DEADZONE_MAX:
			_upValue = DEADZONE_MAX

		analogDeadzone = _upValue
		$DeadzoneGroup/DeadzoneValue.text = str(analogDeadzone)
		Globals.deadzoneUpdate()


# grab deadzone focus
func _on_deadzone_up_focus_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# grab deadzone focus
func _on_deadzone_up_mouse_entered() -> void:
	focusInfoRelay("DEADZONE", deadzoneInfo)


# save data on escape
func _on_escape_button_pressed() -> void:
	if !bufferState:
		if Globals.currentAppState.get("gameRunning") == false:
			Data.saveGameData()
			globalSettingsUpdate() # update global settings
			SceneManager.goToTitle() # go to title
		else:
			if Globals.currentAppState.get("settingsWindowOpen") == false:
				openSettingsCall()
			else:
				closeSettingsCall()


# grab escape button focus
func _on_escape_button_focus_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


# grab escape button focus
func _on_escape_button_mouse_entered() -> void:
	focusInfoRelay("ESCAPE", exitInfo)


# input buffer added to avoid accidental input on load
func _on_input_buffer_timeout() -> void:
	bufferState = false
