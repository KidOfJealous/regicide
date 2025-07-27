class_name CardManager extends Node2D
static var CARD_COLLISION_MASK = 1
static var CARD_SLOT_COLLISION_MASK = 2
var card_dragging:Card
var card_hovering:Card
var screen_size:Vector2
@onready var player_hand:Hand = $"../Hand"
@onready var input_manager:InputManager = $"../InputManager"
# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		event = event as InputEventMouseButton
		if event.pressed:
			var card = prepare_card()
			if card and card is Card:
				_drag(card)
		else:
			_drag_release()
func _drag(card:Card):
	card_dragging = card
	card.scale=Card.origin_scale
	
func _drag_release():
	if card_dragging:
		card_dragging.scale=Card.hover_scale
		var card_slot = prepare_card_slot()
		if card_slot and not card_slot.card:
			player_hand.remove_from_hand(card_dragging)
			card_dragging.position = card_slot.position
			(card_dragging.get_node("Area2D/CollisionShape2D") as CollisionShape2D).disabled = true
			card_slot.card = card_dragging
		else:
			player_hand.add_to_hand(card_dragging)
		card_dragging = null
	
func _ready() -> void:
	screen_size = get_viewport_rect().size # Replace with function body.
	input_manager.on_left_release.connect(_on_click_release)

func _on_click_release():
	_drag_release()

func connect_card(card:Card)->void:
	card.hover.connect(_hover)
	

func _hover(card:Card,hover:bool)->void:
	if hover:
		if !card_hovering:
			card_hovering = card
			card.set_hover(true)
	else:
		card.set_hover(false)
		var new_card = prepare_card()
		if new_card:
			card_hovering = new_card
			new_card.set_hover(true)
		else:
			card_hovering = null
				
func prepare_card()->Card:
	var space_state = get_world_2d().direct_space_state
	var paras = PhysicsPointQueryParameters2D.new()
	paras.position = get_global_mouse_position()
	paras.collision_mask=CARD_COLLISION_MASK
	paras.collide_with_areas = true
	var cards = space_state.intersect_point(paras)
	if cards.size()>0:
		return _get_highest(cards)
	return null
	
func prepare_card_slot()->CardSlot:
	var space_state = get_world_2d().direct_space_state
	var paras = PhysicsPointQueryParameters2D.new()
	paras.position = get_global_mouse_position()
	paras.collision_mask=CARD_SLOT_COLLISION_MASK
	paras.collide_with_areas = true
	var cards = space_state.intersect_point(paras)
	if cards.size()>0:
		return cards[0].collider.get_parent()
	return null
	
func _get_highest(cards)->Card:
	var res = null
	for c in cards:
		var card = c.collider.get_parent() as Card
		if !res or card.z_index > res.z_index:
			res = card
	return res
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_dragging:
		var mouse_pos = get_global_mouse_position()
		card_dragging.position = Vector2(clamp(mouse_pos.x,0,screen_size.x),clamp(mouse_pos.y,0,screen_size.y))
