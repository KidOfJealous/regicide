class_name BossDeck extends Node2D
var _cards: Array[Card] = []
var current_boss: Card = null
var current_boss_health: int
var current_boss_attack: int:
	set(value):
		current_boss_attack = max(0, value)
# Boss免疫状态 - 默认为false，Joker可将其设为true取消免疫
var immune_cancelled: bool = false

# 使用普通变量而非@onready，在_ready中手动初始化
var health_text: Label
var attach_text: Label
var immune_text: Label
var card_manager_ref  # 动态类型

# 花色名称映射（与CardData.Suit枚举对应）
const SUIT_NAMES = ["黑桃", "方块", "红心", "梅花"]
const health_template = "生命值：{0}/{1}"
const attack_template = "攻击力：{0}/{1}"

func _ready() -> void:
	# 手动初始化节点引用（在调用其他函数之前）
	health_text = get_node_or_null("Health")
	attach_text = get_node_or_null("Attack")
	immune_text = get_node_or_null("Immune")
	card_manager_ref = get_node_or_null("../CardManager")
	_init_boss_cards()
func _init_boss_cards() -> void:
	for i in range(2, -1, -1):
		var _temp: Array[Card] = []
		for j in range(4):
			var card = Card.init_boss_scene(j, i)
			card.role = CardData.CardPosition.BOSS
			card.position = self.position
			_temp.push_back(card)
		_temp.shuffle()
		_cards += _temp
	draw_card()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func refresh_status() -> void:
	var attack = current_boss.value
	health_text.text=health_template.format([self.current_boss_health,attack*2])
	attach_text.text=attack_template.format([self.current_boss_attack,attack])
	# 更新免疫状态显示
	_update_immune_display()

# 更新免疫状态显示
func _update_immune_display() -> void:
	if immune_text:
		if current_boss and current_boss.suit != null:
			var suit_name = SUIT_NAMES[current_boss.suit]
			if immune_cancelled:
				immune_text.text = "免疫已取消"
				immune_text.add_theme_color_override("font_color", Color.YELLOW)
			else:
				immune_text.text = "免疫: " + suit_name
				immune_text.add_theme_color_override("font_color", Color.WHITE)
		else:
			immune_text.text = ""
	
func draw_card() -> void:
	if _cards.is_empty():
		return
	current_boss = _cards.pop_back() as Card
	current_boss_health = current_boss.value * 2
	current_boss_attack = current_boss.value
	# 新Boss出现时重置免疫状态
	immune_cancelled = false
	current_boss.flip()
	if card_manager_ref:
		card_manager_ref.add_child(current_boss)
	refresh_status()
