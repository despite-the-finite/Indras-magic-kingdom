class_name ForestProps
## Procedural stylised props for the Enchanted Forest (trees, giant flowers, mushrooms, grass, rocks...).
## Deterministic given a seed. Each function returns the created node so levels can animate or hook it.
## Replace any of these with a .glb via Assets.model(path) (see docs/ASSET_PIPELINE.md).

static var _leaf_mesh: ArrayMesh
static var _grass_mesh: ArrayMesh
static var _flower_mesh: ArrayMesh


static func _leaf_blade(length: float = 1.0, width: float = 0.12, bend: float = 0.5, segs: int = 6) -> ArrayMesh:
	## curved tapered strip; +Y up, bends toward +X, vertex colour dark base -> light tip
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_c := Color.WHITE
	for i in segs + 1:
		var t := float(i) / segs
		var w := width * (1.0 - t * t) * 0.5
		var c := Vector3(bend * t * t * length, t * length, 0)
		var l := c + Vector3(-w, 0, 0)
		var r := c + Vector3(w, 0, 0)
		var col := Color(0.55 + 0.45 * t, 0.7 + 0.3 * t, 0.6 + 0.3 * t)
		if i > 0:
			st.set_color(prev_c); st.add_vertex(prev_l)
			st.set_color(prev_c); st.add_vertex(prev_r)
			st.set_color(col); st.add_vertex(r)
			st.set_color(prev_c); st.add_vertex(prev_l)
			st.set_color(col); st.add_vertex(r)
			st.set_color(col); st.add_vertex(l)
		prev_l = l
		prev_r = r
		prev_c = col
	st.generate_normals()
	return st.commit()


static func grass_mesh() -> ArrayMesh:
	if _grass_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for b in 5:
			var ang := float(b) / 5.0 * TAU
			var h := 0.32 + 0.16 * fmod(b * 0.37, 1.0)
			var w := 0.05
			var dir := Vector3(cos(ang), 0, sin(ang))
			var side := Vector3(-dir.z, 0, dir.x)
			var base := dir * 0.05
			var tip := base + dir * 0.10 + Vector3(0, h, 0)
			var mid := base + dir * 0.03 + Vector3(0, h * 0.5, 0)
			var dark := Color(0.62, 0.78, 0.7)
			var light := Color(1.0, 1.0, 1.0)
			st.set_color(dark); st.add_vertex(base - side * w)
			st.set_color(dark); st.add_vertex(base + side * w)
			st.set_color(light); st.add_vertex(mid + side * w * 0.6)
			st.set_color(dark); st.add_vertex(base - side * w)
			st.set_color(light); st.add_vertex(mid + side * w * 0.6)
			st.set_color(light); st.add_vertex(mid - side * w * 0.6)
			st.set_color(light); st.add_vertex(mid - side * w * 0.6)
			st.set_color(light); st.add_vertex(mid + side * w * 0.6)
			st.set_color(light); st.add_vertex(tip)
		st.generate_normals()
		_grass_mesh = st.commit()
	return _grass_mesh


static func flower_mesh() -> ArrayMesh:
	if _flower_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# stem (a thin quad, green)
		var g := Color(0.45, 0.85, 0.5)
		var top := Vector3(0, 0.42, 0)
		for side in [Vector3(0.012, 0, 0), Vector3(0, 0, 0.012)]:
			st.set_color(g); st.add_vertex(-side)
			st.set_color(g); st.add_vertex(side)
			st.set_color(g); st.add_vertex(top + side)
			st.set_color(g); st.add_vertex(-side)
			st.set_color(g); st.add_vertex(top + side)
			st.set_color(g); st.add_vertex(top - side)
		# petals (white, tinted by instance colour) as a tilted fan
		var n := 6
		for i in n:
			var a := float(i) / n * TAU
			var d := Vector3(cos(a), 0.0, sin(a))
			var s := Vector3(-d.z, 0, d.x)
			var p0 := top + Vector3(0, 0.005, 0)
			var p1 := top + d * 0.13 + Vector3(0, 0.05, 0) + s * 0.05
			var p2 := top + d * 0.13 + Vector3(0, 0.05, 0) - s * 0.05
			var w := Color.WHITE
			st.set_color(w); st.add_vertex(p0)
			st.set_color(w); st.add_vertex(p1)
			st.set_color(w); st.add_vertex(p2)
		# centre (yellow)
		for i in 6:
			var a := float(i) / 6.0 * TAU
			var a2 := float(i + 1) / 6.0 * TAU
			var y := Color(1.0, 0.9, 0.25)
			st.set_color(y); st.add_vertex(top + Vector3(0, 0.02, 0))
			st.set_color(y); st.add_vertex(top + Vector3(cos(a), 0, sin(a)) * 0.04 + Vector3(0, 0.01, 0))
			st.set_color(y); st.add_vertex(top + Vector3(cos(a2), 0, sin(a2)) * 0.04 + Vector3(0, 0.01, 0))
		st.generate_normals()
		_flower_mesh = st.commit()
	return _flower_mesh


# ---------------------------------------------------------------------------
# scatter (MultiMesh)
# ---------------------------------------------------------------------------
static func scatter_grass(parent: Node3D, terrain: Terrain, x0: float, x1: float, per_meter: float, seed_v: int = 1, z_range: Vector2 = Vector2(-4.5, 3.5), tint_a: Color = Color("#5fcf7a"), tint_b: Color = Color("#a7f08c")) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = grass_mesh()
	var count := int((x1 - x0) * per_meter * Settings.particle_scale())
	var xforms: Array[Transform3D] = []
	var cols: Array[Color] = []
	for i in count:
		var x := rng.randf_range(x0, x1)
		var h := terrain.height_at(x)
		if h < -50.0:
			continue
		var z := rng.randf_range(z_range.x, z_range.y)
		var s := rng.randf_range(0.8, 1.9)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.4), s))
		xforms.append(Transform3D(b, Vector3(x, h - 0.02, z)))
		cols.append(tint_a.lerp(tint_b, rng.randf()))
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Mat.toon(Color.WHITE, {"use_vertex_color": true, "wind": 0.28, "wind_speed": 1.6, "sway_height": 0.5, "rim_amount": 0.0, "two_sided": true, "shade_strength": 0.3})
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


static func scatter_flowers(parent: Node3D, terrain: Terrain, x0: float, x1: float, per_meter: float, seed_v: int = 2, palette: Array = [], z_range: Vector2 = Vector2(-3.5, 3.0)) -> MultiMeshInstance3D:
	if palette.is_empty():
		palette = [Mat.PINK, Color.WHITE, Mat.SUN, Mat.LILAC, Color("#ff9a7a"), Mat.SKY]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = flower_mesh()
	var count := int((x1 - x0) * per_meter * Settings.particle_scale())
	var xforms: Array[Transform3D] = []
	var cols: Array[Color] = []
	for i in count:
		var x := rng.randf_range(x0, x1)
		var h := terrain.height_at(x)
		if h < -50.0:
			continue
		var z := rng.randf_range(z_range.x, z_range.y)
		var s := rng.randf_range(0.7, 1.5)
		xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, h - 0.01, z)))
		cols.append(palette[rng.randi() % palette.size()])
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Mat.toon(Color.WHITE, {"use_vertex_color": true, "wind": 0.12, "wind_speed": 1.3, "sway_height": 0.45, "rim_amount": 0.0, "two_sided": true, "emission_color": Color(1, 1, 1), "emission_energy": 0.12})
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


# ---------------------------------------------------------------------------
# hero props
# ---------------------------------------------------------------------------
static func flower(parent: Node3D, pos: Vector3, color: Color, scale_v: float = 1.0) -> Node3D:
	var n := Build.pivot(parent, pos)
	var mi := MeshInstance3D.new()
	mi.mesh = flower_mesh()
	mi.material_override = Mat.toon(color, {"use_vertex_color": true, "wind": 0.1, "sway_height": 0.45, "two_sided": true, "emission_color": color, "emission_energy": 0.25, "rim_amount": 0.0})
	mi.scale = Vector3.ONE * scale_v * 2.0
	n.add_child(mi)
	return n


static func giant_flower(parent: Node3D, pos: Vector3, height: float, color: Color, glow: bool = false) -> Node3D:
	var n := Build.pivot(parent, pos)
	var stem_m := Mat.toon_grad(Color("#3fae6a"), Color("#7fe08f"), 0.0, height, {"wind": 0.10, "sway_height": height, "rim_amount": 0.2})
	# curved stem from 3 capsule segments
	var top := Vector3.ZERO
	for i in 3:
		var seg_h := height / 3.0
		var bend := 0.18 * (i + 1)
		var c := Build.capsule(n, 0.07 - i * 0.012, seg_h * 1.2, Vector3(top.x + bend * 0.5, top.y + seg_h * 0.5, 0), stem_m, Vector3(0, 0, -bend * 0.4))
		top += Vector3(bend * 0.8, seg_h, 0)
	# leaves
	Build.sphere(n, 0.22, Vector3(-0.25, height * 0.25, 0.05), stem_m, Vector3(1.4, 0.25, 0.7), 12).rotation = Vector3(0, 0, 0.5)
	Build.sphere(n, 0.2, Vector3(0.35, height * 0.5, -0.05), stem_m, Vector3(1.4, 0.25, 0.7), 12).rotation = Vector3(0, 0, -0.4)
	var head := Build.pivot(n, top + Vector3(0, 0.1, 0))
	var petal_m := Mat.toon_grad(color.lightened(0.15), color.darkened(0.05), 0.0, 0.7, {"outline": false, "rim_color": color.lightened(0.6), "rim_amount": 0.7, "two_sided": true, "glitter": 0.2, "emission_color": color, "emission_energy": 0.25 if not glow else 0.9, "pulse": 0.4 if glow else 0.0})
	var pr := height * 0.35
	for i in 8:
		var a := float(i) / 8.0 * TAU
		var p := Build.sphere(head, pr * 0.5, Vector3(cos(a) * pr * 0.5, 0.0, sin(a) * pr * 0.5 * 0.55), petal_m, Vector3(1.4, 0.32, 0.8), 14)
		p.rotation = Vector3(0, -a, 0.35)
	Build.sphere(head, pr * 0.32, Vector3(0, 0.05, 0.02), Mat.glowing(Color("#ffd85a"), 0.7), Vector3(1, 0.7, 1), 16)
	if glow:
		Fx.glow_sprite(head, Vector3(0, 0.1, 0.4), Color(color.r, color.g, color.b, 0.35), pr * 2.6)
	return n


static func tree(parent: Node3D, pos: Vector3, h: float = 4.5, kind: int = 0, seed_v: int = 0) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v + int(pos.x * 13.0)
	var n := Build.pivot(parent, pos)
	var bark := Mat.toon_grad(Color("#7a4a3a"), Color("#a8744f"), 0.0, h, {"outline": false, "rim_amount": 0.1, "shade_tint": Color(0.55, 0.4, 0.7)})
	var lean := rng.randf_range(-0.35, 0.35)
	var x := 0.0
	var seg := 5
	for i in seg:
		var t := float(i) / seg
		var r := lerpf(0.26, 0.1, t)
		var y := t * h
		x = sin(t * 2.2 + rng.randf() * 0.5) * 0.3 + lean * t
		Build.capsule(n, r, h / seg * 1.5, Vector3(x, y + h / seg * 0.5, 0), bark, Vector3(0, 0, -cos(t * 2.2) * 0.13))
	# root flare
	Build.cone(n, 0.5, 0.5, Vector3(0, 0.22, 0), bark, Vector3.ZERO, 10)
	var canopy_cols := [
		[Color("#3fae7a"), Color("#8ae89a")],      # classic
		[Color("#e878b8"), Color("#ffc0e0")],      # cherry blossom
		[Color("#4a9ad0"), Color("#9adcf0")],      # moon-leaf (blue)
		[Color("#7a58c8"), Color("#c0a0ff")],      # twilight (violet)
	]
	var cc: Array = canopy_cols[kind % canopy_cols.size()]
	var leaf_m := Mat.toon_grad(cc[0], cc[1], -0.6, 1.2, {"outline": false, "wind": 0.05, "sway_height": 2.0, "rim_color": Color(1, 1, 0.85), "rim_amount": 0.45, "glitter": 0.1, "gradient_amount": 1.0})
	var cr := h * 0.33
	var center := Vector3(x, h + cr * 0.2, 0)
	var blobs := 7
	for i in blobs:
		var a := float(i) / blobs * TAU
		var off := Vector3(cos(a) * cr * 0.85, sin(a * 2.3) * cr * 0.3, sin(a) * cr * 0.55)
		Build.sphere(n, cr * rng.randf_range(0.62, 0.86), center + off, leaf_m, Vector3(1.0, 0.85, 1.0), 16)
	Build.sphere(n, cr * 0.95, center + Vector3(0, cr * 0.35, 0), leaf_m, Vector3(1.0, 0.85, 1.0), 18)
	return n


static func mushroom(parent: Node3D, pos: Vector3, h: float, cap_color: Color, glow: bool = false, spots: bool = true) -> Node3D:
	var n := Build.pivot(parent, pos)
	var stem := Mat.toon(Color("#fff0e0"), {"rim_amount": 0.2, "outline": false})
	Build.cyl(n, h * 0.13, h * 0.19, h, Vector3(0, h * 0.5, 0), stem, 14)
	var cap_m := Mat.toon_grad(cap_color.darkened(0.08), cap_color.lightened(0.15), h * 0.9, h * 1.5, {"outline": false, "rim_color": cap_color.lightened(0.6), "rim_amount": 0.6,
		"emission_color": cap_color, "emission_energy": 0.9 if glow else 0.0, "pulse": 0.5 if glow else 0.0, "gradient_amount": 1.0})
	var capr := h * 0.75
	var cap := Build.sphere(n, capr, Vector3(0, h * 1.02, 0), cap_m, Vector3(1.0, 0.55, 1.0), 22)
	if spots:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(pos.x * 100.0)
		for i in 5:
			var a := rng.randf() * TAU
			var e := rng.randf_range(0.35, 1.0)
			var p := Vector3(cos(a) * capr * 0.62 * e, h * 1.02 + capr * 0.55 * sqrt(maxf(0.0, 1.0 - 0.5 * e * e)) * 0.98, sin(a) * capr * 0.62 * e)
			Build.sphere(n, capr * rng.randf_range(0.1, 0.16), p, Mat.toon(Color("#fff8f0"), {"outline": false}), Vector3(1, 0.4, 1), 8)
	if glow:
		Fx.glow_sprite(n, Vector3(0, h * 1.1, 0.3), Color(cap_color.r, cap_color.g, cap_color.b, 0.4), h * 2.4)
	return n


## Bouncy mushroom platform: solid cap the child can stand on that also launches her upward.
static func bouncy_mushroom(parent: Node3D, pos: Vector3, h: float, cap_color: Color) -> Node3D:
	var n := mushroom(parent, pos, h, cap_color, false, true)
	var capr := h * 0.75
	var top_y := h * 1.02 + capr * 0.55 * 0.98
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = capr * 0.85
	cyl.height = 0.3
	cs.shape = cyl
	cs.position = Vector3(0, top_y - 0.15, 0)
	sb.add_child(cs)
	n.add_child(sb)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var acs := CollisionShape3D.new()
	var ash := CylinderShape3D.new()
	ash.radius = capr * 0.8
	ash.height = 0.5
	acs.shape = ash
	acs.position = Vector3(0, top_y + 0.2, 0)
	area.add_child(acs)
	n.add_child(area)
	area.body_entered.connect(func(b):
		if b is Player and b.velocity.y <= 0.5:
			b.velocity.y = 14.5
			Audio.sfx("boing", -2.0, 1.0, 0.08)
			Fx.sparkle_burst(parent, n.global_position + Vector3(0, top_y, 0), cap_color.lightened(0.4), 14, 2.6, 0.3, 0.8)
			var tw := n.create_tween()
			tw.tween_property(n, "scale", Vector3(1.15, 0.8, 1.15), 0.08)
			tw.tween_property(n, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	return n


## Leafy bush: a cluster of gradient blobs (fills the mid-ground so the forest feels lush).
static func bush(parent: Node3D, pos: Vector3, size: float = 1.0, tint: Color = Color("#2f9a5a"), blossom: Color = Color(0, 0, 0, 0)) -> Node3D:
	var n := Build.pivot(parent, pos)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 17.0 + pos.z * 3.0)
	var m := Mat.toon_grad(tint.darkened(0.15), tint.lightened(0.35), 0.0, size * 1.3, {"outline": false, "rim_color": Color(1, 1, 0.8), "rim_amount": 0.4, "gradient_amount": 1.0, "wind": 0.04, "sway_height": size})
	for i in 5:
		var a := float(i) / 5.0 * TAU + rng.randf()
		var r := size * rng.randf_range(0.42, 0.62)
		Build.sphere(n, r, Vector3(cos(a) * size * 0.55, r * 0.75, sin(a) * size * 0.35), m, Vector3(1.0, 0.85, 1.0), 12)
	Build.sphere(n, size * 0.62, Vector3(0, size * 0.62, 0), m, Vector3(1.0, 0.85, 1.0), 14)
	if blossom.a > 0.0:
		for i in 7:
			var a2 := rng.randf() * TAU
			Build.sphere(n, size * 0.09, Vector3(cos(a2) * size * 0.7, size * rng.randf_range(0.5, 1.0), sin(a2) * size * 0.45 + size * 0.2), Mat.glowing(blossom, 0.4, {"outline": false}), Vector3.ONE, 8)
	return n


static func rock(parent: Node3D, pos: Vector3, size: float, color: Color = Color("#b8a8d8")) -> Node3D:
	var n := Build.pivot(parent, pos)
	var m := Mat.toon_grad(color.darkened(0.1), color.lightened(0.25), 0.0, size, {"outline": false, "rim_amount": 0.25, "gradient_amount": 1.0})
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 31.0 + pos.z * 7.0)
	Build.sphere(n, size, Vector3(0, size * 0.45, 0), m, Vector3(1.2, 0.7, 0.95), 12).rotation.y = rng.randf() * TAU
	Build.sphere(n, size * 0.6, Vector3(size * 0.9, size * 0.25, 0.2), m, Vector3(1.0, 0.7, 1.0), 10)
	# moss cap
	Build.sphere(n, size * 0.7, Vector3(0, size * 0.75, 0), Mat.toon(Color("#6fdc8a"), {"outline": false, "rim_amount": 0.0}), Vector3(1.0, 0.28, 0.8), 10)
	return n


static func hoofprints(parent: Node3D, pos: Vector3, facing: float = 1.0) -> Node3D:
	## Sparkly glowing hoofprints that lead the child along the trail.
	var n := Build.pivot(parent, pos)
	var m := Mat.glowing(Color("#ffb0e0"), 1.6, {"pulse": 0.8, "outline": false, "rim_amount": 0.0})
	for i in 4:
		var x := (i - 1.5) * 0.55 * facing
		var p := Build.pivot(n, Vector3(x, 0.03, (i % 2) * 0.24 - 0.12))
		Build.cyl(p, 0.13, 0.15, 0.03, Vector3.ZERO, m, 14)
		# little notch = cloven look
		Build.cyl(p, 0.035, 0.035, 0.032, Vector3(0.0, 0.002, 0.13), Mat.toon(Color("#ffe0f4"), {"outline": false}), 8)
		Fx.glow_sprite(p, Vector3(0, 0.1, 0), Color(1, 0.7, 0.9, 0.55), 0.55)
	Fx.aura(n, Color(1, 0.8, 0.95), 8, 0.6).position = Vector3(0, 0.3, 0)
	return n


static func glow_bell(parent: Node3D, pos: Vector3, color: Color, h: float = 0.8) -> Node3D:
	## night-time glowing bell flowers
	var n := Build.pivot(parent, pos)
	Build.capsule(n, 0.02, h, Vector3(0, h * 0.5, 0), Mat.toon(Color("#3fae94"), {"wind": 0.1, "sway_height": h}))
	var bell := Build.sphere(n, 0.15, Vector3(0.05, h, 0), Mat.glowing(color, 2.0, {"pulse": 0.8, "outline": false}), Vector3(1, 1.2, 1), 12)
	Fx.glow_sprite(n, Vector3(0.05, h, 0.05), Color(color.r, color.g, color.b, 0.5), 0.8)
	return n


static func fern(parent: Node3D, pos: Vector3, scale_v: float = 1.0, tint: Color = Color("#4fc98a")) -> Node3D:
	if _leaf_mesh == null:
		_leaf_mesh = _leaf_blade(1.0, 0.26, 0.9, 7)
	var n := Build.pivot(parent, pos)
	var m := Mat.toon(tint, {"use_vertex_color": true, "two_sided": true, "wind": 0.1, "sway_height": 0.8, "rim_amount": 0.2})
	for i in 7:
		var a := float(i) / 7.0 * TAU
		var mi := MeshInstance3D.new()
		mi.mesh = _leaf_mesh
		mi.material_override = m
		mi.rotation = Vector3(0, a, 0.15 * (i % 3))
		mi.scale = Vector3.ONE * scale_v * (0.8 + 0.3 * (i % 3) / 2.0)
		n.add_child(mi)
	return n


static func log_platform(parent: Node3D, pos: Vector3, length: float, r: float = 0.4) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.position = pos
	parent.add_child(sb)
	var bark := Mat.toon_grad(Color("#8a5a4e"), Color("#b98a68"), -r, r, {"outline": false, "rim_amount": 0.15})
	Build.cyl(sb, r, r, length, Vector3.ZERO, bark, 16, Vector3(0, 0, PI * 0.5))
	Build.cyl(sb, r * 0.7, r * 0.7, 0.04, Vector3(length * 0.5 + 0.005, 0, 0), Mat.toon(Color("#e8c8a0"), {"outline": false}), 14, Vector3(0, 0, PI * 0.5))
	Build.sphere(sb, r * 0.9, Vector3(0, r * 0.75, 0), Mat.toon(Color("#6fdc8a"), {"outline": false, "rim_amount": 0.0}), Vector3(length * 0.6 / r, 0.28, 0.9), 12)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(length, r * 1.6, 1.6)
	cs.shape = bs
	sb.add_child(cs)
	return sb


static func lantern(parent: Node3D, pos: Vector3, color: Color = Color("#ffe6a0")) -> Node3D:
	var n := Build.pivot(parent, pos)
	Build.cyl(n, 0.012, 0.012, 0.5, Vector3(0, 0.25, 0), Mat.toon(Color("#8a5a4e"), {}), 6)
	Build.sphere(n, 0.13, Vector3.ZERO, Mat.glowing(color, 1.6, {"pulse": 0.4, "outline": false}), Vector3(1, 1.15, 1), 12)
	Fx.glow_sprite(n, Vector3.ZERO, Color(color.r, color.g, color.b, 0.5), 1.4)
	return n


## Soft light shafts (additive) for that golden-hour forest look.
static func light_shafts(parent: Node3D, center: Vector3, count: int, spread: float, color: Color = Color(1, 0.95, 0.7, 0.16), seed_v: int = 3) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := Build.pivot(parent, center)
	for i in count:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(rng.randf_range(1.6, 3.2), rng.randf_range(9.0, 14.0))
		mi.mesh = q
		var col := color
		col.a *= rng.randf_range(0.6, 1.2)
		mi.material_override = Mat.additive(col, FxTex.beam())
		mi.position = Vector3(rng.randf_range(-spread, spread), 4.5, rng.randf_range(-9.0, -3.0))
		mi.rotation = Vector3(0, 0, deg_to_rad(rng.randf_range(12.0, 24.0)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		var tw := mi.create_tween().set_loops()
		tw.tween_property(mi, "rotation:z", mi.rotation.z + 0.05, rng.randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mi, "rotation:z", mi.rotation.z - 0.05, rng.randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)
	return n


## Layered far hills / distant trees for depth (fog does the atmospheric perspective).
static func backdrop(parent: Node3D, x0: float, x1: float, palette: Array, seed_v: int = 5) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := Build.pivot(parent, Vector3.ZERO)
	var layers := [
		{"z": -95.0, "h": 34.0, "w": 60.0, "y": -4.0, "col": palette[0]},
		{"z": -68.0, "h": 24.0, "w": 42.0, "y": -3.0, "col": palette[1]},
		{"z": -44.0, "h": 15.0, "w": 30.0, "y": -2.0, "col": palette[2]},
	]
	for L in layers:
		var mat := Mat.toon_grad(L.col.darkened(0.05), L.col.lightened(0.2), L.y, L.y + L.h, {"outline": false, "rim_amount": 0.0, "gradient_amount": 1.0, "shade_strength": 0.2})
		var x: float = x0 - 40.0
		while x < x1 + 60.0:
			var w: float = L.w * rng.randf_range(0.7, 1.4)
			var hh: float = L.h * rng.randf_range(0.55, 1.15)
			Build.sphere(n, 1.0, Vector3(x, L.y + hh * 0.35, L.z), mat, Vector3(w * 0.6, hh, w * 0.5), 14)
			x += w * rng.randf_range(0.6, 0.9)
	return n
