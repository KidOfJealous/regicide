class_name InputManager extends Node2D
signal on_left_click
signal on_left_release

@onready var deck_reference:Deck = $"../Deck"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		event = event as InputEventMouseButton
		if event.pressed:
			var card = prepare_card()
		else:
			pass

func prepare_card()->Card:
	var space_state = get_world_2d().direct_space_state
	var paras = PhysicsPointQueryParameters2D.new()
	paras.position = get_global_mouse_position()
	paras.collide_with_areas = true
	var cards = space_state.intersect_point(paras)
	if cards.size()>0:
		var mask = cards[0].collider.collision_mask
		if mask == CardManager.CARD_COLLISION_MASK:
			var card_found = cards[0].collider.get_parent()
		elif mask == CardManager.CARD_COLLISION_MASK:
			deck_reference.draw_card()
	return null
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
