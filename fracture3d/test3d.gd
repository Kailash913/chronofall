extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var g=load("res://Game.gd").new()
	root.add_child(g)
	g.set_physics_process(false)
	g.begin()
	assert(g.enemies.size()==3)
	for i in range(120): g._physics_process(1.0/60)
	assert(g.history.size()>0)
	g.controls["REWIND"]=true
	g._physics_process(1.0/60)
	assert(g.charge<100)
	g.controls.clear()
	for wave in range(3):
		for en in g.enemies: en.queue_free()
		g.enemies.clear()
		g._physics_process(1.0/60)
	assert(not g.active and g.stage==3)
	print("PASS: startup, mission start, history, rewind charge, three-wave progression and victory")
	quit()
