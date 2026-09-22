class_name PlayerActionType
extends RefCounted

## 玩家行动枚举。新增行动时：先在 Loader 登记资源，再在这里加枚举和对照。
enum ActionType {
	MOVE, # 移动
	ATTACK_L, # 攻击-左
	ROLL, # 翻滚
	DRAW_SWORD, # 拔剑、收剑
	LOCK_SWITCH, # 软锁甩鼠标切目标
	LOCK_HARD, # 硬锁定
}

## 行动所对应的资源是哪个
const _ACTION_IDS: Dictionary = {
	ActionType.MOVE: Loader.Id.ACTION_MOVE,
	ActionType.ATTACK_L: Loader.Id.ACTION_ATTACK_L,
	ActionType.ROLL: Loader.Id.ACTION_ROLL,
	ActionType.DRAW_SWORD: Loader.Id.ACTION_DRAW_SWORD,
	ActionType.LOCK_SWITCH: Loader.Id.ACTION_LOCK_SWITCH,
	ActionType.LOCK_HARD: Loader.Id.ACTION_LOCK_HARD,
}


## 取出该行动对应的 GUIDE 动作配置。
static func get_action(type: ActionType) -> GUIDEAction:
	if not _ACTION_IDS.has(type):
		push_error("PlayerActionType: 未找到行动 %s。" % type)
		return null
	return Loader.get_resource(_ACTION_IDS[type]) as GUIDEAction
