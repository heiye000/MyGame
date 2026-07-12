## 预输入调试叠层：镜头画面左上角显示每个动作还剩多少帧预输入，方便调手感。
## 用 CanvasLayer，这样不跟着世界坐标跑，始终贴在 Camera2D 画面左上角。
class_name InputBufferDebugOverlay
extends CanvasLayer

## 正常剩余时间用的绿色。
const COLOR_OK := "#66f280"
## 快过期时用的黄色。
const COLOR_WARN := "#f2d84d"
## 没有数据时用的灰色。
const COLOR_IDLE := "#bfbfbf"
## 精确输入窗口开着时用的蓝色。
const COLOR_GATE := "#73bfff"

## 要显示数据的预输入组件。
var _buffer: InputBuffer
## 屏幕空间容器，锚在镜头左上角。
var _root: Control
## 显示文字的标签。
var _label: RichTextLabel


func _ready() -> void:
	# 叠在游戏画面之上；不跟随视口变换，始终是屏幕坐标。
	layer = 100
	follow_viewport_enabled = false

	_root = Control.new()
	_root.name = "Root"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.offset_left = 6.0
	_root.offset_top = 6.0
	_root.offset_right = 220.0
	_root.offset_bottom = 140.0
	add_child(_root)

	_label = RichTextLabel.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.add_theme_font_size_override("normal_font_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_label)


## 绑定预输入组件，开始显示调试信息。
func setup(buffer: InputBuffer) -> void:
	_buffer = buffer
	visible = buffer.debug_enabled
	refresh()


## 每帧刷新显示内容。
func refresh() -> void:
	if _buffer == null or _label == null:
		return

	visible = _buffer.debug_enabled
	if not visible:
		return

	var lines: PackedStringArray = ["[color=%s][InputBuffer][/color]" % COLOR_IDLE]
	var snapshot: Dictionary = _buffer.get_debug_snapshot()

	for action_name: String in snapshot.keys():
		var data: Dictionary = snapshot[action_name]
		match String(data.get("policy", "")):
			"buffer":
				lines.append(_format_buffer_line(action_name, data))
			"gate":
				lines.append(_format_gate_line(action_name, data))
			"instant":
				lines.append("[color=%s]%s: 无缓存（即时判定）[/color]" % [COLOR_IDLE, action_name])
			_:
				lines.append("[color=%s]%s: ---[/color]" % [COLOR_IDLE, action_name])

	_label.text = "\n".join(lines)


## 格式化普通预输入那一行：显示剩余帧和秒数。
func _format_buffer_line(action_name: String, data: Dictionary) -> String:
	var frames: int = int(data.get("frames", -1))
	if frames < 0:
		return "[color=%s]%s: ---[/color]" % [COLOR_IDLE, action_name]
	var sec: float = float(data.get("sec", 0.0))
	var color := COLOR_WARN if frames <= 2 else COLOR_OK
	return "[color=%s]%s: %d帧 (%.2f秒)[/color]" % [color, action_name, frames, sec]


## 格式化精确输入那一行：显示提前按键和窗口剩余帧。
func _format_gate_line(action_name: String, data: Dictionary) -> String:
	var pre_frames: int = int(data.get("pre_frames", -1))
	var gate_frames: int = int(data.get("gate_frames", -1))
	var gate_open: bool = bool(data.get("gate_open", false))

	var pre_text := "提前 %d帧" % pre_frames if pre_frames >= 0 else "提前 ---"
	var gate_text := "窗口开着 %d帧" % gate_frames if gate_open and gate_frames >= 0 else "窗口关着"
	var color := COLOR_GATE if gate_open else COLOR_IDLE
	return "[color=%s]%s: %s | %s[/color]" % [color, action_name, pre_text, gate_text]
