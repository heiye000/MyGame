## 可组合的 Y 排序组件。
## 挂在玩家、敌人、树木等实体下，由 [YSortManager] 统一读取并写入 z_index。
## 用法：添加为子节点 → 设置 [member host] 和 [member sort_offset] → 无需编写排序代码。
class_name YSortable2D
extends Node

## 排序锚点相对 [member host] 的偏移（像素）。
## 用法：将脚点（碰撞体底部或 Marker2D）的本地坐标填入；Y 值越大，显示越靠前。
@export var sort_offset: Vector2 = Vector2.ZERO
## 同 Y 值时的显示优先级（0~9，越大越靠前）。
## 用法：玩家/敌人建议 5，掉落物 2，场景静物 3；用于解决站在同一行时的遮挡争议。
@export_range(0, 9) var sort_priority: int = 5
## 排序 Y 的额外抬升量（像素）。负值表示更靠前（更靠近摄像机）。
## 用法：飞行单位或站在桥上时可设为负值，使其显示在更前方。
@export var elevation: float = 0.0
## 是否参与 Y 排序。
## 用法：死亡淡出、临时隐藏时可关闭，管理器将跳过此对象。
@export var enabled: bool = true
## 实际移动的宿主 [Node2D]；为空时自动使用父节点。
## 用法：玩家宿主为自身根 CharacterBody2D；树/箱子等拖入场景根 Node2D。
@export var host: Node2D


## 获取当前用于排序的宿主节点。
## 优先返回 [member host]；未设置时回退到父节点。
func get_host() -> Node2D:
	if host:
		return host
	return get_parent() as Node2D


## 计算用于排序的世界 Y 坐标。
## 公式：宿主 global_position.y + sort_offset.y + elevation。
func get_sort_y() -> float:
	var h := get_host()
	if h == null:
		var parent_node := get_parent() as Node2D
		if parent_node:
			return parent_node.global_position.y + sort_offset.y + elevation
		return sort_offset.y + elevation
	return h.global_position.y + sort_offset.y + elevation


## 计算最终排序键值（含优先级微偏移）。
## 管理器按此值从小到大排序，值越大 z_index 越高。
func get_sort_key() -> float:
	return get_sort_y() + float(sort_priority) * 0.001


func _enter_tree() -> void:
	add_to_group(&"y_sortable")
	call_deferred(&"_register_with_manager")


func _exit_tree() -> void:
	_unregister_from_manager()
	remove_from_group(&"y_sortable")


## 向场景中的 [YSortManager] 注册自身。
## 由 _enter_tree 延迟调用，无需手动执行。
func _register_with_manager() -> void:
	var manager := _find_manager()
	if manager:
		manager.register(self)


## 从 [YSortManager] 注销自身。
## 由 _exit_tree 自动调用，Chunk 卸载时防止泄漏。
func _unregister_from_manager() -> void:
	var manager := _find_manager()
	if manager:
		manager.unregister(self)


## 在场景树中查找 [YSortManager] 节点（组名 y_sort_manager）。
func _find_manager() -> YSortManager:
	return get_tree().get_first_node_in_group(&"y_sort_manager") as YSortManager
