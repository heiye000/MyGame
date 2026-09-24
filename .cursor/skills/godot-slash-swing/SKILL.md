---
name: godot-slash-swing
description: Builds or updates an 8-direction slash VFX as its own scene (AnimationPlayer frame tracks plus hit polygons on a Hitbox) extending SlashSwing, mirroring right/up_right/down_right by flipping Body. Use when the user asks to add or update a slash, swing VFX, 刀光, attack_left, or to bind a new attack the way ATTACK_L spawns attack_left_1. Requires a sprite sheet with left, up_left, down, down_left, and up.
disable-model-invocation: true
---

# 刀光场景

把刀光做成独立场景：角色攻击动画不带伤害，伤害多边形跟刀光贴图走。样板是 `GamePlayer/core/components/combat/attack/attack_left_1.tscn`。共用前移在 `SlashSwing`，每把刀一个子类，只负责翻转。

方向名只用 `up, up_right, right, down_right, down, down_left, left, up_left`。

## 硬性约定

- 实绘至少要有 `left`、`up_left`、`down`、`down_left`、`up`。缺 PNG 或缺其中任一朝向：**停下**，不要做场景、不要改输入。
- `right`、`up_right`、`down_right` 不画进动画，由 `Body.scale.x = -1` 镜像。不要翻根节点，不要用 `Sprite2D.flip_h`。
- 伤害只在刀光的 `Body/Hitbox/CollisionPolygon2D`。角色、NPC、敌人的攻击动画不写伤害多边形。
- 没说明这刀怎么挥、要不要新按键：场景可以做完，输入相关文件一个都不要改，并告诉用户之后补什么。
- 用户没说末帧判定时，每条方向动画的最后一帧 `polygon` 为空。
- 场景里 `CollisionPolygon2D` 的初始 `polygon` 为空。判定只出现在动画键上。`attack_left_1.tscn` 里那份 up 顶点是旧数据，更新该场景时清掉，不要照抄。
- 有效帧是「共用一张多边形」还是「每帧各描一张」：写动画之前先问用户。没得到回答就停下，不要默认。
- `can_be_blocked` 和 `can_be_perfect_parried` 必须写在该 Hitbox 的 `.tscn` 里，两个都是 `true` 也要写上。存盘被编辑器省掉时，手工补回这两行。
- 用户没说前移速度时，所用 `AttackCaster.advance_speed = 0`（停在出手点）。不要用脚本默认的 `24`。
- 出手位置与删除跟 `AttackCaster.slash()`：`脚底 + spawn_offset + 瞄准 × spawn_distance`（`spawn_distance` 默认 `16`），`z_index = 1`，`animation_finished` 接 `queue_free.unbind(1)` 且 `CONNECT_ONE_SHOT`。
- 刀光方向是进攻击时锁住的完整八向，取身体折成左下/右下之前的那个。不要把身体 blend 传给 `slash()`。
- 第二把刀仍用现有那一个 `AttackCaster`，出手前换成这把刀的 `slash_scene` 再 `slash()`。不要再挂一个发射器。
- 新建 GUIDE 行动前先问 `action_value_type`。不要擅自写成 `2` 或 `0`。现有 `attack_l.tres` 是 `2`（`AXIS_2D`），`BOOL` 是 `0`。
- 刀光必须 `add_child` 到出手者下面。`Hitbox` 靠往上找 `StatsComponent` 才扣血；挂到别处就只有判定、没有伤害。
- 出手者攻击动画上的 `Hitbox` 多边形轨道删掉，不要留空键充数。节点上的 `polygon` 也保持空。

## 进度

```
Slash Progress:
- [ ] Step 1: PNG 五向齐全，否则停止
- [ ] Step 2: 用法 / 按键。没有描述就记一笔，继续做场景
- [ ] Step 3: 先问有效帧多边形怎么做，再描边并写入 AnimationPlayer
- [ ] Step 4: 子类只翻 Body；格挡 / 弹反写在这把刀的 Hitbox 上
- [ ] Step 5: 确认出手者动画没有攻击判定
- [ ] Step 6: 按验收表重读产物，不对就改，再查，直到一致
```

### Step 1 — 贴图

确认 PNG 绝对路径，读像素尺寸。同目录同名 `.json`（`sprite-sheet-frame-annotator` 的产物）若存在，用它的 `grid` 和 `animations` 定网格与帧范围。`y_sort`、`ai_description`、`ai_description_cn` 与刀光场景无关，跳过。

没有标注时：宽必须整除 `hframes`，高必须整除 `vframes`。一行一个朝向、且能对上五个方向名时，可以按视觉定帧范围。对不上、或网格不能整除：**停下问用户**，不要猜。

图里若多出朝右的三向，忽略那些帧，仍走镜像。

通过标准：五个方向名各自有一段不重叠的 0 基帧范围，且都落在 `hframes * vframes - 1` 以内。做不到就停。

`attach_left.png` 的帧表只作样板，见 [reference.md](reference.md)。新图不要照抄那张表的行序。

### Step 2 — 用法

先分清用户要的是哪一种：

| 用户说了什么 | 做什么 |
|--------------|--------|
| 更新已有刀光（点名 tscn / `attack_left_1`） | 只改那份场景。路径、`class_name`、节点名保持不变 |
| 新刀光，接到已有行动（例如仍是 `ATTACK_L`） | 做完场景后，把那个 `AttackCaster.slash_scene` 换成新场景 |
| 新刀光，并且要新按键 | 做完场景后，按 [reference.md](reference.md)「新按键清单」追加，对照 `ActionType.ATTACK_L` |
| 没写怎么用、也没提按键 | 不改 `Loader`、`PlayerActionType`、GUIDE、Profile、动画树、Limbo。回复里列出还要补的四项：谁挥、接哪个已有行动或哪颗新键、要不要预输入、出手者是玩家还是敌人 |

新按键不要插进已有枚举中间。预输入窗口按角色攻击动画时长估，不按刀光时长。刀光在攻击**有效段**才 `slash()`，样板是 `PlayerBattle` 里 `AttackMachine` 的 `active`。

### Step 3 — 动画与判定多边形

先问用户有效帧怎么做，二选一，得到回答再往下：

| 回答 | `CFG.polygon_mode` |
|------|--------------------|
| 有效帧共用一张，贴合刀光主体，末帧清空 | `shared` |
| 每个有效帧按该帧轮廓单独描，末帧清空 | `per_frame` |

1. 跑 [scripts/trace_slash_polygons.py](scripts/trace_slash_polygons.py)。`--map` 只含五个实绘方向，帧范围含两端。需要 Pillow。`--out` 写到临时文件，不要放进 `assets/`。
2. 脚本退出码不是 0，或 JSON 里 `ok` 不是 true：先看 `problems`。阈值不合适时改 `--alpha` 再跑。仍失败就停下，把失败的帧告诉用户，不要手填一个对不上刀光的多边形。
3. 填 [scripts/build_slash_scene.gd](scripts/build_slash_scene.gd) 顶部 `CFG`，`polygon_mode` 用上一步的回答。整段作为 Godot MCP `execute_editor_script` 的 `code`。子类 `.gd` 必须先落盘。`polygon_mode` 为空时脚本会报错退出。
4. 没指定帧率时 `fps = 8`（与 `attack_left_1` 一致）。用户给了音效路径就写上；没给就用 `res://assets/audio/swipe.wav`；明确要求无声则 `swing_sound` 留空字符串。
5. 期望输出以 `OK scene=` 开头。临时 JSON 在场景保存成功后删除。
6. 打开保存后的 `.tscn`，确认 Hitbox 上有 `can_be_blocked` 和 `can_be_perfect_parried`。被省掉就补上。确认 `CollisionPolygon2D` 的初始 `polygon` 是空数组。

每条方向动画两条离散轨道（`UPDATE_DISCRETE`）：

- `Body/Sprite2D:frame`
- `Body/Hitbox/CollisionPolygon2D:polygon`

描边脚本按每帧轮廓出点，并丢掉细碎火花。`polygon_mode = shared` 时，建造脚本把该方向第一张有效多边形铺到除末帧外的每一键。`per_frame` 时各键用各帧的轮廓；某一帧描失败才沿用上一张。末帧为空，除非用户明确要求保留。

坐标：`Sprite2D.centered = true`，多边形相对帧中心，x 右 y 下。

MCP 不可用时，按 `attack_left_1.tscn` 的轨道格式手写 `.tscn`，键值用 JSON 里的 `polygons`。不要另造节点树。

### Step 4 — 子类与这把刀的开关

公共逻辑留在 `SlashSwing`：`advance_direction`、`advance_speed`、`get_hitbox()`、`get_animation_player()`、`_process` 里的前移。子类不要复制这些。

新文件放在 `GamePlayer/core/components/combat/attack/`。脚本 `snake_case.gd`，`class_name` 用 PascalCase，场景与脚本同名。

```gdscript
@tool
class_name AttackFoo
extends SlashSwing

const _MIRROR_FROM := {
	&"right": &"left",
	&"down_right": &"down_left",
	&"up_right": &"up_left",
}

## 按八向名播放。朝右的三个方向翻 Body，不另做动画。
func play_direction(direction_name: StringName) -> void:
	var body := get_node_or_null("Body") as Node2D
	var player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if body == null or player == null:
		return
	var mirrored := _MIRROR_FROM.has(direction_name)
	var anim: StringName = _MIRROR_FROM.get(direction_name, direction_name)
	body.scale.x = -1.0 if mirrored else 1.0
	player.play(anim)
```

`can_be_blocked`、`can_be_perfect_parried` 写在**这把刀**的 Hitbox 上（`build_slash_scene.gd` 的 CFG），并出现在 `.tscn` 文本里。用户指定了就用用户的值；没指定就都是 `true`，也要写进场景。不要改 `hitbox.gd` 的默认值。

节点路径若不是 `Body/Hitbox`，子类才重写 `get_hitbox()`。默认路径不要重写。

### Step 5 — 和出手者分开

`AttackCaster.slash()` 把刀光 `add_child` 到出手者下面。父链上要有 `StatsComponent`，伤害数字才取得到。不要把刀光挂到与出手者无关的节点上。

位置、前移、层、删除都由这个函数做，刀光场景不要自己做：

- `global_position = 出手者脚底 + spawn_offset + aim * spawn_distance`（默认距离 `16`）
- `z_index = 1`
- `advance_direction` 为这一刀的瞄准向量；用户没要前移时 `advance_speed = 0`
- `animation_finished` → `queue_free.unbind(1)`，`CONNECT_ONE_SHOT`

挥刀时机跟 `PlayerBattle`：进入攻击子机时用折之前的完整八向锁进方向；内层进入 `active` 才 `slash()`。不要在按键当帧或 windup 挥，也不要把已经折成左下/右下的身体朝向传进去。

第二把刀：出手前把现有 `AttackCaster.slash_scene` 换成这把刀的场景，再调用同一个 `slash()`。不新增 `AttackCaster` 节点。

出手者自己的攻击动画：删掉 `Hitbox/CollisionPolygon2D:polygon` 轨道。不要改成空数组留着。节点上若还有非空 `polygon`，清成空数组。不要靠人物动画打开 `monitoring`。

### Step 6 — 验收

重读刚写的 `.gd`、`.tscn`，以及 Step 2 如果动过的输入文件。每一条不过就改对应产物，然后整表再查一遍。

- 五个实绘方向都有动画；库里没有 `right` / `up_right` / `down_right`。帧范围不重叠、不越界。
- 每条方向动画：帧轨道与多边形轨道键数相同；末键多边形为空；其余键至少 3 点，且落在半帧宽高附近。`shared` 时这些有效键是同一份顶点。
- 节点上的初始 `polygon` 为空，不是某一向的静止刀形。
- 根节点 `scale` 为 `(1, 1)`。镜像只出现在子类里对 `Body.scale.x` 的赋值。
- 子类 `extends SlashSwing`，没有自己的 `_process`。`SlashSwing.play_direction` 仍是未实现警告，逻辑在子类。
- `.tscn` 的 Hitbox 上有 `can_be_blocked` 和 `can_be_perfect_parried` 两行，值与用户要求一致（未要求则为 true）。
- 出手者攻击动画里不再有 `Hitbox` 多边形轨道。没拿到用法说明时，输入与 `AttackCaster` 引用保持原样。
- 接到已有发射器时：未说明前移则 `advance_speed = 0`；`slash()` 用的是折之前的八向。
- 新按键时：先问过 `action_value_type` 才写 `.tres`。枚举在末尾。Profile 的 `entries` 是 SubResource 列表。挥刀发生在有效段，而不是按键当帧。仍用原来的 `AttackCaster`，只换 `slash_scene`。

向用户报告：场景路径、五向帧范围、`polygon_mode`、末帧是否清空、两个格挡开关的值。若 Step 2 被跳过，把待补的四项写在同一段里。
