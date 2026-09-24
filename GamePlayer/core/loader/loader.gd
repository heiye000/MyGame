class_name Loader
extends Object

## 项目里需要 preload 的资源，统一在这里登记。
## 只走静态方法，不要 new（Object 不会自动释放）。

enum Id {
	ACTION_MOVE, # 玩家移动
	ACTION_ATTACK_L, # 玩家轻攻击
	ACTION_DRAW_SWORD, # 拔剑 / 收剑
	MAPPING_KEYBOARD_MOUSE, # 键盘鼠标映射方案
	SCENE_LOCK_MARKER, # 锁定标记场景
	ACTION_LOCK_SWITCH, # 软锁甩鼠标切目标
	ACTION_LOCK_HARD, # 硬锁定
}

const _RESOURCES: Dictionary = {
	Id.ACTION_MOVE: preload("res://core/components/input/res/actions/move.tres"),
	Id.ACTION_ATTACK_L: preload("res://core/components/input/res/actions/attack_l.tres"),
	Id.ACTION_DRAW_SWORD: preload("res://core/components/input/res/actions/draw_sword.tres"),
	Id.MAPPING_KEYBOARD_MOUSE: preload("res://core/components/input/res/contexts/keyboard_mouse.tres"),
	Id.SCENE_LOCK_MARKER: preload("res://core/components/lock/lock_marker.tscn"),
	Id.ACTION_LOCK_SWITCH: preload("res://core/components/input/res/actions/lock_switch.tres"),
	Id.ACTION_LOCK_HARD: preload("res://core/components/input/res/actions/lock_hard.tres"),
}


## 按枚举取出已 preload 的资源；没登记则报错并返回 null。
static func get_resource(id: Id) -> Resource:
	var res := _RESOURCES.get(id) as Resource
	if res == null:
		push_error("Loader: 未找到资源 %s。" % id)
	return res
