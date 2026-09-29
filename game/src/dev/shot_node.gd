extends Node
## Saves a screenshot of the running game after `delay` seconds, then quits (developer tool).

var path := "shot.png"
var delay := 2.5
var quit_after := true
var _t := 0.0
var _done := false


func _process(delta: float) -> void:
	_t += delta
	if _t >= delay and not _done:
		_done = true
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var dir := path.get_base_dir()
		if dir != "" and not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		img.save_png(path)
		for pr in String(Router.params.get("probe", "")).split(";", false):
			var xy := pr.split(",")
			if xy.size() == 2:
				var c := img.get_pixel(int(xy[0]), int(xy[1]))
				print("[probe] ", pr, " = ", c.to_html(false))
		print("[shot] saved ", path, " ", img.get_size())
		if quit_after:
			get_tree().quit()
