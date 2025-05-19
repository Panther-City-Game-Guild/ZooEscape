extends Node

# This file will store Global var that can be read from anywhere in the game
@onready var ZETileSize := 16

# Volume settings are included by default and changed by the SettingsManager
# Do not alter this variable within your game; use the SettingsManager
@onready var Current_Options_Settings := {
	"master_volume": -6,
	"music_volume": -10, # -6 by default is too loud for this -DevMV
	"sfx_volume": -6,
	"cue_volume": -6,
	"analog_deadzone": 0.50
}

## this will store global values for transferring level data to hud
@onready var Current_Level_Data := {
	"time_limit": 60,
	"warning_threshold": 15
}

# Globally available settings that can be used to store different settings
# Used to hold additional settings for your game, as needed
@onready var Current_Settings := {
	"passwordWindowOpen": false ## global hud control flag
}

# A global variable playground for your game
# Add these programatically when your game loads
# Use Globals.Game_Globals.get_or_add(varName, varValue) to create a dictionary entry
# Use Globals.Game_Globals.varName to retrieve the value
# 	Alternatively, use Globals.Game_Globals.get("varName") to retrieve the value
# TODO: Clean up when someone leaves a game (performed by the SceneManager)
@onready var Game_Globals := {
	"player_score": 0, ## player score total
	# debug levels
	"9990": Scenes.TITLE,
	"9991": Scenes.DEBUG,
	"9992": Scenes.DEBUG2,
	"9993": Scenes.DEBUG3,
	
	# Real Levels
	"0001": Scenes.TUTORIAL1,
	
	"0387": Scenes.LEVEL1,
	"9102": Scenes.LEVEL2
	# "1476": 
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


@onready var highScoreboardNames = [
	"ZAP",
	"MKV",
	"GUS",
	"FTW",
	"ZOO"
]

@onready var highScoreboardValues = [
	20000,
	19000,
	18000,
	17000,
	16000
]
