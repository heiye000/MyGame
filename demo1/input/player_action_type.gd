class_name PlayerActionType
extends RefCounted

## 玩家行动枚举。新增行动时只需在此添加枚举值与对应资源路径。
enum Type {
	MOVE,
}

const _ACTIONS: Dictionary = {
	Type.MOVE: preload("res://input/actions/move.tres"),
}


static func get_action(type: Type) -> GUIDEAction:
	return _ACTIONS.get(type) as GUIDEAction
