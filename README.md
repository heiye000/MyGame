
## 对于角色的统一描述词
Fixed low 3/4 top-down ARPG perspective, approximately 50–55° camera elevation, slightly behind the character, clear rear view with visible back, shoulders and upper body depth, moderate vertical foreshortening, consistent character proportions and ground projection. Keep the camera completely fixed across all animation frames and all character actions. Never rotate, tilt, zoom, or change the camera perspective. Never turn the character into a pure side view or front view.

young male paladin, Sir Xielude, 20 years old, tall and slender youthful body, handsome and noble young face, radiant golden blond hair, short golden blond hair, clear emerald green eyes, crystal-clear jade-like eyes, gentle sincere expression, naturally warm and friendly appearancea young holy knight from the Cloud Church, traditional chivalric spirit, upright and righteous, kind-hearted, trustworthy, polite and respectful, calm and disciplined, inexperienced but exceptionally talented warriorwearing a clean iron light knight armor, polished steel armor, elegant medieval knight design, golden sword at his waist, brown leather belt, refined knight equipmentconsistent character design, consistent face, consistent golden blond hair, consistent emerald eyes, consistent armor, consistent sword, consistent body proportions

consistent character design, consistent face, consistent golden blond hair, consistent emerald eyes, consistent armor, consistent sword, consistent body proportions

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