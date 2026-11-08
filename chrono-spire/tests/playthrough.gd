extends SceneTree
var g
var frames=0
var timeout=4200
var failures=[]
func _initialize(): call_deferred("begin")
func begin():
	g=load("res://scripts/Game.gd").new()
	root.add_child(g)
	g.start_mission(0)
	g.invulnerable=0
	g.tests={}
func aim_at(p):
	var delta=p-g.camera.global_position
	g.yaw=atan2(-delta.x,-delta.z)
	g.pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
func _physics_process(dt):
	if not is_instance_valid(g): return false
	frames+=1
	g.tests={}
	g.mouse_attack=false
	if g.won:
		print("PASS: Physical end-to-end traversal, puzzles, reflected bolt, combat, boss, core; ticks="+str(frames)+" health="+str(g.health)+" falls="+str(g.falls))
		g.queue_free()
		call_deferred("quit",0)
		return false
	if frames>timeout or not g.active:
		print("FAIL: playthrough stage="+str(g.stage)+" position="+str(g.player.position)+" enemies="+str(g.enemies.size()))
		call_deferred("quit",1)
		return false
	match g.stage:
		0:
			g.yaw=0
			g.tests.go=true
		1:
			if g.player.position.z>-7:
				g.yaw=0
				g.tests.go=true
			elif g.puzzles[0].age>0.01:
				aim_at(g.target_position(g.puzzles[0]))
				g.locked=g.puzzles[0]
				g.tests.reverse=true
			else:
				g.yaw=0
				g.tests.go=true
		2:
			if g.puzzles[1].age<0.99:
				g.locked=g.puzzles[1]
				aim_at(g.target_position(g.puzzles[1]))
				g.tests.forward=true
			else:
				g.yaw=0
				g.tests.go=true
		3:
			if not g.bolts.is_empty():
				g.locked=g.bolts[0]
				aim_at(g.bolts[0].node.position)
				g.tests.reverse=true
				g.tests.bubble=true
			if g.enemies.is_empty():
				g.yaw=0
				g.tests.go=true
		4,5:
			if not g.enemies.is_empty():
				var target=g.enemies[0]
				aim_at(target.node.position+Vector3(0,0.4,0))
				g.locked=target
				if target.kind=="golem" and target.exposed<=0: g.tests.reverse=true
				else: g.tests.fire=true
				if g.player.position.distance_to(target.node.position)>12: g.tests.go=true
			else:
				g.yaw=0
				g.tests.go=true
		6:
			aim_at(g.portal.position)
			if g.player.position.distance_to(g.portal.position)>6: g.tests.go=true
			else: g.tests.fire=true
	return false
