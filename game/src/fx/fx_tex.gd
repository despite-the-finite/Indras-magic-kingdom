class_name FxTex
## Procedurally generated particle/sprite textures (cached). No image assets needed.

static var _cache: Dictionary = {}


static func _make(key: String, size: int, fn: Callable) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var u := (float(x) + 0.5) / size * 2.0 - 1.0
			var v := -((float(y) + 0.5) / size * 2.0 - 1.0)
			var a: float = clampf(fn.call(u, v), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func glow() -> ImageTexture:
	return _make("glow", 64, func(u: float, v: float) -> float:
		var d := sqrt(u * u + v * v)
		return pow(clampf(1.0 - d, 0.0, 1.0), 2.2))


static func dot() -> ImageTexture:
	return _make("dot", 48, func(u: float, v: float) -> float:
		var d := sqrt(u * u + v * v)
		return smoothstep(1.0, 0.72, d))


static func star4() -> ImageTexture:
	return _make("star4", 96, func(u: float, v: float) -> float:
		var a := absf(u)
		var b := absf(v)
		var astroid := pow(clampf(1.0 - sqrt(a) - sqrt(b), 0.0, 1.0), 1.6) * 1.6
		var core := pow(clampf(1.0 - sqrt(u * u + v * v) * 1.6, 0.0, 1.0), 2.0)
		return astroid + core)


static func star5() -> ImageTexture:
	## solid rounded 5-point star (for Magic Stars / HUD-ish 3D uses)
	return _make("star5", 128, func(u: float, v: float) -> float:
		var ang := atan2(u, v)
		var r := sqrt(u * u + v * v)
		var k := 0.5 + 0.5 * cos(ang * 5.0)
		var edge := 0.42 + 0.5 * pow(k, 1.6)
		return smoothstep(edge + 0.03, edge - 0.03, r))


static func ring() -> ImageTexture:
	return _make("ring", 96, func(u: float, v: float) -> float:
		var d := sqrt(u * u + v * v)
		return smoothstep(0.16, 0.0, absf(d - 0.72)) * 1.2)


static func heart() -> ImageTexture:
	return _make("heart", 96, func(u: float, v: float) -> float:
		var x := u * 1.25
		var y := v * 1.25 + 0.15
		var f := pow(x * x + y * y - 1.0, 3.0) - x * x * y * y * y
		return smoothstep(0.06, -0.06, f))


static func petal() -> ImageTexture:
	return _make("petal", 64, func(u: float, v: float) -> float:
		# teardrop: wide at the top, pointed at the bottom
		var y := (v + 1.0) * 0.5
		var w := sin(clampf(y, 0.0, 1.0) * PI * 0.92) * (0.35 + 0.35 * y)
		var inside := 1.0 if (y >= 0.0 and y <= 1.0) else 0.0
		return smoothstep(w + 0.05, w - 0.05, absf(u)) * inside)


static func beam() -> ImageTexture:
	## vertical soft beam (light shafts): bright in the middle, fades left/right and toward the bottom
	return _make("beam", 64, func(u: float, v: float) -> float:
		var across := pow(clampf(1.0 - absf(u), 0.0, 1.0), 1.6)
		var down := smoothstep(-1.0, 0.7, v) * smoothstep(1.0, 0.55, v)
		return across * down)


static func soft_square() -> ImageTexture:
	return _make("softsq", 32, func(u: float, v: float) -> float:
		return smoothstep(1.0, 0.7, maxf(absf(u), absf(v))))
