class_name CastleKit
## Procedural storybook castle pieces: towers with cone roofs and waving flags, walls, gate, stable, fountain.
## All swappable for authored models later (docs/ASSET_PIPELINE.md).

static func _stone() -> ShaderMaterial:
	return Mat.toon_grad(Color("#c39cc6"), Color("#e6c4e0"), 0.0, 10.0, {"outline": false, "rim_amount": 0.12, "gradient_amount": 1.0, "shade_tint": Color(0.55, 0.4, 0.8)})


static func window(parent: Node3D, pos: Vector3, w: float = 0.5, h: float = 0.9) -> void:
	var frame := Mat.toon(Color("#c9a0e8"), {"outline": false})
	var glass := Mat.glowing(Color("#ffe9a8"), 1.0, {"outline": false})
	Build.box(parent, Vector3(w + 0.16, h + 0.16, 0.12), pos + Vector3(0, 0, -0.02), frame)
	Build.cyl(parent, (w + 0.16) * 0.5, (w + 0.16) * 0.5, 0.12, pos + Vector3(0, (h + 0.16) * 0.5, -0.02), frame, 12, Vector3(PI * 0.5, 0, 0))
	Build.box(parent, Vector3(w, h, 0.14), pos, glass)
	Build.cyl(parent, w * 0.5, w * 0.5, 0.14, pos + Vector3(0, h * 0.5, 0), glass, 12, Vector3(PI * 0.5, 0, 0))


static func flag(parent: Node3D, pos: Vector3, color: Color) -> Node3D:
	var n := Build.pivot(parent, pos)
	Build.cyl(n, 0.03, 0.03, 1.4, Vector3(0, 0.7, 0), Mat.toon(Color("#ffe28a"), {"outline": false}), 6)
	var q := MeshInstance3D.new()
	var m := QuadMesh.new()
	m.size = Vector2(0.9, 0.55)
	q.mesh = m
	q.material_override = Mat.toon(color, {"two_sided": true, "wind": 0.5, "wind_speed": 3.0, "sway_height": 0.9, "emission_color": color, "emission_energy": 0.2, "outline": false})
	q.position = Vector3(0.5, 1.15, 0)
	n.add_child(q)
	Build.sphere(n, 0.06, Vector3(0, 1.42, 0), Mat.glowing(Color("#ffe28a"), 1.0), Vector3.ONE, 8)
	return n


static func tower(parent: Node3D, pos: Vector3, radius: float, height: float, roof: Color, flag_color: Color = Mat.PINK) -> Node3D:
	var n := Build.pivot(parent, pos)
	var stone := _stone()
	Build.cyl(n, radius, radius * 1.06, height, Vector3(0, height * 0.5, 0), stone, 28)
	Build.torus(n, radius * 0.98, radius * 1.1, Vector3(0, height * 0.72, 0), Mat.toon(Color("#e8c8f0"), {"outline": false}), Vector3.ZERO, 28)
	Build.torus(n, radius * 1.02, radius * 1.16, Vector3(0, height, 0), Mat.toon(Color("#e8c8f0"), {"outline": false}), Vector3.ZERO, 28)
	var roof_m := Mat.toon_grad(roof.darkened(0.1), roof.lightened(0.25), height, height + radius * 3.2, {"outline": false, "rim_amount": 0.5, "gradient_amount": 1.0, "glitter": 0.3})
	Build.cone(n, radius * 1.3, radius * 3.0, Vector3(0, height + radius * 1.5, 0), roof_m, Vector3.ZERO, 28)
	for k in 2:
		window(n, Vector3(0, height * (0.35 + 0.28 * k), radius * 0.98), 0.42, 0.75)
	flag(n, Vector3(0, height + radius * 3.0, 0), flag_color)
	return n


static func castle(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Build.pivot(parent, pos)
	var stone := _stone()
	var roof_l := Color("#a888f0")
	var roof_p := Color("#ff8fbf")
	# curtain wall + gatehouse
	Build.box(n, Vector3(22.0, 6.0, 3.0), Vector3(0, 3.0, 0), stone)
	for i in 14:
		Build.box(n, Vector3(0.9, 0.7, 3.1), Vector3(-10.0 + i * 1.54, 6.35, 0), stone)
	Build.box(n, Vector3(7.0, 9.5, 3.4), Vector3(0, 4.75, 0.2), stone)
	# arched gate (dark)
	Build.box(n, Vector3(2.6, 3.0, 0.3), Vector3(0, 1.5, 1.95), Mat.toon(Color("#2a1a4a"), {"outline": false, "shade_strength": 0.0, "rim_amount": 0.0}))
	Build.cyl(n, 1.3, 1.3, 0.3, Vector3(0, 3.0, 1.95), Mat.toon(Color("#2a1a4a"), {"outline": false, "shade_strength": 0.0, "rim_amount": 0.0}), 20, Vector3(PI * 0.5, 0, 0))
	Build.box(n, Vector3(3.2, 0.3, 0.4), Vector3(0, 0.15, 2.0), Mat.toon(Color("#ffd9a0"), {"outline": false}))
	# round heart window
	Build.cyl(n, 0.9, 0.9, 0.2, Vector3(0, 6.6, 1.95), Mat.toon(Color("#c9a0e8"), {"outline": false}), 24, Vector3(PI * 0.5, 0, 0))
	Build.cyl(n, 0.7, 0.7, 0.24, Vector3(0, 6.6, 1.97), Mat.glowing(Color("#ffe9a8"), 1.2, {"outline": false}), 24, Vector3(PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		window(n, Vector3(sx * 2.4, 5.4, 1.75), 0.5, 1.0)
		window(n, Vector3(sx * 2.4, 2.8, 1.75), 0.5, 1.0)
	# towers
	tower(n, Vector3(0, 9.5, 0.2), 1.9, 3.4, roof_l, Mat.PINK)
	tower(n, Vector3(-11.0, 0, 0), 2.1, 9.0, roof_p, Mat.SKY)
	tower(n, Vector3(11.0, 0, 0), 2.1, 9.0, roof_p, Mat.SKY)
	tower(n, Vector3(-5.2, 0, -0.2), 1.5, 8.2, roof_l, Mat.SUN)
	tower(n, Vector3(5.2, 0, -0.2), 1.5, 8.2, roof_l, Mat.SUN)
	tower(n, Vector3(-2.6, 8.0, -1.5), 1.1, 3.4, roof_p, Mat.LILAC)
	tower(n, Vector3(2.6, 8.0, -1.5), 1.1, 3.4, roof_l, Mat.PINK)
	return n


## Stable: doors swing open when Lumi's home is unlocked. Returns {"node","door_l","door_r","glow"}.
static func stable(parent: Node3D, pos: Vector3, open: bool) -> Dictionary:
	var n := Build.pivot(parent, pos)
	var wall := Mat.toon_grad(Color("#f6d8e6"), Color("#fff2f8"), 0.0, 5.0, {"outline": false, "rim_amount": 0.3, "gradient_amount": 1.0, "shade_tint": Color(0.75, 0.6, 0.95)})
	var roof := Mat.toon_grad(Color("#8a68d8"), Color("#c0a0ff"), 0.0, 4.0, {"outline": false, "rim_amount": 0.5, "gradient_amount": 1.0, "glitter": 0.2})
	Build.box(n, Vector3(9.0, 4.2, 4.0), Vector3(0, 2.1, 0), wall)
	# gabled roof (two slabs)
	for sx in [-1.0, 1.0]:
		var s := Build.box(n, Vector3(5.6, 0.35, 4.8), Vector3(sx * 2.25, 5.1, 0), roof)
		s.rotation.z = -sx * deg_to_rad(28.0)
	Build.box(n, Vector3(9.0, 1.2, 3.9), Vector3(0, 4.7, 0), wall)
	# door frame + interior glow
	var frame := Mat.toon(Color("#c9a0e8"), {"outline": false})
	Build.box(n, Vector3(3.6, 3.4, 0.3), Vector3(0, 1.7, 2.0), Mat.toon(Color("#2a1a4a"), {"outline": false, "shade_strength": 0.0, "rim_amount": 0.0}))
	var glow := Build.box(n, Vector3(3.4, 3.2, 0.1), Vector3(0, 1.7, 1.9), Mat.glowing(Color("#ffd890"), 1.4, {"outline": false}))
	glow.visible = open
	Build.torus(n, 1.7, 1.95, Vector3(0, 3.4, 2.0), frame, Vector3(PI * 0.5, 0, 0), 24)
	var door_l := Build.pivot(n, Vector3(-1.8, 0, 2.05))
	var door_r := Build.pivot(n, Vector3(1.8, 0, 2.05))
	var door_m := Mat.toon(Color("#b98a68"), {"outline": 0.01})
	Build.box(door_l, Vector3(1.75, 3.2, 0.16), Vector3(0.88, 1.6, 0), door_m)
	Build.box(door_r, Vector3(1.75, 3.2, 0.16), Vector3(-0.88, 1.6, 0), door_m)
	for d in [door_l, door_r]:
		Build.sphere(d, 0.09, Vector3(0.7 if d == door_l else -0.7, 1.6, 0.1), Mat.glowing(Mat.GOLD, 0.8), Vector3.ONE, 8)
	# horseshoe sign
	Build.torus(n, 0.22, 0.34, Vector3(0, 4.05, 2.1), Mat.glowing(Mat.GOLD, 0.9, {"outline": false}), Vector3(PI * 0.5, 0, 0), 20)
	# hay + lanterns + flower boxes
	var hay := Mat.toon(Color("#ffd870"), {"outline": 0.01})
	for i in 3:
		Build.cyl(n, 0.6, 0.6, 0.9, Vector3(-3.6 + i * 0.9, 0.45, 2.9 + (i % 2) * 0.3), hay, 14, Vector3(0, 0, PI * 0.5))
	ForestProps.lantern(n, Vector3(-2.4, 3.2, 2.2))
	ForestProps.lantern(n, Vector3(2.4, 3.2, 2.2))
	for sx in [-3.2, 3.2]:
		window(n, Vector3(sx, 2.6, 2.02), 0.9, 1.0)
		Build.box(n, Vector3(1.2, 0.25, 0.4), Vector3(sx, 1.85, 2.3), Mat.toon(Color("#b98a68"), {"outline": false}))
		for k in 3:
			ForestProps.flower(n, Vector3(sx - 0.35 + k * 0.35, 1.95, 2.35), [Mat.PINK, Mat.SUN, Color.WHITE][k], 0.6)
	if not open:
		door_l.rotation.y = 0.0
		door_r.rotation.y = 0.0
	else:
		door_l.rotation.y = deg_to_rad(-105.0)
		door_r.rotation.y = deg_to_rad(105.0)
	return {"node": n, "door_l": door_l, "door_r": door_r, "glow": glow}


static func lock_icon(parent: Node3D, pos: Vector3) -> Node3D:
	## sleeping-place marker: a small golden padlock that gently glows
	var n := Build.pivot(parent, pos)
	Build.box(n, Vector3(0.5, 0.42, 0.2), Vector3(0, 0, 0), Mat.glowing(Mat.GOLD, 0.6, {"outline": 0.008}))
	Build.torus(n, 0.12, 0.2, Vector3(0, 0.27, 0), Mat.toon(Color("#c7b8ee"), {"outline": 0.006}), Vector3(PI * 0.5, 0, 0), 16)
	Fx.glow_sprite(n, Vector3.ZERO, Color(1, 0.9, 0.5, 0.5), 1.0)
	return n


static func fountain(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Build.pivot(parent, pos)
	var stone := _stone()
	Build.cyl(n, 2.1, 2.3, 0.7, Vector3(0, 0.35, 0), stone, 28)
	var water := Mat.water_material(Color(0.35, 0.75, 1.0), Color(0.7, 0.95, 1.0))
	water.set_shader_parameter("alpha_base", 0.9)
	var w := Build.cyl(n, 1.9, 1.9, 0.05, Vector3(0, 0.66, 0), water, 28)
	Build.cyl(n, 0.3, 0.45, 1.5, Vector3(0, 1.4, 0), stone, 14)
	Build.cyl(n, 1.0, 0.5, 0.25, Vector3(0, 2.0, 0), stone, 18)
	Build.sphere(n, 0.28, Vector3(0, 2.4, 0), Mat.glowing(Color("#bfe6ff"), 1.2, {"outline": false}), Vector3.ONE, 12)
	# sparkly spray
	var spray := Fx.aura(n, Color(0.7, 0.9, 1.0), 26, 0.35)
	spray.position = Vector3(0, 2.5, 0)
	return n
