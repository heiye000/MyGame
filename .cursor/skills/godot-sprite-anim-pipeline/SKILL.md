---
name: godot-sprite-anim-pipeline
description: Standard pipeline that turns a sprite-sheet PNG plus a structured manifest into multi-directional AnimationPlayer clips, an AnimationTree state machine, and matching player.gd driver code, executed through the godot-mcp execute_editor_script tool. Use when the user provides a sprite sheet and asks to generate directional idle/walk/attack animations, wire up an AnimationTree, or run the "动画流水线 / sprite animation pipeline / anim pipeline" workflow.
disable-model-invocation: true
---

# Godot Sprite Animation Pipeline

把「精灵图 PNG -> 多方向 AnimationPlayer 动画 -> AnimationTree 状态机 -> `player.gd` 驱动代码」固化为固定流程。执行手段是 `project-0-MyGame-godot-mcp` 的 `execute_editor_script`（在编辑器里跑完整 GDScript，数据驱动地建动画，无需手工连线）。

目标形态对齐 `demo1/player/player.tscn`：`AnimationTree(BlendTree) -> StateMachine -> { MoveMachine{idle, run}, AttackMachine{attack_L} }`，每个状态是一个 `BlendSpace2D`，方向靠 blend 坐标混合。

## 前置条件

1. 目标场景已在 Godot 编辑器中**打开**（脚本用 `EditorInterface.get_edited_scene_root()`）。
2. 场景里存在 `Sprite2D`（已设 `texture` 与 `hframes/vframes`）、`AnimationPlayer`、`AnimationTree` 三个节点，均为根节点直属子节点。
   - 缺 `AnimationTree` 时先用 godot-mcp 的 `create_node` 补建，再继续。
3. 用户已按 [manifest.schema.md](manifest.schema.md) 提供结构化清单（精灵图路径、grid、fps、方向、mirror、每个动作每方向的帧索引区间、transition 表达式）。

## 工作流

复制此清单并逐步跟踪：

```
Pipeline Progress:
- [ ] Step 0: 校验 manifest 与场景前置条件
- [ ] Step 1: 生成 AnimationPlayer 动画
- [ ] Step 2: 生成 AnimationTree 状态机
- [ ] Step 3: 生成/修补 player.gd 驱动代码
- [ ] Step 4: 校验
```

### Step 0 — 校验输入
- 确认 manifest 每个 `action.frames` 的方向集合能被「显式帧 + mirror 派生」覆盖 `directions`。
- 确认帧索引都落在 `hframes * vframes` 范围内。
- 用 `get_scene_tree` 确认三个必需节点存在。缺失则停下让用户补齐或用 `create_node` 补建 `AnimationTree`。

### Step 1 — 生成 AnimationPlayer 动画
读取 [scripts/build_animations.gd](scripts/build_animations.gd)，把顶部 `MANIFEST` 用用户清单填好，整段作为 `execute_editor_script` 的 `code` 执行。它遍历 `动作 × 方向`，为每个动画建 `Sprite2D:frame` 值轨道（离散更新，`time = i/fps`），mirror 派生方向额外加 `Sprite2D:flip_h` 轨道，全部塞进默认 `AnimationLibrary` 并存盘。
- 期望输出：`OK 动画数=<N>`，其中 `N = 1(RESET) + Σ(动作方向数)`。

### Step 2 — 生成 AnimationTree 状态机
读取 [scripts/build_animation_tree.gd](scripts/build_animation_tree.gd)，填好顶部 `CFG`（方向 blend 坐标、`move_states`、`attack_states`、三条 transition 表达式），整段作为 `execute_editor_script` 的 `code` 执行。它建 `BlendSpace2D` -> 子状态机 -> 顶层 `StateMachine` -> `BlendTree`，设置 `active=true`、`anim_player`、`advance_expression_base_node = NodePath("..")`，并初始化各 `blend_position` 参数。
- 拓扑固定为 move + attack；扩展（8 方向、多攻击态）见 [reference.md](reference.md)。

### Step 3 — 生成/修补 player.gd 驱动代码
以 [player_template.gd](player_template.gd) 为模板，按 manifest 对齐后写入目标脚本（`modify_script` 或直接编辑）：`match state_playback.get_current_node()` 分发到每个状态机的处理函数；`update_animation()` 写各状态的 `blend_position`（**y 轴取反**匹配 BlendSpace2D 坐标系）；`get_move_direction()` / `is_attacking()` 走现有 GUIDE `PlayerActionType`。

### Step 4 — 校验
用 `execute_editor_script` 读回校验（见 [reference.md](reference.md) 的校验片段）：
- `AnimationPlayer` 动画数 == 预期。
- 每个 `parameters/StateMachine/.../blend_position` 参数路径可 `get()` 到（非 null）。
- `AnimationTree.active == true`。
- 可选：`run_project` 冒烟测试，观察四方向 idle/walk 切换与攻击定身。

若失败，对照下方坑位表修复后重跑对应 Step。

## 坑位表

| 症状 | 原因 | 修复 |
|------|------|------|
| AnimationTree 不动 | `active == false` | 脚本已设 `tree.active = true`，确认没被覆盖 |
| 播放但精灵帧不变 | 轨道节点路径与实际不符 | manifest 的 `sprite_node` 必须等于场景里 Sprite 节点名 |
| `travel/advance` 不切换 | transition 无表达式或表达式基准节点错 | `advance_expression_base_node = NodePath("..")`，表达式里的 `is_attacking()`/`current_move_direction` 必须是 player 脚本成员 |
| 方向混合错乱 | blend 坐标 y 轴未取反 | `update_animation()` 传入 `Vector2(dir.x, -dir.y)` |
| left 动画不镜像 | 缺 `flip_h` 轨道 | manifest 的 `mirror` 配 `{"left":"right"}`，Step1 会自动加 flip 轨 |
| 攻击后卡住 | attack->move 无 AT_END 过渡 | 脚本已用 `SWITCH_MODE_AT_END`，确认攻击动画 `loop=false` |

## 资源
- 输入清单格式与完整示例：[manifest.schema.md](manifest.schema.md)
- blend 坐标约定 / transition 表达式 / 扩展点 / 校验片段：[reference.md](reference.md)
