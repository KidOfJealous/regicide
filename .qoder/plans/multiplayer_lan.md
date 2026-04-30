# Regicide 局域网多人联机实现计划

## 概述
实现基于Godot 4 ENetMultiplayerPeer的局域网多人联机功能，包含完整大厅系统和隐藏手牌机制。

## 技术架构

### 网络框架选择
- 使用 **ENetMultiplayerPeer** (Godot 4内置，专为游戏设计)
- 主机作为服务器，其他玩家作为客户端连接
- 使用RPC进行状态同步

### 核心组件

```
scripts/
├── network_manager.gd      # 网络管理器（新增）
├── lobby.gd                # 大厅界面逻辑（新增）
├── game_state.gd           # 游戏状态同步（新增）
└── play_ground.gd          # 修改：添加多人轮换支持
scenes/
├── lobby.tscn              # 大厅场景（新增）
├── player_slot.tscn        # 大厅玩家位置显示（新增）
```

## 实现任务

### Task 1: 创建网络管理器 (network_manager.gd)
- 初始化ENetMultiplayerPeer
- 实现主机创建房间（指定端口）
- 实现局域网房间广播发现
- 实现客户端连接/断开处理
- 管理玩家列表（ID、名称、状态）

### Task 2: 创建大厅场景和逻辑
- 大厅UI：房间列表、创建房间按钮、加入按钮
- 创建房间界面：设置玩家数量上限(2-4人)、房间名称
- 等待界面：显示已加入玩家、开始游戏按钮
- 房间发现：局域网UDP广播发现可用房间

### Task 3: 游戏状态同步系统
- 同步内容：
  - Boss状态（生命值、攻击力、免疫状态）
  - 牌堆/弃牌堆数量
  - 当前回合玩家索引
  - 处理区卡牌
- **不同步**：各玩家的具体手牌内容（仅同步手牌数量）
- 使用 @rpc("any_peer", "call_local") 进行同步调用

### Task 4: 多人轮换机制
- 修改play_ground.gd支持多玩家轮换
- 当前玩家出牌，其他玩家等待
- Boss攻击时按顺序弃牌防御
- Joker打出后选择下一位玩家

### Task 5: 分发手牌逻辑
- 主机统一管理牌堆和发牌
- 每位玩家只看到自己的手牌内容
- 其他玩家手牌显示为背面+数量

### Task 6: 回合控制同步
- 当前玩家操作权限控制
- 出牌结果广播通知所有客户端
- 防御阶段轮换弃牌

### Task 7: UI增强
- 显示当前回合玩家指示
- 显示其他玩家手牌数量
- 网络状态指示（连接/断开）
- 等待其他玩家操作的提示

## 数据同步设计

### 需要同步的状态
```gdscript
# 广播给所有客户端
sync_boss_state(health, attack, immune_cancelled)
sync_deck_count(count)
sync_discard_count(count)
sync_current_player(player_id)
sync_cards_played(cards_data)  # 出牌结果
sync_game_result(is_win)
```

### 不需要同步（本地管理）
```gdscript
# 各玩家本地管理自己的手牌
# 主机通过RPC单独发给对应玩家
rpc_send_hand_cards(player_id, cards_data)
```

## 文件修改清单

### 新增文件
1. `scripts/network_manager.gd` - 网络管理核心
2. `scripts/lobby.gd` - 大厅界面逻辑  
3. `scripts/game_state.gd` - 游戏状态同步
4. `scenes/lobby.tscn` - 大厅场景
5. `scenes/player_slot.tscn` - 玩家位置显示组件

### 修改文件
1. `scripts/play_ground.gd` - 多人轮换、网络同步
2. `scripts/player.gd` - 添加peer_id属性
3. `scripts/hand.gd` - 支持隐藏其他玩家手牌
4. `scenes/game_scene.tscn` - 添加NetworkManager节点
5. `project.godot` - 添加lobby为启动场景

## 实现优先级

1. **P0 核心**：网络管理器 + 基本连接
2. **P0 核心**：大厅系统基础（创建/加入房间）
3. **P1 重要**：游戏状态同步 + 手牌分发
4. **P1 重要**：多人轮换机制
5. **P2 增强**：局域网房间发现广播
6. **P2 增强**：UI细节优化