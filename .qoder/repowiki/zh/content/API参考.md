# API参考

<cite>
**本文档中引用的文件**
- [card_data.gd](file://scripts/card_data.gd)
- [card.gd](file://scripts/card.gd)
- [play_ground.gd](file://scripts/play_ground.gd)
</cite>

## 目录
1. [简介](#简介)
2. [CardData类](#carddata类)
3. [Card类](#card类)
4. [PlayGround类](#playground类)
5. [使用示例](#使用示例)
6. [线程安全性注意事项](#线程安全性注意事项)

## 简介

本文档提供了Regicide游戏项目中核心类的完整API参考。主要涵盖CardData、Card和PlayGround三个脚本的公共接口，帮助开发者快速查阅接口规范，减少错误调用。

## CardData类

CardData是一个全局单例节点，提供游戏中的常量定义、枚举值和工具函数。

### 枚举类型

#### CardNum（牌数值）
| 枚举值 | 取值范围 | 描述 |
|--------|----------|------|
| ACE | 0 | A（1点） |
| TWO | 1 | 2 |
| TREE | 2 | 3 |
| FOUR | 3 | 4 |
| FIVE | 4 | 5 |
| SIX | 5 | 6 |
| SEVEN | 6 | 7 |
| EIGHT | 7 | 8 |
| NINE | 8 | 9 |
| TEN | 9 | 10 |

#### Suit（花色）
| 枚举值 | 数值 | 描述 |
|--------|------|------|
| SPADE | 0 | 黑桃♠ |
| DIAMOND | 1 | 方块♦ |
| HEART | 2 | 红心♥ |
| CLUB | 3 | 梅花♣ |

#### Boss（Boss牌）
| 枚举值 | 数值 | 点数 | 描述 |
|--------|------|------|------|
| JACK | 0 | 10 | 杰克 |
| QUEEN | 1 | 15 | 皇后 |
| KING | 2 | 20 | 国王 |

#### Joker（大小王）
| 枚举值 | 描述 |
|--------|------|
| LITTE_JOKER | 小王 |
| BIG_JOKER | 大王 |

#### CardPosition（卡片位置）
| 枚举值 | 数值 | 描述 |
|--------|------|------|
| DECK | 0 | 牌堆 |
| HAND | 1 | 手牌 |
| FIELD | 2 | 场地 |
| BOSS | 3 | Boss |
| DISCARD | 4 | 弃牌堆 |

#### TurnStation（回合阶段）
| 枚举值 | 数值 | 描述 |
|--------|------|------|
| PLAYER | 0 | 玩家回合 |
| DEFEND | 1 | 防御阶段 |

### 常量定义

| 常量名 | 类型 | 值 | 描述 |
|--------|------|----|----- |
| CARD_WIDTH | float | 73.2 | 卡片宽度 |
| CARD_LENGTH | float | 102.4 | 卡片长度 |
| HOVER_SCALE | Vector2 | (1.05,1.05) | 悬停缩放比例 |
| ORIGIN_SCALE | Vector2 | (1,1) | 原始缩放比例 |
| MAX_HAND_CARD_NUM | int | 7 | 手牌最大数量 |
| CARD_SUM_MAX | int | 10 | 卡片总和最大值 |

### 碰撞掩码常量

| 常量名 | 数值 | 用途 |
|--------|------|------|
| CARD_COLLISION_MASK | 1 | 卡片碰撞掩码 |
| CARD_SLOT_COLLISION_MASK | 2 | 卡片槽碰撞掩码 |
| DECK_COLLISION_MASK | 4 | 牌堆碰撞掩码 |
| BOSS_COLLISION_MASK | 5 | Boss碰撞掩码 |
| FIELD_COLLISION_MASK | 6 | 场地标记碰撞掩码 |
| DISCARD_COLLISION_MASK | 7 | 弃牌堆碰撞掩码 |

### 工具函数

#### sum(x:int, y:Card) → int
计算整数与卡片值的和。

**参数：**
- `x`: 整数值
- `y`: 卡片对象

**返回值：** 整数与卡片值的和

**示例：**
```gdscript
var total = CardData.sum(5, card_instance)
```

#### isValidCards(cards:Array[Card], extra:Card) → bool
验证卡片组合是否有效。

**参数：**
- `cards`: 卡片数组
- `extra`: 额外卡片

**返回值：** 布尔值，表示卡片组合是否有效

**验证规则：**
1. 单张卡片始终有效
2. 多张卡片必须具有相同的值或都是1点（A）
3. 总和不能超过CARD_SUM_MAX（10）

**示例：**
```gdscript
var isValid = CardData.isValidCards([card1, card2], extra_card)
```

#### smooth_move(card:Card, pos:Vector2)
平滑移动卡片到指定位置。

**参数：**
- `card`: 要移动的卡片对象
- `pos`: 目标位置向量

**副作用：** 创建一个Tween动画，将卡片移动到指定位置

**示例：**
```gdscript
CardData.smooth_move(card_instance, target_position)
```

**节来源**
- [card_data.gd](file://scripts/card_data.gd#L1-L72)

## Card类

Card类代表游戏中的单张卡片，继承自Node2D，提供卡片的基本属性和行为。

### 属性

#### 基础属性

| 属性名 | 类型 | 访问权限 | 描述 |
|--------|------|----------|------|
| value | int | 只读 | 卡片数值（基于rank计算） |
| suit | CardData.Suit | 只读 | 花色 |
| rank | String | 只读 | 卡片名称（如"ace", "two"等） |
| role | CardData.CardPosition | 只读 | 当前位置 |
| back | bool | 读写 | 是否显示背面 |

#### 视觉状态属性

| 属性名 | 类型 | 访问权限 | 描述 |
|--------|------|----------|------|
| hovered | bool | 读写 | 是否悬停状态 |
| selected | bool | 读写 | 是否选中状态 |
| disabled | bool | 读写 | 是否禁用状态 |

#### 位置相关属性

| 属性名 | 类型 | 访问权限 | 描述 |
|--------|------|----------|------|
| hand_position | Vector2 | 只读 | 手牌位置 |

### 信号

| 信号名 | 参数 | 描述 |
|--------|------|------|
| hover | self, is_hovered | 卡片悬停状态改变时发出 |

### 静态方法

#### init_card_scene(s:CardData.Suit, num:CardData.CardNum, b:bool) → Card
初始化普通卡片场景实例。

**参数：**
- `s`: 花色（CardData.Suit）
- `num`: 数值（CardData.CardNum）
- `b`: 是否显示背面

**返回值：** 初始化完成的Card实例

**使用示例：**
```gdscript
var card = Card.init_card_scene(CardData.Suit.SPADE, CardData.CardNum.ACE, false)
```

#### init_boss_scene(s:CardData.Suit, num:CardData.Boss, b:bool) → Card
初始化Boss卡片场景实例。

**参数：**
- `s`: 花色（CardData.Suit）
- `num`: Boss类型（CardData.Boss）
- `b`: 是否显示背面

**返回值：** 初始化完成的Card实例

**使用示例：**
```gdscript
var boss_card = Card.init_boss_scene(CardData.Suit.HEART, CardData.Boss.QUEEN, false)
```

### 实例方法

#### flip()
翻转卡片动画。

**副作用：** 播放卡片翻转动画

**使用示例：**
```gdscript
card.flip()
```

#### _ready()
节点准备就绪时自动调用。

**自动执行：**
- 连接到父节点的connect_card方法
- 设置初始z_index为1

**节来源**
- [card.gd](file://scripts/card.gd#L1-L67)

## PlayGround类

PlayGround类是游戏的主要控制器，管理游戏流程、回合处理和游戏逻辑。

### 属性

| 属性名 | 类型 | 描述 |
|--------|------|------|
| end | bool | 游戏结束标志 |
| station | CardData.TurnStation | 当前回合阶段 |

### 主要方法

#### start_game()
开始游戏。

**调用时机：** 游戏初始化时自动调用

**功能：**
1. 抽取第一张Boss牌
2. 发给玩家MAX_HAND_CARD_NUM张牌

**副作用：** 初始化游戏状态

#### end_turn()
结束当前回合。

**调用时机：** 玩家主动结束回合时

**功能：**
1. 获取玩家选中的卡片
2. 移除选中的卡片
3. 应用卡片效果

**副作用：** 切换到防御阶段或处理Boss攻击

#### card_effect(cards: Array[Card])
应用卡片效果。

**参数：**
- `cards`: 要应用效果的卡片数组

**功能：**
1. 获取当前Boss牌
2. 计算卡片总值
3. 根据花色应用特殊效果：
   - 梅花：伤害翻倍
   - 红心：恢复牌堆
   - 方块：抽牌
   - 黑桃：直接伤害Boss
4. 更新游戏状态

**副作用：**
- 添加卡片到场地
- 减少Boss生命值
- 检查游戏胜负

#### add_to_field(cards: Array[Card])
将卡片添加到场地。

**参数：**
- `cards`: 要添加的卡片数组

**副作用：**
- 更新场地卡片列表
- 重新排列场地卡片位置

#### add_to_discard(cards: Array[Card])
将卡片添加到弃牌堆。

**参数：**
- `cards`: 要添加的卡片数组

**副作用：**
- 更新弃牌堆卡片列表
- 重新排列弃牌堆卡片位置

#### boss_attack()
处理Boss攻击。

**功能：**
1. 切换到DEFEND回合阶段
2. 检查玩家是否有足够的防御能力
3. 如果防御不足，游戏失败
4. 否则等待玩家选择防御卡片

**副作用：**
- 可能导致游戏结束

#### win()
标记游戏胜利。

**副作用：**
- 设置end为true
- 输出"你赢了"消息

#### lose()
标记游戏失败。

**副作用：**
- 设置end为true
- 输出"你输了"消息

#### _restore_deck(num: int)
从弃牌堆恢复卡片到牌堆。

**参数：**
- `num`: 要恢复的卡片数量

**副作用：**
- 从弃牌堆取出指定数量的卡片
- 放回牌堆

#### boss_to_deck(boss: Card, mercy: bool)
将Boss牌放入牌堆。

**参数：**
- `boss`: Boss卡片
- `mercy`: 是否给予怜悯（可选，默认false）

**功能：**
- 如果有怜悯，将Boss牌放在牌堆顶部
- 否则将Boss牌放入弃牌堆

**节来源**
- [play_ground.gd](file://scripts/play_ground.gd#L1-L96)

## 使用示例

### 创建和配置卡片

```gdscript
# 创建一张黑桃A
var ace_of_spades = Card.init_card_scene(
    CardData.Suit.SPADE, 
    CardData.CardNum.ACE, 
    false
)

# 创建一张Boss牌
var queen_card = Card.init_boss_scene(
    CardData.Suit.HEART,
    CardData.Boss.QUEEN,
    false
)

# 设置卡片位置
ace_of_spades.position = Vector2(100, 100)
queen_card.position = Vector2(200, 100)
```

### 使用CardData常量

```gdscript
# 访问全局常量
print("卡片宽度:", CardData.CARD_WIDTH)
print("最大手牌数:", CardData.MAX_HAND_CARD_NUM)

# 使用枚举值
var heart_suit = CardData.Suit.HEART
var ten_value = CardData.CardNum.TEN

# 验证卡片组合
var cards = [card1, card2]
var isValid = CardData.isValidCards(cards, extra_card)
```

### 控制游戏流程

```gdscript
# 获取PlayGround实例
var play_ground = get_node("/root/PlayGround")

# 开始游戏
play_ground.start_game()

# 结束回合
play_ground.end_turn()

# 应用卡片效果
var selected_cards = [card1, card2]
play_ground.card_effect(selected_cards)

# 检查游戏状态
if play_ground.end:
    if play_ground.station == CardData.TurnStation.PLAYER:
        print("游戏胜利！")
    else:
        print("游戏失败！")
```

### 卡片交互

```gdscript
# 监听卡片悬停事件
func _ready():
    card.connect("hover", self, "_on_card_hover")

func _on_card_hover(card, is_hovered):
    if is_hovered:
        print("卡片悬停:", card.rank)
    else:
        print("卡片离开悬停:", card.rank)

# 平滑移动卡片
CardData.smooth_move(card_instance, target_position)
```

## 线程安全性注意事项

### CardData单例特性

CardData是一个全局单例节点，具有以下特点：

1. **线程安全访问**：由于Godot的单线程架构，CardData的属性和方法在主线程中是安全的
2. **全局状态共享**：所有组件通过CardData访问相同的全局状态
3. **生命周期管理**：由Godot引擎自动管理，无需手动创建或销毁

### 使用建议

1. **避免直接修改单例状态**：尽量通过提供的方法操作CardData状态
2. **注意并发访问**：虽然Godot是单线程的，但在复杂场景中仍要注意状态一致性
3. **信号连接**：确保正确断开不需要的信号连接，避免内存泄漏

### 最佳实践

```gdscript
# 推荐：通过方法访问CardData
var max_cards = CardData.MAX_HAND_CARD_NUM
var is_valid = CardData.isValidCards(cards, extra)

# 不推荐：直接访问可能变化的状态
# var current_value = CardData.some_variable  # 可能过时
```

### 错误处理

```gdscript
# 检查CardData可用性
if Engine.has_singleton("CardData"):
    var card_data = Engine.get_singleton("CardData")
else:
    print("CardData单例不可用")
```

通过遵循这些指导原则，可以确保在多线程环境下的安全性和稳定性，同时充分利用CardData提供的全局功能。