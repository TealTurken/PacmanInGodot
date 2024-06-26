extends Node


var total_pellets_count
var pellets_eaten = 0
var PowerPelletTimer
var ghosts_to_Eat = 0
var pellet_eating_sound_loop_timer = 0.6

@onready var ui = $"../UI" as UI
@onready var chomp_sound_player = $"../SoundPlayers/ChompSoundPlayer"
@onready var power_pellet_sound_player = $"../SoundPlayers/PowerPelletSoundPlayer"
@onready var points_manager = $"../PointsManager"
@onready var background_music_sound_player = $"../SoundPlayers/BackgroundMusicSoundPlayer"

@export var Ghost_Array: Array[Ghost]


func _ready():
	var pellets = self.get_children() as Array[Pellet]
	total_pellets_count = pellets.size()
	
	for pellet in pellets:
		pellet.pellet_eaten.connect(on_pellet_eaten)
		
	for ghost in Ghost_Array:
		ghost.Ghost_eaten_or_escaped.connect(on_ghosts_eaten_or_escaped)
	
	#SOUND
func on_pellet_eaten(should_allow_eating_ghosts: bool):
	if !chomp_sound_player.playing && pellet_eating_sound_loop_timer:
		chomp_sound_player.play()
	
	pellets_eaten += 1
	points_manager.on_pellet_eaten()
	
	if should_allow_eating_ghosts:
		
		if !power_pellet_sound_player.playing:
			power_pellet_sound_player.play()
			background_music_sound_player.stop()
			
		
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
	else:
		pass
	
	if pellets_eaten == total_pellets_count:
		ui.game_won()
		get_tree().paused = true
		await get_tree().create_timer(4.0).timeout
		get_tree().paused = false
		get_tree().reload_current_scene()

func on_ghosts_eaten_or_escaped():
	ghosts_to_Eat -= 1
	if ghosts_to_Eat == 0:
		power_pellet_sound_player.stop()
		background_music_sound_player.play()
