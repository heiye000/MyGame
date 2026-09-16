class_name InputMappingScheme
extends RefCounted

## 输入映射方案枚举。新增方案时：先在 Loader 登记资源，再在这里加枚举和对照。
enum Type {
	KEYBOARD_MOUSE,
}

## 输入映射方案所对应的资源是哪个
const _CONTEXT_IDS: Dictionary = {
	Type.KEYBOARD_MOUSE: Loader.Id.MAPPING_KEYBOARD_MOUSE,
}

static var _current: Type = Type.KEYBOARD_MOUSE


## 取出指定方案的 GUIDE 映射上下文。
static func get_context(type: Type) -> GUIDEMappingContext:
	if not _CONTEXT_IDS.has(type):
		return null
	return Loader.get_resource(_CONTEXT_IDS[type]) as GUIDEMappingContext


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
