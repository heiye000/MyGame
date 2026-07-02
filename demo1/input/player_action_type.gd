class_name PlayerActionType
extends RefCounted

## 玩家行动枚举。新增行动时只需在此添加枚举值与对应资源路径。
enum Type {
	MOVE, 	#移动
	ATTACK_LEFT, #攻击-左

}

const _ACTIONS: Dictionary = {
	Type.MOVE: preload("res://input/actions/move.tres"),
	Type.ATTACK_LEFT: preload("res://input/actions/attack_left.tres"),
}


static func get_action(type: Type) -> GUIDEAction:
	return _ACTIONS.get(type) as GUIDEAction
