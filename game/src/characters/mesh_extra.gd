class_name MeshExtra
## More procedural meshes: ribbons along a path (rainbow roads, vines, trails).

## Flat ribbon following `pts` (world/local XY path), extruded across Z by `width`. UV.x along the path (0..1), UV.y across.
static func path_ribbon(pts: Array[Vector3], width: float, thickness: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := 0.0
	var lens: Array[float] = [0.0]
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
		lens.append(total)
	var hw := width * 0.5
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var u0 := lens[i] / maxf(total, 0.001)
		var u1 := lens[i + 1] / maxf(total, 0.001)
		var a0 := a + Vector3(0, 0, -hw)
		var a1 := a + Vector3(0, 0, hw)
		var b0 := b + Vector3(0, 0, -hw)
		var b1 := b + Vector3(0, 0, hw)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(u0, 0)); st.add_vertex(a0)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(b0)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(b1)
		st.set_uv(Vector2(u0, 0)); st.add_vertex(a0)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(b1)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(a1)
	return st.commit()


## Thorny vine cage: a ring of spiky vines used around a trapped friend. Returns a Node3D (children are thorn vines).
static func thorn_ring(parent: Node3D, radius: float, height: float, mat: Material, thorn_mat: Material, seed_v: int = 1) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := Build.pivot(parent, Vector3.ZERO)
	for i in 9:
		var a := float(i) / 9.0 * TAU + rng.randf() * 0.2
		var base := Vector3(cos(a) * radius, 0, sin(a) * radius * 0.55)
		var seg := 6
		var prev := base
		for k in seg:
			var t := float(k + 1) / seg
			var sway := sin(t * 3.0 + a * 2.0) * 0.28
			var p := Vector3(cos(a + t * 0.9) * radius * (1.0 - t * 0.35) + sway, t * height, sin(a + t * 0.9) * radius * 0.55 * (1.0 - t * 0.35))
			var mid := (prev + p) * 0.5
			var d := p - prev
			var cap := Build.capsule(n, 0.07 * (1.0 - t * 0.4), d.length() * 1.25, mid, mat)
			cap.look_at_from_position(mid, mid + d, Vector3.UP)
			cap.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			if k % 2 == 0:
				var th := Build.cone(n, 0.05, 0.22, mid + Vector3(0, 0.05, 0.1), thorn_mat)
				th.rotation = Vector3(rng.randf_range(-0.8, 0.8), 0, rng.randf_range(-0.8, 0.8))
			prev = p
	return n
