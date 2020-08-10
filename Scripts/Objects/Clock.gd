extends Node

var id
var position
var room
var lifeTimeRemaining = 15.0
var returnMode = false setget setReturnMode
var dir = Vector2(0,0)
var speed = 128 * 1.5
var whoSummoned
var body
var area
var shape
var uniqueTimerID = 0
var timers = {}
var paintTimerID

func setReturnMode (rtn):
	returnMode = rtn
	if returnMode == true:
		timers[paintTimerID].time = 0.05

func newUniqueTimerID ():
	uniqueTimerID += 1

func getSharedData ():
	var data = {}
	data["id"] = id
	data["position"] = position
	data["whoSummoned"] = whoSummoned.id
	return data

func _ready():
	pass

func dirtToPos (pos):
	if !Vars.rooms[room].dirts.has(pos):
		Vars.tryPlaceDirt(room,whoSummoned.id,pos,whoSummoned.team)
	elif Vars.rooms[room].dirts[pos].team != whoSummoned.team:
		Vars.tryChangeDirt(room,whoSummoned.id,pos,whoSummoned.team)

func directionTimeout ():
	if returnMode:
		return
	dir = Vector2(rand_range(-1,1),rand_range(-1,1))
	dir = dir.normalized()
	Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_LINEAR_VELOCITY,dir * speed)

func paintTimeout ():
	dirtToPos(Vars.optimizeVector(position + Vector2(32,32),64))

func init ():
	dir = Vector2(rand_range(-1,1),rand_range(-1,1))
	dir = dir.normalized()
	whoSummoned.clocks.append(id)
	
	newUniqueTimerID()
	timers[uniqueTimerID] = CustomTimer.new()
	timers[uniqueTimerID].time = 2
	timers[uniqueTimerID].connect("timeout",self,"directionTimeout")
	timers[uniqueTimerID].start()
	
	newUniqueTimerID()
	paintTimerID = uniqueTimerID 
	timers[paintTimerID] = CustomTimer.new()
	timers[paintTimerID].time = 0.5
	timers[paintTimerID].connect("timeout",self,"paintTimeout")
	timers[paintTimerID].start()
	
	body = Physics2DServer.body_create()
	Vars.rooms[room].objectsByRID[body] = self
	Physics2DServer.body_set_mode(body, Physics2DServer.BODY_MODE_CHARACTER)
	shape = CircleShape2D.new()
	shape.radius = 3.0
	Physics2DServer.body_add_shape(body, shape, Transform2D(0,Vector2(0,0)))
	Physics2DServer.body_set_space(body, Vars.rooms[room].space)
	Physics2DServer.body_set_param(body,Physics2DServer.BODY_PARAM_FRICTION,0)
	Physics2DServer.body_set_param(body,Physics2DServer.BODY_PARAM_LINEAR_DAMP,0)
	Physics2DServer.body_set_collision_layer(body, 1)
	Physics2DServer.body_set_collision_mask(body, 0)
	Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, Transform2D(0, position))
	Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_LINEAR_VELOCITY,dir * speed)
	#Physics2DServer.body_set_continuous_collision_detection_mode(body,Physics2DServer.CCD_MODE_CAST_RAY)
	Physics2DServer.body_set_max_contacts_reported(body,1)
	
	area = Physics2DServer.area_create()
	Vars.rooms[room].objectsByRID[area] = self
	Physics2DServer.area_add_shape(area, shape, Transform2D(0,Vector2(0,0)))
	Physics2DServer.area_set_space(area, Vars.rooms[room].space)
	Physics2DServer.area_set_collision_layer(area, 0)
	Physics2DServer.area_set_collision_mask(area, 1)
	Physics2DServer.area_set_transform(area,Transform2D(0,position))
	Physics2DServer.area_set_monitorable(area, true)
	Physics2DServer.area_set_area_monitor_callback(area, self, "areaEntered")

func areaEntered (state, rid, inst, shapeidx, shapeidx2):
	if !Vars.rooms[room].objectsByRID.has(rid):
		return
	if returnMode == true:
		if Vars.rooms[room].objectsByRID[rid].id == whoSummoned.id:
			whoSummoned.skills[1].cooldownRemaining -= 4
			Vars.rooms[whoSummoned.room].createObject("Effects/ClockDestroyEffect",{"team": whoSummoned.team, "position": position})
			destroy()
	else:
		if Vars.rooms[room].objectsByRID[rid] is Character:
			if Vars.rooms[room].objectsByRID[rid].team != whoSummoned.team:
				Vars.rooms[whoSummoned.room].createObject("Effects/ClockDestroyEffect",{"team": whoSummoned.team, "position": position})
				destroy()

func bodyEntered (rid):
	dir *= -1
	dir = dir.normalized()
	Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_LINEAR_VELOCITY,dir * speed)
	Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, Transform2D(0, Physics2DServer.body_get_state(body,Physics2DServer.BODY_STATE_TRANSFORM).origin + dir * 4))
	return false

func update (delta):
	position = Physics2DServer.body_get_state(body,Physics2DServer.BODY_STATE_TRANSFORM).origin
	Physics2DServer.area_set_transform(area,Transform2D(0,position))
	
	for i in timers:
		timers[i].update(delta)
	
	var state = Physics2DServer.body_get_direct_state(body)
	var count = state.get_contact_count()
	for i in range(count):
		if bodyEntered(state.get_contact_collider(i)):
			return
	
	if !returnMode:
		lifeTimeRemaining -= delta
		if lifeTimeRemaining <= 0:
			Vars.rooms[whoSummoned.room].createObject("Effects/ClockDestroyEffect",{"team": whoSummoned.team, "position": position})
			destroy()
			return
	else:
		Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_LINEAR_VELOCITY,(whoSummoned.position - position).normalized() * speed * 4)
	Vars.rooms[room].updateObject(id,getSharedData())

func destroy ():
	whoSummoned.clocks.erase(id)
	Vars.rooms[room].objectsByRID.erase(body)
	Physics2DServer.free_rid(body)
	Vars.rooms[room].objectsByRID.erase(area)
	Physics2DServer.free_rid(area)
	Vars.rooms[room].removeObject(id)
