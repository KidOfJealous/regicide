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
# 卡牌类型：普通牌、Boss牌、Joker牌
var card_type: CardData.CardType = CardData.CardType.NORMAL
# Joker类型（仅Joker牌使用）
var joker_type: CardData.Joker = CardData.Joker.LITTE_JOKER
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
	card.card_type = CardData.CardType.BOSS
	(card.get_node("front") as Sprite2D).texture = load(str("res://images/" + CardData.SuitNames[s] + "_" + card.rank + ".png"))
	card.back = b
	return card

# 创建Joker牌
static func init_joker_scene(joker_type: CardData.Joker = CardData.Joker.LITTE_JOKER, b: bool = false) -> Card:
	var card: Card = card_scene.instantiate()
	card.rank = "joker"
	card.value = CardData.JOKER_VALUE
	card.card_type = CardData.CardType.JOKER
	card.joker_type = joker_type  # 保存Joker类型
	# Joker没有花色，SPADE仅作为占位符，不应在任何花色效果逻辑中使用
	# Joker打出后会直接取消免疫并跳过攻击，不会触发花色效果
	card.suit = CardData.Suit.SPADE
	(card.get_node("front") as Sprite2D).texture = load("res://images/joker.png")
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
