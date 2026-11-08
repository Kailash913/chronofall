extends RefCounted
var g
var batches={}
func _init(game): g=game
func box(pos:Vector3,size:Vector3,color:String,solid=true):
	if not batches.has(color): batches[color]=[]
	batches[color].append(Transform3D(Basis.from_scale(size),pos))
	if solid:
		var shape=CollisionShape3D.new()
		var b=BoxShape3D.new()
		b.size=size
		shape.shape=b
		shape.position=pos
		g.world_body.add_child(shape)
func build():
	# Three distinct chambers connected by the induction corridor.
	box(Vector3(0,-0.6,2),Vector3(26,1,28),"263e4d")
	box(Vector3(0,-0.6,-45),Vector3(26,1,46),"263e4d")
	box(Vector3(0,-0.6,-90),Vector3(34,1,44),"263e4d")
	box(Vector3(0,-0.6,-135),Vector3(38,1,46),"263e4d")
	for side in [-1,1]:
		box(Vector3(side*13,4,-26),Vector3(1,8,84),"172a3d")
		box(Vector3(side*17,4,-90),Vector3(1,8,44),"172a3d")
		box(Vector3(side*19,5,-135),Vector3(1,10,44),"172a3d")
	box(Vector3(0,4,16),Vector3(26,8,1),"172a3d")
	box(Vector3(0,5,-157),Vector3(38,10,1),"172a3d")
	for z in range(10,-157,-8):
		var width=12 if z>-68 else (16 if z>-112 else 18)
		for side in [-1,1]:
			box(Vector3(side*(width-0.4),3,z),Vector3(1.2,6,1.2),"385767")
			box(Vector3(side*(width-1.05),3.3,z),Vector3(0.08,4.3,0.35),"00f0ff",false)
			box(Vector3(side*5,-0.07,z),Vector3(0.1,0.03,2),"ffb300",false)
		box(Vector3(0,7,z),Vector3(width*2,0.7,0.6),"233749",false)
	for z in range(12,-157,-4):
		if z<-12 and z>-22: continue
		box(Vector3(0,-0.08,z),Vector3(22,0.03,0.035),"45616b",false)
	# Narrow broken approach, cover and machinery.
	for p in [Vector3(-9,1,-31),Vector3(9,1,-31),Vector3(-10,1,-82),Vector3(10,1,-98),Vector3(-12,1,-131),Vector3(12,1,-137)]:
		box(p,Vector3(3,2,4),"3c5965")
		box(p+Vector3(0,1.05,0),Vector3(3.05,0.12,4.05),"ffb300",false)
	for z in [-68,-112]:
		for side in [-1,1]: box(Vector3(side*10,3,z),Vector3(6,6,1),"385767")
	# Reactor rings use batched bars, cheap on mobile.
	for i in range(16):
		var a=i*TAU/16
		box(Vector3(cos(a)*5,5+sin(a)*5,-151),Vector3(0.5,0.5,0.5),"00f0ff",false)
	flush()
func flush():
	for color in batches:
		var node=MultiMeshInstance3D.new()
		var multi=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		var mesh=BoxMesh.new()
		multi.mesh=mesh
		multi.instance_count=batches[color].size()
		for i in range(multi.instance_count): multi.set_instance_transform(i,batches[color][i])
		node.multimesh=multi
		node.material_override=g.mat(color,0.7 if color in ["00f0ff","ffb300"] else 0.0)
		g.add_child(node)
