extends Node

@onready var player = $"../Player" as Player

func _ready():
	player.player_died_with_lives.connect(reset_ghosts)

func reset_ghosts():
	var ghosts = self.get_children() as Array[Ghost]
	for ghost in ghosts:
		ghost.reset_timers()
		ghost.reset_ghost_parameters()
		ghost.setup()
		ghost.set_position(ghost.start_position)
		ghost.current_state = ghost.start_state
