extends "res://Scripts/Base/Skill.gd"

var main
var casting = false
var castTime = 1.0
var cooldown = 20
var cooldownRemaining = 0
var castRemaining = castTime
var characterScript
var area = 51

func _ready():
	pass

func getSharedData ():
	var data = {}
	data["castTime"] = castTime
	data["cooldown"] = cooldown
	data["cooldownRemaining"] = cooldownRemaining
	data["castRemaining"] = castRemaining
	data["casting"] = casting
	data["area"] = area
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
	
	Vars.rooms[characterScript.room].createObject("Effects/Shockwave",{"position": characterScript.position})
	for x in range(1,area / 2 + 2):
		for y in range (-area / 2 + (x - 1),area / 2 + 1 - (x - 1)):
			var pos = Vars.optimizeVector(characterScript.position + Vector2(32,32),64) + Vector2(y * 64, (x - 1) * 64)
			if Vars.rooms[characterScript.room].dirts.has(pos) && Vars.rooms[characterScript.room].dirts[pos].team == 1:
				Vars.tryChangeDirt(characterScript.room,characterScript.id,pos,2)
			elif Vars.rooms[characterScript.room].dirts.has(pos):
				Vars.tryChangeDirt(characterScript.room,characterScript.id,pos,1)
	for x in range(1,area / 2 + 1):
		for y in range (-area / 2 + x,area / 2 + 1 - x):
			var pos = Vars.optimizeVector(characterScript.position + Vector2(32,32),64) + Vector2(y * 64, -x * 64)
			if Vars.rooms[characterScript.room].dirts.has(pos) && Vars.rooms[characterScript.room].dirts[pos].team == 1:
				Vars.tryChangeDirt(characterScript.room,characterScript.id,pos,2)
			elif Vars.rooms[characterScript.room].dirts.has(pos):
				Vars.tryChangeDirt(characterScript.room,characterScript.id,pos,1)
	
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
