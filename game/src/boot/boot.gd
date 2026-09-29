extends Node
## Entry point. Normal launch goes to the storybook main menu.
## Developer flags (after `--`):  --scene=<id>  --preset=<name>  --shot=<file.png> --shot-delay=<s>  --check

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
	# Boot node stays alive as a harmless parent for autoloads' children; scenes attach to root.
	Router.go_now.call_deferred(scene, args)   # root is still busy setting up children inside _ready
