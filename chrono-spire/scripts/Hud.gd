extends Control
var g
var menu:Control
var menu_kind="main"
var font=ThemeDB.fallback_font
var buttons_down={}
var move_stick=Vector2.ZERO
var look_stick=Vector2.ZERO
var left_id=-1
var right_id=-1
var left_origin=Vector2(145,555)
var right_origin=Vector2(1015,455)
var finger_actions={}
var flash=0.0
var hit_flash=0.0
var buttons={"reverse":Rect2(790,600,135,88),"forward":Rect2(935,600,135,88),"bubble":Rect2(1080,600,170,88),"fire":Rect2(1135,475,112,104),"lock":Rect2(790,488,115,85),"jump":Rect2(650,600,110,88),"sprint":Rect2(25,405,90,70)}
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	show_menu("main")
func style(bg:Color,border:Color,width=1):
	var s=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.set_border_width_all(width)
	s.corner_radius_top_left=3
	s.corner_radius_bottom_right=3
	return s
func text(s:String,p:Vector2,size=20,c=Color("dce5e9")):
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func rect(r:Rect2,c:Color,b=Color("345466")):
	draw_style_box(style(c,b),r)
func add_label(parent,s,pos,size,color=Color("dce5e9"),width=520):
	var l=Label.new()
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.text=s
	l.position=pos
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	l.size=Vector2(width,0)
	return l
func button(parent,title,pos,callback,width=450):
	var b=Button.new()
	b.text=title
	b.position=pos
	b.size=Vector2(width,52)
	b.add_theme_font_size_override("font_size",19)
	b.add_theme_stylebox_override("normal",style(Color("142a3d"),Color("426172")))
	b.add_theme_stylebox_override("hover",style(Color("25485b"),Color("00f0ff"),2))
	b.add_theme_stylebox_override("pressed",style(Color("355c67"),Color("ffb300"),2))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
func clear_menu():
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	menu=null
func hide_menu():
	clear_menu()
	buttons_down.clear()
	finger_actions.clear()
	move_stick=Vector2.ZERO
	look_stick=Vector2.ZERO
	left_id=-1
	right_id=-1
func show_menu(kind="main"):
	clear_menu()
	menu_kind=kind
	menu=Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(menu)
	var bg=Panel.new()
	bg.position=Vector2(42,45)
	bg.size=Vector2(585,630)
	bg.add_theme_stylebox_override("panel",style(Color(0.025,0.07,0.12,0.96),Color("335263")))
	menu.add_child(bg)
	add_label(menu,"CHRONO-SPIRE",Vector2(76,85),43)
	add_label(menu,"TEMPORAL CONTAINMENT DIVISION  /  AGENT VANCE",Vector2(78,141),13,Color("00f0ff"))
	if kind=="main" or kind=="pause":
		add_label(menu,"Tomorrow is breaking.",Vector2(78,193),27,Color("ffb300"))
		add_label(menu,"Descend beneath the city. Rebuild the path, turn the Wardens' weapons against them, and seal the Singularity Core.",Vector2(78,236),19,Color("9cb2c1"),480)
		button(menu,"RESUME MISSION" if kind=="pause" else "INITIATE MISSION",Vector2(78,350),func():
			if kind=="pause": g.pause_game()
			else: g.start_mission(0))
		button(menu,"TEMPORAL ARCHIVES / LEVEL SELECT",Vector2(78,414),func(): show_menu("archives"))
		button(menu,"AUDIO / GRAPHICS SETTINGS",Vector2(78,478),func(): show_menu("settings"))
		button(menu,"QUIT",Vector2(78,542),func(): get_tree().quit())
		add_label(menu,"3 sectors  •  Checkpoints save automatically\nWASD + mouse  /  Touch + optional gyro",Vector2(78,610),14,Color("8aa4b7"))
	elif kind=="archives":
		add_label(menu,"Recovered archives",Vector2(78,200),28,Color("ffb300"))
		var names=["00 / INDUCTION", "01 / WARDEN FOUNDRY", "02 / SINGULARITY CHAMBER"]
		for i in range(3):
			var idx=i
			var b=button(menu,names[i]+("  [LOCKED]" if i>g.unlocked else ""),Vector2(78,280+i*70),func(): g.start_mission(idx))
			b.disabled=i>g.unlocked
		add_label(menu,"Sectors unlock when their temporal anchor is reached.",Vector2(78,505),18,Color("9cb2c1"),470)
		button(menu,"BACK",Vector2(78,580),func(): show_menu("pause" if g.active else "main"))
	elif kind=="settings":
		add_label(menu,"Master volume",Vector2(78,205),20)
		var slider=HSlider.new()
		slider.position=Vector2(78,245)
		slider.size=Vector2(450,35)
		slider.min_value=0
		slider.max_value=1
		slider.step=0.01
		slider.value=g.volume
		slider.value_changed.connect(func(v): g.set_volume(v); g.save_settings())
		menu.add_child(slider)
		add_label(menu,"Render quality",Vector2(78,300),20)
		var option=OptionButton.new()
		option.position=Vector2(78,340)
		option.size=Vector2(450,45)
		for s in ["PERFORMANCE / 65% resolution","BALANCED / 80% resolution","HIGH / 100% resolution"]: option.add_item(s)
		option.selected=g.graphics
		option.item_selected.connect(func(i): g.graphics=i; g.apply_graphics(); g.save_settings())
		menu.add_child(option)
		var check=CheckButton.new()
		check.position=Vector2(78,410)
		check.size=Vector2(450,45)
		check.text="Gyro-assisted aiming (supported phones)"
		check.button_pressed=g.gyro
		check.toggled.connect(func(v): g.gyro=v; g.save_settings())
		menu.add_child(check)
		add_label(menu,"Mobile resolution adapts toward 60 FPS.\nNo dynamic shadows or heavy post-processing.",Vector2(78,480),17,Color("9cb2c1"))
		button(menu,"BACK",Vector2(78,580),func(): show_menu("pause" if g.active else "main"))
	else:
		add_label(menu,"TOMORROW, RESTORED." if kind=="victory" else "TIMELINE INTERRUPTED",Vector2(78,205),27,Color("ffb300"))
		add_label(menu,"Vance seals the fracture. The stolen seconds return to the city. The Chrono-Spire is silent at last." if kind=="victory" else "Your temporal anchor remains intact. Return to the sector checkpoint and try another approach.",Vector2(78,260),22,Color("b7cbd5"),475)
		button(menu,"REPLAY INDUCTION" if kind=="victory" else "RETRY CHECKPOINT",Vector2(78,420),func(): g.start_mission(0 if kind=="victory" else g.checkpoint))
		button(menu,"TEMPORAL ARCHIVES",Vector2(78,490),func(): show_menu("archives"))
		button(menu,"MAIN MENU",Vector2(78,560),func():
			g.active=false
			g.menu_camera.make_current()
			show_menu("main"))
	queue_redraw()
func _input(event):
	if not g.active or g.paused: return
	if event is InputEventScreenTouch:
		var p=event.position
		if event.pressed:
			if Rect2(1205,20,55,50).has_point(p):
				g.pause_game()
				return
			for key in buttons:
				if buttons[key].has_point(p):
					finger_actions[event.index]=key
					buttons_down[key]=true
					if key=="lock": g.toggle_lock()
					if key=="jump": g.jump_queued=true
					get_viewport().set_input_as_handled()
					return
			if p.x<640 and left_id==-1:
				left_id=event.index
				left_origin=p
			elif right_id==-1:
				right_id=event.index
				right_origin=p
		else:
			if finger_actions.has(event.index):
				buttons_down[finger_actions[event.index]]=false
				finger_actions.erase(event.index)
			if event.index==left_id:
				left_id=-1
				move_stick=Vector2.ZERO
			if event.index==right_id:
				right_id=-1
				look_stick=Vector2.ZERO
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		if event.index==left_id: move_stick=((event.position-left_origin)/72).limit_length()
		if event.index==right_id: look_stick=((event.position-right_origin)/90).limit_length()
		get_viewport().set_input_as_handled()
func _draw():
	if not g.active: return
	if flash>0: draw_rect(Rect2(0,0,1280,720),Color(0.9,0.1,0.08,flash*0.4))
	if g.bubble: draw_rect(Rect2(0,0,1280,720),Color(0,0.75,1,0.055))
	rect(Rect2(22,20,1070,90),Color(0.025,0.07,0.12,0.88))
	text("VANCE",Vector2(42,51),24)
	text("HEALTH  %03d" % g.health,Vector2(42,82),18,Color("00f0ff"))
	text(g.objectives[mini(g.stage,6)],Vector2(215,51),18)
	var heading=fposmod(rad_to_deg(-g.yaw),360)
	text("%03d°    N  ·  E  ·  S  ·  W" % heading,Vector2(215,83),14,Color("91aabb"))
	text("ANCHOR %02d  /  WARDENS %d" % [g.checkpoint,g.enemies.size()],Vector2(760,83),14,Color("ffb300"))
	rect(Rect2(1205,20,55,50),Color("142a3d"))
	text("II",Vector2(1223,53),22)
	var center=Vector2(1145,66)
	draw_arc(center,38,-PI/2,TAU-PI/2,48,Color("263e4d"),7,true)
	draw_arc(center,38,-PI/2,-PI/2+TAU*g.energy/100,48,Color("00f0ff") if g.energy>20 else Color("ffb300"),7,true)
	text("%d"%g.energy,center+Vector2(-15,6),20)
	var cp=Vector2(640,360)
	var color=Color("ffb300") if g.valid_target(g.locked) else Color("dce5e9")
	if hit_flash>0: color=Color("ff685e")
	for v in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]: draw_line(cp+v*7,cp+v*14,color,2,true)
	if g.valid_target(g.locked): draw_arc(cp,23,0,TAU,24,Color("ffb300"),1.5,true)
	var target=g.current_target()
	if g.valid_target(target):
		text(target.name,Vector2(505,407),14,Color("ffb300"))
		if target.kind=="golem": text("EXPOSED %.1fs" % target.exposed if target.exposed>0 else "SHIELDED / REWIND ARMOR",Vector2(505,430),14,Color("00f0ff"))
	if g.notice_timer>0:
		rect(Rect2(170,125,940,55),Color(0.025,0.07,0.12,0.9))
		text(g.notice,Vector2(188,158),16,Color("d0dde5"))
	if g.mobile:
		for origin in [left_origin if left_id>=0 else Vector2(145,555),right_origin if right_id>=0 else Vector2(1015,455)]:
			draw_circle(origin,66,Color(0.03,0.12,0.19,0.35))
			draw_arc(origin,66,0,TAU,32,Color(0.4,0.8,0.9,0.5),2,true)
		draw_circle((left_origin if left_id>=0 else Vector2(145,555))+move_stick*45,23,Color(0.3,0.8,0.85,0.5))
		draw_circle((right_origin if right_id>=0 else Vector2(1015,455))+look_stick*45,23,Color(0.3,0.8,0.85,0.5))
		for key in buttons:
			var r=buttons[key]
			rect(r,Color(0.03,0.12,0.19,0.72),Color("00f0ff") if buttons_down.get(key,false) else Color("45616b"))
			text(key.to_upper(),r.position+Vector2(12,r.size.y*0.55),15)
	else:
		rect(Rect2(200,653,880,42),Color(0.025,0.07,0.12,0.85))
		text("WASD  MOVE     SHIFT  SPRINT     SPACE  JUMP     RMB  LOCK     Q  REWIND     E  FORWARD     F  BUBBLE",Vector2(217,679),14,Color("91aabb"))
