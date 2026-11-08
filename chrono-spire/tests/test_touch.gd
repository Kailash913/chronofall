extends SceneTree
func _initialize(): call_deferred("run")
func touch(g,id,pos,pressed):
	var e=InputEventScreenTouch.new()
	e.index=id
	e.position=pos
	e.pressed=pressed
	g.hud._input(e)
func drag(g,id,pos):
	var e=InputEventScreenDrag.new()
	e.index=id
	e.position=pos
	g.hud._input(e)
func run():
	var g=load("res://scripts/Game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.start_mission(0)
	g.mobile=true
	touch(g,0,Vector2(200,500),true)
	drag(g,0,Vector2(200,420))
	assert(g.hud.move_stick.y<-0.9)
	touch(g,1,Vector2(1010,430),true)
	drag(g,1,Vector2(1070,440))
	assert(g.hud.look_stick.x>0.5)
	touch(g,2,Vector2(820,640),true)
	assert(g.down("reverse",KEY_Q))
	touch(g,2,Vector2(820,640),false)
	touch(g,0,Vector2(200,420),false)
	touch(g,1,Vector2(1070,440),false)
	assert(g.hud.move_stick==Vector2.ZERO and g.hud.look_stick==Vector2.ZERO and not g.down("reverse",KEY_Q))
	g.pause_game()
	assert(g.paused and is_instance_valid(g.hud.menu))
	g.pause_game()
	assert(not g.paused and not is_instance_valid(g.hud.menu))
	print("PASS: simultaneous move/look/power touches, releases, pause and resume")
	g.queue_free()
	await process_frame
	quit()
