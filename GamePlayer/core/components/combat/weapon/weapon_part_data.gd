## 武器上的一块，例如剑身或剑鞘。只描述图，以及哪些姿态要显示它。
class_name WeaponPartData
extends Resource

## 部件名字。切换显示时用它指定是哪一块。
@export var part_id: StringName = &""
## 图上的帧号。0 是第一帧。
@export var frame: int = 0
## 握点相对帧中心的偏移，用来把那一点放到挂载点原点。
@export var offset: Vector2 = Vector2.ZERO
## 要显示这块的姿态。没有该姿态则不挂。加姿态只加一行，不改这个脚本。
@export var pose_mounts: Array[WeaponPoseMount] = []


## 这个姿态要不要把这块挂到角色那个唯一的挂载点上。
func shows_in_pose(pose: StringName) -> bool:
	# 表里的行有时是带脚本的 Resource，写成 WeaponPoseMount 会在运行时中断。
	for entry in pose_mounts:
		if entry != null and entry.pose == pose:
			return true
	return false
