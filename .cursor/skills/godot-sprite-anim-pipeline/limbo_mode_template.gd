## 已废弃。不要再复制本文件。
##
## 旧模板是单一 NormalBattle：根为 Node2D、子节点 CharacterBody2D、四向横轴优先、手写 Vector2(dir.x, -dir.y)。
## 现有玩家已经拆成两个模式态，基准脚本是：
## - limbo_normal_template.gd  → PlayerNormal（探索，完整八向）
## - limbo_battle_template.gd  → PlayerBattle（战斗，身体只播左下/右下，刀光另挥）
##
## 输入查询见 player_animation_tree_template.gd。
## 薄壳见 player_template.gd。
## 锁定、刀光、生命、受击的接线见 reference.md「战斗组件」。
