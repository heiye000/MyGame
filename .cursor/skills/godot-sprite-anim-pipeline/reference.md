# Reference：坐标约定 / 表达式 / 预输入 / 扩展点 / 校验

## 分层职责速查

| 组件 | 文件 | 职责 |
|------|------|------|
| Player 壳 | `player.gd` | 节点引用（含 `input_buffer`）、LimboHSM 初始化、AnimationTree 物理帧 |
| 预输入 | `core/components/input/input_buffer/InputBuffer.gd` | GUIDE `just_triggered` 捕获、单槽位、过期、DebugOverlay |
| 动画输入 | `player_animation_tree.gd` | GUIDE + `has_buffered` 查询；transition 表达式基准 |
| 行动模式 | `state_machine/*.gd`（LimboState） | `match` 分发；**进入** Attack/Roll 时消费预输入；分路写 blend |
| 动画图 | AnimationTree `tree_root` | Move / Attack / Roll 等子机切换 |

## 预输入（Input Buffer）约定

### 数据流

```
GUIDE Pressed
  → InputBuffer._on_guide_just_triggered → _store_slot（按 Profile buffer_frames）
  → PlayerAnimationTree.is_*()：is_triggered() OR has_buffered()   （只查不消费）
  → AnimationTree 过渡 Move → Attack/Roll
  → NormalBattle 刚进入对应子机：consume_buffered()
  → _resolve_action_direction(当前 WASD，否则 last_direction) 锁定朝向
```

### 必须遵守

1. **`is_*()` 过渡表达式里禁止 `consume_buffered()`** — AnimationTree 同一帧会多次求值，第一次消费后后续为 false，过渡失败或抽搐。
2. **`consume_buffered()` 放在 `_process_*_machine` 进入分支**（用 `_last_anim_node` 检测），不要在 `_update` 公共块统一消费。
3. **AnimationTree 用物理帧**（`callback_mode_process = PHYSICS`）+ `advance_expression_base_node = "."`，与 LimboHSM / InputBuffer 同拍。
4. **Profile Entry 用独立脚本**；`.tres` 的 `entries` 写成 `[SubResource(...), ...]`，禁止 `Array[ExtResource]`。
5. **开招朝向**：进入子机瞬间优先读当前 WASD；无输入再回退 `last_direction`；整段动作锁定，且只写本机 blend（不写 Move idle/run）。

### `buffer_frames` 怎么估

物理帧率默认 `physics_fps = 60`。对「在动作 A 里预按动作 B、等 A 结束再执行 B」：

```
buffer_frames ≥ ceil(A_length_sec × physics_fps) + 2～6
```

- 只覆盖 A 的后摇：用后摇时长估算即可。
- 调参：DebugOverlay 看剩余帧；太松减小、太紧增大。
- `pre_buffer_frames` / `active_window_frames` 仅给 `WINDOW_GATED`（弹反等），普通攻击/翻滚/闪避用 `BUFFERABLE` + `buffer_frames`。

### 新增可缓冲动作（流水线扩展清单）

1. GUIDE：新建 action `.tres`，触发 **Pressed**；写入 Context。
2. `PlayerActionType`：加枚举 + preload 路径。
3. Profile：加 Entry，`policy=BUFFERABLE`，设 `buffer_frames`。
4. manifest：`machines` 加子机 + `from_move_expr`；可选 `input_buffer.actions` 声明帧数。
5. Step1/2：生成动画与树。
6. `PlayerAnimationTree`：加 `is_*()`（triggered OR has_buffered）。
7. 模式态：`match` + 进入 `consume_buffered` + `_set_*_blend` + 锁朝向。
8. 场景：确认 `InputBuffer.profile` 指向更新后的 Profile。

## BlendSpace2D 方向坐标约定

BlendSpace2D 的 y 轴向上为正，而游戏输入 y 轴向下为正（`Vector2.DOWN = (0,1)`）。因此：
- **建树时**（Step2）blend 点坐标按 BlendSpace 坐标：`up=(0,1)`、`down=(0,-1)`、`left=(-0.8,0)`、`right=(0.8,0)`。
- **驱动时**（Limbo 模式态）传入 `blend_position` 前必须 y 取反：`Vector2(dir.x, -dir.y)`。

walk/run 常用更靠边的坐标（`±1` / `±0.8`）让方向切换更干脆，见 manifest 的 `run_blend_positions`。

## Transition 属性对照

| 语义 | 属性设置 | Godot 枚举 |
|------|----------|-----------|
| 表达式满足即自动切 | `advance_mode = AUTO` + `advance_expression = "..."` | `ADVANCE_MODE_AUTO = 2` |
| 播完当前动画再切 | `switch_mode = AT_END` | `SWITCH_MODE_AT_END = 2` |
| 立即切换 | `switch_mode = IMMEDIATE` | `SWITCH_MODE_IMMEDIATE = 0` |

表达式在 `advance_expression_base_node`（设为 `NodePath(".")`，即 **AnimationTree 自身**）上求值，故 `get_move_direction()`、`is_attacking()`、`is_rolling()` 必须是 `PlayerAnimationTree` 成员。`is_attacking()` / `is_rolling()` 只查 `is_triggered()` 与 `has_buffered()`，**不要**在表达式内 `consume_buffered()`。

## 生成的动画/参数命名

- 动画名：`<action.name>_<direction>`，如 `player_run_up`、`player_attack_left`。
- blend 参数路径：`parameters/StateMachine/<machine>/<state>/blend_position`。
- 顶层播放控制：`parameters/StateMachine/playback`（由模式态 `match` 查询当前子机名）。

## LimboHSM 约定

```gdscript
# player.gd
state_machine.update_mode = LimboHSM.PHYSICS
state_machine.initial_state = normal_battle
state_machine.initialize(self)  # agent = Player
state_machine.set_active(true)
```

模式态内：`var player := agent as Player`，经 `player.animation_tree` / `player.character` / `player.state_playback` / `player.input_buffer` 访问。

### 扩展新行动模式（非动画流水线主路径）
1. 新建 `LimboState` 脚本（可复制 `limbo_mode_template.gd` 精简）。
2. 在场景 `LimboHSM` 下挂节点并 `attach_script`。
3. 在 `player._init_state_machine` 注册 `add_transition`（模式间切换）。
4. AnimationTree 可复用同一棵树，或按模式切换 `tree_root` / `active`。

### 扩展新动画子机（流水线主路径）
1. manifest `actions` + `machines` 增加条目（如 `SkillMachine`）。
2. 重跑 Step1/Step2。
3. `PlayerAnimationTree` 增加 `is_skill()`（只查 `has_buffered`，不消费）；模式态进入时 `consume_buffered()`，并补 `match` 与 `_set_*_blend`。
4. 若可预输入：Profile 加 Entry，按动画时长估 `buffer_frames`。

## 扩展点

### 8 方向
在 manifest 的 `directions` 加入 `up_left` 等，并在 `direction_blend_positions` 给出对角坐标（如 `up_right=(0.7,0.7)`）。Step2 按 `directions` 循环 `add_blend_point`；模式态写入连续向量即可自动混合。

### 逐动作不同帧率
给 action 加 `fps` 字段，Step1 中把 `step` 改为 `1.0/float(action.get("fps", MANIFEST["fps"]))`。

### 多攻击态（attack_L / attack_R ...）
在对应 `machines.*.states` 增加条目，并补 `from_move_expr` 或 AttackMachine 内部选择逻辑；模式态 `_set_attack_blend` 同步补路径；各攻击可共用或分 Entry 缓冲。

### 非镜像 left
若 left 有独立帧，直接在该 action 的 `frames` 里给 `left`，并从 `mirror` 移除。

## 校验片段（Step4，execute_editor_script）

```gdscript
var root = EditorInterface.get_edited_scene_root()
var ap = root.get_node("AnimationPlayer")
var tree = root.get_node("AnimationTree")
var hsm = root.get_node_or_null("LimboHSM")
var buf = root.get_node_or_null("InputBuffer")
var names = ap.get_animation_list()
_custom_print("anim_count=" + str(names.size()))
_custom_print("tree_active=" + str(tree.active))
_custom_print("expr_base=" + str(tree.advance_expression_base_node))
_custom_print("tree_process=" + str(tree.callback_mode_process))
_custom_print("hsm=" + str(hsm != null))
if hsm:
	_custom_print("hsm_children=" + str(hsm.get_child_count()))
if buf:
	_custom_print("buffer_profile=" + str(buf.profile != null))
	if buf.profile:
		_custom_print("buffer_entries=" + str(buf.profile.entries.size()))
var paths = [
	"parameters/StateMachine/MoveMachine/idle/blend_position",
	"parameters/StateMachine/MoveMachine/run/blend_position",
	"parameters/StateMachine/AttackMachine/attack_L/blend_position",
	"parameters/StateMachine/RollMachine/roll/blend_position",
]
for p in paths:
	_custom_print(p + " = " + str(tree.get(p)))
```

期望：`anim_count` 等于 `1 + Σ动作方向数`；`tree_active=true`；`expr_base` 为 `.`；`tree_process=0`（PHYSICS）；每个 blend_position 可取到 `Vector2`；`LimboHSM` 存在；若启用预输入则 `buffer_entries > 0`。
