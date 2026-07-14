# Manifest Schema：静态物品流水线

Agent 把用户口述整理成下方 JSON，填进 `scripts/build_static_prop.gd` 顶部的 `MANIFEST`。

## 最小示例（可破坏草丛）

```json
{
  "name": "Grass",
  "sprite": "res://assets/world/grass.png",
  "shadow": {
    "preset": "small",
    "position": [0, 5],
    "scale": [1.9, 1.25]
  },
  "collision": {
    "enabled": true,
    "shape": "circle",
    "radius": 5.0
  },
  "destructible": {
    "enabled": true,
    "hurtbox": { "shape": "rect", "size": [12, 11], "position": [0, -0.5] },
    "die_effect": "res://scenes/world/ground_deco/effects/GrassDie.tscn"
  },
  "y_sort": {
    "sort_offset": [0, 5],
    "sort_priority": 3
  }
}
```

## 仅主图（其余用缺省）

```json
{
  "name": "Rock",
  "sprite": "res://assets/world/rock.png"
}
```

缺省：有圆碰撞 + 可破坏矩形受击区 + Y 排序脚底；**无阴影**；无销毁特效。

## 不可破坏静物（树/灌木）

```json
{
  "name": "Tree",
  "sprite": "res://assets/world/tree.png",
  "shadow": { "preset": "large", "position": [0, 21] },
  "collision": { "enabled": true, "shape": "circle", "radius": 11.0, "position": [0, 14] },
  "destructible": { "enabled": false },
  "y_sort": { "sort_offset": [0, 25], "sort_priority": 3 }
}
```

## 字段说明

| 键 | 类型 | 必填 | 说明 |
|----|------|------|------|
| `name` | string | 是 | 根节点名与文件名 `{Name}.tscn`（PascalCase） |
| `sprite` | string | 是 | 主图 `res://` 路径 |
| `shadow` | object \| null | 否 | 有则建 `Sprite2D_Shadow` |
| `shadow.texture` | string | 二选一 | 阴影图完整路径 |
| `shadow.preset` | string | 二选一 | `small` / `medium` / `large` |
| `shadow.position` | [x,y] | 否 | 默认 `[0, h/2]` |
| `shadow.scale` | [x,y] | 否 | 默认 `[1, 1]` |
| `collision.enabled` | bool | 否 | 默认 `true` |
| `collision.shape` | `"circle"` \| `"rect"` | 否 | 默认 `circle` |
| `collision.radius` | number | 否 | 圆：默认 `min(w,h)*0.35` |
| `collision.size` | [w,h] | 否 | 矩形尺寸 |
| `collision.position` | [x,y] | 否 | 碰撞形状本地偏移，默认 `[0,0]` |
| `destructible.enabled` | bool | 否 | 默认 `true` |
| `destructible.hurtbox` | object | 否 | Area2D 形状；默认贴图矩形 |
| `destructible.die_effect` | string | 否 | 销毁特效 `.tscn`；可空 |
| `destructible.script` | string | 否 | 默认 `res://scenes/world/ground_deco/DestructibleProp.gd` |
| `y_sort.sort_offset` | [x,y] | 否 | 默认 `[0, h/2]` |
| `y_sort.sort_priority` | int | 否 | 默认 `3` |
| `y_sort.elevation` | number | 否 | 默认 `0` |
| `output_dir` | string | 否 | 默认 `res://scenes/world/ground_deco/scene/` |
| `script_dir` | string | 否 | 默认 `res://scenes/world/ground_deco/` |

## 命名

- 场景 / 根节点：`PascalCase`（`Grass.tscn`、`Bush.tscn`）
- 目录：`snake_case`
- 禁止用主图路径当阴影；阴影必须单独声明
