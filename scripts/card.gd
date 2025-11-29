class_name Card extends Node2D
signal hover
const card_scene = preload("res://scenes/card.tscn")
@onready var front_mask: ColorRect = $"front/ColorRect"
var hovered: bool:
	set(b):
		hovered = b
		if b:
			self.scale = CardData.HOVER_SCALE
			self.z_index = 2
		else:
			self.scale = CardData.ORIGIN_SCALE
			self.z_index = 1
var selected: bool:
	set(value):
		selected = value
var disabled: bool:
	set(value):
		disabled = value
		front_mask.visible = disabled
var value: int
var suit: CardData.Suit
var rank: String
var role: CardData.CardPosition
var back: bool = false:
	set(value):
		back = value
		$back.visible = back
		$front.visible = !back
var hand_position: Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.get_parent().connect_card(self)
	z_index = 1
func flip():
	($AnimationPlayer as AnimationPlayer).play("flip")
static func init_card_scene(s: CardData.Suit = CardData.Suit.SPADE, num: CardData.CardNum = CardData.CardNum.ACE, b: bool = false) -> Card:
	var card: Card = card_scene.instantiate()
	card.rank = CardData.CardNumNames[num]
	card.suit = s
	card.value = num + 1
	card.back = b
	var image_path = str("res://images/" + CardData.SuitNames[s] + "_" + card.rank + ".png")
	print(image_path)
	(card.get_node("front") as Sprite2D).texture = load(image_path)
	return card

static func init_boss_scene(s: CardData.Suit = CardData.Suit.SPADE, num: CardData.Boss = CardData.Boss.JACK, b = false) -> Card:
	var card: Card = card_scene.instantiate()
	card.rank = CardData.BossNames[num]
	card.suit = s
	card.value = CardData.BossValues[num]
	(card.get_node("front") as Sprite2D).texture = load(str("res://images/" + CardData.SuitNames[s] + "_" + card.rank + ".png"))
	card.back = b
	return card

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _on_area_2d_mouse_entered() -> void:
	if self.role==CardData.CardPosition.HAND:
		self.hover.emit(self, true)

func _on_area_2d_mouse_exited() -> void:
	self.hover.emit(self, false)
