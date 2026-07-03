class_name PlayerActionType
extends RefCounted

## 玩家行动枚举。新增行动时只需在此添加枚举值与对应资源路径。
enum Type {
	MOVE, 	#移动
	ATTACK_L, #攻击-左
	ROLL, #翻滚

}

const _ACTIONS: Dictionary = {
	Type.MOVE: preload("res://input/actions/move.tres"),
	Type.ATTACK_L: preload("res://input/actions/attack_L.tres"),
	Type.ROLL: preload("res://input/actions/roll.tres"),
}


static func get_action(type: Type) -> GUIDEAction:
	return _ACTIONS.get(type) as GUIDEAction
