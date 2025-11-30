extends Node2D
@onready var player: Player = $"../Players/Player"
@onready var end_turn_button_ref: EndTurnButton = $"../Button"
@onready var boss_dec: BossDeck = $"../BossDeck"
@onready var deck: Deck = $"../Deck"
@onready var discard: Discard = $"../Discard"
@onready var field: CardField = $"../CardField"

var end:bool = false
var station: CardData.TurnStation = CardData.TurnStation.PLAYER
var is_initialized: bool = false

func _ready():
	# 在_ready中不直接调用_start，而是标记需要初始化
	pass

func _process(delta):
	# 在_process中检查是否所有依赖都已准备好
	if not is_initialized:
		_try_initialize()

func _try_initialize():
	# 检查Player和其Hand是否都已初始化
	if player != null and player.hand != null:
		is_initialized = true
		set_process(false)  # 停止_process调用
		_start()

func take_turns()->void:
	await player_play()

func player_play():
	station = CardData.TurnStation.PLAYER
	# 检查玩家是否还有手牌，如果没有则判负
	if player.get_hand_card_count() == 0:
		lose()
		return
	var selected =  await player.wait_for_play()
	player.remove_selected_cards()
	await card_effect(selected)
	
func _start():
	boss_dec.draw_card()
	deck.draw_card(CardData.MAX_HAND_CARD_NUM, player)
	while not end:
		await take_turns()

func card_effect(cards: Array[Card]) -> void:
	var boss = boss_dec.current_boss
	var value = 0
	var suits: Array[int] = [false, false, false, false]
	for card in cards:
		if not (card.suit == boss.suit or suits[card.suit]):
			suits[card.suit] = true
		value += card.value
	var damage = value
	if suits[CardData.Suit.CLUB]:
		damage *= 2
	if suits[CardData.Suit.HEART]:
		_restore_deck(value)
	if suits[CardData.Suit.DIAMOND]:
		deck.draw_card(value, player)
	if suits[CardData.Suit.SPADE]:
		boss_dec.current_boss_attack -= value
	add_to_field(cards)
	boss_dec.current_boss_health -= damage
	boss_dec.refresh_status()
	if boss_dec.current_boss_health <= 0:
		boss_to_deck(boss, boss_dec.current_boss_health == 0)
		add_to_discard(field.cards)
		field.cards = []
		field.fresh_pos()
		if boss_dec._cards.size() > 0:  # 还有Boss牌
			boss_dec.draw_card()  # 抽取下一个Boss
		else:
			win()
	else:
		await boss_attack()
		
func add_to_discard(cards: Array[Card]):
	discard.cards += cards
	discard.fresh_pos()

func add_to_field(cards: Array[Card]) -> void:
	field.cards += cards
	field.fresh_pos()

func boss_attack() -> void:
	station = CardData.TurnStation.DEFEND
	if player.get_hand_card_sum() < boss_dec.current_boss_attack:
		lose()
	else:
		var cards: Array[Card] = await player.wait_for_discard(boss_dec.current_boss_attack)
		player.remove_selected_cards()
		add_to_discard(cards)

func win():
	end = true
	print("You win")
	# 显示胜利界面
	show_game_over(true)

func lose():
	end = true
	print("You lose")
	# 显示失败界面
	show_game_over(false)

func show_game_over(is_win: bool) -> void:
	# 加载并显示游戏结束界面
	var game_over_scene = preload("res://scenes/game_over.tscn")
	var game_over = game_over_scene.instantiate()
	add_child(game_over)
	
	if is_win:
		game_over.show_win()
	else:
		game_over.show_lose()
		
	# 连接重新开始游戏的信号
	game_over.connect("restart_game", Callable(self, "_restart_game"))

func _restart_game() -> void:
	# 重新开始游戏的逻辑
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

func _restore_deck(num: int):
	deck.put_cards_back(discard.getCards(num))
	
func boss_to_deck(boss: Card, mercy: bool = false):
	if mercy:
		deck.put_boss_top(boss)
	else:
		discard.cards.push_back(boss)
