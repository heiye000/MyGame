---
name: godot-sprite-anim-pipeline
description: Standard pipeline that turns a sprite-sheet PNG plus a structured manifest into multi-directional AnimationPlayer clips, an AnimationTree state machine, LimboHSM mode-driver code, InputBuffer pre-input wiring, and YSortable2D params from sprite-sheet annotation JSON. Use when the user provides a sprite sheet and asks to generate directional animations, wire up an AnimationTree, integrate input buffering, apply Y-sort from annotation, or run the "动画流水线 / sprite animation pipeline / anim pipeline" workflow.
disable-model-invocation: true
---

# Godot Sprite Animation Pipeline

把「精灵图 PNG -> 多方向 AnimationPlayer 动画 -> AnimationTree 动画状态机 -> LimboHSM 行动模式驱动 -> InputBuffer 预输入」固化为固定流程。执行手段是 `user-godot_mcp` 的 `execute_editor_script`（在编辑器里跑完整 GDScript，数据驱动地建动画，无需手工连线）。

## 目标架构（对齐 `GamePlayer/actors/player/`）

玩家场景的根就是 `CharacterBody2D`。探索和战斗是两个 Limbo 态。身体动画和刀光分开：战斗身体只播左下/右下，刀光按锁定的八向另挥。

**不要**对已有 `player.tscn` 重跑 Step2。那棵 AnimationTree 是手维护的嵌套图。`scripts/build_animation_tree.gd` 仍只生成扁平的 Move/Attack/Roll，给新建的简单行动体用。

```
Player (CharacterBody2D)                 # global_position = 脚底；motion_mode = FLOATING
├── Sprite2D                             # 玩家切帧路径就是 Sprite2D
├── YSortable2D
├── CollisionShape2D                     # 脚底约 12×8
├── Hurtbox (Area2D, PlayerHurtbox=4)    # 玩家受击盒目前仍是空壳
├── Hitbox (Area2D, PlayerHitbox=16)     # 只被动画清成空多边形，不再承担伤害
├── StatsComponent
├── TargetLockComponent (Area2D)         # 软锁/硬锁；mask = ActorBody(2)
├── AttackCaster                         # slash_scene、spawn_distance、advance_speed
├── InputBuffer
│     └── DebugOverlay
├── CameraTarget (Marker2D)              # 相机不挂在玩家下
├── AnimationPlayer
├── AnimationTree : PlayerAnimationTree
│     BlendTree -> StateMachine
│       Normal { idle, run_start, run }          # 探索，完整八向
│       DrawSword                                # 拔剑 oneshot，左下/右下
│       Battle
│         MoveMachine { idle, run }              # 左下/右下
│         AttackMachine { windup, active, recovery }
│         RollMachine { roll }
│       SheathSword                              # 收剑 oneshot
└── LimboHSM
      ├── Normal : PlayerNormal                  # 探索；拔剑 dispatch draw_sword
      └── Battle : PlayerBattle                  # 战斗；收剑 dispatch 回探索
```

敌人（如蝙蝠）仍是 `Node2D` 根 + 子 `CharacterBody2D`。给这类新实体跑 Step1 时，`sprite_node` 用 `CharacterBody2D/Sprite2D`。受击组件挂在身体上，见 reference.md「战斗组件」。

| 层 | 职责 | 不负责 |
|----|------|--------|
| `player.gd` | 节点引用（含 `input_buffer`、`target_lock`、`attack_caster`）、LimboHSM 初始化、`is_battle_mode()` | 不写行动 `match`、不消费缓冲、不挥刀 |
| `InputBuffer` | 监听 GUIDE `just_triggered`、维护槽位/过期/DebugOverlay | 不读 AnimationTree 当前状态、不驱动位移 |
| `player_animation_tree.gd` | `get_move_direction()` / `is_battle()` / `is_attacking()` / `is_rolling()`；攻击翻滚只在顶层已是 `Battle` 时为真；同帧已在对应子机则返回 false | **禁止** `consume_buffered()`；不驱动位移 |
| `PlayerNormal` | 探索八向移动；清攻击/翻滚缓冲；拔剑时 `dispatch` | 不挥刀、不写 Battle 子图 blend |
| `PlayerBattle` | 战斗位移；身体折成左下/右下；进入 Attack/Roll 时消费缓冲；`active` 段调用 `AttackCaster.slash` | 不把刀光方向折成两向；不在 windup 挥刀 |
| AnimationTree 图 | 拔剑/收剑、idle↔run、Move↔Attack/Roll | 不决定 Limbo 在探索还是战斗；不播刀光 |
| 刀光 / 锁定 / 生命 | 独立组件，场景里接好。流水线不生成它们的动画 | 见 reference.md |

### 预输入数据流（必须遵守）

```
GUIDE Pressed → InputBuffer(just_triggered) 写入槽位
  → PlayerAnimationTree.is_battle()：Limbo 战斗态才允许顶层 Normal → DrawSword
  → PlayerAnimationTree.is_attacking() / is_rolling()：顶层已是 Battle，且本帧不在该子机
  → AnimationTree：Battle/MoveMachine → AttackMachine / RollMachine
  → PlayerBattle 刚进入对应子机：consume_buffered()                 ← 才消费
  → 身体朝向：锁定瞄准（否则 WASD / last_direction）再折成左下/右下
  → AttackMachine 进入 active：AttackCaster.slash(折之前的八向)     ← 才挥刀
```

探索态每帧清掉攻击/翻滚缓冲。拔剑/收剑不走 InputBuffer，由当前 Limbo 态监听 `DRAW_SWORD` 的 `just_triggered`。

### 人物动作与刀光（必须分开）

人物动作只驱动角色 `Sprite2D`。攻击判定只存在于单独生成的刀光场景里。Step1 只写精灵帧，不写 `Hitbox` 多边形。

| 情况 | 结果 |
|---|---|
| 新增 idle / 跑 / 翻滚 / 拔剑 / 收剑，或任何没点名刀光的动作 | 只播人物动画，不调用 `AttackCaster.slash` |
| 动作明确指定刀光场景（现有 `ATTACK_L` 用 `attack_left_1.tscn`） | 身体照常播；内层进入 `active` 时才 `slash` |
| 没给出刀光场景，却从 `limbo_battle_template.gd` 抄了 `slash()` | 错误。那三行只属于已经指定刀光的攻击 |

`AttackCaster.slash_scene` 是当前这一次攻击的刀光，不是「以后所有新动作的默认刀光」。新动作要出刀，必须同时给出刀光场景，并在该动作自己的进入 `active` 分支里调用 `slash`。

> **精灵标注 JSON**：与 `sprite_sheet` 同目录同名的 `.json`（由 `sprite-sheet-frame-annotator` 生成）可含 `grid` / `y_sort` / `animations`，以及可选的 `ai_description` / `ai_description_cn`。流水线 Step0 优先读取其中的 `grid` 与 `y_sort`；缺标注时再用手写 manifest 或向用户确认。
>
> **忽略提示词字段**：`ai_description`、`ai_description_cn` 仅供标注存档（生成序列帧的提示词及其译文），**不是**动画数据。流水线读写标注时必须忽略这两键：不拷进 manifest、不驱动 AnimationPlayer / AnimationTree / Limbo / YSortable2D、不因缺少或为空而失败。
>
> **扩展新行动模式**：玩家已经有 `Normal` 与 `Battle`。过渡在各自 `_setup` 里 `add_transition`，事件名都是 `draw_sword`。不要在 `player.gd` 里注册。新模式另建 `LimboState`，不要塞回单一 `NormalBattle`。
>
> **扩展新可缓冲动作**：见 [reference.md](reference.md)「预输入约定」；manifest 的 `input_buffer.actions` 声明 `buffer_frames`。

## 前置条件

1. 目标场景已在 Godot 编辑器中**打开**（脚本用 `EditorInterface.get_edited_scene_root()`）。
2. 先分清场景根：
   - **玩家**（已存在，禁止 Step2 覆盖）：根是 `CharacterBody2D`。精灵路径 `Sprite2D`。`LimboHSM/Normal` + `LimboHSM/Battle`。战斗组件按 reference.md 接在根上。
   - **新建简单行动体 / 敌人**：根可以是 `Node2D`，身体是 `CharacterBody2D`。精灵路径 `CharacterBody2D/Sprite2D`。Step1/Step2 只服务这种扁平图。
3. 共用节点：
   - `YSortable2D`（挂 `y_sortable_2d.gd`）——参数见下方「Y 排序接线」
   - `AnimationPlayer`、`AnimationTree`（根直属）
   - 若 manifest 声明可缓冲动作：`InputBuffer` + Profile，及可选 `InputBuffer/DebugOverlay`
4. 用户已按 [manifest.schema.md](manifest.schema.md) 提供结构化清单（含可选 `input_buffer` 段）。
5. 可缓冲动作依赖项目内已有：`PlayerActionType`、GUIDE action `.tres`、`InputBufferProfile` / Entry 脚本（路径 `GamePlayer/core/components/input/`）。

## 工作流

复制此清单并逐步跟踪：

```
Pipeline Progress:
- [ ] Step 0: 校验 manifest / 标注 JSON、场景前置条件、InputBuffer/Profile（若有缓冲动作）
- [ ] Step 1: 生成 AnimationPlayer 动画
- [ ] Step 2: 生成 AnimationTree 状态机
- [ ] Step 3: 生成/修补驱动代码 + 预输入接线 + YSortable2D 接线
- [ ] Step 4: 校验（含预输入冒烟、Y 排序参数）
```

### Step 0 — 校验输入
- **读取精灵标注 JSON**（若存在）：`sprite_sheet` 路径将 `.png` 换为 `.json`（例：`res://assets/enemies/bat.png` → `res://assets/enemies/bat.json`）。用其 `grid` 补全/校验 manifest 的 `hframes`/`vframes`；记录 `y_sort` 供 Step3 写入 `YSortable2D`。标注里的 `ai_description` / `ai_description_cn` **直接跳过**，不参与本步及后续任何生成。
- 确认 manifest 每个 `action.frames` 的方向集合能被「显式帧 + mirror 派生」覆盖 `directions`。
- 确认帧索引都落在 `hframes * vframes` 范围内。
- 用 `get_scene_tree` 确认必需节点存在。缺失则停下让用户补齐，或用 `create_node` 补建 `AnimationTree` / `LimboHSM` / 模式态 / `YSortable2D`。
- 若存在 `input_buffer.actions`（或 oneshot 机带 `bufferable: true`）：
  - 确认 `InputBuffer` 节点存在且 `profile` 已指定（如 `BattleBufferProfile.tres`）。
  - 确认 Profile `entries` 为 `[SubResource(...), ...]`，**禁止** `Array[ExtResource(...)]` 空壳写法。
  - 每个可缓冲动作：`PlayerActionType` 有枚举、GUIDE action 为 **Pressed**、Profile 有对应 Entry。

### Step 1 — 生成 AnimationPlayer 动画
读取 [scripts/build_animations.gd](scripts/build_animations.gd)，把顶部 `MANIFEST` 用用户清单填好，整段作为 `execute_editor_script` 的 `code` 执行。它遍历 `动作 × 方向`，为每个动画建 `Sprite2D:frame` 值轨道（离散更新，`time = i/fps`），mirror 派生方向额外加 `flip_h` 轨道，全部塞进默认 `AnimationLibrary` 并存盘。
- **玩家** `sprite_node` = `Sprite2D`。**嵌套身体的敌人** = `CharacterBody2D/Sprite2D`。
- 本步只切精灵帧。不要给角色 `Hitbox/CollisionPolygon2D:polygon` 写伤害多边形。玩家攻击伤害在刀光场景里。
- 期望输出：`OK 动画数=<N>`，其中 `N = 1(RESET) + Σ(动作方向数)`。
- 记下每个 oneshot 动作的 `length`（秒），供 Step3 估算 `buffer_frames`。
- 已有玩家攻击动画（`battle_attach_up_*`）是手调的，不要用本步覆盖。

### Step 2 — 生成 AnimationTree 状态机
只对**新建的扁平行动体**执行。读取 [scripts/build_animation_tree.gd](scripts/build_animation_tree.gd)，填好顶部 `CFG`，整段作为 `execute_editor_script` 的 `code` 执行。它会换掉整个 `tree_root`。
- 扁平拓扑：`BlendTree -> StateMachine -> { MoveMachine, AttackMachine, RollMachine }`。
- **玩家禁止跑本步。** 玩家图是 `Normal / DrawSword / Battle / SheathSword`，Battle 内再嵌 Move、Attack（windup/active/recovery）、Roll。blend 坐标用 `Direction8.to_blend_position`，不要再手写 `Vector2(dir.x, -dir.y)`。
- `advance_expression_base_node = NodePath(".")`（表达式在 **AnimationTree / PlayerAnimationTree** 上求值）。
- `callback_mode_process = PHYSICS`（与 LimboHSM、InputBuffer 物理帧同拍）。
- Move → Oneshot 的 `from_move_expr` 使用 `is_*() == true`（实现见 Step3，含缓冲查询）。

### Step 3 — 生成/修补驱动代码 + 预输入接线
按 manifest 对齐后写入（`modify_script` 或直接编辑），下列缺一不可：

| 文件 | 模板 | 要点 |
|------|------|------|
| `player.gd` | [player_template.gd](player_template.gd) | 根是 `CharacterBody2D`；保留 `target_lock` / `attack_caster`；`is_battle_mode()`；无行动 `match` |
| `player_animation_tree.gd` | [player_animation_tree_template.gd](player_animation_tree_template.gd) | `is_battle()` 问 Limbo；`is_attacking()` / `is_rolling()` 先要求顶层是 `Battle`；只查不消费 |
| 探索态 | [limbo_normal_template.gd](limbo_normal_template.gd) | 八向移动；清攻击/翻滚缓冲；拔剑 `dispatch` |
| 战斗态 | [limbo_battle_template.gd](limbo_battle_template.gd) | 身体折两向；`active` 时 `attack_caster.slash`；进入子机才 `consume_buffered` |
| Profile / ActionType | 无单独模板 | 可缓冲：`ATTACK_L` / `ROLL`。拔剑、硬锁、软锁切目标不进缓冲 |

`limbo_mode_template.gd` 已废弃，打开它只会看到指向上述两个模式态的说明。战斗组件的挂法和调用见 [reference.md](reference.md)「战斗组件」。Step3 修补玩家脚本时，不得删掉刀光、锁定、受击引用。

在玩家 Battle 子图里新增子机（如 `DodgeMachine`）时同步：
1. `PlayerAnimationTree.is_dodging()`：顶层必须是 `Battle`，只查缓冲，并对 `DodgeMachine` 做同帧门闩。
2. `PlayerBattle` 的 `match` + 进入时 `consume_buffered` + `_set_dodge_blend`。身体朝向仍折成左下/右下。
3. Profile Entry；`buffer_frames ≈ ceil(动画时长秒 × physics_fps) + 2～6` 余量。不要为此重跑 Step2。

场景侧（若尚未挂好）：
- `InputBuffer` 子节点 + `profile` 引用
- 可选 `InputBuffer/DebugOverlay`（`InputBufferDebugOverlay.gd`），子控件 `mouse_filter = Ignore`
- **`YSortable2D` 接线**（见下）

### Y 排序接线（YSortable2D）

实体场景挂载 `YSortable2D` 时，**若精灵标注 JSON 含 `y_sort` 段，必须按标注设置参数**，禁止在场景中另估 `sort_offset` / `elevation`。

**节点约定：**
- 玩家路径：`YSortable2D`（根就是身体）。敌人路径：`CharacterBody2D/YSortable2D`。
- 脚本：`res://core/components/ysort/YSortable2D.gd`
- `host` 可不设（默认父节点 `CharacterBody2D`）
- `Sprite2D` 保持 `centered=true`，与标注 `坐标系` 一致

**属性映射（标注 `y_sort` → 节点）：**

| 标注键 | 节点属性 | 写法 |
|--------|----------|------|
| `sort_offset[0]`, `[1]` | `sort_offset` | `Vector2(x, y)` |
| `elevation` | `elevation` | 直接赋值；缺省 `0` |
| `sort_priority` | `sort_priority` | 直接赋值；缺省：玩家/敌人 `5`，静物 `3` |

**执行时机：** Step3 场景补建阶段——创建或更新 `YSortable2D` 后，从 Step0 读到的标注写入上述属性，并 `save_scene`。

**缺省与异常：**
- 标注**无** `y_sort`：停下提示用户先跑 `sprite-sheet-frame-annotator`，或询问锚点后再补标注；勿静默猜值。
- 场景已有 `YSortable2D` 且标注更新：以标注覆盖场景参数。
- 动画播放**不得**改动 `sort_offset`（锚点固定，不随帧摆动）。

**示例（`bat.json` → `BatEnemy.tscn`）：**

```ini
[node name="YSortable2D" type="Node" parent="CharacterBody2D"]
script = ExtResource("...YSortable2D.gd")
sort_offset = Vector2(0, 1)
elevation = -8.0
```

### Step 4 — 校验
用 `execute_editor_script` 读回校验（见 [reference.md](reference.md)）：
- `AnimationPlayer` 动画数 == 预期。
- 每个 `parameters/StateMachine/.../blend_position` 可 `get()` 到（非 null）。
- `AnimationTree.active == true`；`advance_expression_base_node` 为 `.`；处理模式为 PHYSICS。
- `LimboHSM` 已可初始化且存在初始模式态。
- 若启用预输入：`InputBuffer.profile.entries` 非空；`PlayerAnimationTree` 的 `is_*` 含 `has_buffered` 与同帧门闩（`_root_node_at_frame_start`）；模式态进入分支含 `consume_buffered`。
- **Y 排序**：`YSortable2D` 存在且 `sort_offset` / `elevation` 与标注 `y_sort` 一致（有标注时）；`Sprite2D.hframes/vframes` 与标注 `grid` 一致。
- 可选：`run_project` 冒烟——四方向 idle/run、攻击定身、翻滚位移、recovery 预按能接、开招后 Overlay 对应槽位清零。

若失败，对照下方坑位表修复后重跑对应 Step。

## 坑位表

| 症状 | 原因 | 修复 |
|------|------|------|
| AnimationTree 不动 | `active == false` | `player._ready` / Step2 设 `tree.active = true` |
| 播放但精灵帧不变 | 轨道节点路径与实际不符 | 玩家 `sprite_node` = `Sprite2D`；嵌套敌人 = `CharacterBody2D/Sprite2D` |
| `travel/advance` 不切换 | 表达式基准节点错或方法不在基准上 | `advance_expression_base_node = "."`；`is_*()` 必须在 **PlayerAnimationTree** |
| 方向混合错乱 | 又手写了一次 y 取反 | 只用 `Direction8.to_blend_position`；它已经是 BlendSpace 的 y 向上 |
| left 动画不镜像 | 缺 `flip_h` 轨道 | manifest `mirror` 配 `{"left":"right"}`，Step1 自动加 flip 轨 |
| 攻击/翻滚后卡住 | 返回 Move 无 AT_END 过渡 | `SWITCH_MODE_AT_END`；对应动画 `loop=false` |
| 按住攻击键连打 | `is_*()` 读了 `value_bool` | GUIDE 用 Pressed；`is_*()` 用 `is_triggered()`（再 OR `has_buffered`） |
| Limbo 模式不跑 | 未 `initialize` / `set_active` | `update_mode=PHYSICS`、`initial_state`、`initialize(self)`、`set_active(true)` |
| 输入在 player 上查不到 | 旧模板把 GUIDE 放在 player | 迁移到 `PlayerAnimationTree` |
| 第二次预输入接不上 / 过渡抖动 | 在 `is_*()` 里 `consume_buffered` | 只查 `has_buffered`；进子机再消费 |
| `looped transitions in a single frame` 告警 | Oneshot `At End` 回 Move 同帧 `is_*` 仍为 true，立刻再进形成回环 | `_physics_process` 记帧起点根节点；`is_*` 若本帧已在对应子机则返回 false（连招晚 1 帧） |
| Overlay 有缓冲但动画不接 | 缺 `is_*` 合并缓冲，或 `buffer_frames` 短于来源动作剩余时长 | 补查询；增大 Entry 的 `buffer_frames` |
| Profile entries 运行时为空 | `.tres` 写成 `Array[ExtResource]` | 改为 `entries = [SubResource(...), ...]`；Entry 用独立脚本 |
| 子节点拿不到 `input_buffer` | 子 `_ready` 早于父 `@onready` | 用 `player.get_node_or_null("InputBuffer")`，勿直接读 `@onready` 字段 |
| 斜向移动后攻击方向「锁死」旧朝向 | 开招只用 `last_direction` | 进入子机时先取锁定瞄准，否则当前 WASD，再否则 `last_direction` |
| 战斗身体播成了八向 | 把刀光方向写进了身体 blend | 身体用 `Direction8.to_down_diagonal`；八向只传给 `AttackCaster.slash` |
| 抬手就出刀光 | 在进入 `AttackMachine` 时调用了 `slash` | 等内层回放 `parameters/StateMachine/Battle/AttackMachine/playback` 进入 `active` |
| 同一刀扣两次血 | 角色动画仍在写 `Hitbox` 多边形 | 删掉 `battle_attach_up_active_*` 的多边形轨道；伤害只留在刀光 Hitbox |
| 刀光停在最后一帧 | `animation_finished` 把动画名传给了 `queue_free` | `queue_free.unbind(1)`，并 `CONNECT_ONE_SHOT` |
| 八个方向的刀光都偏到同一侧 | 用固定 `spawn_offset` 当距离 | 用 `spawn_distance`，沿 `Direction8.to_vector` 推 |
| 攻击时跑动画方向被拧歪 | 攻击分支仍写 Move blend | 分路 `_set_move_blend` / `_set_attack_blend` / `_set_roll_blend` |
| Y 排序遮挡不对 | `YSortable2D` 未读标注或手估 `sort_offset` | Step0 读同名 `.json` 的 `y_sort`；Step3 按标注写入，勿重算 |
| 飞行动画播放时排序漂移 | 把翅膀最低点当锚点或动画改了 `sort_offset` | 锚点用标注的稳定躯干/脚底；`sort_offset` 仅初始化一次 |
| 流水线误用提示词字段 | 把 `ai_description` 当动作名/朝向/帧范围 | 跳过 `ai_description` 与 `ai_description_cn`，只读 `grid` / `y_sort` / `animations` |

## 资源
- 输入清单格式与完整示例：[manifest.schema.md](manifest.schema.md)
- 朝向、预输入、战斗组件接线、校验片段：[reference.md](reference.md)
- 模式态模板：[limbo_normal_template.gd](limbo_normal_template.gd)、[limbo_battle_template.gd](limbo_battle_template.gd)。不要用 [limbo_mode_template.gd](limbo_mode_template.gd)
- 精灵表标注（含 `y_sort` 测算）：`sprite-sheet-frame-annotator` 技能
