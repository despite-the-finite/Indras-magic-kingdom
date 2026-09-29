class_name Fx
## Particle + effect builders. All effects follow one recipe (docs/STYLE_BIBLE.md, "particle style"):
## soft additive glows, 4-point sparkles, hearts and petals; warm-to-cool colour ramps; gentle upward drift.

static func _ramp(colors: Array, offsets: Array = []) -> GradientTexture1D:
	var g := Gradient.new()
	var n := colors.size()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for i in n:
		var off: float = offsets[i] if i < offsets.size() else float(i) / maxf(n - 1, 1)
		g.add_point(off, colors[i])
	# add_point leaves the two default points; remove them
	g.remove_point(0)
	g.remove_point(0)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


static func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p in points:
		c.add_point(p)
	var t := CurveTexture.new()
	t.curve = c
	return t


static func _quad_material(tex: Texture2D, blend_add: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if blend_add else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.disable_receive_shadows = true
	m.particles_anim_h_frames = 1
	m.particles_anim_v_frames = 1
	return m


static func _emitter(tex: Texture2D, pm: ParticleProcessMaterial, amount: int, lifetime: float, blend_add: bool = true) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = maxi(1, int(amount * Settings.particle_scale()))
	p.lifetime = lifetime
	p.process_material = pm
	var q := QuadMesh.new()
	q.material = _quad_material(tex, blend_add)
	q.size = Vector2.ONE
	p.draw_pass_1 = q
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-30, -10, -30), Vector3(60, 30, 60))
	p.fixed_fps = 0
	return p


static func _free_after(p: Node, seconds: float) -> void:
	var t := Timer.new()
	t.wait_time = seconds
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(p.queue_free)
	p.add_child(t)


# ---------------------------------------------------------------------------
# bursts (one-shot)
# ---------------------------------------------------------------------------
static func sparkle_burst(parent: Node, pos: Vector3, color: Color = Color(1, 0.9, 0.6), count: int = 26, speed: float = 3.2, size: float = 0.32, life: float = 1.1) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.15
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = speed * 0.4
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -1.2, 0)
	pm.damping_min = 1.2
	pm.damping_max = 2.2
	pm.scale_min = size * 0.5
	pm.scale_max = size
	pm.scale_curve = _curve([Vector2(0, 0.0), Vector2(0.15, 1.0), Vector2(1, 0.0)])
	pm.color_ramp = _ramp([Color(1, 1, 1, 0), color.lightened(0.4), color, Color(color.r, color.g, color.b, 0)], [0.0, 0.12, 0.55, 1.0])
	pm.angular_velocity_min = -120.0
	pm.angular_velocity_max = 120.0
	var p := _emitter(FxTex.star4(), pm, count, life)
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = true
	p.position = pos
	parent.add_child(p)
	_free_after(p, life + 0.6)
	return p


static func heart_burst(parent: Node, pos: Vector3, count: int = 8) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 55.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, 0.6, 0)
	pm.scale_min = 0.28
	pm.scale_max = 0.5
	pm.scale_curve = _curve([Vector2(0, 0.0), Vector2(0.2, 1.0), Vector2(1, 0.4)])
	pm.color_ramp = _ramp([Color(1, 0.5, 0.7, 0), Color(1, 0.55, 0.75, 1), Color(1, 0.7, 0.85, 0)], [0.0, 0.25, 1.0])
	var p := _emitter(FxTex.heart(), pm, count, 1.6, true)
	p.one_shot = true
	p.explosiveness = 0.6
	p.emitting = true
	p.position = pos
	parent.add_child(p)
	_free_after(p, 2.4)
	return p


static func flower_burst(parent: Node, pos: Vector3, colors: Array = [], count: int = 30) -> GPUParticles3D:
	if colors.is_empty():
		colors = [Mat.PINK, Mat.SUN, Mat.LILAC, Color.WHITE]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 75.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.6
	pm.gravity = Vector3(0, -3.0, 0)
	pm.scale_min = 0.16
	pm.scale_max = 0.34
	pm.angular_velocity_min = -220.0
	pm.angular_velocity_max = 220.0
	pm.color_ramp = _ramp([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 0.08, 0.7, 1.0])
	pm.color = colors[randi() % colors.size()]
	pm.hue_variation_min = -0.08
	pm.hue_variation_max = 0.08
	var p := _emitter(FxTex.petal(), pm, count, 1.9, false)
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	p.position = pos
	parent.add_child(p)
	_free_after(p, 2.6)
	# a second emitter with another colour for variety
	var pm2 := pm.duplicate() as ParticleProcessMaterial
	pm2.color = colors[(randi() + 1) % colors.size()]
	var p2 := _emitter(FxTex.petal(), pm2, count, 1.9, false)
	p2.one_shot = true
	p2.explosiveness = 0.9
	p2.emitting = true
	p2.position = pos
	parent.add_child(p2)
	_free_after(p2, 2.6)
	return p


static func star_shower(parent: Node, pos: Vector3, count: int = 40) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.0, 0.2, 1.0)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 20.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, -1.0, 0)
	pm.scale_min = 0.2
	pm.scale_max = 0.5
	pm.color_ramp = _ramp([Color(1, 1, 0.8, 0), Color(1, 0.95, 0.6, 1), Color(1, 0.8, 0.9, 0)], [0.0, 0.2, 1.0])
	pm.angular_velocity_min = -180.0
	pm.angular_velocity_max = 180.0
	var p := _emitter(FxTex.star4(), pm, count, 2.2)
	p.one_shot = true
	p.explosiveness = 0.3
	p.emitting = true
	p.position = pos
	parent.add_child(p)
	_free_after(p, 3.2)
	return p


# ---------------------------------------------------------------------------
# ambient (continuous)
# ---------------------------------------------------------------------------
static func fireflies(parent: Node, center: Vector3, extents: Vector3, count: int = 40, color: Color = Color(1, 0.95, 0.5)) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.45
	pm.turbulence_noise_scale = 1.6
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.12
	pm.scale_min = 0.14
	pm.scale_max = 0.3
	pm.color_ramp = _ramp([Color(color.r, color.g, color.b, 0), color, Color(color.r, color.g, color.b, 0.15), color, Color(color.r, color.g, color.b, 0)], [0.0, 0.15, 0.5, 0.8, 1.0])
	var p := _emitter(FxTex.glow(), pm, count, 7.0)
	p.preprocess = 7.0
	p.position = center
	p.visibility_aabb = AABB(-extents - Vector3(4, 4, 4), extents * 2.0 + Vector3(8, 8, 8))
	parent.add_child(p)
	return p


static func pollen(parent: Node, center: Vector3, extents: Vector3, count: int = 50, color: Color = Color(1, 0.96, 0.75, 0.9)) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0.3, 0.2, 0)
	pm.spread = 120.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	pm.gravity = Vector3(0.05, 0.03, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.25
	pm.turbulence_influence_min = 0.03
	pm.turbulence_influence_max = 0.08
	pm.scale_min = 0.05
	pm.scale_max = 0.13
	pm.color_ramp = _ramp([Color(color.r, color.g, color.b, 0), color, Color(color.r, color.g, color.b, 0)], [0.0, 0.3, 1.0])
	var p := _emitter(FxTex.glow(), pm, count, 9.0)
	p.preprocess = 9.0
	p.position = center
	p.visibility_aabb = AABB(-extents - Vector3(4, 4, 4), extents * 2.0 + Vector3(8, 8, 8))
	parent.add_child(p)
	return p


static func falling_petals(parent: Node, center: Vector3, extents: Vector3, count: int = 18, colors: Array = []) -> GPUParticles3D:
	if colors.is_empty():
		colors = [Mat.PINK, Mat.BLUSH]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0.25, -1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0.15, -0.4, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.7
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.18
	pm.scale_min = 0.12
	pm.scale_max = 0.24
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	pm.color = colors[0]
	pm.hue_variation_min = -0.05
	pm.hue_variation_max = 0.05
	pm.color_ramp = _ramp([Color(1, 1, 1, 0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)], [0.0, 0.1, 0.85, 1.0])
	var p := _emitter(FxTex.petal(), pm, count, 9.0, false)
	p.preprocess = 9.0
	p.position = center
	p.visibility_aabb = AABB(-extents - Vector3(4, 12, 4), extents * 2.0 + Vector3(8, 16, 8))
	parent.add_child(p)
	return p


static func aura(parent: Node, color: Color = Color(1, 0.9, 0.6), count: int = 14, radius: float = 0.6) -> GPUParticles3D:
	## continuous rising sparkles around a node (crown sparkles, glowing objects)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.12
	pm.scale_max = 0.26
	pm.scale_curve = _curve([Vector2(0, 0.0), Vector2(0.3, 1.0), Vector2(1, 0.0)])
	pm.color_ramp = _ramp([Color(color.r, color.g, color.b, 0), color, Color(color.r, color.g, color.b, 0)], [0.0, 0.3, 1.0])
	var p := _emitter(FxTex.star4(), pm, count, 1.8)
	parent.add_child(p)
	return p


static func trail(parent: Node, color: Color = Color(1, 0.8, 0.95), count: int = 30) -> GPUParticles3D:
	## particles left behind by a moving emitter (magic trail, hoofprint sparkles)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.08
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 90.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, -0.3, 0)
	pm.scale_min = 0.12
	pm.scale_max = 0.3
	pm.scale_curve = _curve([Vector2(0, 0.0), Vector2(0.15, 1.0), Vector2(1, 0.0)])
	pm.color_ramp = _ramp([Color(color.r, color.g, color.b, 0), color, Color(color.r, color.g, color.b, 0)], [0.0, 0.15, 1.0])
	var p := _emitter(FxTex.star4(), pm, count, 1.2)
	parent.add_child(p)
	return p


# ---------------------------------------------------------------------------
# single sprites
# ---------------------------------------------------------------------------
static func glow_sprite(parent: Node, pos: Vector3, color: Color, size: float = 1.0, tex: Texture2D = null) -> MeshInstance3D:
	## billboarded additive glow/sparkle quad
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.material_override = Mat.additive(color, tex if tex else FxTex.glow(), true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	parent.add_child(mi)
	return mi
