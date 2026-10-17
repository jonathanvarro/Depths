extends RefCounted
## The part of the screen clear of the iPhone's camera cutout, rounded
## corners and home bar (#6), in UI pixels. Shared by every screen.

## iPhone 15 landscape insets (59pt sides, 21pt bottom) in this game's
## 648px-tall UI space: left, top, right, bottom. Used to preview on Windows.
const SIMULATED_PHONE := Vector4(97, 0, 97, 35)


## Left, top, right, bottom insets. Nothing to avoid on desktop.
static func insets(viewport: Viewport, simulate_phone := false) -> Vector4:
	if simulate_phone:
		return SIMULATED_PHONE
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var to_ui := viewport.get_visible_rect().size / window
	return Vector4(safe.position.x * to_ui.x, safe.position.y * to_ui.y,
			(window.x - safe.end.x) * to_ui.x, (window.y - safe.end.y) * to_ui.y)
