class_name InputMappingScheme
extends RefCounted

## 输入映射方案枚举。新增方案时只需在此添加枚举值与对应资源路径。
enum Type {
	KEYBOARD_MOUSE,
}

const _CONTEXTS: Dictionary = {
	Type.KEYBOARD_MOUSE: preload("res://core/components/input/res/contexts/keyboard_mouse.tres"),
}

static var _current: Type = Type.KEYBOARD_MOUSE


static func get_context(type: Type) -> GUIDEMappingContext:
	return _CONTEXTS.get(type) as GUIDEMappingContext


static func get_current() -> Type:
	return _current


static func get_current_context() -> GUIDEMappingContext:
	return get_context(_current)


## 一键切换到指定映射方案，并禁用其他已启用的方案。
static func switch_to(type: Type) -> void:
	var context := get_context(type)
	if context == null:
		push_error("InputMappingScheme: 未找到映射方案 %s。" % type)
		return
	_current = type
	GUIDE.enable_mapping_context(context, true)
