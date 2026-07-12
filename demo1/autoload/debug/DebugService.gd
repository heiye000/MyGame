## 全局调试服务：读功能注册表、监听 F1 总开关、提供通用查询 API。
## 实现后一般不再因新增功能而修改本文件。
extends Node

signal master_toggled(enabled: bool)
signal overlay_visibility_changed()

const SETTINGS_PATH := "res://data/configs/debug/DebugSettings.tres"
## 总开关物理键（不走 GUIDE，由 _input 直接处理）。
const MASTER_TOGGLE_KEY := KEY_F1

var _settings: DebugSettings
## 运行时总开关（F1 切换）。
var _master_enabled: bool = false
## 各功能开关状态，键为 StringName。
var _feature_states: Dictionary = {}


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_input(false)
		return
	_load_settings()
	_build_feature_states()
	_master_enabled = _settings.master_enabled_on_start if _settings else false
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == MASTER_TOGGLE_KEY:
			toggle_master()
			get_viewport().set_input_as_handled()


func is_master_enabled() -> bool:
	return OS.is_debug_build() and _master_enabled


## 某功能最终是否显示：Debug 构建 + 总开关 + 功能开关。
func is_overlay_enabled(feature_id: StringName) -> bool:
	if not OS.is_debug_build() or not _master_enabled:
		return false
	return bool(_feature_states.get(feature_id, false))


## 读取 FEATURE_REGISTRY 条目中的 options（未来扩展用）。
func get_feature_options(feature_id: StringName) -> Dictionary:
	var entry := DebugSettings.get_registry_entry(feature_id)
	var options: Variant = entry.get("options", {})
	return options if options is Dictionary else {}


func get_settings() -> DebugSettings:
	return _settings


func set_master_enabled(enabled: bool) -> void:
	if not OS.is_debug_build():
		return
	if _master_enabled == enabled:
		return
	_master_enabled = enabled
	master_toggled.emit(_master_enabled)
	overlay_visibility_changed.emit()


func toggle_master() -> void:
	set_master_enabled(not _master_enabled)


func _load_settings() -> void:
	if ResourceLoader.exists(SETTINGS_PATH):
		_settings = load(SETTINGS_PATH) as DebugSettings
	if _settings == null:
		_settings = DebugSettings.new()
		push_warning("DebugService: 未找到 %s，使用内存默认配置。" % SETTINGS_PATH)


func _build_feature_states() -> void:
	_feature_states.clear()
	var overrides: Dictionary = _settings.feature_overrides if _settings else {}
	for entry in DebugSettings.FEATURE_REGISTRY:
		var id := StringName(entry.get("id", &""))
		if id == &"":
			continue
		_feature_states[id] = DebugSettings.resolve_feature_enabled_with(overrides, id)
