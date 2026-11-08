class_name TemporalHistory
extends RefCounted
const CAPACITY=480
var frames:Array=[]
var cursor=0
var count=0
func _init(): frames.resize(CAPACITY)
func record(transform:Transform3D,linear:Vector3,angular:Vector3,flags:int,animation:int,health:float):
	frames[cursor]={"transform":transform,"linear":linear,"angular":angular,"flags":flags,"animation":animation,"health":health}
	cursor=(cursor+1)%CAPACITY
	count=mini(count+1,CAPACITY)
func past(ticks:int)->Dictionary:
	if count==0: return {}
	return frames[posmod(cursor-1-clampi(ticks,0,count-1),CAPACITY)]
func pop()->Dictionary:
	if count==0: return {}
	cursor=posmod(cursor-1,CAPACITY)
	count-=1
	return frames[cursor]
func clear():
	cursor=0
	count=0
