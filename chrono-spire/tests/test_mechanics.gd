extends SceneTree
const H=preload("res://scripts/History.gd")
var game
var passed=[]
func check(ok,message):
	if not ok:
		push_error("FAIL: "+message)
		quit(1)
		assert(ok,message)
	passed.append(message)
func ticks(n):
	for i in range(n):
		game._physics_process(1.0/60)
func _initialize(): call_deferred("run")
func run():
	var ring=H.new()
	for i in range(600): ring.record(Transform3D(Basis.IDENTITY,Vector3(i,0,0)),Vector3(i,1,0),Vector3(0,2,0),i%3,i%12,100-i*0.01)
	check(ring.count==480,"History is bounded to eight seconds / 480 samples")
	check(ring.past(479).transform.origin.x==120,"Ring wraps without losing chronological order")
	check(ring.pop().transform.origin.x==599,"Rewind pops newest state")
	check(ring.past(0).linear.x==598 and ring.past(0).angular.y==2,"Full velocity state retained")
	game=load("res://scripts/Game.gd").new()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_mission(0)
	check(game.active and game.stage==0,"Mission starts at interactive induction")
	game.tutorial_moved=4
	game.advance_progress()
	check(game.stage==1,"Movement tutorial advances")
	game.locked=game.puzzles[0]
	for i in range(125): game.time_power(true,false,1.0/60)
	game.update_puzzle(game.puzzles[0],0)
	check(game.puzzles[0].age<0.12 and not game.puzzles[0].shape.disabled,"Selective rewind reconstructs solid bridge")
	game.player.position=Vector3(0,1,-25)
	game.advance_progress()
	check(game.stage==2,"Crossing rebuilt bridge advances tutorial")
	game.energy=100
	game.locked=game.puzzles[1]
	for i in range(125): game.time_power(false,true,1.0/60)
	game.update_puzzle(game.puzzles[1],0)
	check(game.puzzles[1].age>0.88 and game.puzzles[1].shape.disabled,"Fast-forward corrodes door and removes collision")
	game.player.position=Vector3(0,1,-45)
	game.advance_progress()
	check(game.stage==3 and game.enemies.size()==1,"Turret encounter begins after door")
	var turret=game.enemies[0]
	game.spawn_bolt(turret)
	var bolt=game.bolts[0]
	bolt.node.position=Vector3(0,1,-49)
	var p=bolt.node.position
	game.bubble=true
	game.update_bolts(0.1)
	check(bolt.node.position.distance_to(p)<0.12,"Bubble slows incoming projectile by 90 percent")
	game.locked=bolt
	game.time_power(true,false,0.016)
	check(bolt.returning,"Rewind reverses a locked kinetic projectile")
	bolt.node.position=turret.node.position+Vector3(0,0,0.2)
	game.update_bolts(0.016)
	check(game.enemies.is_empty(),"Returned bolt destroys shielded tutorial turret")
	game.player.position=Vector3(0,1,-65)
	game.advance_progress()
	check(game.stage==4 and game.enemies.size()==3,"Foundry checkpoint spawns Stalkers and Remnant")
	var stalker=game.enemies[0]
	game.history.record(Transform3D(Basis.IDENTITY,Vector3(0,1,-74)),Vector3.ZERO,Vector3.ZERO,0,0,100)
	game.update_enemies(0.016,true)
	check(stalker.ambush>0 and stalker.node.position.z>-80,"Stalker ambushes recorded rewind destination")
	game.clear_combat()
	game.player.position=Vector3(0,1,-114)
	game.advance_progress()
	check(game.stage==5 and game.enemies[0].kind=="golem","Boss checkpoint progression")
	var golem=game.enemies[0]
	game.locked=golem
	game.energy=100
	for i in range(65): game.time_power(true,false,1.0/60)
	check(golem.exposed>4.8,"Rewinding armor opens five-second vulnerability")
	game.bubble=false
	game.update_enemies(5.1,false)
	check(golem.exposed==0,"Golem shield returns when cooling window ends")
	game.clear_combat()
	game.advance_progress()
	check(game.stage==6,"Core objective appears after enemy defeat")
	game.player.position=Vector3(0,1,-149)
	game.shoot()
	check(game.won and not game.active,"Core interaction completes narrative")
	print("PASS: "+str(passed.size())+" mechanics assertions")
	for s in passed: print("  "+s)
	game.queue_free()
	await process_frame
	await process_frame
	quit()
