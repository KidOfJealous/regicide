# API参考

## CardData类

### 常量
| 常量名 | 类型 | 值 | 描述 |
|--------|------|----|------|
| CARD_WIDTH | float | 73.2 | 卡牌宽度 |
| CARD_LENGTH | float | 102.4 | 卡牌长度 |
| HOVER_SCALE | Vector2 | (1.05, 1.05) | 悬停时的缩放比例 |
| ORIGIN_SCALE | Vector2 | (1, 1) | 原始缩放比例 |
| CARD_OVERLAP_RATIO | float | 0.1 | 卡牌层叠重叠比例 |
| CARD_SUM_MAX | int | 10 | 卡牌组合最大点数和 |
| MAX_HAND_CARD_NUM | int | 7 | 手牌最大数量 |

### 枚举
#### CardNum
普通牌数值枚举：
- ACE = 0
- TWO = 1
- THREE = 2
- FOUR = 3
- FIVE = 4
- SIX = 5
- SEVEN = 6
- EIGHT = 7
- NINE = 8
- TEN = 9

#### Suit
花色枚举：
- SPADE = 0 (黑桃)
- DIAMOND = 1 (方块)
- HEART = 2 (红心)
- CLUB = 3 (梅花)

#### Boss
Boss牌类型枚举：
- JACK = 0
- QUEEN = 1
- KING = 2

#### CardPosition
卡牌角色位置枚举：
- DECK = 0 (抽牌堆)
- HAND = 1 (手牌)
- FIELD = 2 (处理区)
- BOSS = 3 (Boss区)
- DISCARD = 4 (弃牌堆)

#### TurnStation
游戏阶段枚举：
- PLAYER = 0 (出牌阶段)
- DEFEND = 1 (防守阶段)

### 方法
#### sum(x:int, y:Card) -> int
计算卡牌点数和

**参数：**
- x: int - 累计点数
- y: Card - 要添加的卡牌

**返回值：**
- int - 累计点数加上卡牌点数

#### isValidCards(cards:Array[Card], extra:Card) -> bool
验证卡牌组合是否符合出牌规则

出牌规则如下：
1. 如果只有一张牌，则一定合法
2. 一张非A牌加若干A牌（无数值上限）
3. 多张相同数值的非A牌且总和不超过CARD_SUM_MAX（10点）

**参数：**
- cards: Array[Card] - 已选中的卡牌
- extra: Card - 要添加的卡牌

**返回值：**
- bool - 是否符合出牌规则

#### smooth_move(card:Card, pos:Vector2) -> void
平滑移动卡牌到指定位置

**参数：**
- card: Card - 要移动的卡牌
- pos: Vector2 - 目标位置

## Player类

### 信号
- finish_play - 玩家出牌完成
- finish_defend - 玩家防守完成
- cards_played(cards: Array[Card]) - 玩家出牌时发出
- cards_discarded(cards: Array[Card]) - 玩家弃牌时发出
- hand_changed(card_count: int) - 手牌数量变化时发出

### 属性
- button: Button - 确认按钮引用
- hand: Hand - 手牌管理器引用

### 方法
#### play_cards() -> void
播放卡牌（PLAYER阶段主方法）

#### add_card_to_hand(card: Card) -> void
添加卡牌到手牌

**参数：**
- card: Card - 要添加的卡牌

#### wait_for_play() -> Array[Card]
等待玩家出牌（PLAYER阶段）

**返回值：**
- Array[Card] - 玩家选择的卡牌

#### wait_for_discard(target: int) -> Array[Card]
等待玩家弃牌（DEFEND阶段）

**参数：**
- target: int - 需要弃掉的最少点数

**返回值：**
- Array[Card] - 玩家选择弃掉的卡牌

#### remove_selected_cards() -> void
移除已选中的卡牌

#### select_card(card: Card) -> void
选择指定卡牌

**参数：**
- card: Card - 要选择的卡牌

#### get_hand_card_count() -> int
获取手牌数量

**返回值：**
- int - 当前手牌数量

#### get_hand_card_sum() -> int
获取手牌点数总和

**返回值：**
- int - 当前手牌点数总和

#### can_add_card() -> bool
检查是否可以添加卡牌（手牌未达到上限）

**返回值：**
- bool - 是否可以添加卡牌

## Hand类

### 属性
- cards: Array[Card] - 手牌集合
- selected_cards: Array[Card] - 选中的卡牌集合
- discard_target: int - DEFEND阶段需要弃掉的最少点数
- station: CardData.TurnStation - 当前游戏阶段

### 方法
#### add_to_hand(card: Card) -> void
添加卡牌到手牌

**参数：**
- card: Card - 要添加的卡牌

#### remove_from_hand(card: Card) -> void
从手牌中移除卡牌

**参数：**
- card: Card - 要移除的卡牌

#### update_position() -> void
更新手牌位置

#### select_card(card: Card) -> void
选择卡牌

**参数：**
- card: Card - 要选择的卡牌

#### remove_selected() -> void
移除选中的卡牌

#### get_selected() -> Array[Card]
获取选中的卡牌

**返回值：**
- Array[Card] - 选中的卡牌集合

#### wait_for_user_play() -> Array[Card]
等待用户出牌

**返回值：**
- Array[Card] - 用户选择的卡牌

#### wait_for_user_discard(target: int) -> Array[Card]
等待用户弃牌

**参数：**
- target: int - 需要弃掉的最少点数

**返回值：**
- Array[Card] - 用户选择弃掉的卡牌

#### update_button_state() -> void
更新按钮状态

根据当前游戏阶段和选中卡牌情况更新确认按钮的可用状态：
- PLAYER阶段：只有当选中至少一张牌时按钮才可用
- DEFEND阶段：当选中牌的点数总和达到目标值时按钮才可用

根据当前游戏阶段和选中卡牌情况更新确认按钮的可用状态：
- PLAYER阶段：只有当选中至少一张牌时按钮才可用
- DEFEND阶段：当选中牌的点数总和达到目标值时按钮才可用

## Deck类

### 属性
- _cards: Array[Card] - 牌堆中的卡牌

### 方法
#### get_cards(num:int=1) -> Array[Card]
抽牌方法

**参数：**
- num: int - 要抽取的卡牌数量，默认为1

**返回值：**
- Array[Card] - 抽取的卡牌

#### draw_card(num:int=1, player: Player = null) -> void
为玩家抽牌方法（已废弃，请使用get_cards()）

**参数：**
- num: int - 要抽取的卡牌数量，默认为1
- player: Player - 目标玩家，默认为null

#### put_boss_top(card:Card) -> void
将Boss牌放回牌堆顶部

**参数：**
- card: Card - 要放回的Boss牌

#### put_cards_back(cards:Array[Card]) -> void
将牌放回牌堆

**参数：**
- cards: Array[Card] - 要放回的卡牌

#### updateStatus() -> void
更新状态显示

更新抽牌堆的计数显示和视觉状态

更新抽牌堆的计数显示和视觉状态

## Discard类

### 属性
- cards: Array[Card] - 弃牌堆中的卡牌

### 方法
#### getCards(num:int = 1) -> Array[Card]
从弃牌堆获取指定数量的牌

**参数：**
- num: int - 要获取的卡牌数量，默认为1

**返回值：**
- Array[Card] - 获取的卡牌

#### fresh_pos() -> void
更新卡牌位置（层叠显示）

按顺序排列卡牌，使每张下层的卡牌露出上面一点花色和点数，形成层叠效果

#### update_count() -> void
更新计数显示

更新区域内的卡牌计数显示，当没有卡牌时不显示计数文本

## CardField类

### 属性
- cards: Array[Card] - 处理区中的卡牌

### 方法
#### fresh_pos() -> void
更新卡牌位置（层叠显示）

按顺序排列卡牌，使每张下层的卡牌露出上面一点花色和点数，形成层叠效果

#### update_count() -> void
更新计数显示

更新区域内的卡牌计数显示，当没有卡牌时不显示计数文本

## BossDeck类

### 属性
- _cards: Array[Card] - Boss牌堆中的卡牌
- current_boss: Card - 当前激活的Boss牌
- current_boss_health: int - 当前Boss生命值
- current_boss_attack: int - 当前Boss攻击力

### 方法
#### _init_boss_cards() -> void
初始化Boss牌

#### draw_card() -> void
抽取Boss牌

#### refresh_status() -> void
刷新Boss状态显示

更新Boss的生命值和攻击力显示

更新Boss的生命值和攻击力显示



**返回值：**
- Card - 当前激活的Boss牌

## Card类

### 信号
- hover - 鼠标悬停时发出

### 属性
- hovered: bool - 是否被鼠标悬停
- selected: bool - 是否被选中
- disabled: bool - 是否被禁用
- value: int - 卡牌点数
- suit: CardData.Suit - 卡牌花色
- rank: String - 卡牌等级
- role: CardData.CardPosition - 卡牌角色位置
- back: bool - 是否显示背面
- hand_position: Vector2 - 手牌位置

### 方法
#### init_card_scene(s: CardData.Suit = CardData.Suit.SPADE, num: CardData.CardNum = CardData.CardNum.ACE, b: bool = false) -> Card
初始化普通牌场景

**参数：**
- s: CardData.Suit - 花色，默认为黑桃
- num: CardData.CardNum - 数值，默认为A
- b: bool - 是否显示背面，默认为false

**返回值：**
- Card - 初始化的普通牌

#### init_boss_scene(s: CardData.Suit = CardData.Suit.SPADE, num: CardData.Boss = CardData.Boss.JACK, b = false) -> Card
初始化Boss牌场景

**参数：**
- s: CardData.Suit - 花色，默认为黑桃
- num: CardData.Boss - Boss类型，默认为JACK
- b: bool - 是否显示背面，默认为false

**返回值：**
- Card - 初始化的Boss牌

#### flip() -> void
翻转卡牌

播放卡牌翻转动画