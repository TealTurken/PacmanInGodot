extends Node

var total_pellets_count
var pellets_eaten = 0
var PowerPelletTimer
var PowerPelletsEatenInTimer = 0
var ghosts_to_Eat = 0
var pellet_eating_sound_loop_timer = 0.6

@onready var ui = $"../UI" as UI
@onready var chomp_sound_player = $"../SoundPlayers/ChompSoundPlayer"
@onready var power_pellet_sound_player = $"../SoundPlayers/PowerPelletSoundPlayer"
@onready var points_manager = $"../PointsManager"
@onready var background_music_sound_player = $"../SoundPlayers/BackgroundMusicSoundPlayer"
@onready var tile_map = $"../TileMap"
@onready var power_pellets_eaten_in_timer = $"../PowerPelletsEatenInTimer"

@export var Ghost_Array: Array[Ghost]

func _ready():
	var pellets = self.get_children() as Array[Pellet]
	total_pellets_count = pellets.size()
	
	for pellet in pellets:
		pellet.pellet_eaten.connect(on_pellet_eaten)
		
	for ghost in Ghost_Array:
		ghost.Ghost_eaten_or_escaped.connect(on_ghosts_eaten_or_escaped)
	

func on_pellet_eaten(should_allow_eating_ghosts: bool):
	if !chomp_sound_player.playing && pellet_eating_sound_loop_timer:
		chomp_sound_player.play()
	
	pellets_eaten += 1
	points_manager.on_pellet_eaten()
	
	#POWER PELLET EATEN
	if should_allow_eating_ghosts:
		PowerPelletsEatenInTimer += 1
		power_pellets_eaten_in_timer.start()
		if !ui.double_points_label.visible: 
			ui.double_points_label.visible = true
		
		#SOUND
		if !power_pellet_sound_player.playing:
			power_pellet_sound_player.play()
			background_music_sound_player.stop()
			
		#GHOST BESERK STATE
		if PowerPelletsEatenInTimer == 1: #ghost berserk
			points_manager.doublePoints = true
			tile_map.modulate = Color(180.0, 0.0, 0.0)
			for ghost in Ghost_Array:
				ghost.beserk()
		#GHOST RUN STATE
		else: 
			for ghost in Ghost_Array:
				if ghost.current_state == ghost.GhostState.EATEN || ghost.current_state == ghost.GhostState.STARTING_AT_HOME:
					continue
				elif ghost.current_state == ghost.GhostState.RUN_AWAY:
					ghost.run_away_timer.start()
					ghost.animation_player.play(("running_away"))
				else:
					ghosts_to_Eat += 1
					print(ghosts_to_Eat)
					ghost.run_away_from_pacman()
	
	if pellets_eaten == total_pellets_count:
		game_win()

func on_ghosts_eaten_or_escaped():
	ghosts_to_Eat -= 1
	if ghosts_to_Eat == 0:
		power_pellet_sound_player.stop()
		background_music_sound_player.play()

func game_win():
	ui.game_won()
	get_tree().paused = true
	await get_tree().create_timer(4.0).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_timer_timeout():
	PowerPelletsEatenInTimer = 0
