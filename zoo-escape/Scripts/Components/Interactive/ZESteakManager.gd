class_name SteakManager extends Node2D

@onready var steakTotal := 0
@onready var allCollected := false

signal AllSteaksCollected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	steakTotal = get_child_count()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if get_child_count() == 0 && !allCollected:
		AllSteaksCollected.emit()
		allCollected = true
