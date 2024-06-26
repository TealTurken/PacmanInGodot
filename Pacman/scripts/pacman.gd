extends CharacterBody2D

class_name Player

#variables
var movement_direction = Vector2.ZERO
var next_movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new() #like raycasting
var start_position
var livesCount #actual track of lives, changes in code

#export variables
@export var speed = 300
@export var lives = 2 #editable lives count, never changes in code
@export var ui: UI

#onready variables
@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var pacman_death_sound_player = $"../SoundPlayers/PacmanDeathSoundPlayer"
@onready var power_pellet_sound_player = $"../SoundPlayers/PowerPelletSoundPlayer"

signal player_died_with_lives

func _ready():
	shape_query.shape = collision_shape_2d.shape
	shape_query.collision_mask = 2
	
	animation_player.play("Pacman_default")
	animation_player.pause()
	start_position = self.get_position()
	livesCount = lives
	ui.set_lives(livesCount)

func _physics_process(delta): 
	get_input()
	
	if movement_direction == Vector2.ZERO:
		movement_direction = next_movement_direction
	if can_move_in_direction(next_movement_direction, delta):
		movement_direction = next_movement_direction

	velocity = movement_direction * speed
	move_and_slide()
	
	
func get_input(): #actual change of movement&rotation
	if Input.is_action_pressed("left"):
		next_movement_direction = Vector2.LEFT
		rotation_degrees = 0
	elif Input.is_action_pressed("right"):
		next_movement_direction = Vector2.RIGHT
		rotation_degrees = 180
	elif Input.is_action_pressed("down"):
		next_movement_direction = Vector2.DOWN
		rotation_degrees = 270
	elif Input.is_action_pressed("up"):
		next_movement_direction = Vector2.UP
		rotation_degrees = 90
	
	#Animation pause if pressed to a wall
	if velocity.is_zero_approx():
		animation_player.pause()
	elif !animation_player.is_playing():
		animation_player.play("Pacman_default")

func can_move_in_direction(dir: Vector2, delta: float) -> bool:
	shape_query.transform = global_transform.translated(dir * speed * delta * 2)
	var result = get_world_2d().direct_space_state.intersect_shape(shape_query)
	return result.size() == 0

func die(): #called by ghost that hit player
	#freeze frame game
	get_tree().paused = true
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	
	#death animation
	rotation_degrees = 180
	animation_player.speed_scale = 1
	animation_player.play("Pacman_death")
	pacman_death_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS
	pacman_death_sound_player.play()
	power_pellet_sound_player.stop()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	#reset game
	await get_tree().create_timer(4.0).timeout
	
	if livesCount > 0: #keep board progress, respawn Pacman
		livesCount -= 1
		ui.set_lives(livesCount)
		self.set_position(start_position)
		animation_player.play("Pacman_default")
		set_physics_process(true)
		process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().paused = false
		player_died_with_lives.emit()
		next_movement_direction = Vector2.ZERO
		return
	
	if livesCount <= 0: #total reset of game
		ui.game_over()
		await get_tree().create_timer(3.0).timeout
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
