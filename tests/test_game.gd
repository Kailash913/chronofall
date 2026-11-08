extends SceneTree
class TestGame extends "res://Game.gd":
	var keys = {}
	func held(k: String) -> bool:
		return keys.get(k,false)
var g
func tick(n: int):
	for i in range(n): g._physics_process(1.0/60.0)
func _initialize():
	g = TestGame.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.started = true
	tick(30)
	assert(g.grounded,"Player should land on start floor")
	g.player=Vector2(310,478)
	tick(1)
	assert(g.acquired,"Gauntlet pickup")
	g.player=Vector2(100,587)
	g.velocity=Vector2.ZERO
	g.keys={"right":true}
	tick(40)
	var before=g.player.x
	g.keys={"rewind":true}
	tick(25)
	assert(g.player.x<before-50,"Rewind must retrace player motion")
	tick(120)
	assert(g.age<0.35 and g.platforms().size()==4,"Rewind restores bridge")
	g.keys={"forward":true}
	tick(200)
	assert(g.age>0.9 and g.platforms().size()==3,"Forward decays bridge")
	g.keys={}
	for stage in range(3):
		g.level=stage
		g.reset_room()
		g.player=g.clue_pos()
		tick(1)
		assert(g.clues[stage],"Clue pickup")
		g.player=Vector2(500,900)
		tick(1)
		assert(g.clues[stage] and g.player.x==100,"Clues survive death")
		g.player=Vector2(1195,587)
		g.velocity=Vector2.ZERO
		tick(2)
		assert(g.level==stage+1 if stage<2 else g.won,"Exit advances level")
	g.won=false
	g.level=1
	g.age=0
	assert(g.platforms().size()==3)
	g.age=1
	assert(g.platforms().size()==6,"Future grows all garden platforms")
	g.level=2
	g.age=0
	assert(g.platforms().size()==4)
	var old_y=g.platforms()[3].position.y
	g.clock+=1
	assert(g.platforms()[3].position.y!=old_y,"Lift is dynamic")
	print("PASS: landing, gauntlet acquisition, player rewind, restored/decayed bridges, garden growth, moving lift, all clue pickups, death persistence, all exits and victory.")
	quit()
