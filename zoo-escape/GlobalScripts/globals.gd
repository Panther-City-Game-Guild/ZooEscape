extends Node

# This file will store Global var that can be read from anywhere in the game
@onready var ZETileSize := 16

# Volume settings are included by default and changed by the SettingsManager
# Do not alter this variable within your game; use the SettingsManager
var Current_Volume_Settings: Dictionary = {
	"master_volume": null,
	"music_volume": null,
	"fx_volume": null
}

# Globally available settings that can be used to store different settings
# Used to hold additional settings for your game, as needed
var Current_Settings : Dictionary = { }

# A global variable playground for your game
# Add these programatically when your game loads
# Use Globals.Game_Globals.get_or_add(varName, varValue) to create a dictionary entry
# Use Globals.Game_Globals.varName to retrieve the value
# 	Alternatively, use Globals.Game_Globals.get("varName") to retrieve the value
# TODO: Clean up when someone leaves a game (performed by the SceneManager)
var Game_Globals: Dictionary = {}
