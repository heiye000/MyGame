---
name: sprite-sheet-frame-annotator
description: Analyze a PNG sprite-sheet / frame-animation image, group frames into animations with ranges and facings, infer Y-sort anchor (YSortable2D sort_offset), and write a JSON manifest next to the PNG (same basename, .json). Use when the user hands over a sprite sheet PNG and asks to identify animations, map frame ranges, label orientations, Y-sort anchor, or "分析序列帧 / 帧动画分析 / 标注精灵表".
disable-model-invocation: true
---

# Sprite Sheet Frame Annotator

用户给一张 PNG 序列帧图，识别其中每段动画的**帧范围**与**朝向**，并解析 **Y 排序锚点**（对应 `YSortable2D.sort_offset`），把结果写成 JSON，存到 **与 PNG 同目录、同主名、`.json` 后缀** 的文件里（如 `bat.png` -> `bat.json`）。

帧索引约定：**0 基、行主序**（左上角为帧 0，从左到右、从上到下递增），与 Godot `Sprite2D.frame` 一致。

## 输出格式（严格遵守）

输出是一个 JSON **对象**，含 `grid`、`y_sort`、`animations` 三个顶层键。

```json
{
  "grid": {
    "hframes": 5,
    "vframes": 1,
    "帧宽": 16,
    "帧高": 24
  },
  "y_sort": {
    "sort_offset": [0, 1],
    "锚点": "脚底板中心（躯干底部，不含翅膀下摆）",
    "坐标系": "Sprite2D centered=true，相对宿主 CharacterBody2D 本地坐标",
    "参考帧": "0-2",
    "elevation": -8,
    "抬升说明": "飞行单位，排序 Y 额外抬升（可选，非飞行填 0）"
  },
  "animations": [
    {
      "动画": "bat_idle",
      "帧范围": "0-4",
      "朝向": "正面向镜头悬停拍翅（翅膀上下扇动循环）"
    }
  ]
}
```

### 字段说明

| 键 | 类型 | 说明 |
|----|------|------|
| `grid.hframes` / `grid.vframes` | int | 精灵表网格，与 `Sprite2D.hframes/vframes` 一致 |
| `grid.帧宽` / `grid.帧高` | int | 单帧像素尺寸 = 图宽/hframes、图高/vframes |
| `y_sort.sort_offset` | `[x, y]` | 排序锚点，直接对应 `YSortable2D.sort_offset`（像素，可含小数） |
| `y_sort.锚点` | string | 锚点语义，如「脚底板中心」「贴地根部中心」 |
| `y_sort.坐标系` | string | 写清假设，默认 `Sprite2D centered=true，相对宿主 CharacterBody2D 本地坐标` |
| `y_sort.参考帧` | string | 测算锚点用的帧范围（含两端，0 基）；多帧动画取稳定姿态帧 |
| `y_sort.elevation` | number | 可选，对应 `YSortable2D.elevation`；地面单位填 `0` |
| `y_sort.抬升说明` | string | 可选，解释 elevation 用途 |
| `animations[]` | array | 动画段列表，每段含 `动画` / `帧范围` / `朝向` |

`帧范围` 是 `"起-止"`（含两端，0 基）。

## 工作流

复制此清单并逐步跟踪：

```
Annotate Progress:
- [ ] Step 0: 定位 PNG 并读取像素尺寸
- [ ] Step 1: 确定网格 (hframes × vframes) 与帧编号
- [ ] Step 2: 视觉识别动画分段、帧范围、朝向
- [ ] Step 3: 解析 Y 排序锚点 (sort_offset)
- [ ] Step 4: 写出同名 .json
- [ ] Step 5: 自检
```

### Step 0 — 定位 PNG 与尺寸
- 确认 PNG 绝对路径。用 `Read` 工具打开图片（视觉分析）。
- 取像素宽高：优先用 Godot MCP 加载资源；或用脚本读 PNG IHDR。若拿不到精确尺寸，进入 Step 1 用视觉估算并向用户确认。

### Step 1 — 确定网格
- 序列帧多为等宽等高单元格。推断 `hframes`（每行帧数）、`vframes`（行数）：`帧宽 = 图宽/hframes`，`帧高 = 图高/vframes`。
- 单行图 `vframes = 1`。
- 帧号 = `row * hframes + col`（0 基）。
- 网格不明显或非等分时，**停下询问用户** `hframes`/`vframes`，不要臆测。
- 将结果写入 `grid` 段。

### Step 2 — 识别动画与朝向
- 逐帧观察，按「同一动作的连续帧」聚成一段动画。相邻且姿态连续渐变的帧属于同一段。
- 命名 `动画`：沿用文件语义 + 朝向后缀，如 `<basename>_<direction>`（`attack_L_right`）。若图内含多动作，用动作名前缀。
- `朝向` 用中文自然语言描述观察到的朝向/动作，示例词汇：`侧身朝右` / `侧身朝左` / `背对镜头向上挥砍` / `正面向下挥砍`。看到镜像/专用左向帧时如实注明。
- `帧范围` 写该段的首帧-末帧（0 基，含末帧）。

### Step 3 — 解析 Y 排序锚点

目标：得出 `y_sort.sort_offset`，供场景 `YSortable2D` 直接读取。

**坐标系假设（默认，与 demo1 一致）：**
- `Sprite2D.centered = true`（Godot 默认），精灵中心落在宿主（通常 `CharacterBody2D`）原点。
- `sort_offset` = 锚点相对宿主原点的本地偏移；x 向右为正，y 向下为正。

**锚点语义（按实体类型选）：**

| 实体类型 | 锚点 | 测算方式 |
|----------|------|----------|
| 行走单位（人形/兽形） | 脚底板中心 | 躯干中心列最底不透明像素 |
| 飞行单位 | 悬停点/躯干底部中心 | 躯干中心列最底像素，**不含**翅膀/尾翼下摆 |
| 场景静物（树/草丛） | 贴地根部中心 | 树干/草丛贴地行中心列 |
| 无明确脚点 | 碰撞底边中心 | 可视内容底边中心或用户指定 |

**像素测算步骤：**
1. 在 `参考帧` 内扫描（优先 idle/站立等**姿态稳定**的帧，避开武器/翅膀极值帧）。
2. 取帧内**水平中心附近**（中心列 ±1px）从上往下找躯干/脚底最后一个不透明像素行 `foot_y`（忽略左右展开的翅膀/特效尖角）。
3. 帧内像素 → 宿主本地坐标：
   - `sort_offset.x = 0`（脚底中心时 x 通常为 0）
   - `sort_offset.y = foot_y - 帧高/2`
4. 多帧 idle 略有差异时，取稳定帧的值，不用翅膀完全下压的极值帧。
5. `elevation`：飞行/悬浮单位标负值（如 `-8`），地面单位填 `0`；用户有明确要求时以用户为准。

拿不准锚点语义时，**停下询问用户**，不要臆测。

### Step 4 — 写出 JSON
- 路径 = PNG 同目录、同主名、扩展名换成 `.json`。
- 内容为 `grid` + `y_sort` + `animations` 对象；UTF-8，中文原样。

### Step 5 — 自检
- 各段 `帧范围` 不重叠、不超出 `hframes*vframes-1`。
- 段的顺序按帧号升序。
- `animations` 每项键名严格为 `动画`/`帧范围`/`朝向`，值类型为字符串。
- `y_sort.sort_offset` 为长度 2 的数值数组；`参考帧` 落在 `grid` 范围内。
- `sort_offset.y` 应落在 `[-帧高/2, +帧高/2]` 附近（脚点通常在帧下半部，y 多为正小值）。
- 向用户报告：JSON 路径 + 动画段数 + `sort_offset` 值。

## 坑位
- 帧号是 0 基还是 1 基：本技能固定 **0 基**，与 Godot `Sprite2D.frame` 对齐；勿改。
- 多行精灵表：帧号跨行按行主序连续累加，别按列。
- 空白/占位帧：若某些单元格为空，仍占帧号，注明或跳过并在朝向里说明。
- 拿不准分段边界或网格：宁可询问用户，别输出错误范围。
- Y 排序锚点：翅膀/武器下摆会随动画下移，**不要用极值帧**的最低点当脚点；固定锚在躯干/脚底。
- `Sprite2D.centered=false` 时坐标换算不同——须在 `坐标系` 字段写明，并改用 `offset + 帧内像素` 公式。
