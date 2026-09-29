class_name Build
## Tiny mesh-building helpers so characters and props can be assembled in a few readable lines.
## (Procedural stand-ins until authored .glb models replace them; see docs/ASSET_PIPELINE.md.)

static func _mi(parent: Node, mesh: Mesh, pos: Vector3, mat: Material, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	if mat:
		m.material_override = mat
	m.position = pos
	m.scale = scl
	m.rotation = rot
	parent.add_child(m)
	return m


static func pivot(parent: Node, pos: Vector3 = Vector3.ZERO, node_name: String = "") -> Node3D:
	var n := Node3D.new()
	n.position = pos
	if node_name != "":
		n.name = node_name
	parent.add_child(n)
	return n


static func sphere(parent: Node, r: float, pos: Vector3 = Vector3.ZERO, mat: Material = null, scl: Vector3 = Vector3.ONE, seg: int = 24) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = maxi(seg / 2, 6)
	return _mi(parent, s, pos, mat, scl)


static func capsule(parent: Node, r: float, h: float, pos: Vector3 = Vector3.ZERO, mat: Material = null, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0)
	c.radial_segments = 20
	c.rings = 6
	return _mi(parent, c, pos, mat, scl, rot)


static func cyl(parent: Node, r_top: float, r_bottom: float, h: float, pos: Vector3 = Vector3.ZERO, mat: Material = null, seg: int = 24, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return _mi(parent, c, pos, mat, Vector3.ONE, rot)


static func cone(parent: Node, r: float, h: float, pos: Vector3 = Vector3.ZERO, mat: Material = null, rot: Vector3 = Vector3.ZERO, seg: int = 16) -> MeshInstance3D:
	return cyl(parent, 0.0, r, h, pos, mat, seg, rot)


static func torus(parent: Node, inner: float, outer: float, pos: Vector3 = Vector3.ZERO, mat: Material = null, rot: Vector3 = Vector3.ZERO, seg: int = 28) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = seg
	t.ring_segments = 12
	return _mi(parent, t, pos, mat, Vector3.ONE, rot)


static func box(parent: Node, size: Vector3, pos: Vector3 = Vector3.ZERO, mat: Material = null, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mi(parent, b, pos, mat, Vector3.ONE, rot)


static func quad(parent: Node, size: Vector2, pos: Vector3 = Vector3.ZERO, mat: Material = null, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	return _mi(parent, q, pos, mat, Vector3.ONE, rot)


# ---- custom meshes -------------------------------------------------------------
## Crescent moon (flat, slightly thick) in the XY plane, opening toward +X... used for the moon tiara.
static func crescent(outer_r: float, inner_offset: float, thickness: float = 0.03, segs: int = 24) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_r := outer_r * 0.82
	var pts_o: Array[Vector2] = []
	var pts_i: Array[Vector2] = []
	# outer arc from angle a0..a1 (a big arc), inner arc is a circle shifted by inner_offset
	var a0 := deg_to_rad(52.0)
	var a1 := deg_to_rad(308.0)
	for i in segs + 1:
		var a := lerpf(a0, a1, float(i) / segs)
		pts_o.append(Vector2(cos(a), sin(a)) * outer_r)
	# inner arc: points on the shifted circle, same angular sweep mirrored back
	for i in segs + 1:
		var a := lerpf(a1, a0, float(i) / segs)
		pts_i.append(Vector2(cos(a), sin(a)) * inner_r + Vector2(inner_offset, 0))
	var ring: Array[Vector2] = []
	ring.append_array(pts_o)
	ring.append_array(pts_i)
	var n := ring.size()
	for face_z in [thickness * 0.5, -thickness * 0.5]:
		for i in range(1, n - 1):
			var flip: bool = face_z < 0.0
			var a := Vector3(ring[0].x, ring[0].y, face_z)
			var b := Vector3(ring[i].x, ring[i].y, face_z)
			var c := Vector3(ring[i + 1].x, ring[i + 1].y, face_z)
			st.set_normal(Vector3(0, 0, -1 if flip else 1))
			if flip:
				st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
			else:
				st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	return st.commit()


## Hanging cape: local +Y runs *away from the shoulders* (so the wind sway in toon.gdshader grows with distance).
static func cape_mesh(w_top: float, w_bottom: float, length: float, cols: int = 5, rows: int = 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in rows:
		for c in cols:
			var pts: Array[Vector3] = []
			for d in [[0, 0], [1, 0], [1, 1], [0, 1]]:
				var rr: float = float(r + d[1]) / rows
				var cc: float = float(c + d[0]) / cols - 0.5
				var w: float = lerpf(w_top, w_bottom, rr)
				var bulge := sin(rr * PI) * 0.03 * (1.0 - absf(cc) * 1.6)
				pts.append(Vector3(cc * w, rr * length, bulge + cc * cc * 0.10 * rr))
			for tri in [[0, 1, 2], [0, 2, 3]]:
				for k in tri:
					st.set_normal(Vector3(0, 0, 1))
					st.set_uv(Vector2(pts[k].x, pts[k].y))
					st.add_vertex(pts[k])
	st.generate_normals()
	return st.commit()


## Butterfly / fairy wing: rounded double lobe, in the XY plane, attached at the origin, extending to +X.
static func wing_mesh(size: float = 1.0, segs: int = 20) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline: Array[Vector2] = []
	for i in segs + 1:
		# teardrop-ish ellipse rooted at the origin, extending to +X
		var a := float(i) / segs * TAU
		var p := Vector2(1.0 - cos(a), sin(a) * 0.72) * 0.5
		p.x += sin(a) * 0.06 * absf(sin(a))
		outline.append(p * size * 2.0)
	for i in segs:
		var a := Vector3(0, 0, 0)
		var b := Vector3(outline[i].x, outline[i].y, 0)
		var c := Vector3(outline[i + 1].x, outline[i + 1].y, 0)
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(a)
		st.set_uv(Vector2(b.x, b.y))
		st.add_vertex(b)
		st.set_uv(Vector2(c.x, c.y))
		st.add_vertex(c)
	return st.commit()


## Extruded rounded-ish 5-point star in the XY plane (front faces +Z). Used for wand tips, crown gems, Magic Stars.
static func star_mesh(r_outer: float = 0.1, r_inner: float = 0.045, depth: float = 0.03, points: int = 5) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector2] = []
	for i in points * 2:
		var a := PI * 0.5 + float(i) / (points * 2) * TAU
		var r := r_outer if i % 2 == 0 else r_inner
		ring.append(Vector2(cos(a), sin(a)) * r)
	var h := depth * 0.5
	var n := ring.size()
	# front and back caps (triangle fan from the centre)
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(0, 0, h))
		st.add_vertex(Vector3(a.x, a.y, h * 0.35))
		st.add_vertex(Vector3(b.x, b.y, h * 0.35))
		st.set_normal(Vector3(0, 0, -1))
		st.add_vertex(Vector3(0, 0, -h))
		st.add_vertex(Vector3(b.x, b.y, -h * 0.35))
		st.add_vertex(Vector3(a.x, a.y, -h * 0.35))
	# rim
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		st.add_vertex(Vector3(a.x, a.y, h * 0.35))
		st.add_vertex(Vector3(a.x, a.y, -h * 0.35))
		st.add_vertex(Vector3(b.x, b.y, -h * 0.35))
		st.add_vertex(Vector3(a.x, a.y, h * 0.35))
		st.add_vertex(Vector3(b.x, b.y, -h * 0.35))
		st.add_vertex(Vector3(b.x, b.y, h * 0.35))
	st.generate_normals()
	return st.commit()


## Flat curved ribbon (an arc in the XY plane), UV.x along the arc, UV.y across the width. Used for rainbows.
static func arc_ribbon(radius: float, width: float, arc_deg: float = 180.0, segs: int = 48, start_deg: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var a0 := deg_to_rad(start_deg + arc_deg * t0)
		var a1 := deg_to_rad(start_deg + arc_deg * t1)
		var o0 := Vector3(cos(a0), sin(a0), 0) * (radius + width * 0.5)
		var i0 := Vector3(cos(a0), sin(a0), 0) * (radius - width * 0.5)
		var o1 := Vector3(cos(a1), sin(a1), 0) * (radius + width * 0.5)
		var i1 := Vector3(cos(a1), sin(a1), 0) * (radius - width * 0.5)
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(Vector2(t0, 0)); st.add_vertex(i0)
		st.set_uv(Vector2(t0, 1)); st.add_vertex(o0)
		st.set_uv(Vector2(t1, 1)); st.add_vertex(o1)
		st.set_uv(Vector2(t0, 0)); st.add_vertex(i0)
		st.set_uv(Vector2(t1, 1)); st.add_vertex(o1)
		st.set_uv(Vector2(t1, 0)); st.add_vertex(i1)
	return st.commit()
