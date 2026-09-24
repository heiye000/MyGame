# 刀光接线对照

样板是 `attack_left_1`。新刀光复用这条链路，不另发明一套判定。

## 场景

```
AttackXxx (Node2D, 子类脚本, scale 保持 1)
├── Body (Node2D)                 # 只有这里允许 scale.x = -1
│   ├── Sprite2D                  # centered = true，不设 flip_h
│   └── Hitbox (hitbox.gd)
│       └── CollisionPolygon2D    # 初始 polygon 为空
└── AnimationPlayer               # RESET + left/down_left/down/up/up_left
```

| 项 | 样板 |
|----|------|
| 脚本 | `GamePlayer/core/components/combat/attack/attack_left_1.gd` |
| 场景 | `GamePlayer/core/components/combat/attack/attack_left_1.tscn` |
| 基类 | `GamePlayer/core/components/combat/attack/slash_swing.gd` |
| 出手 | `GamePlayer/core/components/combat/attack_caster.gd` |
| 贴图 | `GamePlayer/assets/sprites/effects/attach_left.png` |
| 网格 | `hframes = 4`，`vframes = 5`，帧 95×95 |
| 帧 | `left` 0-3，`down_left` 4-7，`down` 8-11，`up` 12-15，`up_left` 16-19 |
| 时间 | 8fps，`step = 0.125`，4 帧，`length = 0.5` |
| 末键 | 每条方向动画最后一键 `polygon` 为 `PackedVector2Array()` |

这张表的行序只属于 `attach_left`。新图以自己的帧范围为准，动画名仍用这五个方向名。

`AttackCaster.slash()` 负责下面这些，刀光场景不负责：

- 实例化后 `add_child` 到出手者下面（`Hitbox` 才能找到 `StatsComponent`）
- 位置 = 脚底 + `spawn_offset` + 瞄准方向 × `spawn_distance`（默认 `16`）
- `z_index = 1`
- `advance_direction` = 瞄准向量。用户没说前移时，发射器上的 `advance_speed = 0`
- 按出手者改 `collision_layer` / `collision_mask`
- `play_direction`
- `animation_finished` 接 `queue_free.unbind(1)`，`CONNECT_ONE_SHOT`。不要直接连 `queue_free`

方向在进入攻击子机时锁成完整八向，取身体折成左下/右下之前。`active` 才 `slash()`。

## 翻转

`attack_left_1.gd` 的 `_MIRROR_FROM`：

| 请求的方向 | 播放的动画 | `Body.scale.x` |
|------------|------------|----------------|
| `left` / `down_left` / `down` / `up` / `up_left` | 同名 | `1` |
| `right` | `left` | `-1` |
| `down_right` | `down_left` | `-1` |
| `up_right` | `up_left` | `-1` |

根节点不翻。`Sprite2D.flip_h` 不作为镜像手段。子类不重写 `_process`；前移留在 `SlashSwing`。

## 格挡开关

写在这把刀的 `Hitbox` 上，由 `DamageInfo.make` 读出：

- `can_be_blocked`：能否被格挡
- `can_be_perfect_parried`：能否被精确弹反

用户没指定时两个都设为 `true`。无论 true 还是 false，都要出现在该 Hitbox 的 `.tscn` 里。编辑器存盘若省掉与脚本默认相同的值，手工把这两行写回去。不要改 `hitbox.gd` 的默认值来迁就一把刀。

## 碰撞层

出手时以 `AttackCaster` 上的导出为准，覆盖刀光 Hitbox。

| 出手者 | `hit_layer` | `hit_mask` |
|--------|-------------|------------|
| 玩家 | `16`（PlayerHitbox，第 5 层） | `8`（EnemyHurtbox，第 4 层） |
| 敌人 | `32`（EnemyHitbox，第 6 层） | `4`（PlayerHurtbox，第 3 层） |

场景里的 Hitbox 先按玩家层摆（与 `attack_left_1` 相同）。敌人用自己的 `AttackCaster` 覆盖。

## 用法三种

**只换现有刀光的图和判定**（点名 `attack_left_1` 或已有 tscn）  
只改该场景的贴图、网格、动画、两个格挡开关。`class_name`、场景路径、节点名不动。不改输入。

**新场景，仍由已有行动挥出**（例如还是 `ATTACK_L`）  
做好新场景后，把对应 `AttackCaster.slash_scene` 指过去。玩家现成节点在 `player.tscn` 的 `AttackCaster`。不新增枚举。

**新按键**  
按下面的清单追加。枚举和 `Loader.Id` 只能加在末尾。`battle_buffer_profile.tres` 里 `action_type` 是枚举整数值，插到 `ATTACK_L` 前面会让旧条目错位。

缺用法说明时：上面三种都不要做。场景可以先交，并告诉用户还要补：谁挥、接到哪个已有行动或哪颗新键、要不要预输入、出手者是玩家还是敌人。

## 新按键清单

对照 `ATTACK_L`，按顺序改：

1. `GamePlayer/core/loader/loader.gd`  
   末尾加 `Id`，`_RESOURCES` 里 `preload` 新的 GUIDE 行动资源。
2. `GamePlayer/core/components/input/player_action_type.gd`  
   枚举末尾追加，`_ACTION_IDS` 对照到新的 `Loader.Id`。
3. 新的 `GUIDEAction` `.tres`  
   先问用户 `action_value_type`，再抄 `attack_l.tres` 并改这个字段。现有文件里攻击是 `2`（`AXIS_2D`），`BOOL` 是 `0`。不要替用户选定。改 `name` / `display_name` / `display_category`。
4. `GamePlayer/core/components/input/res/contexts/keyboard_mouse.tres`  
   只绑用户点名的键。样板 `AttackL` 是键盘 `J`（`key = 74`）加鼠标键，触发器是 `guide_trigger_pressed.gd`。用户没要鼠标就不要复制鼠标那条。
5. 需要预输入时：`GamePlayer/core/components/input/res/profiles/battle_buffer_profile.tres`  
   追加一条 `InputBufferProfileEntry` 的 `SubResource`。`entries` 必须是 `[SubResource(...)]`。`action_type` 用新枚举的整数值。`buffer_frames` 按**角色攻击动画**时长估算（`ceil(秒 × physics_fps) + 2～6`），不是按刀光时长。
6. `GamePlayer/core/components/input/input_buffer/input_buffer.gd`  
   `_action_label()` 加一支 `match`。
7. `GamePlayer/actors/player/player_animation_tree.gd`  
   新增 `is_*()`：顶层已是 `Battle`、本帧还没在该子机、`is_triggered() or has_buffered()`。禁止在这里 `consume_buffered()`。
8. 战斗态（样板 `GamePlayer/actors/player/state_machine/battle.gd`）  
   进入该子机时 `consume_buffered()`，并锁住折之前的完整八向。进入攻击有效段（样板是 `AttackMachine` 的 `active`）才 `slash()`。不要在按键当帧、也不要在 windup 挥刀。不要把左下/右下身体朝向传给刀光。
9. 探索态（`normal.gd`）  
   与 `ATTACK_L` 一样，进探索时 `clear` 这个行动的缓冲。
10. 仍用场景上现有的 `AttackCaster`。出手前把 `slash_scene` 换成这把刀，再调用 `slash()`。不新挂发射器。用户没说前移时 `advance_speed = 0`。`hit_layer` / `hit_mask` 按出手者填。
11. 出手者攻击动画：删除 `Hitbox/CollisionPolygon2D:polygon` 轨道。节点上的 `polygon` 保持空。

人物动画流水线（`godot-sprite-anim-pipeline`）只切角色精灵帧。它不生成刀光多边形，也不代替本技能。
