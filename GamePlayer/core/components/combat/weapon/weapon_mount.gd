## 武器挂载点。动画改位置、角度和遮挡，武器部件作为子节点跟着走。
class_name WeaponMount
extends Marker2D

## 右手。剑默认挂这里。
const HAND_R := &"hand_r"
## 左髋。剑鞘默认挂这里。
const HIP_L := &"hip_l"

## 遮挡关系。0 身前，1 身后，2 身体挡住一块（剑仍在身前，遮罩里的像素不画），3 身体完全挡住。
## 动画里存的是序号，不能改顺序，也不能从中间删。
enum Occlusion { IN_FRONT, BEHIND, BODY_COVERS_RECT, BODY_COVERS_ALL }

## 遮挡档变化时发出。武器外观用来决定要不要挖空。
signal occlusion_changed(next: Occlusion)

## 挂载点名字。武器靠它找点，不靠节点路径。
@export var mount_id: StringName = HAND_R

## 这一姿势下剑和身体谁在前。改它就会重写 z_index。
@export var occlusion: Occlusion = Occlusion.IN_FRONT:
	set(value):
		occlusion = value
		_apply_depth()


func _ready() -> void:
	_apply_depth()


## 身前画在身体上面，身后画在身体下面。完全挡住时整把武器不画。相对角色，不相对整个世界。
func _apply_depth() -> void:
	z_as_relative = true
	visible = occlusion != Occlusion.BODY_COVERS_ALL
	z_index = -1 if occlusion == Occlusion.BEHIND else 1
	occlusion_changed.emit(occlusion)
