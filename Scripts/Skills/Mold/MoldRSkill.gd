extends "res://Scripts/Base/Skill.gd"

var main
var casting = false
var castTime = 1.0
var cooldown = 20
var cooldownRemaining = 0
var castRemaining = castTime
var characterScript
var clonesToSummon = 9
var activeTime = 10
var activeTimeRemaining = 0

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

func findRandomEnemyPlayer():
	var rtn = characterScript.id
	var idArray = []
	for i in Vars.rooms[characterScript.room].objects:
		if Vars.rooms[characterScript.room].objects[i]["instance"] is Character && Vars.rooms[characterScript.room].objects[i]["instance"].team != characterScript.team:
			idArray.append(i)
	if idArray.size() > 0:
		rtn = idArray[randi() % idArray.size()]
	return rtn

func castEnd():
	casting = false
	cooldownRemaining = cooldown
	activeTimeRemaining = activeTime
	characterScript.disguised = findRandomEnemyPlayer()
	main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"skillCalled",[id, "castEnd", [[]]])

func update (delta):
	if casting:
		castRemaining -= delta
		if castRemaining <= 0:
			castEnd()
	elif cooldownRemaining > 0:
		cooldownRemaining -= delta
	if characterScript.disguised != -1:
		activeTimeRemaining -= delta
		if activeTimeRemaining <= 0:
			characterScript.disguised = -1
	if Vars.players.has(characterScript.id) && Vars.players[characterScript.id]["inGame"]:
		main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"updateSkillInfo",[id,getSharedData()])
