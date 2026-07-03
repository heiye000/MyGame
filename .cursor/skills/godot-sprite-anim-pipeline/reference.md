# Reference：坐标约定 / 表达式 / 扩展点 / 校验

## BlendSpace2D 方向坐标约定

BlendSpace2D 的 y 轴向上为正，而游戏输入 y 轴向下为正（`Vector2.DOWN = (0,1)`）。因此：
- **建树时**（Step2）blend 点坐标按 BlendSpace 坐标：`up=(0,1)`、`down=(0,-1)`、`left=(-0.8,0)`、`right=(0.8,0)`。
- **驱动时**（player.gd）传入 `blend_position` 前必须 y 取反：`Vector2(dir.x, -dir.y)`。

walk/run 常用更靠边的坐标（`±1` / `±0.8`）让方向切换更干脆，见 manifest 的 `run_blend_positions`。

## Transition 属性对照

| 语义 | 属性设置 | Godot 枚举 |
|------|----------|-----------|
| 表达式满足即自动切 | `advance_mode = AUTO` + `advance_expression = "..."` | `ADVANCE_MODE_AUTO = 2` |
| 播完当前动画再切 | `switch_mode = AT_END` | `SWITCH_MODE_AT_END = 2` |
| 立即切换 | `switch_mode = IMMEDIATE` | `SWITCH_MODE_IMMEDIATE = 0` |

表达式在 `advance_expression_base_node`（设为 `NodePath("..")`，即 player 节点）上求值，故 `is_attacking()`、`current_move_direction` 必须是 player 脚本成员。

## 生成的动画/参数命名

- 动画名：`<action.name>_<direction>`，如 `walk_up`、`attack_L_left`。
- blend 参数路径：`parameters/StateMachine/<machine>/<state>/blend_position`。
- 顶层播放控制：`parameters/StateMachine/playback`。

## 扩展点

### 8 方向
在 manifest 的 `directions` 加入 `up_left` 等，并在 `direction_blend_positions` 给出对角坐标（如 `up_right=(0.7,0.7)`）。Step2 脚本按 `directions` 循环 `add_blend_point`，无需改结构；player.gd 的 `update_animation` 用连续向量即可自动混合。

### 逐动作不同帧率
给 action 加 `fps` 字段，Step1 中把 `step` 改为 `1.0/float(action.get("fps", MANIFEST["fps"]))`。

### 多攻击态（attack_L / attack_R ...）
在 `attack_states` 增加 `{"attack_R": "attack_R"}`，并在顶层增加对应触发表达式与返回过渡；player.gd 的 `update_animation` 同步补对应 `blend_position` 写入。默认拓扑只连了 `first_attack`，多攻击态需按需扩展 AttackMachine 内部的选择逻辑。

### 非镜像 left
若 left 有独立帧（非 right 镜像），直接在该 action 的 `frames` 里给 `left`，并从 `mirror` 移除，即不生成 `flip_h` 轨。

## 校验片段（Step4，execute_editor_script）

```gdscript
var root = EditorInterface.get_edited_scene_root()
var ap = root.get_node("AnimationPlayer")
var tree = root.get_node("AnimationTree")
var names = ap.get_animation_list()
_custom_print("anim_count=" + str(names.size()))
_custom_print("tree_active=" + str(tree.active))
var paths = [
	"parameters/StateMachine/MoveMachine/idle/blend_position",
	"parameters/StateMachine/MoveMachine/run/blend_position",
	"parameters/StateMachine/AttackMachine/attack_L/blend_position",
]
for p in paths:
	_custom_print(p + " = " + str(tree.get(p)))
```

期望：`anim_count` 等于 `1 + Σ动作方向数`；`tree_active=true`；每个 blend_position 可取到 `Vector2`（非 `null`）。
