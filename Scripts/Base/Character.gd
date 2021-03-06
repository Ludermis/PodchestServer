extends Node

class_name Character

var main
var room
var body
var shape
var area
var areaShape
var velocity = Vector2.ZERO
var acceleration = 64
var maxSpeed = 384
var position
var id
var team = -1
var canMove = true
var canUseSkills = true
var animation = "downIdle"
var desiredDirection = "down"
var direction = "down"
var playerName = "Guest"
var skin = ""
var characterName = "DefaultCharacterName"
var directionsInt = {1: "down", 2: "downRight", 3: "right", 4: "upRight", 5: "up", 6: "upLeft", 7: "left", 8: "downLeft"}
var directionsString = {"down": 1,"downRight": 2,"right": 3,"upRight": 4,"up": 5,"upLeft": 6,"left": 7,"downLeft": 8}
var skills = {}
var impacts = {}
var uniqueImpactID = 0
var uniqueTimerID = 0
var pressed = {"right": false, "left": false, "up": false, "down": false}
var timers = {}

func newUniqueImpactID ():
	uniqueImpactID += 1

func newUniqueTimerID ():
	uniqueTimerID += 1

func addImpact (imp, data):
	newUniqueImpactID()
	impacts[uniqueImpactID] = load("res://Scripts/Impacts/" + imp + ".gd").new()
	impacts[uniqueImpactID].id = uniqueImpactID
	impacts[uniqueImpactID].ownerScript = self
	for i in data:
		impacts[uniqueImpactID][i] = data[i]
	impacts[uniqueImpactID].begin()

func impactSystem (delta):
	var impactsKeys = impacts.keys()
	for i in impactsKeys:
		if impacts.has(i):
			impacts[i].update(delta)

func skillSystem (delta):
	for i in skills:
		skills[i].update(delta)

func useSkill (which, data):
	skills[which].use(data)

func getSkillInfo (who, which):
	var data = skills[which].getSharedData()
	data["gotInfo"] = true
	main.rpc_id(who,"objectCalled",-1,id,"updateSkillInfo",[which,data])

func anySkillCasting ():
	for i in skills:
		if "casting" in skills[i] && skills[i].casting == true:
			return true
	return false

func movementHandler (delta):
	if canMove:
		if pressed["right"]:
			velocity.x = min(velocity.x + acceleration, maxSpeed)
		elif pressed["left"]:
			velocity.x = max(velocity.x - acceleration, -maxSpeed)
		else:
			velocity.x = lerp(velocity.x,0,Vars.friction)
		if pressed["down"]:
			velocity.y = min(velocity.y + acceleration, maxSpeed)
		elif pressed["up"]:
			velocity.y = max(velocity.y - acceleration, -maxSpeed)
		else:
			velocity.y = lerp(velocity.y,0,Vars.friction)
	else:
		velocity.y = lerp(velocity.y,0,Vars.friction)
		velocity.x = lerp(velocity.x,0,Vars.friction)
	
	Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_LINEAR_VELOCITY,velocity)
	position = Physics2DServer.body_get_state(body,Physics2DServer.BODY_STATE_TRANSFORM).origin
	Physics2DServer.area_set_transform(area, Transform2D(0,position))

func findNextDirection ():
	if desiredDirection == direction:
		return
	var dir = 1
	if directionsString[direction] < directionsString[desiredDirection]:
		dir = 1
		if abs(directionsString[direction] - directionsString[desiredDirection]) > 4:
			dir = -1
	else:
		dir = -1
		if abs(directionsString[direction] - directionsString[desiredDirection]) > 4:
			dir = 1
	var next = directionsString[direction] + dir
	if next == 9:
		next = 1
	elif next == 0:
		next = 8
	direction = directionsInt[next]

func _on_DirtTimer_timeout():
	var vec = Vars.optimizeVector(position + Vector2(32,32),64)
	if !Vars.rooms[room].dirts.has(vec):
		Vars.tryPlaceDirt(room,id,vec,team)
	elif Vars.rooms[room].dirts[vec].team != team:
		Vars.tryChangeDirt(room,id,vec,team)

func inputHandler (delta):
	if canMove:
		if pressed["down"] && !pressed["right"] && !pressed["left"]:
			desiredDirection = "down"
		elif pressed["up"] && !pressed["right"] && !pressed["left"]:
			desiredDirection = "up"
		elif pressed["right"] && !pressed["up"] && !pressed["down"]:
			desiredDirection = "right"
		elif pressed["left"] && !pressed["up"] && !pressed["down"]:
			desiredDirection = "left"
		elif pressed["right"] && pressed["up"]:
			desiredDirection = "upRight"
		elif pressed["left"] && pressed["up"]:
			desiredDirection = "upLeft"
		elif pressed["right"] && pressed["down"]:
			desiredDirection = "downRight"
		elif pressed["left"] && pressed["down"]:
			desiredDirection = "downLeft"

func _on_DirectionTimer_timeout():
	findNextDirection()
	if canMove && (pressed["left"] || pressed["right"] || pressed["up"] || pressed["down"]):
		animation = direction + "Walk"
	elif canMove:
		animation = direction + "Idle"

func destroy ():
	Vars.rooms[room].objectsByRID.erase(body)
	Physics2DServer.free_rid(body)
	Vars.rooms[room].objectsByRID.erase(area)
	Physics2DServer.free_rid(area)
	Vars.rooms[room].removeObject(id)

func init ():
	pass
