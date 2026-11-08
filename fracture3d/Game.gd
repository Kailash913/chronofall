extends Node3D
var player: CharacterBody3D
var cam: Camera3D
var enemies=[]
var history=[]
var stage=0
var active=false
var hp=100.0
var charge=100.0
var yaw=0.0
var cooldown=0.0
var ui: Label
var panel: Control
var controls={}
var audio: AudioStreamPlayer
var tutorial=0
var tutorial_time=0.0
var mission=["BREACH / Recover the stolen temporal core", "PURSUIT / Silence the time wardens", "RESTORE / Defend the final timeline"]
func material(c):
	var m=StandardMaterial3D.new()
	m.albedo_color=Color(c)
	m.roughness=0.9
	return m
func block(pos,size,color,solid=true):
	var n=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	n.mesh=mesh
	n.material_override=material(color)
	n.position=pos
	add_child(n)
	if solid:
		var body=StaticBody3D.new()
		var shape=CollisionShape3D.new()
		var box=BoxShape3D.new()
		box.size=size
		shape.shape=box
		n.add_child(body)
		body.add_child(shape)
	return n
func tone(freq):
	var wav=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=22050
	var data=PackedByteArray()
	data.resize(4410)
	for i in range(2205): data.encode_s16(i*2,int(sin(i*TAU*freq/22050)*8000*(1.0-i/2205.0)))
	wav.data=data
	audio.stream=wav
	audio.play()
func detail(parent,pos,size,color):
	var part=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	part.mesh=mesh
	part.material_override=material(color)
	parent.add_child(part)
	part.position=pos
	return part
func _ready():
	var env=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("17283c")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("b1d5e0")
	e.ambient_light_energy=0.8
	env.environment=e
	add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-30,0)
	sun.light_energy=1.2
	add_child(sun)
	block(Vector3(0,-1,0),Vector3(44,2,44),"34475a")
	for x in [-23,23]: block(Vector3(x,3,0),Vector3(2,8,46),"233144")
	for z in [-23,23]: block(Vector3(0,3,z),Vector3(46,8,2),"233144")
	for i in range(12):
		var a=i*TAU/12
		block(Vector3(cos(a)*17,2,sin(a)*17),Vector3(3,4,3),"65818b")
		block(Vector3(cos(a)*17,4.2,sin(a)*17),Vector3(3.2,0.3,3.2),"ff685e",false)
	for i in range(20):
		block(Vector3(-20+i*2,0.02,0),Vector3(0.04,0.03,42),"486372",false)
		block(Vector3(0,0.02,-20+i*2),Vector3(42,0.03,0.04),"486372",false)
	for x in [-20,20]:
		for z in [-15,-5,5,15]:
			block(Vector3(x,4,z),Vector3(0.3,8,0.3),"62e7cf",false)
	for z in [-21,21]:
		block(Vector3(0,6,z),Vector3(42,1,1),"456576")
		block(Vector3(0,6.6,z),Vector3(42,0.15,1.1),"ff685e",false)
	var core=block(Vector3(0,4,-19),Vector3(2,2,2),"62e7cf",false)
	core.rotation_degrees=Vector3(35,0,45)
	for x in [-7,7]:
		block(Vector3(x,1,0),Vector3(3,2,7),"507682")
		block(Vector3(x,2.2,0),Vector3(3,0.2,7),"62e7cf",false)
	player=CharacterBody3D.new()
	add_child(player)
	var col=CollisionShape3D.new()
	col.shape=CapsuleShape3D.new()
	player.add_child(col)
	player.position=Vector3(0,1,12)
	cam=Camera3D.new()
	player.add_child(cam)
	cam.position.y=0.65
	cam.fov=80
	var gun=MeshInstance3D.new()
	var gm=BoxMesh.new()
	gm.size=Vector3(0.10,0.12,0.34)
	gun.mesh=gm
	gun.material_override=material("ff685e")
	gun.position=Vector3(0.23,-0.18,-0.55)
	cam.add_child(gun)
	audio=AudioStreamPlayer.new()
	add_child(audio)
	var canvas=CanvasLayer.new()
	add_child(canvas)
	ui=Label.new()
	ui.position=Vector2(26,20)
	ui.add_theme_font_size_override("font_size",23)
	canvas.add_child(ui)
	var cross=Label.new()
	cross.text="+"
	cross.position=Vector2(631,345)
	cross.add_theme_font_size_override("font_size",28)
	canvas.add_child(cross)
	var names=["LEFT","RIGHT","GO","BACK","TURN <","TURN >","FIRE","REWIND","SLOW"]
	for i in range(names.size()):
		var b=Button.new()
		b.text=names[i]
		var positions=[Vector2(20,535),Vector2(210,535),Vector2(115,440),Vector2(115,625),Vector2(850,535),Vector2(1040,535),Vector2(1135,625),Vector2(850,625),Vector2(995,625)]
		b.position=positions[i]
		b.size=Vector2(90 if i<6 else 130,80)
		canvas.add_child(b)
		var key=names[i]
		b.button_down.connect(func(): controls[key]=true)
		b.button_up.connect(func(): controls[key]=false)
	panel=Panel.new()
	panel.position=Vector2(230,150)
	panel.size=Vector2(820,420)
	canvas.add_child(panel)
	var title=Label.new()
	title.text="CHRONOFALL / FRACTURE\n\nYou are the last Keeper. The Wardens stole tomorrow.\nRecover three cores and restart the timeline.\n\nWASD moves • arrows turn • click/Space fires\nQ rewinds your position and health • E slows enemies\nOn mobile use the bottom controls. Aim near an enemy.\nClear each sector to recover its core and progress."
	title.position=Vector2(30,25)
	title.add_theme_font_size_override("font_size",23)
	panel.add_child(title)
	var start=Button.new()
	start.text="BEGIN / RESTART MISSION"
	start.position=Vector2(220,345)
	start.size=Vector2(380,55)
	panel.add_child(start)
	start.pressed.connect(begin)
func begin():
	stage=0
	tutorial=0
	tutorial_time=0
	hp=100
	charge=100
	history.clear()
	panel.hide()
	active=true
	spawn_wave()
func spawn_wave():
	for en in enemies: en.queue_free()
	enemies.clear()
	player.position=Vector3(0,1,12)
	for i in range(3+stage*2):
		var en=block(Vector3(-12+i*4,1.4,-12),Vector3(1.2,2.8,1.2),"ee635f",false)
		en.mesh=null
		detail(en,Vector3(0,0,0),Vector3(0.8,1.2,0.5),"374b67")
		detail(en,Vector3(0,0.95,0),Vector3(0.55,0.55,0.55),"d5dde4")
		detail(en,Vector3(0,1,-0.3),Vector3(0.5,0.13,0.08),"ff685e")
		for side in [-1,1]:
			detail(en,Vector3(side*0.25,-0.95,0),Vector3(0.27,0.8,0.3),"27354d")
			var arm=detail(en,Vector3(side*0.65,0.1,0),Vector3(0.3,1,0.35),"ee635f")
			arm.rotation.z=side*0.2
		enemies.append(en)
func held(name,key): return controls.get(name,false) or Input.is_physical_key_pressed(key)
func _physics_process(dt):
	if not active: return
	tutorial_time+=dt
	if tutorial==0 and (held("GO",KEY_W) or held("RIGHT",KEY_D)): tutorial=1
	if tutorial==1 and held("FIRE",KEY_SPACE): tutorial=2
	if tutorial==2 and held("REWIND",KEY_Q): tutorial=3
	if tutorial==3 and held("SLOW",KEY_E): tutorial=4
	cooldown=maxf(0,cooldown-dt)
	yaw+=(float(held("TURN <",KEY_LEFT))-float(held("TURN >",KEY_RIGHT)))*dt*1.8
	player.rotation.y=yaw
	var rewind=held("REWIND",KEY_Q) and charge>0
	var slow=held("SLOW",KEY_E) and charge>0
	if rewind and history.size()>0:
		var s=history.pop_back()
		player.position=s[0]
		hp=s[1]
		charge-=dt*20
	else:
		history.append([player.position,hp])
		if history.size()>360: history.pop_front()
		var dir=Vector3(float(held("RIGHT",KEY_D))-float(held("LEFT",KEY_A)),0,float(held("BACK",KEY_S))-float(held("GO",KEY_W)))
		dir=player.basis*dir.normalized()
		player.velocity=dir*7
		player.velocity.y=-5
		player.move_and_slide()
		charge=clampf(charge+dt*(-12 if slow else 8),0,100)
	for en in enemies:
		var d=player.position-en.position
		d.y=0
		en.look_at(Vector3(player.position.x,en.position.y,player.position.z),Vector3.UP)
		if tutorial==4 or tutorial_time>45:
			en.position+=d.normalized()*dt*(0.5 if slow or rewind else 1.7+stage*0.35)
		if d.length()<1.8 and not rewind: hp-=dt*18
	if (held("FIRE",KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and cooldown<=0:
		cooldown=0.28
		tone(180)
		var best=null
		var score=0.88
		for en in enemies:
			var d=(en.position-cam.global_position).normalized()
			var dot=d.dot(-cam.global_basis.z)
			if dot>score:
				var q=PhysicsRayQueryParameters3D.create(cam.global_position,en.position)
				q.exclude=[player.get_rid()]
				if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
					score=dot
					best=en
		if best!=null:
			enemies.erase(best)
			best.queue_free()
			tone(650)
	ui.text="CHRONOFALL  /  "+mission[stage]+"\nHEALTH %d     TIME %d     WARDENS %d\n%s" %[hp,charge,enemies.size(),"REWINDING" if rewind else ("TIME DILATED" if slow else "Recover the core: defeat the Wardens")]
	if tutorial<4:
		ui.text+="\nTRAINING / "+["Move with GO or W. Wardens are suspended during training.","Aim with TURN. Press FIRE or Space to shoot.","Hold REWIND or Q to retrace your movement.","Hold SLOW or E to delay the Wardens."][tutorial]
	if hp<=0:
		active=false
		panel.show()
		ui.text="TIMELINE LOST / Restart the mission"
	if enemies.is_empty():
		stage+=1
		hp=100
		charge=100
		history.clear()
		if stage==3:
			active=false
			panel.show()
			ui.text="TIMELINE RESTORED / All three cores recovered. Tomorrow belongs to everyone."
		else: spawn_wave()
