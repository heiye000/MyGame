## 全局 Y 排序管理器。
## 挂载在 World 场景下，收集所有 [YSortable2D] 并按排序键写入宿主 z_index。
## 用法：World 场景添加 Node 子节点 → 挂载此脚本 → 确保节点在组 y_sort_manager 中（_ready 自动加入）。
class_name YSortManager
extends Node

## 排序步长（像素）。值越小，z_index 对 Y 坐标变化越敏感。
## 用法：16px 像素游戏保持 1 即可；对象极少时可适当增大。
@export var sort_stride: int = 1
## 可排序层的 z_index 下限。应高于地面层（0），低于前景层（100）。
## 用法：默认 10，与 OverheadLayer 的 z_index=100 配合使用。
@export var base_z: int = 10
## 可排序层的 z_index 上限。必须小于前景遮挡层。
## 用法：默认 99；同屏对象按排名均匀分配在 base_z~max_z 之间。
@export var max_z: int = 99
## 是否只处理摄像机视野内的可排序对象。
## 用法：大世界建议开启以节省性能；调试遮挡时可临时关闭。
@export var use_camera_culling: bool = true
## 相机裁剪的扩展边距（像素）。
## 用法：防止对象刚进入/离开屏幕时 z_index 突变；默认 64 像素。
@export var cull_margin: float = 64.0

var _sortables: Array[YSortable2D] = []


func _ready() -> void:
	add_to_group(&"y_sort_manager")
	for node in get_tree().get_nodes_in_group(&"y_sortable"):
		var sortable := node as YSortable2D
		if sortable:
			register(sortable)


## 注册一个 [YSortable2D] 组件。
## 由组件在 _enter_tree 时自动调用；重复注册会被忽略。
func register(sortable: YSortable2D) -> void:
	if sortable == null or _sortables.has(sortable):
		return
	_sortables.append(sortable)


## 注销一个 [YSortable2D] 组件。
## 由组件在 _exit_tree 时自动调用。
func unregister(sortable: YSortable2D) -> void:
	_sortables.erase(sortable)


func _process(_delta: float) -> void:
	_apply_sorting()


## 对当前帧所有有效可排序对象执行排序。
## 按 get_sort_key 升序排列，依次分配 z_index 并设置 z_as_relative=false。
func _apply_sorting() -> void:
	var active: Array[YSortable2D] = []
	var camera_rect := _get_camera_rect()
	var cull := use_camera_culling and camera_rect.has_area()

	for sortable in _sortables:
		if not is_instance_valid(sortable) or not sortable.enabled:
			continue
		var host := sortable.get_host()
		if host == null:
			continue
		if cull and not camera_rect.grow(cull_margin).has_point(host.global_position):
			continue
		active.append(sortable)

	if active.is_empty():
		return

	active.sort_custom(func(a: YSortable2D, b: YSortable2D) -> bool:
		return a.get_sort_key() < b.get_sort_key()
	)

	var z_range := max_z - base_z
	for i in active.size():
		var sortable: YSortable2D = active[i]
		var host := sortable.get_host()
		var z := base_z
		if active.size() > 1:
			z = base_z + int(float(i) / float(active.size() - 1) * float(z_range))
		else:
			z = clampi(base_z + int(sortable.get_sort_key() / float(sort_stride)), base_z, max_z)
		host.z_index = z
		host.z_as_relative = false


## 获取当前摄像机在世界中的可见矩形。
## 无摄像机时返回空 Rect2，裁剪逻辑自动跳过。
func _get_camera_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Rect2()
	var viewport_size := get_viewport().get_visible_rect().size
	var zoom := camera.zoom
	var half_size := viewport_size / zoom * 0.5
	var center := camera.get_screen_center_position()
	return Rect2(center - half_size, viewport_size / zoom)
