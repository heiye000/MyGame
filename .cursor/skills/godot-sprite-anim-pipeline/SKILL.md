---
name: godot-sprite-anim-pipeline
description: Standard pipeline that turns a sprite-sheet PNG plus a structured manifest into multi-directional AnimationPlayer clips, an AnimationTree state machine, LimboHSM mode-driver code, and InputBuffer pre-input wiring, executed through the godot-mcp execute_editor_script tool. Use when the user provides a sprite sheet and asks to generate directional idle/walk/attack/roll animations, wire up an AnimationTree, integrate input buffering, or run the "动画流水线 / sprite animation pipeline / anim pipeline" workflow.
disable-model-invocation: true
---

# Godot Sprite Animation Pipeline

把「精灵图 PNG -> 多方向 AnimationPlayer 动画 -> AnimationTree 动画状态机 -> LimboHSM 行动模式驱动 -> InputBuffer 预输入」固化为固定流程。执行手段是 `user-godot_mcp` 的 `execute_editor_script`（在编辑器里跑完整 GDScript，数据驱动地建动画，无需手工连线）。

## 目标架构（对齐 `demo1/scenes/player/`）

职责分层，便于扩展新行动模式（探索、对话、载具等）与新可缓冲动作（攻击、翻滚、闪避等）：

```
Player (Node2D)
├── CharacterBody2D / Sprite2D          # 物理与精灵
├── InputBuffer                        # 预输入：GUIDE just_triggered 捕获、单槽位、过期
│     └── DebugOverlay                 # 可选：剩余缓冲帧调试叠层
├── AnimationPlayer                    # 切帧动画库
├── AnimationTree : PlayerAnimationTree
│     # 输入查询（transition 表达式）+ 动画图；is_* 只查不消费
│     BlendTree -> StateMachine -> {
│       MoveMachine{idle, run},
│       AttackMachine{attack_L},
│       RollMachine{roll}
│     }
│     每个状态 = BlendSpace2D（方向靠 blend 坐标）
└── LimboHSM
      └── NormalBattle : LimboState
            # match 分发；进入 Attack/Roll 时 consume + 锁定朝向；分路写 blend
```

| 层 | 职责 | 不负责 |
|----|------|--------|
| `player.gd` | 节点引用（含 `input_buffer`）、LimboHSM 初始化、AnimationTree 物理帧对齐 | 不写行动 `match`、不消费缓冲 |
| `InputBuffer` | 监听 GUIDE `just_triggered`、维护槽位/过期/DebugOverlay | 不读 AnimationTree 当前状态、不驱动位移 |
| `player_animation_tree.gd` | `get_move_direction()` / `is_*()` = `is_triggered() or has_buffered()` | **禁止** `consume_buffered()`；不驱动位移 |
| Limbo 模式态（如 `normal_battle.gd`） | `match state_playback`；**进入** Attack/Roll 时 `consume_buffered`；分路写 blend；开招瞬间用当前 WASD 定朝向 | 不在 `_update` 公共块统一消费；不直接读 GUIDE |
| AnimationTree 图 | idle↔run、Move↔Attack/Roll 等切换 | 不决定「当前是战斗还是对话」 |

### 预输入数据流（必须遵守）

```
GUIDE Pressed → InputBuffer(just_triggered) 写入槽位
  → PlayerAnimationTree.is_*()：is_triggered() OR has_buffered()   ← 只查
  → AnimationTree：Move → Attack/Roll
  → NormalBattle 刚进入对应子机：consume_buffered()               ← 才消费
  → 同帧 _resolve_action_direction(当前 WASD，否则 last_direction)
```

> **扩展新行动模式**：在 `LimboHSM` 下新增 `LimboState`（如 `Explore`），在 `player.gd` 里注册 transition；AnimationTree 可复用或按模式换树。流水线 Step3 默认生成/修补 `NormalBattle` 这一种模式。
>
> **扩展新可缓冲动作**：见 [reference.md](reference.md)「预输入约定」；manifest 的 `input_buffer.actions` 声明 `buffer_frames`。

## 前置条件

1. 目标场景已在 Godot 编辑器中**打开**（脚本用 `EditorInterface.get_edited_scene_root()`）。
2. 场景节点（相对 Player 根）：
   - `CharacterBody2D/Sprite2D`（已设 `texture` 与 `hframes/vframes`）
   - `AnimationPlayer`、`AnimationTree`（根直属）
   - `LimboHSM` + 至少一个模式态（如 `LimboHSM/NormalBattle`）——缺则用 godot-mcp `create_node` 补建
   - 若 manifest 声明可缓冲动作：`InputBuffer`（挂 `InputBuffer.gd` + Profile）及可选 `InputBuffer/DebugOverlay`
3. 用户已按 [manifest.schema.md](manifest.schema.md) 提供结构化清单（含可选 `input_buffer` 段）。
4. 可缓冲动作依赖项目内已有：`PlayerActionType`、GUIDE action `.tres`、`InputBufferProfile` / Entry 脚本（路径见 demo1 `core/components/input/`）。

## 工作流

复制此清单并逐步跟踪：

```
Pipeline Progress:
- [ ] Step 0: 校验 manifest、场景前置条件、InputBuffer/Profile（若有缓冲动作）
- [ ] Step 1: 生成 AnimationPlayer 动画
- [ ] Step 2: 生成 AnimationTree 状态机
- [ ] Step 3: 生成/修补驱动代码（Player + AnimationTree + Limbo + 预输入接线）
- [ ] Step 4: 校验（含预输入冒烟）
```

### Step 0 — 校验输入
- 确认 manifest 每个 `action.frames` 的方向集合能被「显式帧 + mirror 派生」覆盖 `directions`。
- 确认帧索引都落在 `hframes * vframes` 范围内。
- 用 `get_scene_tree` 确认必需节点存在。缺失则停下让用户补齐，或用 `create_node` 补建 `AnimationTree` / `LimboHSM` / 模式态。
- 若存在 `input_buffer.actions`（或 oneshot 机带 `bufferable: true`）：
  - 确认 `InputBuffer` 节点存在且 `profile` 已指定（如 `BattleBufferProfile.tres`）。
  - 确认 Profile `entries` 为 `[SubResource(...), ...]`，**禁止** `Array[ExtResource(...)]` 空壳写法。
  - 每个可缓冲动作：`PlayerActionType` 有枚举、GUIDE action 为 **Pressed**、Profile 有对应 Entry。

### Step 1 — 生成 AnimationPlayer 动画
读取 [scripts/build_animations.gd](scripts/build_animations.gd)，把顶部 `MANIFEST` 用用户清单填好，整段作为 `execute_editor_script` 的 `code` 执行。它遍历 `动作 × 方向`，为每个动画建 `Sprite2D:frame` 值轨道（离散更新，`time = i/fps`），mirror 派生方向额外加 `flip_h` 轨道，全部塞进默认 `AnimationLibrary` 并存盘。
- **注意**：`sprite_node` 须为相对 Player 根的路径，当前为 `CharacterBody2D/Sprite2D`。
- 期望输出：`OK 动画数=<N>`，其中 `N = 1(RESET) + Σ(动作方向数)`。
- 记下每个 oneshot 动作的 `length`（秒），供 Step3 估算 `buffer_frames`。

### Step 2 — 生成 AnimationTree 状态机
读取 [scripts/build_animation_tree.gd](scripts/build_animation_tree.gd)，填好顶部 `CFG`（方向 blend 坐标、`machines`、transition 表达式），整段作为 `execute_editor_script` 的 `code` 执行。
- 拓扑：`BlendTree -> StateMachine -> { MoveMachine, AttackMachine, RollMachine, ... }`（由 `CFG.machines` 数据驱动）。
- `advance_expression_base_node = NodePath(".")`（表达式在 **AnimationTree / PlayerAnimationTree** 上求值）。
- `callback_mode_process = PHYSICS`（与 LimboHSM、InputBuffer 物理帧同拍）。
- 设置 `active=true`、`anim_player`，并初始化各 `blend_position`。
- Move → Oneshot 的 `from_move_expr` 使用 `is_*() == true`（实现见 Step3，含缓冲查询）。

### Step 3 — 生成/修补驱动代码 + 预输入接线
按 manifest 对齐后写入（`modify_script` 或直接编辑），下列缺一不可：

| 文件 | 模板 | 要点 |
|------|------|------|
| `player.gd` | [player_template.gd](player_template.gd) | `@onready input_buffer`；`_ready` 设 AnimationTree active / expr base / PHYSICS；无行动 `match` |
| `player_animation_tree.gd` | [player_animation_tree_template.gd](player_animation_tree_template.gd) | `_ready` 经父节点取 `InputBuffer`；`is_*()` = triggered **或** `has_buffered`，**不消费** |
| 模式态（如 `normal_battle.gd`） | [limbo_mode_template.gd](limbo_mode_template.gd) | `_last_anim_node`；进入 Attack/Roll 时 `consume_buffered`；分路 `_set_*_blend`；开招用当前 WASD 锁朝向 |
| Profile / ActionType | 无单独模板 | 每个可缓冲动作：枚举 + GUIDE `.tres` + Profile Entry（`BUFFERABLE` + `buffer_frames`） |

新增 AnimationTree 子机（如 `DodgeMachine`）时同步：
1. `PlayerAnimationTree.is_dodging()`（只查）
2. 模式态 `match` + 进入时 `consume_buffered(DODGE)` + `_set_dodge_blend`
3. Profile Entry；`buffer_frames ≈ ceil(动画时长秒 × physics_fps) + 2～6` 余量

场景侧（若尚未挂好）：
- `InputBuffer` 子节点 + `profile` 引用
- 可选 `InputBuffer/DebugOverlay`（`InputBufferDebugOverlay.gd`），子控件 `mouse_filter = Ignore`

### Step 4 — 校验
用 `execute_editor_script` 读回校验（见 [reference.md](reference.md)）：
- `AnimationPlayer` 动画数 == 预期。
- 每个 `parameters/StateMachine/.../blend_position` 可 `get()` 到（非 null）。
- `AnimationTree.active == true`；`advance_expression_base_node` 为 `.`；处理模式为 PHYSICS。
- `LimboHSM` 已可初始化且存在初始模式态。
- 若启用预输入：`InputBuffer.profile.entries` 非空；`PlayerAnimationTree` 的 `is_*` 含 `has_buffered`；模式态进入分支含 `consume_buffered`。
- 可选：`run_project` 冒烟——四方向 idle/run、攻击定身、翻滚位移、recovery 预按能接、开招后 Overlay 对应槽位清零。

若失败，对照下方坑位表修复后重跑对应 Step。

## 坑位表

| 症状 | 原因 | 修复 |
|------|------|------|
| AnimationTree 不动 | `active == false` | `player._ready` / Step2 设 `tree.active = true` |
| 播放但精灵帧不变 | 轨道节点路径与实际不符 | manifest `sprite_node` = `CharacterBody2D/Sprite2D` |
| `travel/advance` 不切换 | 表达式基准节点错或方法不在基准上 | `advance_expression_base_node = "."`；`is_*()` 必须在 **PlayerAnimationTree** |
| 方向混合错乱 | blend 坐标 y 轴未取反 | 模式态写入前 `Vector2(dir.x, -dir.y)` |
| left 动画不镜像 | 缺 `flip_h` 轨道 | manifest `mirror` 配 `{"left":"right"}`，Step1 自动加 flip 轨 |
| 攻击/翻滚后卡住 | 返回 Move 无 AT_END 过渡 | `SWITCH_MODE_AT_END`；对应动画 `loop=false` |
| 按住攻击键连打 | `is_*()` 读了 `value_bool` | GUIDE 用 Pressed；`is_*()` 用 `is_triggered()`（再 OR `has_buffered`） |
| Limbo 模式不跑 | 未 `initialize` / `set_active` | `update_mode=PHYSICS`、`initial_state`、`initialize(self)`、`set_active(true)` |
| 输入在 player 上查不到 | 旧模板把 GUIDE 放在 player | 迁移到 `PlayerAnimationTree` |
| 第二次预输入接不上 / 过渡抖动 | 在 `is_*()` 里 `consume_buffered` | 只查 `has_buffered`；进子机再消费 |
| Overlay 有缓冲但动画不接 | 缺 `is_*` 合并缓冲，或 `buffer_frames` 短于来源动作剩余时长 | 补查询；增大 Entry 的 `buffer_frames` |
| Profile entries 运行时为空 | `.tres` 写成 `Array[ExtResource]` | 改为 `entries = [SubResource(...), ...]`；Entry 用独立脚本 |
| 子节点拿不到 `input_buffer` | 子 `_ready` 早于父 `@onready` | 用 `player.get_node_or_null("InputBuffer")`，勿直接读 `@onready` 字段 |
| 斜向移动后攻击方向「锁死」旧朝向 | 开招只用 `last_direction` | 进入子机时 `_resolve_action_direction(当前 WASD)` |
| 攻击时跑动画方向被拧歪 | 攻击分支仍写 Move blend | 分路 `_set_move_blend` / `_set_attack_blend` / `_set_roll_blend` |

## 资源
- 输入清单格式与完整示例：[manifest.schema.md](manifest.schema.md)
- blend 坐标 / transition / 预输入约定 / 扩展点 / 校验片段：[reference.md](reference.md)
