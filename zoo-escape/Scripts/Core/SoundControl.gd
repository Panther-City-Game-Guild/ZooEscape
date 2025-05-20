extends Node2D

@onready var bgm := $BGM # music (pauses position on pause)
@onready var sfx := $SFX # in-game sound effects (pauses position on pause)
@onready var cue := $Cue # ui sound effects (ignores pause)

# export for testing purposes, const to set boundaries and ease debugging
const MAX_VOLUME := 0
const DEFAULT_VOLUME := -6
const SILENCE := -20
const defaultBgm := "res://Assets/Sound/theme.ogg"
const testBgm := "res://Assets/Sound/tutorial.ogg"
var currentBgm : String


# references to global volume levels (we can have options for this to adjust)
@onready var masterLevel: float = Globals.currentSettings['master_volume']
@onready var bgmLevel: float = Globals.currentSettings['music_volume']
@onready var sfxLevel: float = Globals.currentSettings['sfx_volume']
@onready var cueLevel: float = Globals.currentSettings['cue_volume']
@onready var volumeReference := bgmLevel
@export var fadeRate := 0.2 # default fade rate, can be updated in code


# fade state machine for audio fading
var fadeState := FADE_STATES.SILENCE
enum FADE_STATES {
	SILENCE, # no audio
	IN_TRIGGER, # audio starts increase (one-shot)
	IN_CURVE, # audio fading in
	PEAK_VOLUME, # audio continuous (idle)
	OUT_TRIGGER, # audio starts decrease (one-shot)
	OUT_CURVE} # audio fades out


# global audio references for easy access
const alert := "res://Assets/Sound/alert.ogg"
const blip := "res://Assets/Sound/blip.ogg"
const chomp := "res://Assets/Sound/chompy.ogg"
const down := "res://Assets/Sound/flourish_down.ogg"
const pickup := "res://Assets/Sound/pickup.ogg"
const flutter := "res://Assets/Sound/flutter.ogg"
const fail := "res://Assets/Sound/game_over.ogg"
const ruined := "res://Assets/Sound/crumble_noise.ogg"
const scratch := "res://Assets/Sound/scratch_delay.ogg"
const scuff := "res://Assets/Sound/scuff_noise.ogg"
const splorch := "res://Assets/Sound/splorch.ogg"
const success := "res://Assets/Sound/success.ogg"
const thump := "res://Assets/Sound/thump.ogg"
const zap := "res://Assets/Sound/zap_delayed.ogg"
const start := "res://Assets/Sound/flourish_up.ogg"


func _ready() -> void: # sound preferences retrieved at ready
	setSoundPreferences(masterLevel,SILENCE,sfxLevel,cueLevel) # set levels
	currentBgm = testBgm # default title music


func _process(delta: float) -> void: # listen for fade states and update volumes
	if !AudioServer.is_bus_mute(3): # check volume reference/bgm bus
		if fadeState != FADE_STATES.PEAK_VOLUME: # fade trigger if bgm not muted
			bgmFadingMachine(delta,fadeRate)


# values set for sound levels
func setSoundPreferences(_master:float,_bgm:float, _sfx:float, _cue:float) -> void:
	AudioServer.set_bus_volume_db(0,_master)
	AudioServer.set_bus_volume_db(1,_cue)
	AudioServer.set_bus_volume_db(2,_sfx)
	AudioServer.set_bus_volume_db(3,_bgm)


# call bgm file and play (state machine handles stop and start automatically)
func playBgm() -> void:
	var _loadBgm = load(currentBgm)
	bgm.volume_db = bgmLevel
	bgm.stream = _loadBgm
	bgm.play()


# for stopping outside of node
func stopBgm() -> void:
	$BGM.stop()


# to update fade value
func fadeRateUpdate(_newValue:float) -> void:
	fadeRate = _newValue


# queue next track and update fade if needed
func levelChangeSoundCall(_value:float, _music:String) -> void:
	currentBgm = _music # allows music to change on next fade start
	fadeState = FADE_STATES.OUT_TRIGGER
	fadeRateUpdate(_value)


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
		FADE_STATES.IN_TRIGGER:
			fadeRate = 0.25 # default rate
			if bgmLevel != SILENCE: # if not silent, start fade curve
				playBgm() # start play
				fadeState = FADE_STATES.IN_CURVE
			else:
				fadeState = FADE_STATES.SILENCE
		FADE_STATES.IN_CURVE:
			if volumeReference < bgmLevel: # increase volume while below target
				volumeReference+=(_delta+_rate)
			else: # then update state
				fadeState = FADE_STATES.PEAK_VOLUME
		FADE_STATES.PEAK_VOLUME: # hold volume steady when not fading
			volumeReference = bgmLevel
		FADE_STATES.OUT_TRIGGER: # start volume decrease (one-shot)
			if volumeReference >= bgmLevel:
				volumeReference-=(_delta+_rate)
				fadeState = FADE_STATES.OUT_CURVE
		FADE_STATES.OUT_CURVE: # if not silence, reduce rate
			if volumeReference > SILENCE:
				volumeReference-=(_delta+_rate*2)
			else: # then set to silence
				fadeState = FADE_STATES.SILENCE
		FADE_STATES.SILENCE: # silence immediately begins next fade in
			volumeReference = SILENCE
			if bgmLevel != SILENCE: # If bgm not silenced, start fade in
				fadeState = FADE_STATES.IN_TRIGGER


func resetMusicFade() -> void: # external function for resetting music volume
	fadeState = FADE_STATES.SILENCE
	$BGM.volume_db = SILENCE


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
