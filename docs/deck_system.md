# 牌堆系统

## 系统组成

牌堆系统由四个主要区域组成：

### 1. 抽牌堆 (Deck)
- **功能**：存放未使用的普通牌
- **初始化**：生成4种花色×10个数值的40张普通牌并洗牌
- **操作**：提供抽牌功能供玩家获取手牌

### 2. 弃牌堆 (Discard)
- **功能**：存放玩家弃掉的牌
- **显示**：卡牌以10%重叠比例层叠显示
- **操作**：提供回收牌功能供特定花色效果使用

### 3. 处理区 (CardField)
- **功能**：存放玩家出过的牌
- **显示**：卡牌以10%重叠比例层叠显示
- **操作**：每回合结束后清空并移至弃牌堆

### 4. Boss区 (BossDeck)
- **功能**：管理Boss牌的生成和切换
- **初始化**：生成3种类型×4种花色的12张Boss牌并洗牌
- **操作**：按顺序激活Boss牌，当前Boss死亡后切换到下一张

## 显示特性

### 层叠显示
所有区域（处理区和弃牌区）的卡牌都以层叠方式显示：
- 重叠比例：10%（通过CARD_OVERLAP_RATIO常量控制）
- 显示方向：纵向层叠
- 层次关系：后添加的牌显示在上方

### 计数显示
每个区域上方显示当前卡牌数量：
- 有卡牌时：显示具体数量
- 无卡牌时：隐藏计数标签，不显示"0"

## 核心方法

### Deck类
```gdscript
# 抽牌方法
func get_cards(num:int=1) -> Array[Card]

# 为玩家抽牌方法
func draw_card(num:int=1, player: Player = null) -> void

# 将Boss牌放回牌堆顶部
func put_boss_top(card:Card) -> void

# 将牌放回牌堆
func put_cards_back(cards:Array[Card]) -> void

# 更新状态显示
func updateStatus() -> void
```

### Discard类
```gdscript
# 从弃牌堆获取指定数量的牌
func getCards(num:int = 1) -> Array[Card]

# 更新卡牌位置（层叠显示）
func fresh_pos() -> void

# 更新计数显示
func update_count() -> void
```

### CardField类
```gdscript
# 更新卡牌位置（层叠显示）
func fresh_pos() -> void

# 更新计数显示
func update_count() -> void
```

### BossDeck类
```gdscript
# 初始化Boss牌
func _init_boss_cards() -> void

# 抽取Boss牌
func draw_card() -> void

# 刷新Boss状态显示
func refresh_status() -> void

```

## 交互控制

### Boss牌交互
为避免下层Boss牌被意外选中：
- 非当前Boss牌设置为disabled状态
- 只有当前激活的Boss牌可以响应鼠标事件
- 当前Boss牌的z_index设置为较高值确保显示在最上层

## 状态同步

所有区域的计数显示会在以下情况下更新：
- 卡牌数量发生变化时
- 卡牌位置需要刷新时
- 游戏状态发生改变时

通过updateStatus、fresh_pos、update_count等方法实现状态同步。