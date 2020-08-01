extends Node

var main
var room
var body
var shape
var velocity = Vector2.ZERO
var acceleration = 64
var maxSpeed = 384
var position
var id
var team = -1
var canMove = true
var animation = "idle"
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
var animationsCantStop = ["rooted","rootedEnd"]
var pressed = {"right": false, "left": false, "up": false, "down": false}

func newUniqueImpactID ():
	uniqueImpactID += 1

func addImpact (imp, data):
	newUniqueImpactID()
	var index = uniqueImpactID
	impacts[index] = load("res://Scripts/Impacts/" + imp + ".gd").new()
	impacts[index].id = index
	impacts[index].ownerNode = id
	for i in data:
		impacts[index][i] = data[i]
	impacts[index].begin()
	return index

func impactSystem (delta):
	for i in impacts:
		impacts[i].update(delta)

func setDesiredDirection (dir):
	desiredDirection = dir

func setAnimation (anim):
	animation = anim

func skillSystem (delta):
	for i in skills:
		skills[i].update(delta)

func useSkill (which):
	skills[which].use()

func updateSkillInfo (which, data):
	for i in data:
		skills[which].set(i,data[i])

func skillCalled (which, funcName, data):
	skills[which].callv(funcName,data)

func anySkillCasting ():
	for i in skills:
		if "casting" in skills[i] && skills[i].casting == true:
			return true
	return false

func anySkillIndicating ():
	for i in skills:
		if "indicating" in skills[i] && skills[i].indicating == true:
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
#	var vec = Vars.optimizeVector(position + Vector2(32,32),64)
#	if !Vars.dirts.has(vec):
#		Vars.tryPlaceDirt(Client.selfPeerID,id,vec,team)
#	elif Vars.dirts[vec].team != team:
#		Vars.tryChangeDirt(Client.selfPeerID,id,vec,team)
	pass

func _on_DirectionTimer_timeout():
	if animation == "walk" || animation == "idle":
		findNextDirection()

func init ():
	pass
