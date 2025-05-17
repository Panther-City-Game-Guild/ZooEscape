class_name SteakManager extends Node2D

@onready var SteakTotal := 0
@onready var AllStaakCollecte := false

signal AllSteakCollected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SteakTotal = get_child_count()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if get_child_count() == 0 && !AllStaakCollecte:
		AllSteakCollected.emit()
		AllStaakCollecte = true
