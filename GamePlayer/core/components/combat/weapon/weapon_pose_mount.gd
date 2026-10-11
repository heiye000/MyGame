## 某个姿态下要显示这块部件。表里没有该姿态，就不挂。
class_name WeaponPoseMount
extends Resource

## 姿态名字，由角色状态传入。脚本不列举合法值。
@export var pose: StringName = &""
