# 架构设计

## 整体架构

Regicide项目采用Godot引擎的节点树结构进行组织，主要分为以下几个模块：

### 场景结构
```
GameScene (Node2D)
├── CardManager (Node2D)
├── Deck (Node2D)
├── InputManager (Node2D)
├── PlayGround (Node2D)
├── Discard (Node2D)
├── CardField (Node2D)
├── BossDeck (Node2D)
└── Players (Node2D)
    └── Player (Node2D)
        ├── Hand (Node2D)
        └── Button (Button)
```

### 核心类设计

#### CardManager
负责卡牌的全局管理，包括卡牌的创建、销毁和交互处理。

#### PlayGround
游戏主逻辑控制器，负责游戏流程的推进和各模块间的协调。

#### Player
玩家类，封装玩家相关的操作和状态。

#### Hand
手牌管理类，负责手牌的显示、选择和操作。

#### Deck
抽牌堆类，管理未使用的普通卡牌。

#### Discard
弃牌堆类，管理玩家弃掉的卡牌。

#### CardField
处理区类，管理玩家出过的卡牌。

#### BossDeck
Boss牌堆类，管理Boss卡牌的生成和切换。

#### Card
卡牌基类，所有卡牌的父类，包含卡牌的基本属性和行为。

#### CardData
卡牌数据类，包含游戏规则和常量定义。

## 数据流设计

### 初始化流程
1. GameScene加载各组件
2. Player初始化手牌
3. BossDeck生成Boss牌并激活第一张
4. Deck生成普通牌并洗牌

### 游戏循环
1. Player阶段：玩家选择并出牌
2. 卡牌效果处理：根据出牌计算对Boss的伤害
3. Boss死亡检查：如果Boss生命值≤0，切换到下一张Boss
4. Boss攻击阶段：Boss对玩家造成伤害，玩家需要弃牌防守
5. 循环回到步骤1

## 模块间通信

### 信号机制
- Player通过信号通知PlayGround玩家操作完成
- Card通过信号通知CardManager鼠标悬停事件
- 各区域通过信号与PlayGround通信状态变化

### 直接调用
- PlayGround直接调用各模块的方法来推进游戏流程
- 各模块通过节点路径访问其他模块的公共方法

## 设计模式

### 观察者模式
通过Godot的信号机制实现模块间的解耦，各模块通过订阅信号来响应事件。

### 单例模式
CardData作为全局数据类，通过autoload机制实现单例模式。

### 状态模式
Hand类通过station属性管理不同的操作状态（PLAYER/DEFEND）。