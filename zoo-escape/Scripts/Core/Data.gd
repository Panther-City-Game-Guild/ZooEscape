extends Control


const SETTINGSFILE := "user://ZooEscapeSave.sv1" # Filepath for Settings
const SCORESFILE := "user://ZooEscapeSave.sv2" # Filepath for High Scores
const VOLUMESETTINGSKEYS := [ "masterVolume", "musicVolume", "sfxVolume", "cueVolume" ]


# Called when node enters scene tree for the first time
func _ready() -> void:
	loadSettingsData() # Load settings
	loadScoreData() # Load scores


# Open or create file, fetch data, convert dictionary to json and save
func saveSettingsData() -> void:
	var saveData := Globals.currentSettings.duplicate()
	var json_string := JSON.stringify(saveData, "\t")
	var file := FileAccess.open(SETTINGSFILE, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()


# Load settings data, with validation
func loadSettingsData() -> void:
	if !FileAccess.file_exists(SETTINGSFILE): # if no file, save default settings
		saveSettingsData()
		loadSettingsData()
	
	else: # if file, parse json and apply to global values
		var loadedData := {}
		var file := FileAccess.open(SETTINGSFILE, FileAccess.READ)
		var json := JSON.new()
		var json_string = file.get_as_text()
		var error: Error
		file.close()
		
		error = json.parse(json_string)
		if error != OK: # If there was an error loading data, create a default save file
			saveSettingsData()
			loadSettingsData()
			return
		
		loadedData = json.data
		
		if !loadedData is Dictionary: # Make sure the loaded data is a dictionary
			saveSettingsData()
			loadSettingsData()
			return
		
		for key in Globals.currentSettings.keys(): # Make sure the loaded data has all required keys
			if !loadedData.has(key):
				saveSettingsData()
				loadSettingsData()
				return
		
		for key in loadedData.keys():
			if !key in Globals.currentSettings.keys(): # Make sure the loaded data does not have unexpected keys
				saveSettingsData()
				loadSettingsData()
				return
		
			if !loadedData[key] is float: # Make sure the values loaded are floats
				saveSettingsData()
				loadSettingsData()
				return
			
			if key in VOLUMESETTINGSKEYS: # Make sure the data fits the parameters
				if !(loadedData[key] >= Globals.MINVOLUME && loadedData[key] <= Globals.MAXVOLUME):
					saveSettingsData()
					loadSettingsData()
					return
			if key == "analogDeadzone": # Make sure the data fits the parameters
				if !(loadedData[key] >= Globals.MINDEADZONE && loadedData[key] <= Globals.MAXDEADZONE):
					saveSettingsData()
					loadSettingsData()
					return
		
		# update global values
		Globals.currentSettings.masterVolume = loadedData.masterVolume
		Globals.currentSettings.musicVolume = loadedData.musicVolume
		Globals.currentSettings.sfxVolume = loadedData.sfxVolume
		Globals.currentSettings.cueVolume = loadedData.cueVolume
		Globals.currentSettings.analogDeadzone = loadedData.analogDeadzone
		
		# update settings and sound
		Globals.deadzoneUpdate()
		SoundControl.updateVolumeLevels()
		SoundControl.resetMusicFade()


# Called to save High Score data
func saveScoreData(data := {}) -> void:
	var file := FileAccess.open(SCORESFILE, FileAccess.WRITE)
	var saveData := {}
	var json_string := ""
	
	if !data:
		saveData = Globals.highScores.duplicate()
	else:
		saveData = data.duplicate()
	
	json_string = JSON.stringify(saveData)
	file.store_string(json_string)
	file.close()


# Called to load High Score data if any exists
func loadScoreData() -> void:
	if !FileAccess.file_exists(SCORESFILE): # If no file, create one
		saveScoreData()
	
	else: # if file, parse json and apply to global highscores variable
		var loadedData := {}
		var file := FileAccess.open(SCORESFILE, FileAccess.READ)
		var json := JSON.new()
		var json_string = file.get_as_text()
		var error: Error
		file.close()
		
		error = json.parse(json_string)
		if error != OK: # If there was an error loading data, create an empty scores file
			saveScoreData()
			loadScoreData()
			return
		
		loadedData = json.data
		if !loadedData is Dictionary:
			saveScoreData() # If the loaded data is not a dictionary, wipe it out
			loadScoreData() # Try again to validate the data
			return
		
		if !isScoreDataValid(loadedData):
			loadScoreData() # If data was not valid, reload data to try again
			return
		
		loadedData = convertFloatsToInts(loadedData) # Convert floats to ints
		loadedData = sortDictionary(loadedData, Globals.PASSWORDS)
		
		for key in loadedData.keys(): # Send the validated data to Globals
			Globals.highScores[key] = loadedData[key]


# Called to verify loaded highScores keys are valid, erasing any invalid keys
func isScoreDataValid(data: Dictionary) -> bool:
	var didRemoveData := false
	for key in data.keys():
		if !key in Globals.PASSWORDS.keys(): # Remove invalid keys
			data.erase(key)
			didRemoveData = true
			continue
		
		if !data[key] is Array || data[key].is_empty(): # Validate top-level array
			data.erase(key)
			didRemoveData = true
			continue
		
		var outerArr: Array = data[key] # Get outer array
		while outerArr.size() > 3: # Remove extraneous entries (Keeping 3 entries for each level)
			outerArr.pop_back()
			didRemoveData = true
			
		var i: int = outerArr.size() - 1
		while i >= 0: # Iterate backwards through outer array
			var innerArr: Variant = outerArr[i]
			if !innerArr is Array: # Remove non-arrays from outer array
				outerArr.remove_at(i)
				didRemoveData = true
				i -= 1
				continue # Move to next index of inner array
				
			if innerArr.size() != 3:
				outerArr.remove_at(i) # Validate size of inner array (3: Score, Time, Moves)
				didRemoveData = true
				i -= 1
				continue # Move to next index of inner array
			
			var areValuesValid := true # Validate values of inner array
			for value in innerArr:
				if !(value is int || value is float): # Value must be int or float
					areValuesValid = false
					break
				if value < 0: # Value must not be less than 0
					areValuesValid = false
					break
			if !areValuesValid:
				outerArr.remove_at(i) # Remove entries from outer array if values in inner array are not numeric
				didRemoveData = true
			
			i -= 1 # Move to next index of outer array
		
		data[key] = outerArr
		if outerArr.is_empty(): 
			data.erase(key)
			didRemoveData = true
		
	if didRemoveData:
		saveScoreData(data) # If data removed, save remaining data
		return false
	return true


# Called to convert float values to int values (used when loading Score data)
func convertFloatsToInts(data: Dictionary) -> Dictionary:
	for key in data.keys(): # Outer array
		for arr in data[key]: # Inner array
			for i: int in arr.size(): # [ Score, Time, Moves ]
				if i == 0 || i == 2:
					arr[i] = int(arr[i])
	return data


# Called to sort the loaded data according to the order of the reference dictionary
func sortDictionary(loadedData: Dictionary, reference: Dictionary) -> Dictionary:
	var sorted := {}
	# Iterate through keys in reference
	for key in reference.keys():
	# Only include keys that exist in loadedData
		if loadedData.has(key):
			sorted[key] = loadedData[key]
	return sorted
