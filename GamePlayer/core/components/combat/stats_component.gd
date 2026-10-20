## 角色共用属性。玩家和敌人都挂这一份，移速、攻击等数字不写在各自脚本上。
class_name StatsComponent
extends Node

## 攻击力；Hitbox 命中时来这里取，不把数字写在判定盒上。
@export var attack: int = 1
## 移动速度（像素/秒）。探索态直接用；战斗态再乘 `battle_move_speed_scale`。
@export var move_speed: float = 100
## 战斗态行走速度相对 `move_speed` 的倍率。
@export var battle_move_speed_scale: float = 0.8
