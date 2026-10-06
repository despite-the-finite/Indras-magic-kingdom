extends LevelBase
## INSIDE THE CASTLE - free play behind the front door (Mode 2, "home").
## Four connected rooms along one hallway, so a small child can never get lost or stuck between scenes:
##   Great Hall (music box, portraits with a secret, the way back out)
##   Throne Room (sit on the throne, the magic mirror opens dress-up)
##   Bedroom     (a cozy nap, the toy box)
##   Kitchen     (bake a rainbow cake, the cookie jar)
## Rescued friends wander the rooms too. Nothing here is required by the story; it is a place to *be* a princess.

const ROOM_W := 15.0
const HALL_X := 7.5
const THRONE_X := 22.5
const MIRROR_X := 27.6
const BED_X := 36.0
const TOYBOX_X := 41.0
const OVEN_X := 50.0
const TABLE_X := 55.2
const JAR_X := 58.0
const DOOR_X := 1.6
const PAINTING_X := 5.0
const MUSIC_X := 3.2

var lumi_w: Wanderer
var lumi_pet: Interactable
var throne_used := false
var cake_baked := false
var naps := 0

var _throne_seat := Vector3.ZERO
var _bed_top := Vector3.ZERO
var _cake: Node3D
var _oven_glow: MeshInstance3D
var _painting: Node3D
var _music_dancer: Node3D
var _secret_done := false
var _story_busy := false
var _used: Dictionary = {}
var _wall_colors := [Color("#f6d6ea"), Color("#e8d8ff"), Color("#d8ecff"), Color("#fff0d0")]


func _configure() -> void:
	preset = "castle_inside"
	min_x = 1.0
	max_x = ROOM_W * 4.0 - 1.0
	kill_y = -6.0
	spawn = Vector3(float(Router.params.get("spawn_x", 3.2)), 0.3, 0)
	music_cue = "castle_theme"
	ambience = ["stable_soft"]


func _build_world() -> void:
	terrain = Terrain.build(self, [
		{"x0": 0.0, "x1": ROOM_W * 4.0, "pts": [[0, 0.0], [ROOM_W * 4.0, 0.0]]},   # its end walls close the hallway
	], {"top_color": Color("#f6dcef"), "top_color_far": Color("#dcc2ea"), "dirt_color": Color("#c9a8d8"), "dirt_dark": Color("#7a5a9a"),
		"path_color": Color("#e8506e"), "color_drift": false, "step": 1.0, "z_back": -9.5})
	_shell()
	_great_hall()
	_throne_room()
	_bedroom()
	_kitchen()
	add_zone("room_great_hall", 2.0, 6.0)
	add_zone("room_throne", ROOM_W + 0.5, ROOM_W + 4.0)
	add_zone("room_bedroom", ROOM_W * 2.0 + 0.5, ROOM_W * 2.0 + 4.0)
	add_zone("room_kitchen", ROOM_W * 3.0 + 0.5, ROOM_W * 3.0 + 4.0)
	Events.zone_entered.connect(_on_zone)


# =============================================================================
# the building
# =============================================================================
func _shell() -> void:
	var trim := Mat.toon(Color("#ffd9a0"), {"outline": false, "rim_amount": 0.3})
	var stone := Mat.toon_grad(Color("#c3a0d0"), Color("#e8ccf0"), 0.0, 8.0, {"outline": false, "rim_amount": 0.15, "gradient_amount": 1.0})
	for i in 4:
		var cx := HALL_X + i * ROOM_W
		var wall := Mat.toon_grad(_wall_colors[i].darkened(0.12), _wall_colors[i].lightened(0.1), 0.0, 7.5, {"outline": false, "rim_amount": 0.1, "gradient_amount": 1.0, "shade_tint": Color(0.75, 0.6, 0.95)})
		Build.box(self, Vector3(ROOM_W + 0.4, 7.6, 0.5), Vector3(cx, 3.8, -7.2), wall)
		# wainscot + gold rail
		Build.box(self, Vector3(ROOM_W + 0.4, 1.2, 0.56), Vector3(cx, 0.6, -7.2), Mat.toon(_wall_colors[i].darkened(0.3), {"outline": false}))
		Build.box(self, Vector3(ROOM_W + 0.4, 0.1, 0.6), Vector3(cx, 1.22, -7.2), trim)
		# a tall window with daylight
		for wx in [cx - 4.5, cx + 4.5]:
			if i == 0 and wx < HALL_X:
				continue   # the front door lives there
			CastleKit.window(self, Vector3(wx, 3.4, -6.9), 1.4, 2.4)
			Build.box(self, Vector3(1.9, 0.18, 0.5), Vector3(wx, 2.1, -6.8), trim)
		_chandelier(Vector3(cx, 4.4, -2.0))
	# dividers with an archway on the play lane
	for k in range(1, 4):
		var x := k * ROOM_W
		Build.box(self, Vector3(0.7, 7.6, 5.4), Vector3(x, 3.8, -4.5), stone)
		Build.box(self, Vector3(0.7, 3.2, 3.6), Vector3(x, 5.9, 0.0), stone)
		var arch := MeshInstance3D.new()
		arch.mesh = Build.arc_ribbon(2.1, 0.5, 180.0, 36)
		arch.material_override = trim
		arch.position = Vector3(x, 2.3, 0.0)
		arch.rotation = Vector3(0, PI * 0.5, 0)
		add_child(arch)
		for pz in [-1.9, 2.1]:
			Build.cyl(self, 0.2 if pz > 0.0 else 0.22, 0.26, 4.4, Vector3(x, 2.2, pz), stone, 12)
			Build.sphere(self, 0.34, Vector3(x, 4.45, pz), trim, Vector3.ONE, 12)
	# ceiling garland of pennants (festive, always moving)
	for i in 30:
		var gx := 1.0 + i * 2.0
		var q := Build.quad(self, Vector2(0.5, 0.7), Vector3(gx, 4.9 - sin(float(i) / 29.0 * PI * 6.0) * 0.15, -1.0),
			Mat.toon([Mat.PINK, Mat.SKY, Mat.SUN, Mat.LILAC, Mat.MINT][i % 5], {"two_sided": true, "wind": 0.35, "wind_speed": 2.5, "sway_height": 0.7, "outline": false}))
		q.rotation.x = PI
	# solid end walls (the terrain's own walls only guard cliffs from below)
	for wx in [-0.3, ROOM_W * 4.0 + 0.3]:
		var wb := StaticBody3D.new()
		wb.collision_layer = 1
		var wcs := CollisionShape3D.new()
		var wbs := BoxShape3D.new()
		wbs.size = Vector3(0.6, 8.0, 6.0)
		wcs.shape = wbs
		wb.add_child(wcs)
		wb.position = Vector3(wx, 4.0, 0)
		add_child(wb)
	Build.box(self, Vector3(0.7, 7.6, 9.0), Vector3(ROOM_W * 4.0 + 0.35, 3.8, -2.5), stone)
	# ambient life
	Fx.pollen(self, Vector3(ROOM_W * 2.0, 2.5, -1.0), Vector3(30, 2.0, 3), 50, Color(1, 0.95, 0.75, 0.8))


func _chandelier(pos: Vector3) -> void:
	var n := Build.pivot(self, pos)
	var gold := Mat.glowing(Mat.GOLD, 0.5, {"outline": false})
	Build.cyl(n, 0.02, 0.02, 2.2, Vector3(0, 1.1, 0), gold, 6)
	Build.torus(n, 0.75, 0.85, Vector3.ZERO, gold, Vector3.ZERO, 24)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		ForestProps.lantern(n, Vector3(cos(a) * 0.8, 0.25, sin(a) * 0.8), Color("#ffe6b0"))
	var ol := OmniLight3D.new()
	ol.light_color = Color(1, 0.88, 0.7)
	ol.light_energy = 0.6
	ol.omni_range = 11.0
	ol.position = Vector3(0, -0.4, 0.8)
	n.add_child(ol)


func _painting_frame(pos: Vector3, color_a: Color, color_b: Color) -> Node3D:
	var n := Build.pivot(self, pos)
	Build.box(n, Vector3(1.9, 1.5, 0.12), Vector3.ZERO, Mat.toon(Mat.GOLD, {"outline": 0.008}))
	Build.box(n, Vector3(1.6, 1.2, 0.16), Vector3(0, 0, 0.02), Mat.toon_grad(color_a, color_b, -0.6, 0.6, {"outline": false, "gradient_amount": 1.0, "rim_amount": 0.2}))
	return n


# =============================================================================
# rooms
# =============================================================================
func _great_hall() -> void:
	var y := 0.0
	# the front door (the way back to the garden)
	var door_m := Mat.toon(Color("#b98a68"), {"outline": 0.01})
	Build.box(self, Vector3(3.4, 4.4, 0.4), Vector3(DOOR_X, 2.2, -6.9), Mat.toon(Color("#c9a0e8"), {"outline": false}))
	Build.cyl(self, 1.7, 1.7, 0.4, Vector3(DOOR_X, 4.4, -6.9), Mat.toon(Color("#c9a0e8"), {"outline": false}), 24, Vector3(PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		Build.box(self, Vector3(1.4, 4.0, 0.2), Vector3(DOOR_X + sx * 0.75, 2.0, -6.7), door_m)
		Build.sphere(self, 0.08, Vector3(DOOR_X + sx * 0.25, 2.0, -6.55), Mat.glowing(Mat.GOLD, 0.8), Vector3.ONE, 8)
	Build.cyl(self, 1.4, 1.4, 0.3, Vector3(DOOR_X, 4.4, -6.75), Mat.glowing(Color("#bfe6ff"), 1.0, {"outline": false}), 24, Vector3(PI * 0.5, 0, 0))
	var fd := Interactable.make(self, "front_door", "press", "", Vector3(DOOR_X, y, 0), 2.2)
	fd.icon = "back"
	fd.halo_height = 2.4
	fd.press_anim = "wave"
	fd.one_shot = false
	fd.activated.connect(func(_p): _leave())
	# grand staircase sweeping up behind the hall
	var stair := Mat.toon_grad(Color("#d8b8e8"), Color("#f4e4ff"), 0.0, 2.4, {"outline": false, "rim_amount": 0.2, "gradient_amount": 1.0})
	var carpet := Mat.toon(Color("#e8506e"), {"outline": false, "rim_amount": 0.1})
	for k in 6:
		Build.box(self, Vector3(4.2, 0.36, 0.8), Vector3(11.0, 0.18 + k * 0.36, -3.0 - k * 0.72), stair)
		Build.box(self, Vector3(1.6, 0.02, 0.82), Vector3(11.0, 0.37 + k * 0.36, -3.0 - k * 0.72), carpet)
		for sx in [-1.0, 1.0]:
			Build.cyl(self, 0.05, 0.06, 0.8, Vector3(11.0 + sx * 2.0, 0.76 + k * 0.36, -3.0 - k * 0.72), Mat.toon(Mat.GOLD, {"outline": false}), 8)
	Build.cyl(self, 0.06, 0.06, 5.2, Vector3(9.0, 1.4 + 1.1, -4.8), Mat.toon(Mat.GOLD, {"outline": false}), 8, Vector3(deg_to_rad(-42), 0, 0))
	Build.cyl(self, 0.06, 0.06, 5.2, Vector3(13.0, 1.4 + 1.1, -4.8), Mat.toon(Mat.GOLD, {"outline": false}), 8, Vector3(deg_to_rad(-42), 0, 0))
	# portraits: the castle fills with friends as they are rescued
	_painting = _painting_frame(Vector3(PAINTING_X, 3.3, -6.85), Color("#ffb0d8"), Color("#ffe6f4"))
	Build.sphere(_painting, 0.3, Vector3(0, 0.05, 0.12), Mat.toon(Color("#ffd2b0"), {"outline": 0.006}), Vector3.ONE, 14)   # the princess
	Build.cone(_painting, 0.16, 0.22, Vector3(0, 0.44, 0.12), Mat.glowing(Mat.GOLD, 0.8, {"outline": false}), Vector3.ZERO, 8)
	var pin := Interactable.make(self, "painting", "press", "", Vector3(PAINTING_X, y, 0), 1.7)
	pin.icon = "sparkle"
	pin.halo_height = 2.2
	pin.press_anim = "curious"
	pin.activated.connect(func(_p): _reveal_painting())
	if GameState.secret_found("castle_painting"):
		pin.used = true
		_secret_done = true
	var p2 := _painting_frame(Vector3(8.0, 3.3, -6.85), Color("#c9a0ff"), Color("#f0e6ff"))
	if GameState.is_at_castle("lumi"):
		Build.sphere(p2, 0.3, Vector3(0, 0.0, 0.12), Mat.toon(Color("#fff4fb"), {"outline": 0.006}), Vector3(1.2, 0.9, 1.0), 14)
		Build.cone(p2, 0.06, 0.34, Vector3(0, 0.42, 0.12), Mat.glowing(Color("#ffe27a"), 1.2, {"outline": false}), Vector3.ZERO, 8)
	else:
		Build.sphere(p2, 0.32, Vector3(0, 0.0, 0.12), Mat.toon(Color("#d8c8f0"), {"outline": false, "rim_amount": 0.0}), Vector3(1.2, 0.9, 0.3), 10)   # still empty
	# the music box on a little table
	Build.cyl(self, 0.7, 0.75, 0.12, Vector3(MUSIC_X, 0.9, -2.4), Mat.toon(Color("#b98a68"), {"outline": 0.008}), 18)
	Build.cyl(self, 0.08, 0.1, 0.9, Vector3(MUSIC_X, 0.45, -2.4), Mat.toon(Color("#b98a68"), {"outline": 0.008}), 10)
	var mbox := Build.pivot(self, Vector3(MUSIC_X, 0.96, -2.4))
	Build.box(mbox, Vector3(0.7, 0.3, 0.5), Vector3(0, 0.15, 0), Mat.toon(Color("#ff8fbf"), {"outline": 0.008, "glitter": 0.3}))
	Build.box(mbox, Vector3(0.7, 0.04, 0.5), Vector3(0, 0.32, 0), Mat.toon(Mat.GOLD, {"outline": false}))
	Build.cyl(mbox, 0.02, 0.02, 0.3, Vector3(0.4, 0.15, 0), Mat.toon(Mat.GOLD, {"outline": false}), 6, Vector3(0, 0, PI * 0.5))
	_music_dancer = Build.pivot(mbox, Vector3(0, 0.34, 0))
	Build.cone(_music_dancer, 0.14, 0.26, Vector3(0, 0.13, 0), Mat.toon(Color("#c9a0ff"), {"outline": false}), Vector3.ZERO, 10)
	Build.sphere(_music_dancer, 0.07, Vector3(0, 0.32, 0), Mat.toon(Color("#ffd2b0"), {"outline": false}), Vector3.ONE, 8)
	var mi := Interactable.make(self, "music_box", "press", "", Vector3(MUSIC_X, y, 0), 1.8)
	mi.icon = "sound"
	mi.halo_height = 2.0
	mi.press_anim = "curious"
	mi.one_shot = false
	mi.activated.connect(func(_p): _play_music_box())
	# a resident friend wanders the halls
	if GameState.is_at_castle("lumi"):
		_spawn_lumi()


func _throne_room() -> void:
	var x := THRONE_X
	var gold := Mat.glowing(Mat.GOLD, 0.45, {"outline": 0.008})
	var stone := Mat.toon_grad(Color("#d8b8e8"), Color("#f4e4ff"), 0.0, 1.0, {"outline": false, "rim_amount": 0.2, "gradient_amount": 1.0})
	# dais of three round steps behind the lane
	var dz := -2.9
	for k in 3:
		Build.cyl(self, 2.8 - k * 0.5, 2.9 - k * 0.5, 0.3, Vector3(x, 0.15 + k * 0.3, dz), stone, 32)
		Build.torus(self, 2.75 - k * 0.5, 2.9 - k * 0.5, Vector3(x, 0.3 + k * 0.3, dz), Mat.toon(Mat.GOLD, {"outline": false}), Vector3.ZERO, 32)
	var top := 0.9
	Build.box(self, Vector3(1.4, 0.02, 2.0), Vector3(x, top + 0.011, dz + 1.0), Mat.toon(Color("#e8506e"), {"outline": false}))
	# the throne
	var th := Build.pivot(self, Vector3(x, top, dz - 0.2))
	Build.box(th, Vector3(1.5, 0.55, 1.2), Vector3(0, 0.27, 0), gold)
	Build.box(th, Vector3(1.4, 0.25, 1.1), Vector3(0, 0.62, 0.05), Mat.toon(Color("#ff8fbf"), {"outline": 0.008, "rim_amount": 0.5}))
	Build.box(th, Vector3(1.5, 2.3, 0.3), Vector3(0, 1.15, -0.55), gold)
	Build.box(th, Vector3(1.3, 1.9, 0.12), Vector3(0, 1.25, -0.37), Mat.toon(Color("#c9a0ff"), {"outline": false, "glitter": 0.4}))
	for sx in [-1.0, 1.0]:
		Build.box(th, Vector3(0.25, 0.7, 1.1), Vector3(sx * 0.72, 0.9, 0.05), gold)
		Build.sphere(th, 0.16, Vector3(sx * 0.72, 1.3, 0.5), Mat.glowing(Mat.PINK, 0.8, {"outline": false}), Vector3.ONE, 10)
	# a heart crowning the throne back
	var heart := Build.pivot(th, Vector3(0, 2.45, -0.55))
	Build.sphere(heart, 0.2, Vector3(-0.15, 0.1, 0), Mat.glowing(Mat.PINK, 1.0, {"outline": 0.006}), Vector3.ONE, 12)
	Build.sphere(heart, 0.2, Vector3(0.15, 0.1, 0), Mat.glowing(Mat.PINK, 1.0, {"outline": 0.006}), Vector3.ONE, 12)
	Build.cone(heart, 0.3, 0.36, Vector3(0, -0.1, 0), Mat.glowing(Mat.PINK, 1.0, {"outline": 0.006}), Vector3(PI, 0, 0), 4)
	Fx.aura(th, Color(1, 0.9, 0.6), 16, 0.9).position = Vector3(0, 1.4, 0.3)
	_throne_seat = Vector3(x, top + 0.74, dz + 0.05)
	var ti := Interactable.make(self, "throne", "press", "", Vector3(x, 0, 0), 2.4)
	ti.icon = "crown"
	ti.halo_height = 2.8
	ti.press_anim = "wonder"
	ti.one_shot = false
	ti.activated.connect(func(_p): _sit_on_throne())
	# banners
	for bx in [x - 5.5, x + 5.5]:
		var q := Build.quad(self, Vector2(1.4, 2.6), Vector3(bx, 4.6, -6.6), Mat.toon(Mat.PINK if bx < x else Mat.LILAC, {"two_sided": true, "wind": 0.25, "wind_speed": 1.8, "sway_height": 2.4, "outline": false, "glitter": 0.2}))
		q.rotation.x = PI
		Build.cyl(self, 0.05, 0.05, 1.8, Vector3(bx, 5.95, -6.5), Mat.toon(Mat.GOLD, {"outline": false}), 8, Vector3(0, 0, PI * 0.5))
	# the magic mirror
	var mx := MIRROR_X
	var mm := Build.pivot(self, Vector3(mx, 0, -2.3))
	Build.cyl(mm, 0.8, 0.9, 0.3, Vector3(0, 0.15, 0), gold, 18)
	Build.cyl(mm, 0.12, 0.16, 0.8, Vector3(0, 0.6, 0), gold, 10)
	var frame := Build.pivot(mm, Vector3(0, 2.1, 0))
	Build.torus(frame, 0.95, 1.1, Vector3.ZERO, gold, Vector3(PI * 0.5, 0, 0), 32)
	var glass := Build.cyl(frame, 0.96, 0.96, 0.06, Vector3.ZERO, Mat.glowing(Color("#c8ecff"), 1.3, {"pulse": 0.6, "outline": false, "glitter": 0.6}), 32, Vector3(PI * 0.5, 0, 0))
	glass.scale = Vector3(1.0, 1.0, 1.35)
	frame.scale = Vector3(1.0, 1.35, 1.0)
	for i in 8:
		var a := float(i) / 8.0 * TAU
		Build.sphere(frame, 0.08, Vector3(cos(a) * 1.08, sin(a) * 1.08, 0.05), Mat.glowing([Mat.PINK, Mat.SKY, Mat.SUN, Mat.MINT][i % 4], 1.2, {"outline": false}), Vector3.ONE, 8)
	Fx.aura(mm, Color(0.85, 0.95, 1.0), 14, 0.8).position = Vector3(0, 2.1, 0.3)
	var mri := Interactable.make(self, "mirror", "press", "", Vector3(mx, 0, 0), 2.0)
	mri.icon = "dress"
	mri.halo_height = 3.4
	mri.press_anim = "wonder"
	mri.one_shot = false
	mri.activated.connect(func(_p): _use_mirror())


func _bedroom() -> void:
	var x := BED_X
	var wood := Mat.toon(Color("#b98a68"), {"outline": 0.008})
	var bed := Build.pivot(self, Vector3(x, 0, -2.6))
	Build.box(bed, Vector3(3.4, 0.5, 2.2), Vector3(0, 0.25, 0), wood)
	Build.box(bed, Vector3(3.2, 0.35, 2.0), Vector3(0, 0.67, 0), Mat.toon(Color("#fff4fb"), {"outline": 0.008}))
	Build.box(bed, Vector3(2.2, 0.3, 2.02), Vector3(0.5, 0.88, 0), Mat.toon_grad(Color("#b58cf2"), Color("#d8c0ff"), 0.7, 1.1, {"outline": 0.008, "gradient_amount": 1.0, "glitter": 0.25}))
	for sz in [-0.5, 0.5]:
		Build.sphere(bed, 0.3, Vector3(-1.1, 0.98, sz), Mat.toon(Color("#ffd9f0"), {"outline": 0.006}), Vector3(1.4, 0.6, 1.0), 12)
	Build.box(bed, Vector3(0.3, 2.0, 2.3), Vector3(-1.6, 1.0, 0), wood)
	for sx in [-1.55, 1.55]:
		for sz in [-1.0, 1.0]:
			Build.cyl(bed, 0.07, 0.08, 3.4, Vector3(sx, 1.7, sz), Mat.toon(Mat.GOLD, {"outline": false}), 8)
	Build.box(bed, Vector3(3.6, 0.25, 2.5), Vector3(0, 3.45, 0), Mat.toon(Color("#ff8fbf"), {"outline": 0.008}))
	for sz in [-1.2, 1.2]:
		var cq := Build.quad(bed, Vector2(0.9, 2.3), Vector3(-1.6, 2.2, sz), Mat.toon(Color("#ffd9f0"), {"two_sided": true, "wind": 0.12, "wind_speed": 1.5, "sway_height": 2.2, "outline": false}))
		cq.rotation = Vector3(PI, PI * 0.5, 0)
	Fx.aura(bed, Color(1, 0.95, 0.8), 10, 0.6).position = Vector3(0.4, 1.3, 0)
	_bed_top = Vector3(x + 0.3, 0.84 + 0.22, -2.4)
	var bi := Interactable.make(self, "bed", "press", "", Vector3(x, 0, 0), 2.4)
	bi.icon = "moon"
	bi.halo_height = 2.9
	bi.press_anim = "wonder"
	bi.one_shot = false
	bi.activated.connect(func(_p): _nap())
	# a rug, a shelf with a teddy, a rocking horse of blocks
	Build.cyl(self, 2.6, 2.6, 0.04, Vector3(x, 0.02, -1.2), Mat.toon(Color("#ffd9f0"), {"outline": false, "rim_amount": 0.0}), 28)
	Build.box(self, Vector3(2.6, 0.12, 0.6), Vector3(x - 5.0, 2.2, -6.6), wood)
	var teddy := Build.pivot(self, Vector3(x - 5.4, 2.26, -6.6))
	var fur := Mat.toon(Color("#c8905a"), {"outline": 0.006, "rim_amount": 0.4})
	Build.sphere(teddy, 0.28, Vector3(0, 0.28, 0), fur, Vector3.ONE, 12)
	Build.sphere(teddy, 0.2, Vector3(0, 0.66, 0), fur, Vector3.ONE, 12)
	for sx in [-1.0, 1.0]:
		Build.sphere(teddy, 0.08, Vector3(sx * 0.16, 0.82, 0), fur, Vector3.ONE, 8)
		Build.sphere(teddy, 0.1, Vector3(sx * 0.3, 0.3, 0.05), fur, Vector3.ONE, 8)
	Build.sphere(teddy, 0.04, Vector3(-0.07, 0.68, 0.18), Mat.toon(Color("#2a1638"), {"outline": false}), Vector3.ONE, 6)
	Build.sphere(teddy, 0.04, Vector3(0.07, 0.68, 0.18), Mat.toon(Color("#2a1638"), {"outline": false}), Vector3.ONE, 6)
	for k in 4:
		Build.box(self, Vector3(0.4, 0.4, 0.4), Vector3(x - 4.2 + (k % 2) * 0.45, 0.2 + (k / 2) * 0.42, -6.0), Mat.toon([Mat.PINK, Mat.SKY, Mat.SUN, Mat.MINT][k], {"outline": 0.008}))
	# the toy box
	var tb := Build.pivot(self, Vector3(TOYBOX_X, 0, -2.4))
	Build.box(tb, Vector3(1.6, 0.9, 1.1), Vector3(0, 0.45, 0), Mat.toon(Color("#6ec6f5"), {"outline": 0.01}))
	Build.box(tb, Vector3(1.6, 0.08, 1.1), Vector3(0, 0.9, 0), Mat.toon(Mat.GOLD, {"outline": false}))
	var lid := Build.box(tb, Vector3(1.6, 0.18, 1.1), Vector3(0, 1.0, -0.55), Mat.toon(Color("#3f9ad8"), {"outline": 0.01}))
	lid.rotation.x = deg_to_rad(-70.0)
	for k in 3:
		Build.sphere(tb, 0.18, Vector3(-0.4 + k * 0.4, 1.0, 0.1 - (k % 2) * 0.2), Mat.toon([Mat.PINK, Mat.SUN, Mat.MINT][k], {"outline": 0.006, "rim_amount": 0.5}), Vector3.ONE, 10)
	var tbi := Interactable.make(self, "toy_box", "press", "", Vector3(TOYBOX_X, 0, 0), 2.0)
	tbi.icon = "star"
	tbi.halo_height = 2.2
	tbi.press_anim = "curious"
	tbi.one_shot = false
	tbi.activated.connect(func(_p): _open_toy_box())


func _kitchen() -> void:
	var wood := Mat.toon(Color("#b98a68"), {"outline": 0.008})
	var x0 := ROOM_W * 3.0
	# long counter along the back wall
	Build.box(self, Vector3(12.0, 1.0, 1.4), Vector3(x0 + 7.5, 0.5, -5.8), Mat.toon(Color("#f6d8c0"), {"outline": 0.008}))
	Build.box(self, Vector3(12.2, 0.12, 1.5), Vector3(x0 + 7.5, 1.06, -5.8), Mat.toon(Color("#ffffff"), {"outline": false, "rim_amount": 0.2}))
	for k in 6:
		Build.box(self, Vector3(1.6, 0.6, 0.06), Vector3(x0 + 2.4 + k * 1.9, 0.5, -5.08), Mat.toon(Color("#e8c0a0"), {"outline": false}))
		Build.sphere(self, 0.05, Vector3(x0 + 2.4 + k * 1.9, 0.5, -5.03), Mat.glowing(Mat.GOLD, 0.6), Vector3.ONE, 6)
	# tiles behind the counter
	for k in 12:
		for j in 3:
			Build.box(self, Vector3(0.85, 0.85, 0.08), Vector3(x0 + 2.0 + k * 0.95, 1.65 + j * 0.95, -6.9), Mat.toon([Color("#bfe6ff"), Color("#ffd9f0")][(k + j) % 2], {"outline": false}))
	# hanging pans + kettle steam
	for k in 3:
		Build.cyl(self, 0.3, 0.3, 0.12, Vector3(x0 + 9.0 + k * 0.9, 3.9, -6.4), Mat.toon(Color("#c0b0d8"), {"outline": 0.006}), 16, Vector3(PI * 0.5, 0, 0))
	Build.cyl(self, 0.28, 0.34, 0.4, Vector3(x0 + 4.4, 1.32, -5.6), Mat.toon(Color("#ff9ab8"), {"outline": 0.008}), 14)
	Fx.pollen(self, Vector3(x0 + 4.4, 2.0, -5.6), Vector3(0.3, 0.8, 0.3), 12, Color(1, 1, 1, 0.7))
	# the oven
	var ox := OVEN_X
	var ov := Build.pivot(self, Vector3(ox, 0, -5.7))
	Build.box(ov, Vector3(2.4, 1.9, 1.5), Vector3(0, 0.95, 0), Mat.toon(Color("#ff8fbf"), {"outline": 0.01}))
	Build.box(ov, Vector3(1.5, 1.0, 0.1), Vector3(0, 0.75, 0.74), Mat.toon(Color("#2a1a4a"), {"outline": false, "shade_strength": 0.0, "rim_amount": 0.0}))
	_oven_glow = Build.box(ov, Vector3(1.3, 0.8, 0.08), Vector3(0, 0.75, 0.78), Mat.glowing(Color("#ffb060"), 0.6, {"outline": false, "pulse": 0.3}))
	Build.box(ov, Vector3(1.6, 0.08, 0.14), Vector3(0, 1.3, 0.8), Mat.toon(Mat.GOLD, {"outline": false}))
	for k in 3:
		Build.cyl(ov, 0.08, 0.08, 0.1, Vector3(-0.5 + k * 0.5, 1.6, 0.78), Mat.toon(Mat.GOLD, {"outline": false}), 10, Vector3(PI * 0.5, 0, 0))
	Build.box(ov, Vector3(0.6, 2.6, 0.6), Vector3(0, 3.2, -0.3), Mat.toon(Color("#c3a0d0"), {"outline": false}))
	var oi := Interactable.make(self, "oven", "press", "", Vector3(ox, 0, 0), 2.4)
	oi.icon = "sparkle"
	oi.halo_height = 2.6
	oi.press_anim = "cast"
	oi.one_shot = false
	oi.activated.connect(func(_p): _bake())
	# the table where the cake appears
	Build.cyl(self, 1.3, 1.35, 0.14, Vector3(TABLE_X, 0.96, -2.5), wood, 24)
	Build.cyl(self, 0.12, 0.2, 0.9, Vector3(TABLE_X, 0.45, -2.5), wood, 10)
	Build.cyl(self, 1.15, 1.15, 0.02, Vector3(TABLE_X, 1.04, -2.5), Mat.toon(Color("#fff4fb"), {"outline": false}), 24)
	_cake = Build.pivot(self, Vector3(TABLE_X, 1.05, -2.5))
	_build_cake(_cake)
	_cake.scale = Vector3.ZERO
	_cake.visible = false
	# fruit bowl + the cookie jar
	Build.cyl(self, 0.45, 0.3, 0.3, Vector3(x0 + 11.4, 1.25, -5.6), Mat.toon(Color("#bfe6ff"), {"outline": 0.008}), 16)
	for k in 5:
		Build.sphere(self, 0.14, Vector3(x0 + 11.3 + cos(k * 1.3) * 0.2, 1.46 + (k % 2) * 0.1, -5.6 + sin(k * 1.3) * 0.2), Mat.toon([Color("#ff6f8f"), Color("#ffb04a"), Color("#a684ff")][k % 3], {"outline": 0.006, "rim_amount": 0.5}), Vector3.ONE, 10)
	var jar := Build.pivot(self, Vector3(JAR_X, 1.12, -5.5))
	Build.cyl(jar, 0.36, 0.3, 0.6, Vector3(0, 0.3, 0), Mat.toon(Color("#fff0d8"), {"outline": 0.008, "rim_amount": 0.4}), 16)
	Build.cyl(jar, 0.38, 0.38, 0.1, Vector3(0, 0.65, 0), Mat.toon(Mat.PINK, {"outline": 0.008}), 16)
	Build.sphere(jar, 0.08, Vector3(0, 0.75, 0), Mat.toon(Mat.PINK, {"outline": false}), Vector3.ONE, 8)
	for k in 3:
		Build.cyl(jar, 0.14, 0.14, 0.05, Vector3(-0.1 + k * 0.1, 0.2 + k * 0.1, 0.32), Mat.toon(Color("#c88a50"), {"outline": false}), 12, Vector3(PI * 0.5, 0, 0))
	var ji := Interactable.make(self, "cookie_jar", "press", "", Vector3(JAR_X - 0.5, 0, 0), 1.8)
	ji.icon = "apple"
	ji.halo_height = 2.4
	ji.press_anim = "feed"
	ji.one_shot = false
	ji.activated.connect(func(_p): _cookies())
	# a rainbow window over the sink
	var arc := MeshInstance3D.new()
	arc.mesh = Build.arc_ribbon(1.1, 0.4, 180.0, 32)
	arc.material_override = Mat.rainbow_material()
	arc.position = Vector3(x0 + 7.5, 4.6, -6.8)
	add_child(arc)


func _build_cake(n: Node3D) -> void:
	var tiers := [[0.9, Mat.PINK], [0.65, Color("#c9a0ff")], [0.42, Mat.SUN]]
	var y := 0.0
	for t in tiers:
		var r: float = t[0]
		Build.cyl(n, r, r, 0.34, Vector3(0, y + 0.17, 0), Mat.toon(t[1], {"outline": 0.008, "rim_amount": 0.4, "glitter": 0.25}), 24)
		Build.cyl(n, r + 0.02, r + 0.02, 0.06, Vector3(0, y + 0.34, 0), Mat.toon(Color("#fff4fb"), {"outline": false}), 24)
		for k in 8:
			var a := float(k) / 8.0 * TAU
			Build.sphere(n, 0.04, Vector3(cos(a) * r * 0.9, y + 0.37, sin(a) * r * 0.9), Mat.toon([Mat.SKY, Mat.MINT, Color.WHITE, Mat.PINK][k % 4], {"outline": false}), Vector3.ONE, 6)
		y += 0.36
	for k in 5:
		var a := float(k) / 5.0 * TAU
		var cp := Vector3(cos(a) * 0.22, y, sin(a) * 0.22)
		Build.cyl(n, 0.025, 0.025, 0.3, cp + Vector3(0, 0.15, 0), Mat.toon([Mat.PINK, Mat.SKY, Mat.SUN][k % 3], {"outline": false}), 6)
		Build.sphere(n, 0.05, cp + Vector3(0, 0.34, 0), Mat.glowing(Color("#ffe6a0"), 2.0, {"pulse": 0.8, "outline": false}), Vector3(1, 1.5, 1), 8)
	Fx.aura(n, Color(1, 0.9, 0.95), 10, 0.5).position = Vector3(0, 0.8, 0)


func _spawn_lumi() -> void:
	var lumi := UnicornRig.new("lumi")
	lumi_w = Wanderer.new()
	lumi_w.rig = lumi
	lumi_w.terrain = terrain
	lumi_w.x_min = 3.0
	lumi_w.x_max = ROOM_W * 4.0 - 3.0
	lumi_w.greet_target = player
	lumi_w.position = Vector3(10.0, 0, 0.6)
	lumi_w.z_lane = 0.6
	add_child(lumi_w)
	lumi.set_emotion("happy")
	var pet := Interactable.make(self, "lumi_pet", "press", "", Vector3.ZERO, 2.0)
	pet.icon = "heart"
	pet.one_shot = false
	pet.press_anim = "pet"
	pet.halo_height = 2.0
	pet.activated.connect(func(_p):
		lumi.set_emotion("joyful")
		lumi.play("hug")
		lumi_w._timer = 3.0
		Fx.heart_burst(self, lumi_w.global_position + Vector3(0, 1.4, 0), 8)
		Audio.sfx("happy_chime", -3.0))
	lumi_pet = pet


# =============================================================================
# story & guidance
# =============================================================================
func _after_ready() -> void:
	# LevelBase wires greet_target before Lumi exists; fix it up now that the player is here
	if lumi_w:
		lumi_w.greet_target = player
	if Router.params.has("skipintro"):
		_refresh_goal()
		return
	await get_tree().create_timer(0.5).timeout
	if Router.params.get("from_mirror", false):
		player.rig.play("spin")
		Fx.sparkle_burst(self, player.global_position + Vector3(0, 1.0, 0), Color(1, 0.9, 1), 30, 3.0, 0.3, 1.0)
	else:
		await Dialogue.play("castle_inside_intro")
	_refresh_goal()


## Flutter / the glow always point at the most fun thing she has not tried yet (and the door last).
func _refresh_goal() -> void:
	var order := ["throne", "oven", "bed", "music_box", "toy_box", "mirror", "cookie_jar", "front_door"]
	var target := "front_door"
	for id in order:
		if not _used.has(id):
			target = id
			break
	Hints.watch_step({"id": "inside_goal", "hint": {"voice": "castle_inside_hint", "voice_alt": "castle_inside_hint", "target": target}})


func _mark(id: String) -> void:
	_used[id] = true
	_refresh_goal()


func _on_zone(id: String) -> void:
	if id.begins_with("room_"):
		Dialogue.play_async(id)


func _level_process() -> void:
	if lumi_pet and lumi_w and is_instance_valid(lumi_w):
		lumi_pet.global_position = lumi_w.global_position
	if _music_dancer and _music_dancer.has_meta("spinning"):
		_music_dancer.rotation.y += get_process_delta_time() * 6.0


func _leave() -> void:
	if _story_busy:
		return
	_story_busy = true
	Audio.sfx("door_open")
	Router.go("castle", {"arrival": "from_inside", "spawn_x": 24.0}, "clouds")


# =============================================================================
# toys
# =============================================================================
func _sit_on_throne() -> void:
	if _story_busy:
		return
	_story_busy = true
	_mark("throne")
	throne_used = true
	player.frozen = true
	Audio.sfx("whoosh_soft", -4.0, 1.2)
	await player.glide_to(_throne_seat, 0.7, true, true)
	player.rig.play("sit")
	player.rig.facing = 1.0
	player.rig.face_camera_amount = 0.9
	player.rig.set_emotion("proud")
	cam.set_zoom(-1.6, 0.7)
	Audio.sting("rescue_sting", -6.0)
	Fx.star_shower(self, _throne_seat + Vector3(0, 3.5, 0.5), 50)
	Fx.sparkle_burst(self, _throne_seat + Vector3(0, 1.2, 0.4), Color(1, 0.9, 0.6), 40, 4.0, 0.36, 1.2)
	await Dialogue.play("throne_sit")
	await get_tree().create_timer(1.4).timeout
	cam.set_zoom(0.0, 0.7)
	player.rig.play("idle")
	player.rig.face_camera_amount = 0.0
	player.rig.set_emotion("happy")
	await player.glide_to(Vector3(THRONE_X, 0.05, 0.0), 0.6, true, true)
	player.release_glide()
	player.frozen = false
	_story_busy = false


func _use_mirror() -> void:
	if _story_busy:
		return
	_story_busy = true
	_mark("mirror")
	player.frozen = true
	Fx.sparkle_burst(self, Vector3(MIRROR_X, 2.1, -2.0), Color(0.85, 0.95, 1.0), 40, 4.0, 0.36, 1.2)
	Audio.sfx("magic_flourish", -2.0)
	await Dialogue.play("mirror_look")
	Router.go("customize", {"return_to": "castle_inside", "return_params": {"spawn_x": MIRROR_X - 1.0, "from_mirror": true}}, "page")


func _nap() -> void:
	if _story_busy:
		return
	_story_busy = true
	_mark("bed")
	naps += 1
	player.frozen = true
	await player.glide_to(_bed_top, 0.7, true, true)
	player.rig.play("sit")
	player.rig.facing = 1.0
	player.rig.face_camera_amount = 0.8
	player.rig.set_emotion("sleepy")
	var key: DirectionalLight3D = env.key
	var base := key.light_energy
	var base_amb: float = env.env.ambient_light_energy
	var tw := create_tween().set_parallel(true)
	tw.tween_property(key, "light_energy", base * 0.35, 0.9)
	tw.tween_property(env.env, "ambient_light_energy", base_amb * 0.5, 0.9)
	# floating z's: little stars drifting up
	for i in 4:
		var z := Fx.glow_sprite(self, _bed_top + Vector3(0.2, 0.9 + i * 0.1, 0.3), Color(1, 0.95, 0.7, 0.8), 0.5, FxTex.star4())
		var zt := create_tween()
		zt.tween_interval(0.5 * i)
		zt.tween_property(z, "position", z.position + Vector3(0.5, 1.6, 0), 2.0).set_trans(Tween.TRANS_SINE)
		zt.parallel().tween_property(z, "scale", Vector3.ZERO, 2.0).set_delay(0.5 * i)
		zt.tween_callback(z.queue_free)
	Audio.sfx("chime_soft", -6.0, 0.8)
	await Dialogue.play("bed_nap", {"line_gap": 0.6})
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(key, "light_energy", base, 0.6)
	tw2.tween_property(env.env, "ambient_light_energy", base_amb, 0.6)
	player.rig.set_emotion("joyful")
	player.rig.play("idle")
	player.rig.face_camera_amount = 0.0
	Fx.sparkle_burst(self, _bed_top + Vector3(0, 1.0, 0.4), Color(1, 0.95, 0.8), 20, 2.5, 0.3, 0.9)
	await player.glide_to(Vector3(BED_X, 0.05, 0.0), 0.6, true, true)
	player.release_glide()
	player.rig.set_emotion("happy")
	player.frozen = false
	_story_busy = false


func _open_toy_box() -> void:
	_mark("toy_box")
	Audio.sfx("boing", -3.0, 1.1)
	Fx.heart_burst(self, Vector3(TOYBOX_X, 1.6, -2.0), 6)
	Fx.flower_burst(self, Vector3(TOYBOX_X, 1.4, -2.0), [], 20)
	for k in 3:
		var ball := Build.sphere(self, 0.22, Vector3(TOYBOX_X, 1.2, -2.0), Mat.toon([Mat.PINK, Mat.SKY, Mat.SUN][k], {"outline": 0.006, "rim_amount": 0.5, "glitter": 0.3}), Vector3.ONE, 12)
		var tx := TOYBOX_X + (-2.2 + k * 2.2) * (0.6 + 0.4 * randf())
		var tw := create_tween()
		var hops := 4
		for h in hops:
			var height := 2.2 - h * 0.5
			var dur := 0.42 - h * 0.06
			var start_x := TOYBOX_X + (tx - TOYBOX_X) * float(h) / hops
			var end_x := TOYBOX_X + (tx - TOYBOX_X) * float(h + 1) / hops
			tw.tween_method(func(t: float):
				ball.position = Vector3(lerpf(start_x, end_x, t), 0.22 + sin(t * PI) * height, -2.0 + 0.8 * float(h + 1) / hops), 0.0, 1.0, dur)
			tw.tween_callback(func(): Audio.sfx("boing", -10.0 - h * 2, 1.2 + h * 0.15))
		tw.tween_interval(4.0)
		tw.tween_property(ball, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(ball.queue_free)
	Dialogue.play_async("toy_box")


func _play_music_box() -> void:
	_mark("music_box")
	_music_dancer.set_meta("spinning", true)
	Audio.sfx("chime_trail", -2.0)
	player.rig.play("dance")
	player.rig.set_emotion("joyful")
	Dialogue.play_async("music_box")
	# Flutter dances in a ring above the box; the princess dances along
	var center := Vector3(MUSIC_X, 2.4, -1.6)
	for i in 9:
		var a := float(i) / 8.0 * TAU * 1.5
		get_tree().create_timer(0.45 * i).timeout.connect(func():
			if is_instance_valid(flutter):
				flutter.guide_to(center + Vector3(cos(a) * 1.2, sin(a * 2.0) * 0.4, sin(a) * 0.5))
				Fx.sparkle_burst(self, center + Vector3(cos(a) * 1.2, 0, sin(a) * 0.5), [Mat.PINK, Mat.SKY, Mat.SUN, Mat.LILAC][i % 4], 6, 1.4, 0.22, 0.8)
				Audio.sfx("chime_soft", -8.0, 0.9 + (i % 5) * 0.12))
	get_tree().create_timer(4.4).timeout.connect(func():
		if is_instance_valid(flutter) and is_instance_valid(player):
			flutter.follow(player)
		if is_instance_valid(_music_dancer):
			_music_dancer.remove_meta("spinning"))


func _reveal_painting() -> void:
	if _secret_done:
		return
	_secret_done = true
	GameState.add_secret("castle_painting")
	Audio.sfx("secret_found")
	var tw := create_tween()
	tw.tween_property(_painting, "rotation:z", 0.35, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var star := spawn_big_star(Vector3(PAINTING_X + 0.6, 2.6, -6.4))
	star.scale = Vector3.ONE * 0.4
	Fx.sparkle_burst(self, star.global_position, Color(1, 0.92, 0.6), 40, 4.0, 0.36, 1.4)
	Dialogue.play_async("painting_secret")
	var st := create_tween()
	st.tween_property(star, "position", Vector3(PAINTING_X + 0.4, 3.9, -4.0), 1.4).set_trans(Tween.TRANS_SINE)
	st.tween_callback(func():
		earn_stars(1, star.global_position, "secret")
		star.queue_free())


func _bake() -> void:
	_mark("oven")
	cake_baked = true
	Audio.sfx("magic_charge", -3.0)
	var m := _oven_glow.material_override as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(func(v): m.set_shader_parameter("emission_energy", v), 0.6, 2.6, 0.6)
	tw.tween_interval(0.4)
	tw.tween_method(func(v): m.set_shader_parameter("emission_energy", v), 2.6, 0.6, 0.6)
	Fx.sparkle_burst(self, Vector3(OVEN_X, 1.0, -4.8), Color(1, 0.8, 0.5), 20, 2.0, 0.26, 0.9)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	Audio.sfx("chime_up", -2.0)
	_cake.visible = true
	_cake.scale = Vector3.ZERO
	var ct := create_tween()
	ct.tween_property(_cake, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.flower_burst(self, _cake.global_position + Vector3(0, 0.8, 0.6), [Mat.PINK, Mat.SUN, Color.WHITE], 24)
	Fx.sparkle_burst(self, _cake.global_position + Vector3(0, 0.8, 0.6), Color(1, 0.9, 0.95), 30, 3.0, 0.3, 1.0)
	player.rig.play("celebrate")
	player.rig.set_emotion("joyful")
	Dialogue.play_async("cake_baked")
	# a resident friend smells cake
	if lumi_w and is_instance_valid(lumi_w):
		lumi_w._greeting = false
		lumi_w._cooldown = 20.0
		lumi_w._target_x = TABLE_X - 2.0
		lumi_w.state = "walk"
		await get_tree().create_timer(2.6).timeout
		if is_instance_valid(lumi_w):
			lumi_w.rig.set_emotion("excited")
			lumi_w.rig.play("eat")
			Dialogue.play_async("lumi_visits_kitchen")


func _cookies() -> void:
	_mark("cookie_jar")
	Audio.sfx("munch", -2.0)
	var p := Vector3(JAR_X, 1.8, -4.6)
	Fx.sparkle_burst(self, p, Color("#d8a060"), 14, 2.4, 0.3, 0.9)
	Fx.heart_burst(self, p, 4)
	for k in 4:
		var c := Build.cyl(self, 0.15, 0.15, 0.05, p, Mat.toon(Color("#c88a50"), {"outline": 0.006}), 12, Vector3(PI * 0.5, 0, 0))
		var tw := create_tween()
		var tx := JAR_X - 1.5 + k * 0.6
		tw.tween_method(func(t: float): c.position = Vector3(lerpf(JAR_X, tx, t), 1.8 + sin(t * PI) * 1.4 - t * 1.6, lerpf(-4.6, -1.2, t)), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(2.0)
		tw.tween_property(c, "scale", Vector3.ZERO, 0.3)
		tw.tween_callback(c.queue_free)
	player.rig.set_emotion("giggle")
	Dialogue.play_async("cookie_jar")
	get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(player): player.rig.set_emotion("happy"))
