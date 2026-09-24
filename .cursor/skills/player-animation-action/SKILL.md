---
name: player-animation-action
description: Wires a new player animation into the existing GUIDE action, AnimationTree, LimboHSM, and InputBuffer chain. Use when the user asks to add a character/player animation, bind an animation to a key, add an attack/roll/skill/draw-sheath clip, or add a facing to an existing BlendSpace (新增角色动画, 绑定按键, 加攻击/翻滚/技能). Collect every required parameter before editing. Do not use for questions that only ask how the current animation system works.
---

# 玩家动画接入

把「新动画 + 按键」接到现有玩家链上。键不调用 `AnimationPlayer.play()`。

```text
GUIDE 映射 → GUIDEAction →（可缓冲则 InputBuffer）
  → PlayerAnimationTree.is_*() 过渡表达式
  → AnimationTree 子状态机 + BlendSpace2D
  → PlayerBattle / PlayerNormal 写 blend、锁朝向、消费预输入
```

样板场景：`GamePlayer/actors/player/player.tscn`。代码模板见 [reference.md](reference.md)。

## 门闩

规格里该种类的每一项都有用户明确答案之前：

- 不改文件、不改场景、不调用会写入工程的工具
- 不替用户填默认值，不从「通常如此」推断
- 「你决定 / 随便 / 看着办 / 跟攻击一样」都不是答案。列出可选项再问

可以读文件，用来核对键位冲突、枚举重名、片段是否已存在。冲突写进要问的问题里。读文件不是执行。

缺什么就在一条消息里问齐。用户已经给出的参数原样列入「已确认」，只问缺口。

全部明确后：先写一小节「规格」，每项都能追溯到用户原话；下面「由此决定」只写机械后果。然后按执行清单做。不要再问「可以开始了吗」。

## 先定种类

只问下面三种之一。种类未定，不问后面的字段。

| 种类 | 何时 |
|---|---|
| `new_oneshot` | 新的一次性动作，要新按键。样板：攻击 |
| `new_direction` | 给已有 BlendSpace 补一个方向片段，不新加键 |
| `mode_toggle` | 切换 Limbo 模式，并播一段顶层过渡。样板：Q 拔剑/收剑 |

## 规格：`new_oneshot`

1. `action_type`：新枚举名，`SCREAMING_SNAKE`。不得与 `MOVE`、`ATTACK_L`、`ROLL`、`DRAW_SWORD`、`LOCK_SWITCH`、`LOCK_HARD` 或已有枚举重名。
2. GUIDE 资源文件名（`snake_case.tres`）、`name`、`display_name`、`display_category`。
3. `action_value_type`：`BOOL` / `AXIS_1D` / `AXIS_2D` / `AXIS_3D`。用户必须点名。按键攻击类常见是 `BOOL`；现有 `attack_l.tres` 是 `AXIS_2D`，不要照抄。
4. 触发器：是否 `Pressed`。
5. 键和/或鼠标键。读 `keyboard_mouse.tres`，已被占用的键要告诉用户并换键。
6. 哪个 Limbo 模式能发起：`battle` / `normal` / `both`。
7. 能否从移动以外的子状态机发起。现有攻击只从 `MoveMachine` 进入。
8. `buffer_policy`：`BUFFERABLE` 或 `INSTANT_ONLY`。模式不是 `battle` 时不能选 `BUFFERABLE`。要精确窗口（弹反）时用户必须另外说明，否则不要用 `WINDOW_GATED`。
9. `BUFFERABLE` 时：动画时长（秒）或直接给 `buffer_frames`。只给了秒，把 `ceil(秒 × 60) + 4` 算出来写进规格让用户看，这是展示不是另问一轮。
10. 身体片段有哪些方向。方向名只许 `up, up_right, right, down_right, down, down_left, left, up_left`。
11. 片段从哪来：已经在 `AnimationPlayer` 里的动画名，或精灵图路径 + `hframes`/`vframes` + 每个方向的帧索引 + fps。循环：一次性动作不循环。
12. 子状态机名（如 `SkillMachine`）和 BlendSpace 状态名（如 `skill`）。
13. 动作期间位移：`zero`（攻击）或 `dash`（按锁定方向冲刺）。`dash` 要速度倍率。
14. 身体朝向：`down_diagonal`（折成左下/右下，与现有战斗一致）或 `direction8`（八向都写 blend）。
15. 出手：`none`，或已有刀光场景路径 + 在哪个相位调用 `AttackCaster.slash()`。要做新刀光：本技能不建刀光，指向 `godot-slash-swing`，刀光场景路径未给出则这一项未明确，整单停下。

## 规格：`new_direction`

1. 加在哪个状态机的哪个 BlendSpace（例如 `Battle/AttackMachine/windup`）。
2. 方向名（同上，八向合法名）。
3. 片段来源：已有动画名，或精灵图 + 帧索引 + fps + 是否循环。
4. 目标若在战斗图，且该模式态用 `_move_blend_from_direction` 把朝向折成左下/右下：用户必须明确「同时改掉折叠，让这个方向能被写进 blend」或「只把片段放进树，接受现在播不出来」。

不改 GUIDE、`Loader`、`PlayerActionType`、`InputBuffer`。

## 规格：`mode_toggle`

1. `action_type`、GUIDE 资源名、`action_value_type`、触发器、键。约束同 `new_oneshot` 的 1–5。
2. 从哪个 Limbo 态到哪个 Limbo 态，事件名。
3. 允许切换时，顶层动画节点和战斗子节点必须是什么。拔剑样板：顶层是 `Normal` 才派发；收剑样板：顶层是 `Battle` 且子节点是 `MoveMachine`。
4. 顶层片段名、方向、片段来源、是否循环（过渡段不循环）。
5. 过渡期间位移。拔剑/收剑样板是速度零。
6. 不进 `InputBuffer`。动画树顶层表达式看的是 `is_battle()` / `is_normal()`，键本身用 `just_triggered` 派发 Limbo 事件。

## 由此决定（不要再问）

- 新 `ActionType` 追加在枚举末尾。禁止插在中间。`battle_buffer_profile.tres` 里的 `action_type` 是枚举序号，插在中间会把已有动作对错号。
- `BUFFERABLE` 只给 Limbo 战斗态。`InputBuffer` 仅在 `is_battle_mode()` 时写入，`PlayerBattle._exit` 调用 `clear_all()`。探索态不 `clear`。`normal` / `both` 不能选 `BUFFERABLE`。
- `is_*()` 只查询 `is_triggered()` 或 `has_buffered()`。进入子状态机的那一帧才 `consume_buffered()`。
- 本帧动画树已经停在该子状态机时，`is_*()` 返回 false。
- 战斗 `down_diagonal`：身体 blend 用 `Direction8.to_blend_position(Direction8.to_down_diagonal(...))`。若同时出手，`AttackCaster.slash()` 用折算之前的八向。
- 不改 `player.gd` 里 AnimationTree 的 `active`、`callback_mode_process`、`advance_expression_base_node`。

## 执行

复制清单并打勾。模板、路径、过渡属性见 [reference.md](reference.md)。

```
Progress:
- [ ] 规格已复述，且每项来自用户原话
- [ ] 资源与枚举（new_oneshot / mode_toggle）
- [ ] 键位映射，且没有占用已有键
- [ ] 预输入 Profile（仅 BUFFERABLE）
- [ ] AnimationPlayer 片段
- [ ] AnimationTree 状态、BlendSpace、过渡表达式
- [ ] PlayerAnimationTree.is_*()（仅 new_oneshot）
- [ ] 模式态 match、blend、消费或派发
- [ ] 确认探索态没有为这个动作写 `clear`
- [ ] 按验收表核对
```

脚本和 `.tres` 直接改。`player.tscn` 里的片段和动画树优先用 Godot MCP，在已打开的玩家场景上改。MCP 不可用时：资源与脚本仍要做完；动画树改动写成节点名、表达式、`switch_mode`，停下说明编辑器里还差什么。不要手改 `player.tscn` 里的子资源 id。

新 GDScript 遵守项目中文注释：新函数上方有 `##`，新成员一行说明用途。

## 验收

- 指定模式里按下新键，播指定片段，一次性动作播完回到该模式的移动/待机。
- `BUFFERABLE`：后摇内提前按，当前段结束后能接上。
- `battle` 专用：探索态按该键不排队，拔剑后不自动补放。
- 连按不出现 `looped transitions in a single frame`。
- 被占用的旧键行为不变。
- 出手项不是 `none` 时：刀光在用户指定的相位出现，方向是折算前的八向。

## 不做

- 不建刀光场景、不描伤害多边形（`godot-slash-swing`）。
- 不改相机、物理层、渲染层。
- 不把 `AnimationTree` 当成玩法状态机，不在按键回调里 `play()`。
