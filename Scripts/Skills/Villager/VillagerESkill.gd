extends "res://Scripts/Base/Skill.gd"

var main
var casting = false
var maxRange = 200
var castTime = 0.5
var cooldown = 7
var cooldownRemaining = 0
var castRemaining = castTime
var castLocation = Vector2.ZERO
var characterScript

func _ready():
	pass

func getSharedData ():
	var data = {}
	data["maxRange"] = maxRange
	data["castTime"] = castTime
	data["cooldown"] = cooldown
	data["cooldownRemaining"] = cooldownRemaining
	data["castRemaining"] = castRemaining
	data["casting"] = casting
	return data

func _init():
	type = "skillshot"

func use (data):
	cast(data)

func cast (data):
	casting = true
	castRemaining = castTime
	main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"skillCalled",[id, "cast", [data]])
	castLocation = data["castLocation"]
	characterScript.addImpact("RootImpact",{"timeRemaining": castTime, "animStart": "cast"})

func castEnd():
	casting = false
	cooldownRemaining = cooldown
	var node = Vars.rooms[characterScript.room].createObject("Objects/BearTrap",{"whoSummoned": characterScript, "position": characterScript.position, "endPosition": castLocation})
	node.init()
	main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"skillCalled",[id, "castEnd", [[]]])

func update (delta):
	if casting:
		castRemaining -= delta
		if castRemaining <= 0:
			castEnd()
	elif cooldownRemaining > 0:
		cooldownRemaining -= delta
	if Vars.players.has(characterScript.id) && Vars.players[characterScript.id]["inGame"]:
		main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"updateSkillInfo",[id,getSharedData()])
