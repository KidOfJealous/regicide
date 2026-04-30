extends Node
# AudioManager - 音效管理器（自动加载单例，无需class_name）

# 音效播放器池
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 8  # 最大同时播放音效数量

# 音效文件路径定义
const SFX_PATHS = {
	"card_play": "res://audio/card_play.wav",      # 出牌音效
	"card_draw": "res://audio/card_draw.wav",      # 抽牌音效
	"card_flip": "res://audio/card_flip.wav",      # 翻牌音效
	"card_select": "res://audio/card_select.wav",  # 选牌音效
	"boss_attack": "res://audio/boss_attack.wav",  # Boss攻击音效
	"boss_defeat": "res://audio/boss_defeat.wav",  # Boss击败音效
	"boss_spawn": "res://audio/boss_spawn.wav",    # Boss出现音效
	"damage": "res://audio/damage.wav",            # 伤害音效
	"shield": "res://audio/shield.wav",            # 黑桃护盾音效
	"heal": "res://audio/heal.wav",                # 红心恢复音效
	"draw_cards": "res://audio/draw_cards.wav",    # 方块抽牌音效
	"double_damage": "res://audio/double_damage.wav", # 梅花翻倍音效
	"joker_play": "res://audio/joker_play.wav",    # Joker出牌音效
	"win": "res://audio/win.wav",                  # 胜利音效
	"lose": "res://audio/lose.wav",                # 失败音效
	"button_click": "res://audio/button_click.wav", # 按钮点击音效
	"turn_change": "res://audio/turn_change.wav",  # 回合切换音效
}

# 音效音量设置
var master_volume: float = 1.0
var sfx_volume: float = 0.8

# 缓存已加载的音频流
var audio_cache: Dictionary = {}

func _ready() -> void:
	# 创建音效播放器池
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(player)
		sfx_players.append(player)

# 播放音效
func play_sfx(sfx_name: String, volume_scale: float = 1.0) -> void:
	if not SFX_PATHS.has(sfx_name):
		push_warning("音效不存在: " + sfx_name)
		return
	
	# 检查音频是否已缓存
	var audio_stream: AudioStream
	if audio_cache.has(sfx_name):
		audio_stream = audio_cache[sfx_name]
	else:
		var path = SFX_PATHS[sfx_name]
		if not ResourceLoader.exists(path):
			push_warning("音效文件不存在: " + path)
			return
		audio_stream = load(path)
		audio_cache[sfx_name] = audio_stream
	
	# 找到一个空闲的播放器
	var player = _get_available_player()
	if player:
		player.stream = audio_stream
		player.volume_db = linear_to_db(sfx_volume * master_volume * volume_scale)
		player.play()

# 获取可用的播放器
func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# 如果所有播放器都在使用，返回第一个（会被打断）
	return sfx_players[0]

# 设置音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func _update_all_volumes() -> void:
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

# 停止所有音效
func stop_all_sfx() -> void:
	for player in sfx_players:
		player.stop()

# ========== 常用音效快捷方法 ==========

func play_card_play() -> void:
	play_sfx("card_play")

func play_card_draw() -> void:
	play_sfx("card_draw")

func play_card_flip() -> void:
	play_sfx("card_flip")

func play_card_select() -> void:
	play_sfx("card_select")

func play_boss_attack() -> void:
	play_sfx("boss_attack")

func play_boss_defeat() -> void:
	play_sfx("boss_defeat", 1.2)  # 略大声

func play_boss_spawn() -> void:
	play_sfx("boss_spawn", 1.0)

func play_damage() -> void:
	play_sfx("damage")

func play_win() -> void:
	play_sfx("win", 1.5)  # 胜利音效更大声

func play_lose() -> void:
	play_sfx("lose", 1.2)

func play_button_click() -> void:
	play_sfx("button_click", 0.5)  # 按钮音效较轻

func play_joker() -> void:
	play_sfx("joker_play", 1.3)

# 花色效果音效
func play_suit_effect(suit: CardData.Suit) -> void:
	match suit:
		CardData.Suit.CLUB:
			play_sfx("double_damage")
		CardData.Suit.HEART:
			play_sfx("heal")
		CardData.Suit.DIAMOND:
			play_sfx("draw_cards")
		CardData.Suit.SPADE:
			play_sfx("shield")