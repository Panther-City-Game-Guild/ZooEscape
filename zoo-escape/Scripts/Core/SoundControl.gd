extends Node


# export for testing purposes, const to set boundaries and ease debugging
const MAX_VOLUME := 0
const SILENCE := -20
const defaultBgm := "res://Assets/Sound/Theme.ogg"
const testBgm := "res://Assets/Sound/Tutorial.ogg"

# global audio references for easy access
const alert := "res://Assets/Sound/Alert.ogg"
const blip := "res://Assets/Sound/Blip.ogg"
const chomp := "res://Assets/Sound/Chompy.ogg"
const down := "res://Assets/Sound/FlourishDown.ogg"
const pickup := "res://Assets/Sound/Pickup.ogg"
const fanfare := "res://Assets/Sound/FanfareMajor.ogg"
const flutter := "res://Assets/Sound/Flutter.ogg"
const fail := "res://Assets/Sound/GameOver.ogg"
const ruined := "res://Assets/Sound/CrumbleNoise.ogg"
const scratch := "res://Assets/Sound/ScratchDelay.ogg"
const scuff := "res://Assets/Sound/ScuffNoise.ogg"
const splorch := "res://Assets/Sound/Splorch.ogg"
const success := "res://Assets/Sound/Success.ogg"
const thump := "res://Assets/Sound/Thump.ogg"
const zap := "res://Assets/Sound/ZapDelayed.ogg"
const start := "res://Assets/Sound/FlourishUp.ogg"
const bzzzt := "res://Assets/Sound/Pinknoise.ogg"
const oontz := "res://Assets/Sound/Boop.ogg"

# Possible fade states for audio fading
enum fadeStates {
	SILENCE, # no audio
	IN_TRIGGER, # audio starts increase (one-shot)
	IN_CURVE, # audio fading in
	PEAK_VOLUME, # audio continuous (idle)
	OUT_TRIGGER, # audio starts decrease (one-shot)
	OUT_CURVE} # audio fades out


# references to global volume levels
var masterLevel: float = Globals.currentSettings.masterVolume
var bgmLevel: float = Globals.currentSettings.musicVolume
var sfxLevel: float = Globals.currentSettings.sfxVolume
var cueLevel: float = Globals.currentSettings.cueVolume
var volumeReference := bgmLevel
var fadeRate := 0.1 # default fade rate, can be updated in code
var currentBgm := testBgm # compares to next to determine bgm behaviour
var nextBgm := defaultBgm # stores next bgm reference
var fadeState := fadeStates.SILENCE # current fade state

@onready var bgm := $BGM # music (pauses position on pause)
@onready var sfx := $SFX # in-game sound effects (pauses position on pause)
@onready var cue := $Cue # ui sound effects (ignores pause)

# bgm by level for triggering fades
const levelsBgm := {
	"0001": testBgm,
	"0387": testBgm,
	"9102": defaultBgm,
	"1476": defaultBgm,
	"4111": defaultBgm,
	"5829": testBgm,
	"8934": testBgm
}


 # sound preferences retrieved at ready
func _ready() -> void:
	updateVolumeLevels()


 # listen for fade states and update volumes
func _process(delta: float) -> void:
	if !AudioServer.is_bus_mute(3): # check volume reference/bgm bus
		bgmFadingMachine(delta,fadeRate)


# values set for sound levels (using Globals)
func updateVolumeLevels() -> void:
	AudioServer.set_bus_volume_db(0, Globals.currentSettings.masterVolume)
	AudioServer.set_bus_volume_db(1, Globals.currentSettings.cueVolume)
	AudioServer.set_bus_volume_db(2, Globals.currentSettings.sfxVolume)
	AudioServer.set_bus_volume_db(3, Globals.currentSettings.musicVolume)


# for stopping outside of node
func stopBgm() -> void:
	bgm.stop()


# for simple playing
func playBgm() -> void:
	if !bgm.playing:
		bgm.stream = load(currentBgm)
		bgm.play()


# for fading in bgm, always fade in if not max volume
func musicFadeIn() -> void:
	if fadeState != fadeStates.PEAK_VOLUME:
		volumeReference = -20
		fadeState = fadeStates.IN_TRIGGER


# for fading out bgm, always fade in if there is a new bgm next
func musicFadeOut() -> void:
	if nextBgm != currentBgm:
		currentBgm = nextBgm
		fadeState = fadeStates.OUT_TRIGGER


# to update fade value
func fadeRateUpdate(_newValue:float) -> void:
	fadeRate = _newValue


# hard stop function
func stopSounds() -> void:
	bgm.stop()
	sfx.stop()


# call sfx file and play
func playSfx(_sfxFile:String) -> void:
	randomize() # queue rng
	var _variant = randf_range(-0.3,0.3) # change pitch each time
	var _loadSfx = load(_sfxFile)
	sfx.stream = _loadSfx
	sfx.pitch_scale = 1+_variant
	sfx.play()


# call system noises and play (note: system noises do not pause)
func playCue(_cueFile:String,_pitch:float) -> void:
	cue.pitch_scale = _pitch
	var _loadCue = load(_cueFile)
	cue.stream = _loadCue
	cue.play()


# fade volume state machine for music
func bgmFadingMachine(_delta:float,_rate:float) -> void:
	bgm.volume_db = volumeReference # volume reflects abstraction value
	
	match fadeState:
		fadeStates.IN_TRIGGER: # fetch bgm and play (one-shot)
			$BGM.stream = load(currentBgm)
			$BGM.play()
			fadeState = fadeStates.IN_CURVE
		fadeStates.IN_CURVE:
			if volumeReference < bgmLevel: # increase volume while below target
				volumeReference+=(_delta+_rate*2)
			else: # then update state
				fadeState = fadeStates.PEAK_VOLUME
		fadeStates.PEAK_VOLUME: # hold volume steady when not fading
			volumeReference = bgmLevel
		fadeStates.OUT_TRIGGER: # start volume decrease (one-shot)
			if volumeReference >= bgmLevel:
				volumeReference-=(_delta+_rate)
				fadeState = fadeStates.OUT_CURVE
		fadeStates.OUT_CURVE: # if not silence, reduce rate
			if volumeReference > SILENCE:
				volumeReference-=(_delta+_rate*2)
			else: # then set to silence
				fadeState = fadeStates.SILENCE
		fadeStates.SILENCE: # mute when below audibility
			$BGM.stop()
			$BGM.volume_db = -80


# external function for resetting music volume and fade state
func resetMusicFade() -> void: 
	$BGM.stop()
	volumeReference = -20
	fadeState = fadeStates.SILENCE
	currentBgm = testBgm
	nextBgm = "next"


# external function for checking mute state (-20), mute buses accordingly
func muteAudioBusCheck() -> void:
	if AudioServer.get_bus_volume_db(0) < -19:
		AudioServer.set_bus_mute(0,true)
	else:
		AudioServer.set_bus_mute(0,false)


	if AudioServer.get_bus_volume_db(3) < -19:
		AudioServer.set_bus_mute(3,true)
	else:
		AudioServer.set_bus_mute(3,false)


	if AudioServer.get_bus_volume_db(2) < -19:
		AudioServer.set_bus_mute(2,true)
	else:
		AudioServer.set_bus_mute(2,false)


	if AudioServer.get_bus_volume_db(1) < -19:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)
