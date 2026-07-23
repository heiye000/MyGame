@tool
## 世界持久对象身份组件。挂在宝箱、门、NPC、触发器等会存档/会随 Chunk 装卸的实体下。
## 制作期可用 Inspector 按钮生成 persistent_id（生成后应保存场景，运行时不再改）。
class_name Persistable
extends Node

## 世界实例永久身份；同一世界内唯一，Chunk 重生不得更换。
@export var persistent_id: StringName = &""
## 配置/原型身份；同款对象可共用（如 chest_wood_small）。
@export var definition_id: StringName = &""

## 空着时点一次生成；已有值则跳过并警告。
@export_tool_button("生成 persistent_id", "Add")
var generate_persistent_id_btn: Callable:
	get:
		return _editor_generate_persistent_id

## 强制换新 ID（会破坏已有存档关联，慎用）。
@export_tool_button("重新生成 persistent_id", "Reload")
var regenerate_persistent_id_btn: Callable:
	get:
		return _editor_regenerate_persistent_id

## 本次运行临时句柄；不进存档，进入树时分配。
var runtime_id: int = -1

## 静态递增，用于生成本次运行的 runtime_id。
static var _next_runtime_id: int = 1


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if runtime_id < 0:
		runtime_id = _next_runtime_id
		_next_runtime_id += 1


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if persistent_id == &"":
		warnings.append("persistent_id 为空：请手填或点「生成 persistent_id」。")
	return warnings


## 是否已填写永久身份（内容制作验收用）。
func has_persistent_id() -> bool:
	return persistent_id != &""


## 调试用摘要。
func debug_label() -> String:
	return "persistent=%s definition=%s runtime=%d" % [persistent_id, definition_id, runtime_id]


## 编辑器：仅在空时生成。
func _editor_generate_persistent_id() -> void:
	if not Engine.is_editor_hint():
		return
	if persistent_id != &"":
		push_warning("Persistable: persistent_id 已有值「%s」，未覆盖。若要换新请点「重新生成」。" % persistent_id)
		return
	_apply_new_persistent_id()


## 编辑器：强制生成新 ID。
func _editor_regenerate_persistent_id() -> void:
	if not Engine.is_editor_hint():
		return
	_apply_new_persistent_id()


## 写入新 ID 并刷新检查器、标记场景未保存。
func _apply_new_persistent_id() -> void:
	persistent_id = _make_unique_persistent_id()
	update_configuration_warnings()
	notify_property_list_changed()
	# 提醒把新 ID 存进 .tscn。
	EditorInterface.mark_scene_as_unsaved()
	print("Persistable: 已生成 persistent_id = ", persistent_id)


## 制作期唯一 ID：前缀_时间戳_随机后缀。前缀优先用 definition_id，否则用父节点名。
func _make_unique_persistent_id() -> StringName:
	var prefix := "entity"
	if definition_id != &"":
		prefix = String(definition_id)
	elif get_parent() != null:
		prefix = get_parent().name
	prefix = String(prefix).to_snake_case()
	# 去掉不适合做 ID 的字符。
	var cleaned := ""
	for i in prefix.length():
		var ch := prefix[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
			cleaned += ch
		else:
			cleaned += "_"
	prefix = cleaned.strip_edges().trim_prefix("_").trim_suffix("_")
	if prefix.is_empty():
		prefix = "entity"
	var stamp := int(Time.get_unix_time_from_system())
	var salt := randi() % 0x10000
	return StringName("%s_%d_%04x" % [prefix, stamp, salt])
