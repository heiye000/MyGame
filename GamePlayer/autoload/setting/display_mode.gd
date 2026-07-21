##窗口显示模式
class_name DisplayMode extends Node

#示窗口模式的枚举
enum DisplayModeEnum {
	WINDOWED,
	BORDERLESS_MAXIMIZED,
	BORDERLESS_FULLSCREEN,
	EXCLUSIVE_FULLSCREEN,
}


func set_display_mode(display_mode: DisplayModeEnum) -> void:
	var window := get_window()

	match display_mode:
		DisplayModeEnum.WINDOWED:
			window.mode = Window.MODE_WINDOWED
			window.borderless = false
			window.size = Vector2i(1280, 720)

		DisplayModeEnum.BORDERLESS_MAXIMIZED:
			window.mode = Window.MODE_WINDOWED
			window.borderless = true
			window.mode = Window.MODE_MAXIMIZED

		DisplayModeEnum.BORDERLESS_FULLSCREEN:
			# 全屏状态本身已经没有边框。
			window.borderless = false
			window.mode = Window.MODE_FULLSCREEN

		DisplayModeEnum.EXCLUSIVE_FULLSCREEN:
			window.borderless = false
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
