extends SceneTree
var g
func _initialize(): call_deferred("run")
func snap(name):
	for i in range(5): await process_frame
	root.get_texture().get_image().save_png("res://builds/"+name+".png")
	print(name+" draw calls: "+str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
func run():
	g=load("res://scripts/Game.gd").new()
	root.add_child(g)
	await snap("menu")
	g.start_mission(0)
	g.set_physics_process(false)
	g.player.position=Vector3(0,1,-5)
	g.pitch=-0.15
	g.camera.rotation.x=g.pitch
	g.stage=1
	for p in g.puzzles: g.update_puzzle(p,0)
	g.hud.queue_redraw()
	await snap("induction")
	g.mobile=true
	g.hud.queue_redraw()
	await snap("mobile-controls")
	g.mobile=false
	g.unlocked=2
	g.start_mission(2)
	g.set_physics_process(false)
	g.player.position=Vector3(0,1,-122)
	g.camera.rotation.x=0
	g.hud.queue_redraw()
	await snap("golem")
	g.mobile=true
	for i in range(10):
		g.spawn_bolt(g.enemies[i%2])
		var bolt=g.bolts[-1]
		bolt.node.position=Vector3(-5+i,1.5,-128)
		for j in range(250): bolt.history.record(bolt.node.transform,Vector3.ZERO,Vector3.ZERO,0,0,10)
	g.update_echoes()
	g.hud.queue_redraw()
	await snap("combat-stress")
	g.queue_free()
	await process_frame
	await process_frame
	quit()
