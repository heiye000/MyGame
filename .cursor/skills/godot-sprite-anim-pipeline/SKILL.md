---
name: godot-sprite-anim-pipeline
description: Standard pipeline that turns a sprite-sheet PNG plus a structured manifest into multi-directional AnimationPlayer clips, an AnimationTree state machine, and LimboHSM mode-driver code, executed through the godot-mcp execute_editor_script tool. Use when the user provides a sprite sheet and asks to generate directional idle/walk/attack/roll animations, wire up an AnimationTree, or run the "动画流水线 / sprite animation pipeline / anim pipeline" workflow.
disable-model-invocation: true
---

# Godot Sprite Animation Pipeline

把「精灵图 PNG -> 多方向 AnimationPlayer 动画 -> AnimationTree 动画状态机 -> LimboHSM 行动模式驱动」固化为固定流程。执行手段是 `user-godot_mcp` 的 `execute_editor_script`（在编辑器里跑完整 GDScript，数据驱动地建动画，无需手工连线）。

## 目标架构（对齐 `demo1/scenes/player/`）

职责分层，便于扩展新行动模式（探索、对话、载具等）：

```
Player (Node2D)
├── CharacterBody2D / Sprite2D          # 物理与精灵
├── AnimationPlayer                    # 切帧动画库
├── AnimationTree : PlayerAnimationTree
│     # 仅负责：输入查询（供 transition 表达式）+ 动画图
│     BlendTree -> StateMachine -> {
│       MoveMachine{idle, run},
│       AttackMachine{attack_L},
│       RollMachine{roll}
│     }
│     每个状态 = BlendSpace2D（方向靠 blend 坐标）
└── LimboHSM
      └── NormalBattle : LimboState     # 行动模式：读 AnimationTree 当前节点，驱动移动/攻击/翻滚
```

| 层 | 职责 | 不负责 |
|----|------|--------|
| `player.gd` | 持有引用、初始化 LimboHSM、共享数据（`move_speed`/`last_direction`） | 不写 `_physics_process` 行动逻辑 |
| `player_animation_tree.gd` | `get_move_direction()` / `is_attacking()` / `is_rolling()` 等，供 AnimationTree transition 表达式调用 | 不驱动位移 |
| Limbo 模式态（如 `normal_battle.gd`） | `match state_playback` 分发、写 `blend_position`、`move_and_slide` | 不直接读 GUIDE（经 AnimationTree） |
| AnimationTree 图 | idle↔run、Move↔Attack/Roll 等动画切换 | 不决定「当前是战斗还是对话」 |

> **扩展新行动模式**：在 `LimboHSM` 下新增 `LimboState`（如 `Explore`），在 `player.gd` 里注册 transition；AnimationTree 可复用或按模式换树。流水线 Step3 默认生成/修补 `NormalBattle` 这一种模式。

## 前置条件

1. 目标场景已在 Godot 编辑器中**打开**（脚本用 `EditorInterface.get_edited_scene_root()`）。
2. 场景节点（相对 Player 根）：
   - `CharacterBody2D/Sprite2D`（已设 `texture` 与 `hframes/vframes`）
   - `AnimationPlayer`、`AnimationTree`（根直属）
   - `LimboHSM` + 至少一个模式态（如 `LimboHSM/NormalBattle`）——缺则用 godot-mcp `create_node` 补建
3. 用户已按 [manifest.schema.md](manifest.schema.md) 提供结构化清单。

## 工作流

复制此清单并逐步跟踪：

```
Pipeline Progress:
- [ ] Step 0: 校验 manifest 与场景前置条件
- [ ] Step 1: 生成 AnimationPlayer 动画
- [ ] Step 2: 生成 AnimationTree 状态机
- [ ] Step 3: 生成/修补驱动代码（player + AnimationTree 脚本 + Limbo 模式态）
- [ ] Step 4: 校验
```

### Step 0 — 校验输入
- 确认 manifest 每个 `action.frames` 的方向集合能被「显式帧 + mirror 派生」覆盖 `directions`。
- 确认帧索引都落在 `hframes * vframes` 范围内。
- 用 `get_scene_tree` 确认必需节点存在。缺失则停下让用户补齐，或用 `create_node` 补建 `AnimationTree` / `LimboHSM` / 模式态。

### Step 1 — 生成 AnimationPlayer 动画
读取 [scripts/build_animations.gd](scripts/build_animations.gd)，把顶部 `MANIFEST` 用用户清单填好，整段作为 `execute_editor_script` 的 `code` 执行。它遍历 `动作 × 方向`，为每个动画建 `Sprite2D:frame` 值轨道（离散更新，`time = i/fps`），mirror 派生方向额外加 `flip_h` 轨道，全部塞进默认 `AnimationLibrary` 并存盘。
- **注意**：`sprite_node` 须为相对 Player 根的路径，当前为 `CharacterBody2D/Sprite2D`。
- 期望输出：`OK 动画数=<N>`，其中 `N = 1(RESET) + Σ(动作方向数)`。

### Step 2 — 生成 AnimationTree 状态机
读取 [scripts/build_animation_tree.gd](scripts/build_animation_tree.gd)，填好顶部 `CFG`（方向 blend 坐标、`machines`、transition 表达式），整段作为 `execute_editor_script` 的 `code` 执行。
- 拓扑：`BlendTree -> StateMachine -> { MoveMachine, AttackMachine, RollMachine, ... }`（由 `CFG.machines` 数据驱动）。
- `advance_expression_base_node = NodePath(".")`（表达式在 **AnimationTree / PlayerAnimationTree** 上求值）。
- 设置 `active=true`、`anim_player`，并初始化各 `blend_position`。

### Step 3 — 生成/修补驱动代码
按 manifest 对齐后写入（`modify_script` 或直接编辑），三份模板缺一不可：

| 文件 | 模板 | 要点 |
|------|------|------|
| `player.gd` | [player_template.gd](player_template.gd) | 薄壳：引用 + `_init_state_machine()`；无行动 `match` |
| `player_animation_tree.gd` | [player_animation_tree_template.gd](player_animation_tree_template.gd) | GUIDE 输入查询；挂到 `AnimationTree` 节点 |
| 模式态（如 `normal_battle.gd`） | [limbo_mode_template.gd](limbo_mode_template.gd) | `match state_playback`；`update_animation` 写 blend（**y 轴取反**） |

新增 AnimationTree 子机（如 `RollMachine`）时：同步补模式态的 `match` 分支与 `blend_position` 写入，并在 AnimationTree 脚本加对应 `is_*()`。

### Step 4 — 校验
用 `execute_editor_script` 读回校验（见 [reference.md](reference.md)）：
- `AnimationPlayer` 动画数 == 预期。
- 每个 `parameters/StateMachine/.../blend_position` 可 `get()` 到（非 null）。
- `AnimationTree.active == true`。
- `LimboHSM` 已 `initialize` 且存在初始模式态。
- 可选：`run_project` 冒烟——四方向 idle/run、攻击定身、翻滚位移。

若失败，对照下方坑位表修复后重跑对应 Step。

## 坑位表

| 症状 | 原因 | 修复 |
|------|------|------|
| AnimationTree 不动 | `active == false` | 脚本已设 `tree.active = true`，确认没被覆盖 |
| 播放但精灵帧不变 | 轨道节点路径与实际不符 | manifest `sprite_node` = `CharacterBody2D/Sprite2D`（相对 Player 根） |
| `travel/advance` 不切换 | 表达式基准节点错或方法不在基准上 | `advance_expression_base_node = "."`；`is_attacking()` 等必须在 **PlayerAnimationTree** 上 |
| 方向混合错乱 | blend 坐标 y 轴未取反 | 模式态 `update_animation` 传入 `Vector2(dir.x, -dir.y)` |
| left 动画不镜像 | 缺 `flip_h` 轨道 | manifest `mirror` 配 `{"left":"right"}`，Step1 自动加 flip 轨 |
| 攻击/翻滚后卡住 | 返回 Move 无 AT_END 过渡 | 脚本用 `SWITCH_MODE_AT_END`；对应动画 `loop=false` |
| Limbo 模式不跑 | 未 `initialize` / `set_active` | `player._init_state_machine()`：`update_mode=PHYSICS`、`initial_state`、`initialize(self)`、`set_active(true)` |
| 输入在 player 上查不到 | 旧模板把 GUIDE 放在 player | 迁移到 `PlayerAnimationTree`；模式态经 `player.animation_tree.get_move_direction()` |

## 资源
- 输入清单格式与完整示例：[manifest.schema.md](manifest.schema.md)
- blend 坐标 / transition / 扩展点 / 校验片段：[reference.md](reference.md)
