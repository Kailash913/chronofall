extends Node3D
const History=preload("res://scripts/History.gd")
const WorldBuilder=preload("res://scripts/World.gd")
const HUD=preload("res://scripts/Hud.gd")
const SPAWNS=[Vector3(0,1.0,10),Vector3(0,1.0,-71),Vector3(0,1.0,-116)]
var player:CharacterBody3D
var camera:Camera3D
var menu_camera:Camera3D
var world_body:StaticBody3D
var hud
var active=false
var paused=false
var won=false
var stage=0
var unlocked=0
var checkpoint=0
var health=100.0
var energy=100.0
var yaw=0.0
var pitch=0.0
var sensitivity=0.0025
var gyro=false
var graphics=1
var volume=0.65
var bubble=false
var echoes=true
var world_time=0.0
var fire_cooldown=0.0
var power_sound=0.0
var step_clock=0.0
var invulnerable=0.0
var aim_target={}
var locked={}
var puzzles=[]
var enemies=[]
var bolts=[]
var effects=[]
var mats={}
var history=History.new()
var tests={}
var mouse_attack=false
var jump_queued=false
var mobile=false
var last_rewind=false
var notice=""
var notice_timer=0.0
var sound_players=[]
var sounds={}
var ambient:AudioStreamPlayer
var weapon:Node3D
var menu_actor:Node3D
var echo_mesh:MultiMeshInstance3D
var draw_peak=0
var frames_seen=0
var dead_count=0
var falls=0
var quiet_test=false
var fps_clock=0.0
var tutorial_moved=0.0
var portal:Node3D
var visual_bubble:MeshInstance3D
var objectives=[
"INDUCTION  /  Move, look, and cross the cracked approach",
"INDUCTION  /  Lock bridge fragments. Hold REWIND to rebuild the catwalk",
"INDUCTION  /  Lock the vault hinges. Hold FORWARD to corrode the lock",
"INDUCTION  /  Activate BUBBLE. Lock a bolt and REWIND it into the turret",
"WARDEN FOUNDRY  /  Defeat the Stalkers and Remnants. Reach the reactor",
"SINGULARITY  /  Rewind the Golem's armor, then fire at its exposed core",
"THE LAST SECOND  /  Reach the cyan core and FIRE to seal the rift"]
func mat(hex:String,glow:float=0.0):
	var key=hex+str(glow)
	if mats.has(key): return mats[key]
	var m=ShaderMaterial.new()
	m.shader=load("res://scripts/toon.gdshader")
	m.set_shader_parameter("base_color",Color(hex))
	m.set_shader_parameter("glow",glow)
	mats[key]=m
	return m
func part(parent:Node3D,pos:Vector3,size:Vector3,color:String,glow=0.0)->MeshInstance3D:
	var n=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	n.mesh=mesh
	n.material_override=mat(color,glow)
	n.position=pos
	parent.add_child(n)
	return n
func label3(text:String,pos:Vector3,size=40):
	var n=Label3D.new()
	n.text=text
	n.font_size=size
	n.pixel_size=0.012
	n.position=pos
	n.modulate=Color("9bbfc8")
	n.no_depth_test=false
	add_child(n)
func actor(parent:Node3D,boss=false,color="dce4e4")->Node3D:
	var root=Node3D.new()
	parent.add_child(root)
	var scale_factor=1.8 if boss else 1.0
	# One mesh per color through SurfaceTool keeps enemies inexpensive.
	var chunks={"25364c":[],color:[],"00f0ff":[]}
	chunks[color]=[[Vector3(0,0.4,0),Vector3(0.75,0.9,0.45)],[Vector3(-0.55,0.45,0),Vector3(0.35,0.65,0.45)],[Vector3(0.55,0.45,0),Vector3(0.35,0.65,0.45)],[Vector3(0,1.12,0),Vector3(0.45,0.42,0.45)]]
	chunks["25364c"]=[[Vector3(-0.22,-0.45,0),Vector3(0.3,0.8,0.35)],[Vector3(0.22,-0.45,0),Vector3(0.3,0.8,0.35)]]
	chunks["00f0ff"]=[[Vector3(0,1.16,-0.24),Vector3(0.4,0.1,0.04)],[Vector3(0,0.4,-0.24),Vector3(0.22,0.35,0.04)]]
	for c in chunks:
		var multi=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=load("res://assets/meshes/beveled_pillar.obj")
		multi.instance_count=chunks[c].size()
		for i in range(multi.instance_count):
			var piece=chunks[c][i]
			multi.set_instance_transform(i,Transform3D(Basis.from_scale(piece[1]*scale_factor*0.5),piece[0]*scale_factor))
		var n=MultiMeshInstance3D.new()
		n.multimesh=multi
		n.material_override=mat(c,0.7 if c=="00f0ff" else 0.0)
		root.add_child(n)
	return root
func _ready():
	quiet_test=DisplayServer.get_name()=="headless" or "--qa-silent" in OS.get_cmdline_user_args()
	mobile=OS.has_feature("android") or OS.has_feature("ios")
	load_settings()
	Engine.max_fps=60
	var env=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("081422")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("79b8cc")
	e.ambient_light_energy=0.5
	env.environment=e
	add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-50,-25,0)
	sun.light_color=Color("ffe0b6")
	sun.light_energy=1.05
	sun.shadow_enabled=false
	add_child(sun)
	world_body=StaticBody3D.new()
	add_child(world_body)
	WorldBuilder.new(self).build()
	make_puzzles()
	make_player()
	make_audio()
	make_menu_scene()
	make_echoes()
	var canvas=CanvasLayer.new()
	add_child(canvas)
	hud=HUD.new()
	hud.g=self
	canvas.add_child(hud)
	apply_graphics()
	label3("CHRONO-SPIRE  /  INDUCTION",Vector3(0,5,-10))
	label3("02  /  WARDEN FOUNDRY",Vector3(0,5,-70))
	label3("03  /  SINGULARITY CHAMBER",Vector3(0,6,-116))
	label3("SEAL THE FRACTURE",Vector3(0,8,-152))
	menu_camera.make_current()
func make_player():
	player=CharacterBody3D.new()
	player.name="AgentVance"
	add_child(player)
	var col=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.radius=0.35
	capsule.height=1.8
	col.shape=capsule
	player.add_child(col)
	player.position=SPAWNS[0]
	camera=Camera3D.new()
	camera.fov=78
	camera.near=0.08
	camera.far=190
	camera.position.y=0.65
	player.add_child(camera)
	weapon=Node3D.new()
	camera.add_child(weapon)
	part(weapon,Vector3(0.25,-0.22,-0.55),Vector3(0.12,0.14,0.42),"25364c")
	part(weapon,Vector3(0.25,-0.17,-0.58),Vector3(0.07,0.04,0.45),"00f0ff",0.8)
	part(weapon,Vector3(0.25,-0.31,-0.39),Vector3(0.11,0.17,0.12),"dce4e4")
func make_menu_scene():
	menu_actor=Node3D.new()
	menu_actor.position=Vector3(42,2,8)
	add_child(menu_actor)
	actor(menu_actor,false,"dce4e4")
	part(menu_actor,Vector3(0,-1.1,0),Vector3(4,0.3,4),"385767")
	part(menu_actor,Vector3(0,-1.28,0),Vector3(4.1,0.06,4.1),"00f0ff",1.0)
	part(menu_actor,Vector3(0.64,0.25,-0.4),Vector3(0.15,0.18,0.8),"ffb300",0.25)
	menu_camera=Camera3D.new()
	add_child(menu_camera)
	menu_camera.position=Vector3(46,3.5,14)
	menu_camera.look_at(Vector3(40.5,2.1,8))
	for i in range(16):
		var n=part(menu_actor,Vector3(sin(i)*3.7,2+cos(i*3)*2,cos(i)*3.7),Vector3(0.08,0.35,0.08),"00f0ff",0.8)
		n.set_meta("particle",true)
func make_audio():
	for key in ["ambient","reverse","forward","step","shot","impact","switch","bubble"]: sounds[key]=load("res://assets/audio/"+key+".wav")
	for i in range(8):
		var ap=AudioStreamPlayer.new()
		add_child(ap)
		sound_players.append(ap)
	ambient=AudioStreamPlayer.new()
	ambient.stream=sounds.ambient
	ambient.volume_db=-20
	add_child(ambient)
	ambient.finished.connect(func():
		if not quiet_test: ambient.play())
	if not quiet_test: ambient.play()
	set_volume(volume)
func sound(key:String,quiet=false):
	if quiet_test: return
	for ap in sound_players:
		if not ap.playing:
			ap.stream=sounds[key]
			ap.volume_db=-18 if quiet else -6
			ap.play()
			return
func set_volume(v):
	volume=v
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,0.001)))
func apply_graphics():
	get_viewport().scaling_3d_scale=[0.65,0.8,1.0][graphics]
func load_settings():
	var cfg=ConfigFile.new()
	if cfg.load("user://progress.cfg")==OK:
		unlocked=clampi(cfg.get_value("save","unlocked",0),0,2)
		volume=cfg.get_value("settings","volume",0.65)
		graphics=clampi(cfg.get_value("settings","graphics",1),0,2)
		gyro=cfg.get_value("settings","gyro",false)
func save_settings():
	var cfg=ConfigFile.new()
	cfg.set_value("save","unlocked",unlocked)
	cfg.set_value("settings","volume",volume)
	cfg.set_value("settings","graphics",graphics)
	cfg.set_value("settings","gyro",gyro)
	cfg.save("user://progress.cfg")
func make_puzzles():
	var bridge=Node3D.new()
	bridge.position=Vector3(0,-0.275,-17)
	add_child(bridge)
	var pieces=[]
	for i in range(6): pieces.append(part(bridge,Vector3(0,0,(i-2.5)*1.7),Vector3(5,0.35,1.65),"567b87"))
	var body=StaticBody3D.new()
	bridge.add_child(body)
	var col=CollisionShape3D.new()
	var shape=BoxShape3D.new()
	shape.size=Vector3(5,0.35,10.5)
	col.shape=shape
	body.add_child(col)
	puzzles.append({"kind":"bridge","node":bridge,"age":1.0,"shape":col,"parts":pieces,"history":History.new(),"name":"FRACTURED CATWALK"})
	var door=Node3D.new()
	door.position=Vector3(0,2.6,-38)
	add_child(door)
	var slab=part(door,Vector3.ZERO,Vector3(24,5.5,0.65),"385767")
	var hinge=part(door,Vector3(0,0,0.4),Vector3(0.7,3.7,0.25),"ffb300",0.6)
	var db=StaticBody3D.new()
	door.add_child(db)
	var dc=CollisionShape3D.new()
	var ds=BoxShape3D.new()
	ds.size=Vector3(24,5.5,0.65)
	dc.shape=ds
	db.add_child(dc)
	puzzles.append({"kind":"door","node":door,"age":0.0,"shape":dc,"parts":[slab,hinge],"history":History.new(),"name":"TITANIUM HINGES"})
	portal=Node3D.new()
	portal.position=Vector3(0,3,-150)
	add_child(portal)
	var core=part(portal,Vector3.ZERO,Vector3(1.7,3,1.7),"00f0ff",1.3)
	core.rotation_degrees=Vector3(0,0,30)
func update_puzzle(p,dt):
	var age=p.age
	if p.kind=="bridge":
		for i in range(p.parts.size()):
			var n=p.parts[i]
			n.position=Vector3(sin(i*2.7)*3*age,age*(1.5+cos(i*1.9)),(i-2.5)*1.7)
			n.rotation=Vector3(age*sin(i)*1.3,age*cos(i)*0.7,age*0.9)
		p.shape.disabled=age>0.12
	else:
		p.parts[0].position.y=-age*6.5
		p.parts[1].scale=Vector3(maxf(0.03,1-age),1,1)
		p.shape.disabled=age>0.88
	var tracked=p.parts[0].global_transform if p.kind=="bridge" else p.parts[0].global_transform
	p.history.record(tracked,Vector3.ZERO,Vector3.ZERO,1 if age>0.5 else 0,int(world_time*60)%60,1-age)
func make_echoes():
	echo_mesh=MultiMeshInstance3D.new()
	var multi=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	var mesh=CapsuleMesh.new()
	mesh.radius=0.3
	mesh.height=1.6
	mesh.radial_segments=8
	mesh.rings=2
	multi.mesh=mesh
	multi.instance_count=48
	multi.visible_instance_count=0
	echo_mesh.multimesh=multi
	var m=StandardMaterial3D.new()
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color=Color(0,0.94,1,0.16)
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	echo_mesh.material_override=m
	add_child(echo_mesh)
func start_mission(sector=0):
	clear_combat()
	checkpoint=clampi(sector,0,unlocked)
	stage=[0,4,5][checkpoint]
	player.position=SPAWNS[checkpoint]
	player.velocity=Vector3.ZERO
	yaw=0
	pitch=0
	health=100
	energy=100
	active=true
	paused=false
	won=false
	tutorial_moved=0
	history.clear()
	locked={}
	puzzles[0].age=1.0 if checkpoint==0 else 0.0
	puzzles[1].age=0.0 if checkpoint==0 else 1.0
	camera.make_current()
	if not mobile: Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	hud.hide_menu()
	if stage==4: spawn_foundry()
	elif stage==5: spawn_boss()
	tell("VANCE / Containment failed. Reach the Singularity Core. Seal the fracture.",7)
func clear_combat():
	for e in enemies: e.node.queue_free()
	for b in bolts: b.node.queue_free()
	for fx in effects: fx.node.queue_free()
	enemies.clear()
	bolts.clear()
	effects.clear()
func tell(text:String,seconds=4.0):
	notice=text
	notice_timer=seconds
func pause_game():
	if not active: return
	paused=not paused
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused or mobile else Input.MOUSE_MODE_CAPTURED
	if paused: hud.show_menu("pause")
	else: hud.hide_menu()
func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and active and not paused: pause_game()
func down(action:String,key:int)->bool:
	if tests.has(action): return tests[action]
	return hud.buttons_down.get(action,false) or Input.is_physical_key_pressed(key)
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE: pause_game()
		if event.keycode==KEY_SPACE: jump_queued=true
		if event.keycode==KEY_R and not active: start_mission(checkpoint)
		if event.keycode==KEY_T: echoes=not echoes
	if not active or paused: return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		yaw-=event.relative.x*sensitivity
		pitch=clampf(pitch-event.relative.y*sensitivity,-1.15,1.15)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed: toggle_lock()
		if event.button_index==MOUSE_BUTTON_LEFT: mouse_attack=event.pressed
func toggle_lock():
	if not aim_target.is_empty():
		locked=aim_target
		sound("switch",true)
	else: locked={}
func target_position(t):
	if t.kind=="bridge": return t.node.global_position+Vector3(0,1,0)
	return t.node.global_position
func valid_target(t)->bool:
	return not t.is_empty() and is_instance_valid(t.node) and not t.node.is_queued_for_deletion()
func choose_target():
	var all=[]
	all.append_array(puzzles)
	all.append_array(enemies)
	all.append_array(bolts)
	var best={}
	var score=0.87
	for t in all:
		if not valid_target(t): continue
		var delta=target_position(t)-camera.global_position
		if delta.length()>42: continue
		var d=delta.normalized().dot(-camera.global_basis.z)
		if d>score:
			score=d
			best=t
	aim_target=best
	if valid_target(locked):
		if target_position(locked).distance_to(player.position)>48: locked={}
	else: locked={}
func current_target():
	return locked if valid_target(locked) else aim_target
func spawn_enemy(kind:String,pos:Vector3):
	var body=CharacterBody3D.new()
	body.position=pos
	add_child(body)
	var col=CollisionShape3D.new()
	var cs=CapsuleShape3D.new()
	cs.radius=0.5 if kind!="golem" else 1.1
	cs.height=2.0 if kind!="golem" else 3.6
	col.shape=cs
	body.add_child(col)
	var model=actor(body,kind=="golem","c59a60" if kind=="golem" else ("d96460" if kind=="stalker" else "758fc2"))
	var e={"node":body,"kind":kind,"name":{"turret":"PULSE SENTINEL","stalker":"CHRONO-STALKER","remnant":"TEMPORAL REMNANT","golem":"PHASE GOLEM"}[kind],"hp":180.0 if kind=="golem" else (55.0 if kind=="stalker" else 45.0),"cooldown":1.7,"exposed":0.0,"armor":0.0,"ambush":0.0,"history":History.new(),"model":model,"velocity":Vector3.ZERO}
	var shield:MeshInstance3D=null
	if kind=="golem" or kind=="turret":
		shield=MeshInstance3D.new()
		var sphere=SphereMesh.new()
		sphere.radius=2.1 if kind=="golem" else 1.25
		sphere.height=sphere.radius*2
		sphere.radial_segments=12
		sphere.rings=6
		shield.mesh=sphere
		var sm=StandardMaterial3D.new()
		sm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.albedo_color=Color(1,0.7,0.05,0.14)
		sm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		shield.material_override=sm
		body.add_child(shield)
	e["shield"]=shield
	enemies.append(e)
	return e
func spawn_foundry():
	spawn_enemy("stalker",Vector3(-6,1,-87))
	spawn_enemy("stalker",Vector3(7,1,-96))
	spawn_enemy("remnant",Vector3(0,2,-101))
	tell("ARCHIVE 02 / The Stalkers remember your past. Rewind away from their ambush.",6)
func spawn_boss():
	spawn_enemy("golem",Vector3(0,2,-137))
	spawn_enemy("remnant",Vector3(-9,2,-143))
	tell("VANCE / The Golem's armor hardened after the breach. Rewind it into its cooling phase.",7)
func spawn_bolt(sender):
	var node=MeshInstance3D.new()
	var mesh=SphereMesh.new()
	mesh.radius=0.22
	mesh.height=0.44
	mesh.radial_segments=8
	mesh.rings=4
	node.mesh=mesh
	node.material_override=mat("ffb300",1.3)
	node.position=sender.node.position+Vector3(0,0.5,0)
	add_child(node)
	var vel=(player.position+Vector3(0,0.3,0)-node.position).normalized()*10
	bolts.append({"node":node,"kind":"bolt","name":"KINETIC BOLT / REWIND TO RETURN","velocity":vel,"sender":sender,"returning":false,"life":12.0,"history":History.new()})
func hurt(amount):
	if invulnerable>0: return
	health=maxf(0,health-amount)
	hud.flash=0.35
	sound("impact",true)
func kill_enemy(e):
	if not enemies.has(e): return
	if locked==e: locked={}
	enemies.erase(e)
	e.node.queue_free()
	sound("impact")
	energy=minf(100,energy+12)
func shoot():
	if stage==6 and player.position.distance_to(portal.position)<7:
		win_game()
		return
	if fire_cooldown>0: return
	fire_cooldown=0.22
	sound("shot")
	weapon.position.z=0.07
	var origin=camera.global_position
	var direction=-camera.global_basis.z
	var best={}
	var distance=65.0
	for e in enemies:
		var delta=e.node.position+Vector3(0,0.4,0)-origin
		var along=delta.dot(direction)
		if along<0 or along>distance: continue
		var radius=1.6 if e.kind=="golem" else 0.9
		if (delta-direction*along).length()<radius:
			var query=PhysicsRayQueryParameters3D.create(origin,e.node.position)
			query.exclude=[player.get_rid(),e.node.get_rid()]
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				best=e
				distance=along
	var tracer=part(self,origin+direction*distance*0.5,Vector3(0.025,0.025,distance),"00f0ff",1.0)
	tracer.look_at(origin+direction*distance)
	effects.append({"node":tracer,"life":0.06})
	if not best.is_empty():
		if best.kind=="turret":
			tell("Sentinel shield active. Return its own bolt with REWIND.",2)
		elif best.kind=="golem" and best.exposed<=0:
			tell("Armor is hardened. Lock the Golem and hold REWIND.",2)
		else:
			best.hp-=18
			hud.hit_flash=0.15
			if best.hp<=0: kill_enemy(best)
func time_power(reverse:bool,forward:bool,dt:float):
	var t=current_target()
	if not valid_target(t) or energy<=1 or not (reverse or forward): return
	energy=maxf(0,energy-dt*10)
	if power_sound<=0:
		sound("reverse" if reverse else "forward",true)
		power_sound=0.55
	if t.kind=="bridge":
		t.age=clampf(t.age+(-1 if reverse else 1)*dt*0.5,0,1)
	elif t.kind=="door":
		t.age=clampf(t.age+(-1 if reverse else 1)*dt*0.5,0,1)
	elif t.kind=="golem" and reverse:
		t.armor+=dt
		if t.armor>=1.0:
			t.exposed=5.0
			t.armor=0
			tell("COOLING PHASE / Core exposed for 5 seconds. Fire!",2)
	elif t.kind=="bolt" and reverse:
		t.returning=true
		t.node.material_override=mat("00f0ff",1)
		sound("switch",true)
	elif reverse and t.history.count>0:
		var old=t.history.pop()
		t.node.transform=old.transform
		t.velocity=old.linear
func update_enemies(dt,reverse):
	for e in enemies.duplicate():
		if not is_instance_valid(e.node): continue
		var scaled=dt*(0.1 if bubble and e.node.position.distance_to(player.position)<18 else 1.0)
		e.exposed=maxf(0,e.exposed-dt)
		if is_instance_valid(e.shield): e.shield.visible=e.exposed<=0
		e.ambush=maxf(0,e.ambush-dt)
		e.cooldown-=scaled
		var delta=player.position-e.node.position
		delta.y=0
		if delta.length()>0.1: e.node.look_at(e.node.position+delta,Vector3.UP)
		if e.kind=="stalker":
			if reverse and not last_rewind and e.ambush<=0:
				var old=history.past(120)
				if not old.is_empty():
					var arrival=old.transform.origin+Vector3(2,0,1)
					arrival.y=1
					e.node.position=arrival
					e.ambush=5.0
					tell("STALKER / Temporal disturbance detected. Ambush at your past position!",2)
			e.node.velocity=delta.normalized()*4.2*(scaled/dt)
			e.node.velocity.y=-5
			e.node.move_and_slide()
			if delta.length()<1.7 and e.cooldown<=0:
				hurt(12)
				e.cooldown=0.9
		elif e.kind=="golem":
			e.node.velocity=delta.normalized()*1.3*(scaled/dt)
			e.node.velocity.y=-5
			e.node.move_and_slide()
			e.model.scale=Vector3.ONE*(0.93 if e.exposed>0 else 1.0)
			if e.cooldown<=0:
				spawn_bolt(e)
				e.cooldown=2.1
			if delta.length()<2.6 and e.cooldown<1:
				hurt(15)
				e.cooldown=2.3
		else:
			if e.kind=="remnant":
				e.node.position.x+=sin(world_time+e.node.position.z)*scaled*1.2
				e.model.position.y=sin(world_time*2)*0.3
			if e.cooldown<=0:
				spawn_bolt(e)
				e.cooldown=2.8 if e.kind=="turret" else 2.2
		e.velocity=e.node.velocity
		if not (reverse and current_target()==e): e.history.record(e.node.transform,e.velocity,Vector3.ZERO,1 if e.exposed>0 else 0,int(world_time*12)%8,e.hp)
func update_bolts(dt):
	for b in bolts.duplicate():
		var scaled=dt*(0.1 if bubble and b.node.position.distance_to(player.position)<18 and not b.returning else 1.0)
		b.life-=dt
		if b.returning:
			if valid_target(b.sender):
				b.velocity=(b.sender.node.position-b.node.position).normalized()*22
				if b.node.position.distance_to(b.sender.node.position)<1.5:
					b.sender.hp-=80
					if b.sender.hp<=0: kill_enemy(b.sender)
					b.life=0
			else: b.life=0
		elif b.sender.kind=="remnant":
			var desired=(player.position-b.node.position).normalized()*10
			b.velocity=b.velocity.lerp(desired,scaled*0.8)
		var old=b.node.position
		b.node.position+=b.velocity*scaled
		if not b.returning and b.node.position.distance_to(player.position)<0.85:
			hurt(15)
			b.life=0
		var query=PhysicsRayQueryParameters3D.create(old,b.node.position)
		query.exclude=[player.get_rid()]
		if valid_target(b.sender): query.exclude.append(b.sender.node.get_rid())
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): b.life=0
		b.history.record(b.node.transform,b.velocity,Vector3.ZERO,1 if b.returning else 0,0,b.life)
		if b.life<=0:
			if locked==b: locked={}
			bolts.erase(b)
			b.node.queue_free()
func update_echoes():
	var index=0
	if echoes:
		var tracked=enemies+bolts+puzzles
		for t in tracked:
			for age in [60,120,180,240]:
				if t.history.count>age and index<48:
					var frame=t.history.past(age)
					var tf=frame.transform
					if t.kind=="bolt": tf.basis=tf.basis.scaled(Vector3.ONE*0.2)
					elif t.kind=="bridge" or t.kind=="door": tf.basis=tf.basis.scaled(Vector3(1.8,0.2,1.0))
					echo_mesh.multimesh.set_instance_transform(index,tf)
					index+=1
	echo_mesh.multimesh.visible_instance_count=index
func advance_progress():
	if stage==0 and tutorial_moved>3:
		stage=1
		tell("OPS / The catwalk collapsed. Lock the floating fragments, then hold REWIND.",6)
	if stage==1 and puzzles[0].age<0.12 and player.position.z<-23:
		stage=2
		sound("switch")
		tell("OPS / Titanium is strong today, brittle tomorrow. Fast-forward the hinges.",6)
	if stage==2 and puzzles[1].age>0.88 and player.position.z<-41:
		stage=3
		spawn_enemy("turret",Vector3(0,1.2,-59))
		tell("OPS / Slow the bolt with F or BUBBLE. Lock it. REWIND sends it home.",7)
	if stage==3 and enemies.is_empty() and player.position.z<-63:
		set_checkpoint(1)
		stage=4
		spawn_foundry()
	if stage==4 and enemies.is_empty() and player.position.z<-112:
		set_checkpoint(2)
		stage=5
		spawn_boss()
	if stage==5 and enemies.is_empty():
		stage=6
		tell("VANCE / The guardians are down. Get to the core and seal it.",6)
func set_checkpoint(n):
	checkpoint=n
	unlocked=maxi(unlocked,n)
	health=100
	energy=100
	history.clear()
	save_settings()
	sound("switch")
func win_game():
	active=false
	won=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	hud.show_menu("victory")
	sound("switch")
func _physics_process(dt):
	world_time+=dt
	if not active:
		menu_actor.rotation.y=sin(world_time*0.25)*0.2
		for c in menu_actor.get_children():
			if c.has_meta("particle"): c.position.y=fposmod(c.position.y-dt*0.5,5)
		hud.queue_redraw()
		return
	if paused: return
	invulnerable=maxf(0,invulnerable-dt)
	notice_timer=maxf(0,notice_timer-dt)
	fire_cooldown=maxf(0,fire_cooldown-dt)
	power_sound=maxf(0,power_sound-dt)
	var reverse=down("reverse",KEY_Q)
	var forward=down("forward",KEY_E)
	var was_bubble=bubble
	bubble=down("bubble",KEY_F) and energy>1
	if bubble and not was_bubble: sound("bubble",true)
	if bubble: energy=maxf(0,energy-dt*17)
	elif not reverse and not forward: energy=minf(100,energy+dt*12)
	var move=Vector2(float(down("right",KEY_D))-float(down("left",KEY_A)),float(down("back",KEY_S))-float(down("go",KEY_W)))+hud.move_stick
	move=move.limit_length()
	yaw-=hud.look_stick.x*dt*2.2
	pitch=clampf(pitch-hud.look_stick.y*dt*1.6,-1.15,1.15)
	if mobile and gyro:
		var rate=Input.get_gyroscope()
		yaw-=rate.y*dt*0.45
		pitch=clampf(pitch-rate.x*dt*0.45,-1.15,1.15)
	player.rotation.y=yaw
	camera.rotation.x=pitch
	var prev=player.position
	var dir=player.basis*Vector3(move.x,0,move.y)
	var speed=9.0 if down("sprint",KEY_SHIFT) else 6.0
	player.velocity.x=dir.x*speed
	player.velocity.z=dir.z*speed
	player.velocity.y-=22*dt
	if (jump_queued or down("jump",KEY_SPACE)) and player.is_on_floor(): player.velocity.y=7.0
	jump_queued=false
	choose_target()
	if reverse and not valid_target(current_target()) and history.count>0 and energy>1:
		var old=history.pop()
		player.transform=old.transform
		player.velocity=old.linear
		health=maxf(health,old.health)
		energy=maxf(0,energy-dt*15)
	else:
		player.move_and_slide()
		history.record(player.transform,player.velocity,Vector3.ZERO,0,int(world_time*12)%8,health)
	tutorial_moved+=player.position.distance_to(prev)
	if move.length()>0.2 and player.is_on_floor():
		step_clock-=dt
		if step_clock<=0:
			sound("step",true)
			step_clock=0.35
	# Keep progression gates explicit; no skipping tutorial encounters.
	if stage<3: player.position.z=maxf(player.position.z,-44)
	elif stage==3 and not enemies.is_empty(): player.position.z=maxf(player.position.z,-64)
	elif stage==4 and not enemies.is_empty(): player.position.z=maxf(player.position.z,-110)
	if player.position.y<-8:
		falls+=1
		hurt(25)
		player.position=SPAWNS[checkpoint] if stage!=2 else Vector3(0,1,-25)
		player.velocity=Vector3.ZERO
		history.clear()
		invulnerable=1
		tell("Temporal anchor restored your position. Rebuild the catwalk before crossing.",4)
	time_power(reverse,forward,dt)
	for p in puzzles: update_puzzle(p,dt)
	update_enemies(dt,reverse)
	update_bolts(dt)
	if mouse_attack or down("fire",KEY_NONE): shoot()
	weapon.position.z=move_toward(weapon.position.z,0,dt*0.8)
	for fx in effects.duplicate():
		fx.life-=dt
		if fx.life<=0:
			fx.node.queue_free()
			effects.erase(fx)
	update_echoes()
	advance_progress()
	portal.rotation.y+=dt*0.5
	last_rewind=reverse
	if health<=0:
		active=false
		dead_count+=1
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		hud.show_menu("death")
	hud.flash=maxf(0,hud.flash-dt)
	hud.hit_flash=maxf(0,hud.hit_flash-dt)
	frames_seen+=1
	draw_peak=maxi(draw_peak,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	fps_clock+=dt
	if mobile and fps_clock>3:
		fps_clock=0
		var fps=Engine.get_frames_per_second()
		if fps<48: get_viewport().scaling_3d_scale=maxf(0.55,get_viewport().scaling_3d_scale-0.05)
		elif fps>58: get_viewport().scaling_3d_scale=minf([0.65,0.8,1.0][graphics],get_viewport().scaling_3d_scale+0.025)
	hud.queue_redraw()

func _exit_tree():
	if is_instance_valid(ambient):
		ambient.stop()
		ambient.stream=null
	for ap in sound_players:
		if is_instance_valid(ap):
			ap.stop()
			ap.stream=null
	sounds.clear()
