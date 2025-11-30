# 卡牌系统

## 卡牌类型

### 普通牌
普通牌包含四种花色和10个数值：

**花色：**
- SPADE (黑桃)
- DIAMOND (方块)
- HEART (红心)
- CLUB (梅花)

**数值：**
- ACE (A) = 1
- TWO (2) = 2
- THREE (3) = 3
- FOUR (4) = 4
- FIVE (5) = 5
- SIX (6) = 6
- SEVEN (7) = 7
- EIGHT (8) = 8
- NINE (9) = 9
- TEN (10) = 10

### Boss牌
Boss牌包含三种类型和四种花色：

**类型：**
- JACK (J) = 10
- QUEEN (Q) = 15
- KING (K) = 20

**花色：**
- SPADE (黑桃)
- DIAMOND (方块)
- HEART (红心)
- CLUB (梅花)

## 出牌规则

### isValidCards函数实现

卡牌有效性检查函数实现了三种出牌规则：

```gdscript
func isValidCards(cards:Array[Card],extra:Card)->bool:
    cards = cards.duplicate()
    cards.push_back(extra)
    
    # 规则1: 出一张牌
    if cards.size() == 1:
        return true
    
    # 规则2: 出一张牌（可以是A）和若干A
    # 规则3: 出一些相同数值的牌且总数值和不能超过上界
    
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
    # 如果有A，且除了A之外只有一种其他数值，且这种数值的牌只有一张
    if ace_count > 0 and values.size() == 2:  # 有两种数值：A和其他一种
        # 检查非A的牌是否只有一张
        for value in values:
            if value != 1 and value_counts[value] == 1:
                return true
    
    # 规则3: 一些相同数值的牌且总数值和不能超过上界
    # 如果只有一种数值（可以是A或非A），则检查总和是否超过上限
    if values.size() == 1:
        var total_sum = cards.reduce(CardData.sum, 0)
        return total_sum <= CARD_SUM_MAX
    
    # 其他情况不合法
    return false
```

### 合法出牌示例

1. **规则1 - 单张牌**：
   - [5] ✓

2. **规则2 - 一张牌加若干A**：
   - [3, A, A] ✓
   - [A, A, A] ✓

3. **规则3 - 相同数值牌**：
   - [3, 3, 3] ✓ (如果总和≤10)
   - [A, A, A] ✓ (如果总和≤10)

### 非法出牌示例

1. [3, 5] ✗ (两种不同数值且没有A)
2. [A, 3, 5] ✗ (三种不同数值)
3. [3, 3, 3, 3, 3] ✗ (如果总和>10)

## 花色效果

不同花色的牌具有不同的特殊效果：

- **CLUB (梅花)**：伤害翻倍
- **HEART (红心)**：从弃牌堆回收牌
- **DIAMOND (方块)**：抽牌
- **SPADE (黑桃)**：降低Boss攻击力

## 卡牌状态

### 角色状态 (role)
- DECK：在抽牌堆中
- HAND：在玩家手中
- FIELD：在处理区
- BOSS：作为Boss牌
- DISCARD：在弃牌堆中

### 显示状态
- hovered：是否被鼠标悬停
- selected：是否被选中
- disabled：是否被禁用
- back：是否显示背面

## 卡牌交互

### 鼠标交互
- 鼠标悬停：高亮显示卡牌
- 鼠标点击：选择/取消选择卡牌

### 物理交互
- 通过Area2D和CollisionShape2D实现碰撞检测
- 使用PhysicsPointQueryParameters2D进行点查询