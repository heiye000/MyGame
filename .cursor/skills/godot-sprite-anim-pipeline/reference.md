# Reference：坐标约定 / 表达式 / 预输入 / 扩展点 / 校验

## 分层职责速查

| 组件 | 文件 | 职责 |
|------|------|------|
| Player 壳 | `actors/player/player.gd` | 根即 `CharacterBody2D`；引用锁定、刀光、受击盒；`is_battle_mode()` |
| 预输入 | `core/components/input/input_buffer/input_buffer.gd` | GUIDE `just_triggered` 捕获、单槽位、过期、DebugOverlay |
| 动画输入 | `player_animation_tree.gd` | `is_battle` / `is_attacking` / `is_rolling`；只查不消费 |
| 探索态 | `state_machine/normal.gd` | 八向移动；清攻击/翻滚缓冲；拔剑 |
| 战斗态 | `state_machine/battle.gd` | 身体两向；`active` 挥刀；进入子机才消费缓冲 |
| 八向 | `core/components/direction/direction_8.gd` | `from_vector` / `to_vector` / `to_blend_position` / `to_down_diagonal` |
| 刀光 | `attack_caster.gd` + `attack/slash_swing.gd` | 生成刀光、沿瞄准推出、播完删除 |
| 锁定 | `lock/target_lock_component.gd` | 软锁/硬锁；`get_aim_direction` |
| 伤害 | `hitbox.gd` / `hurtbox.gd` / `health_component.gd` / `damage_info.gd` | 有多边形才检测；一刀一次；扣血发信号 |
| 受击表现 | `hit_effect_component.gd` / `death_effect_component.gd` | 听 `damaged` / `died`，不改血 |
| Y 排序 | `y_sortable_2d.gd` | 读精灵标注 `y_sort`；不参与动画驱动 |

## Y 排序（YSortable2D）约定

### 数据来源

精灵标注 JSON（与 `sprite_sheet` 同名 `.json`）的 `y_sort` 段：

```json
"y_sort": {
  "sort_offset": [0, 1],
  "elevation": -8
}
```

由 `sprite-sheet-frame-annotator` 测算；流水线 **只读取、不重算**。

标注里若有 `ai_description` / `ai_description_cn`（生成序列帧的提示词及其简体中文），流水线 **忽略**，不参与 `grid` / `y_sort` / 动画生成。

### 接线规则

1. 玩家节点路径：`YSortable2D`。敌人：`CharacterBody2D/YSortable2D`。脚本 `res://core/components/ysort/y_sortable_2d.gd`。
2. `sort_offset = Vector2(y_sort.sort_offset[0], y_sort.sort_offset[1])`。
3. `elevation = y_sort.elevation`（缺省 `0`）；`sort_priority` 缺省：玩家/敌人 `5`，静物 `3`。
4. 标注无 `y_sort` 时停下补标注，勿手估。
5. 动画播放不得修改 `sort_offset`。

### 与 grid 联动

Step0 同时用标注 `grid.hframes` / `grid.vframes` 设置 `Sprite2D`，与动画 manifest 保持一致。

## 预输入（Input Buffer）约定

### 数据流

```
GUIDE Pressed
  → InputBuffer 写入槽位（按 Profile buffer_frames）
  → PlayerAnimationTree.is_attacking() / is_rolling()：顶层是 Battle，且本帧不在该子机
       is_triggered() OR has_buffered()（只查不消费）
  → AnimationTree：Battle/MoveMachine → AttackMachine / RollMachine
  → PlayerBattle 刚进入对应子机：consume_buffered()
  → 身体朝向：TargetLockComponent.get_aim_direction，否则 WASD / last_direction，再 to_down_diagonal
  → 内层 AttackMachine 进入 active：AttackCaster.slash(折之前的 Direction8)
```

### 必须遵守

1. **`is_*()` 过渡表达式里禁止 `consume_buffered()`** — AnimationTree 同一帧会多次求值，第一次消费后后续为 false，过渡失败或抽搐。
2. **`consume_buffered()` 放在 `PlayerBattle._process_*_machine` 进入分支**（用 `_last_anim_node` 检测）。探索态改为 `clear`，不要消费。
3. **AnimationTree 用物理帧**（`callback_mode_process = PHYSICS`）+ `advance_expression_base_node = "."`，与 LimboHSM / InputBuffer 同拍。
4. **同帧门闩（防 looped transitions）**：`_physics_process` 记下顶层节点，若顶层是 `Battle` 再记下 `parameters/StateMachine/Battle/playback`。`is_attacking()` / `is_rolling()` 在顶层不是 `Battle`，或本帧 Battle 子图已是 `AttackMachine` / `RollMachine` 时返回 `false`。连招/连滚因此晚 1 物理帧，属预期。
5. **Profile Entry 用独立脚本**；`.tres` 的 `entries` 写成 `[SubResource(...), ...]`，禁止 `Array[ExtResource]`。
6. **开招朝向**：有锁用 `get_aim_direction`；否则当前 WASD；再否则 `last_direction`。身体 blend 再折成左下/右下。刀光方向在折之前用 `Direction8.from_vector` 锁死。翻滚不吃锁定。

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
4. 玩家：在现有 Battle 子图里加状态，不要重跑 Step2。新建扁平行动体才把子机写进 manifest 并跑 Step1/Step2。
5. `PlayerAnimationTree`：加 `is_*()`。玩家版本要先确认顶层是 `Battle`，再查 triggered OR has_buffered，并对新子机做同帧门闩。
6. `PlayerBattle`：`match` + 进入 `consume_buffered` + `_set_*_blend`。身体朝向折成左下/右下。只有该动作写明了刀光场景时，才在它自己的 `active` 分支调用 `AttackCaster.slash`。没写明就只有人物动作。
7. 场景：确认 `InputBuffer.profile` 指向更新后的 Profile。

## BlendSpace2D 方向坐标约定

世界坐标 y 向下。BlendSpace y 向上。转换只走 `Direction8`，模式态不要再写 `Vector2(dir.x, -dir.y)`。

| 方向名 | `to_vector`（y 向下） | `to_blend_position`（y 向上） |
|---|---|---|
| `up` | `(0, -1)` | `(0, 1)` |
| `up_right` | 归一化 `(1, -1)` | `(0.7, 0.7)` |
| `right` | `(1, 0)` | `(1, 0)` |
| `down_right` | 归一化 `(1, 1)` | `(0.7, -0.7)` |
| `down` | `(0, 1)` | `(0, -1)` |
| `down_left` | 归一化 `(-1, 1)` | `(-0.7, -0.7)` |
| `left` | `(-1, 0)` | `(-1, 0)` |
| `up_left` | 归一化 `(-1, -1)` | `(-0.7, 0.7)` |

- 探索移动：`Direction8.from_vector` 后 `to_blend_position`，八向都写。
- 战斗身体、拔剑、收剑：`to_down_diagonal(facing_x)`，只剩 `down_left` / `down_right`。
- 刀光：用折之前的 `Dir`，名字是 `to_string_name`。朝右的三向由刀光场景翻 `Body.scale.x`，不要翻根节点，也不要另做三条动画。

## Transition 属性对照

| 语义 | 属性设置 | Godot 枚举 |
|------|----------|-----------|
| 表达式满足即自动切 | `advance_mode = AUTO` + `advance_expression = "..."` | `ADVANCE_MODE_AUTO = 2` |
| 播完当前动画再切 | `switch_mode = AT_END` | `SWITCH_MODE_AT_END = 2` |
| 立即切换 | `switch_mode = IMMEDIATE` | `SWITCH_MODE_IMMEDIATE = 0` |

表达式在 `advance_expression_base_node`（`NodePath(".")`，即 **AnimationTree 自身**）上求值。`get_move_direction()`、`is_battle()`、`is_normal()`、`is_attacking()`、`is_rolling()` 必须是 `PlayerAnimationTree` 成员。顶层用 `is_battle()` / `is_normal()` 进出拔剑和收剑。Battle 子图才用 `is_attacking()` / `is_rolling()`。

## 生成的动画/参数命名

- 探索动画名：`<action>_<direction>`，八向，如 `player_run_up`。
- 战斗身体动画名带 `down_left` / `down_right`，攻击三段是 `battle_attach_up_{windup,active,recovery}_{down_left,down_right}`。
- 玩家 blend 路径示例：
  - `parameters/StateMachine/Normal/idle/blend_position`
  - `parameters/StateMachine/Battle/MoveMachine/idle/blend_position`
  - `parameters/StateMachine/Battle/AttackMachine/active/blend_position`
- 回放：顶层 `parameters/StateMachine/playback`；战斗 `parameters/StateMachine/Battle/playback`；攻击相位 `parameters/StateMachine/Battle/AttackMachine/playback`（`windup` / `active` / `recovery`）。

## LimboHSM 约定

```gdscript
# player.gd
state_machine.update_mode = LimboHSM.PHYSICS
state_machine.initial_state = normal   # LimboHSM/Normal
state_machine.initialize(self)          # agent = Player（根就是 CharacterBody2D）
state_machine.set_active(true)
```

模式态内：`var player := agent as Player`。位移写 `player.velocity`，不要再写 `player.character.velocity`。`player.character` 只是兼容旧敌人脚本的 getter，返回 `self`。

拔剑/收剑的 `add_transition` 写在 `PlayerNormal._setup` 和 `PlayerBattle._setup`，事件名都是 `draw_sword`。

### 扩展新行动模式
1. 新建 `LimboState`，挂到 `LimboHSM` 下。
2. 在相关模式的 `_setup` 里 `add_transition`。不要放进 `player.gd`。
3. 不要恢复单一 `NormalBattle`。

### 扩展新动画子机
玩家图不要重跑 Step2。在现有 Battle 子图里加状态，并同步：
1. `PlayerAnimationTree` 增加 `is_*()`（顶层必须是 `Battle`，只查缓冲，带同帧门闩）。
2. `PlayerBattle` 的 `match`、进入时 `consume_buffered`、`_set_*_blend`。
3. Profile Entry 与 `buffer_frames`。

## 扩展点

### 8 方向
方向名只用 `up, up_right, right, down_right, down, down_left, left, up_left`。探索移动写满八向。战斗身体不要做八向，用 `to_down_diagonal`。刀光的右、右下、右上由 `Body.scale.x = -1` 镜像。

### 逐动作不同帧率
给 action 加 `fps` 字段，Step1 中把 `step` 改为 `1.0/float(action.get("fps", MANIFEST["fps"]))`。

### 新的攻击方式
不要在 `AttackCaster` 里写死 `AttackLeft1`。新刀光场景继承 `SlashSwing`，实现 `play_direction`，再把发射器的 `slash_scene` 换成那一份。身体动画仍可以只有左下/右下。

### 非镜像 left
角色身体若 left 有独立帧，直接在该 action 的 `frames` 里给 `left`，并从 `mirror` 移除。刀光不要为右侧再画三条，除非美术不再是镜像。

## 战斗组件

流水线不生成这些组件。新敌人按蝙蝠的身体子节点来挂。玩家的伤害不走自己身上的 `Hitbox` 多边形。

物理层（`collision_layer` 数值）：`ActorBody=2`，`PlayerHurtbox=4`，`EnemyHurtbox=8`，`PlayerHitbox=16`，`EnemyHitbox=32`。

### 锁定

| 谁 | 挂在哪 | 怎么用 |
|---|---|---|
| `TargetLockComponent` | 玩家根，`Area2D` | `collision_layer=256`，`collision_mask=2`。探测进入圈内的 `CharacterBody2D`，再找子节点 `LockableTarget` |
| `LockableTarget` | 敌人身体下，组 `lockable` | 提供 `get_host()`、`get_lock_point()`、`is_alive()`。`health` 空着会找同级 `HealthComponent`；没有生命则永远可锁 |

对外只需要三个方法：

- `has_target()`：现在有没有锁着的人。
- `get_aim_direction(from)`：从脚底指向锁定点的单位向量；没有目标时是 `Vector2.ZERO`。
- 模式 `NONE / SOFT / HARD`。圈内自动软锁。`LOCK_HARD` 在软锁和硬锁之间切换。软锁时 `LOCK_SWITCH` 的鼠标甩动换目标。硬锁超出 `hard_break_radius`、目标死亡或被删掉才松开。

`PlayerBattle._battle_visual_facing` 有目标就用 `get_aim_direction`。翻滚不读锁定。

### 刀光

```
AttackCaster.slash(Direction8.Dir)
  → instantiate slash_scene as SlashSwing
  → 挂到攻击者下面（这样 Hitbox 能爬到 StatsComponent）
  → 位置 = 脚底 + spawn_offset + aim * spawn_distance
  → advance_direction = aim，advance_speed 抄发射器
  → Hitbox 层/掩码抄发射器（玩家 16 / 8）
  → play_direction(方向名)
  → animation_finished → queue_free.unbind(1)，CONNECT_ONE_SHOT
```

- `spawn_distance`：沿这一刀的瞄准方向推离身体，像素。固定 `spawn_offset` 不能代替它。
- `advance_speed = 0` 或 `advance_direction = ZERO`：刀光停在出手点。
- 镜像写在子类（`AttackLeft1`）里，翻的是 `Body.scale.x`。`SlashSwing._process` 移动的也是 `Body`，精灵和多边形一起走。
- 现有 `ATTACK_L` 的挥刀时机在 `PlayerBattle`：进入 `AttackMachine` 时锁八向；内层回放变成 `active` 时调用一次 `slash`。这是因为这次攻击已经指定 `attack_left_1.tscn`。
- 没指定刀光的新人物动作不要调用 `slash`，也不要写角色 `Hitbox` 多边形。流水线只加精灵帧和 blend。
- 播完删除必须 `unbind(1)`。`animation_finished` 会多传动画名，直接连 `queue_free` 会失败，刀光停在最后一帧。

新攻击方式要出刀时：新场景继承 `SlashSwing`，实现 `play_direction`，再在该动作自己的 `active` 分支里把对应场景交给 `AttackCaster` 并调用 `slash`。不要让后来的动作共用这一次的 `slash_scene`。

### 生命、命中、受击

```
刀光 Hitbox（多边形点数 >= 3 才 monitoring）
  → area_entered 只认 Hurtbox
  → 同一 Hurtbox 实例这一刀只记一次
  → DamageInfo.make(StatsComponent, 攻击者, Hitbox)
  → Hurtbox.receive_hit → HealthComponent.apply_damage
  → damaged(remaining, info)；血量到 0 再 died
```

| 组件 | 挂在哪 | 行为 |
|---|---|---|
| `StatsComponent` | 攻击者根，与刀光的祖先同级能被向上找到 | 目前只有 `attack`。扣血数是 `stats.attack`，不写在判定盒上 |
| `Hitbox` | 刀光 `Body/Hitbox`，子节点 `CollisionPolygon2D` | `can_be_blocked`、`can_be_perfect_parried` 抄进 `DamageInfo`。空多边形表示这一帧没有刀 |
| `Hurtbox` | 受击者身体 | `monitoring=false`，`mask=0`，只等 Hitbox 来扫。`health` 空着找同级 `HealthComponent` |
| `HealthComponent` | 受击者身体 | `apply_damage` 忽略已死亡。信号给表现用 |
| `HitEffectComponent` | 同级，听 `damaged` | 播受击火花。致死那下也会先走这里 |
| `DeathEffectComponent` | 同级，听 `died` | 关掉 Hurtbox，播死亡，再删实体 |

玩家根上的 `Hitbox` 仍挂着 `hitbox.gd`，但攻击动画的有效段不再写多边形。`RESET`、抬手、后摇上的空多边形留下来，用来把身上的形状清掉。

`HealthComponent` 目前只要收到 `DamageInfo` 就按攻击力扣血。`can_be_blocked` / `can_be_perfect_parried` 只是标记，防守方还没读它们。

蝙蝠身体上的现成接线：`Hurtbox`（层 8）→ `HealthComponent` → `HitEffectComponent` / `DeathEffectComponent` → `LockableTarget`。

## 校验片段（Step4，execute_editor_script）

```gdscript
var root = EditorInterface.get_edited_scene_root()
var ap = root.get_node("AnimationPlayer")
var tree = root.get_node("AnimationTree")
var hsm = root.get_node_or_null("LimboHSM")
var buf = root.get_node_or_null("InputBuffer")
var ysort = root.get_node_or_null("YSortable2D")
if ysort == null:
	ysort = root.get_node_or_null("CharacterBody2D/YSortable2D")
var names = ap.get_animation_list()
_custom_print("anim_count=" + str(names.size()))
_custom_print("tree_active=" + str(tree.active))
_custom_print("expr_base=" + str(tree.advance_expression_base_node))
_custom_print("tree_process=" + str(tree.callback_mode_process))
_custom_print("hsm=" + str(hsm != null))
if ysort:
	_custom_print("ysort_offset=" + str(ysort.sort_offset))
	_custom_print("ysort_elevation=" + str(ysort.elevation))
if hsm:
	_custom_print("hsm_children=" + str(hsm.get_child_count()))
if buf:
	_custom_print("buffer_profile=" + str(buf.profile != null))
	if buf.profile:
		_custom_print("buffer_entries=" + str(buf.profile.entries.size()))
var paths = [
	"parameters/StateMachine/playback",
	"parameters/StateMachine/Normal/idle/blend_position",
	"parameters/StateMachine/Battle/playback",
	"parameters/StateMachine/Battle/AttackMachine/playback",
	"parameters/StateMachine/Battle/MoveMachine/idle/blend_position",
	"parameters/StateMachine/Battle/AttackMachine/active/blend_position",
]
for p in paths:
	_custom_print(p + " = " + str(tree.get(p)))
```

期望：`anim_count` 等于 `1 + Σ动作方向数`；`tree_active=true`；`expr_base` 为 `.`；`tree_process=0`（PHYSICS）；每个 blend_position 可取到 `Vector2`；`LimboHSM` 存在；若启用预输入则 `buffer_entries > 0`；若有标注 `y_sort` 则 `ysort_offset` / `ysort_elevation` 与 JSON 一致。
