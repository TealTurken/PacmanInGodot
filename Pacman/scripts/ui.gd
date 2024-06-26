extends CanvasLayer


class_name UI

@onready var center_container = $MarginContainer/CenterContainer
@onready var life_counter_label = %LifeCounterLabel
@onready var game_score_label = %GameScoreLabel
@onready var game_label = %GameLabel

func set_lives(lives):
	life_counter_label.text = "LIVES %d" % lives

func set_score(score):
	game_score_label.text = "SCORE %d" % score

func game_over():
	game_label.text = "Game Over"
	center_container.show()

func game_won():
	game_label.text = "You Win!"
	center_container.show()
