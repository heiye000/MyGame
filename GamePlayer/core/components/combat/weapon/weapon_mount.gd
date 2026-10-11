## 武器挂载点。动画改位置、角度和遮挡，武器部件作为子节点跟着走。
class_name WeaponMount
extends Marker2D

## 矩形挡剑用的着色器。裁掉的范围跟子节点 CoverRect 重合。
const COVER_SHADER := preload("res://core/components/combat/weapon/weapon_cover.gdshader")

## 右手。剑默认挂这里。
const HAND_R := &"hand_r"
## 左髋。剑鞘默认挂这里。
const HIP_L := &"hip_l"

## 遮挡关系。0 身前，1 身后，2 矩形内被身体挡住，3 身体完全挡住。动画存序号，新项只能加在最后。
enum Occlusion { IN_FRONT, BEHIND, BODY_COVERS_RECT, BODY_COVERS_ALL }

## 挂载点名字。武器靠它找点，不靠节点路径。
@export var mount_id: StringName = HAND_R

## 这一姿势下剑和身体谁在前。改它就会重写 z_index。
@export var occlusion: Occlusion = Occlusion.IN_FRONT:
	set(value):
		occlusion = value
		_apply_depth()


func _ready() -> void:
	_apply_depth()


## 身前和半挡画在身体上面，身后画在身体下面。完全挡住时整把武器不画。相对角色，不相对整个世界。
func _apply_depth() -> void:
	z_as_relative = true
	visible = occlusion != Occlusion.BODY_COVERS_ALL
	z_index = -1 if occlusion == Occlusion.BEHIND else 1
	_apply_cover()


func _cover_area() -> VisibleOnScreenNotifier2D:
	return get_node_or_null(^"CoverRect") as VisibleOnScreenNotifier2D


## 这一姿势是否真的要用矩形挡剑。区域来自子节点 CoverRect。
func uses_cover_rect() -> bool:
	var area := _cover_area()
	if area == null or Engine.is_editor_hint():
		return false
	var size := area.rect.size
	return occlusion == Occlusion.BODY_COVERS_RECT and size.x > 0.0 and size.y > 0.0


## 矩形遮挡时，把落在 CoverRect 里的剑像素裁掉。其它遮挡去掉裁切。
func _apply_cover() -> void:
	if Engine.is_editor_hint():
		return
	var area := _cover_area()
	var cover := uses_cover_rect()
	for child in get_children():
		var sprite := child as Sprite2D
		if sprite == null:
			continue
		if not cover:
			sprite.material = null
			continue
		var mat := sprite.material as ShaderMaterial
		if mat == null or mat.shader != COVER_SHADER:
			mat = ShaderMaterial.new()
			mat.shader = COVER_SHADER
			sprite.material = mat
		mat.set_shader_parameter("cover_origin", area.position)
		mat.set_shader_parameter("cover_rotation", area.rotation)
		mat.set_shader_parameter("cover_scale", area.scale)
		mat.set_shader_parameter("cover_position", area.rect.position)
		mat.set_shader_parameter("cover_size", area.rect.size)
