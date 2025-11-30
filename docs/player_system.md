# 玩家系统

## 系统组成

玩家系统由两个核心组件构成：

### 1. Player类
- **功能**：封装玩家相关的操作和状态
- **职责**：
  - 管理玩家手牌
  - 处理玩家输入
  - 协调游戏阶段转换
  - 提供玩家状态查询接口

### 2. Hand类
- **功能**：管理玩家手牌的显示和操作
- **职责**：
  - 维护手牌集合
  - 处理卡牌选择逻辑
  - 更新手牌显示位置
  - 验证出牌合法性

## 游戏阶段

玩家系统支持两种游戏阶段：

### PLAYER阶段
- **描述**：玩家选择并出牌攻击Boss
- **操作**：
  - 选择符合规则的卡牌组合
  - 点击确认按钮提交出牌
- **提示文本**："请选择要出的牌"

### DEFEND阶段
- **描述**：Boss攻击玩家，玩家需要弃牌防守
- **操作**：
  - 根据Boss攻击力选择足够的牌弃掉
  - 可选择性弃牌或直接确认（当Boss攻击力为0时）
- **提示文本**：
  - "请弃掉至少 X 点数的牌"（当需要强制弃牌时）
  - "可选择弃牌或直接确认"（当可选弃牌时）

## 核心方法

### Player类
```gdscript
# 播放卡牌（PLAYER阶段主方法）
func play_cards() -> void

# 添加卡牌到手牌
func add_card_to_hand(card: Card) -> void

# 等待玩家出牌（PLAYER阶段）
func wait_for_play() -> Array[Card]

# 等待玩家弃牌（DEFEND阶段）
func wait_for_discard(target: int) -> Array[Card]

# 移除已选中的卡牌
func remove_selected_cards() -> void

# 选择指定卡牌
func select_card(card: Card) -> void

# 获取手牌数量
func get_hand_card_count() -> int

# 获取手牌点数总和
func get_hand_card_sum() -> int

# 检查是否可以添加卡牌
func can_add_card() -> bool

# 更新状态标签文本
func _update_status_label(discard_target: int = 0) -> void
```

### Hand类
```gdscript
# 添加卡牌到手牌
func add_to_hand(card: Card) -> void

# 从手牌中移除卡牌
func remove_from_hand(card: Card) -> void

# 更新手牌位置
func update_position() -> void

# 选择卡牌
func select_card(card: Card) -> void

# 移除选中的卡牌
func remove_selected() -> void

# 获取选中的卡牌
func get_selected() -> Array[Card]

# 等待用户出牌
func wait_for_user_play() -> Array[Card]

# 等待用户弃牌
func wait_for_user_discard(target: int) -> Array[Card]

# 更新按钮状态
func update_button_state() -> void
```

## 状态管理

### 手牌状态
- **card_size**：当前手牌数量
- **card_sum**：当前手牌点数总和
- **selected_cards**：当前选中的卡牌集合

### 游戏阶段状态
- **station**：当前游戏阶段（PLAYER/DEFEND）
- **discard_target**：DEFEND阶段需要弃掉的最少点数

## 交互逻辑

### 卡牌选择
1. 玩家点击卡牌进行选择/取消选择
2. 系统实时验证选择的卡牌组合是否符合出牌规则
3. 不符合规则的卡牌会被禁用（disabled状态）

### 按钮控制
确认按钮的状态根据以下规则动态更新：
- **PLAYER阶段**：当选中至少一张卡牌时启用
- **DEFEND阶段**：
  - 当discard_target > 0时：当选中卡牌点数总和≥discard_target时启用
  - 当discard_target = 0时：始终启用

## 胜负判定

### 判负条件（单人模式）
当玩家在PLAYER阶段用完所有手牌后，系统检测到手牌数量≤0时判定玩家失败。

### 判胜条件
当所有Boss牌都被击败且BossDeck中没有剩余Boss牌时判定玩家胜利。

## 扩展性考虑

当前实现为单人模式规则，未来扩展多人模式时可能需要调整：
- 胜负判定逻辑
- 手牌管理机制
- 游戏阶段转换逻辑