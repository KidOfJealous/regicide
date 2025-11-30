extends Node2D

signal restart_game

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

func _ready() -> void:
	# 移除默认隐藏，让show_win()/show_lose()来控制显示
	restart_button.connect("pressed", Callable(self, "_on_restart_button_pressed"))

func show_win() -> void:
	result_label.text = "胜利"
	show()

func show_lose() -> void:
	result_label.text = "失败"
	show()

func _on_restart_button_pressed() -> void:
	# 直接重新加载游戏场景，不再需要通过信号通知
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")