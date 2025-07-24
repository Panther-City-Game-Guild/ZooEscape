class_name SettingsMenu extends Panel

# Signals
signal GoBack

# Enums
enum groupTypes {
	NONE,
	CLOSE,
	MASTER,
	BGM,
	SFX,
	CUE,
	DEADZONE
}

# Info to display for options
const groupHints := {
	groupTypes.NONE: "",
	groupTypes.CLOSE: "Close this menu.  Settings \n are automatically saved.",
	groupTypes.MASTER: "Controls total volume of \nall sound.",
	groupTypes.BGM: "Controls volume level \nof background music.",
	groupTypes.SFX: "Controls volume level of \nsound effects.",
	groupTypes.CUE: "Controls volume of system \ncues like pause noises.",
	groupTypes.DEADZONE: "Controls the level at which \nanalog direction inputs trigger."
}

# Variables
var settingsChanged := false # only save settings if any values were changed
var focusGroup := groupTypes.NONE # shows which control area has focus

# Handles to groups, group labels, sliders, value labels, and button(s)
@onready var groups: Dictionary[groupTypes, HBoxContainer]= {
	groupTypes.MASTER: $VBox/MasterGroup,
	groupTypes.BGM: $VBox/BGMGroup,
	groupTypes.SFX: $VBox/SFXGroup,
	groupTypes.CUE: $VBox/CueGroup,
	groupTypes.DEADZONE: $VBox/DeadzoneGroup
}

@onready var groupLabels: Dictionary[groupTypes, Label] = {
	groupTypes.MASTER: $VBox/MasterGroup/MasterText,
	groupTypes.BGM: $VBox/BGMGroup/BGMText,
	groupTypes.SFX: $VBox/SFXGroup/SFXText,
	groupTypes.CUE: $VBox/CueGroup/CueText,
	groupTypes.DEADZONE: $VBox/DeadzoneGroup/DeadzoneText
}

@onready var sliders: Dictionary[groupTypes, HSlider] = {
	groupTypes.MASTER: $VBox/MasterGroup/MasterSlider,
	groupTypes.BGM: $VBox/BGMGroup/BGMSlider,
	groupTypes.SFX: $VBox/SFXGroup/SFXSlider,
	groupTypes.CUE: $VBox/CueGroup/CueSlider,
	groupTypes.DEADZONE: $VBox/DeadzoneGroup/DeadzoneSlider
}

@onready var valueHints: Dictionary[groupTypes, Label] = {
	groupTypes.MASTER: $VBox/MasterGroup/MasterValue,
	groupTypes.BGM: $VBox/BGMGroup/BGMValue,
	groupTypes.SFX: $VBox/SFXGroup/SFXValue,
	groupTypes.CUE: $VBox/CueGroup/CueValue,
	groupTypes.DEADZONE: $VBox/DeadzoneGroup/DeadzoneValue
}

@onready var closeButton: Button = $VBox/Header/CloseButton


# Called when node enters the scene tree for the first time
func _ready() -> void:
	var settings := {
		groupTypes.MASTER: Globals.currentSettings.masterVolume,
		groupTypes.BGM: Globals.currentSettings.musicVolume,
		groupTypes.SFX: Globals.currentSettings.sfxVolume,
		groupTypes.CUE: Globals.currentSettings.cueVolume,
		groupTypes.DEADZONE: Globals.currentSettings.analogDeadzone
	}
	
	# Connect exit button signals
	closeButton.mouse_entered.connect(onMouseEntered.bind(groupTypes.CLOSE))
	closeButton.focus_entered.connect(onFocusEntered.bind(groupTypes.CLOSE))
	closeButton.pressed.connect(returnToLastMenu)
	
	# Connect group signals
	for group: HBoxContainer in groups.values():
		var key: groupTypes = groups.find_key(group)
		group.mouse_entered.connect(onMouseEntered.bind(key))
	
	# Connect slider signals and set values
	for slider: HSlider in sliders.values():
		var key: groupTypes = sliders.find_key(slider)
		slider.mouse_entered.connect(onMouseEntered.bind(key))
		slider.value_changed.connect(onSliderValueChanged.bind(key))
		slider.focus_entered.connect(onFocusEntered.bind(key))
		if key != groupTypes.DEADZONE:
			slider.drag_started.connect(onDragStartOrEnd.bind(0.0, key))
			slider.drag_ended.connect(onDragStartOrEnd.bind(key))
		slider.value = settings[key]
		updateValueHint(key, settings[key])


# Called when InputEvent detected
func _input(event: InputEvent) -> void:
	if !visible || event.is_echo(): # Only detect inputs when this menu is visible
		return
	
	# If Escape or other CancelButtton pressed, close the munu
	if event.is_action_pressed("CancelButton"):
		get_viewport().set_input_as_handled() # Prevent more nodes from processing this input
		returnToLastMenu() # trigger escape function
	
	# If Left or Right released after adjusting SFX or CUE sliders, play a sound
	if (event.is_action_released("DigitalLeft") || event.is_action_released("DigitalRight")):
		if focusGroup == groupTypes.SFX: # add sound cues to test fx levels
			SoundControl.playSfx(SoundControl.scratch)
		if focusGroup == groupTypes.CUE:
			SoundControl.playCue(SoundControl.pickup, 1.0)
	
	if (event.is_action_released("DigitalUp")) || event.is_action_released("DigitalDown"):
		if focusGroup != groupTypes.BGM:
			$LocalBgmTest.stop()


# Called by the MenuManager to show the SettingsMenu
func showMenu() -> void:
	sliders[groupTypes.MASTER].call_deferred("grab_focus")
	show()


# Called to go back in the menu heap - also saves settings if any changed
func returnToLastMenu() -> void:
	if settingsChanged:
		Data.saveSettingsData()
		settingsChanged = false
		$LocalBgmTest.stop() # stop any triggering testers
		$LocalMasterTest.stop()
	SoundControl.playCue(SoundControl.down, 1.4)
	updateDescriptionHint(groupTypes.CLOSE) # This removes any theme overrides from control groups
	GoBack.emit()


# Update description text to new groupHint
func updateDescriptionHint(which: groupTypes) -> void:
	var lastGroup: groupTypes
	if !focusGroup == which:
		lastGroup = focusGroup
		focusGroup = which
		if groupLabels.has(focusGroup):
			groupLabels[focusGroup].add_theme_color_override("font_color", Color("#6bffbc"))
			valueHints[focusGroup].add_theme_color_override("font_color", Color("#6bffbc"))
		$VBox/Description.visible_ratio = 0.0 # roll text back
		$VBox/Description.text = groupHints[which]
		$Animator.play("roll_info") # roll in text
	if lastGroup != focusGroup && groupLabels.has(lastGroup):
		groupLabels[lastGroup].remove_theme_color_override("font_color")
		valueHints[lastGroup].remove_theme_color_override("font_color")


# Update valueHints when value changed
func updateValueHint(which: groupTypes, value: float):
	match which:
		groupTypes.MASTER, groupTypes.BGM, groupTypes.SFX, groupTypes.CUE:
			valueHints[which].text = str(abs(percentageConversion(value))) + "%"
		
		groupTypes.DEADZONE:
			valueHints[which].text = str(value)


# Convert audio level to visual percent feedback
func percentageConversion(volumeLevel) -> int:
	var volume: float = abs(volumeLevel) # get volume level
	const rate := 0.2 # 20/100
	var percentage := 100 - roundi(abs(volume / rate)) # take total from 100 for rate, clean display
	return percentage # return value and display in scene


# EVENT HANDLERS
# Any slider value changed
func onSliderValueChanged(value: float, which: groupTypes):
	settingsChanged = true
	match which:
		groupTypes.MASTER:
			Globals.currentSettings.masterVolume = value # update master level
			if MenuManager.currentMenu == MenuManager.menuTypes.SETTINGS and !$LocalMasterTest.playing: # do not trigger unless settings open
				$LocalMasterTest.play() # use local master bus object to test master (allows test while pausing)
		groupTypes.BGM:
			Globals.currentSettings.musicVolume = value # update bgm level 
			if MenuManager.currentMenu == MenuManager.menuTypes.SETTINGS and !$LocalBgmTest.playing:
				$LocalBgmTest.play() # use local bgm bus check to test volume (allows test while pausing)
		groupTypes.SFX:
			Globals.currentSettings.sfxVolume = value # update sfx level
		groupTypes.CUE:
			Globals.currentSettings.cueVolume = value # update cue level
		groupTypes.DEADZONE:
			Globals.currentSettings.analogDeadzone = value # update deadzone
	
	updateValueHint(which, value)
	
	if !which == groupTypes.DEADZONE:
		SoundControl.updateVolumeLevels()
		SoundControl.muteAudioBusCheck()
	else:
		Globals.deadzoneUpdate()


# Mouse hovering slider or CloseButton
func onMouseEntered(which: groupTypes) -> void:
	if !which == groupTypes.CLOSE:
		sliders[which].call_deferred("grab_focus")
	else:
		closeButton.call_deferred("grab_focus")
	updateDescriptionHint(which)


# Slider or CloseButton gained focus
func onFocusEntered(which: groupTypes) -> void:
	match which:
		groupTypes.MASTER, groupTypes.BGM, groupTypes.SFX, groupTypes.CUE, groupTypes.DEADZONE:
			sliders[which].call_deferred("grab_click_focus") # Grab click-focus on whichever slider
		groupTypes.CLOSE:
			closeButton.call_deferred("grab_click_focus") # Grab click-focus on CloseButton
	updateDescriptionHint(which)


# Audio playback on slider drag start/end
func onDragStartOrEnd(_value: float, which: groupTypes) -> void:
	match which:
		groupTypes.MASTER:
			if !$LocalMasterTest.playing:
				$LocalMasterTest.play()
		groupTypes.BGM:
			if !$LocalBgmTest.playing:
				SoundControl.playBgm()
		groupTypes.SFX:
			SoundControl.playSfx(SoundControl.scratch)
		groupTypes.CUE:
			SoundControl.playCue(SoundControl.pickup, 1.0)
