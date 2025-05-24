extends Node

# Global constant that tells the game the sizes of our tiles
const TILESIZE := 16

# Globally accessible list of passwords and corresponding scenes
const PASSWORDS := {
	# Debug Levels
	"9990": Scenes.TITLE,
	"9991": Scenes.DEBUG,
	"9992": Scenes.DEBUG2,
	"9993": Scenes.DEBUG3,
	
	# Real Levels
	"0001": Scenes.TUTORIAL1,
	
	"0387": Scenes.LEVEL1,
	"9102": Scenes.LEVEL2,
	"1476": Scenes.LEVEL3
	# "5829": 
	# "0053": 
	
	# "7618": 
	# "2940": 
	# "8365": 
	# "0721": 
	# "6594": 
	
	# "3082": 
	# "9817": 
	# "4250": 
	# "1639": 
	# "7048": 
	
	# "2561": 
	# "8934": 
	# "0195": 
	# "5473": 
	# "3706": 
}

# Globally accessible storage locker for the user's settings
var currentSettings := {
	"master_volume": -6,
	"music_volume": -6, # -6 by default is too loud for this -DevMV
	"sfx_volume": -6,
	"cue_volume": -6,
	"analog_deadzone": 0.50,
}

# Globally accessible data related to the currently active game
var currentGameData := {
	"player_score" : 0, # player score total
	"current_level" : 0001
}

# Globally accessible data related to the state of the application
var currentAppState := {
	"passwordWindowOpen": false, # global hud control flag
	"gameRunning" : false # flag to return to game from settings or password screen
}

# TODO: Try combining highScoreboardNames with highScoreBoardValues into one Dictionary.
# var highScores := {
# 	"ZAP": 20000,
# 	"MKV": 19000,
# 	"ZAP": 18000,
# }

# Global storage space for player names in the high scores list
# NOTE: See the above TODO.
var highScoreboardNames = [
	"ZAP",
	"MKV",
	"GUS",
	"FTW",
	"ZOO"
]

# Global storage space for scores in the high scores list
# NOTE: See the above TODO.
var highScoreboardValues = [
	20000,
	19000,
	18000,
	17000,
	16000
]


# global function for changing score, with bool for determining plus/minus
func scoreUpdate(value:int,buff:bool) -> void:
	var _scoreCheck : int = currentGameData.get("player_score") # get current score
	var _newScore : int # create holder for totaling
	if buff == true: # is it a buff?
		_newScore = _scoreCheck + value # add
	else:
		_newScore = _scoreCheck - value # or subtract

	currentGameData.set("player_score",_newScore) # then update global


# global function to update input deadzones
func deadzoneUpdate() -> void:
	var _deadzone : float = currentSettings.get("analog_deadzone")
	InputMap.action_set_deadzone("DigitalLeft", _deadzone)
	InputMap.action_set_deadzone("DigitalDown", _deadzone)
	InputMap.action_set_deadzone("DigitalRight", _deadzone)
	InputMap.action_set_deadzone("DigitalUp", _deadzone)


# function to report game is running, for relaying UI scene behavior (passwords, etc)
func gameRun(_state:bool) -> void:
	if _state == true:
		if currentAppState.get("gameRunning") == false:
			currentAppState.set("gameRunning", true)
	else:
		if currentAppState.get("gameRunning") == true:
			currentAppState.set("gameRunning", false)
