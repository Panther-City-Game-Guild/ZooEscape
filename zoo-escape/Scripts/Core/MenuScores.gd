extends Panel

# Signals
signal SetMenu(menu: MenuManager.menuTypes)
signal GoBack

# Enums
enum buttonTypes {
	CLOSE,
	PREV,
	NEXT,
	PLAY
}

enum starTypes {
	GOLD,
	SILVER,
	BRONZE
}

const STARS := {
	starTypes.GOLD: preload("res://Assets/Images/Icons/StarGold32.png"),
	starTypes.SILVER: preload("res://Assets/Images/Icons/StarSilver32.png"),
	starTypes.BRONZE: preload("res://Assets/Images/Icons/StarBronze32.png")
}

var scoreIndex := 0
var key := "9990"
var highScoresSize := Globals.highScores.size()

@onready var levelName := $Margin/Info/Header/LevelName
@onready var levelPass := $Margin/Info/Header/LevelCode
@onready var thresholds := [ $Margin/Info/Header/Thresholds/Gold/Label, $Margin/Info/Header/Thresholds/Silver/Label, $Margin/Info/Header/Thresholds/Bronze/Label ]
@onready var scoreLabels: Array[Label] = [ $Margin/Info/Scores/Data/ScoreTxt1, $Margin/Info/Scores/Data/ScoreTxt2, $Margin/Info/Scores/Data/ScoreTxt3 ]
@onready var moveBoxes: Array[Label] = [ $Margin/Info/Scores/Data/Moves1, $Margin/Info/Scores/Data/Moves2, $Margin/Info/Scores/Data/Moves3 ]
@onready var timeBoxes: Array[Label] = [ $Margin/Info/Scores/Data/Time1, $Margin/Info/Scores/Data/Time2, $Margin/Info/Scores/Data/Time3 ]
@onready var scoreBoxes: Array[Label] = [ $Margin/Info/Scores/Data/Score1, $Margin/Info/Scores/Data/Score2, $Margin/Info/Scores/Data/Score3 ]
@onready var ratingBoxes: Array[TextureRect] = [ $Margin/Info/Scores/Data/Rating1, $Margin/Info/Scores/Data/Rating2, $Margin/Info/Scores/Data/Rating3 ]
@onready var buttons := {
	buttonTypes.CLOSE: $Margin/CloseButton,
	buttonTypes.PREV: $Margin/PrevButton,
	buttonTypes.NEXT: $Margin/NextButton,
	buttonTypes.PLAY: $Margin/PlayButton,
}


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Connect button signals to Event Handlers
	for button in buttons.values():
		var btnKey: buttonTypes = buttons.find_key(button)
		button.pressed.connect(onButtonPressed.bind(btnKey))
		button.mouse_entered.connect(onButtonMouseEntered.bind(btnKey))
		button.focus_entered.connect(onButtonFocusEntered.bind(btnKey))


# Called when an InputEvent is detected
func _input(event: InputEvent) -> void:
	if !visible || !event.is_pressed() || event.is_echo():
		return
	
	var buttonType := -1
	if event.is_action("DigitalRight"):
		buttonType = buttonTypes.NEXT
	elif event.is_action("DigitalLeft"):
		buttonType = buttonTypes.PREV
	elif event.is_action("CancelButton"):
		buttonType = buttonTypes.CLOSE
	
	if buttonType != -1:
		get_viewport().set_input_as_handled()
		var button = buttons[buttonType]
		var opposite_buttonType = buttonTypes.PREV if buttonType == buttonTypes.NEXT else buttonTypes.NEXT
		
		if !button.disabled:
			button.call_deferred("grab_focus")
			onButtonPressed(buttonType)
		if button.disabled:
			buttons[opposite_buttonType].call_deferred("grab_focus")


# Called to retrieve score data
func getScoreData() -> void:
	if Globals.highScores.is_empty():
		return 
	
	highScoresSize = Globals.highScores.size()
	key = Globals.highScores.keys()[scoreIndex]
	var lName: String = Globals.LEVELNAMES[key]
	var tHolds: Array = Globals.THRESHOLDS[key].duplicate()
	var hScores: Array = Globals.highScores[key]
	
	if lName.is_empty() || tHolds.is_empty() || hScores.is_empty():
		return # If required data is missing, exit early
	resetWindow()
	levelName.text = lName
	levelPass.text = "Password: " + key
	
	# Set the threshold labels
	tHolds.sort() # Sort and reverse thresholds to ensure ordered from greatest to least
	tHolds.reverse()
	for i: int in tHolds.size():
		if tHolds[i] == 0: # If threshold is 0, leave the text reset
			continue
		thresholds[i].text = str(tHolds[i]) # [ Gold, Silver, Bronze ]
	
	# Set the score-related labels/textures
	for i: int in hScores.size(): # [ [ score, time, moves ], ... ]
		scoreBoxes[i].text = str(hScores[i][0]) # Set score text
		moveBoxes[i].text = str(hScores[i][2]) # Set moves text
		timeBoxes[i].text = str(hScores[i][1]) # Set time text
		
		# Set rating texture
		if hScores[i][0] >= tHolds[0]:
			ratingBoxes[i].texture = STARS[starTypes.GOLD]
		elif hScores[i][0] >= tHolds[1]:
			ratingBoxes[i].texture = STARS[starTypes.SILVER]
		elif hScores[i][0] >= tHolds[2]:
			ratingBoxes[i].texture = STARS[starTypes.BRONZE]
		else:
			ratingBoxes[i].texture = null
		
	toggleButtons() # Disable buttons if needed


# Called by the MenuManager to show this window
func showMenu() -> void:
	getScoreData() # Update variables and retrieve the first set of score data
	var btn: buttonTypes
	if !buttons[buttonTypes.NEXT].disabled:
		btn = buttonTypes.NEXT
	elif !buttons[buttonTypes.PREV].disabled:
		btn = buttonTypes.PREV
	else:
		btn = buttonTypes.PLAY
	buttons[btn].call_deferred("grab_focus")
	show()


# Called to return to the last menu
func returnToLastMenu() -> void:
	SoundControl.playCue(SoundControl.down, 1.4)
	GoBack.emit() # Bye!


# Called to reset the window text to default values
func resetWindow() -> void:
	levelName.text = "Unnamed Level"
	levelPass.text = "Password: ----"
	for tHold: Label in thresholds:
		tHold.text = "--"
	for mBox: Label in moveBoxes:
		mBox.text = "--"
	for tBox: Label in timeBoxes:
		tBox.text = "--"
	for sBox: Label in scoreBoxes:
		sBox.text = "--"
	for rBox: TextureRect in ratingBoxes:
		rBox.texture = null


# Called to enable/disable NextButton / PrevButton when appropriate
func toggleButtons() -> void:
	var isFirst := scoreIndex == 0
	var isLast := scoreIndex == highScoresSize - 1
	var isSingle := highScoresSize == 1
	var nextNeighbor := "../NextButton"
	var prevNeighbor := "../PrevButton"
	
	# Enable/disable buttons
	buttons[buttonTypes.PREV].disabled = isSingle || isFirst
	buttons[buttonTypes.NEXT].disabled = isSingle || isLast
	
	# Set focus neighbors
	if isLast:
		nextNeighbor = "../PrevButton"
	if isFirst:
		prevNeighbor = "../NextButton"
	
	buttons[buttonTypes.NEXT].focus_neighbor_left = prevNeighbor
	buttons[buttonTypes.PREV].focus_neighbor_right = nextNeighbor
	if isSingle:
		buttons[buttonTypes.PLAY].focus_neighbor_top = "../CloseButton"
		buttons[buttonTypes.CLOSE].focus_neighbor_bottom = "../PlayButton"
	else:
		buttons[buttonTypes.PLAY].focus_neighbor_top = nextNeighbor
		buttons[buttonTypes.CLOSE].focus_neighbor_bottom = nextNeighbor
	
	# Set focus
	if isSingle:
		buttons[buttonTypes.PLAY].call_deferred("grab_focus")
	elif isFirst:
		buttons[buttonTypes.NEXT].call_deferred("grab_focus")


# Called when a button is pressed
func onButtonPressed(btnType: buttonTypes) -> void:
	match btnType:
		buttonTypes.NEXT, buttonTypes.PREV:
			if (btnType == buttonTypes.NEXT && scoreIndex < highScoresSize - 1) || (btnType == buttonTypes.PREV && scoreIndex > 0):
				scoreIndex += 1 if btnType == buttonTypes.NEXT else -1
				SoundControl.playCue(SoundControl.blip, 5.0)
				getScoreData()
		
		buttonTypes.PLAY:
			SoundControl.playCue(SoundControl.start, 1.0)
			SceneManager.call_deferred("goToNewSceneString", Globals.PASSWORDS[key])
			SetMenu.emit(MenuManager.menuTypes.NONE)
		
		buttonTypes.CLOSE:
			returnToLastMenu()


# Event handler for when the mouse hovers a menu button
func onButtonMouseEntered(btnType: buttonTypes) -> void:
	var button: Button = buttons[btnType]
	if !button.disabled: # Make the button grab_focus
		button.call_deferred("grab_focus")


# Event handler for when a menu button receives focus
func onButtonFocusEntered(btnType: buttonTypes) -> void:
	buttons[btnType].call_deferred("grab_click_focus")
