# 关键技术实现

## 节点初始化顺序处理

### 问题描述
在Godot中，不同节点的_ready函数执行顺序可能导致访问未初始化的节点引用。

### 解决方案
1. **信号机制**：使用自定义信号通知节点初始化完成
   ```gdscript
   # 在Player类中
   signal initialized
   
   func _ready() -> void:
       # 发出initialized信号表示Player已完全初始化
       initialized.emit()
   ```

2. **延迟初始化**：在_process函数中检查依赖是否就绪
   ```gdscript
   # 在PlayGround类中
   var is_initialized: bool = false
   
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
   ```

## 卡牌层叠显示实现

### 实现原理
通过计算每张卡牌的垂直偏移量实现层叠效果，并使用z_index控制显示层级。

### 核心代码
```gdscript
# 在CardField和Discard类中
func fresh_pos() -> void:
    # 计算层叠偏移量，每张牌露出一部分
    var overlap_offset = CardData.CARD_LENGTH * CardData.CARD_OVERLAP_RATIO
    
    for i in range(cards.size()):
        var card = cards[i]
        # 每张牌向下偏移，形成层叠效果
        var card_position = Vector2(self.position.x, self.position.y + i * overlap_offset)
        card.position = card_position
        # 设置z_index，确保后面的牌在上面
        card.z_index = i
        CardData.smooth_move(card, card_position)
```

## 出牌规则验证

### 实现思路
通过统计卡牌数值分布来验证出牌组合是否符合规则。

### 核心逻辑
```gdscript
func isValidCards(cards:Array[Card],extra:Card)->bool:
    cards = cards.duplicate()
    cards.push_back(extra)
    
    # 规则1: 出一张牌
    if cards.size() == 1:
        return true
    
    # 统计不同数值的牌的数量
    var value_counts = {}
    var ace_count = 0
    for card in cards:
        if card.value == 1:  # A的值为1
            ace_count += 1
        if card.value in value_counts:
            value_counts[card.value] += 1
        else:
            value_counts[card.value] = 1
    
    # 获取所有不同的数值
    var values = value_counts.keys()
    
    # 规则2: 一张牌（可以是A）和若干A
    if ace_count > 0 and values.size() == 2:
        # 检查非A的牌是否只有一张
        for value in values:
            if value != 1 and value_counts[value] == 1:
                return true
    
    # 规则3: 一些相同数值的牌且总数值和不能超过上界
    if values.size() == 1:
        var total_sum = cards.reduce(CardData.sum, 0)
        return total_sum <= CARD_SUM_MAX
    
    # 其他情况不合法
    return false
```

## Boss牌交互控制

### 问题描述
BossDeck中有多张Boss牌堆叠在一起，可能会导致下层牌被意外选中。

### 解决方案
通过禁用非当前Boss牌的交互功能，并设置当前Boss牌的高z_index来解决。

```gdscript
# 在BossDeck类中
func _init_boss_cards() -> void:
    var _temp: Array[Card] = []
    # 生成所有Boss牌
    for boss_type in range(3):
        for suit in range(4):
            var card = Card.init_boss_scene(suit, boss_type)
            card.role = CardData.CardPosition.BOSS
            card.position = self.position
            _temp.push_back(card)
    _temp.shuffle()
    _cards = _temp
    draw_card()

func draw_card() -> void:
    if _cards.is_empty():
        return
    current_boss = _cards.pop_back() as Card
    # 启用当前Boss牌的交互功能
    current_boss.disabled = false
    # 设置当前Boss牌的z_index为最高值
    current_boss.z_index = 100
```

## 计数显示优化

### 问题描述
当区域没有卡牌时，不显示"0"文本以保持界面简洁。

### 实现方案
通过检查卡牌数量来决定是否显示计数标签。

```gdscript
# 在各区域类中
func update_count():
    # 更新计数显示，没有卡牌时不显示
    if count_label:
        if cards.size() > 0:  # 或 _cards.size() > 0 对于Deck
            count_label.text = str(cards.size())
            count_label.show()
        else:
            count_label.hide()
```

## 平滑动画实现

### 实现原理
使用Godot的Tween系统实现卡牌移动的平滑动画效果。

### 核心代码
```gdscript
# 在CardData类中
func smooth_move(card:Card,pos:Vector2):
    var tween = get_tree().create_tween()
    tween.tween_property(card,"position",pos,0.1)
```

## 游戏阶段管理

### 实现原理
通过TurnStation枚举和station属性管理不同的游戏阶段。

### 核心逻辑
```gdscript
# 在Hand类中
var station: CardData.TurnStation:
    set(st):
        if not st == station:
            station = st
            update_button_state()

# 根据不同阶段更新按钮状态
func update_button_state() -> void:
    if station == CardData.TurnStation.DEFEND:
        # DEFEND阶段逻辑
    else:
        # PLAYER阶段逻辑
```

## 物理交互系统

### 实现原理
使用Godot的物理查询系统实现鼠标与卡牌的交互。

### 核心代码
```gdscript
# 在CardManager类中
func prepare_card() -> Card:
    var space_state = get_world_2d().direct_space_state
    var paras = PhysicsPointQueryParameters2D.new()
    paras.position = get_global_mouse_position()
    paras.collision_mask = CardData.CARD_COLLISION_MASK
    paras.collide_with_areas = true
    var cards = space_state.intersect_point(paras)
    if cards.size() > 0:
        return _get_highest(cards)
    return null

func _get_highest(cards) -> Card:
    var res = null
    for c in cards:
        var card = c.collider.get_parent() as Card
        if !res or card.z_index > res.z_index:
            res = card
    return res
```

这些关键技术实现确保了游戏的流畅运行和良好的用户体验。