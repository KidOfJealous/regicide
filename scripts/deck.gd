class_name Deck extends Node2D
var _cards:Array[Card] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_hand_cards() # Replace with function body.
@onready var card_manager_ref:CardManager=$"../CardManager"
@onready var count_label: Label = $CountLabel

func _init_hand_cards()->void:
	for i in range(4):
		for j in range(10):
			var card = Card.init_card_scene(i,j)
			card.role = CardData.CardPosition.DECK
			card.position = self.position
			_cards.push_back(card)
	_cards.shuffle()
	updateStatus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 抽牌方法 - 返回指定数量的卡牌，不直接添加到手牌
func get_cards(num:int=1)->Array[Card]:
	var result: Array[Card] = []
	var count = min(num, _cards.size())
	for i in range(count):
		if not _cards.is_empty():
			var card = _cards.pop_back() as Card
			result.push_back(card)
	updateStatus()
	return result

# 旧的draw_card方法保留以保持兼容，但现在需要传入player引用
func draw_card(num:int=1, player: Player = null)->void:
	if player == null:
		# 如果没有传入player，直接返回，这是为了防止错误
		push_error("Deck.draw_card() requires a player parameter. Use get_cards() instead.")
		return
	
	if not player.can_add_card():
		return
	else:
		while num>0 and player.can_add_card() and not _cards.is_empty():
			var card = _cards.pop_back() as Card
			card_manager_ref.add_child(card)
			player.add_card_to_hand(card)
			card.flip()
			num-=1
			await  get_tree().create_timer(0.2).timeout
	updateStatus()

func put_boss_top(card:Card)->void:
	_cards.push_back(card)
	updateStatus()

func put_cards_back(cards:Array[Card])->void:
	_cards=cards+_cards
	updateStatus()

func updateStatus():
	$empty.visible=_cards.is_empty()
	$card_back.visible = !_cards.is_empty()
	
	# 更新计数显示
	if count_label:
		count_label.text = str(_cards.size())