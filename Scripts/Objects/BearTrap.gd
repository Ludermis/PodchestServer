extends Node

var room
var area
var shape
var endPosition
var whoSummoned
var speed = 512
var planted = false
var id
var trappedPlayer = -1
var trapTimeRemaining = 2
var position
var animationPlayed

func getSharedData ():
	var data = {}
	data["id"] = id
	data["whoSummoned"] = whoSummoned.id
	data["position"] = position
	data["animationPlayed"] = animationPlayed
	return data

func init ():
	area = Physics2DServer.area_create()
	shape = CircleShape2D.new()
	shape.radius = 6.5 * 4
	Physics2DServer.area_add_shape(area, shape, Transform2D(0,Vector2(0,0)))
	Physics2DServer.area_set_space(area, Vars.rooms[room].space)
	Physics2DServer.area_set_transform(area, Transform2D(0, Vector2(position.x, position.y)))
	Physics2DServer.area_set_monitorable(area,true)
	Physics2DServer.area_set_monitor_callback(area,self,"bodyEntered")
	Vars.rooms[room].objectsByRID[area] = self

func bodyEntered (state, rid, id, shape_idx_obj, shape_idx_area):
	if trappedPlayer == -1 && Vars.rooms[room].objectsByRID[rid] is Character && Vars.rooms[room].objectsByRID[rid].team != whoSummoned.team:
		planted = true
		trappedPlayer = Vars.rooms[room].objectsByRID[rid].id
		Vars.rooms[room].objectsByRID[rid].addImpact("RootImpact",{"timeRemaining": trapTimeRemaining, "animStart": "rooted", "animEnd": "rootedEnd", "endAnimStartTime": 0.15, "disableSkills": true})

func update (delta):
	if !planted:
		position = position.move_toward(endPosition,delta * speed)
		Physics2DServer.area_set_transform(area, Transform2D(0, position))
	if planted == false && position.distance_to(endPosition) < 0.1:
		position = endPosition
		planted = true
	if trappedPlayer != -1:
		trapTimeRemaining -= delta
		if trapTimeRemaining <= 0:
			destroy()
			return
	Vars.rooms[room].updateObject(id,getSharedData())

func destroy ():
	Vars.rooms[room].objectsByRID.erase(area)
	Physics2DServer.free_rid(area)
	Vars.rooms[room].removeObject(id)
