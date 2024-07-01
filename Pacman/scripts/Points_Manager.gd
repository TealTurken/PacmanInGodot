extends Node

class_name PointsManager

@onready var ui = $"../UI" as UI

var points = 0
var doublePoints = false

func pause_on_ghost_eaten(): #called from Ghost.gd (script)
	if doublePoints: points += 400
	else: points += 200
	ui.set_score(points)
	get_tree().paused = true
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false

func on_pellet_eaten(): #called from pellets_manager
	if doublePoints: points += 20
	else: points += 10
	ui.set_score(points)
