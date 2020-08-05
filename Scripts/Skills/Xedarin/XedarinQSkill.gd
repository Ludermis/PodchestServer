extends "res://Scripts/Base/Skill.gd"

var main
var casting = false
var castTime = 1.0
var cooldown = 15
var cooldownRemaining = 0
var castRemaining = castTime
var characterScript

func _ready():
	pass

func getSharedData ():
	var data = {}
	data["castTime"] = castTime
	data["cooldown"] = cooldown
	data["cooldownRemaining"] = cooldownRemaining
	data["castRemaining"] = castRemaining
	data["casting"] = casting
	return data

func _init():
	type = "cast"

func use (data):
	if characterScript.canUseSkills:
		cast(data)

func cast (data):
	casting = true
	castRemaining = castTime
	main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"skillCalled",[id, "cast", [data]])
	characterScript.addImpact("RootImpact",{"timeRemaining": castTime, "animStart": "cast"})

func castEnd():
	casting = false
	cooldownRemaining = cooldown
	for i in range(3):
		Vars.rooms[characterScript.room].createObject("Objects/Clock",{"whoSummoned": characterScript, "position": characterScript.position}).init()
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
