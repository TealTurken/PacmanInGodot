extends Area2D

class_name Ghost

enum GhostState {
	SCATTER,
	CHASE,
	RUN_AWAY,
	EATEN,
	STARTING_AT_HOME
}

var current_scatter_index = 0
var current_home_index = 0
var direction = null
var current_state
var isBlinking = false
var speed
var start_position
var start_state

signal Ghost_eaten_or_escaped

@onready var direction_lookup_table = {
	"down": down,
	"up": up,
	"left": left,
	"right": right
}

@export_group("Configuration")
@export var normalSpeed = 120
@export var runHomeSpeed = 250
@export var color: Color
@export var is_starting_at_home = false
@export_group("")

@export_group("Navigation and References")
@export var movement_targets: Array[Node2D]
@export var home_movement_targets: Array[Node2D]
@export var tile_map: MazeTileMap
@export var chasing_target: Node2D
@export var points_manager: PointsManager
@export_group("")

@export_group("Eye Textures")
@export var up: Texture2D
@export var down: Texture2D
@export var left: Texture2D
@export var right: Texture2D
@export_group("")

@onready var navigation_agent_2d = $NavigationAgent2D
@onready var body_sprite = $BodySprite
@onready var eye_sprite = $EyeSprite
@onready var animation_player = $AnimationPlayer
@onready var scatter_timer = $ScatterTimer
@onready var at_home_timer = $AtHomeTimer
@onready var eaten_timeout_timer = $EatenTimeoutTimer
@onready var update_chasing_target_position_timer = $UpdateChasingTargetPositionTimer
@onready var run_away_timer = $RunAwayTimer
@onready var points_label = $pointsLabel
@onready var eat_ghost_sound_player = $"../../SoundPlayers/EatGhostSoundPlayer"



func _ready():
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	navigation_agent_2d.target_reached.connect(on_postion_reached)
	start_position = self.get_position()
	speed = normalSpeed
	
	call_deferred("setup") # return to set up when no other code is running(?)

func _process(delta):
	if !run_away_timer.is_stopped() && run_away_timer.time_left < run_away_timer.wait_time / 2 && !isBlinking:
		start_blinking()
	move_ghost(navigation_agent_2d.get_next_path_position(), delta)

func move_ghost(next_position: Vector2, delta: float):
	var current_ghost_position = global_position
	
	var new_velocity = (next_position - current_ghost_position).normalized() * speed * delta
	
	calculate_direction(new_velocity)
	
	position += new_velocity	

func calculate_direction(new_velocity: Vector2):
	#Used for Eye Sprite updating
	var current_direction
	
	if new_velocity.x > 1:
		current_direction = "right"
	elif new_velocity.x < -1:
		current_direction = "left"
	elif new_velocity.y > 1:
		current_direction = "down"
	elif new_velocity.y < -1:
		current_direction = "up"
		
	if current_direction != direction:
		direction = current_direction
		change_eyes(current_direction)

func change_eyes(direction_of_movement):
	if direction_of_movement == null:
		return
	eye_sprite.texture = direction_lookup_table[direction_of_movement]

func setup():
	body_sprite.modulate = color
	animation_player.play("moving")
	navigation_agent_2d.set_navigation_map(tile_map.get_navigation_map(0))
	NavigationServer2D.agent_set_map(navigation_agent_2d.get_rid(), tile_map.get_navigation_map(0))
	if is_starting_at_home:
		start_at_home()
	else:
		scatter()
	start_state = current_state

func scatter():
	scatter_timer.start()
	current_state = GhostState.SCATTER
	navigation_agent_2d.target_position = movement_targets[current_scatter_index].position	

func beserk():
	reset_ghost_parameters()
	scatter_timer.stop()
	run_away_timer.stop()
	at_home_timer.stop()
	body_sprite.modulate = Color.WHITE
	eye_sprite.hide()
	animation_player.play("Beserk")
	speed = 0
	await get_tree().create_timer(8.0).timeout
	body_sprite.position = Vector2(0.0, 0.0)
	body_sprite.modulate = color
	eye_sprite.show()
	if self.name == "YellowGhost": eye_sprite.modulate = Color(0.0, 200.0, 200.0)
	else: eye_sprite.modulate = Color(50.0, 50.0, 0.0)
	eye_sprite.position = Vector2(0.0, 0.0)
	animation_player.play("moving")
	speed = 200
	current_state = GhostState.CHASE
	update_chasing_target_position_timer.start()

func start_at_home():
	at_home_timer.start()
	current_state = GhostState.STARTING_AT_HOME
	navigation_agent_2d.target_position = home_movement_targets[0].position

func on_postion_reached():
	if current_state == GhostState.SCATTER:
		if current_scatter_index < movement_targets.size()-1:
			current_scatter_index += 1
		else:
			current_scatter_index = 0
		navigation_agent_2d.target_position = movement_targets[current_scatter_index].position
	
	elif current_state == GhostState.EATEN:
		if eaten_timeout_timer.is_stopped():
			eaten_timeout_timer.start()
		movement_at_home()
	
	elif current_state == GhostState.STARTING_AT_HOME:
		movement_at_home()

	elif current_state == GhostState.CHASE:
		navigation_agent_2d.target_position = chasing_target.position
	
	elif current_state == GhostState.RUN_AWAY:
		run_away_movement()

func _on_scatter_timer_timeout():
	start_chasing_pacman()

func start_chasing_pacman():
	if chasing_target == null:
		print("No Target for ghost to chase")
	else:
		navigation_agent_2d.target_position = chasing_target.position	
		current_state = GhostState.CHASE
		update_chasing_target_position_timer.start()

func _on_update_chasing_target_position_timer_timeout():
	navigation_agent_2d.target_position = chasing_target.position	

func run_away_from_pacman():
	if run_away_timer.is_stopped():
		run_away_timer.start()
		scatter_timer.stop()
		update_chasing_target_position_timer.stop()
		body_sprite.modulate = Color.WHITE
		eye_sprite.hide()
		animation_player.play(("running_away"))
		current_state = GhostState.RUN_AWAY
	run_away_movement()

func run_away_movement():
	var empty_cell_position = tile_map.get_random_empty_cell()
	navigation_agent_2d.target_position = empty_cell_position

func _on_run_away_timer_timeout():
	isBlinking = false
	reset_ghost_parameters()
	start_chasing_pacman()
	Ghost_eaten_or_escaped.emit()

func start_blinking():
	isBlinking = true
	animation_player.play("running_away_blinking")

func _on_body_entered(body):
	var player = body as Player
	if current_state == GhostState.RUN_AWAY: #ghost dies
		get_eaten()
	elif current_state == GhostState.EATEN: #ignore collision
		pass
	else: #player dies
		update_chasing_target_position_timer.stop()
		player.die()
		scatter()

func get_eaten():
	eat_ghost_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS
	eat_ghost_sound_player.play()
	body_sprite.hide()
	eye_sprite.show()
	points_label.show()
	await points_manager.pause_on_ghost_eaten()
	points_label.hide()
	run_away_timer.stop()
	current_state = GhostState.EATEN
	Ghost_eaten_or_escaped.emit()
	speed = runHomeSpeed
	current_home_index = 0
	navigation_agent_2d.target_position = home_movement_targets[0].position

func _on_eaten_timeout_timer_timeout():
	reset_ghost_parameters()
	start_chasing_pacman()

func movement_at_home():
	current_home_index = 1 if current_home_index == 0 else 0
	navigation_agent_2d.target_position = home_movement_targets[current_home_index].position

func _on_at_home_timer_timeout():
	scatter()

func reset_timers():
	scatter_timer.stop()
	eaten_timeout_timer.stop()
	update_chasing_target_position_timer.stop()
	run_away_timer.stop()
	at_home_timer.stop()

func reset_ghost_parameters():
	body_sprite.show()
	body_sprite.modulate = color
	eye_sprite.show()
	eye_sprite.modulate = Color(1.0, 1.0, 1.0)
	speed = normalSpeed
	animation_player.play("moving")
	isBlinking = false
	current_home_index = 0
