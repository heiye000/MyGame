---
name: godot-static-prop-pipeline
description: Pipeline that turns a static prop PNG into a reusable 2D top-down ground decoration scene (Sprite2D, optional shadow, StaticBody2D, YSortable2D, optional attackable Area2D + destroy script). Use when the user provides a static item image and asks to generate a prop scene, destructible grass/bush/rock deco, or run the "静态物品流水线 / static prop pipeline / ground deco pipeline" workflow.
disable-model-invocation: true
---

# Godot Static Prop Pipeline

把「静态物品 PNG → 独立 `.tscn` 场景」固化为固定流程。参考实现：`demo1/scenes/world/ground_deco/scene/Grass.tscn`（可破坏草丛）。

## 目标场景树（对齐 Grass）

```
PropName (Node2D)                    # 根；可破坏时挂 DestructibleProp 脚本
├── Sprite2D_Shadow                  # 可选：阴影图
├── Sprite2D                         # 必有：主图（centered=true）
├── StaticBody2D                     # 可选：阻挡碰撞
│   └── CollisionShape2D
├── YSortable2D                      # 必有：sort_offset 默认物体底部
└── Area2D                           # 可选：可攻击受击区
    └── CollisionShape2D
```

| 节点 | 必选 | 参数来源 |
|------|------|----------|
| `Sprite2D` | 是 | manifest `sprite` |
| `Sprite2D_Shadow` | 否 | manifest `shadow`（有则建） |
| `StaticBody2D` | 否 | `collision.enabled` |
| `YSortable2D` | 是 | 默认脚底；可覆盖 `y_sort` |
| `Area2D` + 销毁脚本 | 否 | `destructible.enabled` |

> **根节点约定**：统一用 `Node2D`（Grass 模式）。不要用 `StaticBody2D` 当根（Bush/Tree 旧写法），便于可选组件组合。

## 前置条件

1. 用户提供至少一张主图：`res://.../*.png`（单帧静态，非精灵表）。
2. 输出目录存在或可创建（默认 `res://scenes/world/ground_deco/scene/`）。
3. 项目已有 `res://core/components/ysort/YSortable2D.gd`。
4. 优先用 `user-godot_mcp` / `project-0-MyGame-godot-mcp` 的 `execute_editor_script` 跑生成脚本；MCP 不可用时直接写 `.tscn` + `.gd` 并让用户在编辑器刷新。

## 工作流

```
Pipeline Progress:
- [ ] Step 0: 收集 manifest、读贴图尺寸、定输出路径
- [ ] Step 1: 写/复用销毁脚本（若 destructible）
- [ ] Step 2: 生成 .tscn（节点 + 贴图 + 碰撞 + YSort）
- [ ] Step 3: 校验场景树与默认参数
```

### Step 0 — 收集输入

按 [manifest.schema.md](manifest.schema.md) 填清单。最少只要：

```json
{
  "name": "Grass",
  "sprite": "res://assets/world/grass.png"
}
```

缺省行为（对齐可破坏草丛）：

| 项 | 缺省 |
|----|------|
| `shadow` | 不建阴影节点 |
| `collision.enabled` | `true`，圆碰撞，半径 ≈ `min(w,h) * 0.35` |
| `destructible.enabled` | `true`，矩形受击区 ≈ 贴图尺寸 |
| `y_sort.sort_offset` | `Vector2(0, h/2)`（`centered` 时脚底） |
| `y_sort.sort_priority` | `3`（静物） |
| `output_dir` | `res://scenes/world/ground_deco/scene/` |
| `script_dir` | `res://scenes/world/ground_deco/` |

**阴影**：用户必须明确哪张图是阴影。可用路径，或预设名 `small` / `medium` / `large` → `res://assets/shadows/{name}_shadow.png`。

读贴图宽高 `w,h`（`Image.load` 或 `ResourceLoader.load` 后 `get_width/height`），后续碰撞与 Y 排序都基于此。

### Step 1 — 销毁脚本

仅当 `destructible.enabled == true`：

1. 若尚无通用脚本，从 [templates/DestructibleProp.gd](templates/DestructibleProp.gd) 落到 `script_dir`（文件名可用 `DestructibleProp.gd` 共享，或 `{Name}.gd` 仅当要定制）。
2. 优先复用已有 `DestructibleProp.gd`，避免每个道具复制一份。
3. `die_effect`：manifest 有路径则写入 `@export` / 场景属性；无则留空（只 `queue_free`）。
4. 销毁特效场景本身走独立「特效动画流水线」（AnimatedSprite2D + `animation_finished` → `queue_free`），本技能不生成特效。

### Step 2 — 生成场景

读取 [scripts/build_static_prop.gd](scripts/build_static_prop.gd)，顶部 `MANIFEST` 换成用户清单，整段作为 `execute_editor_script` 的 `code` 执行。

脚本会：

1. 新建 `Node2D` 根，名为 `name`
2. 按需挂销毁脚本与 `die_effect`
3. 可选建 `Sprite2D_Shadow`（先于主精灵，保证绘制在下）
4. 建 `Sprite2D`，赋主贴图，`centered = true`
5. 可选建 `StaticBody2D` + `CollisionShape2D`
6. 建 `YSortable2D`，写 `sort_offset` / `sort_priority`
7. 可选建 `Area2D` + `CollisionShape2D`，并在脚本 `_ready` 里连 `area_entered`
8. `PackedScene.pack` + `ResourceSaver.save` 到 `{output_dir}/{Name}.tscn`

**MCP 不可用时**：按 [reference.md](reference.md) 的 `.tscn` 骨架手写等价文件，贴图用 `ExtResource`，碰撞用 `SubResource`。

### Step 3 — 校验

- 根为 `Node2D`，名 = `name`
- `Sprite2D.texture` 指向主图
- 有阴影时存在 `Sprite2D_Shadow`，且 texture 为声明的阴影图（不是主图）
- `YSortable2D.sort_offset.y` ≈ `h/2`（未手写覆盖时）
- `collision` / `destructible` 开关与节点有无一致
- 可破坏：根脚本存在，且能拿到 `$Area2D`
- 期望打印：`OK prop=<Name> path=<tscn>`

## 坑位表

| 症状 | 原因 | 修复 |
|------|------|------|
| 人走进道具身后被挡错 | `sort_offset` 不在脚底 | 用 `Vector2(0, h/2)`；或用户给脚点 |
| 阴影盖住主图 | 阴影节点在 Sprite2D 之后 | 阴影必须是主精灵的**兄前**节点 |
| 砍不掉 | 无 Area2D 或未连信号 | `destructible.enabled`；脚本连 `area_entered` |
| 砍了没特效 | `die_effect` 空 | 填特效 `.tscn`，或接受仅销毁 |
| 碰撞太大/太小 | 默认半径不准 | manifest 覆盖 `collision.radius` / `shape` |
| Bush 根是 StaticBody2D | 旧场景 | 新场景一律 Node2D 根，本流水线勿复刻旧根 |

## 资源

- 输入清单：[manifest.schema.md](manifest.schema.md)
- 默认值 / `.tscn` 骨架 / 阴影预设：[reference.md](reference.md)
- 销毁脚本模板：[templates/DestructibleProp.gd](templates/DestructibleProp.gd)
- 编辑器生成脚本：[scripts/build_static_prop.gd](scripts/build_static_prop.gd)
