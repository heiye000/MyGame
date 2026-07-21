class_name PlayerActionType
extends RefCounted

## 玩家行动枚举。新增行动时只需在此添加枚举值与对应资源路径。
enum Type {
	MOVE, 	#移动
	ATTACK_L, #攻击-左
	ROLL, #翻滚
}

const _ACTIONS: Dictionary = {
	Type.MOVE: preload("res://core/components/input/res/actions/move.tres"),
	Type.ATTACK_L: preload("res://core/components/input/res/actions/attack_l.tres"),
	Type.ROLL: preload("res://core/components/input/res/actions/roll.tres"),
}

#获取动作配置
static func get_action(type: Type) -> GUIDEAction:
	return _ACTIONS.get(type) as GUIDEAction
