extends Node
## Entry point. Normal launch goes to the storybook main menu.
## Developer flags (after `--`):  --scene=<id>  --preset=<name>  --shot=<file.png> --shot-delay=<s>  --check  --noident

func _ready() -> void:
	var args := DevTools.parse_args(OS.get_cmdline_user_args())
	if args.has("check"):
		DevTools.run_smoke_check()
		return
	if args.has("playthrough"):
		DevTools.attach_playthrough(get_tree())
		return
	# Load the save if there is one (the menu decides whether to offer "continue").
	GameState.load_game()
	if args.has("preset"):
		DevTools.apply_preset(String(args.preset))
	if args.has("shot"):
		DevTools.attach_shot(get_tree(), args)
	var scene := String(args.get("scene", "menu"))
	# A normal launch opens on the Entropic Labs ident, then fades into the menu.
	# Dev launches (--scene / --shot / --skipintro / --noident) and headless runs go straight in.
	var dev_launch := args.has("scene") or args.has("shot") or args.has("skipintro") or args.has("noident")
	if not dev_launch and DisplayServer.get_name() != "headless":
		var ident := Ident.new()
		add_child(ident)
		await ident.finished
	# Boot node stays alive as a harmless parent for autoloads' children; scenes attach to root.
	Router.go_now.call_deferred(scene, args)   # root is still busy setting up children inside _ready
