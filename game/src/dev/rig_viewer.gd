extends Node3D
## Developer scene: look-dev for characters.
##   --who=princess|lumi|luna|clover|flutter|all   --app=hair_style:puffs,dress:sun_gown   --emotion=joyful
##   --anim=wave   --front=1   --stars=8   --env=day_forest   --ov=key_energy:0.5   --cam=0,1.2,4.4

func _ready() -> void:
	var args: Dictionary = Router.params
	var ov := {}
	if args.has("ov"):
		for kv in String(args.ov).split(","):
			var p := kv.split(":")
			if p.size() == 2:
				ov[p[0]] = float(p[1])
	EnvKit.apply(self, String(args.get("env", "day_forest")), ov)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 30)
	ground.mesh = pm
	ground.material_override = Mat.toon_grad(Color("#78d99a"), Color("#a5f0a0"), -1.0, 1.0, {"rim_amount": 0.0})
	add_child(ground)

	var app := GameState.appearance().duplicate(true)
	if args.has("app"):
		for kv in String(args.app).split(","):
			var p := kv.split(":")
			if p.size() == 2:
				app[p[0]] = p[1]
	var who := String(args.get("who", "princess"))
	var stars := int(args.get("stars", -1))
	if stars >= 0:
		GameState.data.stars = stars

	var cam := FollowCam.new()
	add_child(cam)
	cam.set_process(false)
	var cp := String(args.get("cam", "0,1.2,4.4" if who != "all" else "0,1.3,7.2")).split(",")
	cam.global_position = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))
	cam.rotation_degrees = Vector3(-4, 0, 0)
	cam.fov = 36

	var rigs: Array = []
	var all := who == "all"
	if who == "princess" or all:
		var pr := PrincessRig.new(app)
		add_child(pr)
		pr.position = Vector3(-1.9 if all else 0.0, 0, 0)
		rigs.append(pr)
	if who == "lumi" or all:
		var lu := UnicornRig.new("lumi")
		add_child(lu)
		lu.position = Vector3(0.1 if all else 0.0, 0, 0)
		rigs.append(lu)
	if who == "luna":
		var lu2 := UnicornRig.new("luna")
		add_child(lu2)
		rigs.append(lu2)
	if who == "clover" or all:
		var rb := RabbitRig.new()
		add_child(rb)
		rb.position = Vector3(1.7 if all else 0.0, 0, 0)
		rigs.append(rb)
	if who == "flutter" or all:
		var fl := Flutter.new()
		add_child(fl)
		fl.hold_at(Vector3(-0.2 if all else 0.0, 1.0, 0.5))
		fl.global_position = Vector3(-0.2 if all else 0.0, 1.8, 0.5)
	for r in rigs:
		r.face_camera_amount = float(args.get("front", 0.0))
		if args.has("emotion"):
			r.set_emotion(String(args.emotion))
		if args.has("anim"):
			r.play(String(args.anim))
