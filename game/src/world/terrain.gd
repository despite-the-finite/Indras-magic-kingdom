class_name Terrain
## Builds side-scroller ground from height "segments" (with cliff faces at gaps) plus trimesh collision.
## Each segment: {"x0": -10, "x1": 100, "pts": [[x, y], ...]}  (heights are smoothed with Catmull-Rom).

var segments: Array = []
var body: StaticBody3D
var z_back := -48.0
var z_front := 16.0      # front edge sits behind the camera so the cliff face is never in frame
var top_color := Color("#7fdc8f")
var top_color_far := Color("#4fb37f")
var dirt_color := Color("#b58a6a")
var dirt_dark := Color("#7a5a6a")
var step := 0.5
var path_color := Color(0, 0, 0, 0)     # optional cobblestone lane colour


static func build(parent: Node3D, segs: Array, opts: Dictionary = {}) -> Terrain:
	var t := Terrain.new()
	t.segments = segs
	for k in opts:
		t.set(k, opts[k])
	t._make(parent)
	return t


func height_at(x: float) -> float:
	for s in segments:
		if x >= s.x0 and x <= s.x1:
			return _seg_h(s, x)
	return -100.0


func in_gap(x: float) -> bool:
	return height_at(x) < -50.0


func _seg_h(s: Dictionary, x: float) -> float:
	var pts: Array = s.pts
	if pts.size() == 1:
		return float(pts[0][1])
	var i := 0
	while i < pts.size() - 2 and x > pts[i + 1][0]:
		i += 1
	var p0: Vector2 = Vector2(pts[maxi(i - 1, 0)][0], pts[maxi(i - 1, 0)][1])
	var p1: Vector2 = Vector2(pts[i][0], pts[i][1])
	var p2: Vector2 = Vector2(pts[i + 1][0], pts[i + 1][1])
	var p3: Vector2 = Vector2(pts[mini(i + 2, pts.size() - 1)][0], pts[mini(i + 2, pts.size() - 1)][1])
	var t := clampf((x - p1.x) / maxf(p2.x - p1.x, 0.001), 0.0, 1.0)
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1.y) + (-p0.y + p2.y) * t + (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 + (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)


func _make(parent: Node3D) -> void:
	body = StaticBody3D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var top_st := SurfaceTool.new()
	top_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side_st := SurfaceTool.new()
	side_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col_faces := PackedVector3Array()
	for s in segments:
		var n := int(ceil((s.x1 - s.x0) / step))
		for i in n:
			var xa: float = s.x0 + i * step
			var xb: float = minf(s.x0 + (i + 1) * step, s.x1)
			var ya := _seg_h(s, xa)
			var yb := _seg_h(s, xb)
			# top surface: 3 depth bands for colour variation (lighter toward the play lane)
			var zs := [z_back, -9.0, -1.6, 1.4, z_front]
			for b in 4:
				var za: float = zs[b]
				var zb: float = zs[b + 1]
				var c0 := _top_col(za, xa)
				var c1 := _top_col(zb, xa)
				var c2 := _top_col(zb, xb)
				var c3 := _top_col(za, xb)
				_quad(top_st, Vector3(xa, ya, za), Vector3(xb, yb, za), Vector3(xb, yb, zb), Vector3(xa, ya, zb), c0, c3, c2, c1)
			# collision: only the play strip
			var zc0 := -1.2
			var zc1 := 1.2
			col_faces.append_array([Vector3(xa, ya, zc0), Vector3(xb, yb, zc0), Vector3(xb, yb, zc1),
				Vector3(xa, ya, zc0), Vector3(xb, yb, zc1), Vector3(xa, ya, zc1)])
		# cliff faces at both ends and the front edge
		var depth := -8.0
		for end in [0, 1]:
			var x: float = s.x0 if end == 0 else s.x1
			var y := _seg_h(s, x)
			var flip: bool = end == 0
			_wall(side_st, Vector3(x, y, z_back), Vector3(x, y, z_front), depth, flip)
		# front face (facing the camera)
		for i in n:
			var xa2: float = s.x0 + i * step
			var xb2: float = minf(s.x0 + (i + 1) * step, s.x1)
			var ya2 := _seg_h(s, xa2)
			var yb2 := _seg_h(s, xb2)
			side_st.set_color(dirt_color)
			side_st.add_vertex(Vector3(xa2, ya2, z_front))
			side_st.set_color(dirt_color)
			side_st.add_vertex(Vector3(xb2, yb2, z_front))
			side_st.set_color(dirt_dark)
			side_st.add_vertex(Vector3(xb2, depth, z_front))
			side_st.set_color(dirt_color)
			side_st.add_vertex(Vector3(xa2, ya2, z_front))
			side_st.set_color(dirt_dark)
			side_st.add_vertex(Vector3(xb2, depth, z_front))
			side_st.set_color(dirt_dark)
			side_st.add_vertex(Vector3(xa2, depth, z_front))
	top_st.generate_normals()
	var top_mesh := top_st.commit()
	var grass_mat := Mat.toon(Color.WHITE, {"use_vertex_color": true, "rim_amount": 0.0, "shade_strength": 0.4})
	var mi := MeshInstance3D.new()
	mi.mesh = top_mesh
	mi.material_override = grass_mat
	body.add_child(mi)
	side_st.generate_normals()
	var side_mesh := side_st.commit()
	var mi2 := MeshInstance3D.new()
	mi2.mesh = side_mesh
	mi2.material_override = Mat.toon(Color.WHITE, {"use_vertex_color": true, "rim_amount": 0.0, "two_sided": true})
	body.add_child(mi2)
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(col_faces)
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)


func _top_col(z: float, x: float) -> Color:
	var k := clampf(-z / 30.0, 0.0, 1.0)
	var c := top_color.lerp(top_color_far, k)
	# soft large-scale colour drift so the meadow isn't flat
	var v := sin(x * 0.11) * 0.5 + sin(x * 0.047 + 1.7) * 0.5
	c = c.lerp(Color("#c8e070") if v > 0.0 else Color("#2f9a8a"), absf(v) * 0.38)
	if path_color.a > 0.0 and z > -1.7 and z < 1.5:
		c = c.lerp(path_color, 0.85)
	return c


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	st.set_color(ca); st.add_vertex(a)
	st.set_color(cb); st.add_vertex(b)
	st.set_color(cc); st.add_vertex(c)
	st.set_color(ca); st.add_vertex(a)
	st.set_color(cc); st.add_vertex(c)
	st.set_color(cd); st.add_vertex(d)


func _wall(st: SurfaceTool, top_a: Vector3, top_b: Vector3, depth: float, flip: bool) -> void:
	var a := top_a
	var b := top_b
	var c := Vector3(top_b.x, depth, top_b.z)
	var d := Vector3(top_a.x, depth, top_a.z)
	var order := [a, b, c, a, c, d]
	if flip:
		order = [a, c, b, a, d, c]
	for i in order.size():
		var v: Vector3 = order[i]
		st.set_color(dirt_color if v.y > depth + 0.1 else dirt_dark)
		st.add_vertex(v)
