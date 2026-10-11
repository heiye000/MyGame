
## 对于角色的统一描述词
Young male fantasy adventurer / light paladin, around 20 years old, slim and well-proportioned body, youthful appearance with a subtle warrior-like presence, fair natural skin, delicate and gentle facial features, calm, kind, reliable and slightly noble expression.
Bright golden blond short hair, fluffy and layered hairstyle, naturally tousled hair with several slightly raised strands, soft bangs spreading across the forehead. Warm golden-yellow base color, pale blond and light yellow highlights, darker golden-brown shadows for clear pixel-art volume and separation.
He wears a lightweight fantasy knight outfit dominated by white, light gray and silver-gray tones. A white long-sleeved inner garment is combined with subtle light silver-gray armor elements around the shoulders, upper torso and limbs. The armor should remain light and elegant rather than bulky or heavily plated, giving him the appearance of a young paladin, swordsman or heroic fantasy adventurer.
Small golden decorative accents appear around the outfit edges and armor details. Dark gray and charcoal pixels are used selectively for outlines, seams and visual separation.
A warm brown to dark-brown leather belt wraps around the waist, accompanied by small leather straps or accessories. The brown leather elements create contrast against the predominantly white clothing.
White or very light gray trousers, with subtle gray protective pieces or straps around the legs. Lightweight dark-brown or black-brown adventurer boots, avoiding oversized heavy metal boots.
Core color palette: golden blond hair, white clothing, pale silver-gray armor, warm dark-brown leather, charcoal-gray outlines, subtle golden accents.
Clean fantasy pixel-art character design, bright but controlled colors, readable silhouette, strong separation between major color areas, limited pixel shading, carefully placed highlights and shadows, no realistic textures, no excessive ornamentation, game-ready ARPG sprite aesthetic.

Low 3/4 top-down ARPG perspective, 50–55° camera elevation looking downward. Visible top surfaces of hair, shoulders and pauldrons, moderate vertical foreshortening, upright readable silhouette, not pure overhead.

## 概念图约束词
头和身体的比例采用1比4 , 人物的长宽比是2比1, 生成的图片背景透明,人物需要拥有 上/下/左/左上/左下 5种朝向的三视图
The ratio of head to body is 1 to 4, and the aspect ratio of the figure is approximately 2 to 1.transparent background.


## 记录概念图到像素图的流程
1.GPT尝试生成概念图,需要使用上面的概念图约束生成
2.将概念图中的人物正面图单独提取出来,并将统一将人物高度缩放至256, 需要锁定宽高比
3.pixelLab采用Image to pixel art 转化为更加符合像素风的图,并保持高度为136
4.通过rotate旋转8方向,然后生成characters
5.通过animation给人物增加一些基础的动画(比如idle,running)

## 角色
你是一个资深的2D像素风低俯视角arpg godot游戏开发者。我需要你帮我列出我要做的事情有哪些，然后一步一步教我如何完成。 你不要自己去修改，先列出所有需要做的事情，我说开始时先教我第一步，等我确认后再教第二步，直至结束

## 待办事项
1.角色换装
2.重置角色的现有动作，使其更加流畅，更换刀光特效资源
3.补齐上下左右四方向的攻击动作以及闪避动作
4.增加一个人形敌人用于调教打击感
5.更加真实的打击感
6.敌人AI行为
7.格挡、精准格挡，格挡反击，一个连招技能



## 当前正在开发中的模块步骤
定切割约定
格子大小、脚底锚点、每一层画哪些像素（脸和头发留在躯干，卸掉头盔还有头）、哪些朝向手绘、哪些用水平翻转、四层的前后顺序。
完成：约定写下来，后面每张图都按它切。

选一条片段试拆
用现有的一条动画（建议待机朝下），在原图上分成四层，整格导出四张图。不按层各自裁切。
完成：四张图和原来的格子、帧数、锚点一致，叠回去就是现在的角色。

在玩家场景里摆四个精灵
在现有 Sprite2D 旁边加头盔、躯干、鞋子、武器四个 Sprite2D，位置与身体重合，用相对 z_index 分前后。原来的 Sprite2D 先留着，动画仍打在它上面。
完成：场景里能看到四个空精灵，游戏行为与现在相同。

让四层跟着身体帧走
身体换贴图、帧号、水平翻转时，四层抄同一帧；用一张对照表把「身体这张图」对应到「这一件装备的四张图」。
完成：只接上试做那一条时，四层和身体同步，不晚一帧、不错格。

只验证这一条
进游戏看试做片段：对齐、翻转、脚底没漂。不对就回到第 2 步改导出，不开始拆别的图。
完成：这一条叠上去和拆之前看起来一样。

按同一约定拆完现有全部片段
AnimationPlayer 里已经有的待机、走跑、翻滚、拔剑、攻击等，每条都导出四层。帧数或格子和身体不一致的，整条重导。
完成：每条现有动画都有四张同布局的图。

登记其余片段并关掉整身显示
对照表补全。四层齐了之后，原来的整身 Sprite2D 不再画出来（动画轨道仍可驱动它，只是不显示）。
完成：所有现有动作都由四层拼出来，没有整身图叠在上面。

补朝向遮挡和空槽
面朝下武器在身体前，面朝上在身体后。某一槽没有装备时隐藏该层（头仍在躯干上）。
完成：八向里武器前后正确；卸掉头盔、武器后，人还在，只是少了那一层。

全动作走查
把现有动作逐个看一遍：对齐、翻转、遮挡、空槽。
完成：和拆之前是同一个人，只是变成了四层。


### 角色动作提示词模板 
角色动作提示词模板
All directional terms are relative to the character’s current facing direction.
“Forward” means toward the current facing direction, “backward” means the opposite direction, and left/right refer to the character’s own left/right.

A pixel ARPG battle animation pose,
a 【character type】 wielding a 【weapon】 performing 【action name】,
starting from 【starting pose relative to the current facing direction】,
transitioning into 【motion process relative to the current facing direction】,
captured at the moment of 【impact / swing / strike / landing】,
body weight 【leaning toward the current facing direction / leaning opposite the current facing direction / lowered / airborne】,
arms 【arm pose】,
legs 【leg pose relative to the current facing direction】,
weapon motion arc 【vertical slash / character-relative horizontal slash / character-relative diagonal slash / thrust toward the current facing direction / spinning slash】,
emphasizing 【power / speed / explosive force / sharpness / aggression】,
clear action silhouette, strong readability, exaggerated combat pose,
suitable for pixel-style ARPG sprite animation.

动作描述规则调整
1. 动作类型
   待机、跑步、攻击、下劈、横斩、上挑、突刺、冲刺斩、跳斩、蓄力斩、受击、倒地、施法、闪避。这里本身通常不需要方向转换。
2. 起手姿态
   原来的“身前、向前、踏前”等改成相对当前朝向：
   双手持剑举于当前朝向一侧的身前、单手持剑侧身蓄力、双手高举过头顶、身体下沉准备爆发、身体朝当前面向方向俯身准备突进、一只脚朝当前面向方向踏出稳定重心。
3. 动作过程
   短暂蓄力后迅速挥下不变；
   朝当前面向方向踏步同时挥砍；
   扭转腰部带动手臂斩击；
   借助身体下压完成重斩；
   身体旋转带出回旋斩击；
   朝当前面向方向前冲，同时向当前面向方向突刺命中目标。
4. 关键定格瞬间
   挥下瞬间、命中瞬间、蓄力完成瞬间、腾空下砍瞬间、落地收势瞬间，这些不需要方向转换。
5. 重心与姿态
   重心朝当前面向方向压出；
   身体朝当前面向方向倾斜；
   身体先朝当前面向相反方向略微后仰，再朝当前面向方向爆发；
   下盘稳固、躯干扭转明显、双膝弯曲吸收冲击。
6. 武器轨迹
   从头顶上方朝身体下方竖直劈砍；
   从角色自身左侧向自身右侧横向斩击；
   从角色自身右上方向自身左下方斜劈；
   朝当前面向方向笔直突刺；
   围绕角色身体大幅回旋挥砍；
   从身体下方向上挑斩。
7. 动作表现重点
   高速、爆发、力量感、压迫感、敏捷、凌厉、果断、凶猛、干净利落，不需要方向转换。


最实用的“套壳格式”
你以后可以直接复制这个壳，然后替换里面的内容：
All directions are relative to the character’s current facing direction.

像素ARPG战斗动作，
【角色】使用【武器】做出【动作名称】，
起手【相对于当前朝向的起手姿态】，
随后【相对于当前朝向的动作过程】，
定格在【关键动作瞬间】，
身体【相对于当前朝向的重心状态】，
手臂【手臂姿态】，
双腿【相对于当前朝向的腿部姿态】，
武器轨迹【以角色自身方向为基准的攻击轨迹】，
强调【力量感 / 速度感 / 爆发感】，
整体气质【凌厉 / 果断 / 凶猛 / 迅捷】，
轮廓清晰，动作夸张明确，适合像素ARPG角色动画表现。

示例:
按你刚才那个“唐竹下劈”做示范
中文版

所有方向均以角色当前朝向为基准。

像素ARPG战斗动作，
角色双手持剑做出唐竹式下劈，
起手双手高举长剑过头顶，身体略微朝当前面向相反方向后仰蓄力，
随后迅速朝当前面向方向踏步，并将长剑从头顶上方朝身体下方猛烈劈落，
定格在下劈命中的瞬间，
身体重心明显朝当前面向方向压出，
双臂全力向下挥砍，
一条腿朝当前面向方向踏出，另一条腿留在相反方向稳定支撑，
武器轨迹为从头顶上方朝身体下方的笔直竖劈，
强调爆发感、力量感和压迫感，
整体气质凌厉果断，
轮廓清晰，动作夸张明确，适合像素ARPG战斗动画表现。

英文关键词版
All directions are relative to the character’s current facing direction.

pixel ARPG battle pose, two-handed sword overhead slash,
sword raised high above the head, slight wind-up opposite the current facing direction,
stepping toward the current facing direction into a powerful overhead downward strike,
captured at the impact moment,
body weight driven toward the current facing direction,
both arms driving the blade downward,
one leg toward the current facing direction and the other opposite for stability,
clear vertical slash from above the head downward,
strong power, explosive force, intense pressure,
sharp and decisive combat pose,
clear silhouette, readable sprite action,
suitable for pixel action RPG animation