## Y 排序调试叠层：在世界坐标中绘制每个可排序对象的排序线与 z_index。
## 显示由 DebugService 统一控制（总开关 F1 + FEATURE_REGISTRY）。
## 仅在 Debug 构建下生效，不影响正式导出包。
class_name YSortDebugOverlay
extends Node2D

const LINE_COLOR := Color(1.0, 0.2, 0.2, 0.9)
const POINT_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 0.95)
const LINE_HALF_WIDTH := 18.0

var _font: Font


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		visible = false
		return
	_font = ThemeDB.fallback_font
	z_index = 200
	z_as_relative = false
	DebugService.overlay_visibility_changed.connect(_sync_visibility)
	DebugService.master_toggled.connect(_on_master_toggled)
	_sync_visibility()


func _on_master_toggled(_enabled: bool) -> void:
	_sync_visibility()


func _sync_visibility() -> void:
	var on := DebugService.is_overlay_enabled(DebugSettings.ID_Y_SORT_OVERLAY)
	visible = on
	set_process(on)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for node in get_tree().get_nodes_in_group(&"y_sortable"):
		var sortable := node as YSortable2D
		if sortable == null or not sortable.enabled:
			continue
		var host := sortable.get_host()
		if host == null:
			continue
		var sort_y: float = sortable.get_sort_y()
		var anchor_x: float = host.global_position.x
		var line_start := to_local(Vector2(anchor_x - LINE_HALF_WIDTH, sort_y))
		var line_end := to_local(Vector2(anchor_x + LINE_HALF_WIDTH, sort_y))
		draw_line(line_start, line_end, LINE_COLOR, 1.0)
		draw_circle(to_local(Vector2(anchor_x, sort_y)), 2.0, POINT_COLOR)
		var label := "%s z:%d" % [host.name, host.z_index]
		draw_string(
			_font,
			to_local(Vector2(anchor_x + LINE_HALF_WIDTH + 2.0, sort_y - 2.0)),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			8,
			TEXT_COLOR
		)
