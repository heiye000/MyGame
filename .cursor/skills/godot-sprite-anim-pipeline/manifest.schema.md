# Manifest 输入契约

用户每次运行流水线只需提供这份结构化清单。字段直接映射到 Step1/Step2 脚本顶部的 `MANIFEST` / `CFG`。

## 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `sprite_sheet` | String | 精灵图资源路径，如 `res://assets/player/player.png` |
| `sprite_node` | String | 被驱动的 Sprite 相对 Player 根的路径，当前为 `CharacterBody2D/Sprite2D` |
| `anim_player` | String | AnimationPlayer 节点名，默认 `AnimationPlayer` |
| `anim_tree` | String | AnimationTree 节点名，默认 `AnimationTree` |
| `grid.hframes` | int | 精灵图横向帧数（= `Sprite2D.hframes`） |
| `grid.vframes` | int | 精灵图纵向帧数（= `Sprite2D.vframes`），单行图填 `1` |
| `fps` | float | 帧率，决定 `step = 1/fps`、`length = 帧数/fps` |
| `directions` | Array | 方向名列表，默认 `["up","down","left","right"]` |
| `direction_blend_positions` | Dict | 每个方向在 BlendSpace2D 的坐标（见 reference.md） |
| `run_blend_positions` | Dict | 可选，walk/run 用更靠边的坐标；缺省复用上一项 |
| `mirror` | Dict | 镜像派生，如 `{"left":"right"}`：left 用 right 帧 + `flip_h=true` |
| `actions[]` | Array | 每个动作定义，见下 |
| `machines` | Dict | AnimationTree 子状态机配置（Step2），见下 |
| `transitions` | Dict | 顶层 / Move 内部 transition 表达式 |
| `limbo` | Dict | 可选，LimboHSM 相关路径与模式态脚本目标 |

### action 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | String | 动作名，动画命名为 `<name>_<direction>`，如 `player_run_up` |
| `machine` | String | 归属子状态机：`MoveMachine` / `AttackMachine` / `RollMachine` 等 |
| `state` | String | 该动作在子机中的状态名；缺省用 `name`（如 `player_run` -> `run`） |
| `loop` | bool | 是否循环（run=true，idle/attack/roll=false） |
| `frames` | Dict | `方向 -> 帧索引数组`；未列出的方向由 `mirror` 派生 |

### machines（Step2）

每个 key 是顶层子状态机名。值：

| 字段 | 类型 | 说明 |
|------|------|------|
| `kind` | String | `move`（含 idle↔run）或 `oneshot`（播完回 End，再由顶层回 Move） |
| `states` | Dict | `状态名 -> 动画前缀`，如 `{"idle":"player_idle","run":"player_run"}` |
| `from_move_expr` | String | 可选；非 Move 机时，MoveMachine -> 本机的 advance 表达式 |

### transitions

| 键 | 默认值 | 含义 |
|----|--------|------|
| `idle_to_run` | `"get_move_direction().length() > 0.0"` | idle -> run |
| `run_to_idle` | `"get_move_direction().length() == 0.0"` | run -> idle |
| `move_to_attack` | `"is_attacking() == true"` | MoveMachine -> AttackMachine（也可写在 `machines.AttackMachine.from_move_expr`） |
| `move_to_roll` | `"is_rolling() == true"` | MoveMachine -> RollMachine |

> 表达式在 **AnimationTree（PlayerAnimationTree）** 上求值（`advance_expression_base_node = NodePath(".")`），因此 `get_move_direction()` / `is_attacking()` / `is_rolling()` 必须是 AnimationTree 脚本成员，**不是** `player.gd`。

### limbo（Step3 可选）

| 字段 | 说明 |
|------|------|
| `hsm_node` | 默认 `LimboHSM` |
| `initial_mode` | 默认 `NormalBattle`（相对 HSM 的子节点名） |
| `mode_script` | 模式态脚本路径，如 `res://scenes/player/state_machine/normal_battle.gd` |

## 完整示例（对齐 demo1/scenes/player 现状）

```json
{
  "sprite_sheet": "res://assets/player/player.png",
  "sprite_node": "CharacterBody2D/Sprite2D",
  "anim_player": "AnimationPlayer",
  "anim_tree": "AnimationTree",
  "grid": { "hframes": 60, "vframes": 1 },
  "fps": 10.0,
  "directions": ["up", "down", "left", "right"],
  "direction_blend_positions": {
    "up":    [0, 1],
    "down":  [0, -1],
    "left":  [-0.8, 0],
    "right": [0.8, 0]
  },
  "run_blend_positions": {
    "up":    [0, 0.8],
    "down":  [0, -0.8],
    "left":  [-1, 0],
    "right": [1, 0]
  },
  "mirror": { "left": "right" },
  "actions": [
    {
      "name": "player_idle", "machine": "MoveMachine", "state": "idle", "loop": false,
      "frames": { "up": [42], "down": [54], "right": [30] }
    },
    {
      "name": "player_run", "machine": "MoveMachine", "state": "run", "loop": true,
      "frames": {
        "up":    [18, 19, 20, 21, 22, 23],
        "down":  [12, 13, 14, 15, 16, 17],
        "right": [0, 1, 2, 3, 4, 5]
      }
    },
    {
      "name": "player_attack", "machine": "AttackMachine", "state": "attack_L", "loop": false,
      "frames": {
        "up":    [28, 29, 30, 31],
        "down":  [36, 37, 38, 39],
        "left":  [32, 33, 34, 35],
        "right": [24, 25, 26, 27]
      }
    },
    {
      "name": "player_roll", "machine": "RollMachine", "state": "roll", "loop": false,
      "frames": {
        "up":    [45, 46, 47, 48, 49],
        "down":  [40, 41, 42, 43, 44],
        "right": [50, 51, 52, 53, 54]
      }
    }
  ],
  "machines": {
    "MoveMachine": {
      "kind": "move",
      "states": { "idle": "player_idle", "run": "player_run" }
    },
    "AttackMachine": {
      "kind": "oneshot",
      "states": { "attack_L": "player_attack" },
      "from_move_expr": "is_attacking() == true"
    },
    "RollMachine": {
      "kind": "oneshot",
      "states": { "roll": "player_roll" },
      "from_move_expr": "is_rolling() == true"
    }
  },
  "transitions": {
    "idle_to_run": "get_move_direction().length() > 0.0",
    "run_to_idle": "get_move_direction().length() == 0.0"
  },
  "limbo": {
    "hsm_node": "LimboHSM",
    "initial_mode": "NormalBattle",
    "mode_script": "res://scenes/player/state_machine/normal_battle.gd"
  }
}
```

> 上表 `frames` 仅为示意；以用户当次提供的帧索引为准。`idle`/`run`/`roll` 可省略 `left`，由 `mirror` 从 `right` 派生。
