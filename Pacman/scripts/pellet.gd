extends Area2D

class_name Pellet

@export var should_allow_eating_ghosts = false

signal pellet_eaten(should_allow_eating_ghosts: bool)


func _on_body_entered(body):
	if body is Player:
		pellet_eaten.emit(should_allow_eating_ghosts)
		queue_free()
