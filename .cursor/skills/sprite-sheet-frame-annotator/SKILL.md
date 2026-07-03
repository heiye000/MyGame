---
name: sprite-sheet-frame-annotator
description: Analyze a PNG sprite-sheet / frame-animation image, group its frames into named animations with frame ranges and facing directions, and write a JSON manifest next to the PNG (same basename, .json). Use when the user hands over a sprite sheet PNG and asks to identify animations, map frame ranges, label orientations, or "分析序列帧 / 帧动画分析 / 标注精灵表".
disable-model-invocation: true
---

# Sprite Sheet Frame Annotator

用户给一张 PNG 序列帧图，识别其中每段动画的**帧范围**与**朝向**，并把结果写成 JSON，存到 **与 PNG 同目录、同主名、`.json` 后缀** 的文件里（如 `attack_L.png` -> `attack_L.json`）。

帧索引约定：**0 基、行主序**（左上角为帧 0，从左到右、从上到下递增），与 Godot `Sprite2D.frame` 一致。

## 输出格式（严格遵守）

输出是一个 JSON 数组，每个元素三个键：`动画` / `帧范围` / `朝向`。`帧范围` 是 `"起-止"`（含两端，0 基）。

```json
[
  {
    "动画": "attack_L_right",
    "帧范围": "24-27",
    "朝向": "侧身朝右"
  },
  {
    "动画": "attack_L_up",
    "帧范围": "28-31",
    "朝向": "背对镜头向上挥砍"
  },
  {
    "动画": "attack_L_left",
    "帧范围": "32-35",
    "朝向": "侧身朝左（精灵表自带的左向专用帧）"
  },
  {
    "动画": "attack_L_down",
    "帧范围": "36-39",
    "朝向": "正面向下挥砍"
  }
]
```

## 工作流

复制此清单并逐步跟踪：

```
Annotate Progress:
- [ ] Step 0: 定位 PNG 并读取像素尺寸
- [ ] Step 1: 确定网格 (hframes × vframes) 与帧编号
- [ ] Step 2: 视觉识别动画分段、帧范围、朝向
- [ ] Step 3: 写出同名 .json
- [ ] Step 4: 自检
```

### Step 0 — 定位 PNG 与尺寸
- 确认 PNG 绝对路径。用 `Read` 工具打开图片（视觉分析）。
- 取像素宽高：优先用 `project-0-MyGame-godot-mcp` 加载资源；或跨平台脚本。若拿不到精确尺寸，进入 Step 1 用视觉估算并向用户确认。

### Step 1 — 确定网格
- 序列帧多为等宽等高单元格。推断 `hframes`（每行帧数）、`vframes`（行数）：`帧宽 = 图宽/hframes`，`帧高 = 图高/vframes`。
- 单行图 `vframes = 1`。
- 帧号 = `row * hframes + col`（0 基）。
- 网格不明显或非等分时，**停下询问用户** `hframes`/`vframes`，不要臆测。

### Step 2 — 识别动画与朝向
- 逐帧观察，按「同一动作的连续帧」聚成一段动画。相邻且姿态连续渐变的帧属于同一段。
- 命名 `动画`：沿用文件语义 + 朝向后缀，如 `<basename>_<direction>`（`attack_L_right`）。若图内含多动作，用动作名前缀。
- `朝向` 用中文自然语言描述观察到的朝向/动作，示例词汇：`侧身朝右` / `侧身朝左` / `背对镜头向上挥砍` / `正面向下挥砍`。看到镜像/专用左向帧时如实注明。
- `帧范围` 写该段的首帧-末帧（0 基，含末帧）。

### Step 3 — 写出 JSON
- 路径 = PNG 同目录、同主名、扩展名换成 `.json`。
- 内容为 Step 2 得到的数组，保持上面的键名与格式；UTF-8，`ensure_ascii=false` 等价（中文原样）。

### Step 4 — 自检
- 各段 `帧范围` 不重叠、不超出 `hframes*vframes-1`。
- 段的顺序按帧号升序。
- 键名严格为 `动画`/`帧范围`/`朝向`，值类型为字符串。
- 向用户报告：写出的 JSON 路径 + 识别出的动画段数。

## 坑位
- 帧号是 0 基还是 1 基：本技能固定 **0 基**，与 Godot `Sprite2D.frame` 对齐；勿改。
- 多行精灵表：帧号跨行按行主序连续累加，别按列。
- 空白/占位帧：若某些单元格为空，仍占帧号，注明或跳过并在朝向里说明。
- 拿不准分段边界或网格：宁可询问用户，别输出错误范围。
