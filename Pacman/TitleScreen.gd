extends Control


@onready var button = $Title/Button
@onready var start_button_flash_timer = $StartButtonFlashTimer
@onready var title = $Title
@onready var get_ready_box = $"Get Ready Box"
@onready var game_label = %GameLabel
@onready var intro_theme_player = $IntroThemePlayer
@onready var tile_map = $TileMap

func _ready():
	start_button_flash_timer.start()

func _on_button_pressed():
	start_button_flash_timer.stop
	title.visible = false
	get_ready_box.visible = true
	intro_theme_player.play()
	await get_tree().create_timer(1.0).timeout
	game_label.text = "Get Ready."
	await get_tree().create_timer(1.0).timeout
	game_label.text = "Get Ready.."
	await get_tree().create_timer(1.0).timeout
	game_label.text = "Get Ready..."
	await get_tree().create_timer(1.25).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_start_button_flash_timer_timeout():
	button.visible = !button.visible
	start_button_flash_timer.start()
	
