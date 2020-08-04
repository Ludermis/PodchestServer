extends "res://Scripts/Base/Skill.gd"

var main
var casting = false
var activeTime = 15
var activeTimeRemaining = activeTime
var castTime = 1.0
var cooldown = 25
var cooldownRemaining = 0
var castRemaining = castTime
var characterScript

func _ready():
	pass

func getSharedData ():
	var data = {}
	data["activeTime"] = activeTime
	data["activeTimeRemaining"] = activeTimeRemaining
	data["castTime"] = castTime
	data["cooldown"] = cooldown
	data["cooldownRemaining"] = cooldownRemaining
	data["castRemaining"] = castRemaining
	data["casting"] = casting
	return data

func _init():
	type = "cast"

func use (data):
	cast(data)

func cast (data):
	casting = true
	castRemaining = castTime
	main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"skillCalled",[id, "cast", [data]])
	characterScript.addImpact("RootImpact",{"timeRemaining": castTime, "animStart": "cast"})

func castEnd():
	casting = false
	cooldownRemaining = cooldown
	activeTimeRemaining = activeTime
	characterScript.scytheActive = true
	characterScript.timers[characterScript.scytheTimerID].start()
	main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"skillCalled",[id, "castEnd", [[]]])

func update (delta):
	if casting:
		castRemaining -= delta
		if castRemaining <= 0:
			castEnd()
	elif cooldownRemaining > 0:
		cooldownRemaining -= delta
	if characterScript.scytheActive:
		activeTimeRemaining -= delta
		if activeTimeRemaining <= 0:
			characterScript.scytheActive = false
			characterScript.timers[characterScript.scytheTimerID].stop()
	if Vars.players.has(characterScript.id) && Vars.players[characterScript.id]["inGame"]:
		main.rpc_id(characterScript.id,"objectCalled",-1,characterScript.id,"updateSkillInfo",[id,getSharedData()])
