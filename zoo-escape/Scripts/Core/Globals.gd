extends Node

# Global constant that tells the game the sizes of our tiles
const TILESIZE := 32

# Global constants for Min/Max Volumes and Min/Max Deadzone
const MAXVOLUME := 0
const MINVOLUME := -20
const MAXDEADZONE := 1.0
const MINDEADZONE := 0.2

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
	"1476": Scenes.LEVEL3,
	"4111": Scenes.LEVEL4,
	"5829": Scenes.ICEANDBOX,
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
	 "8934": Scenes.ICELABYRINTH
	# "0195": 
	# "5473": 
	# "3706": 
}

# Global list of star-rating thresholds for the various levels
const THRESHOLDS := { # "CODE": [ Gold, Silver, Bronze ] # Gold should be challenging, because this is an exceedingly easy game
	# Real Levels
	"0001": [ 0, 0, 0 ],
	
	"0387": [ 4050, 3050, 2050 ],
	"9102": [ 8400, 7400, 6400 ],
	"1476": [ 4000, 3000, 2000 ],
	"4111": [ 9000, 8000, 7000 ],
	"5829": [ 3800, 2800, 1800 ],
	# "0053": [],
	
	# "7618": [],
	# "2940": [],
	# "8365": [],
	# "0721": [],
	# "6594": [],
	
	# "3082": [],
	# "9817": [],
	# "4250": [],
	# "1639": [],
	# "7048": [],
	
	# "2561": [],
	 "8934": [ 9250, 8250, 7250 ],
	# "0195": [],
	# "5473": [],
	# "3706": []
}

const LEVELNAMES := { # "CODE": "Level Name" (No longer than 23 characters!)
	# Real Levels
	"0001": "Tutorial 1", # TODO: Rename this level
	
	"0387": "Level 1", # TODO: Rename this level
	"9102": "Level 2", # TODO: Rename this level
	"1476": "Level 3", # TODO: Rename this level
	"4111": "Level 4", # TODO: Rename this level
	"5829": "Ice and Box",
	# "0053": "",
	
	# "7618": "",
	# "2940": "",
	# "8365": "",
	# "0721": "",
	# "6594": "",
	
	# "3082": "",
	# "9817": "",
	# "4250": "",
	# "1639": "",
	# "7048": "",
	
	# "2561": "",
	 "8934": "Ice Labyrinth",
	# "0195": "",
	# "5473": "",
	# "3706": ""
}

# Global storage for high scores data
var highScores: Dictionary [String, Array] = {
	# Example: "password": [ [ score, time, moves, rating ],  [ score, time, moves, rating ], [ score, time, moves, rating ] ]
}

# Globally accessible storage locker for the user's settings
# NOTE: These double as default settings values for Data.gd
var currentSettings := {
	"masterVolume": -6,
	"musicVolume": -6,
	"sfxVolume": -6,
	"cueVolume": -6,
	"analogDeadzone": 0.50,
}

# Globally accessible data related to the currently active game
var currentGameData := {
	"gameRunning": false, # flag to change hud and window behaviors in game
	"playerScore": 0, # player score total (useful for reloads and moving to the next level)
}


# global function to update input deadzones
func deadzoneUpdate() -> void:
	InputMap.action_set_deadzone("DigitalLeft", currentSettings.analogDeadzone)
	InputMap.action_set_deadzone("DigitalDown", currentSettings.analogDeadzone)
	InputMap.action_set_deadzone("DigitalRight", currentSettings.analogDeadzone)
	InputMap.action_set_deadzone("DigitalUp", currentSettings.analogDeadzone)
