## 一把武器的外观。玩家、NPC、敌人共用同一份，不写遮挡和坐标。
class_name WeaponVisualData
extends Resource

## 整张部件图。多块部件共用这一张。
@export var texture: Texture2D
## 横向有几格。
@export var hframes: int = 1
## 纵向有几格。
@export var vframes: int = 1
## 剑、鞘等部件。顺序不代表前后。
@export var parts: Array[WeaponPartData] = []
