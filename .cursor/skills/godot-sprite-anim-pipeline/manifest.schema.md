# Manifest 输入契约

用户每次运行流水线只需提供这份结构化清单。字段直接映射到 Step1/Step2 脚本顶部的 `MANIFEST` / `CFG`。

## 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `sprite_sheet` | String | 精灵图资源路径，如 `res://ui/player/hero.png` |
| `sprite_node` | String | 被驱动的 Sprite 节点名（须与场景一致），如 `Sprite2D` |
| `anim_player` | String | AnimationPlayer 节点名，默认 `AnimationPlayer` |
| `grid.hframes` | int | 精灵图横向帧数（= `Sprite2D.hframes`） |
| `grid.vframes` | int | 精灵图纵向帧数（= `Sprite2D.vframes`），单行图填 `1` |
| `fps` | float | 帧率，决定 `step = 1/fps`、`length = 帧数/fps` |
| `directions` | Array | 方向名列表，默认 `["up","down","left","right"]` |
| `direction_blend_positions` | Dict | 每个方向在 BlendSpace2D 的坐标（见 reference.md） |
| `run_blend_positions` | Dict | 可选，walk/run 用更靠边的坐标；缺省复用上一项 |
| `mirror` | Dict | 镜像派生，如 `{"left":"right"}`：left 用 right 帧 + `flip_h=true` |
| `fps` 覆盖 | - | 如需逐动作不同帧率，见 reference.md 扩展点 |
| `actions[]` | Array | 每个动作定义，见下 |
| `transitions` | Dict | 三条 transition 表达式 |

### action 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | String | 动作名，动画命名为 `<name>_<direction>`，如 `walk_up` |
| `machine` | String | 归属状态机：`MoveMachine` 或 `AttackMachine` |
| `state` | String | 该动作在状态机中的状态名；缺省用 `name`（如 `walk` -> `run`） |
| `loop` | bool | 是否循环（walk/run=true，idle/attack=false） |
| `frames` | Dict | `方向 -> 帧索引数组`；未列出的方向由 `mirror` 派生 |

### transitions

| 键 | 默认值 | 含义 |
|----|--------|------|
| `move_to_attack` | `"is_attacking() == true"` | MoveMachine -> AttackMachine |
| `idle_to_run` | `"current_move_direction.length() > 0.0"` | idle -> run |
| `run_to_idle` | `"current_move_direction.length() == 0.0"` | run -> idle |

> 表达式基于 player 脚本成员求值（`advance_expression_base_node = NodePath("..")`），因此其中的方法/变量必须存在于 `player.gd`。

## 完整示例（对齐 demo1 现状）

```json
{
  "sprite_sheet": "res://ui/player/player.png",
  "sprite_node": "Sprite2D",
  "anim_player": "AnimationPlayer",
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
      "name": "idle", "machine": "MoveMachine", "state": "idle", "loop": false,
      "frames": { "up": [6], "down": [18], "right": [0] }
    },
    {
      "name": "walk", "machine": "MoveMachine", "state": "run", "loop": true,
      "frames": {
        "up":    [6, 7, 8, 9, 10, 11],
        "down":  [18, 19, 20, 21, 22, 23],
        "right": [0, 1, 2, 3, 4, 5]
      }
    },
    {
      "name": "attack_L", "machine": "AttackMachine", "state": "attack_L", "loop": false,
      "frames": {
        "up":    [28, 29, 30, 31],
        "down":  [36, 37, 38, 39],
        "left":  [32, 33, 34, 35],
        "right": [24, 25, 26, 27]
      }
    }
  ],
  "transitions": {
    "move_to_attack": "is_attacking() == true",
    "idle_to_run": "current_move_direction.length() > 0.0",
    "run_to_idle": "current_move_direction.length() == 0.0"
  }
}
```

> `idle`/`walk` 省略 `left`，由 `mirror` 从 `right` 派生（加 `flip_h`）。`attack_L` 显式给了四方向，不走镜像。
