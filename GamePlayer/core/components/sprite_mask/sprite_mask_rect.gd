@tool
class_name SpriteMaskRect
extends ReferenceRect

const _SHADER := preload("res://core/components/sprite_mask/sprite_mask_rect.gdshader")

## 编辑器里指定的一张精灵。运行时用 bind 登记的可以不填这里。矩形不要挂在这张图下面。
@export var target: Sprite2D:
	set(value):
		if target == value:
			return
		_set_mask_enabled(target, false)
		target = value
		# 新目标也要写上当前矩形，不能因为范围没变就跳过。
		_applied_min = Vector2(INF, INF)
		if is_inside_tree():
			update_configuration_warnings()
		_apply_mask()

## 上次写进着色器的范围。没变化就不再写，避免编辑器里一直标场景被改过。
var _applied_min := Vector2(INF, INF)
## 同上，右下角。
var _applied_max := Vector2(INF, INF)
## 目标已经有别的材质时只警告一次。
var _blocked_material := false
## 运行时登记的精灵。和 target 一起挖，矩形本身不动。
var _sprites: Array[Sprite2D] = []


func _enter_tree() -> void:
	# 框只在编辑器里看。运行时不画，位置和大小仍参与挖空。
	editor_only = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	_apply_mask()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if target != null and target.is_ancestor_of(self):
		warnings.append("矩形挂在目标精灵下面会跟着图走。把矩形挪到精灵外面。")
	return warnings


## 登记一张要挖空的精灵。同一张重复登记没有效果。
func bind(sprite: Sprite2D) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	if sprite in _sprites:
		return
	_sprites.append(sprite)
	# 范围可能没变，也要让新精灵写上一次。
	_applied_min = Vector2(INF, INF)
	_apply_mask()


## 解开一张精灵，并把它上面的洞关掉。
func unbind(sprite: Sprite2D) -> void:
	_sprites.erase(sprite)
	_set_mask_enabled(sprite, false)


## 把当前矩形写到所有已登记的精灵上。每帧都写，剑一转，挖空范围也跟着变。
func _apply_mask() -> void:
	var sprites := _sprites_to_mask()
	if sprites.is_empty():
		return
	var parent_node := get_parent() as Node2D
	if parent_node == null:
		return
	# 用矩形在父节点里的左上角和宽高。不走 Control 的全局坐标。
	var mask_pos := Vector2(offset_left, offset_top)
	var mask_size := Vector2(offset_right - offset_left, offset_bottom - offset_top)
	var parent_inv := parent_node.get_global_transform().affine_inverse()
	for sprite in sprites:
		if not sprite.is_inside_tree():
			continue
		var mat := _ensure_material(sprite)
		if mat == null:
			continue
		var to_parent := parent_inv * sprite.get_global_transform()
		mat.set_shader_parameter("to_parent_x", to_parent.x)
		mat.set_shader_parameter("to_parent_y", to_parent.y)
		mat.set_shader_parameter("to_parent_origin", to_parent.origin)
		mat.set_shader_parameter("mask_pos", mask_pos)
		mat.set_shader_parameter("mask_size", mask_size)
		mat.set_shader_parameter("mask_enabled", true)


## target 和运行时登记的精灵，去掉已经释放的。
func _sprites_to_mask() -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	if target != null and is_instance_valid(target):
		result.append(target)
	var alive: Array[Sprite2D] = []
	for sprite in _sprites:
		if not is_instance_valid(sprite):
			continue
		alive.append(sprite)
		if sprite not in result:
			result.append(sprite)
	_sprites = alive
	return result


## 没有材质就挂上遮罩着色器。已经是这份着色器就接着用。
func _ensure_material(sprite: Sprite2D) -> ShaderMaterial:
	var current := sprite.material as ShaderMaterial
	if current != null and current.shader == _SHADER:
		_blocked_material = false
		return current
	if sprite.material != null:
		if not _blocked_material:
			_blocked_material = true
			push_warning("SpriteMaskRect：%s 已有别的材质，遮罩没有盖上去。" % sprite.name)
		return null
	var created := ShaderMaterial.new()
	created.shader = _SHADER
	sprite.material = created
	return created


## 换目标或清空时，关掉旧精灵上的洞。
func _set_mask_enabled(sprite: Sprite2D, enabled: bool) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null or mat.shader != _SHADER:
		return
	mat.set_shader_parameter("mask_enabled", enabled)
	_applied_min = Vector2(INF, INF)
	_applied_max = Vector2(INF, INF)
