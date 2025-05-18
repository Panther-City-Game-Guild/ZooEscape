extends Control

const FILEPATH := "user://ZooEscapeSave.json" ## persistent filepath
var saveData : Dictionary ## save data dictionary
var access : FileAccess ## file access call
## default values for external settings
const DEFAULT_VOLUME := -6
const DEFAULT_DZ := 0.5
const DEFAULT_VALUES := [
	20000,
	19000,
	18000,
	17000,
	16000]
const DEFAULT_NAMES := [
	"ZAP",
	"MKV",
	"GUS",
	"FTW",
	"ZOO"]


## grab game data and update dictionary for save
func fetchGameData() -> Dictionary:
	saveData = {
		"master_volume" = Globals.Current_Options_Settings.get("master_volume"),
		"music_volume" = Globals.Current_Options_Settings.get("music_volume"),
		"sfx_volume" = Globals.Current_Options_Settings.get("sfx_volume"),
		"cue_volume" = Globals.Current_Options_Settings.get("cue_volume"),
		"analog_deadzone" = Globals.Current_Options_Settings.get("analog_deadzone"),
		"highScoreboardValues" = Globals.highScoreboardValues,
		"highScoreboardNames" = Globals.highScoreboardNames
	}
	
	return saveData


## open file, fetch data, convert dictionary to json and save
func saveGameData()-> void:
	access = FileAccess.open(FILEPATH, FileAccess.WRITE)
	saveData = fetchGameData()
	access.store_string(JSON.stringify(saveData))
	access.close()
	

## apply default settings
func defaultGameData() -> void:
	Globals.Current_Options_Settings["master_volume"] = DEFAULT_VOLUME
	Globals.Current_Options_Settings["music_volume"] = DEFAULT_VOLUME
	Globals.Current_Options_Settings["sfx_volume"] = DEFAULT_VOLUME
	Globals.Current_Options_Settings["sfx_volume"] = DEFAULT_VOLUME
	Globals.Current_Options_Settings["cue_volume"] = DEFAULT_VOLUME
	Globals.Current_Options_Settings["analog_deadzone"] = DEFAULT_DZ
	Globals.highScoreboardNames = DEFAULT_NAMES.duplicate()
	Globals.highScoreboardValues = DEFAULT_VALUES.duplicate()


## load with check
func loadData()-> void:
	if !FileAccess.file_exists(FILEPATH): ## if no file, default settings
		print("No save detected. Default data loaded.")
		defaultGameData()
	else: ## if file, parse json and apply to global values
		access = FileAccess.open(FILEPATH, FileAccess.READ)
		saveData = JSON.parse_string(access.get_as_text())
		print("Data loaded!")
		access.close()
		Globals.Current_Options_Settings["master_volume"] = saveData.master_volume
		Globals.Current_Options_Settings["music_volume"] = saveData.music_volume
		Globals.Current_Options_Settings["sfx_volume"] = saveData.sfx_volume
		Globals.Current_Options_Settings["cue_volume"] = saveData.cue_volume
		Globals.Current_Options_Settings["analog_deadzone"] = saveData.analog_deadzone
		## copy high score arrays
		Globals.highScoreboardValues = saveData.highScoreboardValues.duplicate()
		Globals.highScoreboardNames = saveData.highScoreboardValues.duplicate()
