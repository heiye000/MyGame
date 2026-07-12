## 调试功能注册表与资源配置。
## ★ 新增调试开关只改本文件的 FEATURE_REGISTRY ★
class_name DebugSettings
extends Resource

# ---------------------------------------------------------------------------
# ★ 新增调试开关只改这里 ★
# ---------------------------------------------------------------------------
const FEATURE_REGISTRY: Array[Dictionary] = [
	{
		"id": &"input_buffer_overlay",
		"label": "InputBuffer 叠层",
		"default_enabled": true,
	},
	{
		"id": &"y_sort_overlay",
		"label": "Y 排序线",
		"default_enabled": true,
	},
	# 未来扩展示例：
	# { "id": &"collision_shapes", "label": "碰撞体", "default_enabled": false, "options": {} },
]

## overlay 用的功能 ID 别名，与 FEATURE_REGISTRY.id 保持一致。
const ID_INPUT_BUFFER_OVERLAY := &"input_buffer_overlay"
const ID_Y_SORT_OVERLAY := &"y_sort_overlay"

# ---------------------------------------------------------------------------
# .tres 可覆盖的启动默认
# ---------------------------------------------------------------------------

@export_group("启动默认")
## 进游戏时总开关是否默认打开。
@export var master_enabled_on_start: bool = false
## 覆盖 FEATURE_REGISTRY 中的 default_enabled。键为功能 id（StringName），值为 bool。
@export var feature_overrides: Dictionary = {}


## 按功能 id 取注册表条目；找不到返回空 Dictionary。
static func get_registry_entry(feature_id: StringName) -> Dictionary:
	for entry in FEATURE_REGISTRY:
		if StringName(entry.get("id", &"")) == feature_id:
			return entry
	return {}


## 解析某功能最终默认开关：overrides 优先，否则用 registry 的 default_enabled。
## 使用静态方法，避免部分 Resource 实例上实例方法调用异常。
static func resolve_feature_enabled_with(
	overrides: Dictionary,
	feature_id: StringName
) -> bool:
	if overrides.has(feature_id):
		return bool(overrides[feature_id])
	var as_string := String(feature_id)
	if overrides.has(as_string):
		return bool(overrides[as_string])
	var entry := get_registry_entry(feature_id)
	if entry.is_empty():
		return false
	return bool(entry.get("default_enabled", false))


## 实例便捷封装。
func resolve_feature_enabled(feature_id: StringName) -> bool:
	return DebugSettings.resolve_feature_enabled_with(feature_overrides, feature_id)
