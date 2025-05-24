extends Node


# This is set by gameroot when it is ready
@onready var gameRoot: GameRoot
@onready var currentScene: Node
const TITLE := Scenes.TITLE
const SETTINGS := Scenes.SETTINGS


# Set the root node so it (and its children set to Inherit mode) cannot be paused
# Inherit mode is default for Nodes, so set your game node's mode to Pausable
func _ready() -> void:
	get_parent().process_mode = Node.PROCESS_MODE_ALWAYS



# this takes a loaded scene as argument and unpauses the tree
func goToNewScenePacked(newScene: PackedScene) -> void:
	# Before switching to another scene, make sure the scene tree is not paused
	# This happens if a game is exited while paused
	get_tree().paused = false
	
	# Switch the scenes
	gameRoot.goToNextScene(currentScene, newScene)


# this takes a filename/string as argument and loads it with the previous function
func goToNewSceneString(newScene: String) -> void:
	# TODO: add error checking
	var scene: Resource = load(newScene)
	goToNewScenePacked(scene)


# this returns to the title with a function that clears the scene queue
func goToTitle() -> void:
	goToNewSceneString(TITLE)


# this goes to the settings menu with a function that clears the scene queue
func goToSettings() -> void:
	goToNewSceneString(SETTINGS)
