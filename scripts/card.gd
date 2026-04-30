class_name Card extends Node2D
signal hover
const card_scene = preload("res://scenes/card.tscn")

# 使用 get_node_or_null 而非 @onready，避免加载顺序问题
var front_mask: ColorRect
var animation_player: AnimationPlayer
var _is_ready: bool = false  # 标记是否已完成_ready初始化

# 悬停状态
var hovered: bool:
	set(b):
		hovered = b
		if not _is_ready:
			return  # 未初始化时跳过
		if b:
			_animate_scale(CardData.HOVER_SCALE)
			self.z_index = 2
		else:
			_animate_scale(CardData.ORIGIN_SCALE)
			self.z_index = 1

# 选中状态
var selected: bool:
	set(value):
		if selected != value:
			selected = value
			if not _is_ready:
				return  # 未初始化时跳过
			if selected:
				_animate_scale(Vector2(1.1, 1.1))
				self.z_index = 3
			else:
				_animate_scale(CardData.ORIGIN_SCALE)
				self.z_index = 1

# 禁用状态
var disabled: bool:
	set(value):
		disabled = value
		if not _is_ready:
			return  # 未初始化时跳过
		if front_mask:
			front_mask.visible = disabled
		# 禁用时添加灰暗效果
		if disabled:
			self.modulate = Color(0.6, 0.6, 0.6, 1.0)
		else:
			self.modulate = Color(1.0, 1.0, 1.0, 1.0)

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
		if not _is_ready:
			return  # 未初始化时跳过
		$back.visible = back
		$front.visible = !back
var hand_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 初始化节点引用
	front_mask = get_node_or_null("front/ColorRect")
	animation_player = get_node_or_null("AnimationPlayer")
	_is_ready = true
	self.get_parent().connect_card(self)
	z_index = 1

# 翻牌动画
func flip():
	if not _is_ready:
		# 未初始化时动态获取
		var player = get_node_or_null("AnimationPlayer")
		if player:
			player.play("flip")
		return
	if animation_player:
		animation_player.play("flip")

# 平滑缩放动画
func _animate_scale(target_scale: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# 平滑移动动画（外部调用）
func animate_move_to(target_pos: Vector2, duration: float = 0.2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

# 出牌动画（向上飞出）
func animate_play() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.2)

# 被击败动画（Boss牌）
func animate_defeated() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 注意：不在此处queue_free，由调用方处理卡牌节点
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
