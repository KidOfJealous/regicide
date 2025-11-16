extends Node2D

signal finish_play
signal finish_defend
@onready var button:Button = $Button
@onready var hand:Hand = $Hand
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func play_cards()->void:
	hand.station = CardData.TurnStation.PLAYER
	await button.pressed
	finish_play.emit()
func 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
