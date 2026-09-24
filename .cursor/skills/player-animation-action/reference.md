# 玩家动画接入参考

## 文件

| 改什么 | 路径 |
|---|---|
| GUIDE 行动 | `GamePlayer/core/components/input/res/actions/<name>.tres` |
| 键鼠映射 | `GamePlayer/core/components/input/res/contexts/keyboard_mouse.tres` |
| 资源登记 | `GamePlayer/core/loader/loader.gd` |
| 行动枚举 | `GamePlayer/core/components/input/player_action_type.gd` |
| 预输入 | `GamePlayer/core/components/input/res/profiles/battle_buffer_profile.tres` |
| 过渡查询 | `GamePlayer/actors/player/player_animation_tree.gd` |
| 战斗驱动 | `GamePlayer/actors/player/state_machine/battle.gd` |
| 探索驱动 | `GamePlayer/actors/player/state_machine/normal.gd` |
| 片段与树 | `GamePlayer/actors/player/player.tscn` |
| 八向坐标 | `GamePlayer/core/components/direction/direction_8.gd` |

枚举对照的写法以这两个文件顶部的注释为准：先 `Loader` 登记，再 `PlayerActionType` 加枚举和 `_ACTION_IDS`。

## 现有链（改之前先读，不要凭记忆改路径）

顶层动画节点：`Normal`、`DrawSword`、`Battle`、`SheathSword`。

- `Normal → DrawSword` 表达式 `is_battle() == true`，播完进 `Battle`。
- `Battle → SheathSword` 表达式 `is_normal() == true`，播完进 `Normal`。
- 战斗子图：`MoveMachine`、`AttackMachine`、`RollMachine`。
- `MoveMachine → AttackMachine`：`is_attacking() == true`。
- `MoveMachine → RollMachine`：`is_rolling() == true`。
- 攻击内部：`windup → active → recovery`，播完回 `MoveMachine`（`switch_mode = At End`）。
- 战斗身体片段目前只有 `down_left` / `down_right`。探索移动是八向。

blend 参数形如：

```text
parameters/StateMachine/Battle/AttackMachine/windup/blend_position
parameters/StateMachine/Battle/RollMachine/roll/blend_position
parameters/StateMachine/Normal/idle/blend_position
```

`Direction8.to_blend_position` 的 Y 向上为正。左下 `(-0.7, -0.7)`，右下 `(0.7, -0.7)`。

## 过渡

| 语义 | 设置 |
|---|---|
| 表达式成立就切 | `advance_mode = Auto`（2），`advance_expression` |
| 当前片段播完再切 | `switch_mode = At End`（2） |
| 立刻切 | `switch_mode = Immediate`（0） |

表达式在 AnimationTree 上求值（`advance_expression_base_node = NodePath(".")`）。`is_*()` 必须是 `PlayerAnimationTree` 的方法。

## `is_*()` 模板

把 `SKILL` / `SkillMachine` 换成规格里的名字。门闩用的节点名必须和动画树子状态机名一致。

```gdscript
## 只给 Battle 子图用；只查询不消费。本帧已在技能态时返回 false。
func is_skilling() -> bool:
	if _root_node_at_frame_start != &"Battle":
		return false
	if _battle_node_at_frame_start == &"SkillMachine":
		return false
	var action := PlayerActionType.get_action(PlayerActionType.ActionType.SKILL)
	if action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.ActionType.SKILL):
		return true
	return false
```

`INSTANT_ONLY` 删掉 `has_buffered` 那两行。`normal` 专用时，帧起点节点改成规格里的顶层节点，不要照抄 `&"Battle"`。

## 模式态模板

进入子状态机的第一帧消费缓冲并锁朝向。blend 路径做成常量，和 `battle.gd` 里 `_BLEND_ATTACK_*` 一样。

```gdscript
"SkillMachine":
	if _last_anim_node != &"SkillMachine":
		player.input_buffer.consume_buffered(PlayerActionType.ActionType.SKILL)
		_locked_action_dir = _resolve_action_direction(player, move_direction)
		_last_anim_node = &"SkillMachine"
	player.animation_tree.set(_BLEND_SKILL, _move_blend_from_direction(_locked_action_dir))
	player.velocity = Vector2.ZERO
	player.move_and_slide()
```

- 规格是 `direction8`：blend 用 `Direction8.to_blend_position(Direction8.from_vector(...))`，不要调用 `_move_blend_from_direction`（那个函数会折成左下/右下）。
- 规格是 `dash`：速度用锁定方向 × `move_speed` × 用户给的倍率，参照翻滚。
- 规格要出手：在用户指定的相位、且该次动作还没出手时调用 `player.attack_caster.slash(折算前的八向)`。先把 `slash_scene` 换成用户给的场景再出手。不要新挂一个 `AttackCaster`。

`mode_toggle` 不要消费缓冲。在对应 Limbo 态 `_enter` 里 `just_triggered.connect`，`_exit` 里断开。回调里检查规格规定的节点，再 `dispatch`。样板是 `battle.gd` 的 `_on_draw_sword`。

## GUIDE 与 Profile

`GUIDEAction` 字段：`name`、`action_value_type`（`BOOL=0`，`AXIS_1D=1`，`AXIS_2D=2`，`AXIS_3D=3`）、`is_remappable`、`display_name`、`display_category`。触发器放在映射项上，不写进行动资源。

映射项结构对齐 `keyboard_mouse.tres` 里现有的攻击/翻滚：

- 键盘：`GUIDEInputKey.key` = Godot `Key` 整数值
- 鼠标：`GUIDEInputMouseButton.button`（左键是默认键，右键是 `2`）
- 触发器：`GUIDETriggerPressed`
- 把新的 `GUIDEActionMapping` 放进上下文的 `mappings`

`BUFFERABLE` 的 Profile 条目是 `InputBufferProfileEntry` 子资源：`action_type` = 新枚举的序号（追加之后的那个整数），`buffer_frames` = 规格里的数。`policy` 默认就是 `BUFFERABLE`，与现有攻击/翻滚条目一致即可。不要把 `entries` 写成 `Array[ExtResource]` 空壳。

`InputBuffer` 只对非 `INSTANT_ONLY` 的条目连接 `just_triggered`。即时动作不要写进 Profile。

## 片段命名

方向后缀用八向名。前缀跟它加入的那组现有片段：

- 探索：`player_idle_<dir>`、`player_run_<dir>`、`player_run_start_<dir>`
- 战斗移动：`battle_idle_down_left`、`battle_walking_down_right`
- 攻击三段：`battle_attach_up_<windup|active|recovery>_down_<left|right>`
- 拔剑/收剑：`draw_sword_down_left`、`sheath_sword_down_right`
- 翻滚：`player_roll_left`、`player_roll_right`

新动作的前缀用规格里的片段名，不要改已有名字。
