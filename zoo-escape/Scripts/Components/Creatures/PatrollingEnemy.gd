class_name PatrollingEnemy extends CharacterBody2D

# Enums
enum enemyTypes {
	PEABODY,
	GIRAFFE
}

enum behaviors {
	PATROL, # Creature will follow a path comprising a series of wapoints (must use Marker2D, added to the WaypointManager node)
	STATIONARY # Creature will remain where placed in the editor
} 

# The PatrollingEnemy can be Idle, Patrolling, or Approaching
enum states {
	IDLE, # Creature is not moving (either resting at a way point or stationary)
	WAITING, # Creature is waiting at a waypoint
	PATROLLING, # Creature is actively patrolling (moving toward a waypoint)
	APPROACH, # Creature is approaching the Player (moving toward the waypoint nearest the player)
	CHASE # Creature is chasing the player
}

# Constants
const dirToAnimtionName := {
	Vector2.UP: "IdleUp",
	Vector2.RIGHT: "IdleRight",
	Vector2.DOWN: "IdleDown",
	Vector2.LEFT: "IdleLeft"
} # Directional movement-to-animation converter

# Behavior-related variables
@export var showPath := false # During runtime, do I keep the PatrolPath node after extracting points?
@export var enemyType := enemyTypes.PEABODY
@export var behavior := behaviors.PATROL # Do I patrol, or am I stationary?
@export var makeALoop := false # Is the defined path supposed to be a loop?  If so, Enemy will take a circular path instead of moving back and forth.
@export_range(0, 10, 0.1) var waitTime := 1.5 # How long do I wait at waypoints?
@export var autoApproach := true # Do I move toward the Player, along my path, if it gets near my path?
@export_range(0, 10, 1) var approachProximity := 3 # How close does the Player get to my path before I approach it? (Globals.TILESIZE * approachProximity)
@export var chasePlayer := false # Do I chase the Player when it moves away?
@export_range(0, 10, 1) var chaseRange := 3 # How far do I chase the Player before returning to where I came from? (Globals.TILESIZE * chaseRange)
@export var moveSpeed := 0.75 # Time to delay between movements
var currentState: states = states.IDLE # The current state of the Enemy
var timeWaited := 0.0 # How long the Enemy has been waiting
var waypoints: Array[Vector2] # An array of waypoints for the Enemy to move to
var lastWaypoint: int # The last waypoint's index within the waypoints array
var currentWaypoint := 0 # The current waypoint's index within the waypoints array
var savedPosition := Vector2.ZERO # The position from which the Enemy came
var movingForward := 1 # The direction along the path we're traveling (1 = counting up, -1 = counting down)
var isPlayerNear := false # Indicates whether the Player is near Enemy waypoints

# Additional variables
@onready var path: Line2D = $PatrolPath
@onready var terrainDetector := $TerrainDetector
@onready var ray := $RayCast2D
@onready var sprite := $AnimatedSprite2D


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	makeWaypoints() # Make an array of waypoints
	if showPath && makeALoop: # If path will remain in scene tree, show path as closed
		path.closed = true
	
	if !showPath: # If path not shown during run-time, remove path from scene tree
		path.queue_free()
	
	if waypoints.size() >= 1: # If waypoints, go to first one
		position = waypoints[0]
	
	else: # If no waypoints, revert to stationary
		behavior = behaviors.STATIONARY
		autoApproach = false


func _process(delta: float) -> void:
	# TODO: If the enemy is supposed to approach nearby Player, detect if Player is near path
	# This should interrupt normal patrolling
	if autoApproach:
		pass
	
	match behavior:
		# If the Enemy is set to Stationary, check for chasePlayer
		behaviors.STATIONARY:
			if chasePlayer:
				currentState = states.CHASE
			# TODO: Check chasePlayer and act accordingly
			return
		
		# If the Enemy is set to Patrol, do that
		behaviors.PATROL:
			timeWaited += delta # Add time since last frame
			match currentState:
				states.WAITING:
					if !timeWaited >= waitTime:
						return # If I have not waited at my waypoint long enough, exit early
					else:
						currentState = states.PATROLLING
				states.PATROLLING:
					if !timeWaited >= moveSpeed: # If not enough time has elapsed since the last move, exit the process early
						return
					else:
						if !position == waypoints[currentWaypoint]:
							print("Moving toward [", currentWaypoint, "]: ", waypoints[currentWaypoint])
							timeWaited = 0
							move()
						# If I have reached my waypoint, get a new one and move toward that
						else:
							print("Reached destination [", currentWaypoint, "]: ", waypoints[currentWaypoint])
							timeWaited = 0
							lastWaypoint = currentWaypoint
							# When I reach the end of the waypoints array, where do I go?
							if currentWaypoint >= waypoints.size() - 1:
								# Do I go back the other direction?
								if !makeALoop:
									movingForward = -1
								# Or do I make a loop?
								else:
									movingForward = 1
									currentWaypoint = -1 # Set currentWaypoint to -1 so it rolls over to 0 down below
								
							# When I reach the beginning of the waypoints array, iterate the other direction
							if currentWaypoint <= 0:
								movingForward = 1
							
							# Add movingForward to currentWaypoint to iternate forward or backward through the loop
							currentWaypoint += movingForward


func makeWaypoints() -> void:
	for point in path.points:
		waypoints.push_back(to_global(point))
		print("Point: ", point, " | Global Point: ", to_global(point))


# Called to face the direction of movement or the player
func faceDirection() -> Vector2:
	var direction: Vector2 = (waypoints[currentWaypoint] - global_position).normalized()
	ray.target_position = direction * Globals.TILESIZE
	sprite.play(dirToAnimtionName[direction])
	
	
	var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	
	var travelDir := Vector2.DOWN
	var max_dot := -1.0
	
	for dir in directions:
		var dot := direction.dot(dir)
		if dot > max_dot:
			max_dot = dot
			travelDir = dir
			
	
	return travelDir



func checkPosition() -> bool:
	return position == waypoints[currentWaypoint]


# Called to move the enemy
func move() -> void:
	var direction = faceDirection()
	global_position += direction * Globals.TILESIZE
	
	if showPath: # If path shown, make sure it's positioned at the first waypoint
		path.global_position = waypoints[0]
