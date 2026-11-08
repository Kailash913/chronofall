extends Node2D

const W = 1280.0
const H = 720.0
const TITLES = ["01  /  THE BROKEN VIADUCT", "02  /  THE GLASS GARDEN", "03  /  THE LAST SECOND"]
const CLUES = ["MEMORY 01: The bridge remembers its shape. Pull time backward.", "MEMORY 02: Life needs a future. Let the sleeping garden grow.", "MEMORY 03: The tower needs both past and future. Nothing is lost."]
var player = Vector2(100, 570)
var velocity = Vector2.ZERO
var grounded = false
var age = 0.75
var clock = 0.0
var level = 0
var acquired = false
var clues = [false, false, false]
var history: Array = []
var mode = 0
var started = false
var won = false
var paused = false
var deaths = 0
var message = ""
var message_time = 0.0
var jump_was = false
var touches = {}
var font = ThemeDB.fallback_font
var trail: Array = []
var buttons = {"left":Rect2(28,614,80,78), "right":Rect2(120,614,80,78), "rewind":Rect2(844,614,120,78), "forward":Rect2(976,614,120,78), "jump":Rect2(1110,614,142,78)}

func say(s: String):
	message = s
	message_time = 5.0

func reset_room():
	player = Vector2(100, 560)
	velocity = Vector2.ZERO
	age = 0.75 if level != 1 else 0.12
	history.clear()
	trail.clear()

func held(k: String) -> bool:
	for p in touches.values():
		if buttons[k].has_point(p): return true
	match k:
		"left": return Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		"right": return Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
		"jump": return Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_UP)
		"rewind": return Input.is_physical_key_pressed(KEY_Q)
		"forward": return Input.is_physical_key_pressed(KEY_E)
	return false

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed: touches[event.index] = event.position
		else: touches.erase(event.index)
	if event is InputEventScreenDrag: touches[event.index] = event.position
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: paused = not paused
		if event.keycode == KEY_R:
			if won:
				level = 0
				clues = [false,false,false]
				acquired = false
				won = false
			reset_room()
	if not started and ((event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)):
		started = true
		say("Find the gauntlet. Move with A/D or arrows. Jump with Space.")
	elif won and event is InputEventScreenTouch and event.pressed:
		level = 0
		clues = [false,false,false]
		acquired = false
		won = false
		reset_room()

func platforms() -> Array:
	var a = [Rect2(0,610,440,110), Rect2(900,610,380,110)]
	if level == 0:
		a.append(Rect2(230,520,160,18))
		if age < 0.35: a.append(Rect2(430,554,480,22))
	elif level == 1:
		a.append(Rect2(310,530,125,18))
		if age > 0.34: a.append(Rect2(470,530,120,20))
		if age > 0.65: a.append(Rect2(630,460,125,20))
		if age > 0.82: a.append(Rect2(790,530,130,20))
	else:
		if age < 0.36: a.append(Rect2(430,550,190,22))
		a.append(Rect2(640,500 + sin(clock * 1.3) * 45,110,18))
		if age > 0.64: a.append(Rect2(785,550,130,22))
	return a

func clue_pos() -> Vector2:
	return [Vector2(1020,555), Vector2(690,417), Vector2(1005,555)][level]

func _physics_process(dt):
	if not started or won or paused:
		queue_redraw()
		return
	message_time = maxf(0,message_time-dt)
	var old_player = player
	mode = 0
	if acquired:
		if held("rewind"): mode = -1
		elif held("forward"): mode = 1
	age = clampf(age + mode * dt * 0.33,0,1)
	clock += dt * (mode * 2.5 if mode != 0 else 1.0)
	if mode == -1 and not history.is_empty():
		var snap = history.pop_back()
		player = snap[0]
		velocity = snap[1]
		grounded = false
	else:
		history.append([player,velocity])
		if history.size() > 480: history.pop_front()
		var direction = float(held("right")) - float(held("left"))
		velocity.x = move_toward(velocity.x,direction*285,2200*dt)
		var jump_now = held("jump")
		if jump_now and not jump_was and grounded:
			velocity.y = -535
		jump_was = jump_now
		velocity.y = minf(velocity.y+1450*dt,900)
		player.x = clampf(player.x + velocity.x*dt,16,1264)
		player.y += velocity.y*dt
		grounded = false
		for plat in platforms():
			if player.x+14 > plat.position.x and player.x-14 < plat.end.x and velocity.y >= 0 and old_player.y+23 <= plat.position.y+7 and player.y+23 >= plat.position.y:
				player.y = plat.position.y-23
				velocity.y = 0
				grounded = true
	if Engine.get_physics_frames() % 4 == 0:
		trail.append(player)
		if trail.size()>12: trail.pop_front()
	if not acquired and player.distance_to(Vector2(310,478)) < 48:
		acquired = true
		say("GAUNTLET ACQUIRED  •  Hold Q to rewind yourself + restore ruins. E advances the world.")
	if player.distance_to(clue_pos()) < 40 and not clues[level]:
		clues[level] = true
		say(CLUES[level])
	if player.y > 820:
		deaths += 1
		reset_room()
		say("The loop catches you. Your memories remain. Hold time controls to shape a path.")
	if player.x > 1180 and grounded:
		if not clues[level]:
			say("The gate needs this room's memory fragment. Find the glowing diamond.")
		elif level < 2:
			level += 1
			reset_room()
			say("Grow the garden with E. Jump between the living platforms." if level == 1 else "Restore the first bridge, ride the lift, then advance the final bridge.")
		else: won = true
	queue_redraw()

func box(r: Rect2, color: Color, border: Color = Color.TRANSPARENT):
	draw_style_box(style(color,border),r)

func style(c: Color,b: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color=c
	s.border_color=b
	s.set_border_width_all(1 if b.a>0 else 0)
	s.set_corner_radius_all(8)
	return s

func label_at(s: String,p: Vector2,size: int=20,c: Color=Color("e6edf5")):
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)

func diamond(p: Vector2, c: Color, size: float):
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-size),p+Vector2(size,0),p+Vector2(0,size),p+Vector2(-size,0)]),c)

func _draw():
	draw_rect(Rect2(0,0,W,H),Color("09101f"))
	for i in range(75):
		var p = Vector2(fmod(i*177.1,1280),fmod(i*93.7,540))
		draw_circle(p,1.1,Color(0.4,0.7,0.9,0.22+sin(clock+i)*0.12))
	# Distant architecture and the fractured clock.
	for i in range(12):
		var x = i*119.0-40
		var h = 140+fmod(i*73,200)
		draw_rect(Rect2(x,610-h,76,h),Color("101d30"))
		for j in range(3): draw_rect(Rect2(x+15,630-h+j*44,5,17),Color("1c354b"))
	var center = Vector2(1050,285)
	draw_arc(center,136,0,TAU,96,Color("20364d"),3)
	draw_arc(center,120,0,TAU,96,Color("172b42"),1)
	for i in range(12):
		var v=Vector2.from_angle(i*TAU/12)
		draw_line(center+v*124,center+v*133,Color("38536b"),3)
	draw_line(center,center+Vector2.from_angle(clock*0.2-PI/2)*90,Color("38536b"),3)
	draw_line(center,center+Vector2.from_angle(clock*0.05)*60,Color("38536b"),5)
	for i in range(4):
		draw_line(Vector2(0,580+i*12),Vector2(W,580+i*12),Color(0.12,0.32,0.4,0.08),1)
	# Ghost geometry communicates the alternate environment state.
	var ghost = [Rect2(430,554,480,22)] if level==0 else ([Rect2(470,530,120,20),Rect2(630,460,125,20),Rect2(790,530,130,20)] if level==1 else [Rect2(430,550,190,22),Rect2(785,550,130,22)])
	for g in ghost:
		draw_rect(g,Color(0.3,0.7,0.75,0.08))
		draw_rect(g,Color(0.3,0.7,0.75,0.25),false,1)
	for p in platforms():
		var tint=Color("19394b") if p.position.y<600 else Color("18283d")
		box(p,tint,Color("34556b"))
		draw_line(p.position+Vector2(6,1),Vector2(p.end.x-6,p.position.y+1),Color("64d9cb"),3)
		if level==1 and p.position.x>440 and p.position.x<900:
			draw_line(Vector2(p.get_center().x,700),p.get_center(),Color("296d60"),5)
			for j in range(3):
				var leaf=p.get_center()+Vector2(0,35+j*32)
				draw_line(leaf,leaf+Vector2(25 if j%2==0 else -25,-18),Color("4cb68e"),6)
	# Pit haze.
	for i in range(6): draw_rect(Rect2(440,660+i*10,460,10),Color(0.15,0.52,0.65,0.03+i*0.012))
	if not acquired:
		var gp=Vector2(310,478+sin(clock*3)*5)
		draw_circle(gp,30,Color(0.3,0.9,0.8,0.08))
		diamond(gp,Color("70ffe0"),17)
		label_at("TIME GAUNTLET",Vector2(242,437),16,Color("70ffe0"))
	if not clues[level]:
		var cp=clue_pos()+Vector2(0,sin(clock*3)*5)
		draw_circle(cp,27,Color(1,0.76,0.38,0.09))
		diamond(cp,Color("ffc878"),11)
		label_at("MEMORY",cp+Vector2(-31,-28),13,Color("ffc878"))
	box(Rect2(1180,496,55,114),Color("152f40"),Color("6de5d6") if clues[level] else Color("44576b"))
	for i in range(3): draw_line(Vector2(1190+i*16,510),Vector2(1190+i*16,596),Color(0.4,0.9,0.84,0.2),2)
	label_at("EXIT",Vector2(1188,483),15)
	if mode!=0:
		for i in range(trail.size()):
			draw_rect(Rect2(trail[i]-Vector2(12,21),Vector2(24,44)),Color(0.35,0.9,0.9,float(i)/trail.size()*0.16))
	# Explorer silhouette and luminous scarf.
	draw_circle(player+Vector2(0,25),15,Color(0,0,0,0.25))
	box(Rect2(player-Vector2(13,8),Vector2(26,27)),Color("d6e4ed"))
	draw_circle(player+Vector2(0,-15),12,Color("bcd5e2"))
	box(Rect2(player+Vector2(-9,-20),Vector2(19,10)),Color("182e45"))
	draw_line(player+Vector2(-7,-14),player+Vector2(6,-14),Color("71fce0"),2)
	draw_line(player+Vector2(-6,19),player+Vector2(-7,24),Color("6d8ba4"),6)
	draw_line(player+Vector2(6,19),player+Vector2(7,24),Color("6d8ba4"),6)
	draw_line(player+Vector2(-10,-3),player+Vector2(-31,-1+sin(clock*8)*4),Color("fcab69"),6)
	if acquired: draw_circle(player+Vector2(14,5),5,Color("68f8d4"))
	# HUD
	box(Rect2(24,22,1232,94),Color("101d30"),Color("27394f"))
	label_at("CHRONOFALL",Vector2(46,57),27)
	label_at(TITLES[level],Vector2(47,88),14,Color("8ea6bd"))
	label_at("WORLD AGE",Vector2(450,48),12,Color("8ea6bd"))
	box(Rect2(450,61,350,8),Color("263b50"))
	box(Rect2(450,61,maxf(4,350*age),8),Color("68dfcd") if mode<0 else Color("f4b871"))
	label_at("PAST",Vector2(450,91),12,Color("6be2d0"))
	label_at("FUTURE",Vector2(750,91),12,Color("f4b871"))
	label_at("MEMORIES  %d / 3" % clues.count(true),Vector2(914,53),17,Color("ffc878"))
	label_at("REWIND" if mode<0 else ("FAST FORWARD" if mode>0 else "TIME FLOWS"),Vector2(914,84),14,Color("8ea6bd"))
	if message_time>0:
		box(Rect2(110,133,1060,48),Color(0.05,0.1,0.17,0.95),Color("365368"))
		label_at(message,Vector2(130,163),17,Color("e2e9ee"))
	elif level==0:
		label_at("Hold REWIND to rebuild the missing bridge. Memories survive every loop.",Vector2(302,155),18,Color("8ea6bd"))
	for key in buttons:
		var r=buttons[key]
		box(r,Color(0.07,0.14,0.22,0.94),Color("65d9ca") if held(key) else Color("344c64"))
		var txt={"left":"A / <","right":"D / >","rewind":"Q / <<","forward":"E / >>","jump":"SPACE / UP"}[key]
		label_at(txt,r.position+Vector2(14,31),16)
		label_at({"left":"MOVE","right":"MOVE","rewind":"REWIND","forward":"FORWARD","jump":"JUMP"}[key],r.position+Vector2(14,56),12,Color("8ea6bd"))
	label_at("R  restart room   /   ESC  pause",Vector2(300,674),15,Color("8ea6bd"))
	if not started: draw_overlay(false)
	if won: draw_overlay(true)
	if paused and started and not won:
		box(Rect2(400,270,480,150),Color("101d30"),Color("65d9ca"))
		label_at("TIME SUSPENDED",Vector2(475,330),28)
		label_at("Press Escape to return",Vector2(505,375),18)

func draw_overlay(end: bool):
	draw_rect(Rect2(0,0,W,H),Color(0.025,0.05,0.10,0.94))
	label_at("A SMALL ADVENTURE THROUGH A BROKEN TIMELINE",Vector2(310,170),17,Color("71dfcc"))
	label_at("CHRONOFALL" if not end else "TIME, RESTORED.",Vector2(310,267),64)
	label_at("The past is a path. The future is a tool.",Vector2(314,319),25,Color("f3be81"))
	var lines = ["Find the gauntlet. Recover three memories. Reach the clock tower.","Rewind restores ruins and retraces your last eight seconds.","Fast forward grows the garden and changes the world around you.","Memories endure. Experiment, fall, and try another timeline."]
	if end: lines=["You carried every memory through the fracture.","The bridge, the garden, and the tower share one timeline again.","Three chambers completed • %d falls • no memory lost." % deaths,"Built for touch and keyboard. Your next loop awaits."]
	for i in range(4): label_at(lines[i],Vector2(315,380+i*33),19,Color("a7b8cb"))
	box(Rect2(312,550,650,62),Color("204b50"),Color("6ee7cd"))
	label_at("TAP OR PRESS ANY KEY TO BEGIN" if not end else "PRESS R OR TAP TO PLAY AGAIN",Vector2(363,590),23)
