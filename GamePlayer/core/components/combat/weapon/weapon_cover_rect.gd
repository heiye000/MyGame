@tool
## 编辑器里的遮挡框。拖它就是在改裁切区域。
## rect.position 是左上角，rect.size 是宽高，都是挂载点局部像素，y 向下。
class_name WeaponCoverRect
extends VisibleOnScreenNotifier2D

var _drawn := Rect2()
var _origin := Vector2()
var _angle := 0.0
var _scale := Vector2.ONE
var _show := false


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	var mount := get_parent() as WeaponMount
	if mount == null:
		return
	var show := mount.occlusion == WeaponMount.Occlusion.BODY_COVERS_RECT
	var moved := rect != _drawn or position != _origin or rotation != _angle or scale != _scale
	if Engine.is_editor_hint():
		if show != _show or (show and moved):
			_show = show
			_capture()
			queue_redraw()
		return
	if not show:
		_drawn = Rect2()
		return
	if not moved:
		return
	_capture()
	mount._apply_cover()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var mount := get_parent() as WeaponMount
	if mount == null or mount.occlusion != WeaponMount.Occlusion.BODY_COVERS_RECT:
		return
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(rect, Color(0.95, 0.22, 0.18, 0.28), true)
	draw_rect(rect, Color(1.0, 0.4, 0.3, 1.0), false, 1.0)


func _capture() -> void:
	_drawn = rect
	_origin = position
	_angle = rotation
	_scale = scale
